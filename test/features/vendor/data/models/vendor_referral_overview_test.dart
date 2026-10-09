import 'package:eventsrus_ui/features/vendor/data/models/vendor_referral_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorReferralOverview.fromJson parses a full response', () {
    final overview = VendorReferralOverview.fromJson({
      'referralCode': 'ACME123',
      'referralLink': 'https://eventsrus.com/vendor/signup?ref=ACME123',
      'totalPendingCommission': 500.0,
      'totalPaidCommission': 1500.0,
      'referrals': [
        {
          'id': 1,
          'referredBusinessName': 'Acme Catering',
          'status': 'PENDING',
          'commissionAmount': null,
          'createdAt': '2026-01-01T00:00:00Z',
          'convertedAt': null,
          'paidAt': null,
          'paymentRemarks': null,
          'paymentProofUrl': null,
        },
      ],
    });

    expect(overview.referralCode, 'ACME123');
    expect(overview.totalPendingCommission, 500.0);
    expect(overview.totalPaidCommission, 1500.0);
    expect(overview.referrals, hasLength(1));
    expect(overview.referrals.single.referredBusinessName, 'Acme Catering');
  });

  test('VendorReferralOverview.fromJson defaults missing totals and referrals', () {
    final overview = VendorReferralOverview.fromJson({
      'referralCode': 'ACME123',
      'referralLink': 'https://eventsrus.com/vendor/signup?ref=ACME123',
    });

    expect(overview.totalPendingCommission, 0);
    expect(overview.totalPaidCommission, 0);
    expect(overview.referrals, isEmpty);
  });
}
