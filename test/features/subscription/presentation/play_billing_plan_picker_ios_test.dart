import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_cycle.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:eventsrus_ui/features/subscription/data/play_billing_gateway.dart';
import 'package:eventsrus_ui/features/subscription/data/store_info.dart';
import 'package:eventsrus_ui/features/subscription/data/subscription_api.dart';
import 'package:eventsrus_ui/features/subscription/presentation/widgets/play_billing_plan_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

SubscriptionStatusResponse _status({PlanTier? plan, BillingSource? source}) => SubscriptionStatusResponse(
      userId: 42,
      plan: plan,
      expiresAt: null,
      expiringSoon: false,
      expired: false,
      billingSource: source,
    );

class _Api implements SubscriptionApi {
  final SubscriptionStatusResponse status;
  _Api(this.status);

  @override
  Future<SubscriptionStatusResponse> getStatus() async => status;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements PlayBillingGateway {
  final bool unavailable;
  _Gateway({this.unavailable = false});

  @override
  Future<List<PlayOffer>> loadOffers(String appUserId) async {
    if (unavailable) throw const PlayBillingUnavailable('no key');
    return const [
      PlayOffer(cycle: BillingCycle.quarterly, priceString: 'P4,500.00'),
      PlayOffer(cycle: BillingCycle.semiAnnual, priceString: 'P7,500.00'),
      PlayOffer(cycle: BillingCycle.annual, priceString: 'P15,000.00'),
    ];
  }

  @override
  Future<PlayPurchaseOutcome> purchase(PlayOffer offer) async => PlayPurchaseOutcome.purchased;

  @override
  Future<void> restore() async {}

  @override
  Future<void> logOut() async {}
}

Future<void> _pump(WidgetTester tester, SubscriptionStatusResponse status, {bool unavailable = false}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<SubscriptionApi>.value(value: _Api(status)),
      Provider<PlayBillingGateway>.value(value: _Gateway(unavailable: unavailable)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PlayBillingPlanPicker(onStatusChanged: (_) {}, store: StoreInfo.apple),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('iOS shows the three store prices, Apple renewal terms and Terms/Privacy links', (tester) async {
    await _pump(tester, _status());

    expect(find.text('P4,500.00'), findsOneWidget);
    expect(find.text('P15,000.00'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.textContaining('Apple ID'), findsOneWidget);
    expect(find.byKey(const Key('play-terms-link')), findsOneWidget);
    expect(find.byKey(const Key('play-privacy-link')), findsOneWidget);
    // Nothing on iOS mentions Google Play, PayPal, GCash or paying on the website.
    expect(find.textContaining('Google Play'), findsNothing);
    expect(find.textContaining('PayPal'), findsNothing);
    expect(find.textContaining('GCash'), findsNothing);
    expect(find.textContaining('website'), findsNothing);
  });

  testWidgets('iOS not-available state names the App Store, not Google Play', (tester) async {
    await _pump(tester, _status(), unavailable: true);

    expect(find.byKey(const Key('play-not-available')), findsOneWidget);
    expect(find.textContaining('App Store'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsNothing);
  });

  testWidgets('an App Store plan is not sold again and offers Manage subscription', (tester) async {
    await _pump(tester, _status(plan: PlanTier.pro, source: BillingSource.appStore));

    expect(find.text('You already have an active plan'), findsOneWidget);
    expect(find.textContaining('billed through App Store'), findsOneWidget);
    expect(find.byKey(const Key('play-manage-subscription')), findsOneWidget);
  });

  testWidgets('a Google Play plan seen from iOS is not sold again and has no manage button here', (tester) async {
    await _pump(tester, _status(plan: PlanTier.pro, source: BillingSource.googlePlay));

    expect(find.text('You already have an active plan'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsWidgets);
    expect(find.byKey(const Key('play-manage-subscription')), findsNothing);
  });
}
