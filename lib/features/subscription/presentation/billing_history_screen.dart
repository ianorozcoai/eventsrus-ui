import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/models/plan_tier.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_controller.dart';
import '../data/models/billing_history_entry.dart';
import '../data/models/billing_source.dart';
import '../data/models/subscription_status_response.dart';
import '../data/subscription_api.dart';
import 'widgets/subscription_plan_picker.dart';

/// Vendor billing history - mirrors eventsrus-web's single-page
/// vendor/subscription.html: a "Current Plan" status card (plan/status/
/// renewal date), the pay/renew form (SubscriptionPlanPicker - billing
/// cycle + PayPal/GCash) inlined directly below it rather than behind a
/// separate screen, then the same past-charges table this screen already
/// had. PlanSelectionScreen still exists separately for the forced
/// brand-new-vendor paywall (see its own doc comment) - this screen reuses
/// the same picker widget rather than duplicating the payment logic.
class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  List<BillingHistoryEntry>? _entries;
  SubscriptionStatusResponse? _status;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final entries = await context.read<SubscriptionApi>().getHistory();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      // Anything other than ApiException (e.g. a response shape mismatch)
      // must still clear _loading, or the spinner hangs forever instead of
      // ever reaching a retry-able state - show a generic message to the
      // vendor, keep the real one in the console for diagnosis.
      debugPrint('BillingHistoryScreen: failed to load history. ($e)');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load billing history. Please try again.';
        _loading = false;
      });
    }
    // Current-plan status is a secondary, non-blocking concern - the history
    // list is still useful on its own if this fails (same convention as
    // PlanStatusBanner's own status fetch).
    try {
      final status = await context.read<SubscriptionApi>().getStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {}
  }

  // The GCash grant takes effect immediately (temporary 7-day access while
  // an admin reviews) - refresh both this screen's status and the session's
  // own plan right away, same as PlanSelectionScreen's own handler.
  Future<void> _onStatusChanged(SubscriptionStatusResponse status) async {
    setState(() => _status = status);
    await context.read<AuthController>().applyPlanUpdate(plan: status.plan, planExpiresAt: status.expiresAt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_status != null) ...[
                        _CurrentPlanCard(status: _status!),
                        const SizedBox(height: 16),
                        Text(
                          'Renew Subscription',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SubscriptionPlanPicker(status: _status!, onStatusChanged: _onStatusChanged),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Billing & Payment History',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Chip(label: Text('${(_entries ?? []).length} total')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((_entries ?? []).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('No billing history yet.')),
                        )
                      else
                        for (final entry in _entries!) ...[
                          _HistoryTile(entry: entry),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
    );
  }
}

/// Mirrors web's "Current Plan" card (vendor/subscription.html) - plan
/// name, a status badge, the renewal/expiry date, and a pay/renew CTA into
/// PlanSelectionScreen. Badge copy/colors match PlanStatusBanner's own
/// strings for consistency with the dashboard's dismissible version of the
/// same information.
class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionStatusResponse status;

  const _CurrentPlanCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPlan = status.plan != null;
    final isFreeGrant = status.gcashAwaitingVerification ||
        status.gcashRejected ||
        status.billingSource == BillingSource.freeGrant;

    final String planName = !hasPlan ? 'No active plan' : (isFreeGrant ? 'Free-Pro' : 'PRO');

    late final String badgeText;
    late final Color badgeColor;
    String? dateLine;

    if (status.gcashRejected) {
      badgeText = 'Payment verification failed';
      badgeColor = colorScheme.error;
    } else if (status.gcashAwaitingVerification) {
      badgeText = 'Payment is being verified';
      badgeColor = Colors.orange;
    } else if (!hasPlan) {
      badgeText = 'No active plan';
      badgeColor = colorScheme.outline;
    } else if (status.expired) {
      badgeText = 'Expired';
      badgeColor = colorScheme.error;
      dateLine = status.expiresAt == null ? null : 'Expired on ${_formatDate(status.expiresAt!)}';
    } else if (status.inGracePeriod) {
      badgeText = 'Grace Period';
      badgeColor = colorScheme.error;
      dateLine = status.graceEndsAt == null
          ? null
          : 'You still have full access until ${_formatDate(status.graceEndsAt!)} - renew before then to avoid losing access.';
    } else if (status.expiringSoon) {
      badgeText = 'Renews soon';
      badgeColor = Colors.orange;
      dateLine = status.expiresAt == null ? null : 'Renews on ${_formatDate(status.expiresAt!)}';
    } else {
      badgeText = 'Active';
      badgeColor = Colors.green;
      dateLine = status.expiresAt == null ? null : 'Renews on ${_formatDate(status.expiresAt!)}';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(planName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text(badgeText, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            if (status.gcashRejected && status.gcashRejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(status.gcashRejectionReason!, style: TextStyle(color: colorScheme.error)),
            ],
            if (dateLine != null) ...[
              const SizedBox(height: 8),
              Text(dateLine, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _HistoryTile extends StatelessWidget {
  final BillingHistoryEntry entry;

  const _HistoryTile({required this.entry});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final periodLabel = entry.periodStart != null && entry.periodEnd != null
        ? '${_formatDate(entry.periodStart!)} - ${_formatDate(entry.periodEnd!)}'
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.plan.toApi(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.billingSource.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  if (periodLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      periodLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.amount == null ? 'Free' : '${entry.currency} ${entry.amount!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.occurredAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
