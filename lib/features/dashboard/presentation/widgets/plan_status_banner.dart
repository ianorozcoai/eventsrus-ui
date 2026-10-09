import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/role.dart';
import '../../../auth/state/auth_controller.dart';
import '../../../subscription/data/models/subscription_status_response.dart';
import '../../../subscription/data/subscription_api.dart';

/// Dashboard paywall banners for vendors. Mirrors eventsrus-web's
/// paywallModal (expiring/grace/expired - fragments/common.html ::
/// paywallModal) and gcashAwaitingVerificationModal/gcashRejectedModal.
/// The "no plan at all yet" case (web's planSelectionModal) doesn't apply
/// here - that's handled before a vendor ever reaches the dashboard that
/// hosts this banner, see lib/app/auth_gate.dart.
///
/// Both banners are session-only dismissible (no persisted "already shown"
/// flag, unlike web's WebSession.PAYWALL_SHOWN) - they reappear next time
/// this widget remounts (e.g. next login), which is an acceptable mobile
/// simplification of "keeps reappearing every login until resolved".
class PlanStatusBanner extends StatefulWidget {
  const PlanStatusBanner({super.key});

  @override
  State<PlanStatusBanner> createState() => _PlanStatusBannerState();
}

class _PlanStatusBannerState extends State<PlanStatusBanner> {
  SubscriptionStatusResponse? _status;
  bool _expiryDismissed = false;
  bool _gcashDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    final authController = context.read<AuthController>();
    if (authController.role != Role.vendor) return;

    try {
      final status = await context.read<SubscriptionApi>().getStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {
      // Non-blocking CTA — silently skip if the status check fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final status = _status;

    if (authController.role != Role.vendor || status == null) {
      return const SizedBox.shrink();
    }

    final banners = <Widget>[];

    if (!_expiryDismissed && (status.expired || status.inGracePeriod || status.expiringSoon)) {
      banners.add(
        _Banner(
          message: status.expired
              ? 'Your plan has expired. Upgrade to keep full access to vendor features.'
              : status.inGracePeriod
                  ? 'Your plan has expired but you still have full access until '
                      '${_formatDate(status.graceEndsAt)}. Renew now to avoid losing access.'
                  : 'Your plan is expiring soon. Upgrade now to avoid any interruption.',
          actionLabel: 'Upgrade',
          onAction: () => Navigator.of(context).pushNamed('/subscription/plans'),
          onDismiss: status.expired ? null : () => setState(() => _expiryDismissed = true),
        ),
      );
    }

    if (!_gcashDismissed && (status.gcashAwaitingVerification || status.gcashRejected)) {
      banners.add(
        _Banner(
          message: status.gcashRejected
              ? 'Your GCash payment verification failed.'
                  '${status.gcashRejectionReason != null ? ' ${status.gcashRejectionReason}' : ''} '
                  'Please re-upload your payment screenshot.'
              : 'Your GCash payment is being reviewed. An admin will confirm it shortly - no '
                  'further action needed from you.',
          actionLabel: status.gcashRejected ? 'Resolve' : null,
          onAction: status.gcashRejected
              ? () => Navigator.of(context).pushNamed('/subscription/plans')
              : null,
          onDismiss: () => setState(() => _gcashDismissed = true),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: banners,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'soon';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const _Banner({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: colorScheme.onTertiaryContainer)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.onTertiaryContainer),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
