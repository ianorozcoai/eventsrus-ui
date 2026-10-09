import 'package:eventsrus_ui/features/vendor/data/models/payment_method_status.dart';
import 'package:eventsrus_ui/features/vendor/data/models/vendor_payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorPaymentMethod.fromJson parses a full response', () {
    final method = VendorPaymentMethod.fromJson({
      'id': 9,
      'label': 'GCash',
      'qrImageUrl': 'https://cdn.example.com/qr/9.png',
      'status': 'APPROVED',
    });

    expect(method.id, 9);
    expect(method.label, 'GCash');
    expect(method.qrImageUrl, 'https://cdn.example.com/qr/9.png');
    expect(method.status, PaymentMethodStatus.approved);
  });

  test('VendorPaymentMethod.fromJson tolerates a null qrImageUrl', () {
    final method = VendorPaymentMethod.fromJson({
      'id': 9,
      'label': 'GCash',
      'qrImageUrl': null,
      'status': 'PENDING',
    });

    expect(method.qrImageUrl, isNull);
  });

  test('every PaymentMethodStatus string from the backend parses correctly', () {
    expect(PaymentMethodStatusApi.fromApi('PENDING'), PaymentMethodStatus.pending);
    expect(PaymentMethodStatusApi.fromApi('APPROVED'), PaymentMethodStatus.approved);
    expect(PaymentMethodStatusApi.fromApi('REJECTED'), PaymentMethodStatus.rejected);
  });

  test('unknown status string throws', () {
    expect(() => PaymentMethodStatusApi.fromApi('UNKNOWN'), throwsFormatException);
  });
}
