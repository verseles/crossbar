class PluginOutput {
  const PluginOutput({
    required this.pluginId,
    required this.icon,
    this.title,
    this.text,
    this.color,
    this.trayTooltip,
    this.trayIcon,
    this.menu = const [],
    this.hasError = false,
    this.errorMessage,
  });

  factory PluginOutput.error(String pluginId, String message) {
    return PluginOutput(
      pluginId: pluginId,
      icon: '',
      text: 'Error',
      hasError: true,
      errorMessage: message,
    );
  }

  factory PluginOutput.empty(String pluginId) {
    return PluginOutput(
      pluginId: pluginId,
      icon: '',
      text: '',
    );
  }
  final String pluginId;
  final String icon;
  final String? title;
  final String? text;
  final int? color;
  final String? trayTooltip;

  /// Freedesktop icon name for tray (e.g., 'battery-level-50-symbolic').
  /// If null, falls back to icon name mapping based on pluginId.
  final String? trayIcon;
  final List<MenuItem> menu;
  final bool hasError;
  final String? errorMessage;

  PluginOutput copyWith({
    String? pluginId,
    String? icon,
    String? title,
    String? text,
    int? color,
    String? trayTooltip,
    String? trayIcon,
    List<MenuItem>? menu,
    bool? hasError,
    String? errorMessage,
  }) {
    return PluginOutput(
      pluginId: pluginId ?? this.pluginId,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      text: text ?? this.text,
      color: color ?? this.color,
      trayTooltip: trayTooltip ?? this.trayTooltip,
      trayIcon: trayIcon ?? this.trayIcon,
      menu: menu ?? this.menu,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'icon': icon,
      'title': title,
      'text': text,
      'color': color,
      'trayTooltip': trayTooltip,
      'trayIcon': trayIcon,
      'menu': menu.map((m) => m.toJson()).toList(),
      'hasError': hasError,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'PluginOutput(pluginId: $pluginId, icon: $icon, title: $title, text: $text, hasError: $hasError)';
  }
}

class MenuItem {
  const MenuItem({
    this.text,
    this.separator = false,
    this.bash,
    this.href,
    this.refresh = false,
    this.color,
    this.submenu,
  });

  factory MenuItem.separator() {
    return const MenuItem(separator: true);
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      text: json['text'] as String?,
      separator: json['separator'] as bool? ?? false,
      bash: json['bash'] as String?,
      href: json['href'] as String?,
      refresh: json['refresh'] as bool? ?? false,
      color: json['color'] as String?,
      submenu: (json['submenu'] as List<dynamic>?)
          ?.map((s) => MenuItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
  final String? text;
  final bool separator;
  final String? bash;
  final String? href;
  final bool refresh;
  final String? color;
  final List<MenuItem>? submenu;

  /// Whether this item is purely an action (not informational content).
  bool get isAction => bash != null || refresh || href != null;

  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
      'separator': separator,
      if (bash != null) 'bash': bash,
      if (href != null) 'href': href,
      if (refresh) 'refresh': refresh,
      if (color != null) 'color': color,
      if (submenu != null) 'submenu': submenu!.map((s) => s.toJson()).toList(),
    };
  }

  MenuItem copyWith({
    String? text,
    bool? separator,
    String? bash,
    String? href,
    bool? refresh,
    String? color,
    List<MenuItem>? submenu,
  }) {
    return MenuItem(
      text: text ?? this.text,
      separator: separator ?? this.separator,
      bash: bash ?? this.bash,
      href: href ?? this.href,
      refresh: refresh ?? this.refresh,
      color: color ?? this.color,
      submenu: submenu ?? this.submenu,
    );
  }

  @override
  String toString() {
    if (separator) return 'MenuItem(separator)';
    return 'MenuItem(text: $text)';
  }
}
