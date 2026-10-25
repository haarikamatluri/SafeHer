import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/app/app.dart';
import 'package:safeher/widgets/sos_button.dart';

void main() {
  testWidgets('SafeHerApp builds and shows Splash Screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SafeHerApp());

    expect(find.text('SafeHer'), findsOneWidget);
    expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Your Safety. Our Priority.'), findsOneWidget);

    // Let the splash screen bootstrap timers complete safely
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('SosButton renders correctly with SOS label', (
    WidgetTester tester,
  ) async {
    bool triggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SosButton(
            onTrigger: () {
              triggered = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('SOS'), findsOneWidget);
    expect(
      find.text('Press and hold for 1 second\nto activate'),
      findsOneWidget,
    );
    expect(triggered, isFalse);
  });
}
