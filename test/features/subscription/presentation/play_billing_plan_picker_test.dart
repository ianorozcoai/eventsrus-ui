import 'package:eventsrus_ui/core/network/api_exception.dart';
import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_cycle.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:eventsrus_ui/features/subscription/data/play_billing_gateway.dart';
import 'package:eventsrus_ui/features/subscription/data/subscription_api.dart';
import 'package:eventsrus_ui/features/subscription/presentation/widgets/play_billing_plan_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

SubscriptionStatusResponse _status({PlanTier? plan, BillingSource? source, int? userId = 42}) =>
    SubscriptionStatusResponse(
      userId: userId,
      plan: plan,
      expiresAt: null,
      expiringSoon: false,
      expired: false,
      billingSource: source,
    );

class _FakeApi implements SubscriptionApi {
  final List<SubscriptionStatusResponse> responses;
  int calls = 0;
  bool failFirst;

  _FakeApi(this.responses, {this.failFirst = false});

  @override
  Future<SubscriptionStatusResponse> getStatus() async {
    calls++;
    if (failFirst && calls == 1) throw const ApiException(statusCode: 500, message: 'boom');
    return responses[(calls - 1).clamp(0, responses.length - 1)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGateway implements PlayBillingGateway {
  final List<PlayOffer> offers;
  final bool unavailable;
  PlayPurchaseOutcome outcome;
  String? loadedFor;
  PlayOffer? purchased;
  int restores = 0;

  _FakeGateway({this.offers = const [], this.unavailable = false, this.outcome = PlayPurchaseOutcome.purchased});

  @override
  Future<List<PlayOffer>> loadOffers(String appUserId) async {
    loadedFor = appUserId;
    if (unavailable) throw const PlayBillingUnavailable('no key');
    return offers;
  }

  @override
  Future<PlayPurchaseOutcome> purchase(PlayOffer offer) async {
    purchased = offer;
    return outcome;
  }

  @override
  Future<void> restore() async => restores++;

  @override
  Future<void> logOut() async {}
}

const _offers = [
  PlayOffer(cycle: BillingCycle.quarterly, priceString: '₱4,500.00'),
  PlayOffer(cycle: BillingCycle.semiAnnual, priceString: '₱7,500.00'),
  PlayOffer(cycle: BillingCycle.annual, priceString: '₱15,000.00'),
];

Future<void> _pump(
  WidgetTester tester, {
  required _FakeApi api,
  required _FakeGateway gateway,
  void Function(SubscriptionStatusResponse)? onChanged,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<SubscriptionApi>.value(value: api),
      Provider<PlayBillingGateway>.value(value: gateway),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PlayBillingPlanPicker(
            onStatusChanged: onChanged ?? (_) {},
            activationPollInterval: const Duration(milliseconds: 10),
            activationPollAttempts: 3,
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows only the store prices for the three packages, none of the web payment options', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(tester, api: _FakeApi([_status()]), gateway: gateway);

    expect(gateway.loadedFor, '42'); // app_user_id = backend user id
    expect(find.text('₱4,500.00'), findsOneWidget);
    expect(find.text('₱7,500.00'), findsOneWidget);
    expect(find.text('₱15,000.00'), findsOneWidget);
    expect(find.text('Subscribe with Google Play'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(find.textContaining('PayPal'), findsNothing);
    expect(find.textContaining('GCash'), findsNothing);
    expect(find.textContaining('website'), findsNothing);
  });

  testWidgets('already having a plan blocks buying and never queries the store', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(
      tester,
      api: _FakeApi([_status(plan: PlanTier.pro, source: BillingSource.paypal)]),
      gateway: gateway,
    );

    expect(find.text('You already have an active plan'), findsOneWidget);
    expect(find.text('Subscribe with Google Play'), findsNothing);
    expect(gateway.loadedFor, isNull);
  });

  testWidgets('a Google Play plan also offers Manage subscription', (tester) async {
    await _pump(
      tester,
      api: _FakeApi([_status(plan: PlanTier.pro, source: BillingSource.googlePlay)]),
      gateway: _FakeGateway(),
    );

    expect(find.byKey(const Key('play-manage-subscription')), findsOneWidget);
  });

  testWidgets('no usable key shows the safe not-available state', (tester) async {
    await _pump(tester, api: _FakeApi([_status()]), gateway: _FakeGateway(unavailable: true));

    expect(find.byKey(const Key('play-not-available')), findsOneWidget);
    expect(find.text('Subscribe with Google Play'), findsNothing);
  });

  testWidgets('an empty offering shows the safe not-available state', (tester) async {
    await _pump(tester, api: _FakeApi([_status()]), gateway: _FakeGateway(offers: const []));

    expect(find.byKey(const Key('play-not-available')), findsOneWidget);
  });

  testWidgets('a status without a user id cannot start a purchase', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(tester, api: _FakeApi([_status(userId: null)]), gateway: gateway);

    expect(find.byKey(const Key('play-not-available')), findsOneWidget);
    expect(gateway.loadedFor, isNull);
  });

  testWidgets('a failed status check shows a retry instead of the store', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(tester, api: _FakeApi([_status()], failFirst: true), gateway: gateway);

    expect(find.byKey(const Key('play-load-error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('play-offers')), findsOneWidget);
  });

  testWidgets('buying the selected package then waits for the backend to grant the plan', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    SubscriptionStatusResponse? changed;
    // 1: pre-purchase check, 2: first poll still none, 3: plan granted.
    final api = _FakeApi([_status(), _status(), _status(plan: PlanTier.pro, source: BillingSource.googlePlay)]);
    await _pump(tester, api: api, gateway: gateway, onChanged: (s) => changed = s);

    await tester.tap(find.byKey(const Key('play-offer-ANNUAL')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('play-subscribe')));
    await tester.pumpAndSettle();

    expect(gateway.purchased?.cycle, BillingCycle.annual);
    expect(changed?.plan, PlanTier.pro);
    expect(find.text('You already have an active plan'), findsOneWidget);
  });

  testWidgets('cancelling the Play dialog changes nothing', (tester) async {
    final gateway = _FakeGateway(offers: _offers, outcome: PlayPurchaseOutcome.cancelled);
    await _pump(tester, api: _FakeApi([_status()]), gateway: gateway);

    await tester.tap(find.byKey(const Key('play-subscribe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('play-offers')), findsOneWidget);
    expect(find.textContaining('could not be completed'), findsNothing);
  });

  testWidgets('a purchase the backend has not confirmed yet is reported honestly', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(tester, api: _FakeApi([_status()]), gateway: gateway);

    await tester.tap(find.byKey(const Key('play-subscribe')));
    await tester.pumpAndSettle();

    expect(find.textContaining('being activated'), findsOneWidget);
  });

  testWidgets('restore purchases asks the gateway', (tester) async {
    final gateway = _FakeGateway(offers: _offers);
    await _pump(tester, api: _FakeApi([_status()]), gateway: gateway);

    await tester.tap(find.byKey(const Key('play-restore')));
    await tester.pumpAndSettle();

    expect(gateway.restores, 1);
  });

  test('manage subscription opens the Google Play subscriptions page for this app', () {
    final uri = playManageSubscriptionUri();
    expect(uri.host, 'play.google.com');
    expect(uri.queryParameters['package'], 'com.eventsrus.eventsrus_ui');
    expect(uri.queryParameters['sku'], 'supplier_pro');
  });
}
