// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lucky_hub/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LuckyHubApp());

    // Wait for initial frame
    await tester.pump();

    // Verify that our app starts with HomePage
    // Check for AppBar title "LuckyHub"
    expect(find.text('LuckyHub'), findsWidgets);
    
    // Verify that FloatingActionButton exists (for creating new spin)
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
