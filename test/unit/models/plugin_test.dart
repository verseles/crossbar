import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/models/plugin.dart';

void main() {
  group('Plugin', () {
    test('creates plugin with required parameters', () {
      final plugin = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      expect(plugin.id, 'test.10s.sh');
      expect(plugin.path, '/path/to/test.10s.sh');
      expect(plugin.interpreter, 'bash');
      expect(plugin.refreshInterval, const Duration(seconds: 10));
      expect(plugin.enabled, true);
      expect(plugin.lastRun, isNull);
      expect(plugin.lastError, isNull);
    });

    test('creates plugin with all parameters', () {
      final lastRun = DateTime.now();
      final plugin = Plugin(
        id: 'test.5m.py',
        path: '/path/to/test.5m.py',
        interpreter: 'python3',
        refreshInterval: const Duration(minutes: 5),
        enabled: false,
        lastRun: lastRun,
        lastError: 'Some error',
      );

      expect(plugin.id, 'test.5m.py');
      expect(plugin.enabled, false);
      expect(plugin.lastRun, lastRun);
      expect(plugin.lastError, 'Some error');
    });

    test('creates mock plugin', () {
      final plugin = Plugin.mock();

      expect(plugin.id, 'mock.10s.sh');
      expect(plugin.path, '/path/to/mock.10s.sh');
      expect(plugin.interpreter, 'bash');
      expect(plugin.refreshInterval, const Duration(seconds: 10));
    });

    test('creates mock plugin with custom values', () {
      final plugin = Plugin.mock(
        id: 'custom.1h.py',
        interpreter: 'python3',
        refreshInterval: const Duration(hours: 1),
      );

      expect(plugin.id, 'custom.1h.py');
      expect(plugin.interpreter, 'python3');
      expect(plugin.refreshInterval, const Duration(hours: 1));
    });

    test('serializes to JSON', () {
      final plugin = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final json = plugin.toJson();

      expect(json['id'], 'test.10s.sh');
      expect(json['path'], '/path/to/test.10s.sh');
      expect(json['interpreter'], 'bash');
      expect(json['refreshInterval'], 10000);
      expect(json['enabled'], true);
      expect(json['lastRun'], isNull);
      expect(json['lastError'], isNull);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'test.10s.sh',
        'path': '/path/to/test.10s.sh',
        'interpreter': 'bash',
        'refreshInterval': 10000,
        'enabled': true,
      };

      final plugin = Plugin.fromJson(json);

      expect(plugin.id, 'test.10s.sh');
      expect(plugin.path, '/path/to/test.10s.sh');
      expect(plugin.interpreter, 'bash');
      expect(plugin.refreshInterval, const Duration(seconds: 10));
      expect(plugin.enabled, true);
    });

    test('deserializes from JSON with lastRun', () {
      final lastRun = DateTime.now();
      final json = {
        'id': 'test.10s.sh',
        'path': '/path/to/test.10s.sh',
        'interpreter': 'bash',
        'refreshInterval': 10000,
        'enabled': false,
        'lastRun': lastRun.toIso8601String(),
        'lastError': 'Error message',
      };

      final plugin = Plugin.fromJson(json);

      expect(plugin.enabled, false);
      expect(plugin.lastRun, isNotNull);
      expect(plugin.lastError, 'Error message');
    });

    test('copyWith creates new instance with updated values', () {
      final plugin = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final updated = plugin.copyWith(enabled: false);

      expect(updated.id, 'test.10s.sh');
      expect(updated.enabled, false);
      expect(plugin.enabled, true);
    });

    test('copyWith preserves original values when not specified', () {
      final plugin = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
        enabled: false,
      );

      final updated = plugin.copyWith(lastError: 'New error');

      expect(updated.id, plugin.id);
      expect(updated.path, plugin.path);
      expect(updated.interpreter, plugin.interpreter);
      expect(updated.refreshInterval, plugin.refreshInterval);
      expect(updated.enabled, plugin.enabled);
      expect(updated.lastError, 'New error');
    });

    test('toString returns readable representation', () {
      final plugin = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      expect(plugin.toString(), contains('test.10s.sh'));
      expect(plugin.toString(), contains('bash'));
    });

    test('equality comparison works correctly', () {
      final plugin1 = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final plugin2 = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final plugin3 = Plugin(
        id: 'other.5m.py',
        path: '/path/to/other.5m.py',
        interpreter: 'python3',
        refreshInterval: const Duration(minutes: 5),
      );

      expect(plugin1, equals(plugin2));
      expect(plugin1, isNot(equals(plugin3)));
    });

    test('hashCode is consistent', () {
      final plugin1 = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final plugin2 = Plugin(
        id: 'test.10s.sh',
        path: '/path/to/test.10s.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      expect(plugin1.hashCode, equals(plugin2.hashCode));
    });
  });
}
