import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/auth/state/auth_controller.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_cycle.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_history_entry.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:eventsrus_ui/features/subscription/data/play_billing_gateway.dart';
import 'package:eventsrus_ui/features/subscription/data/subscription_api.dart';
import 'package:eventsrus_ui/features/subscription/presentation/billing_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Before the purchase: no plan, no history. After it: a Google Play plan and one payment entry.
class _FakeApi implements SubscriptionApi {
  bool purchased = false;
  int historyCalls = 0;

  @override
  Future<SubscriptionStatusResponse> getStatus() async => SubscriptionStatusResponse(
        userId: 3,
        plan: purchased ? PlanTier.pro : null,
        expiresAt: purchased ? DateTime.now().add(const Duration(days: 365)) : null,
        expiringSoon: false,
        expired: false,
        billingSource: purchased ? BillingSource.googlePlay : null,
      );

  @override
  Future<List<BillingHistoryEntry>> getHistory() async {
    historyCalls++;
    if (!purchased) return [];
    return [
      BillingHistoryEntry(
        id: 1,
        plan: PlanTier.pro,
        billingSource: BillingSource.googlePlay,
        amount: 15000,
        currency: 'PHP',
        occurredAt: DateTime.now(),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGateway implements PlayBillingGateway {
  final _FakeApi api;

  _FakeGateway(this.api);

  @override
  Future<List<PlayOffer>> loadOffers(String appUserId) async =>
      const [PlayOffer(cycle: BillingCycle.annual, priceString: 'PHP 15,000.00')];

  @override
  Future<PlayPurchaseOutcome> purchase(PlayOffer offer) async {
    api.purchased = true; // Google confirmed it and our server recorded it
    return PlayPurchaseOutcome.purchased;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<void> logOut() async {}
}

class _FakeAuth extends ChangeNotifier implements AuthController {
  @override
  Future<void> applyPlanUpdate({required PlanTier? plan, DateTime? planExpiresAt}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('right after a Google Play purchase the new payment shows in the history without a manual refresh',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final api = _FakeApi();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<SubscriptionApi>.value(value: api),
        Provider<PlayBillingGateway>.value(value: _FakeGateway(api)),
        ChangeNotifierProvider<AuthController>.value(value: _FakeAuth()),
      ],
      child: const MaterialApp(home: BillingHistoryScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No billing history yet.'), findsOneWidget);
    expect(find.text('0 total'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play-subscribe')));
    await tester.pumpAndSettle();

    expect(find.text('No billing history yet.'), findsNothing);
    expect(find.text('1 total'), findsOneWidget);
    expect(find.textContaining('15000'), findsOneWidget);
  });
}
