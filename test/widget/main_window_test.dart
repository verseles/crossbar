import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/ui/main_window.dart';

void main() {
  group('MainWindow', () {
    testWidgets('creates MaterialApp', (tester) async {
      await tester.pumpWidget(const MainWindow());

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('has correct title', (tester) async {
      await tester.pumpWidget(const MainWindow());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Crossbar');
    });

    testWidgets('has light and dark theme', (tester) async {
      await tester.pumpWidget(const MainWindow());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });

    testWidgets('uses system theme mode', (tester) async {
      await tester.pumpWidget(const MainWindow());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('does not show debug banner', (tester) async {
      await tester.pumpWidget(const MainWindow());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
    });
  });

  group('MainScreen', () {
    testWidgets('has NavigationRail', (tester) async {
      await tester.pumpWidget(const MainWindow());

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('has 3 navigation destinations', (tester) async {
      await tester.pumpWidget(const MainWindow());

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 3);
    });

    testWidgets('shows Plugins tab by default', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump();

      expect(find.text('Plugins'), findsWidgets);
    });

    testWidgets('can navigate to Settings tab', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump();

      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('can navigate to Marketplace tab', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump();

      await tester.tap(find.text('Marketplace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Crossbar Marketplace'), findsOneWidget);
    });

    testWidgets('shows Crossbar branding', (tester) async {
      await tester.pumpWidget(const MainWindow());

      expect(find.text('Crossbar'), findsWidgets);
    });
  });
}
