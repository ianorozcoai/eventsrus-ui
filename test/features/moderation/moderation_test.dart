import 'package:eventsrus_ui/features/moderation/data/moderation_models.dart';
import 'package:eventsrus_ui/features/moderation/presentation/moderation_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report enums use the same strings as the backend', () {
    expect(ReportContentType.message.toApi(), 'MESSAGE');
    expect(ReportContentType.review.toApi(), 'REVIEW');
    expect(ReportContentType.storefront.toApi(), 'STOREFRONT');
    expect(ReportContentType.user.toApi(), 'USER');
    expect(ReportReason.fraudOrScam.toApi(), 'FRAUD_OR_SCAM');
    expect(ReportReason.values.map((r) => r.toApi()),
        ['SPAM', 'HARASSMENT', 'FRAUD_OR_SCAM', 'INAPPROPRIATE', 'OTHER']);
  });

  test('every report reason has a plain-language label', () {
    for (final reason in ReportReason.values) {
      expect(reason.label, isNotEmpty);
    }
  });

  test('BlockedUser parses the backend response', () {
    final user = BlockedUser.fromJson({
      'userId': 4,
      'displayName': 'Ben Reyes',
      'blockedAt': '2026-10-16T01:02:03Z',
    });
    expect(user.userId, 4);
    expect(user.displayName, 'Ben Reyes');
    expect(user.blockedAt.toUtc().year, 2026);
  });

  Future<void> openDialog(WidgetTester tester, void Function(ReportDraft?) onResult) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => onResult(await showReportDialog(context, subject: 'Ben')),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('report dialog: Send stays disabled until a reason is chosen', (tester) async {
    await openDialog(tester, (_) {});

    expect(find.text('Report Ben'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report')).onPressed, isNull);

    await tester.tap(find.text('Harassment or abusive language'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report')).onPressed, isNotNull);
  });

  testWidgets('report dialog returns the chosen reason and note', (tester) async {
    ReportDraft? result;
    await openDialog(tester, (draft) => result = draft);

    await tester.tap(find.text('Fraud or a scam'));
    await tester.enterText(find.byType(TextField), 'Asked me to pay outside the app');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send report'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.reason, ReportReason.fraudOrScam);
    expect(result!.details, 'Asked me to pay outside the app');
  });

  testWidgets('report dialog returns nothing when cancelled', (tester) async {
    ReportDraft? result = const ReportDraft(ReportReason.spam, null);
    await openDialog(tester, (draft) => result = draft);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
