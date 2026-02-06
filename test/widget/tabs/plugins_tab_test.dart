import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/l10n/app_localizations.dart';
import 'package:crossbar/services/refresh_service.dart';
import 'package:crossbar/ui/tabs/plugins_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PluginsTab', () {
    late Directory tempDir;
    late PluginManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('plugins_tab_test_');
      manager = PluginManager();
      manager.customPluginsDirectory = tempDir.path;
      manager.clear();
      RefreshService().resetForTesting();

      await _createPlugin(tempDir, 'alpha.1s.lua');
      await _createPlugin(tempDir, 'beta.10s.lua');
      await _createPlugin(tempDir, 'gamma.off.5s.lua');
      await RefreshService().discoverPlugins();
    });

    tearDown(() {
      manager.customPluginsDirectory = null;
      manager.clear();
      RefreshService().resetForTesting();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('filters enabled plugins only', (tester) async {
      await tester.pumpWidget(_wrap(const PluginsTab()));
      await tester.runAsync(() async {
        await RefreshService().discoverPlugins();
      });
      await _waitForPlugin(tester, 'Alpha');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PluginsTab)),
      )!;

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, l10n.enabled));
      await _pumpForLoad(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Gamma'), findsNothing);
    });

    testWidgets('sorts plugins by alphabetical order', (tester) async {
      await tester.pumpWidget(_wrap(const PluginsTab()));
      await tester.runAsync(() async {
        await RefreshService().discoverPlugins();
      });
      await _waitForPlugin(tester, 'Alpha');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PluginsTab)),
      )!;

      await tester.tap(find.widgetWithText(Chip, l10n.enabledFirst));
      await _pumpForLoad(tester);
      await tester.tap(find.text(l10n.alphabetical));
      await _pumpForLoad(tester);

      final alphaPos = tester.getTopLeft(find.text('Alpha')).dy;
      final betaPos = tester.getTopLeft(find.text('Beta')).dy;
      final gammaPos = tester.getTopLeft(find.text('Gamma')).dy;

      expect(alphaPos, lessThan(betaPos));
      expect(betaPos, lessThan(gammaPos));
    });

    testWidgets('filters by search query', (tester) async {
      await tester.pumpWidget(_wrap(const PluginsTab()));
      await tester.runAsync(() async {
        await RefreshService().discoverPlugins();
      });
      await _waitForPlugin(tester, 'Alpha');

      await tester.enterText(find.byType(TextField), 'beta');
      await _pumpForLoad(tester);

      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsNothing);
    });

    testWidgets('disables plugin via switch', (tester) async {
      await tester.pumpWidget(_wrap(const PluginsTab()));
      await tester.runAsync(() async {
        await RefreshService().discoverPlugins();
      });
      await _waitForPlugin(tester, 'Alpha');

      final alphaCard = find.ancestor(
        of: find.text('Alpha'),
        matching: find.byType(Card),
      );
      final alphaSwitch = find.descendant(
        of: alphaCard.first,
        matching: find.byType(Switch),
      );

      expect(alphaSwitch, findsOneWidget);

      await tester.tap(alphaSwitch);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await _pumpForLoad(tester);

      final disabledFile = File(path.join(tempDir.path, 'alpha.1s.off.lua'));
      expect(disabledFile.existsSync(), isTrue);
    });
  });
}

Future<void> _createPlugin(Directory dir, String name) async {
  final file = File(path.join(dir.path, name));
  file.writeAsStringSync('print("ok")\n');
  await Process.run('chmod', ['+x', file.path]);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<void> _pumpForLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _waitForPlugin(WidgetTester tester, String name) async {
  var attempts = 0;
  while (attempts < 10) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await _pumpForLoad(tester);
    if (find.text(name).evaluate().isNotEmpty) {
      return;
    }
    attempts++;
  }
  await tester.pump(const Duration(milliseconds: 200));
}
