# CROSSBAR - Plano Completo Unificado

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
- Única framework madura com suporte a 5 plataformas (desktop + mobile) nativo.
- **Alternativas descartadas**: Electron (pesado, sem mobile), React Native (suporte desktop fraco), Tauri (sem mobile, Rust adiciona complexidade).

**Por quê Dart 3.x**:
- Linguagem type-safe, null-safety nativo, tooling excelente, ecossistema pub.dev maduro.
- CLI nativa: `dart:io` permite criar CLI completa sem dependências externas.

**Por quê esses 6 linguagens de plugin**: Cobrem 95% dos casos (bash ubíquo, python/node mainstream, dart nativo Flutter, go/rust para performance).
- Bash (.sh) - Universal em Linux/macOS
- Python (.py) - `python3` (não python2)
- Node.js (.js) - `node` ou `#!/usr/bin/env node`
- Dart (.dart) - `dart run` (Flutter SDK)
- Go (.go) - `go run` (requer Go SDK)
- Rust (.rs) - Compila com `rustc`, executa binário

### 2.2 Packages Críticos

| Package | Versão | Justificativa |
|---------|--------|---------------|
| `tray_manager` | ^0.2.3 | Único package maduro multi-plataforma (Win/Linux/macOS) |
| `dio` | ^5.7.0 | Melhor client HTTP Flutter (interceptors, retries, validação SSL) |
| `intl` | ^0.19.0 | i18n oficial Google com compile-time safety |
| `flutter_secure_storage` | ^9.2.2 | Keychain/KeyStore (nunca passwords em plaintext) |
| `path_provider` | ^2.1.4 | Diretórios cross-platform (~/.crossbar/) |

### 2.3 Estrutura de Diretórios

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

## 3. VERDADE TÉCNICA (Versões Validadas Nov 2025)

### 3.1 Versões de Tecnologia

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

### 3.2 Dependências Flutter Completas

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

---

## 4. CLI API UNIFICADA

### 4.1 Filosofia da API

**"Best Effort"**: Todos comandos tentam executar, retornam erro claro se falharem (ex: permissão negada, feature não disponível no OS).

**Por quê texto puro padrão**: Scripts bash/shell precisam de saída simples para `$(crossbar --cpu)`. JSON requer parse (jq, python).

**Por quê `--json` como flag**: Mantém compatibilidade com BitBar (texto) mas permite avanços (objetos complexos).

**Formatos de Saída**:
- Padrão: texto puro (compatível BitBar, parseável em bash)
- `--json`: objeto JSON estruturado
- `--xml`: XML (para integração legada)

### 4.2 Comandos Completos (~45 total)

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

### 4.3 Matriz de Compatibilidade

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

### 4.4 Variáveis de Ambiente Injetadas

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

---

## 5. SISTEMA DE PLUGINS

### 5.1 Auto-detecção de Linguagem

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

### 5.2 Refresh Interval (Parsing de Nome)

```dart
Duration parseRefreshInterval(String filename) {
  // Regex: qualquer número + unidade (s/m/h) antes da extensão
  // Exemplos: clock.5s.sh, cpu.1m.py, weather.2h.dart
  final match = RegExp(r'\.(\d+(?:\.\d+)?)(s|m|h)\.').firstMatch(filename);

  if (match != null) {
    final value = double.parse(match.group(1)!);
    final unit = match.group(2)!;

    Duration interval;
    switch (unit) {
      case 's': interval = Duration(milliseconds: (value * 1000).round());
      case 'm': interval = Duration(minutes: value.round());
      case 'h': interval = Duration(hours: value.round());
    }

    // IMPORTANTE: Mínimo 1 segundo (evita 0.1s = 10x/seg)
    if (interval < Duration(seconds: 1)) {
      log('Warning: ${filename} interval <1s, clamped to 1s');
      return Duration(seconds: 1);
    }

    return interval;
  }

  // Default se nome não tem intervalo
  return Duration(minutes: 5);
}
```

**Por quê mínimo 1s**: Protege contra plugins mal-feitos (`clock.0.1s.sh` = 600 execuções/min = trava sistema).

**Override do usuário**:

