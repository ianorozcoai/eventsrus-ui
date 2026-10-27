import 'package:eventsrus_ui/features/auth/state/auth_controller.dart';
import 'package:eventsrus_ui/features/terms/data/terms_api.dart';
import 'package:eventsrus_ui/features/terms/presentation/terms_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeTermsApi implements TermsApi {
  bool accepted;
  bool failStatus;
  bool failAccept;
  int acceptCalls = 0;

  _FakeTermsApi({this.accepted = false, this.failStatus = false, this.failAccept = false});

  @override
  Future<TermsStatus> getStatus() async {
    if (failStatus) throw Exception('offline');
    return TermsStatus(accepted: accepted, currentVersion: '2026-10-27');
  }

  @override
  Future<TermsStatus> accept() async {
    acceptCalls++;
    if (failAccept) throw Exception('offline');
    accepted = true;
    return const TermsStatus(accepted: true, currentVersion: '2026-10-27');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth extends ChangeNotifier implements AuthController {
  int logouts = 0;

  @override
  Future<void> logout() async => logouts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeAuth> _pump(WidgetTester tester, _FakeTermsApi api) async {
  final auth = _FakeAuth();
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<TermsApi>.value(value: api),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const MaterialApp(home: TermsGate(child: Scaffold(body: Text('the real app')))),
  ));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('someone who already accepted goes straight to the app', (tester) async {
    await _pump(tester, _FakeTermsApi(accepted: true));

    expect(find.text('the real app'), findsOneWidget);
    expect(find.byKey(const Key('terms-acceptance-screen')), findsNothing);
  });

  testWidgets('someone who has not accepted sees the full-page Terms first, not the app', (tester) async {
    await _pump(tester, _FakeTermsApi());

    expect(find.byKey(const Key('terms-acceptance-screen')), findsOneWidget);
    expect(find.text('Please review our Terms'), findsOneWidget);
    expect(find.text('the real app'), findsNothing);
    expect(find.text('I agree and continue'), findsOneWidget);
    expect(find.text('Decline and log out'), findsOneWidget);
    expect(find.byKey(const Key('terms-read-terms')), findsOneWidget);
    expect(find.byKey(const Key('terms-read-privacy')), findsOneWidget);
  });

  testWidgets('the two buttons are the same width with a gap between them', (tester) async {
    await _pump(tester, _FakeTermsApi());

    final agree = tester.getRect(find.byKey(const Key('terms-agree')));
    final decline = tester.getRect(find.byKey(const Key('terms-decline')));

    expect(agree.width, decline.width);
    expect(decline.top - agree.bottom, greaterThanOrEqualTo(12));
  });

  testWidgets('agreeing records the acceptance and opens the app', (tester) async {
    final api = _FakeTermsApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(const Key('terms-agree')));
    await tester.pumpAndSettle();

    expect(api.acceptCalls, 1);
    expect(find.text('the real app'), findsOneWidget);
  });

  testWidgets('declining logs the person out and records nothing', (tester) async {
    final api = _FakeTermsApi();
    final auth = await _pump(tester, api);

    await tester.tap(find.byKey(const Key('terms-decline')));
    await tester.pumpAndSettle();

    expect(auth.logouts, 1);
    expect(api.acceptCalls, 0);
  });

  testWidgets('if saving the answer fails the person stays on the screen with a clear message', (tester) async {
    await _pump(tester, _FakeTermsApi(failAccept: true));

    await tester.tap(find.byKey(const Key('terms-agree')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('terms-acceptance-screen')), findsOneWidget);
    expect(find.textContaining('could not save your answer'), findsOneWidget);
    expect(find.text('the real app'), findsNothing);
  });

  testWidgets('if the check itself cannot be made the person is let through, not locked out', (tester) async {
    await _pump(tester, _FakeTermsApi(failStatus: true));

    expect(find.text('the real app'), findsOneWidget);
  });
}
