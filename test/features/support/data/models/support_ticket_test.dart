import 'package:eventsrus_ui/features/support/data/models/support_ticket.dart';
import 'package:eventsrus_ui/features/support/data/models/ticket_category.dart';
import 'package:eventsrus_ui/features/support/data/models/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SupportTicket.fromJson parses a full response', () {
    final ticket = SupportTicket.fromJson({
      'id': 42,
      'subject': 'Payment did not go through',
      'category': 'BILLING',
      'status': 'OPEN',
      'raisedByUserId': 7,
      'raisedByName': 'Ian Orozco',
      'relatedEventName': null,
      'lastMessagePreview': 'Payment did not go through',
      'lastMessageAt': '2026-10-01T10:00:00Z',
      'createdAt': '2026-10-01T10:00:00Z',
    });

    expect(ticket.id, 42);
    expect(ticket.category, TicketCategory.billing);
    expect(ticket.status, TicketStatus.open);
  });

  test('every TicketCategory round-trips through toApi/fromApi', () {
    for (final category in TicketCategory.values) {
      expect(TicketCategoryApi.fromApi(category.toApi()), category);
    }
  });

  test('every TicketStatus string from the backend parses correctly', () {
    expect(TicketStatusApi.fromApi('OPEN'), TicketStatus.open);
    expect(TicketStatusApi.fromApi('IN_PROGRESS'), TicketStatus.inProgress);
    expect(TicketStatusApi.fromApi('RESOLVED'), TicketStatus.resolved);
    expect(TicketStatusApi.fromApi('CLOSED'), TicketStatus.closed);
  });
}