```json
// ~/.crossbar/configs/weather.5m.py.json
{
  "_crossbar_refresh_override": "1m"
}
```

### 5.3 Parser de Saída (BitBar Text OU JSON)

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

### 5.4 Execução com Timeout e Rate Limiting

```dart
class ScriptRunner {
  final _processPool = <String, Process>{};
  final _lastRun = <String, DateTime>{};
  static const maxConcurrent = 10;  // Máx processos simultâneos

  Future<PluginOutput> run(Plugin plugin) async {
    // Rate limiting (evita spam)
    final lastExec = _lastRun[plugin.id];
    if (lastExec != null &&
        DateTime.now().difference(lastExec) < plugin.refreshInterval) {
      return PluginOutput.cached(plugin.id);
    }

    // Pool limiting (evita fork bomb)
    if (_processPool.length >= maxConcurrent) {
      log('Pool full (${maxConcurrent}), queueing ${plugin.id}');
      await Future.delayed(Duration(seconds: 1));
      return run(plugin);  // Retry
    }

    // Prepara ENV vars
    final env = {
      ...Platform.environment,
      ...await _loadPluginConfig(plugin),
      'CROSSBAR_OS': Platform.operatingSystem,
      'CROSSBAR_DARK_MODE': _isDarkMode() ? 'true' : 'false',
      'CROSSBAR_VERSION': '1.0.0',
      'CROSSBAR_PLUGIN_ID': plugin.id,
    };

    // Executa com timeout
    try {
      final process = await Process.start(
        plugin.interpreter,
        [plugin.path],
        environment: env,
      );

      _processPool[plugin.id] = process;
      _lastRun[plugin.id] = DateTime.now();

      final output = await process.stdout
        .transform(utf8.decoder)
        .timeout(Duration(seconds: 30), onTimeout: (sink) {
          process.kill();
          sink.addError('Timeout after 30s');
        })
        .join();

      await process.exitCode;
      _processPool.remove(plugin.id);

      return OutputParser.parse(output, plugin);

    } catch (e) {
      log('Error running ${plugin.id}: $e');
      return PluginOutput.error(plugin.id, e.toString());
    }
  }
}
```

**Por quê timeout 30s**: Plugins devem ser rápidos (<1s ideal). 30s é limite generoso para chamadas HTTP lentas.

**Por quê pool de 10**: Evita fork bomb se usuário ativa 50 plugins com interval 1s.

### 5.5 Hot Reload (File Watcher)

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

**Por quê debounce 1s**: Vim salva múltiplas vezes ao `:w`. 1s evita reload repetido.

---

## 6. CONFIGURAÇÃO DECLARATIVA DE PLUGINS

### 6.1 Filosofia

Plugin **declara** suas configurações, Crossbar **renderiza** GUI automaticamente e **injeta** valores como ENV vars. Usuário nunca edita código.

**Dois formatos aceitos** (precedência: JSON externo > embutido):

1. **Arquivo separado** (`plugin.config.json`)
2. **Bloco embutido** no script (comentário `CROSSBAR_CONFIG:`)

### 6.2 Schema de Configuração

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

### 6.3 Tipos de Campos (25 total)

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

### 6.4 Grid System (1-100)

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
```

### 6.5 Armazenamento Seguro (Passwords)

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

---

## 7. UI/UX MULTI-PLATAFORMA

### 7.1 Renderização Adaptativa

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

### 7.2 Múltiplos Ícones de Tray (Desktop)

**Por quê múltiplos ícones**: BitBar tem ícone fixo. Crossbar permite dashboard completo na tray (clock, CPU, network, cada um com seu ícone).

```dart
class TrayService {
  final _trayIcons = <String, TrayManager>{};  // plugin.id → TrayManager

  Future<void> createTray(Plugin plugin, PluginOutput output) async {
    final tray = TrayManager();
    await tray.setIcon(output.icon);
    await tray.setTitle(output.text);
    await tray.setContextMenu(Menu(items: _buildMenu(output.menu)));

    tray.addListener((event) {
      if (event == TrayEvent.click) {
        tray.popUpContextMenu();
      }
    });

    _trayIcons[plugin.id] = tray;
  }
}
```

**Modo consolidado** (Settings → "Single tray icon"):

```
Em vez de: [🕐] [⚡45%] [📶12Mbps]
Fica:      [📊] → menu:
              Clock
              CPU: 45%
              Network: 12Mbps
