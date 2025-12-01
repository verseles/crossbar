# CROSSBAR - PLANO MESTRE DEFINITIVO

> **Documento Unificado**: Este é o plano mestre oficial que consolida e substitui todos os outros documentos de planejamento (`final_plan.md`, `original_plan.md`, `plan.md`).

**Sistema Universal de Plugins para Barra de Tarefas/Menu Bar**

**Repositório**: `verseles/crossbar`
**Licença**: AGPLv3 (garante que derivados e serviços SaaS retornem melhorias à comunidade)
**Tecnologia**: Dart 3.10+ + Flutter 3.35+
**Plataformas**: Linux, Windows, macOS, Android, iOS
**Última Atualização**: 01 de Dezembro de 2025

---

## ÍNDICE

1. [Visão Geral e Filosofia](#1-visão-geral-e-filosofia)
2. [Arquitetura e Tech Stack](#2-arquitetura-e-tech-stack)
3. [Estrutura de Diretórios](#3-estrutura-de-diretórios)
4. [Implementação Técnica Core](#4-implementação-técnica-core)
5. [CLI API Unificada](#5-cli-api-unificada)
6. [Sistema de Plugins](#6-sistema-de-plugins)
7. [Configuração Declarativa](#7-configuração-declarativa)
8. [UI/UX Multi-Plataforma](#8-uiux-multi-plataforma)
9. [Internacionalização (i18n)](#9-internacionalização-i18n)
10. [Testes e Qualidade](#10-testes-e-qualidade)
11. [Build & CI/CD](#11-build--cicd)
12. [Marketplace e Ecossistema](#12-marketplace-e-ecossistema)
13. [Roadmap de Execução](#13-roadmap-de-execução)
14. [Performance Targets](#14-performance-targets)
15. [Porquês Essenciais (DNA do Crossbar)](#15-porquês-essenciais-dna-do-crossbar)
16. [Roadmap Futuro (Pós-V1)](#16-roadmap-futuro-pós-v1)
17. [Anexos Técnicos](#17-anexos-técnicos)

---

## 1. VISÃO GERAL E FILOSOFIA

### 1.1 Conceito

Crossbar é um sistema revolucionário de plugins cross-platform inspirado em BitBar (macOS) e Argos (Linux), que eleva o conceito para todas as plataformas desktop e mobile com uma API unificada.

**Diferenciais Revolucionários**:

1. **API CLI Unificada**: Plugin escreve `crossbar --cpu` uma única vez, funciona em 5 plataformas (BitBar/Argos forçam cada dev a reimplementar para cada OS).

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

**Por quê Dart 3.10+**:
- **Por quê**: Linguagem type-safe, null-safety nativo, tooling excelente, ecossistema pub.dev maduro.
- **CLI nativa**: `dart:io` permite criar CLI completa sem dependências externas.

**Por quê esses 6 linguagens de plugin**: Cobrem 95% dos casos (bash ubíquo, python/node mainstream, dart nativo Flutter, go/rust para performance).
- Bash (.sh) - Universal em Linux/macOS
- Python (.py) - `python3` (não python2)
- Node.js (.js) - `node` ou `#!/usr/bin/env node`
- Dart (.dart) - `dart run` (Flutter SDK)
- Go (.go) - `go run` (requer Go SDK)
- Rust (.rs) - Compila com `rustc`, executa binário

### 2.2 Versões de Tecnologia (Validadas Nov 2025)

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

### 2.3 Packages Flutter Críticos

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

## 3. ESTRUTURA DE DIRETÓRIOS

```
crossbar/
├── lib/
│   ├── core/                      # Lógica de negócio
│   │   ├── plugin_manager.dart    # Detecta, carrega, executa plugins
│   │   ├── script_runner.dart     # Process.run com timeout, ENV injection
│   │   ├── config_parser.dart     # Parse .config.json + embutido
│   │   ├── output_parser.dart     # Parse texto BitBar OU JSON
│   │   └── api/                   # CLI API (~45 comandos)
│   │       ├── system_api.dart    # --cpu, --memory, --battery
│   │       ├── network_api.dart   # --web, --net-status, --wifi
│   │       ├── media_api.dart     # --media-play, --audio-volume
│   │       └── utils_api.dart     # --hash, --uuid, --notify
│   ├── ui/                        # Flutter UI
│   │   ├── main_window.dart       # Janela principal (3 abas)
│   │   ├── tabs/
│   │   │   ├── plugins_tab.dart   # Lista plugins, preview, status
│   │   │   ├── settings_tab.dart  # Config global (tema, tray, i18n)
│   │   │   └── marketplace_tab.dart # Busca GitHub, instala plugins
│   │   ├── dialogs/
│   │   │   └── plugin_config_dialog.dart # Form auto-gerado
│   │   └── widgets/
│   │       ├── config_fields/     # 25 tipos: TextInput, ColorPicker, etc
│   │       └── plugin_preview.dart # Preview saída do plugin
│   ├── models/                    # Data classes
│   │   ├── plugin.dart            # Plugin metadata
│   │   ├── plugin_config.dart     # Schema de configuração
│   │   └── plugin_output.dart     # Saída parseada
│   ├── services/
│   │   ├── tray_service.dart      # Gerencia múltiplos tray icons
│   │   ├── notification_service.dart # Android foreground + notificações
│   │   ├── widget_service.dart    # Home screen widgets (Android/iOS)
│   │   └── ipc_server.dart        # HTTP localhost:48291 (GUI ↔ background)
│   ├── utils/
│   │   ├── file_watcher.dart      # Hot reload plugins (debounce 1s)
│   │   └── logger.dart            # Logs rotativos (5MB, 7 dias)
│   └── l10n/                      # i18n (10 idiomas)
│       └── app_*.arb              # en, pt_BR, es, fr, zh, hi, ar, bn, ru, ja
├── bin/
│   └── crossbar.dart              # CLI entrypoint (executa comandos API)
├── test/
│   ├── unit/                      # Testes unitários (core, parsers, API)
│   ├── integration/               # Executa plugins reais, valida saída
│   └── widget/                    # Testes de UI Flutter
├── plugins/                       # 24 plugins exemplo (4 funcs × 6 langs)
│   ├── bash/
│   ├── python/
│   ├── node/
│   ├── dart/
│   ├── go/
│   └── rust/
├── docker/
│   ├── Dockerfile.linux
│   ├── Dockerfile.android
│   ├── Dockerfile.macos
│   └── Dockerfile.windows
├── .github/
│   └── workflows/
│       └── ci.yml                 # Matrix builds (5 plataformas)
├── docs/
│   ├── api-reference.md           # CLI API completa
│   ├── plugin-development.md      # Tutorial passo-a-passo
│   └── config-schema.md           # Tipos de campos de configuração
├── Makefile                       # Dev local (Docker/nativo)
├── docker-compose.yml
├── podman-compose.yml
├── pubspec.yaml
└── README.md
```

---

## 4. IMPLEMENTAÇÃO TÉCNICA CORE

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

### 4.4 Plugin Manager (lib/core/plugin_manager.dart)

```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/core/script_runner.dart';
import 'package:crossbar/core/output_parser.dart';

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

## 5. CLI API UNIFICADA

### 5.1 Filosofia da API

**"Best Effort"**: Todos comandos tentam executar, retornam erro claro se falharem (ex: permissão negada, feature não disponível no OS).

**Por quê texto puro padrão**: Scripts bash/shell precisam de saída simples para `$(crossbar --cpu)`. JSON requer parse (jq, python).

**Por quê `--json` como flag**: Mantém compatibilidade com BitBar (texto) mas permite avanços (objetos complexos).

**Formatos de Saída**:
- Padrão: texto puro (compatível BitBar, parseável em bash)
- `--json`: objeto JSON estruturado
- `--xml`: XML (para integração legada)

### 5.2 Comandos Completos (~45 total)

#### Sistema

```bash
crossbar --cpu                   # % uso CPU (0-100)
crossbar --memory                # RAM livre/total (ex: "8.2/16.0 GB")
crossbar --disk [path]           # Espaço disco (padrão: /, ou path específico)
crossbar --battery               # Nível bateria + charging (ex: "87% ⚡")
crossbar --uptime                # Tempo desde boot (ex: "3d 12h 45m")
crossbar --cpu-temp              # Temperatura CPU °C (best effort)
crossbar --os                    # "linux" | "windows" | "macos" | "android" | "ios"
crossbar --os --json             # {"short":"linux","name":"Ubuntu","version":"24.04"}
```

#### Rede & Conectividade

```bash
crossbar --net                   # Download/upload Mbps (ex: "12.5↓ 1.2↑")
crossbar --net-status            # "online" | "offline" | "wifi" | "cellular" | "ethernet"
crossbar --net-ssid              # Nome WiFi conectado
crossbar --net-ip                # IP local
crossbar --net-ip --public       # IP público (via API ipify.org)
crossbar --net-ping <host>       # Latência ms
crossbar --wifi-on               # Liga WiFi
crossbar --wifi-off              # Desliga WiFi
crossbar --bluetooth-status      # "on" | "off" | "devices:3"
crossbar --vpn-status            # "connected:NordVPN" | "disconnected"

crossbar --web <url> \
  [--method GET|POST|PUT|DELETE|HEAD] \
  [--headers '{"Authorization":"Bearer token"}'] \
  [--body '{"key":"value"}'] \
  [--timeout 5s] \
  [--json | --xml]
```

#### Dispositivo & Localização

```bash
crossbar --device-model          # "iPhone 15 Pro" / "ThinkPad X1 Carbon"
crossbar --device-screen --json  # {"width":1920,"height":1080,"dpi":96}
crossbar --locale                # "pt_BR"
crossbar --timezone              # "America/Sao_Paulo"
crossbar --location --json       # {"lat":-23.550520,"lon":-46.633308}
crossbar --location-city         # "São Paulo"
```

#### Áudio & Mídia

```bash
# GET
crossbar --audio-volume          # "75"
crossbar --audio-output          # "speakers" | "headphones" | "bluetooth"
crossbar --media-playing --json  # {"app":"Spotify","title":"Song","status":"playing"}

# SET (controles bidirecionais)
crossbar --audio-volume-set 50   # Define volume 0-100
crossbar --audio-mute            # Toggle mute
crossbar --media-play            # Resume playback
crossbar --media-pause
crossbar --media-next
crossbar --media-prev
crossbar --screen-brightness-set 30
```

#### Clipboard

```bash
crossbar --clipboard             # Conteúdo atual (texto)
crossbar --clipboard-set "text"  # Copia para clipboard
crossbar --clipboard-clear
```

#### Processos & Apps

```bash
crossbar --process-list --json   # Top 5 por CPU
crossbar --process-count         # Total de processos rodando
crossbar --process-find <name>   # Retorna PID
crossbar --process-kill <pid>    # Kill processo
crossbar --app-running <name>    # "true" | "false"
```

#### UI & Sistema

```bash
crossbar --screenshot [path]     # Tira screenshot
crossbar --wallpaper-get         # Path do wallpaper atual
crossbar --wallpaper-set <path>  # Define novo wallpaper

crossbar --notify "Título" "Mensagem" \
  [--icon "⚠️"] \
  [--sound "default"] \
  [--priority high|normal|low]

crossbar --dnd-status            # Do Not Disturb: "on" | "off"
crossbar --open-url "https://google.com"
crossbar --open-app "spotify"
crossbar --power-sleep
crossbar --power-restart
crossbar --power-shutdown
```

#### Utilitários

```bash
crossbar --hash "texto" [--algo md5|sha1|sha256|sha512|blake3]
crossbar --uuid                  # Gera UUID v4
crossbar --random [min] [max]    # Número aleatório
crossbar --qr-generate "text"    # QR code base64 PNG
crossbar --base64-encode "text"
crossbar --base64-decode "dGV4dA=="
crossbar --time [fmt=12h|24h]    # Hora local
```

### 5.3 Matriz de Compatibilidade

| Comando         | Linux | Windows | macOS | Android | iOS | Notas                         |
| :-------------- | :---- | :------ | :---- | :------ | :-- | :---------------------------- |
| --cpu           | ✅    | ✅      | ✅    | ✅      | ✅  |                               |
| --battery       | ✅    | ✅      | ✅    | ✅      | ✅  |                               |
| --web           | ✅    | ✅      | ✅    | ✅      | ✅  | Dio cross-platform            |
| --wifi-on/off   | ⚠️    | ⚠️      | ⚠️    | ⚠️      | ❌  | Precisa permissões elevadas   |
| --media-play    | ✅    | ✅      | ✅    | ✅      | ⚠️  | iOS: só em foreground         |
| --screenshot    | ✅    | ✅      | ✅    | ✅      | ❌  | iOS: impossível em background |
| --wallpaper-set | ✅    | ✅      | ✅    | ✅      | ❌  | iOS: restrição sandbox        |

**Legenda**: ✅ Funciona, ⚠️ Best effort (pode precisar permissão), ❌ Impossível (limitação OS)

### 5.4 Variáveis de Ambiente Injetadas

**SEMPRE injetadas** em todo plugin:

```bash
CROSSBAR_OS=linux             # Short name do OS
CROSSBAR_DARK_MODE=true       # Tema do sistema (dark/light)
CROSSBAR_VERSION=1.0.0        # Versão do Crossbar
CROSSBAR_PLUGIN_ID=cpu.10s.sh # Nome do plugin
```

**Configs do usuário** (de `~/.crossbar/configs/<plugin>.json`):

```bash
WEATHER_API_KEY=abc123        # Password vem do Keychain (não do JSON)
WEATHER_LOCATION=São Paulo
WEATHER_UNITS=metric
```

### 5.5 CLI Entry Point (bin/crossbar.dart)

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

String? _getArg(List<String> args, dynamic key) {
  if (key is int) {
    return key < args.length ? args[key] : null;
  }
  final index = args.indexOf(key as String);
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

### 5.6 System API (lib/core/api/system_api.dart)

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

### 5.7 Network API (lib/core/api/network_api.dart)

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

### 6.1 Auto-detecção de Linguagem

**Por extensão + shebang**:

```python
# Prioridade 1: Shebang
#!/usr/bin/env python3  → python3 script.py
#!/usr/bin/env node     → node script.js
#!/bin/bash             → bash script.sh

# Prioridade 2: Extensão
script.py   → python3
script.js   → node
script.sh   → bash
script.dart → dart run
script.go   → go run
script.rs   → rustc + execute binary
```

### 6.2 Refresh Interval (Parsing de Nome)

**Por quê mínimo 1s**: Protege contra plugins mal-feitos (`clock.0.1s.sh` = 600 execuções/min = trava sistema).

**Padrão**: Se o nome não tem intervalo, usa 5 minutos.

**Override do usuário**:

```json
// ~/.crossbar/configs/weather.5m.py.json
{
  "_crossbar_refresh_override": "1m"
}
```

### 6.3 Parser de Saída (BitBar Text OU JSON)

**Auto-detect**: Primeira linha começa com `{` → JSON, senão → texto BitBar.

#### Formato Texto (BitBar-compatible)

```
Primeira linha → Tray icon/text
---
Linhas seguintes → Menu dropdown

Atributos:
| color=red
| size=12
| bash=/path/script.sh
| href=https://url.com
| refresh=true
```

#### Formato JSON (Avançado)

```json
{
  "icon": "⚡",
  "text": "45%",
  "color": "#FF5733",
  "tray_tooltip": "CPU Usage: 45%",
  "menu": [
    { "text": "CPU: 45%", "color": "orange" },
    { "separator": true },
    {
      "text": "Core 1: 50%",
      "submenu": [{ "text": "User: 30%" }, { "text": "System: 20%" }]
    },
    { "text": "Details", "bash": "/usr/bin/top" },
    { "text": "Monitor", "href": "https://monitor.local" }
  ]
}
```

**Por quê dois formatos**: Texto = compatibilidade BitBar, onboarding fácil. JSON = poder total (submenus, cores, ícones custom).

### 6.4 Hot Reload (File Watcher)

**Por quê debounce 1s**: Vim salva múltiplas vezes ao `:w`. 1s evita reload repetido.

```dart
class PluginWatcher {
  final _debouncer = <String, Timer>{};

  void watch(Directory pluginsDir) {
    pluginsDir.watch(recursive: true).listen((event) {
      if (event.path.endsWith('.sh') ||
          event.path.endsWith('.py') ||
          event.path.endsWith('.js') ||
          // ... outras extensões
      ) {
        _debounceReload(event.path);
      }
    });
  }

  void _debounceReload(String path) {
    // Cancela timer anterior (usuário salvando múltiplas vezes)
    _debouncer[path]?.cancel();

    // Aguarda 1s de silêncio antes de recarregar
    _debouncer[path] = Timer(Duration(seconds: 1), () {
      log('Hot reload: $path');
      PluginManager.reload(path);
    });
  }
}
```

---

## 7. CONFIGURAÇÃO DECLARATIVA

### 7.1 Filosofia

Plugin **declara** suas configurações, Crossbar **renderiza** GUI automaticamente e **injeta** valores como ENV vars. Usuário nunca edita código.

**Dois formatos aceitos** (precedência: JSON externo > embutido):

1. **Arquivo separado** (`plugin.config.json`)
2. **Bloco embutido** no script (comentário `CROSSBAR_CONFIG:`)

### 7.2 Schema de Configuração

```json
{
  "name": "Weather Widget",
  "description": "Shows weather for your location",
  "icon": "🌤️",
  "config_required": "first_run",

  "settings": [
    {
      "key": "WEATHER_API_KEY",
      "label": "OpenWeather API Key",
      "type": "password",
      "required": true,
      "placeholder": "Enter API key",
      "help": "Get free key at openweathermap.org",
      "width": 100
    },
    {
      "key": "WEATHER_LOCATION",
      "label": "Location",
      "type": "text",
      "default": "São Paulo",
      "required": true,
      "width": 60
    },
    {
      "key": "WEATHER_UNITS",
      "label": "Units",
      "type": "select",
      "options": [
        { "value": "metric", "label": "Celsius" },
        { "value": "imperial", "label": "Fahrenheit" }
      ],
      "default": "metric",
      "width": 40
    }
  ]
}
```

### 7.3 Tipos de Campos (25 total)

#### Inputs Básicos
```json
{"type": "text", "placeholder": "Enter text"}
{"type": "password"}  // → Flutter Keychain (SecureStorage)
{"type": "number", "min": 1, "max": 100, "step": 5}
{"type": "textarea", "rows": 5}
{"type": "hidden", "default": "1.0.0"}
```

#### Seleção
```json
{"type": "select", "options": [{"value": "a", "label": "Option A"}]}
{"type": "radio", "options": [...]}
{"type": "checkbox", "default": true}
{"type": "switch"}
{"type": "multiselect", "options": [...]}
{"type": "tags", "suggestions": ["tag1", "tag2"]}
```

#### Arquivos
```json
{"type": "file", "accept": ".png,.jpg", "maxSize": "2MB"}
{"type": "directory"}
{"type": "path"}
{"type": "image", "preview": true}
```

#### Visual
```json
{"type": "color", "default": "#FF0000"}
{"type": "slider", "min": 0, "max": 100, "step": 10, "unit": "%"}
{"type": "range", "min": 0, "max": 100, "default": {"min": 20, "max": 80}}
{"type": "icon", "options": "emoji"}
```

#### Data/Hora
```json
{"type": "date", "default": "2025-01-01"}
{"type": "time", "default": "09:00"}
{"type": "datetime"}
```

#### Avançados
```json
{"type": "keyvalue", "placeholder": {"key": "Header", "value": "Value"}}
{"type": "json", "syntax": true}
{"type": "code", "language": "python", "rows": 10}
{"type": "url", "protocols": ["https"]}
```

#### Layout
```json
{"type": "section", "label": "Authentication"}
{"type": "separator"}
{"type": "tabs", "tabs": [...]}
{"type": "collapsible", "label": "Advanced", "collapsed": true, "fields": [...]}
{"type": "info", "text": "⚠️ Requires restart", "variant": "warning"}
```

### 7.4 Grid System (1-100)

**Por quê 1-100 em vez de 1-12**: Mais intuitivo ("width: 75" = 75% da tela) que grid Bootstrap (6/12 = ?).

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

### 7.5 Armazenamento Seguro (Passwords)

**Tipo `password` NUNCA vai pra disco em plaintext**:

1. GUI pede senha → usuário digita → salva no **Keychain** (macOS/iOS), **KeyStore** (Android), **Credential Manager** (Windows), **Secret Service** (Linux)
2. Arquivo de config salva apenas **referência**:

```json
{
  "GITHUB_TOKEN": { "secureRef": "github_status.token.v1" }
}
```

3. Na execução, Crossbar resolve:

```dart
final token = await SecureStorage().read(key: 'github_status.token.v1');
env['GITHUB_TOKEN'] = token;  // Injeta no processo do plugin
```

### 7.6 Plugin Config Model (lib/models/plugin_config.dart)

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

---

## 8. UI/UX MULTI-PLATAFORMA

### 8.1 Renderização Adaptativa

**Por quê renderização adaptativa**: Plugin é agnóstico de UI. Dev não precisa saber iOS/Android/Desktop.

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

### 8.2 Múltiplos Ícones de Tray (Desktop)

**Por quê múltiplos ícones**: BitBar tem ícone fixo. Crossbar permite dashboard completo na tray (clock, CPU, network, cada um com seu ícone).

**Modo consolidado** (Settings → "Single tray icon"):

```
Em vez de: [🕐] [⚡45%] [📶12Mbps]
Fica:      [📊] → menu:
              Clock
              CPU: 45%
              Network: 12Mbps
```

### 8.3 Android - Notificações Persistentes

**Por quê foreground service**: Android 12+ mata processos em background agressivamente. Notificação persistente = garantia de execução.

```kotlin
class CrossbarForegroundService : Service() {
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("Crossbar")
      .setContentText("3 plugins active")
      .setSmallIcon(R.drawable.ic_crossbar)
      .setOngoing(true)
      .build()

    startForeground(NOTIFICATION_ID, notification)
    return START_STICKY
  }
}
```

### 8.4 Main Window (lib/ui/main_window.dart)

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

### 8.5 Plugins Tab (lib/ui/tabs/plugins_tab.dart)

```dart
import 'package:flutter/material.dart';
import 'package:crossbar/core/plugin_manager.dart';

class PluginsTab extends StatefulWidget {
  const PluginsTab({super.key});

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
      return const Center(child: CircularProgressIndicator());
    }

    final plugins = _pluginManager.plugins;

    if (plugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No plugins found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

### 8.6 Settings Tab (lib/ui/tabs/settings_tab.dart)

```dart
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.color_lens),
                title: Text('Appearance'),
                subtitle: Text('Theme and display settings'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                value: false,
                onChanged: (value) {
                  // TODO: Implementar toggle tema
                },
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.power_settings_new),
                title: Text('General'),
                subtitle: Text('Startup and behavior'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.start),
                title: const Text('Start with system'),
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

### 8.7 Marketplace Tab (lib/ui/tabs/marketplace_tab.dart)

```dart
import 'package:flutter/material.dart';

class MarketplaceTab extends StatelessWidget {
  const MarketplaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Marketplace',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
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

## 9. INTERNACIONALIZAÇÃO (i18n)

### 9.1 Sistema de Tradução

**Package**: `intl` (oficial Google, compile-time safety)

**Por quê intl em vez de easy_localization**:
- Compile-time checks detectam traduções faltando
- Suporte oficial de longo prazo pelo time Flutter
- ICU completo (plurais complexos, gênero, formatação)

**Por quê esses 10 idiomas**: Cobrem 4+ bilhões de falantes (top 10 mundial por total speakers).

**Estrutura**:

```
lib/l10n/
├── app_en.arb       # Inglês (base)
├── app_pt_BR.arb    # Português Brasileiro
├── app_es.arb       # Espanhol
├── app_fr.arb       # Francês
├── app_zh.arb       # Chinês Simplificado
├── app_hi.arb       # Hindi
├── app_ar.arb       # Árabe (RTL automático)
├── app_bn.arb       # Bengali
├── app_ru.arb       # Russo
└── app_ja.arb       # Japonês
```

### 9.2 Formato ARB

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Crossbar",
  "pluginsTab": "Plugins",
  "settingsTab": "Settings",
  "marketplaceTab": "Marketplace",

  "configDialog_title": "Configure: {pluginName}",
  "@configDialog_title": {
    "placeholders": {
      "pluginName": { "type": "String" }
    }
  },

  "marketplace_stars": "{count, plural, =0{No stars} =1{1 star} other{{count} stars}}"
}
```

---

## 10. TESTES E QUALIDADE

### 10.1 Meta de Cobertura

**Por quê 90%**: Padrão pragmático (100% é perfeccionismo, <80% é arriscado para projeto crítico).

**Obrigatório**: ≥ 90% coverage no código Dart (core + CLI + parsers + services)

### 10.2 Estrutura de Testes

```
test/
├── unit/                           # Testes unitários (funções puras)
│   ├── core/
│   │   ├── plugin_manager_test.dart
│   │   ├── output_parser_test.dart
│   │   ├── config_parser_test.dart
│   │   └── api/
│   │       ├── system_api_test.dart
│   │       └── network_api_test.dart
│   ├── models/
│   │   └── plugin_test.dart
│   └── utils/
│       └── file_watcher_test.dart
│
├── integration/                    # Testes end-to-end
│   ├── plugin_execution_test.dart
│   ├── cli_test.dart
│   └── marketplace_test.dart
│
└── widget/                        # Testes de UI Flutter
    ├── plugin_config_dialog_test.dart
    ├── plugins_tab_test.dart
    └── settings_tab_test.dart
```

### 10.3 Exemplos de Testes

#### Teste Unitário (Parser)

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

#### Teste de Integração

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

## 11. BUILD & CI/CD

### 11.1 Makefile (Comandos Unificados)

```makefile
COMPOSE := $(shell command -v docker-compose 2>/dev/null || command -v podman-compose 2>/dev/null)
FLUTTER := $(shell command -v flutter 2>/dev/null)

.PHONY: setup run test lint build-linux build-android

setup:
ifdef FLUTTER
	flutter pub get
else
	$(COMPOSE) run --rm flutter-dev flutter pub get
endif

run:
ifdef FLUTTER
	flutter run -d linux
else
	$(COMPOSE) up flutter-dev
endif

test:
ifdef FLUTTER
	flutter test --coverage
else
	$(COMPOSE) run --rm flutter-test
endif

lint:
ifdef FLUTTER
	flutter analyze
	dart format --set-exit-if-changed lib/ test/
else
	$(COMPOSE) run --rm flutter-dev flutter analyze
endif

build-linux:
ifdef FLUTTER
	flutter build linux --release
else
	$(COMPOSE) run --rm flutter-linux
endif

build-android:
ifdef FLUTTER
	flutter build apk --release
else
	$(COMPOSE) run --rm flutter-android
endif
```

### 11.2 GitHub Actions CI/CD

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

env:
  FLUTTER_VERSION: "3.35.2"

jobs:
  analyze:
    name: Lint & Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage
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
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter build linux --release
      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-linux
          path: build/linux/x64/release/bundle/

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: "zulu"
          java-version: "25"
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-android
          path: build/app/outputs/flutter-apk/app-release.apk

  build-windows:
    name: Build Windows
    runs-on: windows-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter build windows --release

  build-macos:
    name: Build macOS
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter build macos --release
```

---

## 12. MARKETPLACE E ECOSSISTEMA

### 12.1 Busca no GitHub

**Tag padrão**: `#crossbar` (devs marcam repos de plugins)

```dart
class MarketplaceService {
  final Dio dio;

  Future<List<PluginRepo>> search(String query, {String? language}) async {
    final searchQuery = [
      'topic:crossbar',
      if (query.isNotEmpty) query,
      if (language != null) 'language:$language',
    ].join(' ');

    final response = await dio.get(
      'https://api.github.com/search/repositories',
      queryParameters: {
        'q': searchQuery,
        'sort': 'stars',
        'order': 'desc',
        'per_page': 30,
      },
    );

    return (response.data['items'] as List)
      .map((item) => PluginRepo.fromJson(item))
      .toList();
  }
}
```

### 12.2 Instalação de Plugin

```bash
crossbar install https://github.com/user/weather-plugin
```

**Processo**:
1. Clone repo temporário
2. Detecta arquivos executáveis (shebang ou extensão)
3. Valida estrutura mínima (README, LICENSE)
4. Move pra `~/.crossbar/plugins/<language>/`
5. `chmod +x` (Linux/macOS)
6. Detecta `.config.json` (se existir)
7. Ativa plugin automaticamente

### 12.3 Template de Plugin

```bash
crossbar init --lang python --type clock
```

Gera:
```
~/.crossbar/plugins/python/clock.5s.py
~/.crossbar/plugins/python/clock.config.json
```

---

## 13. ROADMAP DE EXECUÇÃO

### Fase 1: Core & CLI (Semanas 1-2)
- [ ] Setup projeto Flutter (pubspec.yaml, estrutura dirs)
- [ ] CLI parser (crossbar --cpu, --memory, --battery básicos)
- [ ] Plugin manager (detecta, carrega, executa bash/python)
- [ ] Output parser (texto BitBar)
- [ ] Testes unitários (coverage > 90%)

### Fase 2: UI Básica (Semanas 3-4)
- [ ] Tray service (ícone único, menu dropdown)
- [ ] GUI principal (3 abas básicas)
- [ ] Plugins tab (lista, ativa/desativa)
- [ ] Settings tab (tema, idioma)
- [ ] Testes de widget

### Fase 3: Configuração (Semanas 5-6)
- [ ] Config parser (.config.json + embutido)
- [ ] 10 tipos de campos básicos (text, number, select, checkbox, etc)
- [ ] Dialog auto-gerado
- [ ] Secure storage (passwords → Keychain)
- [ ] Testes de integração

### Fase 4: API Completa (Semanas 7-8)
- [ ] 45 comandos CLI implementados
- [ ] Dio para --web
- [ ] ENV vars injetadas
- [ ] Matriz de compatibilidade testada

### Fase 5: Mobile (Semanas 9-10)
- [ ] Android foreground service
- [ ] Notificações persistentes
- [ ] Widgets (3 tamanhos)
- [ ] iOS widgets (WidgetKit)

### Fase 6: Polish (Semanas 11-12)
- [ ] i18n (10 idiomas)
- [ ] Marketplace tab (busca GitHub, instala)
- [ ] Hot reload (file watcher)
- [ ] Logs rotativos
- [ ] 24 plugins exemplo
- [ ] Documentação completa
- [ ] CI/CD configurado

### Fase 7: Release (Semana 13)
- [ ] Builds finais (5 plataformas)
- [ ] Release notes
- [ ] Publicação GitHub Releases
- [ ] README atualizado
- [ ] Anúncio em redes sociais

---

## 14. PERFORMANCE TARGETS

| Métrica | Target |
|---------|--------|
| Boot Time (desktop) | < 2s |
| Boot Time (Android cold start) | < 3s |
| Memory Footprint (idle, 3 plugins) | < 150MB (desktop), < 100MB (mobile) |
| Plugin Execution Overhead | < 50ms |
| Hot Reload | < 1s |
| CI/CD Total (5 plataformas) | < 15 minutos |

---

## 15. PORQUÊS ESSENCIAIS (DNA DO CROSSBAR)

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
15. **Por que refresh override user**: Dev define 5min, usuário quer 1min

**Estes porquês são o DNA do Crossbar - sem eles, vira apenas mais uma ferramenta.**

---

## 16. ROADMAP FUTURO (Pós-V1)

### V2.0 (6-12 meses após lançamento)
- Telemetria opt-in: OpenTelemetry + Grafana
- Package managers: Homebrew, Snap, Flatpak, winget, AUR
- Plugin sandboxing (opcional): Permissões granulares
- Sync de configs: Backup automático via GitHub Gists
- Theme customization: Além de dark/light, temas custom
- Voice commands: Integração com assistentes
- Widgets maiores: 4x4, full-screen widgets
- Remote plugins: Plugins rodando em servidores

### Métricas de Sucesso (6 meses pós-lançamento)
- 1.000+ stars no GitHub
- 50+ plugins comunitários
- 10.000+ downloads
- 5+ contribuidores ativos
- 0 issues críticas abertas por >48h

---

## 17. ANEXOS TÉCNICOS

### ANEXO A: Documentação e Recursos Técnicos

#### 📚 Documentação Oficial

##### Flutter & Dart

- **Flutter Documentation**: https://docs.flutter.dev/
- **Flutter Desktop**: https://docs.flutter.dev/platform-integration/desktop
- **Flutter Android**: https://docs.flutter.dev/platform-integration/android
- **Flutter iOS**: https://docs.flutter.dev/platform-integration/ios
- **Dart Language Tour**: https://dart.dev/language
- **Dart Packages**: https://pub.dev/
- **Flutter Testing**: https://docs.flutter.dev/testing
- **Flutter Architecture**: https://docs.flutter.dev/app-architecture

##### APIs Nativas por Plataforma

- **Android Foreground Services**: https://developer.android.com/develop/background-work/services/fgs
- **Android App Widgets**: https://developer.android.com/develop/ui/views/appwidgets
- **Android Notification**: https://developer.android.com/develop/ui/views/notifications
- **iOS WidgetKit**: https://developer.apple.com/documentation/widgetkit
- **iOS Background Tasks**: https://developer.apple.com/documentation/backgroundtasks
- **macOS Menu Bar**: https://developer.apple.com/design/human-interface-guidelines/the-menu-bar
- **Windows System Tray**: https://learn.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications/
- **Linux System Tray (libappindicator)**: https://wiki.ubuntu.com/DesktopExperienceTeam/ApplicationIndicators

##### i18n e Localização

- **Flutter Internationalization**: https://docs.flutter.dev/ui/internationalization
- **Intl Package**: https://pub.dev/packages/intl
- **ARB Format Spec**: https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification
- **ICU Message Format**: https://unicode-org.github.io/icu/userguide/format_parse/messages/

##### HTTP & Networking

- **Dio Documentation**: https://pub.dev/documentation/dio/latest/
- **Dio GitHub**: https://github.com/cfug/dio
- **HTTP Status Codes**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

##### Segurança

- **Flutter Secure Storage**: https://pub.dev/packages/flutter_secure_storage
- **Keychain Services (iOS/macOS)**: https://developer.apple.com/documentation/security/keychain_services
- **Android KeyStore**: https://developer.android.com/privacy-and-security/keystore
- **Windows Credential Manager**: https://learn.microsoft.com/en-us/windows/win32/secauthn/credential-manager

##### BitBar & Argos (Inspiração)

- **BitBar GitHub**: https://github.com/matryer/bitbar
- **BitBar Plugin Format**: https://github.com/matryer/bitbar#writing-plugins
- **Argos GitHub**: https://github.com/p-e-w/argos
- **Argos Extensions**: https://extensions.gnome.org/extension/1176/argos/

##### System Tray Implementations

- **tray_manager Source**: https://github.com/leanflutter/tray_manager
- **Electron System Tray**: https://www.electronjs.org/docs/latest/api/tray (referência de API)
- **Qt System Tray**: https://doc.qt.io/qt-6/qsystemtrayicon.html

##### CI/CD & DevOps

- **GitHub Actions Flutter**: https://github.com/marketplace/actions/flutter-action
- **GitHub Actions Matrix**: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/

##### Docker & Containerization

- **Docker-OSX**: https://github.com/sickcodes/Docker-OSX
- **Flutter Docker Images**: https://github.com/cirruslabs/docker-images-flutter
- **Podman Compose**: https://github.com/containers/podman-compose

##### Open Source Best Practices

- **GitHub Community Standards**: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions
- **Open Source Guides**: https://opensource.guide/
- **AGPL-3.0 License**: https://www.gnu.org/licenses/agpl-3.0.html
- **SPDX License List**: https://spdx.org/licenses/

##### Design Resources (Ícones, UI)

- **Material Icons**: https://fonts.google.com/icons (ícones padrão Flutter)
- **Emoji Database**: https://emojipedia.org/ (para ícones emoji em plugins)
- **Flutter Widget Catalog**: https://docs.flutter.dev/ui/widgets
- **Material Design 3**: https://m3.material.io/
- **Cupertino (iOS Style)**: https://docs.flutter.dev/ui/widgets/cupertino

##### Ferramentas CLI Úteis

```bash
# Flutter
flutter doctor      # Diagnóstico do ambiente
flutter pub get     # Instalar dependências
flutter analyze     # Análise estática
flutter test        # Rodar testes
flutter build       # Build release

# Dart
dart format         # Formatar código
dart fix --apply    # Aplicar fixes automáticos
dart pub outdated   # Checar dependências desatualizadas

# Git
git tag v1.0.0      # Criar tag de versão
git push --tags     # Push tags

# Docker
docker-compose build    # Build imagens
docker-compose up       # Subir serviços
docker system prune -af # Limpar Docker

# Coverage
lcov --summary coverage/lcov.info  # Resumo de cobertura
genhtml coverage/lcov.info -o coverage/html  # Gerar HTML
```

---

### ANEXO B: Toolchains e Dependências (Linux)

#### 🐧 Ambiente de Desenvolvimento Linux Completo

##### 1. Sistema Base

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    build-essential

# Fedora/RHEL
sudo dnf install -y \
    curl \
    git \
    unzip \
    xz \
    zip \
    mesa-libGLU \
    gcc-c++ \
    make

# Arch Linux
sudo pacman -S --needed \
    curl \
    git \
    unzip \
    xz \
    zip \
    mesa \
    base-devel
```

##### 2. Flutter SDK (Obrigatório)

```bash
# Download Flutter 3.35+ (versão estável atual)
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$HOME/flutter/bin:$PATH"

# Adicionar ao ~/.bashrc ou ~/.zshrc permanentemente
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verificar instalação
flutter doctor

# Aceitar licenças Android
flutter doctor --android-licenses

# Precache binários Linux
flutter precache --linux
```

**Versão atual (Nov 2025)**: Flutter 3.35.2 / Dart 3.10.0
**Versão mínima recomendada**: Flutter 3.35.0+

**Verificação**:

```bash
flutter --version
# Flutter 3.35.2 • channel stable
# Dart 3.10.0 • DevTools 2.38.2

dart --version
# Dart SDK version: 3.10.0 (stable) (Mon Nov 12 2025)
```

**Por quê Flutter 3.35+**: Dart 3.10 inclui melhorias de performance significativas e novas features de linguagem. Hot reload disponível para web sem flags experimentais.

##### 3. Dependências Linux Desktop (Obrigatório)

```bash
# Ubuntu/Debian
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev

# Fedora/RHEL
sudo dnf install -y \
    clang \
    cmake \
    ninja-build \
    gtk3-devel \
    xz-devel \
    libstdc++-devel

# Arch Linux
sudo pacman -S --needed \
    clang \
    cmake \
    ninja \
    gtk3 \
    xz
```

##### 4. Runtimes de Plugins (Opcionais, mas recomendados)

```bash
# Python 3.13/3.14
sudo apt-get install -y python3 python3-pip  # Ubuntu/Debian
sudo dnf install -y python3 python3-pip      # Fedora
sudo pacman -S python python-pip             # Arch

python3 --version  # Deve ser 3.13+ ou 3.14+

# Node.js 24 LTS
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs  # Ubuntu/Debian

node --version  # Deve ser v24.x

# Go 1.25
wget https://go.dev/dl/go1.25.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.25.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

go version  # Deve ser go1.25+

# Rust 1.91+
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

rustc --version  # Deve ser 1.91+
```

##### 5. Android SDK (Para builds Android)

```bash
# Instalar Android Studio (recomendado)
# OU instalar command-line tools apenas:

# Download command-line tools
mkdir -p ~/Android/cmdline-tools
cd ~/Android/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*_latest.zip
mv cmdline-tools latest

# Configurar PATH
export ANDROID_HOME=$HOME/Android
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

echo 'export ANDROID_HOME=$HOME/Android' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc

# Instalar SDKs necessários
sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0"

# Aceitar licenças
flutter doctor --android-licenses
```

##### 6. Java 25 LTS (Para Android builds)

```bash
# Ubuntu/Debian
sudo apt-get install -y openjdk-25-jdk

# Arch Linux (via AUR)
paru -S jdk25-openjdk

# Verificar
java --version  # Deve ser openjdk 25
```

##### 7. Docker/Podman (Opcional - para builds isolados)

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# OU Podman (recomendado para Arch/Fedora)
sudo apt-get install -y podman podman-compose  # Ubuntu
sudo dnf install -y podman podman-compose      # Fedora
sudo pacman -S podman podman-compose           # Arch
```

##### 8. Ferramentas de Qualidade (Opcionais)

```bash
# lcov (para coverage reports)
sudo apt-get install -y lcov  # Ubuntu/Debian
sudo dnf install -y lcov      # Fedora
sudo pacman -S lcov           # Arch

# jq (para parsing JSON em scripts)
sudo apt-get install -y jq
```

---

### ANEXO C: Checklist de Implementação Final

#### Fase 1: Core (Obrigatório)
- [ ] CLI Parser (`bin/crossbar.dart`)
- [ ] API Implementations (SystemApi, NetworkApi)
- [ ] Output Parser (Text e JSON)
- [ ] Plugin Model (Plugin class)
- [ ] Plugin Manager (Discovery, execution)
- [ ] Script Runner (Execução com timeout)
- [ ] Tests unitários (coverage >= 90%)

#### Fase 2: UI (Obrigatório)
- [ ] Main Window (3 abas)
- [ ] Plugins Tab (Lista plugins, toggle)
- [ ] Settings Tab (Configurações)
- [ ] Marketplace Tab (Placeholder)
- [ ] Config Dialog (Grid system)

#### Fase 3: Build & CI (Obrigatório)
- [ ] CI/CD (GitHub Actions)
- [ ] Build Linux (Flutter)
- [ ] Code Quality (Analyze, format)
- [ ] Documentation (README.md)

#### Fase 4: Optional (Pós-V1)
- [ ] Tray Service (System tray)
- [ ] Android (Foreground service, notifications)
- [ ] iOS (Widgets)
- [ ] i18n (10 idiomas)
- [ ] Marketplace (Integração GitHub real)

---

**PLANO MESTRE DEFINITIVO - VERSÃO 1.0**
**Gerado em**: 01 de Dezembro de 2025
**Repositório**: verseles/crossbar
**Licença**: AGPLv3

**FIM DO DOCUMENTO**
