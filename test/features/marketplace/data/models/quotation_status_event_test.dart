import 'package:eventsrus_ui/features/marketplace/data/models/quotation.dart';
import 'package:eventsrus_ui/features/marketplace/data/models/quotation_status_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuotationStatusEvent.fromJson parses a STATUS_CHANGE entry', () {
    final event = QuotationStatusEvent.fromJson({
      'id': 1,
      'entryType': 'STATUS_CHANGE',
      'fromStatus': 'REQUEST_FOR_QUOTE',
      'toStatus': 'QUOTE_SENT',
      'changedByUserId': 5,
      'changedByName': 'Acme Catering',
      'reason': null,
      'pdfUrl': 'https://example.com/quote.pdf',
      'version': 1,
      'quotedAmount': 50000.0,
      'targetDate': null,
      'packageNames': ['Silver'],
      'paymentScreenshotUrl': null,
      'invoiceUrl': null,
      'attachmentUrl': null,
      'attachmentFileType': null,
      'createdAt': '2026-10-01T10:00:00Z',
    });

    expect(event.entryType, HistoryEntryType.statusChange);
    expect(event.fromStatus, QuotationStatus.requestForQuote);
    expect(event.toStatus, QuotationStatus.quoteSent);
    expect(event.quotedAmount, 50000.0);
  });

  test('QuotationStatusEvent.fromJson parses an ATTACHMENT entry', () {
    final event = QuotationStatusEvent.fromJson({
      'id': 2,
      'entryType': 'ATTACHMENT',
      'fromStatus': null,
      'toStatus': null,
      'changedByUserId': 5,
      'changedByName': 'Acme Catering',
      'reason': 'Updated floor plan',
      'pdfUrl': null,
      'version': null,
      'quotedAmount': null,
      'targetDate': null,
      'packageNames': [],
      'paymentScreenshotUrl': null,
      'invoiceUrl': null,
      'attachmentUrl': 'https://example.com/floorplan.pdf',
      'attachmentFileType': 'PDF',
      'createdAt': '2026-10-02T10:00:00Z',
    });

    expect(event.entryType, HistoryEntryType.attachment);
    expect(event.fromStatus, isNull);
    expect(event.attachmentFileType, 'PDF');
  });
}
