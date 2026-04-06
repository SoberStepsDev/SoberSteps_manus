import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sobersteps/main.dart' as app;

/// Device / desktop smoke: full init (Firebase, Supabase, providers) + first frames.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E smoke: app boots and navigates off splash', (tester) async {
    app.main();

    // main() awaits Firebase / Supabase / notifications before runApp.
    var foundApp = false;
    for (var i = 0; i < 600; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(MaterialApp).evaluate().isNotEmpty) {
        foundApp = true;
        break;
      }
    }
    expect(foundApp, isTrue, reason: 'MaterialApp did not mount within 30s');

    // Splash shows branding briefly.
    expect(find.text('SoberSteps'), findsOneWidget);

    // Advance frames until splash navigates (async prefs + 800ms delay).
    var leftSplash = false;
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('SoberSteps').evaluate().isEmpty) {
        leftSplash = true;
        break;
      }
    }
    expect(leftSplash, isTrue, reason: 'Expected navigation off splash within ~20s');

    expect(tester.takeException(), isNull);
  });
}
