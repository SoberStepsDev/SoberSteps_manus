import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobersteps/l10n/strings.dart';

void main() {
  testWidgets('smoke: MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SoberSteps')),
        ),
      ),
    );
    expect(find.text('SoberSteps'), findsOneWidget);
  });

  testWidgets('S.t resolves recoveryPlus for en', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (ctx) => Text(S.t(ctx, 'recoveryPlus')),
        ),
      ),
    );
    expect(find.text('Recovery+'), findsOneWidget);
  });
}
