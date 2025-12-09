import 'package:crossbar/services/widget_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetService Tests', () {
    late WidgetService service;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      log.clear();

      const MethodChannel('com.verseles.crossbar/widget')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      service = WidgetService();
      service.forcePlatformCheck = true;
    });

    tearDown(() {
      const MethodChannel('com.verseles.crossbar/widget').setMockMethodCallHandler(null);
    });

    test('finishConfiguration saves to prefs and notifies native', () async {
      await service.init();

      await service.finishConfiguration(123, ['pluginA', 'pluginB']);

      // Check Prefs
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('crossbar_widget_config_123'), ['pluginA', 'pluginB']);
      expect(prefs.getStringList('crossbar_active_widgets'), ['123']);

      // Check Native Call
      // Expect configurationFinished call
      expect(log.any((c) => c.method == 'configurationFinished'), isTrue);
      final configCall = log.firstWhere((c) => c.method == 'configurationFinished');
      expect(configCall.arguments['widgetId'], 123);
      expect(configCall.arguments['success'], true);

      // Expect updateWidgets call
      // expect(log.any((c) => c.method == 'updateWidgets'), isTrue);
    });

    test('cancelConfiguration notifies native', () async {
      await service.init();
      await service.cancelConfiguration(456);

      expect(log.last.method, 'configurationFinished');
      expect(log.last.arguments, {'widgetId': 456, 'success': false});
    });
  });
}
