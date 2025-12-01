import 'dart:async';
import 'dart:io';

typedef FileChangeCallback = void Function(String path, FileSystemEvent event);

class FileWatcher {
  final Map<String, Timer> _debouncer = {};
  final Duration _debounceDelay;
  StreamSubscription<FileSystemEvent>? _subscription;
  final FileChangeCallback? onFileChanged;

  FileWatcher({
    Duration debounceDelay = const Duration(seconds: 1),
    this.onFileChanged,
  }) : _debounceDelay = debounceDelay;

  static const List<String> _watchedExtensions = [
    '.sh',
    '.py',
    '.js',
    '.dart',
    '.go',
    '.rs',
    '.json',
  ];

  void watch(Directory directory) {
    if (!directory.existsSync()) {
      return;
    }

    _subscription = directory.watch(recursive: true).listen((event) {
      final path = event.path;

      if (_shouldWatch(path)) {
        _debounceReload(path, event);
      }
    });
  }

  bool _shouldWatch(String path) {
    final ext = path.substring(path.lastIndexOf('.'));
    return _watchedExtensions.contains(ext.toLowerCase());
  }

  void _debounceReload(String path, FileSystemEvent event) {
    _debouncer[path]?.cancel();

    _debouncer[path] = Timer(_debounceDelay, () {
      _debouncer.remove(path);
      onFileChanged?.call(path, event);
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;

    for (final timer in _debouncer.values) {
      timer.cancel();
    }
    _debouncer.clear();
  }

  void dispose() {
    stop();
  }
}
