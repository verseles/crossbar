import 'package:crossbar/cli/commands/volume_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VolumeCommand', () {
    test('name should be volume', () {
      final command = VolumeCommand();
      expect(command.name, 'volume');
    });

    test('description should be descriptive', () {
      final command = VolumeCommand();
      expect(command.description, contains('Control volume'));
    });
  });
}
