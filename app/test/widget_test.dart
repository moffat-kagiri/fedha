import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Basic widget test', (WidgetTester tester) async {
      // Test a simple widget
      await tester.pumpWidget(const MaterialApp(home: Text('Test')));

      // Verify the widget is rendered
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
