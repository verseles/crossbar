// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/services/settings_service.dart';
import 'package:crossbar/ui/main_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Make all flutter_animate animations instant in tests
  Animate.restartOnHotReload = false;
  Animate.defaultDuration = Duration.zero;

  group('MainWindow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsService().resetForTesting();
    });

    testWidgets('creates MaterialApp', (tester) async {
      await tester.pumpWidget(const MainWindow());
      // Pump enough frames to settle animation controllers
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsOneWidget);

      // Dispose the widget tree so timers from AnimatedSwitcher are cleaned up
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('has correct title', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Crossbar');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('has light and dark theme', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('uses configured theme mode (default system/auto)', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does not show debug banner', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('MainScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsService().resetForTesting();
    });

    testWidgets('has NavigationRail', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NavigationRail), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('has 3 navigation destinations', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 3);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows Plugins tab by default', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Plugins'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('can navigate to Settings tab', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Appearance'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('can navigate to Marketplace tab', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Marketplace'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Crossbar Marketplace'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows Crossbar branding', (tester) async {
      await tester.pumpWidget(const MainWindow());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Crossbar'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
