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

    test('layout types always return null', () {
      for (final type in ['separator', 'divider', 'section', 'info']) {
        final setting = Setting(key: '_$type', label: 'L', type: type);
        expect(validateSettingValue(setting, null), isNull);
        expect(validateSettingValue(setting, ''), isNull);
        expect(validateSettingValue(setting, 'anything'), isNull);
      }
    });

    test('container types always return null', () {
      for (final type in ['collapsible', 'tabs']) {
        final setting = Setting(key: '_$type', label: 'L', type: type);
        expect(validateSettingValue(setting, null), isNull);
      }
    });

    test('validates range format', () {
      const setting = Setting(
        key: 'RANGE',
        label: 'Range',
        type: 'range',
        min: 0,
        max: 100,
      );

      expect(validateSettingValue(setting, '20,80'), isNull);
      expect(validateSettingValue(setting, '80,20'), isNotNull); // start > end
      expect(validateSettingValue(setting, 'abc,def'), isNotNull);
      expect(validateSettingValue(setting, '10'), isNotNull); // single value
      expect(validateSettingValue(setting, '-5,50'), isNotNull); // below min
      expect(validateSettingValue(setting, '10,150'), isNotNull); // above max
    });

    test('validates json format', () {
      const setting = Setting(key: 'DATA', label: 'Data', type: 'json');

      expect(validateSettingValue(setting, '{"key":"value"}'), isNull);
      expect(validateSettingValue(setting, '[1,2,3]'), isNull);
      expect(validateSettingValue(setting, 'not json'), isNotNull);
      expect(validateSettingValue(setting, ''), isNull); // empty is ok
    });

    test('hidden field has no validation', () {
      const setting = Setting(
        key: 'VER',
        label: '',
        type: 'hidden',
        defaultValue: '1.0',
      );
      expect(validateSettingValue(setting, null), isNull);
      expect(validateSettingValue(setting, '1.0'), isNull);
    });

    test('switch field basic validation', () {
      const setting = Setting(
        key: 'TOGGLE',
        label: 'Toggle',
        type: 'switch',
        required: true,
      );
      expect(validateSettingValue(setting, ''), isNotNull);
      expect(validateSettingValue(setting, 'true'), isNull);
      expect(validateSettingValue(setting, 'false'), isNull);
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

    // --- Hidden ---
    testWidgets('hidden renders zero pixels', (tester) async {
      const setting = Setting(
        key: 'VERSION',
        label: '',
        type: 'hidden',
        defaultValue: '1.0',
      );
      await pumpField(tester, setting);
      expect(find.byType(SizedBox), findsWidgets);
      // Should not render any visible text fields
      expect(find.byType(TextFormField), findsNothing);
    });

    // --- Switch ---
    testWidgets('switch renders and toggles', (tester) async {
      var val = 'false';
      const setting = Setting(
        key: 'DARK_MODE',
        label: 'Dark Mode',
        type: 'switch',
        defaultValue: 'false',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (v) => val = v,
            ),
          ),
        ),
      );

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(val, 'true');
    });

    // --- Separator ---
    testWidgets('separator renders Divider', (tester) async {
      const setting = Setting(key: '_sep', label: '', type: 'separator');
      await pumpField(tester, setting);
      expect(find.byType(Divider), findsOneWidget);
    });

    // --- Divider without label ---
    testWidgets('divider without label renders simple Divider', (tester) async {
      const setting = Setting(key: '_div', label: '', type: 'divider');
      await pumpField(tester, setting);
      expect(find.byType(Divider), findsOneWidget);
    });

    // --- Divider with label ---
    testWidgets('divider with label renders text between dividers', (
      tester,
    ) async {
      const setting = Setting(
        key: '_div',
        label: 'Visual Fields',
        type: 'divider',
      );
      await pumpField(tester, setting);
      expect(find.text('Visual Fields'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2)); // left + right
    });

    // --- Section ---
    testWidgets('section renders title and description', (tester) async {
      const setting = Setting(
        key: '_sec',
        label: 'Basic Fields',
        type: 'section',
        description: 'Common configuration options',
      );
      await pumpField(tester, setting);
      expect(find.text('Basic Fields'), findsOneWidget);
      expect(find.text('Common configuration options'), findsOneWidget);
    });

    testWidgets('section renders without description', (tester) async {
      const setting = Setting(
        key: '_sec',
        label: 'Basic Fields',
        type: 'section',
      );
      await pumpField(tester, setting);
      expect(find.text('Basic Fields'), findsOneWidget);
    });

    // --- Info ---
    testWidgets('info card renders with info format', (tester) async {
      const setting = Setting(
        key: '_info',
        label: 'Note',
        type: 'info',
        description: 'Advanced fields below.',
        format: 'info',
      );
      await pumpField(tester, setting);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Advanced fields below.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('info card renders with warning format', (tester) async {
      const setting = Setting(
        key: '_warn',
        label: 'Warning',
        type: 'info',
        format: 'warning',
      );
      await pumpField(tester, setting);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('info card renders with error format', (tester) async {
      const setting = Setting(
        key: '_err',
        label: 'Error',
        type: 'info',
        format: 'error',
      );
      await pumpField(tester, setting);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('info card renders with success format', (tester) async {
      const setting = Setting(
        key: '_ok',
        label: 'Done',
        type: 'info',
        format: 'success',
      );
      await pumpField(tester, setting);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    // --- Radio ---
    testWidgets('radio renders options and selects', (tester) async {
      var val = '';
      const setting = Setting(
        key: 'THEME',
        label: 'Theme',
        type: 'radio',
        defaultValue: 'system',
        options: [
          SelectOption(value: 'light', label: 'Light'),
          SelectOption(value: 'dark', label: 'Dark'),
          SelectOption(value: 'system', label: 'System'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (v) => val = v,
            ),
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(val, 'dark');
    });

    // --- Range ---
    testWidgets('range slider renders with labels', (tester) async {
      const setting = Setting(
        key: 'TEMP_RANGE',
        label: 'Temp Range',
        type: 'range',
        min: -10,
        max: 50,
        step: 1,
        unit: 'C',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Temp Range'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    // --- Multiselect ---
    testWidgets('multiselect renders chips and toggles', (tester) async {
      var val = '';
      const setting = Setting(
        key: 'PLATFORMS',
        label: 'Platforms',
        type: 'multiselect',
        options: [
          SelectOption(value: 'linux', label: 'Linux'),
          SelectOption(value: 'macos', label: 'macOS'),
          SelectOption(value: 'android', label: 'Android'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (v) => val = v,
            ),
          ),
        ),
      );

      expect(find.text('Linux'), findsOneWidget);
      expect(find.text('macOS'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);

      await tester.tap(find.text('Linux'));
      await tester.pumpAndSettle();
      expect(val, 'linux');

      await tester.tap(find.text('Android'));
      await tester.pumpAndSettle();
      expect(val, contains('android'));
    });

    // --- Tags ---
    testWidgets('tags field renders and accepts input', (tester) async {
      var val = '';
      const setting = Setting(
        key: 'LABELS',
        label: 'Labels',
        type: 'tags',
        max: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigField.fromSetting(
              setting: setting,
              onChanged: (v) => val = v,
            ),
          ),
        ),
      );

      expect(find.text('Labels'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);

      // Type a tag
      await tester.enterText(find.byType(TextField), 'test-tag');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(val, 'test-tag');
    });

    // --- JSON ---
    testWidgets('json field renders monospace', (tester) async {
      const setting = Setting(
        key: 'EXTRA_JSON',
        label: 'Extra Config',
        type: 'json',
        rows: 6,
      );
      await pumpField(tester, setting);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Extra Config'), findsOneWidget);
    });

    // --- Code ---
    testWidgets('code field renders monospace', (tester) async {
      const setting = Setting(
        key: 'SCRIPT',
        label: 'Lua Script',
        type: 'code',
        format: 'lua',
        rows: 8,
      );
      await pumpField(tester, setting);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Lua Script'), findsOneWidget);
    });

    // --- Icon ---
    testWidgets('icon field renders with picker trigger', (tester) async {
      const setting = Setting(
        key: 'ICON',
        label: 'Icon',
        type: 'icon',
        defaultValue: '🔥',
      );
      await pumpField(tester, setting);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
    });

    // --- Image ---
    testWidgets('image field renders with browse button', (tester) async {
      const setting = Setting(
        key: 'AVATAR',
        label: 'Avatar',
        type: 'image',
        accept: '.png,.jpg',
      );
      await pumpField(tester, setting);
      expect(find.text('Avatar'), findsOneWidget);
      expect(find.text('Choose Image'), findsOneWidget);
    });

    // --- KeyValue ---
    testWidgets('keyvalue field renders with add button', (tester) async {
      const setting = Setting(
        key: 'ENV_VARS',
        label: 'Env Vars',
        type: 'keyvalue',
      );
      await pumpField(tester, setting);
      expect(find.text('Env Vars'), findsOneWidget);
      expect(find.text('Add Pair'), findsOneWidget);
      expect(find.text('Key'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });
  });

  group('ConfigFormBuilder', () {
    testWidgets('renders mixed settings with full-width layout types', (
      tester,
    ) async {
      const settings = [
        Setting(key: '_sec', label: 'Section', type: 'section'),
        Setting(key: 'NAME', label: 'Name', type: 'text'),
        Setting(key: '_sep', label: '', type: 'separator'),
        Setting(key: 'AGE', label: 'Age', type: 'number'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConfigFormBuilder(
                settings: settings,
                values: {},
                onFieldChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('renders collapsible container', (tester) async {
      const settings = [
        Setting(
          key: '_adv',
          label: 'Advanced',
          type: 'collapsible',
          fields: [
            Setting(key: 'INNER', label: 'Inner Field', type: 'text'),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConfigFormBuilder(
                settings: settings,
                values: {},
                onFieldChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Advanced'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);

      // Expand
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(find.text('Inner Field'), findsOneWidget);
    });

    testWidgets('renders tabs container', (tester) async {
      const settings = [
        Setting(
          key: '_tabs',
          label: 'Settings Tabs',
          type: 'tabs',
          tabs: [
            SettingTab(
              label: 'General',
              fields: [
                Setting(key: 'G1', label: 'General Field', type: 'text'),
              ],
            ),
            SettingTab(
              label: 'Advanced',
              fields: [
                Setting(key: 'A1', label: 'Advanced Field', type: 'number'),
              ],
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConfigFormBuilder(
                settings: settings,
                values: {},
                onFieldChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Settings Tabs'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('General Field'), findsOneWidget);

      // Switch to Advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(find.text('Advanced Field'), findsOneWidget);
    });
  });

  group('PluginConfig model - SettingTab', () {
    test('SettingTab serializes to JSON', () {
      const tab = SettingTab(
        label: 'General',
        icon: '⚙️',
        fields: [
          Setting(key: 'NAME', label: 'Name', type: 'text'),
        ],
      );

      final json = tab.toJson();
      expect(json['label'], 'General');
      expect(json['icon'], '⚙️');
      expect((json['fields'] as List).length, 1);
    });

    test('SettingTab deserializes from JSON', () {
      final json = {
        'label': 'Advanced',
        'icon': '🔧',
        'fields': [
          {'key': 'PORT', 'label': 'Port', 'type': 'number'},
        ],
      };

      final tab = SettingTab.fromJson(json);
      expect(tab.label, 'Advanced');
      expect(tab.icon, '🔧');
      expect(tab.fields.length, 1);
      expect(tab.fields[0].key, 'PORT');
    });

    test('Setting with fields serializes correctly', () {
      const setting = Setting(
        key: '_adv',
        label: 'Advanced',
        type: 'collapsible',
        fields: [
          Setting(key: 'INNER', label: 'Inner', type: 'text'),
        ],
      );

      final json = setting.toJson();
      expect(json['fields'], isNotNull);
      expect((json['fields'] as List).length, 1);
    });

    test('Setting with tabs serializes correctly', () {
      const setting = Setting(
        key: '_tabs',
        label: 'Tabs',
        type: 'tabs',
        tabs: [
          SettingTab(
            label: 'Tab1',
            fields: [Setting(key: 'F1', label: 'F1', type: 'text')],
          ),
        ],
      );

      final json = setting.toJson();
      expect(json['tabs'], isNotNull);
      expect((json['tabs'] as List).length, 1);
    });

    test('Setting round-trip with fields and tabs', () {
      final json = {
        'key': '_container',
        'label': 'Container',
        'type': 'tabs',
        'tabs': [
          {
            'label': 'General',
            'icon': '⚙️',
            'fields': [
              {'key': 'NAME', 'label': 'Name', 'type': 'text'},
            ],
          },
          {
            'label': 'Advanced',
            'fields': [
              {
                'key': '_nested',
                'label': 'Nested',
                'type': 'collapsible',
                'fields': [
                  {'key': 'DEEP', 'label': 'Deep', 'type': 'number'},
                ],
              },
            ],
          },
        ],
      };

      final setting = Setting.fromJson(json);
      expect(setting.tabs, isNotNull);
      expect(setting.tabs!.length, 2);
      expect(setting.tabs![0].label, 'General');
      expect(setting.tabs![0].icon, '⚙️');
      expect(setting.tabs![0].fields.length, 1);
      expect(setting.tabs![1].fields[0].type, 'collapsible');
      expect(setting.tabs![1].fields[0].fields!.length, 1);

      // Round-trip
      final reJson = setting.toJson();
      final reSetting = Setting.fromJson(reJson);
      expect(reSetting.tabs!.length, 2);
      expect(reSetting.tabs![1].fields[0].fields![0].key, 'DEEP');
    });
  });
}
