import 'package:eventsrus_ui/features/marketplace/data/models/quotation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Quotation.fromJson parses a full response', () {
    final quotation = Quotation.fromJson({
      'id': 10,
      'eventId': 3,
      'eventName': 'Birthday Bash',
      'vendorUserId': 5,
      'vendorBusinessName': 'Acme Catering',
      'vendorSlug': 'acme-catering',
      'cancellationPolicyUrl': null,
      'refundTermsUrl': null,
      'plannerUserId': 7,
      'plannerName': 'Ian Orozco',
      'targetDate': '2026-12-01',
      'requestMessage': 'Need catering for 100 guests',
      'status': 'QUOTE_SENT',
      'version': 2,
      'quotedAmount': 50000.5,
      'pdfUrl': 'https://example.com/quote.pdf',
      'respondedAt': '2026-10-01T10:00:00Z',
      'acceptedAt': null,
      'paymentScreenshotUrl': null,
      'paymentRejectionReason': null,
      'createdAt': '2026-09-30T10:00:00Z',
      'packageIds': [1, 2],
      'packageNames': ['Silver', 'Gold'],
      'declinedAt': null,
      'referenceImageUrls': ['https://example.com/ref.png'],
      'responseImageUrls': [],
    });

    expect(quotation.id, 10);
    expect(quotation.status, QuotationStatus.quoteSent);
    expect(quotation.version, 2);
    expect(quotation.quotedAmount, 50000.5);
    expect(quotation.packageNames, ['Silver', 'Gold']);
    expect(quotation.isOpenNegotiation, isTrue);
  });

  test('every QuotationStatus round-trips through toApi/fromApi', () {
    for (final status in QuotationStatus.values) {
      expect(QuotationStatusApi.fromApi(status.toApi()), status);
    }
  });

  test('isOpenNegotiation is false once accepted or closed out', () {
    for (final status in [
      QuotationStatus.quoteAccepted,
      QuotationStatus.pendingDeposit,
      QuotationStatus.paymentReview,
      QuotationStatus.paymentRejected,
      QuotationStatus.booked,
      QuotationStatus.declined,
      QuotationStatus.cancelled,
    ]) {
      final quotation = Quotation(
        id: 1,
        eventId: 1,
        vendorUserId: 1,
        plannerUserId: 1,
        status: status,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(quotation.isOpenNegotiation, isFalse, reason: 'expected $status to not be open negotiation');
    }
  });
}
