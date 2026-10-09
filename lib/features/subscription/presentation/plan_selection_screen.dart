import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_controller.dart';
import '../data/models/subscription_status_response.dart';
import '../data/subscription_api.dart';
import 'widgets/subscription_plan_picker.dart';

/// Plan-selection / paywall screen for vendors. Mirrors eventsrus-web's
/// planSelectionModal + proPlanPickerForm fragments: a billing-cycle picker
/// (4 real cycles, priced from the backend) plus a PayPal-or-GCash payment
/// choice. Only PRO exists as a plan tier on the backend today (PREMIUM was
/// dropped before it ever had a subscriber - see
/// com.backend.eventsrus.enums.PlanTier's doc comment), so unlike the old
/// version of this screen there's no tier picker here, only a billing-cycle
/// one.
///
/// Reached two ways:
///  - Pushed normally (e.g. from PlanStatusBanner's "Upgrade" button) for a
///    vendor who already has a plan but is renewing/upgrading - dismissible
///    like any other pushed screen.
///  - Rendered directly as the app's root content by AuthGate (forced: true,
///    no back button, see lib/app/auth_gate.dart) for a brand-new vendor who
///    has never subscribed at all (auth.plan == null) - mirrors web's
///    non-dismissible-until-first-choice planSelectionModal, adapted to a
///    mobile-appropriate "forced initial route" rather than a literal modal.
///
/// Note: showWelcomePopup (the one-time "Welcome to PRO!" celebration) is
/// parsed into SubscriptionStatusResponse for parity but has no mobile UI
/// yet - no screen calls POST /welcome-shown. Left out of scope: it's a
/// purely cosmetic one-time popup, not a functional gap.
class PlanSelectionScreen extends StatefulWidget {
  final bool forced;

  const PlanSelectionScreen({super.key, this.forced = false});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  bool _loadingStatus = true;
  String? _errorMessage;
  SubscriptionStatusResponse? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _errorMessage = null;
    });
    try {
      final status = await context.read<SubscriptionApi>().getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loadingStatus = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loadingStatus = false;
      });
    }
  }

  // The GCash grant takes effect immediately (temporary 7-day access while
  // an admin reviews), so refresh the session's plan right away - this is
  // also what lets AuthGate stop forcing this screen for a brand-new
  // vendor the instant they submit.
  Future<void> _onStatusChanged(SubscriptionStatusResponse status) async {
    setState(() => _status = status);
    await context.read<AuthController>().applyPlanUpdate(plan: status.plan, planExpiresAt: status.expiresAt);
  }

  void _openBillingHistory() {
    Navigator.of(context).pushNamed('/subscription/history');
  }

  // Mirrors AppTopBar's _confirmLogout - duplicated rather than shared since
  // this screen (when forced) has no AppTopBar at all, see its own actions
  // list above.
  Future<void> _confirmLogout() async {
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign in again to continue."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forced ? 'Choose your PRO plan' : 'Choose a Plan'),
        automaticallyImplyLeading: !widget.forced,
        actions: [
          // The vendor just paid in an external browser (PayPal) or is
          // waiting on a GCash admin review - there's no automatic way for
          // this screen to learn that finished (same reasoning as the Google
          // Calendar screen's manual refresh button), so without this they'd
          // have no way to pick up a since-activated plan short of fully
          // restarting the app.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: _loadingStatus ? null : _loadStatus,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Billing history',
            onPressed: _openBillingHistory,
          ),
          // When forced (a brand-new vendor with no plan yet - see
          // lib/app/auth_gate.dart), this screen is the entire app content
          // with no back button and no other route to reach the logout
          // control that every other root screen gets from AppTopBar - so
          // without this, a vendor who isn't ready to pay right now has no
          // way out of the app short of force-quitting it (and relaunching
          // just lands them right back here, still logged in).
          if (widget.forced)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: _confirmLogout,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _loadingStatus
              ? const CircularProgressIndicator()
              : _status == null
                  ? _LoadErrorView(message: _errorMessage, onRetry: _loadStatus)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.forced ? 'Choose your PRO plan' : 'Upgrade your plan',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.forced
                                ? 'Pick a billing cycle and pay via PayPal or GCash to get full access.'
                                : 'Billed in PHP. Pay via PayPal or GCash. Cancel anytime.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          SubscriptionPlanPicker(status: _status!, onStatusChanged: _onStatusChanged),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _LoadErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
          const SizedBox(height: 12),
          Text(
            message ?? 'Could not load plan pricing.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
