import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zqr/main.dart';

void main() {
  group('MainApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(const MainApp(initialDarkMode: false, initialConnected: true));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(const MainApp(initialDarkMode: false, initialConnected: true));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays Hello World text', (tester) async {
      await tester.pumpWidget(const MainApp(initialDarkMode: false, initialConnected: true));
      expect(find.text('Hello World!'), findsOneWidget);
    });

    testWidgets('centers the text', (tester) async {
      await tester.pumpWidget(const MainApp(initialDarkMode: false, initialConnected: true));
      final center = tester.widget<Center>(find.byType(Center));
      expect(center.child, isA<Text>());
    });
  });
}
