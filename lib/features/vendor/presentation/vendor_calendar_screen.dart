import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/calendar_api.dart';
import '../../marketplace/data/models/calendar_entry.dart';
import '../../marketplace/presentation/month_calendar_grid.dart';
import '../data/google_calendar_api.dart';
import '../data/models/google_calendar_status.dart';

class VendorCalendarScreen extends StatefulWidget {
  const VendorCalendarScreen({super.key});

  @override
  State<VendorCalendarScreen> createState() => _VendorCalendarScreenState();
}

class _VendorCalendarScreenState extends State<VendorCalendarScreen> {
  List<CalendarEntry>? _entries;
  bool _loading = true;

  GoogleCalendarStatus? _googleStatus;
  bool _googleStatusLoading = true;
  bool _googleActionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadGoogleStatus();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await context.read<CalendarApi>().vendorCalendar();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGoogleStatus() async {
    setState(() => _googleStatusLoading = true);
    try {
      final status = await context.read<GoogleCalendarApi>().getStatus();
      if (!mounted) return;
      setState(() {
        _googleStatus = status;
        _googleStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _googleStatusLoading = false);
    }
  }

  Future<void> _connectGoogleCalendar() async {
    setState(() => _googleActionInProgress = true);
    try {
      await context.read<GoogleCalendarApi>().connectNative();
      if (mounted) await _loadGoogleStatus();
    } on GoogleCalendarCancelledException {
      // Vendor dismissed the consent screen - not an error, nothing to show.
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _googleActionInProgress = false);
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Calendar?'),
        content: const Text(
          'Your confirmed bookings will stop syncing until you reconnect.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, Disconnect')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _googleActionInProgress = true);
    try {
      await context.read<GoogleCalendarApi>().disconnect();
      if (!mounted) return;
      await _loadGoogleStatus();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _googleActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final entries = _entries ?? [];

    final markersByDay = <DateTime, List<CalendarMarker>>{};
    for (final entry in entries) {
      if (entry.eventDatetime == null) continue;
      final d = entry.eventDatetime!.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      markersByDay.putIfAbsent(key, () => []).add(CalendarMarker(
            label: entry.eventName ?? 'Event #${entry.eventId}',
            color: statusColor(entry.status),
          ));
    }

    // Dated (booked/cancelled) entries first, then undated inquiries.
    final sortedEntries = [...entries]..sort((a, b) {
        if (a.eventDatetime == null && b.eventDatetime == null) return 0;
        if (a.eventDatetime == null) return 1;
        if (b.eventDatetime == null) return -1;
        return a.eventDatetime!.compareTo(b.eventDatetime!);
      });

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calendar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendDot(color: kCalendarBookedColor, label: 'Booked'),
                _LegendDot(color: kCalendarPendingColor, label: 'Pending / In Progress'),
                _LegendDot(color: kCalendarCancelledColor, label: 'Cancelled'),
              ],
            ),
            const SizedBox(height: 12),
            _GoogleCalendarStatusBar(
              status: _googleStatus,
              loading: _googleStatusLoading,
              actionInProgress: _googleActionInProgress,
              onConnect: _connectGoogleCalendar,
              onDisconnect: _disconnectGoogleCalendar,
              onRefresh: _loadGoogleStatus,
            ),
            const SizedBox(height: 12),
            TabBar(
              tabs: [
                const Tab(icon: Icon(Icons.list_alt_outlined), text: 'All Events'),
                const Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _AgendaList(entries: sortedEntries),
                  MonthCalendarGrid(
                    markersByDay: markersByDay,
                    onDaySelected: (day) => _showDayEntries(context, day, entries),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same bucket colors as eventsrus-web's FullCalendar event coloring
/// (calendar.html) - BOOKED and CANCELLED are literal statuses, everything
/// else (INQUIRY, or any live, non-terminal QuotationStatus) buckets into
/// "pending" exactly as web's toFullCalendarEventsJson does.
Color statusColor(String status) {
  if (status == 'BOOKED') return kCalendarBookedColor;
  if (status == 'CANCELLED') return kCalendarCancelledColor;
  return kCalendarPendingColor;
}

const kCalendarBookedColor = Color(0xFF059669);
const kCalendarPendingColor = Color(0xFF8E70C1);
const kCalendarCancelledColor = Color(0xFFEF4444);

const _monthNamesFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Tapped a day on the Calendar tab's month grid - lists every entry that
/// day (there can be more than the 2 the grid cell itself has room to
/// show), matching FullCalendar's own "click a day to see everything on
/// it" behavior on web.
void _showDayEntries(BuildContext context, DateTime day, List<CalendarEntry> entries) {
  final dayEntries = entries.where((e) {
    final d = e.eventDatetime?.toLocal();
    return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
  }).toList();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${_monthNamesFull[day.month - 1]} ${day.day}, ${day.year}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: dayEntries.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final entry = dayEntries[index];
            final color = statusColor(entry.status);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.eventName ?? 'Event #${entry.eventId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(entry.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                if (entry.plannerName != null) Text(entry.plannerName!),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
      ],
    ),
  );
}

class _GoogleCalendarStatusBar extends StatelessWidget {
  final GoogleCalendarStatus? status;
  final bool loading;
  final bool actionInProgress;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final Future<void> Function() onRefresh;

  const _GoogleCalendarStatusBar({
    required this.status,
    required this.loading,
    required this.actionInProgress,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }

    final connected = status?.connected ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (connected ? Colors.green : colorScheme.surfaceContainerHighest).withValues(alpha: connected ? 0.15 : 1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connected ? Icons.check_circle : Icons.cancel_outlined,
                size: 14,
                color: connected ? Colors.green.shade800 : colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Google Calendar Connected' : 'Google Calendar Not Connected',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: connected ? Colors.green.shade800 : colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (actionInProgress)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else if (connected)
          TextButton(onPressed: onDisconnect, child: const Text('Disconnect'))
        else
          TextButton(onPressed: onConnect, child: const Text('Connect')),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: 'Refresh status',
          onPressed: actionInProgress ? null : onRefresh,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AgendaList extends StatelessWidget {
  final List<CalendarEntry> entries;

  const _AgendaList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Chip(label: Text('${entries.length} total')),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text('No event dates yet. Your booked and pending dates will show up here.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final color = statusColor(entry.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (entry.eventDatetime != null)
                              Text(
                                _formatDateTime(entry.eventDatetime!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            const Spacer(),
                            Text(
                              entry.status,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.eventName ?? 'Event #${entry.eventId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(entry.plannerName ?? '', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year} - $hour:$minute $ampm';
  }
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
