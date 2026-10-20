import 'package:eventsrus_ui/features/subscription/data/models/subscription_status_response.dart';
import 'package:eventsrus_ui/features/subscription/data/subscription_api.dart';
import 'package:eventsrus_ui/features/subscription/presentation/plan_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSubscriptionApi implements SubscriptionApi {
  @override
  Future<SubscriptionStatusResponse> getStatus() async => const SubscriptionStatusResponse(
        plan: null,
        expiresAt: null,
        expiringSoon: false,
        expired: false,
        monthlyPrice: 1500,
        quarterlyPrice: 4500,
        semiAnnualPrice: 7500,
        annualPrice: 15000,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, {required bool forced}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<SubscriptionApi>.value(
      value: _FakeSubscriptionApi(),
      child: MaterialApp(home: PlanSelectionScreen(forced: forced)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a supplier held on the plan screen can still reach Delete account', (tester) async {
    await _pump(tester, forced: true);

    await tester.tap(find.byKey(const Key('plan-screen-more-menu')));
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('the normal (pushed) plan screen has no extra menu: it has the shared header elsewhere', (tester) async {
    await _pump(tester, forced: false);

    expect(find.byKey(const Key('plan-screen-more-menu')), findsNothing);
  });
}
