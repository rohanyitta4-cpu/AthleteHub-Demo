// Smoke test — does not boot the full app (Firebase, notifications, etc.).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: basic widget tree builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ok')),
        ),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