```

### 7.3 Android - Notificações Persistentes

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

### 7.4 GUI Principal (3 Abas)

```dart
class MainWindow extends StatelessWidget {
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
            title: Text('Crossbar'),
            bottom: TabBar(tabs: [
              Tab(icon: Icon(Icons.extension), text: 'Plugins'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.store), text: 'Marketplace'),
            ]),
          ),
          body: TabBarView(children: [
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

---

## 8. INTERNACIONALIZAÇÃO (i18n)

### 8.1 Sistema de Tradução

**Package**: `intl` (oficial Google, compile-time safety)

**Por quê intl em vez de easy_localization**:
- Compile-time checks detectam traduções faltando
- Suporte oficial de longo prazo pelo time Flutter
- ICU completo (plurais complexos, gênero, formatação)

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

**Por quê esses 10 idiomas**: Cobrem 4+ bilhões de falantes (top 10 mundial por total speakers).

### 8.2 Formato ARB

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

## 9. TESTES E QUALIDADE

### 9.1 Meta de Cobertura

**Por quê 90%**: Padrão pragmático (100% é perfeccionismo, <80% é arriscado para projeto crítico).

**Obrigatório**: ≥ 90% coverage no código Dart (core + CLI + parsers + services)

### 9.2 Estrutura de Testes

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

### 9.3 Exemplos de Testes

#### Teste Unitário (Parser)

```dart
void main() {
  group('OutputParser', () {
    test('parses BitBar text format', () {
      final input = '''⚡ 45% | color=orange
---
Details | bash=/usr/bin/top''';

      final output = OutputParser.parse(input, 'test.sh');

      expect(output.icon, '⚡');
      expect(output.text, '45%');
      expect(output.menu.length, 1);
      expect(output.menu[0].bash, '/usr/bin/top');
    });

    test('parses JSON format', () {
      final input = '{"icon": "⚡", "text": "45%"}';
      final output = OutputParser.parse(input, 'test.py');
      expect(output.icon, '⚡');
    });

    test('auto-detects JSON vs text', () {
      expect(OutputParser.isJson('{"key":"value"}'), true);
      expect(OutputParser.isJson('Text output'), false);
    });
  });
}
```

#### Teste de Integração

```dart
test('executes bash plugin successfully', () async {
  final plugin = Plugin(
    id: 'clock.5s.sh',
    path: 'plugins/bash/clock.5s.sh',
    interpreter: 'bash',
    refreshInterval: Duration(seconds: 5),
  );

  final output = await runner.run(plugin);

  expect(output.hasError, false);
  expect(output.text, isNotEmpty);
}, timeout: Timeout(Duration(seconds: 5)));
```

---

## 10. BUILD & CI/CD

### 10.1 Makefile (Comandos Unificados)

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

### 10.2 GitHub Actions CI/CD

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

## 11. MARKETPLACE E ECOSSISTEMA

### 11.1 Busca no GitHub

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

### 11.2 Instalação de Plugin

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

### 11.3 Template de Plugin

```bash
crossbar init --lang python --type clock
```

Gera:
```
~/.crossbar/plugins/python/clock.5s.py
~/.crossbar/plugins/python/clock.config.json
```

---

## 12. ROTEIRO DE EXECUÇÃO

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

## 13. PERFORMANCE TARGETS

| Métrica | Target |
|---------|--------|
| Boot Time (desktop) | < 2s |
| Boot Time (Android cold start) | < 3s |
| Memory Footprint (idle, 3 plugins) | < 150MB (desktop), < 100MB (mobile) |
| Plugin Execution Overhead | < 50ms |
| Hot Reload | < 1s |
| CI/CD Total (5 plataformas) | < 15 minutos |

---

## 14. PORQUÊS ESSENCIAIS (DNA DO CROSSBAR)

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

## 15. ROADMAP FUTURO (Pós-V1)

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

**PLANO COMPLETO UNIFICADO - VERSÃO 1.0**
**Repositório**: verseles/crossbar
**Licença**: AGPLv3
