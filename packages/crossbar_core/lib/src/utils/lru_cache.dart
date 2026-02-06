import 'dart:collection';

class LruCache<K, V> {
  LruCache({required int maxEntries}) : _maxEntries = maxEntries;

  final int _maxEntries;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();
  int _evictions = 0;

  int get maxEntries => _maxEntries;
  int get length => _entries.length;
  int get evictions => _evictions;

  bool containsKey(K key) => _entries.containsKey(key);

  V? get(K key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_entries.containsKey(key)) {
      _entries.remove(key);
    }
    _entries[key] = value;
    _evictIfNeeded();
  }

  void remove(K key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
    _evictions = 0;
  }

  Iterable<K> get keys => _entries.keys;

  void _evictIfNeeded() {
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
      _evictions++;
    }
  }
}
