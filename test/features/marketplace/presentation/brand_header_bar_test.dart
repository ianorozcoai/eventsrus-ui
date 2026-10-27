import 'package:eventsrus_ui/app/theme_controller.dart';
import 'package:eventsrus_ui/features/auth/state/auth_controller.dart';
import 'package:eventsrus_ui/features/marketplace/presentation/app_top_bar.dart';
import 'package:eventsrus_ui/features/marketplace/presentation/brand_header_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuth extends ChangeNotifier implements AuthController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, PreferredSizeWidget bar) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: _FakeAuth()),
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
    ],
    child: MaterialApp(home: Scaffold(appBar: bar, body: const SizedBox())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the phone header no longer has an Appearance icon: it is the first item of the three-dot menu',
      (tester) async {
    await _pump(tester, const BrandHeaderBar());

    expect(find.byTooltip('Appearance'), findsNothing);
    expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);
    expect(find.byTooltip('Log out'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Blocked users'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    // Appearance comes first.
    expect(tester.getTopLeft(find.text('Appearance')).dy, lessThan(tester.getTopLeft(find.text('Blocked users')).dy));
  });

  testWidgets('choosing Appearance from the menu opens the theme picker', (tester) async {
    await _pump(tester, const BrandHeaderBar());

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('the wide-layout top bar also keeps Appearance in its menu, not as an icon', (tester) async {
    await _pump(tester, const AppTopBar(title: 'Dashboard'));

    expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
  });
}
