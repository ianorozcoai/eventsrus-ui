import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../dashboard/presentation/widgets/plan_status_banner.dart';
import '../data/models/vendor_dashboard.dart';
import '../data/vendor_dashboard_api.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  VendorDashboard? _dashboard;
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

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PlanStatusBanner(),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatTile(
                  label: 'NEW LEADS',
                  value: '${dashboard.newLeadsCount}',
                  icon: Icons.person_search_outlined,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'NEW MESSAGES',
                  value: '${dashboard.newMessagesCount}',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'NEW QUOTATIONS',
                  value: '${dashboard.newQuotationsCount}',
                  icon: Icons.request_quote_outlined,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'NEW BOOKINGS',
                  value: '${dashboard.newBookingsCount}',
                  icon: Icons.event_available_outlined,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'UPCOMING EVENTS',
                  value: '${dashboard.upcomingEventsCount}',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'TOTAL INCOME',
                  value: '₱${dashboard.totalIncome.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  label: 'CANCELLATIONS',
                  value: '${dashboard.cancellationsCount}',
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Same deep violet as the bottom nav (vendor_shell.dart) - one consistent
// brand accent rather than a different color per card, kept deliberately
// restrained for a "simple but elegant" look.
const _statAccent = Color(0xFF5B21B6);

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(icon, size: 22, color: _statAccent),
        ],
      ),
    );
  }
}
