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
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    List<SelectOption>? options;
    if (json['options'] != null) {
      options = (json['options'] as List<dynamic>)
          .map((o) => SelectOption.fromJson(o as Map<String, dynamic>))
          .toList();
    }

    return Setting(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      defaultValue: json['default'] as String?,
      description: json['description'] as String?,
      required: json['required'] as bool? ?? false,
      options: options,
      width: json['width'] as int?,
      placeholder: json['placeholder'] as String?,
      help: json['help'] as String?,
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
    );
  }

  @override
  String toString() {
    return 'Setting(key: $key, type: $type, required: $required)';
  }
}

