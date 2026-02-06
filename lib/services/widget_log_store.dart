import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:meta/meta.dart';

import 'settings_service.dart';

class WidgetLogKeys {
  static const String logKey = 'widget_debug_logs';
  static const String discardedKey = 'widget_debug_logs_discarded';
}

abstract class LogStore {
  Future<List<String>> loadLines();
  Future<String> loadRaw();
  Future<int?> loadDiscardedCount();
  Future<void> clear();
}

class FileLogStore implements LogStore {
  static const int maxLines = 200;

  @visibleForTesting
  static List<String> normalizeLines(String raw, {int limit = maxLines}) {
    final lines = raw
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length <= limit) return lines;
    return lines.sublist(lines.length - limit);
  }

  @override
  Future<List<String>> loadLines() async {
    if (!Platform.isAndroid) return [];

    final raw = await loadRaw();
    if (raw.trim().isEmpty) return [];

    return normalizeLines(raw);
  }

  @override
  Future<String> loadRaw() async {
    if (!Platform.isAndroid) return '';
    return await HomeWidget.getWidgetData<String>(WidgetLogKeys.logKey) ?? '';
  }

  @override
  Future<int?> loadDiscardedCount() async {
    if (!Platform.isAndroid) return null;
    final raw = await HomeWidget.getWidgetData<String>(
      WidgetLogKeys.discardedKey,
    );
    if (raw == null || raw.trim().isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  @override
  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<String?>(WidgetLogKeys.logKey, null);
    await HomeWidget.saveWidgetData<String?>(WidgetLogKeys.discardedKey, null);
  }
}

class MemoryLogStore implements LogStore {
  List<String> _lines = [];
  String _raw = '';
  int? _discardedCount;

  Future<void> seedFrom(LogStore source) async {
    _raw = await source.loadRaw();
    _lines = await source.loadLines();
    _discardedCount = await source.loadDiscardedCount();
  }

  @override
  Future<List<String>> loadLines() async => List<String>.from(_lines);

  @override
  Future<String> loadRaw() async => _raw;

  @override
  Future<int?> loadDiscardedCount() async => _discardedCount;

  @override
  Future<void> clear() async {
    _lines = [];
    _raw = '';
    _discardedCount = null;
  }
}

class WidgetLogStore {
  WidgetLogStore({
    SettingsService? settings,
    LogStore? fileStore,
    MemoryLogStore? memoryStore,
  }) : _settings = settings ?? SettingsService(),
       _fileStore = fileStore ?? FileLogStore(),
       _memoryStore = memoryStore ?? MemoryLogStore();

  final SettingsService _settings;
  final LogStore _fileStore;
  final MemoryLogStore _memoryStore;
  bool _memorySeeded = false;

  Future<LogStore> _activeStore() async {
    if (_settings.widgetLogStorageMode == WidgetLogStorageMode.memory) {
      if (!_memorySeeded) {
        await _memoryStore.seedFrom(_fileStore);
        _memorySeeded = true;
      }
      return _memoryStore;
    }
    return _fileStore;
  }

  Future<List<String>> loadLines() async {
    final store = await _activeStore();
    return store.loadLines();
  }

  Future<String> loadRaw() async {
    final store = await _activeStore();
    return store.loadRaw();
  }

  Future<int?> loadDiscardedCount() async {
    final store = await _activeStore();
    return store.loadDiscardedCount();
  }

  Future<void> clear() async {
    await _fileStore.clear();
    await _memoryStore.clear();
  }
}
