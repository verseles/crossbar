class PluginConfig {
  /// Reserved config key for custom display title.
  /// Keys prefixed with `_crossbar_` are reserved by the system.
  static const String customTitleKey = '_crossbar_title';

  const PluginConfig({
    required this.name,
    required this.description,
    required this.icon,
    required this.configRequired,
    required this.settings,
  });

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      configRequired: json['config_required'] as String? ?? 'optional',
      settings: (json['settings'] as List<dynamic>?)
              ?.map((s) => Setting.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String name;
  final String description;
  final String icon;
  final String configRequired;
  final List<Setting> settings;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'config_required': configRequired,
      'settings': settings.map((s) => s.toJson()).toList(),
    };
  }

  PluginConfig copyWith({
    String? name,
    String? description,
    String? icon,
    String? configRequired,
    List<Setting>? settings,
  }) {
    return PluginConfig(
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      configRequired: configRequired ?? this.configRequired,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'PluginConfig(name: $name, settings: ${settings.length})';
  }
}

/// Represents a single configuration option for select fields.
class SelectOption {
  const SelectOption({
    required this.value,
    required this.label,
  });

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    return SelectOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }

  final String value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// Represents a tab within a `tabs` type setting.
class SettingTab {
  const SettingTab({
    required this.label,
    required this.fields,
    this.icon,
  });

  factory SettingTab.fromJson(Map<String, dynamic> json) {
    return SettingTab(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((s) => Setting.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String label;
  final String? icon;
  final List<Setting> fields;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (icon != null) 'icon': icon,
      'fields': fields.map((s) => s.toJson()).toList(),
    };
  }
}

class Setting {
  const Setting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.description,
    this.required = false,
    this.options,
    this.width,
    this.placeholder,
    this.help,
    this.min,
    this.max,
    this.step,
    this.pattern,
    this.format,
    this.accept,
    this.unit,
    this.rows,
    this.fields,
    this.tabs,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'];
    List<SelectOption>? options;
    if (optionsJson is List<dynamic>) {
      options = optionsJson.map(_parseSelectOption).toList();
    } else if (optionsJson is Map<String, dynamic>) {
      final choices = optionsJson['choices'];
      if (choices is List<dynamic>) {
        options = choices.map(_parseSelectOption).toList();
      }
    }

    return Setting(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      defaultValue: json['default']?.toString(),
      description: json['description'] as String?,
      required: _toBool(json['required']),
      options: options,
      width: _toInt(json['width']),
      placeholder: json['placeholder'] as String?,
      help: json['help'] as String?,
      min: _toDouble(json['min'] ?? _readOption(optionsJson, 'min')),
      max: _toDouble(json['max'] ?? _readOption(optionsJson, 'max')),
      step: _toDouble(json['step'] ?? _readOption(optionsJson, 'step')),
      pattern:
          (json['pattern'] ?? _readOption(optionsJson, 'pattern'))?.toString(),
      format:
          (json['format'] ?? _readOption(optionsJson, 'format'))?.toString(),
      accept:
          (json['accept'] ?? _readOption(optionsJson, 'accept'))?.toString(),
      unit: (json['unit'] ?? _readOption(optionsJson, 'unit'))?.toString(),
      rows: _toInt(json['rows'] ?? _readOption(optionsJson, 'rows')),
      fields: (json['fields'] as List<dynamic>?)
          ?.map((s) => Setting.fromJson(s as Map<String, dynamic>))
          .toList(),
      tabs: (json['tabs'] as List<dynamic>?)
          ?.map((t) => SettingTab.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
  final String key;
  final String label;
  final String type;
  final String? defaultValue;
  final String? description;
  final bool required;
  final List<SelectOption>? options;
  final int? width;
  final String? placeholder;
  final String? help;
  final double? min;
  final double? max;
  final double? step;
  final String? pattern;
  final String? format;
  final String? accept;
  final String? unit;
  final int? rows;

  /// Child fields for container types like `collapsible`.
  final List<Setting>? fields;

  /// Tab definitions for `tabs` type.
  final List<SettingTab>? tabs;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      'required': required,
      if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
      if (width != null) 'width': width,
      if (placeholder != null) 'placeholder': placeholder,
      if (help != null) 'help': help,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (pattern != null) 'pattern': pattern,
      if (format != null) 'format': format,
      if (accept != null) 'accept': accept,
      if (unit != null) 'unit': unit,
      if (rows != null) 'rows': rows,
      if (fields != null) 'fields': fields!.map((s) => s.toJson()).toList(),
      if (tabs != null) 'tabs': tabs!.map((t) => t.toJson()).toList(),
    };
  }

  Setting copyWith({
    String? key,
    String? label,
    String? type,
    String? defaultValue,
    String? description,
    bool? required,
    List<SelectOption>? options,
    int? width,
    String? placeholder,
    String? help,
    double? min,
    double? max,
    double? step,
    String? pattern,
    String? format,
    String? accept,
    String? unit,
    int? rows,
    List<Setting>? fields,
    List<SettingTab>? tabs,
  }) {
    return Setting(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
      required: required ?? this.required,
      options: options ?? this.options,
      width: width ?? this.width,
      placeholder: placeholder ?? this.placeholder,
      help: help ?? this.help,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      pattern: pattern ?? this.pattern,
      format: format ?? this.format,
      accept: accept ?? this.accept,
      unit: unit ?? this.unit,
      rows: rows ?? this.rows,
      fields: fields ?? this.fields,
      tabs: tabs ?? this.tabs,
    );
  }

  @override
  String toString() {
    return 'Setting(key: $key, type: $type, required: $required)';
  }
}

SelectOption _parseSelectOption(dynamic value) {
  if (value is String) {
    return SelectOption(value: value, label: value);
  }
  if (value is Map<String, dynamic>) {
    return SelectOption.fromJson(value);
  }
  final fallback = value.toString();
  return SelectOption(value: fallback, label: fallback);
}

dynamic _readOption(dynamic options, String key) {
  if (options is Map<String, dynamic>) {
    return options[key];
  }
  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
  return false;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
