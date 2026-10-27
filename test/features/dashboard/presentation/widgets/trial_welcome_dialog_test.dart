import 'package:eventsrus_ui/features/dashboard/presentation/widgets/trial_welcome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TrialWelcomeChoice?> _open(WidgetTester tester, {required int? daysLeft, required Future<void> Function() tap}) async {
  TrialWelcomeChoice? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => result = await showTrialWelcomeDialog(context, daysLeft: daysLeft),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tap();
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('welcomes the new supplier, names the trial length and offers both choices', (tester) async {
    await _open(tester, daysLeft: 30, tap: () async {});

    expect(find.text('Welcome to EventsRUs!'), findsOneWidget);
    expect(find.textContaining('30-day free trial'), findsOneWidget);
    expect(find.text('Subscribe now'), findsOneWidget);
    expect(find.text('Continue with free trial'), findsOneWidget);
  });

  testWidgets('Subscribe now reports that choice', (tester) async {
    final result = await _open(tester, daysLeft: 30, tap: () => tester.tap(find.byKey(const Key('trial-welcome-subscribe'))));

    expect(result, TrialWelcomeChoice.subscribeNow);
    expect(find.byKey(const Key('trial-welcome-dialog')), findsNothing);
  });

  testWidgets('Continue with free trial reports that choice', (tester) async {
    final result = await _open(tester, daysLeft: 30, tap: () => tester.tap(find.byKey(const Key('trial-welcome-continue'))));

    expect(result, TrialWelcomeChoice.continueTrial);
  });

  testWidgets('without a known length it still says free trial', (tester) async {
    await _open(tester, daysLeft: null, tap: () async {});

    expect(find.textContaining('a free trial'), findsOneWidget);
  });

  testWidgets('tapping outside the dialog does not dismiss it: the supplier answers one way or the other', (tester) async {
    await _open(tester, daysLeft: 30, tap: () => tester.tapAt(const Offset(5, 5)));

    expect(find.byKey(const Key('trial-welcome-dialog')), findsOneWidget);
  });
}
