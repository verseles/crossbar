import 'dart:async';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:yaml/yaml.dart';

/// DeclarativeRunner - Executes YAML-based plugins without code
///
/// This runner parses .yaml plugin files and executes them declaratively.
/// Plugins define data sources and output templates, no programming required.
///
/// Example plugin (plugins/weather.30m.yaml):
/// ```yaml
/// name: Weather
/// interval: 30m
/// 
/// source:
///   type: http
///   url: "https://api.openweathermap.org/data/2.5/weather?q=London&appid=${WEATHER_API_KEY}"
///
/// output:
///   text: "🌡️ ${response.main.temp}°C"
///   tooltip: "${response.weather[0].description}"
///
/// menu:
///   - title: "Humidity: ${response.main.humidity}%"
///   - title: "Wind: ${response.wind.speed} m/s"
///   - separator
///   - title: "Refresh"
///     action: refresh
/// ```
class DeclarativeRunner {
  factory DeclarativeRunner() => instance;
  DeclarativeRunner._();
  
  static final DeclarativeRunner instance = DeclarativeRunner._();
  
  final CrossbarBridge _bridge = CrossbarBridge();
  
  /// Execute a YAML plugin file
  Future<DeclarativeRunResult> run(String pluginPath) async {
    final file = File(pluginPath);
    if (!file.existsSync()) {
      return DeclarativeRunResult.error('Plugin file not found: $pluginPath');
    }
    
    final content = await file.readAsString();
    return runSource(content, pluginPath: pluginPath);
  }
  
  /// Execute YAML source and return result
  Future<DeclarativeRunResult> runSource(String yamlSource, {String? pluginPath}) async {
    try {
      final doc = loadYaml(yamlSource);
      if (doc is! YamlMap) {
        return DeclarativeRunResult.error('Invalid YAML: root must be a map');
      }
      
      final config = PluginConfig.fromYaml(doc);
      
      // Fetch data from source
      final data = await _fetchData(config.source);
      
      // Render output using template
      final output = _renderTemplate(config.output.text, data);
      final tooltip = config.output.tooltip != null 
          ? _renderTemplate(config.output.tooltip!, data)
          : null;
      
      // Render menu items
      final menuItems = config.menu.map((item) {
        if (item.separator) return DeclarativeMenuItem.separator();
        return DeclarativeMenuItem(
          title: _renderTemplate(item.title!, data),
          action: item.action,
        );
      }).toList();
      
      return DeclarativeRunResult(
        output: output,
        tooltip: tooltip,
        menu: menuItems,
        icon: config.output.icon,
        color: config.output.color,
        data: data,
        pluginPath: pluginPath,
      );
      
    } catch (e, stack) {
      return DeclarativeRunResult.error(
        'Error executing plugin: $e\n${stack.toString().split('\n').take(3).join('\n')}',
      );
    }
  }
  
  /// Fetch data based on source configuration
  Future<Map<String, dynamic>> _fetchData(SourceConfig source) async {
    switch (source.type) {
      case 'http':
        final url = _interpolateEnv(source.url!);
        final response = await _bridge.web(
          url,
          method: source.method ?? 'GET',
          headers: source.headers,
        );
        if (response is Map<String, dynamic>) {
          return {'response': response};
        }
        return {'response': {'body': response.toString()}};
        
      case 'system':
        return _getSystemData(source.command!);
        
      case 'exec':
        final command = _interpolateEnv(source.command!);
        final result = await _bridge.exec(command);
        return {'output': result, 'response': {'output': result}};
        
      case 'static':
        // Wrap static data in 'response' for template consistency
        final staticData = _yamlToMap(source.data);
        return {'response': staticData};
        
      default:
        return {};
    }
  }
  
  /// Get system data based on command
  Future<Map<String, dynamic>> _getSystemData(String command) async {
    switch (command) {
      case 'cpu':
        final cpu = await _bridge.cpu();
        return {'response': {'value': cpu, 'percent': cpu}};
      case 'memory':
        final mem = await _bridge.memory();
        return {'response': mem};
      case 'battery':
        final bat = await _bridge.battery();
        return {'response': bat};
      case 'time':
        return {'response': {'value': _bridge.time()}};
      case 'date':
        return {'response': {'value': _bridge.date()}};
      case 'uptime':
        final uptime = await _bridge.uptime();
        return {'response': {'value': uptime}};
      case 'network':
        final status = await _bridge.netStatus();
        final localIp = await _bridge.localIp();
        return {'response': {'status': status, 'localIp': localIp}};
      default:
        return {};
    }
  }
  
  /// Interpolate environment variables in string
  String _interpolateEnv(String template) {
    return template.replaceAllMapped(
      RegExp(r'\$\{(\w+)\}'),
      (match) {
        final varName = match.group(1)!;
        return _bridge.env(varName) ?? '';
      },
    );
  }
  
  /// Render template with data
  String _renderTemplate(String template, Map<String, dynamic> data) {
    var result = template;
    
    // First interpolate env vars
    result = _interpolateEnv(result);
    
    // Then interpolate data paths like ${response.main.temp}
    result = result.replaceAllMapped(
      RegExp(r'\$\{([a-zA-Z0-9_.[\]]+)\}'),
      (match) {
        final path = match.group(1)!;
        final value = _resolvePath(data, path);
        return value?.toString() ?? '';
      },
    );
    
    return result;
  }
  
