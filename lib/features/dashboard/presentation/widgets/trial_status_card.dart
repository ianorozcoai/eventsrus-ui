import 'package:flutter/material.dart';

import '../../../subscription/data/models/billing_source.dart';
import '../../../subscription/data/models/subscription_status_response.dart';

/// The supplier's free period, always visible on the dashboard: a new supplier otherwise sees a normal-looking
/// dashboard and has no idea the free period will end and that a plan is needed. Calm while there is plenty of
/// time, amber in the last [urgentDays] days. Shown for the sign-up free trial (the grace period of a free
/// grant) and for a longer free plan such as a promo code; null for everyone else (paid suppliers etc.).
class TrialStatusCard extends StatelessWidget {
  /// Same window as the website's reminder popup.
  static const int urgentDays = 14;

  final SubscriptionStatusResponse status;
  final VoidCallback onChoosePlan;

  const TrialStatusCard({super.key, required this.status, required this.onChoosePlan});

  /// Whether [status] describes a free period this card should talk about.
  static bool appliesTo(SubscriptionStatusResponse status) {
    if (status.onFreeTrial) return true;
    return status.plan != null &&
        status.billingSource == BillingSource.freeGrant &&
        !status.expired &&
        !status.inGracePeriod &&
        status.expiresAt != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final trialDays = status.freeTrialDaysLeft;
    final DateTime? endDate = trialDays != null ? status.graceEndsAt : status.expiresAt;
    final int? daysLeft = trialDays ?? _daysUntil(endDate);
    final urgent = daysLeft != null && daysLeft <= urgentDays;

    final title = trialDays != null
        ? 'Free trial: ${_days(daysLeft!)} left'
        : daysLeft != null
            ? 'Free access: ${_days(daysLeft)} left'
            : 'Free access';
    final body = endDate == null
        ? 'Your supplier tools are free for now. Choose a plan to keep them after your free period ends.'
        : urgent
            ? 'Your free period ends on ${_formatDate(endDate)}. Choose a plan now to keep quotations, chat, bookings '
                'and your place in planner search.'
            : 'Everything is free until ${_formatDate(endDate)}. After that you need a plan to keep your supplier '
                'tools. You can choose one any time.';

    final background = urgent ? colorScheme.tertiaryContainer : colorScheme.surface;
    final foreground = urgent ? colorScheme.onTertiaryContainer : colorScheme.onSurface;
    final accent = urgent ? const Color(0xFFD97706) : const Color(0xFF7C3AED);

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        key: const Key('trial-status-card'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: urgent ? accent.withValues(alpha: 0.5) : colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(urgent ? Icons.hourglass_bottom : Icons.workspace_premium_outlined, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: urgent
                  ? FilledButton(
                      key: const Key('trial-choose-plan'),
                      onPressed: onChoosePlan,
                      child: const Text('Choose a plan'),
                    )
                  : OutlinedButton(
                      key: const Key('trial-choose-plan'),
                      onPressed: onChoosePlan,
                      child: const Text('See plans'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _days(int days) => '$days ${days == 1 ? 'day' : 'days'}';

  static int? _daysUntil(DateTime? end) {
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    if (left.isNegative) return 0;
    return (left.inMinutes / (24 * 60)).ceil().clamp(1, 100000);
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
