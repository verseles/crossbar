class Plugin {
  final String id;
  final String path;
  final String interpreter;
  final Duration refreshInterval;
  final bool enabled;
  final DateTime? lastRun;
  final String? lastError;

  const Plugin({
    required this.id,
    required this.path,
    required this.interpreter,
    required this.refreshInterval,
    this.enabled = true,
    this.lastRun,
    this.lastError,
  });

  factory Plugin.mock({
    String id = 'mock.10s.sh',
    String path = '/path/to/mock.10s.sh',
    String interpreter = 'bash',
    Duration refreshInterval = const Duration(seconds: 10),
  }) {
    return Plugin(
      id: id,
      path: path,
      interpreter: interpreter,
      refreshInterval: refreshInterval,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'interpreter': interpreter,
      'refreshInterval': refreshInterval.inMilliseconds,
      'enabled': enabled,
      'lastRun': lastRun?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      id: json['id'] as String,
      path: json['path'] as String,
      interpreter: json['interpreter'] as String,
      refreshInterval:
          Duration(milliseconds: json['refreshInterval'] as int),
      enabled: json['enabled'] as bool? ?? true,
      lastRun: json['lastRun'] != null
          ? DateTime.parse(json['lastRun'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }

  Plugin copyWith({
    String? id,
    String? path,
    String? interpreter,
    Duration? refreshInterval,
    bool? enabled,
    DateTime? lastRun,
    String? lastError,
  }) {
    return Plugin(
      id: id ?? this.id,
      path: path ?? this.path,
      interpreter: interpreter ?? this.interpreter,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      enabled: enabled ?? this.enabled,
      lastRun: lastRun ?? this.lastRun,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() {
    return 'Plugin(id: $id, interpreter: $interpreter, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plugin &&
        other.id == id &&
        other.path == path &&
        other.interpreter == interpreter &&
        other.refreshInterval == refreshInterval &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(id, path, interpreter, refreshInterval, enabled);
  }
}
