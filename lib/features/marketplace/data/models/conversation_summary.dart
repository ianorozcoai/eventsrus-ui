class ConversationSummary {
  final int id;
  final int eventId;
  final String? eventName;
  final DateTime? eventDate;
  final int otherPartyUserId;
  final String otherPartyName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationSummary({
    required this.id,
    required this.eventId,
    this.eventName,
    this.eventDate,
    required this.otherPartyUserId,
    required this.otherPartyName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        id: json['id'] as int,
        eventId: json['eventId'] as int,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        otherPartyUserId: json['otherPartyUserId'] as int,
        otherPartyName: json['otherPartyName'] as String,
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: json['lastMessageAt'] == null ? null : DateTime.parse(json['lastMessageAt'] as String),
        unreadCount: json['unreadCount'] as int,
      );
}
