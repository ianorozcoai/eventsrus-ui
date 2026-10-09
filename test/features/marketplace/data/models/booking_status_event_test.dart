import 'package:eventsrus_ui/features/marketplace/data/models/booking.dart';
import 'package:eventsrus_ui/features/marketplace/data/models/booking_status_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BookingStatusEvent.fromJson parses a full response', () {
    final event = BookingStatusEvent.fromJson({
      'id': 1,
      'fromStatus': 'PAYMENT_SUBMITTED',
      'toStatus': 'BOOKED',
      'changedByUserId': 5,
      'changedByName': 'Acme Catering',
      'reason': null,
      'createdAt': '2026-10-01T10:00:00Z',
    });

    expect(event.fromStatus, BookingStatus.paymentSubmitted);
    expect(event.toStatus, BookingStatus.booked);
    expect(event.changedByName, 'Acme Catering');
  });
}
