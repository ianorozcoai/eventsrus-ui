import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_cycle.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses a full response with every field populated', () {
    final status = SubscriptionStatusResponse.fromJson({
      'plan': 'PRO',
      'expiresAt': '2026-12-25T10:00:00Z',
      'expiringSoon': true,
      'expired': false,
      'inGracePeriod': false,
      'graceEndsAt': null,
      'monthlyPrice': 999,
      'quarterlyPrice': 2997,
      'semiAnnualPrice': 4995,
      'annualPrice': 9990,
      'billingSource': 'PAYPAL',
      'monthlyPlanId': 'P-MONTHLY',
      'quarterlyPlanId': 'P-QUARTERLY',
      'semiAnnualPlanId': 'P-SEMI',
      'annualPlanId': 'P-ANNUAL',
      'showWelcomePopup': true,
      'gcashAwaitingVerification': false,
      'gcashRejected': false,
      'gcashRejectionReason': null,
    });

    expect(status.plan, PlanTier.pro);
    expect(status.expiresAt, DateTime.parse('2026-12-25T10:00:00Z'));
    expect(status.expiringSoon, isTrue);
    expect(status.expired, isFalse);
    expect(status.monthlyPrice, 999);
    expect(status.quarterlyPrice, 2997);
    expect(status.semiAnnualPrice, 4995);
    expect(status.annualPrice, 9990);
    expect(status.billingSource, BillingSource.paypal);
    expect(status.monthlyPlanId, 'P-MONTHLY');
    expect(status.showWelcomePopup, isTrue);
  });

  test('fromJson defaults missing optional fields for a brand-new vendor', () {
    final status = SubscriptionStatusResponse.fromJson({
      'plan': null,
      'expiresAt': null,
      'expiringSoon': false,
      'expired': false,
    });

    expect(status.plan, isNull);
    expect(status.expiresAt, isNull);
    expect(status.inGracePeriod, isFalse);
    expect(status.graceEndsAt, isNull);
    expect(status.monthlyPrice, 0);
    expect(status.billingSource, isNull);
    expect(status.showWelcomePopup, isFalse);
    expect(status.gcashAwaitingVerification, isFalse);
    expect(status.gcashRejected, isFalse);
    expect(status.gcashRejectionReason, isNull);
  });

  test('fromJson parses the GCash-rejected state with its reason', () {
    final status = SubscriptionStatusResponse.fromJson({
      'plan': 'PRO',
      'expiresAt': null,
      'expiringSoon': false,
      'expired': false,
      'gcashRejected': true,
      'gcashRejectionReason': 'Screenshot did not match the expected amount.',
    });

    expect(status.gcashRejected, isTrue);
    expect(status.gcashRejectionReason, 'Screenshot did not match the expected amount.');
  });

  test('priceFor returns the matching price field for each cycle', () {
    const status = SubscriptionStatusResponse(
      plan: PlanTier.pro,
      expiresAt: null,
      expiringSoon: false,
      expired: false,
      monthlyPrice: 999,
      quarterlyPrice: 2997,
      semiAnnualPrice: 4995,
      annualPrice: 9990,
    );

    expect(status.priceFor(BillingCycle.monthly), 999);
    expect(status.priceFor(BillingCycle.quarterly), 2997);
    expect(status.priceFor(BillingCycle.semiAnnual), 4995);
    expect(status.priceFor(BillingCycle.annual), 9990);
  });
}
