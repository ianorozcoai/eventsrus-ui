import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../dashboard/presentation/widgets/trial_status_card.dart';
import '../../dashboard/presentation/trial_welcome_screen.dart';
import '../../subscription/data/models/subscription_status_response.dart';
import '../../subscription/data/subscription_api.dart';
import '../data/models/vendor_dashboard.dart';
import '../data/vendor_dashboard_api.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  VendorDashboard? _dashboard;
  SubscriptionStatusResponse? _planStatus;
  bool _welcomeHandled = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await context.read<VendorDashboardApi>().getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
      _loadPlanStatus();
    } catch (e) {
      // ApiException.message is already written to be shown to a user
      // (same pattern as login_screen.dart etc.) - anything else is an
      // unexpected/parsing failure, so log the real detail for whoever's
      // looking at the dev console rather than putting it on screen.
      if (e is! ApiException) debugPrint('VendorDashboardScreen failed to load: $e');
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load dashboard. Please try again.';
        _loading = false;
      });
    }
  }

  /// The plan status only feeds the free-trial card, so a failure here must never break the dashboard.
  Future<void> _loadPlanStatus() async {
    try {
      final status = await context.read<SubscriptionApi>().getStatus();
      if (!mounted) return;
      setState(() => _planStatus = status);
      if (status.showTrialWelcome && !_welcomeHandled) {
        _welcomeHandled = true;
        await _showTrialWelcome(status);
      }
    } catch (_) {}
  }

  /// The one-time "Welcome to EventsRUs" message right after sign-up. Either answer ends it for good.
  Future<void> _showTrialWelcome(SubscriptionStatusResponse status) async {
    final api = context.read<SubscriptionApi>();
    final choice = await showTrialWelcomeScreen(context, daysLeft: TrialStatusCard.freeDaysLeft(status));
    try {
      await api.markTrialWelcomeShown();
    } catch (_) {
      // Worst case the welcome is offered once more next time; it must never get in the supplier's way.
    }
    if (!mounted) return;
    if (choice == TrialWelcomeChoice.subscribeNow) {
      await Navigator.of(context).pushNamed('/subscription/plans');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      // Was previously a dead end with no way to recover short of
      // restarting the app - a transient failure (e.g. the backend not
      // reachable yet) left the dashboard stuck on this message forever.
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dashboard = _dashboard!;
    final colorScheme = Theme.of(context).colorScheme;
    final stats = <_Stat>[
      _Stat('New leads', '${dashboard.newLeadsCount}', Icons.person_search_outlined, const Color(0xFF0C83FF)),
      _Stat('New messages', '${dashboard.newMessagesCount}', Icons.mail_outline, const Color(0xFF7C3AED)),
      _Stat('New quotations', '${dashboard.newQuotationsCount}', Icons.request_quote_outlined, const Color(0xFFD97706)),
      _Stat('New bookings', '${dashboard.newBookingsCount}', Icons.event_available_outlined, const Color(0xFF16A34A)),
      _Stat('Upcoming events', '${dashboard.upcomingEventsCount}', Icons.calendar_month_outlined, const Color(0xFF0D9488)),
      _Stat('Cancellations', '${dashboard.cancellationsCount}', Icons.cancel_outlined, const Color(0xFFDC2626)),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time business overview.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_planStatus != null && TrialStatusCard.appliesTo(_planStatus!))
              TrialStatusCard(
                status: _planStatus!,
                onChoosePlan: () => Navigator.of(context).pushNamed('/subscription/plans'),
              ),
            if (!dashboard.hasPackages)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You haven't added any packages yet — add one so planners can see what you offer.",
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Income is the number a supplier checks first, so it leads on its own; the six
            // activity counts sit below in a two-column grid so they fit on one screen.
            _IncomeCard(value: '₱${dashboard.totalIncome.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            for (var i = 0; i < stats.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _StatTile(stat: stats[i])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < stats.length ? _StatTile(stat: stats[i + 1]) : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Same deep violet as the bottom nav (vendor_shell.dart): the one brand accent, used for the
// featured income card; each activity count gets its own soft tint so they scan apart quickly.
const _statAccent = Color(0xFF5B21B6);

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat(this.label, this.value, this.icon, this.color);
}

/// Rounded icon chip: a soft tint of [color] behind the icon (works on light and dark surfaces).
class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _Stat stat;

  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${stat.label}: ${stat.value}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconChip(icon: stat.icon, color: stat.color),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                stat.value,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The featured card: total income, on the brand violet so it is the one thing that stands out.
class _IncomeCard extends StatelessWidget {
  final String value;

  const _IncomeCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Total income: $value',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_statAccent, Color(0xFF7C3AED)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total income',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.payments_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
