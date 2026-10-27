import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/dashboard/presentation/widgets/trial_status_card.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A new supplier: a free grant that has already reached its end date, so the grace period is the trial.
SubscriptionStatusResponse _signupTrial({required double daysLeft}) => SubscriptionStatusResponse(
      plan: PlanTier.pro,
      expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      expiringSoon: false,
      expired: false,
      inGracePeriod: true,
      graceEndsAt: DateTime.now().add(Duration(minutes: (daysLeft * 24 * 60).round())),
      billingSource: BillingSource.freeGrant,
    );

Future<void> _pump(WidgetTester tester, SubscriptionStatusResponse status, {VoidCallback? onChoosePlan}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: TrialStatusCard(status: status, onChoosePlan: onChoosePlan ?? () {}))),
  ));
}

void main() {
  testWidgets('on the first days a new supplier is told, calmly, that the free period ends and a plan is needed',
      (tester) async {
    await _pump(tester, _signupTrial(daysLeft: 29.5));

    expect(find.text('Free trial: 30 days left'), findsOneWidget);
    expect(find.textContaining('After that you need a plan'), findsOneWidget);
    expect(find.text('See plans'), findsOneWidget);
    expect(find.text('Choose a plan'), findsNothing);
    expect(find.textContaining('expired'), findsNothing);
  });

  testWidgets('in the last two weeks the card turns urgent with a Choose a plan button', (tester) async {
    await _pump(tester, _signupTrial(daysLeft: 9.5));

    expect(find.text('Free trial: 10 days left'), findsOneWidget);
    expect(find.textContaining('Choose a plan now'), findsOneWidget);
    expect(find.text('Choose a plan'), findsOneWidget);
  });

  testWidgets('the last day is spelled in the singular', (tester) async {
    await _pump(tester, _signupTrial(daysLeft: 0.4));

    expect(find.text('Free trial: 1 day left'), findsOneWidget);
  });

  testWidgets('a longer free plan (promo code) is described as free access with its end date', (tester) async {
    final promo = SubscriptionStatusResponse(
      plan: PlanTier.pro,
      expiresAt: DateTime.now().add(const Duration(days: 80, hours: 1)),
      expiringSoon: false,
      expired: false,
      billingSource: BillingSource.freeGrant,
    );
    expect(TrialStatusCard.appliesTo(promo), isTrue);

    await _pump(tester, promo);

    expect(find.text('Free access: 81 days left'), findsOneWidget);
    expect(find.textContaining('Everything is free until'), findsOneWidget);
  });

  testWidgets('tapping the button opens the plans', (tester) async {
    var opened = 0;
    await _pump(tester, _signupTrial(daysLeft: 20), onChoosePlan: () => opened++);

    await tester.tap(find.byKey(const Key('trial-choose-plan')));

    expect(opened, 1);
  });

  test('paid, expired and plan-less suppliers get no trial card', () {
    SubscriptionStatusResponse status({BillingSource? source, bool expired = false, bool grace = false, PlanTier? plan = PlanTier.pro}) =>
        SubscriptionStatusResponse(
          plan: plan,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          expiringSoon: false,
          expired: expired,
          inGracePeriod: grace,
          graceEndsAt: grace ? DateTime.now().add(const Duration(days: 5)) : null,
          billingSource: source,
        );

    expect(TrialStatusCard.appliesTo(status(source: BillingSource.googlePlay)), isFalse);
    expect(TrialStatusCard.appliesTo(status(source: BillingSource.paypal)), isFalse);
    // A lapsed PAID plan in its grace period keeps the banner's "expired" wording, not the trial card.
    expect(TrialStatusCard.appliesTo(status(source: BillingSource.googlePlay, grace: true)), isFalse);
    expect(TrialStatusCard.appliesTo(status(source: BillingSource.freeGrant, expired: true, plan: null)), isFalse);
    expect(TrialStatusCard.appliesTo(status(source: null, plan: null)), isFalse);
  });
}
