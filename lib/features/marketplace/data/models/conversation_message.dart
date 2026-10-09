class ConversationMessage {
  final int id;
  final int senderUserId;
  final String senderName;
  final DateTime? targetDate;
  final String body;
  final String? attachmentUrl;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    this.targetDate,
    required this.body,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
        id: json['id'] as int,
        senderUserId: json['senderUserId'] as int,
        senderName: json['senderName'] as String,
        targetDate: json['targetDate'] == null ? null : DateTime.parse(json['targetDate'] as String),
        body: json['body'] as String,
        attachmentUrl: json['attachmentUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
