import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zqr/main.dart';

void main() {
  group('MainApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(
        const MainApp(initialDarkMode: false, initialConnected: true, prefs: null),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('renders Scaffold when connected', (tester) async {
      await tester.pumpWidget(
        const MainApp(initialDarkMode: false, initialConnected: true, prefs: null),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows HomeScreen when connected', (tester) async {
      await tester.pumpWidget(
        const MainApp(initialDarkMode: false, initialConnected: true, prefs: null),
      );
      expect(find.text('zQR'), findsOneWidget);
    });

    testWidgets('shows offline screen when not connected', (tester) async {
      await tester.pumpWidget(
        const MainApp(initialDarkMode: false, initialConnected: false, prefs: null),
      );
      expect(find.text('No Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
