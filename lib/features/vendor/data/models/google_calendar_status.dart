/// Mirrors eventsrus-backend's {@code GoogleCalendarStatusResponse}
/// field-for-field.
class GoogleCalendarStatus {
  final bool connected;
  final DateTime? connectedAt;

  const GoogleCalendarStatus({
    required this.connected,
    this.connectedAt,
  });

  factory GoogleCalendarStatus.fromJson(Map<String, dynamic> json) => GoogleCalendarStatus(
        connected: json['connected'] as bool,
        connectedAt: json['connectedAt'] == null ? null : DateTime.parse(json['connectedAt'] as String),
      );
}
