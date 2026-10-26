import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:flutter_test/flutter_test.dart';

SubscriptionStatusResponse _graceStatus(BillingSource source, DateTime graceEndsAt) => SubscriptionStatusResponse(
      plan: PlanTier.pro,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 5)),
      expiringSoon: false,
      expired: false,
      inGracePeriod: true,
      graceEndsAt: graceEndsAt,
      billingSource: source,
    );

void main() {
  test('a free grant in its grace period is a free trial, with the days left rounded up', () {
    final status = _graceStatus(BillingSource.freeGrant, DateTime.now().add(const Duration(days: 29, hours: 3)));

    expect(status.onFreeTrial, isTrue);
    expect(status.freeTrialDaysLeft, 30);
  });

  test('the last hours of the trial still count as one day', () {
    final status = _graceStatus(BillingSource.freeGrant, DateTime.now().add(const Duration(hours: 2)));

    expect(status.freeTrialDaysLeft, 1);
  });

  test('a lapsed paid plan in grace is NOT a free trial, it keeps the expired wording', () {
    for (final source in [BillingSource.googlePlay, BillingSource.paypal, BillingSource.gcash]) {
      final status = _graceStatus(source, DateTime.now().add(const Duration(days: 10)));

      expect(status.onFreeTrial, isFalse, reason: '$source');
      expect(status.freeTrialDaysLeft, isNull, reason: '$source');
    }
  });

  test('an active free promo plan (not yet in grace) is not reported as the grace-period trial', () {
    final status = SubscriptionStatusResponse(
      plan: PlanTier.pro,
      expiresAt: DateTime.now().add(const Duration(days: 40)),
      expiringSoon: false,
      expired: false,
      billingSource: BillingSource.freeGrant,
    );

    expect(status.onFreeTrial, isFalse);
  });
}
