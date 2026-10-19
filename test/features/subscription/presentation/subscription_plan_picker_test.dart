import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:eventsrus_ui/features/subscription/presentation/widgets/subscription_plan_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _status = SubscriptionStatusResponse(
  plan: null,
  expiresAt: null,
  expiringSoon: false,
  expired: false,
  monthlyPrice: 1500,
  quarterlyPrice: 4500,
  semiAnnualPrice: 7500,
  annualPrice: 15000,
);

Future<void> _pump(WidgetTester tester, {bool? externalPaymentsAllowed}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SubscriptionPlanPicker(
          status: _status,
          onStatusChanged: (_) {},
          externalPaymentsAllowed: externalPaymentsAllowed,
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('with external payments allowed (web-style), shows PayPal and GCash', (tester) async {
    await _pump(tester, externalPaymentsAllowed: true);

    expect(find.text('Continue with PayPal'), findsOneWidget);
    expect(find.text('Pay with GCash'), findsOneWidget);
    expect(find.byKey(const Key('no-in-app-purchase-notice')), findsNothing);
  });

  testWidgets('on Android, shows no purchase options and no pointer to other payment methods', (tester) async {
    await _pump(tester, externalPaymentsAllowed: false);

    expect(find.byKey(const Key('no-in-app-purchase-notice')), findsOneWidget);
    expect(find.text('Continue with PayPal'), findsNothing);
    expect(find.text('Debit or Credit Card'), findsNothing);
    expect(find.text('Pay with GCash'), findsNothing);
    // Google Play steering rule: nothing tells the person to pay somewhere else.
    expect(find.textContaining('website'), findsNothing);
    expect(find.textContaining('PayPal'), findsNothing);
    expect(find.textContaining('GCash'), findsNothing);
  });

  testWidgets('decides from the platform when not told: Android means no external payments', (tester) async {
    // The override must be cleared inside the test body (Flutter checks it before tear-downs run).
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      expect(externalPaymentsAllowedOnThisPlatform(), isFalse);
      await _pump(tester);
      expect(find.byKey(const Key('no-in-app-purchase-notice')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('other platforms keep external payments', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(externalPaymentsAllowedOnThisPlatform(), isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
