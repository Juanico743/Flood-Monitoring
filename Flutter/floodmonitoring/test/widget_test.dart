import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// 1. Change this to your MapScreen path
import 'package:floodmonitoring/pages/map.dart';

void main() {
  testWidgets('App loads map screen', (WidgetTester tester) async {
    // 2. Build our app using MapScreen instead of Dashboard
    await tester.pumpWidget(MaterialApp(home: MapScreen()));

    // 3. You can verify if the Map is present (adjust based on your actual UI text)
    // For example, if your map has a "Search" or "Alerts" text:
    // expect(find.text('Alerts'), findsOneWidget);
  });
}