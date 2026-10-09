class CalendarEntry {
  final int eventId;
  final String? eventName;
  final DateTime? eventDatetime;
  final String status;
  final List<String>? vendorNames;
  final String? plannerName;

  const CalendarEntry({
    required this.eventId,
    this.eventName,
    this.eventDatetime,
    required this.status,
    this.vendorNames,
    this.plannerName,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
        eventId: json['eventId'] as int,
        eventName: json['eventName'] as String?,
        eventDatetime: json['eventDatetime'] == null ? null : DateTime.parse(json['eventDatetime'] as String),
        status: json['status'] as String,
        vendorNames: (json['vendorNames'] as List?)?.map((e) => e as String).toList(),
        plannerName: json['plannerName'] as String?,
      );
}
