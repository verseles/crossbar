import 'package:crossbar/cli/commands/qr_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrCommand', () {
    late QrCommand qrCommand;

    setUp(() {
      qrCommand = QrCommand();
    });

    test('name is qr', () {
      expect(qrCommand.name, 'qr');
    });

    test('generate ASCII QR code', () async {
      // We can't easily capture stdout here without a lot of boilerplate,
      // but we can test that it executes successfully.
      final exitCode = await qrCommand.execute(['https://crossbar.dev']);
      expect(exitCode, 0);
    });

    test('generate Image QR code (Base64)', () async {
      final exitCode = await qrCommand.execute(['https://crossbar.dev', '--image']);
      expect(exitCode, 0);
    });

    test('shows help for no args', () async {
      final exitCode = await qrCommand.execute([]);
      expect(exitCode, 0);
    });
  });
}
