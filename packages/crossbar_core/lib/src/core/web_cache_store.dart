import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/lru_cache.dart';

class WebCacheMetrics {
  int hits = 0;
  int misses = 0;
  int diskReads = 0;
  int diskWrites = 0;
  int bytesWritten = 0;
  int bytesSaved = 0;

  int get totalRequests => hits + misses;
  double get hitRate => totalRequests == 0 ? 0 : hits / totalRequests;

  WebCacheMetrics snapshot() {
    return WebCacheMetrics()
      ..hits = hits
      ..misses = misses
      ..diskReads = diskReads
      ..diskWrites = diskWrites
      ..bytesWritten = bytesWritten
      ..bytesSaved = bytesSaved;
  }
}

class WebCacheDiskStats {
  WebCacheDiskStats({
    required this.totalBytes,
    required this.fileCount,
    required this.compressedFiles,
    required this.uncompressedFiles,
  });

  final int totalBytes;
  final int fileCount;
  final int compressedFiles;
  final int uncompressedFiles;
}

class WebCacheStore {
  WebCacheStore({
    required String Function() baseDirProvider,
    required String Function(String) hash,
    required String Function(String) sanitizePluginId,
    int maxEntries = 100,
    Duration maxAge = const Duration(days: 7),
    int compressionThresholdBytes = 10 * 1024 * 1024,
  })  : _baseDirProvider = baseDirProvider,
        _hash = hash,
        _sanitizePluginId = sanitizePluginId,
        _maxEntries = maxEntries,
        _maxAge = maxAge,
        _compressionThresholdBytes = compressionThresholdBytes,
        _memoryCache = LruCache<String, dynamic>(maxEntries: maxEntries);

  final String Function() _baseDirProvider;
  final String Function(String) _hash;
  final String Function(String) _sanitizePluginId;
  final int _maxEntries;
  Duration _maxAge;
  final int _compressionThresholdBytes;
  final LruCache<String, dynamic> _memoryCache;
  final WebCacheMetrics _metrics = WebCacheMetrics();
  final GZipCodec _gzip = GZipCodec();

  bool _compressionEvaluated = false;
  bool _compressionEnabled = false;

  int get maxEntries => _maxEntries;
  int get memoryEntryCount => _memoryCache.length;
  int get evictions => _memoryCache.evictions;
  bool get compressionEnabled => _compressionEnabled;
  Duration get maxAge => _maxAge;

  WebCacheMetrics get metrics => _metrics.snapshot();

  void resetMetrics() {
    _metrics.hits = 0;
    _metrics.misses = 0;
    _metrics.diskReads = 0;
    _metrics.diskWrites = 0;
    _metrics.bytesWritten = 0;
    _metrics.bytesSaved = 0;
  }

  void resetMemory() {
    clearMemory();
    resetMetrics();
  }

  void setMaxAge(Duration value) {
    _maxAge = value;
  }

  void clearMemory() {
    _memoryCache.clear();
  }

  void clearAll({String? pluginId}) {
    clearMemory();
    final baseDir = _baseCacheDir();
    final root = Directory(baseDir);
    if (!root.existsSync()) return;

    if (pluginId == null || pluginId.isEmpty) {
      root.deleteSync(recursive: true);
      return;
    }

    final dir = Directory(_cacheDirForPlugin(pluginId));
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  dynamic read(String pluginId, String cacheKey) {
    final cached = _memoryCache.get(cacheKey);
    if (cached != null) {
      _metrics.hits++;
      return cached;
    }

    final existing = _findExistingCacheFile(pluginId, cacheKey);
    if (existing == null || !existing.existsSync()) {
      _metrics.misses++;
      return null;
    }

    if (_isExpired(existing)) {
      _safeDelete(existing);
      _metrics.misses++;
      return null;
    }

    final value = _readFile(existing);
    if (value == null) {
      _safeDelete(existing);
      _metrics.misses++;
      return null;
    }

    _metrics.hits++;
    _metrics.diskReads++;
    _memoryCache.put(cacheKey, value);

    if (_compressionEnabled && !_isCompressed(existing)) {
      _writeCompressedCopy(pluginId, cacheKey, value, existing);
    }

    return value;
  }

  void write(
    String pluginId,
    String cacheKey,
    dynamic value, {
    bool persist = true,
  }) {
    _memoryCache.put(cacheKey, value);
    if (!persist) return;

    _ensureCompressionEvaluated();
    final payload = jsonEncode(value);
    final bytes = utf8.encode(payload);

    if (_compressionEnabled) {
      final compressed = _gzip.encode(bytes);
      final file = _cacheFile(pluginId, cacheKey, compressed: true);
      _writeFile(file, compressed);
      _metrics.diskWrites++;
      _metrics.bytesWritten += compressed.length;
      _metrics.bytesSaved +=
          (bytes.length - compressed.length).clamp(0, bytes.length);
      _removeUncompressed(pluginId, cacheKey);
      return;
    }

    final file = _cacheFile(pluginId, cacheKey, compressed: false);
    _writeFile(file, bytes);
    _metrics.diskWrites++;
    _metrics.bytesWritten += bytes.length;
  }

  void pruneStale({String? pluginId}) {
    final root = Directory(_cacheRoot());
    if (!root.existsSync()) return;

    if (pluginId != null && pluginId.isNotEmpty) {
      _pruneDir(Directory(_cacheDirForPlugin(pluginId)));
      return;
    }

    for (final entity in root.listSync()) {
      if (entity is Directory) {
        _pruneDir(entity);
      }
    }
  }

  Future<WebCacheDiskStats> getDiskStats({String? pluginId}) async {
    final root = Directory(
      pluginId == null || pluginId.isEmpty
          ? _cacheRoot()
          : _cacheDirForPlugin(pluginId),
    );

    if (!root.existsSync()) {
      return WebCacheDiskStats(
        totalBytes: 0,
        fileCount: 0,
        compressedFiles: 0,
        uncompressedFiles: 0,
      );
    }

    var totalBytes = 0;
    var fileCount = 0;
    var compressedFiles = 0;
    var uncompressedFiles = 0;

    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      totalBytes += stat.size;
      fileCount++;
      if (_isCompressed(entity)) {
        compressedFiles++;
      } else {
        uncompressedFiles++;
      }
    }

    return WebCacheDiskStats(
      totalBytes: totalBytes,
      fileCount: fileCount,
      compressedFiles: compressedFiles,
      uncompressedFiles: uncompressedFiles,
    );
  }

