import 'package:eventsrus_ui/features/dashboard/presentation/trial_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TrialWelcomeChoice?> _open(WidgetTester tester,
    {required int? daysLeft, int? bookingsGoal, required Future<void> Function() act}) async {
  TrialWelcomeChoice? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => result = await showTrialWelcomeScreen(context, daysLeft: daysLeft, bookingsGoal: bookingsGoal),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await act();
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('a supplier on the bookings rule sees no day count, only free until the first bookings', (tester) async {
    await _open(tester, daysLeft: 365, bookingsGoal: 3, act: () async {});

    expect(find.text('Free until your first 3 bookings'), findsOneWidget);
    expect(find.text("Subscribe any time. We'll remind you before your free access ends."), findsOneWidget);
    expect(find.textContaining('day free trial'), findsNothing);
    expect(find.text('Subscribe any time before the trial ends'), findsNothing);
  });

  testWidgets('is a full page that welcomes the new supplier and names the trial length', (tester) async {
    await _open(tester, daysLeft: 30, act: () async {});

    expect(find.byKey(const Key('trial-welcome-screen')), findsOneWidget);
    expect(find.byKey(const Key('trial-welcome-logo')), findsOneWidget);
    expect(find.text('Welcome to EventsRUs!'), findsOneWidget);
    expect(find.text('30-day free trial'), findsOneWidget);
    expect(find.text('No payment is needed today'), findsOneWidget);
    expect(find.text('Subscribe now'), findsOneWidget);
    expect(find.text('Continue with free trial'), findsOneWidget);
    // A page, not a pop-up: there is no dialog on screen.
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the two buttons are the same width and have a gap between them', (tester) async {
    await _open(tester, daysLeft: 30, act: () async {});

    final subscribe = tester.getRect(find.byKey(const Key('trial-welcome-subscribe')));
    final carryOn = tester.getRect(find.byKey(const Key('trial-welcome-continue')));

    expect(subscribe.width, carryOn.width);
    expect(subscribe.left, carryOn.left);
    expect(carryOn.top - subscribe.bottom, greaterThanOrEqualTo(12));
  });

  testWidgets('Subscribe now reports that choice and closes the page', (tester) async {
    final result = await _open(tester, daysLeft: 30, act: () => tester.tap(find.byKey(const Key('trial-welcome-subscribe'))));

    expect(result, TrialWelcomeChoice.subscribeNow);
    expect(find.byKey(const Key('trial-welcome-screen')), findsNothing);
  });

  testWidgets('Continue with free trial reports that choice', (tester) async {
    final result = await _open(tester, daysLeft: 30, act: () => tester.tap(find.byKey(const Key('trial-welcome-continue'))));

    expect(result, TrialWelcomeChoice.continueTrial);
  });

  testWidgets('without a known length it still says free trial', (tester) async {
    await _open(tester, daysLeft: null, act: () async {});

    expect(find.text('Free trial'), findsOneWidget);
  });

  testWidgets('the system back button does not skip the choice', (tester) async {
    await _open(tester, daysLeft: 30, act: () async => await tester.binding.handlePopRoute());

    expect(find.byKey(const Key('trial-welcome-screen')), findsOneWidget);
  });
}
