import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/data/booking_api.dart';
import '../../marketplace/data/calendar_api.dart';
import '../../marketplace/data/models/booking.dart';
import '../../marketplace/data/models/calendar_entry.dart';
import '../../marketplace/presentation/month_calendar_grid.dart';

class PlannerCalendarScreen extends StatefulWidget {
  const PlannerCalendarScreen({super.key});

  @override
  State<PlannerCalendarScreen> createState() => _PlannerCalendarScreenState();
}

class _PlannerCalendarScreenState extends State<PlannerCalendarScreen> {
  List<CalendarEntry>? _entries;
  List<Booking> _pending = [];
  bool _loading = true;
  int? _respondingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await context.read<CalendarApi>().plannerCalendar();
      final bookings = await context.read<BookingApi>().listForPlanner();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _pending = bookings.where((b) => b.status == BookingStatus.proposed).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(Booking booking, bool approve) async {
    setState(() => _respondingId = booking.id);
    try {
      if (approve) {
        await context.read<BookingApi>().approve(booking.id);
      } else {
        await context.read<BookingApi>().decline(booking.id);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not respond to booking')));
    } finally {
      if (mounted) setState(() => _respondingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final entries = _entries ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    const bookedColor = Colors.green;
    const plannedColor = Colors.orange;

    final markersByDay = <DateTime, List<CalendarMarker>>{};
    for (final entry in entries) {
      if (entry.eventDatetime == null) continue;
      final d = entry.eventDatetime!.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      markersByDay.putIfAbsent(key, () => []).add(CalendarMarker(
            label: entry.eventName ?? 'Event #${entry.eventId}',
            color: entry.status == 'BOOKED' ? bookedColor : plannedColor,
          ));
    }

    final sortedEntries = [...entries]..sort((a, b) {
        if (a.eventDatetime == null && b.eventDatetime == null) return 0;
        if (a.eventDatetime == null) return 1;
        if (b.eventDatetime == null) return -1;
        return a.eventDatetime!.compareTo(b.eventDatetime!);
      });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('My Calendar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_pending.isNotEmpty) ...[
            Text(
              'Pending Approval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._pending.map(
              (booking) => Card(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.vendorBusinessName ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(booking.eventName ?? 'Event #${booking.eventId}'),
                      const SizedBox(height: 4),
                      if (booking.price != null) Text('₱${booking.price!.toStringAsFixed(0)}'),
                      if (booking.agreementDetails != null) ...[
                        const SizedBox(height: 4),
                        Text(booking.agreementDetails!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _respondingId == booking.id ? null : () => _respond(booking, false),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _respondingId == booking.id ? null : () => _respond(booking, true),
                              child: _respondingId == booking.id
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Row(
            children: [
              _LegendDot(color: plannedColor, label: 'Planned'),
              SizedBox(width: 16),
              _LegendDot(color: bookedColor, label: 'Booked'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final calendar = MonthCalendarGrid(markersByDay: markersByDay);
                final agenda = _AgendaList(entries: sortedEntries);

                if (!isWide) {
                  return Column(
                    children: [
                      SizedBox(height: 420, child: calendar),
                      const SizedBox(height: 16),
                      Expanded(child: agenda),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: calendar),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: agenda),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
          Text('My Events', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Quick lookup for your saved events.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text('No saved events yet.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final booked = entry.status == 'BOOKED';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (booked ? Colors.green : Colors.orange).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (entry.eventDatetime != null)
                              Text(
                                '${entry.eventDatetime!.month}/${entry.eventDatetime!.day}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            const Spacer(),
                            Text(
                              booked ? 'BOOKED' : 'PLANNED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: booked ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.eventName ?? 'Event #${entry.eventId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          entry.vendorNames != null && entry.vendorNames!.isNotEmpty
                              ? entry.vendorNames!.join(', ')
                              : 'No vendors booked yet',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
}
