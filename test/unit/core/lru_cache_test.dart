import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LruCache', () {
    test('evicts least recently used entries', () {
      final cache = LruCache<String, int>(maxEntries: 3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.get('a'), 1);

      cache.put('d', 4);

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.containsKey('d'), isTrue);
    });

    test('caps size after many inserts', () {
      final cache = LruCache<int, int>(maxEntries: 100);

      for (var i = 0; i < 500; i++) {
        cache.put(i, i);
      }

      expect(cache.length, 100);
      expect(cache.evictions, 400);
    });
  });
}
