import 'package:flutter/material.dart';

class CalendarMarker {
  final String label;
  final Color color;

  const CalendarMarker({required this.label, required this.color});
}

/// A real month-grid calendar — reusable presentational widget shared by
/// the planner and vendor calendar screens. Weeks are laid out as equally
/// sized rows filling all available height (never scrolls, never
/// overflows), with each marker rendered as a visible colored pill inside
/// its day cell — not just a dot.
class MonthCalendarGrid extends StatefulWidget {
  final Map<DateTime, List<CalendarMarker>> markersByDay;

  /// Called with a day that has at least one marker, when that day's cell
  /// is tapped - lets the caller show its own details popup (this widget
  /// only knows markers' label/color, not the richer entry each one came
  /// from, so it reports the day and leaves rendering details to the
  /// caller, same reasoning as why markersByDay itself is caller-built).
  final void Function(DateTime day)? onDaySelected;

  const MonthCalendarGrid({super.key, required this.markersByDay, this.onDaySelected});

  @override
  State<MonthCalendarGrid> createState() => _MonthCalendarGridState();
}

class _MonthCalendarGridState extends State<MonthCalendarGrid> {
  late DateTime _visibleMonth;

  static const _weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  static const _monthLabels = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  List<CalendarMarker> _markersFor(DateTime day) {
    return widget.markersByDay[DateTime(day.year, day.month, day.day)] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // DateTime.weekday: Mon=1..Sun=7 — convert to a Sun=0..Sat=6 leading offset.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final weekCount = totalCells ~/ 7;
    final today = DateTime.now();

    final weeks = <List<int?>>[];
    for (var w = 0; w < weekCount; w++) {
      final week = <int?>[];
      for (var d = 0; d < 7; d++) {
        final cellIndex = w * 7 + d;
        final dayNumber = cellIndex - leadingBlanks + 1;
        week.add(dayNumber >= 1 && dayNumber <= daysInMonth ? dayNumber : null);
      }
      weeks.add(week);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${_monthLabels[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.outline,
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const Divider(height: 20),
          Expanded(
            child: Column(
              children: weeks
                  .map(
                    (week) => Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: week
                            .map(
                              (dayNumber) => Expanded(
                                child: dayNumber == null
                                    ? const SizedBox.shrink()
                                    : _DayCell(
                                        dayNumber: dayNumber,
                                        isToday: _visibleMonth.year == today.year &&
                                            _visibleMonth.month == today.month &&
                                            dayNumber == today.day,
                                        markers: _markersFor(DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber)),
                                        onTap: widget.onDaySelected == null
                                            ? null
                                            : () => widget.onDaySelected!(
                                                DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber)),
                                      ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final bool isToday;
  final List<CalendarMarker> markers;
  final VoidCallback? onTap;

  const _DayCell({required this.dayNumber, required this.isToday, required this.markers, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: markers.isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday ? colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ClipRect(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final marker in markers.take(2))
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: marker.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          marker.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, color: marker.color, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (markers.length > 2)
                      Text(
                        '+${markers.length - 2} more',
                        style: TextStyle(fontSize: 8, color: colorScheme.outline),
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
