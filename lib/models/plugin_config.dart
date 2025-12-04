class PluginConfig {

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

class Setting {

  const Setting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.options,
    this.width,
    this.placeholder,
    this.help,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      defaultValue: json['default'] as String?,
      required: json['required'] as bool? ?? false,
      options: json['options'] as Map<String, dynamic>?,
      width: json['width'] as int?,
      placeholder: json['placeholder'] as String?,
      help: json['help'] as String?,
    );
  }
  final String key;
  final String label;
  final String type;
  final String? defaultValue;
  final bool required;
  final Map<String, dynamic>? options;
  final int? width;
  final String? placeholder;
  final String? help;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      if (defaultValue != null) 'default': defaultValue,
      'required': required,
      if (options != null) 'options': options,
      if (width != null) 'width': width,
      if (placeholder != null) 'placeholder': placeholder,
      if (help != null) 'help': help,
    };
  }

  Setting copyWith({
    String? key,
    String? label,
    String? type,
    String? defaultValue,
    bool? required,
    Map<String, dynamic>? options,
    int? width,
    String? placeholder,
    String? help,
  }) {
    return Setting(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      required: required ?? this.required,
      options: options ?? this.options,
      width: width ?? this.width,
      placeholder: placeholder ?? this.placeholder,
      help: help ?? this.help,
    );
  }

  @override
  String toString() {
    return 'Setting(key: $key, type: $type, required: $required)';
  }
}
