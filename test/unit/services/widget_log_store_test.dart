import 'package:crossbar/services/widget_log_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileLogStore', () {
    test('limits log lines to max entries', () {
      final raw = List.generate(1000, (i) => 'line $i').join('\n');

      final lines = FileLogStore.normalizeLines(raw, limit: 200);

      expect(lines.length, 200);
      expect(lines.first, 'line 800');
      expect(lines.last, 'line 999');
    });
  });
}
