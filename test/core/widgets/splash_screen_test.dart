import 'package:eventsrus_ui/core/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the branded logo on a white background, mid-entrance-animation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    // Deliberately not pumpAndSettle()'d past this point - the logo must be
    // in the tree immediately on the first frame (FadeTransition/
    // ScaleTransition still mount their child right away, just at opacity/
    // scale 0), not only once the entrance animation finishes.
    expect(find.byType(SvgPicture), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
  });

  testWidgets('entrance animation settles to fully visible, normal scale', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpAndSettle();

    // Scoped to the ancestors of the logo specifically - Flutter's own
    // machinery (e.g. page-route transitions) can add its own
    // FadeTransition/ScaleTransition elsewhere in the tree, so a bare
    // find.byType(...) here is ambiguous.
    final logo = find.byType(SvgPicture);
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: logo, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1.0);

    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: logo, matching: find.byType(ScaleTransition)).first,
    );
    expect(scale.scale.value, 1.0);
  });
}
