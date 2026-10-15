import 'package:eventsrus_ui/core/network/api_exception.dart';
import 'package:eventsrus_ui/features/profile/presentation/delete_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  bool isVendor = false,
  Future<DateTime> Function()? requestDeletion,
  Future<void> Function()? onFinished,
}) {
  return MaterialApp(
    home: DeleteAccountView(
      isVendor: isVendor,
      requestDeletion: requestDeletion ?? () async => DateTime(2026, 11, 16),
      onFinished: onFinished ?? () async {},
    ),
  );
}

// A tall test screen, so the whole form is on screen without scrolling.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
}

Finder get _deleteButton => find.widgetWithText(FilledButton, 'Delete my account');

void main() {
  group('isDeletionConfirmed', () {
    test('needs both the tick and the word DELETE', () {
      expect(isDeletionConfirmed(typedText: 'DELETE', accepted: true), isTrue);
      expect(isDeletionConfirmed(typedText: ' delete ', accepted: true), isTrue);
      expect(isDeletionConfirmed(typedText: 'DELETE', accepted: false), isFalse);
      expect(isDeletionConfirmed(typedText: 'DELET', accepted: true), isFalse);
      expect(isDeletionConfirmed(typedText: '', accepted: true), isFalse);
    });
  });

  test('formatDeletionDate writes day, short month, year', () {
    expect(formatDeletionDate(DateTime(2026, 11, 16)), '16 Nov 2026');
  });

  testWidgets('delete button stays disabled until the box is ticked and DELETE is typed', (tester) async {
    await _pump(tester,_wrap());
    expect(tester.widget<FilledButton>(_deleteButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(_deleteButton).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(_deleteButton).onPressed, isNotNull);
  });

  testWidgets('shows the supplier-only text and the cancel-instead hint only for vendors', (tester) async {
    await _pump(tester,_wrap(isVendor: false));
    expect(find.textContaining('Planning to come back'), findsNothing);

    await _pump(tester,_wrap(isVendor: true));
    expect(find.textContaining('Planning to come back'), findsOneWidget);
    expect(find.textContaining('supplier storefront'), findsOneWidget);
  });

  testWidgets('shows the plain reason when the backend blocks the deletion', (tester) async {
    var finished = false;
    await _pump(tester,_wrap(
      requestDeletion: () async =>
          throw const ApiException(statusCode: 409, message: 'You have an active subscription. Please cancel it first.'),
      onFinished: () async => finished = true,
    ));
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(_deleteButton);
    await tester.tap(_deleteButton);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('active subscription'), findsOneWidget);
    expect(finished, isFalse);
  });

  testWidgets('on success shows the scheduled date, then finishes (logs out) after OK', (tester) async {
    var finished = false;
    await _pump(tester,_wrap(onFinished: () async => finished = true));
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(_deleteButton);
    await tester.tap(_deleteButton);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('16 Nov 2026'), findsOneWidget);
    expect(finished, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });
}
