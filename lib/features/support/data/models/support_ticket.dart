import 'ticket_category.dart';
import 'ticket_status.dart';

/// Mirrors eventsrus-backend's {@code SupportTicketResponse} field-for-field.
class SupportTicket {
  final int id;
  final String subject;
  final TicketCategory category;
  final TicketStatus status;
  final int raisedByUserId;
  final String raisedByName;
  final String? relatedEventName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.raisedByUserId,
    required this.raisedByName,
    this.relatedEventName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as int,
        subject: json['subject'] as String,
        category: TicketCategoryApi.fromApi(json['category'] as String),
        status: TicketStatusApi.fromApi(json['status'] as String),
        raisedByUserId: json['raisedByUserId'] as int,
        raisedByName: json['raisedByName'] as String? ?? '',
        relatedEventName: json['relatedEventName'] as String?,
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: json['lastMessageAt'] == null ? null : DateTime.parse(json['lastMessageAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