  /// Resolve a dot-notation path in data
  dynamic _resolvePath(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic current = data;
    
    for (final part in parts) {
      if (current == null) return null;
      
      // Handle array access like weather[0]
      final arrayMatch = RegExp(r'(\w+)\[(\d+)\]').firstMatch(part);
      if (arrayMatch != null) {
        final key = arrayMatch.group(1)!;
        final index = int.parse(arrayMatch.group(2)!);
        if (current is Map && current.containsKey(key)) {
          final list = current[key];
          if (list is List && index < list.length) {
            current = list[index];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }
  
  /// Convert YamlMap to regular Dart Map recursively
  Map<String, dynamic> _yamlToMap(dynamic yaml) {
    if (yaml == null) return {};
    if (yaml is! Map) return {};
    
    final result = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlMap || value is Map) {
        result[key] = _yamlToMap(value);
      } else if (value is YamlList) {
        result[key] = value.map((e) => e is YamlMap ? _yamlToMap(e) : e).toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }
  
  /// Check if this runner can handle the given plugin
  bool canRun(String pluginPath) {
    final ext = pluginPath.split('.').last.toLowerCase();
    return ext == 'yaml' || ext == 'yml';
  }
}

/// Plugin configuration parsed from YAML
class PluginConfig {
  PluginConfig({
    required this.name,
    required this.source, required this.output, this.interval,
    this.menu = const [],
    this.requires = const [],
  });
  
  factory PluginConfig.fromYaml(YamlMap yaml) {
    return PluginConfig(
      name: yaml['name'] as String? ?? 'Unnamed Plugin',
      interval: yaml['interval'] as String?,
      source: SourceConfig.fromYaml(yaml['source'] as YamlMap? ?? YamlMap()),
      output: OutputConfig.fromYaml(yaml['output'] as YamlMap? ?? YamlMap()),
      menu: (yaml['menu'] as YamlList?)
          ?.map(MenuItemConfig.fromYaml)
          .toList() ?? [],
      requires: (yaml['requires'] as YamlList?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
  
  final String name;
  final String? interval;
  final SourceConfig source;
  final OutputConfig output;
  final List<MenuItemConfig> menu;
  final List<String> requires;
}

/// Source configuration for data fetching
class SourceConfig {
  SourceConfig({
    required this.type,
    this.url,
    this.method,
    this.headers,
    this.command,
    this.data,
  });
  
  factory SourceConfig.fromYaml(YamlMap yaml) {
    return SourceConfig(
      type: yaml['type'] as String? ?? 'static',
      url: yaml['url'] as String?,
      method: yaml['method'] as String?,
      headers: (yaml['headers'] as YamlMap?)?.cast<String, String>(),
      command: yaml['command'] as String?,
      data: (yaml['data'] as YamlMap?)?.cast<String, dynamic>(),
    );
  }
  
  final String type; // http, system, exec, static
  final String? url;
  final String? method;
  final Map<String, String>? headers;
  final String? command;
  final Map<String, dynamic>? data;
}

/// Output configuration for rendering
class OutputConfig {
  OutputConfig({
    required this.text,
    this.tooltip,
    this.icon,
    this.color,
  });
  
  factory OutputConfig.fromYaml(YamlMap yaml) {
    return OutputConfig(
      text: yaml['text'] as String? ?? '',
      tooltip: yaml['tooltip'] as String?,
      icon: yaml['icon'] as String?,
      color: yaml['color'] as String?,
    );
  }
  
  final String text;
  final String? tooltip;
  final String? icon;
  final String? color;
}

/// Menu item configuration
class MenuItemConfig {
  MenuItemConfig({
    this.title,
    this.action,
    this.separator = false,
  });
  
  factory MenuItemConfig.fromYaml(dynamic yaml) {
    if (yaml == 'separator' || yaml == '---') {
      return MenuItemConfig(separator: true);
    }
    if (yaml is YamlMap) {
      return MenuItemConfig(
        title: yaml['title'] as String?,
        action: yaml['action'] as String?,
      );
    }
    return MenuItemConfig(title: yaml?.toString());
  }
  
  final String? title;
  final String? action;
  final bool separator;
}

/// Result of running a declarative plugin
class DeclarativeRunResult {
  DeclarativeRunResult({
    this.output = '',
    this.tooltip,
    this.menu = const [],
    this.icon,
    this.color,
    this.data = const {},
    this.error,
    this.pluginPath,
  });
  
  factory DeclarativeRunResult.error(String message) {
    return DeclarativeRunResult(error: message);
  }
  
  final String output;
  final String? tooltip;
  final List<DeclarativeMenuItem> menu;
  final String? icon;
  final String? color;
  final Map<String, dynamic> data;
  final String? error;
  final String? pluginPath;
  
  bool get success => error == null;
  bool get hasOutput => output.isNotEmpty;
  bool get hasMenu => menu.isNotEmpty;
  
  @override
  String toString() {
    if (error != null) return 'DeclarativeRunResult(error: $error)';
    return output;
  }
}

/// Menu item for declarative plugin
class DeclarativeMenuItem {
  DeclarativeMenuItem({
    this.title,
    this.action,
    this.isSeparator = false,
  });
  
  factory DeclarativeMenuItem.separator() {
    return DeclarativeMenuItem(isSeparator: true);
  }
  
  final String? title;
  final String? action;
  final bool isSeparator;
}