  File? findExistingCacheFile(String pluginId, String cacheKey) {
    return _findExistingCacheFile(pluginId, cacheKey);
  }

  void _pruneDir(Directory dir) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (_isExpired(entity)) {
        _safeDelete(entity);
      }
    }
  }

  void _ensureCompressionEvaluated() {
    if (_compressionEvaluated) return;
    _compressionEvaluated = true;

    final root = Directory(_cacheRoot());
    if (!root.existsSync()) return;

    var totalSize = 0;
    try {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      }
    } catch (_) {
      return;
    }

    if (totalSize > _compressionThresholdBytes) {
      _compressionEnabled = true;
    }
  }

  String _cacheRoot() => path.join(_baseCacheDir(), 'crossbar_web_cache');

  String _cacheDirForPlugin(String pluginId) {
    final safeId = _sanitizePluginId(pluginId.isEmpty ? 'unknown' : pluginId);
    return path.join(_cacheRoot(), safeId);
  }

  String _baseCacheDir() {
    final base = _baseDirProvider();
    if (base.isEmpty) return Directory.systemTemp.path;
    return base;
  }

  File _cacheFile(String pluginId, String cacheKey,
      {required bool compressed}) {
    final dir = Directory(_cacheDirForPlugin(pluginId));
    final fileName = '${_hash(cacheKey)}${compressed ? '.json.gz' : '.json'}';
    return File(path.join(dir.path, fileName));
  }

  File? _findExistingCacheFile(String pluginId, String cacheKey) {
    final compressed = _cacheFile(pluginId, cacheKey, compressed: true);
    if (compressed.existsSync()) return compressed;
    final plain = _cacheFile(pluginId, cacheKey, compressed: false);
    if (plain.existsSync()) return plain;
    return null;
  }

  bool _isExpired(File file) {
    try {
      final modified = file.lastModifiedSync();
      return DateTime.now().difference(modified) > _maxAge;
    } catch (_) {
      return true;
    }
  }

  dynamic _readFile(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final decoded = _isCompressed(file) ? _gzip.decode(bytes) : bytes;
      final payload = utf8.decode(decoded);
      return jsonDecode(payload);
    } catch (_) {
      return null;
    }
  }

  void _writeFile(File file, List<int> bytes) {
    try {
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes, flush: true);
    } catch (_) {
      // Ignore cache write errors
    }
  }

  bool _isCompressed(File file) => file.path.endsWith('.json.gz');

  void _removeUncompressed(String pluginId, String cacheKey) {
    final plain = _cacheFile(pluginId, cacheKey, compressed: false);
    if (plain.existsSync()) {
      _safeDelete(plain);
    }
  }

  void _writeCompressedCopy(
    String pluginId,
    String cacheKey,
    dynamic value,
    File original,
  ) {
    try {
      final payload = jsonEncode(value);
      final bytes = utf8.encode(payload);
      final compressed = _gzip.encode(bytes);
      final file = _cacheFile(pluginId, cacheKey, compressed: true);
      _writeFile(file, compressed);
      _metrics.diskWrites++;
      _metrics.bytesWritten += compressed.length;
      _metrics.bytesSaved +=
          (bytes.length - compressed.length).clamp(0, bytes.length);
      _safeDelete(original);
    } catch (_) {
      // Ignore compression failures
    }
  }

  void _safeDelete(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // Ignore delete errors
    }
  }
}
