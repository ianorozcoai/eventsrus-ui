import 'package:eventsrus_ui/features/marketplace/data/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Booking.fromJson parses a full response', () {
    final booking = Booking.fromJson({
      'id': 1,
      'eventId': 2,
      'eventName': 'Wedding',
      'vendorUserId': 3,
      'vendorBusinessName': 'Acme Catering',
      'vendorSlug': 'acme-catering',
      'cancellationPolicyUrl': null,
      'refundTermsUrl': null,
      'plannerUserId': 4,
      'plannerName': 'Ian Orozco',
      'quotationId': 9,
      'price': 75000.0,
      'eventDatetime': '2026-12-25T10:00:00Z',
      'agreementDetails': 'Full day coverage',
      'status': 'BOOKED',
      'proposedAt': '2026-10-01T10:00:00Z',
      'respondedAt': '2026-10-02T10:00:00Z',
      'paymentScreenshotUrl': null,
      'paymentScreenshotUploadedAt': null,
      'paymentAcknowledgedAt': null,
      'paymentRejectionReason': null,
      'invoiceUrl': 'https://example.com/invoice.pdf',
      'invoiceUploadedAt': '2026-10-03T10:00:00Z',
      'cancelledAt': null,
      'cancellationReason': null,
      'cancelledByUserId': null,
      'hasPendingAmendment': true,
      'canReview': false,
      'reviewId': null,
      'reviewRating': null,
      'reviewComment': null,
    });

    expect(booking.id, 1);
    expect(booking.status, BookingStatus.booked);
    expect(booking.quotationId, 9);
    expect(booking.hasPendingAmendment, isTrue);
    expect(booking.isTerminal, isFalse);
  });

  test('every BookingStatus round-trips through toApi/fromApi', () {
    for (final status in BookingStatus.values) {
      expect(BookingStatusApi.fromApi(status.toApi()), status);
    }
  });

  test('isTerminal is true only for declined/cancelled', () {
    final base = {
      'id': 1,
      'eventId': 1,
      'vendorUserId': 1,
      'plannerUserId': 1,
      'proposedAt': '2026-01-01T00:00:00Z',
    };
    expect(
      Booking.fromJson({...base, 'status': 'DECLINED'}).isTerminal,
      isTrue,
    );
    expect(
      Booking.fromJson({...base, 'status': 'CANCELLED'}).isTerminal,
      isTrue,
    );
    expect(
      Booking.fromJson({...base, 'status': 'BOOKED'}).isTerminal,
      isFalse,
    );
  });
}
