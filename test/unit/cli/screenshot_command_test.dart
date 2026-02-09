import 'package:crossbar/cli/commands/screenshot_command.dart';
import 'package:crossbar/core/api/utils_api.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUtilsApi extends UtilsApi {
  String? result = '/tmp/screenshot.png';
  String? capturedPath;
  bool? capturedClipboard;

  @override
  Future<String?> takeScreenshot({String? path, bool toClipboard = false}) async {
    capturedPath = path;
    capturedClipboard = toClipboard;
    return result;
  }
}

void main() {
  group('ScreenshotCommand', () {
    late ScreenshotCommand command;
    late TestUtilsApi testApi;

    setUp(() {
      testApi = TestUtilsApi();
      command = ScreenshotCommand(api: testApi);
    });

    test('name is screenshot', () {
      expect(command.name, 'screenshot');
    });

    test('description is not empty', () {
      expect(command.description, isNotEmpty);
    });

    test('executes successfully and returns 0', () async {
      testApi.result = '/tmp/screenshot.png';

      final exitCode = await command.execute(['/tmp/screenshot.png']);

      expect(exitCode, 0);
      expect(testApi.capturedPath, '/tmp/screenshot.png');
      expect(testApi.capturedClipboard, false);
    });

    test('handles --clipboard flag', () async {
      testApi.result = 'clipboard';

      final exitCode = await command.execute(['--clipboard']);

      expect(exitCode, 0);
      expect(testApi.capturedPath, isNull);
      expect(testApi.capturedClipboard, true);
    });

    test('handles -c flag', () async {
      testApi.result = 'clipboard';

      final exitCode = await command.execute(['-c']);

      expect(exitCode, 0);
      expect(testApi.capturedClipboard, true);
    });

    test('handles failure and returns 1', () async {
      testApi.result = null;

      final exitCode = await command.execute([]);

      expect(exitCode, 1);
      expect(testApi.capturedPath, isNull);
      expect(testApi.capturedClipboard, false);
    });
  });
}
