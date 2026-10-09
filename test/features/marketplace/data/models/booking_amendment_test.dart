import 'package:eventsrus_ui/features/marketplace/data/models/booking_amendment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BookingAmendment.fromJson parses a full response', () {
    final amendment = BookingAmendment.fromJson({
      'id': 1,
      'bookingId': 2,
      'proposedByUserId': 3,
      'proposedByName': 'Ian Orozco',
      'newPrice': 80000.0,
      'newEventDatetime': '2026-12-25T10:00:00Z',
      'newAgreementDetails': 'Add 2 extra hours',
      'newPackageIds': [4, 5],
      'newPackageNames': ['Gold', 'Platinum'],
      'note': 'Client wants to extend the event',
      'status': 'PENDING',
      'createdAt': '2026-10-01T10:00:00Z',
      'resolvedAt': null,
    });

    expect(amendment.id, 1);
    expect(amendment.status, AmendmentStatus.pending);
    expect(amendment.newPrice, 80000.0);
    expect(amendment.newPackageNames, ['Gold', 'Platinum']);
  });

  test('every AmendmentStatus string from the backend parses correctly', () {
    expect(AmendmentStatusApi.fromApi('PENDING'), AmendmentStatus.pending);
    expect(AmendmentStatusApi.fromApi('ACCEPTED'), AmendmentStatus.accepted);
    expect(AmendmentStatusApi.fromApi('REJECTED'), AmendmentStatus.rejected);
    expect(AmendmentStatusApi.fromApi('WITHDRAWN'), AmendmentStatus.withdrawn);
  });
}
