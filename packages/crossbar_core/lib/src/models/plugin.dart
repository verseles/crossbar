import 'plugin_config.dart';

class PluginVariant {
  const PluginVariant({
    required this.path,
    required this.interpreter,
    required this.enabled,
  });

  factory PluginVariant.fromJson(Map<String, dynamic> json) {
    return PluginVariant(
      path: json['path'] as String,
      interpreter: json['interpreter'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final String path;
  final String interpreter;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'interpreter': interpreter,
      'enabled': enabled,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PluginVariant &&
        other.path == path &&
        other.interpreter == interpreter &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(path, interpreter, enabled);
}

class Plugin {
  const Plugin({
    required this.id,
    required this.path,
    required this.interpreter,
    required this.refreshInterval,
    this.customTitle,
    this.enabled = true,
    this.lastRun,
    this.lastError,
    this.config,
    this.variants = const [],
  });

  factory Plugin.mock({
    String id = 'mock.10s.sh',
    String path = '/path/to/mock.10s.sh',
    String interpreter = 'bash',
    Duration refreshInterval = const Duration(seconds: 10),
    String? customTitle,
    PluginConfig? config,
    List<PluginVariant> variants = const [],
  }) {
    return Plugin(
      id: id,
      path: path,
      interpreter: interpreter,
      refreshInterval: refreshInterval,
      customTitle: customTitle,
      config: config,
      variants: variants,
    );
  }

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      id: json['id'] as String,
      path: json['path'] as String,
      interpreter: json['interpreter'] as String,
      refreshInterval: Duration(milliseconds: json['refreshInterval'] as int),
      enabled: json['enabled'] as bool? ?? true,
      customTitle: json['customTitle'] as String?,
      lastRun: json['lastRun'] != null
          ? DateTime.parse(json['lastRun'] as String)
          : null,
      lastError: json['lastError'] as String?,
      config: json['config'] != null
          ? PluginConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => PluginVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String path;
  final String interpreter;
  final Duration refreshInterval;
  final String? customTitle;
  final bool enabled;
  final DateTime? lastRun;
  final String? lastError;
  final PluginConfig? config;
  final List<PluginVariant> variants;

  /// Returns true if the plugin has a configuration schema defined.
  bool get hasConfig => config != null && config!.settings.isNotEmpty;

  /// Returns true if the plugin requires configuration before running.
  bool get requiresConfig {
    final mode = config?.configRequired;
    return mode == 'required' || mode == 'always' || mode == 'first_run';
  }

  /// Returns true when configuration should be requested on every run.
  bool get requiresConfigAlways => config?.configRequired == 'always';

  /// Returns true when configuration should be requested only for first run.
  bool get requiresConfigFirstRun => config?.configRequired == 'first_run';

  /// Human-friendly display name for UI and widgets.
  ///
  /// Uses config.name when available, otherwise derives from the plugin id.
  String get displayName {
    final override = customTitle?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final configured = config?.name.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return _formatDisplayName(id);
  }

  static String _formatDisplayName(String pluginId) {
    var normalized = pluginId.replaceFirst('.off.', '.');

    final match = RegExp(r'^(.+?)\.(?:\d+(?:\.\d+)?)[smh]\.').firstMatch(
      normalized,
    );
    if (match != null) {
      normalized = match.group(1) ?? normalized;
    } else {
      final firstDot = normalized.indexOf('.');
      if (firstDot > 0) {
        normalized = normalized.substring(0, firstDot);
      }
    }

    final words = normalized
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(
          (word) => '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .toList();

    return words.isEmpty ? pluginId : words.join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'interpreter': interpreter,
      'refreshInterval': refreshInterval.inMilliseconds,
      'enabled': enabled,
      if (customTitle != null) 'customTitle': customTitle,
      'lastRun': lastRun?.toIso8601String(),
      'lastError': lastError,
      if (config != null) 'config': config!.toJson(),
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  Plugin copyWith({
    String? id,
    String? path,
    String? interpreter,
    Duration? refreshInterval,
    String? customTitle,
    bool? enabled,
    DateTime? lastRun,
    String? lastError,
    PluginConfig? config,
    List<PluginVariant>? variants,
  }) {
    return Plugin(
      id: id ?? this.id,
      path: path ?? this.path,
      interpreter: interpreter ?? this.interpreter,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      customTitle: customTitle ?? this.customTitle,
      enabled: enabled ?? this.enabled,
      lastRun: lastRun ?? this.lastRun,
      lastError: lastError ?? this.lastError,
      config: config ?? this.config,
      variants: variants ?? this.variants,
    );
  }

  @override
  String toString() {
    return 'Plugin(id: $id, interpreter: $interpreter, enabled: $enabled, customTitle: $customTitle, variants: ${variants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plugin &&
        other.id == id &&
        other.path == path &&
        other.interpreter == interpreter &&
        other.refreshInterval == refreshInterval &&
        other.enabled == enabled &&
        other.customTitle == customTitle &&
        other.config == config &&
        _listEquals(other.variants, variants);
  }

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      path,
      interpreter,
      refreshInterval,
      customTitle,
      enabled,
      config,
      variants,
    );
  }
}
