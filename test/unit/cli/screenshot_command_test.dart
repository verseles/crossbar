import 'package:crossbar/cli/commands/screenshot_command.dart';
import 'package:crossbar/core/api/utils_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockUtilsApi extends UtilsApi {
  String? result = '/tmp/screenshot.png';
  String? capturedPath;
  bool? capturedClipboard;

  @override
  Future<String?> takeScreenshot(
      {String? path, bool toClipboard = false}) async {
    capturedPath = path;
    capturedClipboard = toClipboard;
    return result;
  }
}

class _ThrowingUtilsApi extends UtilsApi {
  @override
  Future<String?> takeScreenshot(
      {String? path, bool toClipboard = false}) async {
    throw Exception('gnome-screenshot not found');
  }
}

void main() {
  group('ScreenshotCommand', () {
    late ScreenshotCommand command;
    late _MockUtilsApi mockApi;

    setUp(() {
      mockApi = _MockUtilsApi();
      command = ScreenshotCommand(api: mockApi);
    });

    test('name is screenshot', () {
      expect(command.name, 'screenshot');
    });

    test('description is not empty', () {
      expect(command.description, isNotEmpty);
    });

    test('--help returns 0', () async {
      final exitCode = await command.execute(['--help']);
      expect(exitCode, 0);
    });

    test('-h returns 0', () async {
      final exitCode = await command.execute(['-h']);
      expect(exitCode, 0);
    });

    test('saves screenshot to specified path', () async {
      mockApi.result = '/tmp/my-screenshot.png';

      final exitCode = await command.execute(['/tmp/my-screenshot.png']);

      expect(exitCode, 0);
      expect(mockApi.capturedPath, '/tmp/my-screenshot.png');
      expect(mockApi.capturedClipboard, false);
    });

    test('saves screenshot to default path when no args', () async {
      mockApi.result = '/home/user/screenshot_2026.png';

      final exitCode = await command.execute([]);

      expect(exitCode, 0);
      expect(mockApi.capturedPath, isNull);
      expect(mockApi.capturedClipboard, false);
    });

    test('handles --clipboard flag', () async {
      mockApi.result = 'clipboard';

      final exitCode = await command.execute(['--clipboard']);

      expect(exitCode, 0);
      expect(mockApi.capturedPath, isNull);
      expect(mockApi.capturedClipboard, true);
    });

    test('handles -c shorthand flag', () async {
      mockApi.result = 'clipboard';

      final exitCode = await command.execute(['-c']);

      expect(exitCode, 0);
      expect(mockApi.capturedClipboard, true);
    });

    test('returns 1 when screenshot tool not available', () async {
      mockApi.result = null;

      final exitCode = await command.execute([]);

      expect(exitCode, 1);
    });

    test('returns 1 when exception is thrown', () async {
      final throwingCommand = ScreenshotCommand(api: _ThrowingUtilsApi());

      final exitCode = await throwingCommand.execute([]);

      expect(exitCode, 1);
    });

    test('supports --json flag', () async {
      mockApi.result = '/tmp/screenshot.png';

      final exitCode = await command.execute(['--json']);

      expect(exitCode, 0);
    });

    test('supports --xml flag', () async {
      mockApi.result = '/tmp/screenshot.png';

      final exitCode = await command.execute(['--xml']);

      expect(exitCode, 0);
    });
  });
}
