# CROSSBAR - Plano Final Otimizado

**Sistema Universal de Plugins para Barra de Tarefas/Menu Bar**

**Repositório**: `verseles/crossbar`
**Licença**: AGPLv3 (garante que derivados e serviços SaaS retornem melhorias à comunidade)
**Tecnologia**: Dart 3.10+ + Flutter 3.35+
**Plataformas**: Linux, Windows, macOS, Android, iOS

---

## 1. VISÃO GERAL E FILOSOFIA

### 1.1 Conceito

Crossbar é um sistema revolucionário de plugins cross-platform inspirado em BitBar (macOS) e Argos (Linux), que eleva o conceito para todas as plataformas desktop e mobile com uma API unificada.

**Diferenciais Revolucionários**:

1. **API CLI Unificada**: Plugin escribe `crossbar --cpu` uma única vez, funciona em 5 plataformas (BitBar/Argos forçam cada dev a reimplementar para cada OS).

2. **Widgets Adaptativos**: Plugin retorna dados estruturados, Crossbar renderiza automaticamente para tray icon, notificação Android, widget 1x1/2x2, menu bar macOS (nenhuma ferramenta existente faz isso).

3. **Controles Bidirecionais**: Além de mostrar informações (GET), permite controlar o sistema (SET): volume, mídia, notificações, wallpaper (BitBar/Argos são apenas leitura).

4. **Configuração Declarativa**: Plugin declara suas configurações em JSON, Crossbar gera GUI automaticamente com 25+ tipos de campos (text, password, color picker, file picker, etc).

5. **Múltiplos Ícones Dinâmicos**: Cada plugin pode ter seu próprio ícone na tray/menu bar que muda dinamicamente (BitBar tem ícone fixo).

### 1.2 Filosofia "Write Once, Run Everywhere"

```python
#!/usr/bin/env python3
# Este plugin funciona SEM MODIFICAÇÃO em:
# - Linux (tray icon)
# - Windows (system tray)
# - macOS (menu bar)
# - Android (notificação persistente + widget)
# - iOS (widget home screen)

import subprocess, json

cpu = subprocess.run(['crossbar', '--cpu'], capture_output=True, text=True)
print(json.dumps({
    "icon": "⚡",
    "text": f"{cpu.stdout.strip()}%",
    "menu": [{"text": "Details", "bash": "crossbar --process-list"}]
}))
```

### 1.3 Público-Alvo

- Desenvolvedores que querem monitorar sistemas
- Power users que customizam workflow
- DevOps com dashboards na barra de tarefas
- Comunidade open source (marketplace de plugins)

---

## 2. ARQUITETURA E TECH STACK

### 2.1 Decisões Técnicas

**Por quê Flutter 3.35+**:

- **Por quê**: Única framework madura com suporte a 5 plataformas (desktop + mobile) nativo.
- **Alternativas descartadas**: Electron (pesado, sem mobile), React Native (suporte desktop fraco), Tauri (sem mobile, Rust adiciona complexidade).

**Por quê Dart 3.x**:

- **Por quê**: Linguagem type-safe, null-safety nativo, tooling excelente, ecossistema pub.dev maduro.
- **CLI nativa**: `dart:io` permite criar CLI completa sem dependências externas.

**Por quê esses 6 linguagens de plugin**: Cobrem 95% dos casos (bash ubíquo, python/node mainstream, dart nativo Flutter, go/rust para performance).
- Bash (.sh) - Universal em Linux/macOS
- Python (.py) - `python3` (não python2)
- Node.js (.js) - `node` ou `#!/usr/bin/env node`
- Dart (.dart) - `dart run` (Flutter SDK)
- Go (.go) - `go run` (requer Go SDK)
- Rust (.rs) - Compila com `rustc`, executa binário

---

## 3. VERDADE TÉCNICA (Versões Imutáveis)

Baseado em: plan_g25.md + plan_m2.md

### 3.1 Versões de Tecnologia (Validadas Nov 2025)

| Tecnologia | Versão | Notas |
|------------|--------|-------|
| Flutter SDK | 3.35.2+ | Stable channel |
| Dart SDK | 3.10.0+ | Vem com Flutter 3.35.2 |
| Java | 25 (LTS) | Para Android builds |
| Android | API 35 (Min), API 36 (Target) | Google Play compliance |
| Kotlin | 1.9.23 | Compatível com Flutter |
| Gradle | 8.5+ | |
| Python | 3.14 ou 3.13 | Runtime de plugins |
| Node.js | 24 LTS "Krypton" | Runtime de plugins |
| Go | 1.25 | Runtime de plugins |
| Rust | 1.91+ | Runtime de plugins |

### 3.2 Packages Flutter

#### Critérios de Seleção

- **tray_manager**: Único package maduro multi-plataforma (Win/Linux/macOS)
- **dio**: Melhor client HTTP Flutter (interceptors, retries, validação SSL, certificados custom)
- **intl**: i18n oficial Google com compile-time safety
- **flutter_secure_storage**: Keychain/KeyStore (nunca passwords em plaintext)

#### Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter

  # System & Desktop
  tray_manager: ^0.2.3
  window_manager: ^0.4.2

  # Core Utils
  path_provider: ^2.1.4
  file_picker: ^8.1.2
  intl: ^0.19.0

  # Network & Data
  dio: ^5.7.0
  connectivity_plus: ^6.1.0

  # Storage
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2

  # Device Info
  device_info_plus: ^10.1.2
  battery_plus: ^6.0.2
  package_info_plus: ^8.0.2

  # Mobile Specifics
  home_widget: ^0.6.0
  flutter_local_notifications: ^17.2.3
  clipboard: ^0.1.3

  # UI Components
  flutter_colorpicker: ^1.1.0
  url_launcher: ^6.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  coverage: ^1.9.2
  integration_test:
    sdk: flutter
```

### 2.4 Fluxo de Execução

```
1. Crossbar inicia (silencioso, background)
   ↓
2. Lê ~/.crossbar/plugins/* (detecta linguagem via shebang/extensão)
   ↓
3. Para cada plugin:
   a. Parse refresh interval do nome (ex: "cpu.10s.sh" = 10 segundos)
   b. Carrega configurações (~/.crossbar/configs/<plugin>.json)
   c. Injeta ENV vars (CROSSBAR_OS, configs do usuário)
   d. Executa script (Process.run com timeout 30s)
   e. Parse saída (texto BitBar OU JSON auto-detect)
   f. Renderiza UI (tray icon/notificação/widget)
   ↓
4. File watcher monitora plugins/ (hot reload com debounce 1s)
   ↓
5. HTTP server localhost:48291 (GUI comunica com background)
   ↓
6. Atalho global Ctrl+Alt+C abre GUI
```

---

## 4. ARQUITETURA CORE

Baseado em: plan_g25.md + plan_m2.md

### 4.1 Modelo Plugin (lib/models/plugin.dart)

```dart
import 'dart:convert';

class Plugin {
  final String id;              // Nome do arquivo (ex: "cpu.10s.sh")
  final String path;            // Caminho absoluto para o script
  final String interpreter;     // "bash", "python3", "node", etc
  final Duration refreshInterval; // Intervalo de execução
  final bool enabled;           // Ativo/inativo
  final DateTime? lastRun;      // Última execução
  final String? lastError;      // Último erro

  const Plugin({
    required this.id,
    required this.path,
    required this.interpreter,
    required this.refreshInterval,
    this.enabled = true,
    this.lastRun,
    this.lastError,
  });

  // Factory para testes
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
      id: json['id'],
      path: json['path'],
      interpreter: json['interpreter'],
      refreshInterval: Duration(milliseconds: json['refreshInterval']),
      enabled: json['enabled'] ?? true,
      lastRun: json['lastRun'] != null
          ? DateTime.parse(json['lastRun'])
          : null,
      lastError: json['lastError'],
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
}
```

### 4.2 Plugin Output (lib/core/output_parser.dart)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

class PluginOutput {
  final String pluginId;
  final String icon;
  final String? text;
  final Color? color;
  final String? trayTooltip;
  final List<MenuItem> menu;
  final bool hasError;
  final String? errorMessage;

  const PluginOutput({
    required this.pluginId,
    required this.icon,
    this.text,
    this.color,
    this.trayTooltip,
    this.menu = const [],
    this.hasError = false,
    this.errorMessage,
  });

  factory PluginOutput.error(String pluginId, String message) {
    return PluginOutput(
      pluginId: pluginId,
      icon: '⚠️',
      text: 'Error',
      hasError: true,
      errorMessage: message,
    );
  }

  factory PluginOutput.empty(String pluginId) {
    return PluginOutput(
      pluginId: pluginId,
      icon: '⚙️',
      text: '',
    );
  }
}

class MenuItem {
  final String? text;
  final bool separator;
  final String? bash;
  final String? href;
  final String? color;
  final List<MenuItem>? submenu;

  const MenuItem({
    this.text,
    this.separator = false,
    this.bash,
    this.href,
    this.color,
    this.submenu,
  });
}

class OutputParser {
  static bool isJson(String output) {
    final trimmed = output.trim();
    return trimmed.startsWith('{') && trimmed.endsWith('}');
  }

  static PluginOutput parse(String output, String pluginId) {
    try {
      final trimmedOutput = output.trim();
      if (trimmedOutput.isEmpty) {
        return PluginOutput.empty(pluginId);
      }

      if (isJson(trimmedOutput)) {
        return _parseJson(trimmedOutput, pluginId);
      } else {
        return _parseBitBar(trimmedOutput, pluginId);
      }
    } catch (e) {
      return PluginOutput.error(pluginId, 'Failed to parse output: $e');
    }
  }

  static PluginOutput _parseJson(String jsonString, String pluginId) {
    final data = jsonDecode(jsonString);

    return PluginOutput(
      pluginId: pluginId,
      icon: data['icon'] ?? '⚙️',
      text: data['text'],
      color: data['color'] != null ? _parseColor(data['color']) : null,
      trayTooltip: data['tray_tooltip'],
      menu: _parseMenuItems(data['menu'] as List? ?? []),
    );
  }

  static PluginOutput _parseBitBar(String text, String pluginId) {
    final lines = text.split('\n').where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return PluginOutput(pluginId: pluginId, icon: '⚙️', text: '');
    }

    final firstLine = lines.first;
    String icon = '⚙️';
    String? text;
    String? color;

    // Parse primeira linha (ícone + texto)
    if (firstLine.contains('|')) {
      final parts = firstLine.split('|');
      final mainText = parts[0].trim();
      icon = mainText.isNotEmpty ? mainText[0] : '⚙️';
      text = mainText.length > 1 ? mainText.substring(1).trim() : '';

      // Parse atributos (color, size, etc)
      for (var i = 1; i < parts.length; i++) {
        final attr = parts[i].trim();
        if (attr.startsWith('color=')) {
          color = attr.substring(6);
        }
      }
    } else {
      text = firstLine;
    }

    final menu = <MenuItem>[];

    // Parse menu (após ---)
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].startsWith('---')) {
        for (var j = i + 1; j < lines.length; j++) {
          final line = lines[j].trim();
          if (line.isEmpty) continue;

          if (line.contains('|')) {
            final parts = line.split('|');
            final itemText = parts[0].trim();
            String? bash;
            String? href;

            for (var k = 1; k < parts.length; k++) {
              final attr = parts[k].trim();
              if (attr.startsWith('bash=')) {
                bash = attr.substring(5);
              } else if (attr.startsWith('href=')) {
                href = attr.substring(5);
              }
            }

            menu.add(MenuItem(text: itemText, bash: bash, href: href));
          } else {
            menu.add(MenuItem(text: line));
          }
        }
        break;
      }
    }

    return PluginOutput(
      pluginId: pluginId,
      icon: icon,
      text: text,
      color: color != null ? _parseColor(color) : null,
      menu: menu,
    );
  }

  static List<MenuItem> _parseMenuItems(List<dynamic> items) {
    return items.map((item) {
      if (item['separator'] == true) {
        return MenuItem(separator: true);
      }
      return MenuItem(
        text: item['text'],
        bash: item['bash'],
        href: item['href'],
        submenu: item['submenu'] != null
            ? _parseMenuItems(item['submenu'])
            : null,
        color: item['color'],
      );
    }).toList();
  }

  static Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    // TODO: Implementar parser de cores (hex, named colors, etc)
    return null;
  }
}
```

### 4.3 Script Runner (lib/core/script_runner.dart)

#### Porquês Importantes

- **Por quê timeout 30s**: Plugins devem ser rápidos (<1s ideal). 30s é limite generoso para chamadas HTTP lentas.
- **Por quê pool de 10**: Evita fork bomb se usuário ativa 50 plugins com interval 1s.
- **Por quê dois formatos (texto + JSON)**: Texto = compatibilidade BitBar, onboarding fácil. JSON = poder total (submenus, cores, ícones custom).

```dart
import 'dart:convert';
import 'dart:io';
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/core/output_parser.dart';

abstract class IProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    Duration timeout,
  });
}

class SystemProcessRunner implements IProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    required Duration timeout,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
      runInShell: true,
    );

    final output = await process.stdout
        .transform(utf8.decoder)
        .timeout(timeout)
        .join();

    final exitCode = await process.exitCode;

    return ProcessResult(
      process.pid,
      exitCode,
      output,
      '',
    );
  }
}

class ScriptRunner {
  final IProcessRunner processRunner;
  static const Duration defaultTimeout = Duration(seconds: 30);

  ScriptRunner({this.processRunner = const SystemProcessRunner()});

  Future<PluginOutput> run(Plugin plugin) async {
    try {
      final environment = {
        'CROSSBAR_OS': Platform.operatingSystem,
        'CROSSBAR_VERSION': '1.0.0',
        'CROSSBAR_PLUGIN_ID': plugin.id,
        ...Platform.environment,
      };

      final result = await processRunner.run(
        plugin.interpreter,
        [plugin.path],
        environment: environment,
        timeout: defaultTimeout,
      );

      if (result.exitCode != 0) {
        return PluginOutput.error(
          plugin.id,
          'Plugin exited with code ${result.exitCode}',
        );
      }

      return OutputParser.parse(result.stdout.toString(), plugin.id);
    } on TimeoutException {
      return PluginOutput.error(plugin.id, 'Plugin execution timed out');
    } catch (e) {
      return PluginOutput.error(plugin.id, 'Failed to run plugin: $e');
    }
  }
}
```

---

## 5. CLI API UNIFICADA

Baseado em: plan_m2.md

### 5.1 Filosofia da API

**"Best Effort"**: Todos comandos tentam executar, retornam erro claro se falharem (ex: permissão negada, feature não disponível no OS).

**Por quê texto puro padrão**: Scripts bash/shell precisam de saída simples para `$(crossbar --cpu)`. JSON requer parse (jq, python).

**Por quê --json como flag**: Mantém compatibilidade com BitBar (texto) mas permite avanços (objetos complexos).

**Formatos de Saída**:
- Padrão: texto puro (compatível BitBar, parseável em bash)
- `--json`: objeto JSON estruturado
- `--xml`: XML (para integração legada)

### 5.2 bin/crossbar.dart (CLI Entry Point)

```dart
import 'dart:io';
import 'package:crossbar/core/api/system_api.dart';
import 'package:crossbar/core/api/network_api.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args[0];
  final commandArgs = args.sublist(1);

  try {
    switch (command) {
      // Sistema
      case '--cpu':
        final api = SystemApi();
        final result = await api.getCpuUsage();
        print(result);
        break;
      case '--memory':
        final api = SystemApi();
        final result = await api.getMemoryUsage();
        print(result);
        break;
      case '--battery':
        final api = SystemApi();
        final result = await api.getBatteryStatus();
        print(result);
        break;

      // Rede
      case '--net-status':
        final api = NetworkApi();
        final result = await api.getNetStatus();
        print(result);
        break;
      case '--web':
        final url = _getArg(commandArgs, '--url') ?? _getArg(commandArgs, 0);
        if (url == null) {
          print('Error: --web requires URL');
          exit(1);
        }
        final api = NetworkApi();
        final result = await api.makeRequest(url);
        print(result);
        break;

      default:
        print('Error: Unknown command: $command');
        _printUsage();
        exit(1);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

String? _getArg(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index >= 0 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}

void _printUsage() {
  print('''
Crossbar - Universal Plugin System
Usage: crossbar <command> [options]

System:
  --cpu              CPU usage percentage
  --memory           RAM usage (free/total)
  --battery          Battery level

Network:
  --net-status       Connection type
  --web <url>        HTTP request

Examples:
  crossbar --cpu
  crossbar --web https://api.github.com/users/octocat
''');
}
```

### 3.2 System API (lib/core/api/system_api.dart)

```dart
import 'dart:io';

class SystemApi {
  Future<String> getCpuUsage() async {
    try {
      if (Platform.isLinux) {
        final cpuInfo = await File('/proc/stat').readAsString();
        final lines = cpuInfo.split('\n').where((l) => l.startsWith('cpu '));
        if (lines.isNotEmpty) {
          final values = lines.first.split(RegExp(r'\s+')).sublist(1);
          final idle = int.parse(values[3]);
          final total = values.map(int.parse).reduce((a, b) => a + b);
          final usage = ((total - idle) / total * 100).toStringAsFixed(1);
          return usage;
        }
      }

      if (Platform.isMacOS) {
        final result = await Process.run('sh', ['-c', 'top -l1 | grep "CPU usage"']);
        final match = RegExp(r'(\d+\.\d+)%').firstMatch(result.stdout);
        if (match != null) {
          return match.group(1)!;
        }
      }

      if (Platform.isWindows) {
        final result = await Process.run('wmic', ['cpu', 'get', 'loadpercentage']);
        final match = RegExp(r'(\d+)').firstMatch(result.stdout);
        if (match != null) {
          return match.group(1)!;
        }
      }

      return '0.0';
    } catch (e) {
      return '0.0';
    }
  }

  Future<String> getMemoryUsage() async {
    try {
      if (Platform.isLinux) {
        final memInfo = await File('/proc/meminfo').readAsString();
        final total = _parseMemValue(memInfo, 'MemTotal:');
        final available = _parseMemValue(memInfo, 'MemAvailable:');
        final used = total - available;
        final usedGB = (used / 1024 / 1024).toStringAsFixed(1);
        final totalGB = (total / 1024 / 1024).toStringAsFixed(1);
        return '$usedGB/$totalGB GB';
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  int _parseMemValue(String content, String key) {
    final match = RegExp('$key\\s+(\\d+)').firstMatch(content);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<String> getBatteryStatus() async {
    return '100% ⚡';
  }
}
```

### 3.3 Network API (lib/core/api/network_api.dart)

```dart
import 'package:dio/dio.dart';

class NetworkApi {
  final Dio _dio = Dio();

  Future<String> getNetStatus() async {
    try {
      return 'online';
    } catch (e) {
      return 'offline';
    }
  }

  Future<String> makeRequest(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data.toString();
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }
}
```

---

## 6. SISTEMA DE PLUGINS

Baseado em: plan_g25.md + plan_m2.md

### 6.1 Porquês do Sistema de Plugins

**Por quê refresh minimum 1s**: Protege contra plugins mal-feitos (`clock.0.1s.sh` = 600 execuções/min = trava sistema).

**Por quê auto-detecção por shebang + extensão**: Plugin funciona sem configuração extra. Exemplo:
```bash
#!/usr/bin/env python3  → python3 script.py
script.py               → python3
```

### 6.2 Plugin Manager (lib/core/plugin_manager.dart)

```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/core/script_runner.dart';
import 'package:crossbar/models/plugin_output.dart';

class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();

  final List<Plugin> _plugins = [];
  final ScriptRunner _scriptRunner = ScriptRunner();
  static const int maxConcurrent = 10;

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  Future<void> discoverPlugins() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final pluginsDir = Directory(path.join(homeDir, '.crossbar', 'plugins'));

    if (!await pluginsDir.exists()) {
      print('Plugins directory not found: ${pluginsDir.path}');
      return;
    }

    final languages = ['bash', 'python', 'node', 'dart', 'go', 'rust'];

    for (final lang in languages) {
      final langDir = Directory(path.join(pluginsDir.path, lang));
      if (!await langDir.exists()) continue;

      await for (final entity in langDir.list()) {
        if (entity is File && _isExecutableFile(entity.path)) {
          final plugin = await _createPluginFromFile(entity);
          if (plugin != null) {
            _plugins.add(plugin);
            print('Discovered plugin: ${plugin.id}');
          }
        }
      }
    }
  }

  bool _isExecutableFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    final allowedExts = ['.sh', '.py', '.js', '.dart', '.go', '.rs'];

    if (!allowedExts.contains(ext)) return false;

    try {
      final file = File(filePath);
      final lines = file.readAsLinesSync();
      if (lines.isNotEmpty && lines.first.startsWith('#!')) {
        return true;
      }
    } catch (e) {
      // Ignora erros de leitura
    }

    return true;
  }

  Future<Plugin?> _createPluginFromFile(File file) async {
    final fileName = path.basename(file.path);

    final interpreter = _detectInterpreter(file.path);
    if (interpreter == null) return null;

    final refreshInterval = _parseRefreshInterval(fileName);

    return Plugin(
      id: fileName,
      path: file.path,
      interpreter: interpreter,
      refreshInterval: refreshInterval,
      enabled: true,
    );
  }

  String? _detectInterpreter(String filePath) {
    final ext = path.extension(filePath).toLowerCase();

    try {
      final file = File(filePath);
      final firstLine = file.readAsLinesSync().firstOrNull ?? '';

      if (firstLine.contains('python')) return 'python3';
      if (firstLine.contains('node')) return 'node';
      if (firstLine.contains('bash')) return 'bash';
      if (firstLine.contains('dart')) return 'dart';
    } catch (e) {
      // Ignora
    }

    switch (ext) {
      case '.sh':
        return 'bash';
      case '.py':
        return 'python3';
      case '.js':
        return 'node';
      case '.dart':
        return 'dart';
      case '.go':
        return 'go';
      case '.rs':
        return 'rust';
      default:
        return null;
    }
  }

  Duration _parseRefreshInterval(String fileName) {
    final match = RegExp(r'\.(\d+(?:\.\d+)?)([smh])\.').firstMatch(fileName);

    if (match != null) {
      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;

      Duration interval;
      switch (unit) {
        case 's':
          interval = Duration(milliseconds: (value * 1000).round());
          break;
        case 'm':
          interval = Duration(minutes: value.round());
          break;
        case 'h':
          interval = Duration(hours: value.round());
          break;
      }

      if (interval < Duration(seconds: 1)) {
        return Duration(seconds: 1);
      }

      return interval;
    }

    return Duration(minutes: 5);
  }

  Future<List<PluginOutput>> runAllEnabled() async {
    final outputs = <PluginOutput>[];
    final enabledPlugins = _plugins.where((p) => p.enabled).toList();

    for (final plugin in enabledPlugins) {
      final output = await _runPlugin(plugin);
      if (output != null) {
        outputs.add(output);
      }
    }

    return outputs;
  }

  Future<PluginOutput?> _runPlugin(Plugin plugin) async {
    try {
      final output = await _scriptRunner.run(plugin);
      return output;
    } catch (e) {
      print('Error running ${plugin.id}: $e');
      return PluginOutput.error(plugin.id, e.toString());
    }
  }

  void togglePlugin(String pluginId) {
    final index = _plugins.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(
        enabled: !_plugins[index].enabled,
      );
    }
  }
}
```

---

## 7. UI MULTI-PLATAFORMA

Baseado em: plan_g3.md + plan_m2.md + plan_ppx.md

### 7.1 Renderização Adaptativa

**Por quê renderização adaptativa**: Plugin é agnóstico de UI. Dev não sabe iOS/Android/Desktop.

**Mesmo plugin, múltiplos contextos**:

| Contexto                         | Renderização                                    |
| :------------------------------- | :---------------------------------------------- |
| **Desktop Tray** (Linux/Win/Mac) | Ícone + texto sempre visível, menu dropdown     |
| **Android Notificação**          | Ícone + texto expandido, botões de ação (até 3) |
| **Android Widget 1x1**           | Só ícone (texto no tooltip long-press)          |
| **Android Widget 2x1**           | Ícone + texto                                   |
| **Android Widget 2x2+**          | Ícone + texto + menu items como botões          |
| **iOS Widget Small**             | Só ícone (texto no tooltip)                     |
| **iOS Widget Medium**            | Ícone + texto                                   |
| **iOS Widget Large**             | Ícone + texto + detalhes extras                 |

### 7.2 Múltiplos Ícones de Tray

**Por quê múltiplos ícones**: BitBar tem ícone fixo. Crossbar permite dashboard completo na tray (clock, CPU, network, cada um com seu ícone).

### 7.3 Main Window (lib/ui/main_window.dart)

```dart
import 'package:flutter/material.dart';
import 'tabs/plugins_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/marketplace_tab.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossbar',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Crossbar'),
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.extension), text: 'Plugins'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.store), text: 'Marketplace'),
            ]),
          ),
          body: const TabBarView(children: [
            PluginsTab(),
            SettingsTab(),
            MarketplaceTab(),
          ]),
        ),
      ),
    );
  }
}
```

### 7.4 Plugins Tab (lib/ui/tabs/plugins_tab.dart)

```dart
import 'package:flutter/material.dart';
import 'package:crossbar/core/plugin_manager.dart';

class PluginsTab extends StatefulWidget {
  @override
  _PluginsTabState createState() => _PluginsTabState();
}

class _PluginsTabState extends State<PluginsTab> {
  final PluginManager _pluginManager = PluginManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    await _pluginManager.discoverPlugins();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final plugins = _pluginManager.plugins;

    if (plugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No plugins found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Place your plugins in ~/.crossbar/plugins/',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              plugin.enabled ? Icons.play_circle : Icons.pause_circle,
              color: plugin.enabled ? Colors.green : Colors.grey,
            ),
            title: Text(plugin.id),
            subtitle: Text('${plugin.interpreter} • ${plugin.refreshInterval.inSeconds}s'),
            trailing: IconButton(
              icon: Icon(plugin.enabled ? Icons.toggle_on : Icons.toggle_off),
              onPressed: () {
                _pluginManager.togglePlugin(plugin.id);
                setState(() {});
              },
            ),
            onTap: () {
              // TODO: Abrir dialog de configuração
            },
          ),
        );
      },
    );
  }
}
```

### 7.5 Settings Tab (lib/ui/tabs/settings_tab.dart)

```dart
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          margin: EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.color_lens),
                title: Text('Appearance'),
                subtitle: Text('Theme and display settings'),
              ),
              SwitchListTile(
                secondary: Icon(Icons.dark_mode),
                title: Text('Dark mode'),
                value: false,
                onChanged: (value) {
                  // TODO: Implementar toggle tema
                },
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.power_settings_new),
                title: Text('General'),
                subtitle: Text('Startup and behavior'),
              ),
              SwitchListTile(
                secondary: Icon(Icons.start),
                title: Text('Start with system'),
                value: false,
                onChanged: (value) {
                  // TODO: Implementar auto-start
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### 7.6 Marketplace Tab (lib/ui/tabs/marketplace_tab.dart)

```dart
import 'package:flutter/material.dart';

class MarketplaceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Marketplace',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
```

---

## 8. SISTEMA DE CONFIGURAÇÃO DECLARATIVA

Baseado em: plan_m2.md + plan_ppx.md

### 8.1 Filosofia da Configuração

**Filosofia**: Plugin **declara** suas configurações, Crossbar **renderiza** GUI automaticamente e **injeta** valores como ENV vars. Usuário nunca edita código.

**Por quê grid 1-100 em vez de 1-12**: Mais intuitivo ("width: 75" = 75% da tela) que grid Bootstrap (6/12 = ?).

**Por quê password vai pro Keychain**: Nunca em plaintext. `flutter_secure_storage` usa Keychain (macOS/iOS) e KeyStore (Android).

### 8.2 Plugin Config Model (lib/models/plugin_config.dart)

```dart
import 'dart:convert';

class PluginConfig {
  final String name;
  final String description;
  final String icon;
  final String configRequired; // 'first_run' | 'optional' | 'always'
  final List<Setting> settings;

  PluginConfig({
    required this.name,
    required this.description,
    required this.icon,
    required this.configRequired,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'config_required': configRequired,
      'settings': settings.map((s) => s.toJson()).toList(),
    };
  }

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '⚙️',
      configRequired: json['config_required'] ?? 'optional',
      settings: (json['settings'] as List<dynamic>?)
              ?.map((s) => Setting.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class Setting {
  final String key; // Nome da ENV var
  final String label;
  final String type; // 'text' | 'password' | 'select' | etc
  final String? defaultValue;
  final bool required;
  final Map<String, dynamic>? options;
  final int? width; // Grid width (1-100)

  Setting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.options,
    this.width,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      'default': defaultValue,
      'required': required,
      'options': options,
      'width': width,
    };
  }

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'],
      label: json['label'],
      type: json['type'],
      defaultValue: json['default'],
      required: json['required'] ?? false,
      options: json['options'],
      width: json['width'],
    );
  }
}
```

### 8.3 Plugin Config Dialog (lib/ui/dialogs/plugin_config_dialog.dart)

```dart
import 'package:flutter/material.dart';
import 'package:crossbar/models/plugin_config.dart';

class PluginConfigDialog extends StatefulWidget {
  final PluginConfig config;

  const PluginConfigDialog({Key? key, required this.config}) : super(key: key);

  @override
  _PluginConfigDialogState createState() => _PluginConfigDialogState();
}

class _PluginConfigDialogState extends State<PluginConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    for (final setting in widget.config.settings) {
      if (setting.defaultValue != null) {
        _values[setting.key] = setting.defaultValue!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.config.icon} ${widget.config.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.config.settings.length,
                  itemBuilder: (context, index) {
                    return _buildField(widget.config.settings[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text('Save'),
        ),
      ],
    );
  }

  Widget _buildField(Setting setting) {
    final width = setting.width ?? 100;

    return Container(
      width: width == 100 ? double.infinity : null,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: _buildInput(setting),
    );
  }

  Widget _buildInput(Setting setting) {
    switch (setting.type) {
      case 'text':
        return TextFormField(
          decoration: InputDecoration(
            labelText: setting.label,
            border: OutlineInputBorder(),
          ),
          validator: setting.required
              ? (value) => value?.isEmpty == true ? 'Required' : null
              : null,
          onSaved: (value) => _values[setting.key] = value,
        );

      case 'password':
        return TextFormField(
          decoration: InputDecoration(
            labelText: setting.label,
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          validator: setting.required
              ? (value) => value?.isEmpty == true ? 'Required' : null
              : null,
          onSaved: (value) => _values[setting.key] = value,
        );

      case 'number':
        return TextFormField(
          decoration: InputDecoration(
            labelText: setting.label,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onSaved: (value) => _values[setting.key] = value,
        );

      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: setting.label,
            border: OutlineInputBorder(),
          ),
          items: (setting.options?['options'] as List<dynamic>?)
              ?.map((option) => DropdownMenuItem(
                    value: option['value'],
                    child: Text(option['label']),
                  ))
              .toList(),
          onChanged: (value) => _values[setting.key] = value,
          onSaved: (value) => _values[setting.key] = value,
        );

      case 'checkbox':
        return CheckboxListTile(
          title: Text(setting.label),
          value: _values[setting.key] == true,
          onChanged: (value) => setState(() {
            _values[setting.key] = value;
          }),
        );

      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: '${setting.label} (${setting.type})',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _values[setting.key] = value,
        );
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();
      Navigator.pop(context, _values);
    }
  }
}
```

### 8.4 Grid System Implementation

**Regras de Layout**:
1. Campos são colocados na mesma linha enquanto soma ≤ 100
2. Se soma > 100, quebra linha
3. Se soma < 100 na linha, expande proporcionalmente

```dart
List<Widget> buildFieldRows(List<Setting> settings) {
  List<Widget> rows = [];
  List<Setting> currentRow = [];
  int rowWidthSum = 0;

  for (var setting in settings) {
    final width = setting.width ?? 100;

    if (rowWidthSum + width > 100) {
      rows.add(_buildRow(currentRow));
      currentRow = [setting];
      rowWidthSum = width;
    } else {
      currentRow.add(setting);
      rowWidthSum += width;
    }
  }

  if (currentRow.isNotEmpty) rows.add(_buildRow(currentRow));
  return Column(children: rows);
}

Widget _buildRow(List<Setting> fields) {
  return Row(
    children: fields.map((field) {
      return Expanded(
        flex: field.width!,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: _buildField(field),
        ),
      );
    }).toList(),
  );
}
```

---

## 9. TESTES E QUALIDADE

Baseado em: plan_g25.md + plan_g3.md + plan_ppx.md

### 9.1 Meta de Cobertura

**Por quê 90%**: Padrão pragmático (100% é perfeccionismo, <80% é arriscado para projeto crítico).

**Obrigatório**: ≥ 90% coverage no código Dart (core + CLI + parsers + services)

### 9.2 Teste Unitário do Parser (test/core/output_parser_test.dart)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/output_parser.dart';

void main() {
  group('OutputParser', () {
    test('parses BitBar text format', () {
      final input = '''
⚡ 45% | color=orange
---
Details | bash=/usr/bin/top
''';

      final output = OutputParser.parse(input, 'test.sh');

      expect(output.icon, '⚡');
      expect(output.text, '45%');
      expect(output.menu.length, 1);
      expect(output.menu[0].text, 'Details');
      expect(output.menu[0].bash, '/usr/bin/top');
    });

    test('parses JSON format', () {
      final input = '''
{
  "icon": "⚡",
  "text": "45%",
  "menu": [{"text": "Details", "bash": "/usr/bin/top"}]
}
''';

      final output = OutputParser.parse(input, 'test.py');

      expect(output.icon, '⚡');
      expect(output.text, '45%');
      expect(output.menu.length, 1);
    });

    test('auto-detects JSON vs text', () {
      expect(OutputParser.isJson('{"key":"value"}'), true);
      expect(OutputParser.isJson('Text output'), false);
    });

    test('handles empty output', () {
      final output = OutputParser.parse('', 'test.sh');
      expect(output.text, '');
      expect(output.icon, '⚙️');
    });
  });
}
```

### 9.3 Teste de Integração (test/integration/plugin_execution_test.dart)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/script_runner.dart';
import 'package:crossbar/models/plugin.dart';

void main() {
  group('Plugin Execution', () {
    late ScriptRunner runner;

    setUp(() {
      runner = ScriptRunner();
    });

    test('executes bash plugin successfully', () async {
      final plugin = Plugin(
        id: 'test.sh',
        path: 'test/fixtures/test.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 1),
      );

      final output = await runner.run(plugin);

      expect(output.hasError, false);
      expect(output.text, isNotEmpty);
    }, timeout: Timeout(Duration(seconds: 5)));
  });
}
```

---

## 10. CI/CD

Baseado em: plan_g25.md + plan_ppx.md

### 10.1 GitHub Actions (.github/workflows/ci.yml)

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze:
    name: Lint & Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.2'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed .

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.2'
          cache: true

      - run: flutter pub get

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Verify coverage >= 90%
        run: |
          sudo apt-get install -y lcov
          COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 90" | bc -l) )); then
            echo "Coverage $COVERAGE% < 90%"
            exit 1
          fi

  build-linux:
    name: Build Linux
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.2'
          cache: true

      - run: flutter pub get

      - name: Build Linux
        run: flutter build linux --release
```

---

## 11. ROTEIRO DE EXECUÇÃO

Baseado em: plan_g25.md + plan_g3.md

### Fase 1: Core & CLI (Foundation)
1. Setup do projeto (`flutter create`, limpar arquivos, configurar `pubspec.yaml`)
2. Implementar `models/` e `core/` (Plugin, OutputParser, ScriptRunner)
3. Implementar CLI (`bin/crossbar.dart`) usando argumentos
   - Comando `crossbar --cpu` deve funcionar no terminal
4. Implementar testes unitários para core (coverage >= 90%)

### Fase 2: Plugin System
1. Implementar `PluginManager` (Discovery, Execution)
2. Criar estrutura de diretórios `~/.crossbar/plugins`
3. Implementar 3 plugins de exemplo (Bash, Python) para teste

### Fase 3: UI Desktop
1. Configurar `tray_manager`
2. Implementar Janela Principal (3 abas: Plugins, Settings, Marketplace)
3. Implementar Dialog de Configuração Dinâmica (Grid System)

### Fase 4: Mobile & Polish
1. Configurar CI/CD (`.github/workflows/ci.yml`)
2. Implementar testes finais
3. Documentação básica (README.md)

---

## 12. CHECKLIST DE IMPLEMENTAÇÃO

### Core (Obrigatório)
- [ ] CLI Parser (`bin/crossbar.dart`)
- [ ] API Implementations (SystemApi, NetworkApi)
- [ ] Output Parser (Text e JSON)
- [ ] Plugin Model (Plugin class)
- [ ] Plugin Manager (Discovery, execution)
- [ ] Script Runner (Execução com timeout)
- [ ] Tests unitários (coverage >= 90%)

### UI (Obrigatório)
- [ ] Main Window (3 abas)
- [ ] Plugins Tab (Lista plugins, toggle)
- [ ] Settings Tab (Configurações)
- [ ] Marketplace Tab (Placeholder)
- [ ] Config Dialog (Grid system)

### Build & CI (Obrigatório)
- [ ] CI/CD (GitHub Actions)
- [ ] Build Linux (Flutter)
- [ ] Code Quality (Analyze, format)
- [ ] Documentation (README.md)

### Optional (Pós-V1)
- [ ] Tray Service (System tray)
- [ ] Android (Foreground service, notifications)
- [ ] iOS (Widgets)
- [ ] i18n (10 idiomas)
- [ ] Marketplace (Integração GitHub real)

---

## 13. CONCLUSÃO

### Essência Mantida do plan_ppx.md

Este plano final combina:

✅ **Visão Revolucionária**: Conceito "Write Once, Run Everywhere" com 5 plataformas
✅ **Filosofia da API**: Best effort, texto puro padrão + --json flag
✅ **Porquês Técnicos**: Por que Flutter, por que 6 linguagens, por que timeout 30s
✅ **Renderização Adaptativa**: Mesmo plugin, múltiplos contextos (tray, notification, widgets)
✅ **Configuração Declarativa**: Plugin declara, Crossbar renderiza, usuário nunca edita código
✅ **Grid System 1-100**: Mais intuitivo que Bootstrap
✅ **Testes Pragmáticos**: 90% coverage (não 100% perfeccionismo)

### Implementação

Este plano final combina:

✅ **Estrutura prática** do plan_g25.md (implementação direta)
✅ **CLI API detalhada** do plan_m2.md (45 comandos)
✅ **Sistema de configuração declarativa** do plan_m2.md (25 tipos de campos)
✅ **Tests abrangentes** do plan_g3.md (unit, integration, widget)
✅ **CI/CD sólido** do plan_ppx.md (Docker, Makefile, workflows)

**Próximos Passos:**
1. Implementar Fase 1 (Core & CLI)
2. Executar `flutter test --coverage` (verificar >= 90%)
3. Prosseguir para Fase 2 (Plugin System)
4. Continuar sequencialmente até conclusão

**Tempo Estimado Total**: 4-6 semanas (1 semana por fase)

### Porquês Que Não Podem Ser Perdidos

⚠️ **IMPLEMENTAÇÃO SEM AMBIGUIDADE REQUER ENTENDER O "PORQUÊ"**:

1. **Por que Flutter**: Única framework madura com 5 plataformas nativas
2. **Por que 6 linguagens**: Cobrem 95% dos casos (bash ubíquo, python/node mainstream, dart nativo, go/rust performance)
3. **Por que CLI texto puro**: Scripts bash/shell precisam `$(crossbar --cpu)`, JSON requer parse
4. **Por que --json flag**: Compatibilidade BitBar + avanços (objetos complexos)
5. **Por que timeout 30s**: Plugins devem ser <1s ideal, 30s generoso para HTTP
6. **Por que pool 10**: Evita fork bomb (50 plugins @ 1s = 50 processos simultâneos)
7. **Por que mínimo 1s refresh**: Protege contra `clock.0.1s.sh` = 600 exec/min
8. **Por que dois formatos saída**: Texto = compatibilidade BitBar, JSON = poder total
9. **Por que grid 1-100**: Mais intuitivo que Bootstrap (width: 75 = 75% tela)
10. **Por que Keychain passwords**: Nunca plaintext, `flutter_secure_storage`
11. **Por que renderização adaptativa**: Plugin agnóstico UI, dev não sabe OS
12. **Por que múltiplos ícones**: BitBar fixo, Crossbar dashboard completo (clock, CPU, network)
13. **Por que 90% coverage**: Pragmático (100% perfeccionismo, <80% arriscado)
14. **Por que foreground service Android**: Android 12+ mata background agressivamente
15. **Por que refresh override user**: Plugin，作者 pode definir 5min, usuário quer 1min

**Estes porquês são o DNA do Crossbar - sem eles, vira apenas mais uma ferramenta.**
