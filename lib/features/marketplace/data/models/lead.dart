class Lead {
  final int id;
  final int plannerUserId;
  final String plannerName;
  final int eventId;
  final String? eventName;
  // Null when the planner never set a date for this event - not mandatory.
  final DateTime? eventDate;
  final DateTime firstVisitedAt;
  final DateTime lastVisitedAt;

  const Lead({
    required this.id,
    required this.plannerUserId,
    required this.plannerName,
    required this.eventId,
    this.eventName,
    this.eventDate,
    required this.firstVisitedAt,
    required this.lastVisitedAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as int,
        plannerUserId: json['plannerUserId'] as int,
        plannerName: json['plannerName'] as String,
        eventId: json['eventId'] as int,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        firstVisitedAt: DateTime.parse(json['firstVisitedAt'] as String),
        lastVisitedAt: DateTime.parse(json['lastVisitedAt'] as String),
      );
}
