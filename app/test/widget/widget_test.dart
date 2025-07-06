// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fedha/main.dart';

void main() {
  testWidgets('Profile creation flow', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const FedhaApp());

    // Tap "Create Business Profile" button
    await tester.tap(find.text('Create Business Profile'));
    await tester.pumpAndSettle();

    // Enter PIN
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Verify UUID is displayed
    expect(find.textContaining(RegExp(r'biz_')), findsOneWidget);
  });
}
// This test verifies the profile creation flow by simulating user interactions
// such as tapping buttons and entering text. It checks that the UUID is