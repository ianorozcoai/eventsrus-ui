class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final bool read;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        relatedEntityType: json['relatedEntityType'] as String?,
        relatedEntityId: json['relatedEntityId'] as int?,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
