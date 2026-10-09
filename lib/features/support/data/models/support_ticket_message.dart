/// Mirrors eventsrus-backend's {@code SupportTicketMessageResponse}.
class SupportTicketMessage {
  final int id;
  final int senderUserId;
  final String senderName;
  final String body;
  final String? attachmentUrl;
  final DateTime createdAt;

  const SupportTicketMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.body,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) => SupportTicketMessage(
        id: json['id'] as int,
        senderUserId: json['senderUserId'] as int,
        senderName: json['senderName'] as String? ?? '',
        body: json['body'] as String,
        attachmentUrl: json['attachmentUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
