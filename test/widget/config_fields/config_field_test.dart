import 'package:crossbar/ui/widgets/config_fields/config_field.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateSettingValue', () {
    test('validates url', () {
      const setting = Setting(
        key: 'SITE_URL',
        label: 'URL',
        type: 'url',
        required: true,
      );

      expect(validateSettingValue(setting, ''), isNotNull);
      expect(validateSettingValue(setting, 'invalid-url'), isNotNull);
      expect(validateSettingValue(setting, 'https://example.com'), isNull);
    });

    test('validates datetime with explicit timezone', () {
      const setting = Setting(
        key: 'COUNTDOWN_TARGET',
        label: 'Target',
        type: 'datetime',
      );

      expect(validateSettingValue(setting, '2026-12-31T23:59:59'), isNotNull);
      expect(
        validateSettingValue(setting, '2026-12-31T23:59:59+00:00'),
        isNull,
      );
    });

    test('validates numeric ranges', () {
      const setting = Setting(
        key: 'CPU_WARN',
        label: 'Warn',
        type: 'number',
        min: 0,
        max: 100,
      );

      expect(validateSettingValue(setting, '-1'), isNotNull);
      expect(validateSettingValue(setting, '101'), isNotNull);
      expect(validateSettingValue(setting, '50'), isNull);
    });
  });

  group('ConfigField widgets', () {
    Future<void> pumpField(WidgetTester tester, Setting setting) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: ConfigField.fromSetting(
                setting: setting,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders url field', (tester) async {
      const setting = Setting(key: 'SITE_URL', label: 'URL', type: 'url');
      await pumpField(tester, setting);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);
    });

    testWidgets('renders path field with file and directory actions', (
      tester,
    ) async {
      const setting = Setting(
        key: 'TODO_FILE',
        label: 'Todo file path',
        type: 'path',
      );
      await pumpField(tester, setting);
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('Pasta'), findsOneWidget);
    });

    testWidgets('renders slider and updates value', (tester) async {
      var changedValue = '';
      const setting = Setting(
        key: 'CPU_WARN',
        label: 'Warning',
        type: 'slider',
        min: 0,
        max: 100,
        step: 5,
        defaultValue: '50',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(changedValue, isNotEmpty);
    });
  });
}
