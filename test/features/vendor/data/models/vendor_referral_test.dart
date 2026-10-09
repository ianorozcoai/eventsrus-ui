import 'package:eventsrus_ui/features/vendor/data/models/vendor_referral.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorReferral.fromJson parses a full response', () {
    final referral = VendorReferral.fromJson({
      'id': 1,
      'referredBusinessName': 'Acme Catering',
      'status': 'CONVERTED',
      'commissionAmount': 500.0,
      'createdAt': '2026-01-01T00:00:00Z',
      'convertedAt': '2026-01-05T00:00:00Z',
      'paidAt': null,
      'paymentRemarks': null,
      'paymentProofUrl': null,
    });

    expect(referral.id, 1);
    expect(referral.referredBusinessName, 'Acme Catering');
    expect(referral.status, ReferralStatus.converted);
    expect(referral.commissionAmount, 500.0);
    expect(referral.convertedAt, isNotNull);
    expect(referral.paidAt, isNull);
  });

  test('VendorReferral.fromJson parses a paid referral with payment proof', () {
    final referral = VendorReferral.fromJson({
      'id': 2,
      'referredBusinessName': 'Bloom Florals',
      'status': 'COMMISSION_PAID',
      'commissionAmount': 500.0,
      'createdAt': '2026-01-01T00:00:00Z',
      'convertedAt': '2026-01-05T00:00:00Z',
      'paidAt': '2026-01-10T00:00:00Z',
      'paymentRemarks': 'Sent via GCash',
      'paymentProofUrl': 'https://example.com/proof.png',
    });

    expect(referral.status, ReferralStatus.commissionPaid);
    expect(referral.paymentRemarks, 'Sent via GCash');
    expect(referral.paymentProofUrl, 'https://example.com/proof.png');
  });

  test('every ReferralStatus round-trips through fromApi', () {
    const values = {
      ReferralStatus.pending: 'PENDING',
      ReferralStatus.converted: 'CONVERTED',
      ReferralStatus.commissionPaid: 'COMMISSION_PAID',
    };
    for (final entry in values.entries) {
      expect(ReferralStatusApi.fromApi(entry.value), entry.key);
    }
  });

  test('VendorReferral.fromJson defaults a missing business name to empty string', () {
    final referral = VendorReferral.fromJson({
      'id': 3,
      'status': 'PENDING',
      'createdAt': '2026-01-01T00:00:00Z',
    });

    expect(referral.referredBusinessName, '');
    expect(referral.commissionAmount, isNull);
  });
}
