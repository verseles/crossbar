# CROSSBAR - ESPECIFICAÇÕES TÉCNICAS (Plan Docs Part 2/3)

Este documento detalha as especificações da API, sistema de plugins e configurações declarativas.

---

## 3. CLI API UNIFICADA

### 3.1 Filosofia da API

**"Best Effort"**: Todos comandos tentam executar, retornam erro claro se falharem (ex: permissão negada, feature não disponível no OS).

**Formatos de Saída**:

- Padrão: texto puro (compatível BitBar, parseável em bash)
- `--json`: objeto JSON estruturado
- `--xml`: XML (para integração legada)

**Exemplo**:

```bash
# Texto puro (padrão)
$ crossbar --cpu
45.2

# JSON (plugins avançados)
$ crossbar --cpu --json
{"usage":45.2,"avg1m":42.1,"avg5m":38.5,"cores":8}

# XML (legado/enterprise)
$ crossbar --cpu --xml
<cpu usage="45.2" avg1m="42.1" cores="8"/>
```

### 3.2 Comandos Completos (~45 total)

#### Sistema

```bash
crossbar --cpu                   # % uso CPU (0-100)
crossbar --memory                # RAM livre/total (ex: "8.2/16.0 GB")
crossbar --disk [path]           # Espaço disco (padrão: /, ou path específico)
crossbar --battery               # Nível bateria + charging (ex: "87% ⚡")
crossbar --uptime                # Tempo desde boot (ex: "3d 12h 45m")
crossbar --cpu-temp              # Temperatura CPU °C (best effort, pode falhar)

# --os: nome curto + detalhado
crossbar --os                    # "linux" | "windows" | "macos" | "android" | "ios"
crossbar --os --json
# {"short":"linux","name":"Ubuntu","version":"24.04","kernel":"6.8.0","arch":"x86_64"}
```

**Por quê texto puro padrão**: Scripts bash/shell precisam de saída simples para `$(crossbar --cpu)`. JSON requer parse (jq, python).

**Por quê `--json` como flag**: Mantém compatibilidade com BitBar (texto) mas permite avanços (objetos complexos).

#### Rede \& Conectividade

```bash
crossbar --net                   # Download/upload Mbps (ex: "12.5↓ 1.2↑")
crossbar --net-status            # "online" | "offline" | "wifi" | "cellular" | "ethernet"
crossbar --net-ssid              # Nome WiFi conectado (ou "" se não WiFi)
crossbar --net-ip                # IP local (ex: "192.168.1.100")
crossbar --net-ip --public       # IP público (via API ipify.org)
crossbar --net-ping <host>       # Latência ms (ex: "14")
crossbar --net-mac               # MAC address
crossbar --net-gateway           # IP do roteador
crossbar --net-dns               # Servidores DNS (lista)

# WiFi/Bluetooth (best effort, precisa permissões)
crossbar --wifi-on               # Liga WiFi (pode precisar sudo)
crossbar --wifi-off
crossbar --wifi-list --json      # Lista redes disponíveis
crossbar --bluetooth-status      # "on" | "off" | "devices:3"
crossbar --bluetooth-on
crossbar --bluetooth-off
crossbar --bluetooth-devices --json # Lista dispositivos pareados

crossbar --vpn-status            # "connected:NordVPN" | "disconnected"
```

**Implementação `--web` (Dio-powered)**:

```bash
crossbar --web <url> \
  [--method GET|POST|PUT|DELETE|HEAD] \
  [--headers '{"Authorization":"Bearer token"}'] \
  [--body '{"key":"value"}' | --body-file path.json] \
  [--timeout 5s] \
  [--user-agent "Crossbar/1.0"] \
  [--insecure]  # Ignora SSL (dev apenas)
  [--json | --xml]

# Exemplo
crossbar --web api.github.com/users/octocat \
  --headers '{"Accept":"application/json"}' \
  --json
# {"login":"octocat","name":"The Octocat","public_repos":8,...}
```

**Por quê Dio**: Melhor client HTTP Flutter com interceptors, retries automáticos, validação SSL, suporte a certificados custom.

#### Dispositivo \& Localização

```bash
crossbar --device-model          # "iPhone 15 Pro" / "ThinkPad X1 Carbon"
crossbar --device-screen --json  # {"width":1920,"height":1080,"dpi":96}

# Locale & timezone
crossbar --locale                # "pt_BR"
crossbar --locale --json         # {"language":"pt","country":"BR","full":"pt_BR"}
crossbar --timezone              # "America/Sao_Paulo"
crossbar --timezone --json       # {"name":"...","offset":"-03:00","isDST":false}

# Localização (requer permissão)
crossbar --location --json       # {"lat":-23.550520,"lon":-46.633308}
crossbar --location-city         # "São Paulo" (via geocoding)
```

#### Áudio \& Mídia

```bash
# GET
crossbar --audio-volume          # "75"
crossbar --audio-output          # "speakers" | "headphones" | "bluetooth"
crossbar --media-playing --json
# {"app":"Spotify","title":"Song","artist":"Artist","status":"playing","position":"2:34/5:55"}

# SET (controles)
crossbar --audio-volume-set 50   # Define volume 0-100
crossbar --audio-mute            # Toggle mute
crossbar --audio-output-set speakers|headphones|bluetooth

crossbar --media-play            # Resume playback
crossbar --media-pause
crossbar --media-stop
crossbar --media-next            # Próxima faixa
crossbar --media-prev            # Faixa anterior
crossbar --media-seek +30s       # Avançar/retroceder

crossbar --screen-brightness     # "80"
crossbar --screen-brightness-set 30
```

**Por quê controles bidirecionais**: Eleva Crossbar de "monitor" para "automação". Usuário pode criar plugin "Media Controller" com botões na tray.

#### Clipboard

```bash
crossbar --clipboard             # Conteúdo atual (texto)
crossbar --clipboard-set "text"  # Copia para clipboard
crossbar --clipboard-clear
crossbar --clipboard-history --json # Últimos 5 (se OS suportar)
```

#### Processos \& Apps

```bash
crossbar --process-list --json   # Top 5 por CPU
crossbar --process-count         # Total de processos rodando
crossbar --process-find <name>   # Retorna PID (ou "" se não encontrado)
crossbar --process-kill <pid>    # Kill processo (precisa permissão)
crossbar --app-running <name>    # "true" | "false"
crossbar --app-close <name>      # Fecha app gracefully
```

#### UI \& Sistema

```bash
crossbar --screenshot [path]     # Tira screenshot, salva em path (padrão: ~/screenshot.png)
crossbar --screenshot --clipboard # Screenshot direto pro clipboard

crossbar --wallpaper-get         # Path do wallpaper atual
crossbar --wallpaper-set <path>  # Define novo wallpaper

crossbar --notify "Título" "Mensagem" \
  [--icon "⚠️"] \
  [--sound "default"] \
  [--action "open-url:https://..."] \
  [--priority high|normal|low]

crossbar --dnd-status            # Do Not Disturb: "on" | "off"
crossbar --dnd-set on|off

crossbar --open-url "https://google.com"  # Abre no navegador padrão
crossbar --open-app "spotify"             # Abre app por nome
crossbar --open-file "/path/file.pdf"     # Abre com app padrão

crossbar --power-sleep           # Suspende sistema
crossbar --power-restart         # Reinicia (pede confirmação)
crossbar --power-shutdown        # Desliga (pede confirmação)
```

#### Utilitários

```bash
crossbar --hash "texto" [--algo md5|sha1|sha256|sha512|blake3]
# Padrão: SHA256 (mais seguro que MD5)

crossbar --uuid                  # Gera UUID v4
crossbar --random [min] [max]    # Número aleatório (padrão: 0-100)
crossbar --qr-generate "text"    # QR code base64 PNG
crossbar --base64-encode "text"
crossbar --base64-decode "dGV4dA=="
crossbar --time [fmt=12h|24h]    # Hora local
```

### 3.3 Matriz de Compatibilidade (APIs Críticas)

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

### 3.4 Variáveis de Ambiente Injetadas

**SEMPRE injetadas** em todo plugin:

```bash
CROSSBAR_OS=linux             # Short name do OS
CROSSBAR_DARK_MODE=true       # Tema do sistema (dark/light)
CROSSBAR_VERSION=1.0.0        # Versão do Crossbar
CROSSBAR_PLUGIN_ID=cpu.10s.sh # Nome do plugin
```

**Configs do usuário** (de `~/.crossbar/configs/<plugin>.json`):

```bash
# Se plugin definiu configs, são injetadas automaticamente:
WEATHER_API_KEY=abc123        # Password vem do Keychain (não do JSON)
WEATHER_LOCATION=São Paulo
WEATHER_UNITS=metric
```

**Por quê ENV vars**: Universal (todas linguagens leem), seguro (processo isolado), simples (plugin só faz `os.environ['KEY']`).

---

## 4. SISTEMA DE PLUGINS

### 4.1 Auto-detecção de Linguagem

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

**Linguagens suportadas V1**:

1. **Bash** (.sh) - Universal em Linux/macOS
2. **Python** (.py) - `python3` (não python2)
3. **Node.js** (.js) - `node` ou `#!/usr/bin/env node`
4. **Dart** (.dart) - `dart run` (Flutter SDK)
5. **Go** (.go) - `go run` (requer Go SDK)
6. **Rust** (.rs) - Compila com `rustc`, executa binário

**Por quê essas 6**: Cobrem 95% dos casos (bash ubíquo, python/node mainstream, dart nativo Flutter, go/rust para performance).

### 4.2 Refresh Interval (Parsing de Nome)

```dart
// lib/core/plugin_manager.dart
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

**Override do usuário** (ver seção 5.5):

```json
// ~/.crossbar/configs/weather.5m.py.json
{
  "_crossbar_refresh_override": "1m" // User quer 1min em vez de 5min
}
```

### 4.3 Parser de Saída (BitBar Text OU JSON)

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

**Exemplo**:

```bash
echo "⚡ 45% | color=orange"
echo "---"
echo "CPU Details | bash=/usr/bin/top"
echo "Open Monitor | href=https://monitor.local"
```

#### Formato JSON (Avançado)

```json
{
  "icon": "⚡", // Emoji ou path (icon=file:///path.png)
  "text": "45%",
  "color": "#FF5733",
  "tray_tooltip": "CPU Usage: 45%", // Hover text (Windows/Linux)
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

### 4.4 Execução com Timeout e Rate Limiting

```dart
// lib/core/script_runner.dart
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
        plugin.interpreter,  // bash, python3, node, etc
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

### 4.5 Hot Reload (File Watcher)

```dart
// lib/utils/file_watcher.dart
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

## 5. CONFIGURAÇÃO DECLARATIVA DE PLUGINS

### 5.1 Filosofia

Plugin **declara** suas configurações, Crossbar **renderiza** GUI automaticamente e **injeta** valores como ENV vars. Usuário nunca edita código.

**Dois formatos aceitos** (precedência: JSON externo > embutido):

1. **Arquivo separado** (`plugin.config.json`)
2. **Bloco embutido** no script (comentário `CROSSBAR_CONFIG:`)

### 5.2 Schema de Configuração

```json
{
  "name": "Weather Widget",
  "description": "Shows weather for your location",
  "icon": "🌤️",
  "config_required": "first_run", // "first_run" | "optional" | "always"

  "settings": [
    {
      "key": "WEATHER_API_KEY", // Nome da ENV var
      "label": "OpenWeather API Key",
      "type": "password", // Vai pro Keychain (nunca plaintext)
      "required": true,
      "placeholder": "Enter API key",
      "help": "Get free key at openweathermap.org",
      "width": 100 // Grid 1-100 (porcentagem da tela)
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
    },
    {
      "key": "WEATHER_SHOW_ICON",
      "label": "Show icon",
      "type": "checkbox",
      "default": true,
      "width": 50
    },
    {
      "key": "WEATHER_COLOR",
      "label": "Color scheme",
      "type": "color",
      "default": "#FF5733",
      "width": 50
    }
  ]
}
```

### 5.3 Tipos de Campos (25 total)

#### Inputs Básicos

```json
{"type": "text", "placeholder": "Enter text"}
{"type": "password"}  // → Flutter Keychain (SecureStorage)
{"type": "number", "min": 1, "max": 100, "step": 5}
{"type": "textarea", "rows": 5}
{"type": "hidden", "default": "1.0.0"}  // Não renderiza, só injeta ENV
```

#### Seleção

```json
{"type": "select", "options": [{"value": "a", "label": "Option A"}]}
{"type": "radio", "options": [...]}
{"type": "checkbox", "default": true}
{"type": "switch"}  // Toggle iOS-style
{"type": "multiselect", "options": [...]}  // Retorna array
{"type": "tags", "suggestions": ["tag1", "tag2"]}  // Input chips
```

#### Arquivos

```json
{"type": "file", "accept": ".png,.jpg", "maxSize": "2MB"}
{"type": "directory"}  // Folder picker
{"type": "path"}  // Text input + browse button
{"type": "image", "preview": true}  // Com thumbnail
```

#### Visual

```json
{"type": "color", "default": "#FF0000"}  // Color picker
{"type": "slider", "min": 0, "max": 100, "step": 10, "unit": "%"}
{"type": "range", "min": 0, "max": 100, "default": {"min": 20, "max": 80}}  // Dual slider
{"type": "icon", "options": "emoji"}  // Emoji/icon picker
```

#### Data/Hora

```json
{"type": "date", "default": "2025-01-01"}
{"type": "time", "default": "09:00"}
{"type": "datetime"}
```

#### Avançados

```json
{"type": "keyvalue", "placeholder": {"key": "Header", "value": "Value"}}  // Dinâmico
{"type": "json", "syntax": true}  // Editor JSON
{"type": "code", "language": "python", "rows": 10}  // Syntax highlight
{"type": "url", "protocols": ["https"], "validation": {"regex": "^https://.*"}}
```

#### Layout

```json
{"type": "section", "label": "Authentication"}  // Título seção
{"type": "separator"}  // Linha divisória
{"type": "tabs", "tabs": [...]}  // Organiza em abas
{"type": "collapsible", "label": "Advanced", "collapsed": true, "fields": [...]}
{"type": "info", "text": "⚠️ Requires restart", "variant": "warning"}  // info|warning|error|success
{"type": "divider", "text": "Settings"}
```

### 5.4 Grid System (1-100)

**Por quê 1-100 em vez de 1-12**: Mais intuitivo ("width: 75" = 75% da tela) que grid Bootstrap (6/12 = ?).

**Regras de Layout**:

1. Campos são colocados na mesma linha enquanto soma ≤ 100
2. Se soma > 100, quebra linha
3. Se soma < 100 na linha, expande proporcionalmente

**Exemplo**:

```json
[
  { "key": "NAME", "width": 60 },
  { "key": "AGE", "width": 40 }, // Soma = 100, mesma linha
  { "key": "EMAIL", "width": 100 } // Soma = 200, quebra linha
]
```

Renderiza:

```
[ NAME (60%)______________ ] [ AGE (40%)____ ]
[ EMAIL (100%)________________________________]
```

**Implementação Flutter**:

```dart
// lib/ui/dialogs/plugin_config_dialog.dart
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
          child: _buildField(field),  // TextFormField, ColorPicker, etc
        ),
      );
    }).toList(),
  );
}
```

### 5.5 Refresh Interval Override

**Feature**: Usuário pode sobrescrever intervalo definido pelo dev.

**GUI**:

```
┌───────────────────────────────────┐
│ ⏱️ Update Frequency               │
│                                   │
│ Default: 5 minutes (from filename)│
│                                   │
│ ☐ Override refresh interval:      │
│   [Slider: 1s ━━━━●━━━ 15m]       │
│   Current: 1 minute               │
│                                   │
│ Quick presets:                    │
│ [1m] [5m (default)] [10m] [30m]   │
│                                   │
│ ⚠️ < 5s may impact battery/CPU    │
└───────────────────────────────────┘
```

**Armazenamento** (`~/.crossbar/configs/weather.5m.py.json`):

```json
{
  "WEATHER_API_KEY": { "secureRef": "weather.key" },
  "WEATHER_LOCATION": "São Paulo",
  "_crossbar_refresh_override": "1m" // ← User override
}
```

**Lógica**:

```dart
Duration getRefreshInterval(Plugin plugin) {
  final config = loadPluginConfig(plugin.id);

  // 1. User override tem prioridade
  if (config['_crossbar_refresh_override'] != null) {
    return parseInterval(config['_crossbar_refresh_override']);
  }

  // 2. Filename (dev default)
  return parseRefreshInterval(plugin.name);  // "5m"
}
```

**Por quê permitir override**: Power users querem CPU atualizado a cada 1s, mas dev padrão é 10s (economiza bateria).

### 5.6 Armazenamento Seguro (Passwords)

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

**Por quê**: Usuário pode compartilhar `*.values.json` (versionamento, backup) sem vazar secrets.

**Package**: `flutter_secure_storage` (wrapper cross-platform para Keychain/KeyStore).

---
---

## 7. INTERNACIONALIZAÇÃO (i18n)

### 7.1 Sistema de Tradução

**Package**: `intl` (oficial Google, compile-time safety)

**Por quê intl em vez de easy_localization**:
- Compile-time checks detectam traduções faltando
- Suporte oficial de longo prazo pelo time Flutter
- ICU completo (plurais complexos, gênero, formatação)

**Por quê esses 10 idiomas**: Cobrem 4+ bilhões de falantes (top 10 mundial por total speakers).

### 7.2 Estrutura

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

### 7.3 Formato ARB

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

### 7.4 Detecção de Locale

1. Tenta locale do sistema (`Platform.localeName`).
2. Se não suportado, fallback para `en`.
3. Usuário pode forçar override em Settings.

```dart
// lib/main.dart
runApp(MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales, // Auto-generated
  locale: _userOverride ?? _systemLocale,
));
```

---

## 8. TESTES E QUALIDADE

### 8.1 Meta de Cobertura

**Por quê 90%**: Padrão pragmático (100% é perfeccionismo, <80% é arriscado para projeto crítico).

**Obrigatório**: ≥ 90% coverage no código Dart (core + CLI + parsers + services)

### 8.2 Estrutura de Testes

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

### 8.3 Exemplos de Testes

#### Teste Unitário (Parser)

```dart
// test/unit/core/output_parser_test.dart
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

      final output = OutputParser.parse(input, Plugin.mock());

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

      final output = OutputParser.parse(input, Plugin.mock());

      expect(output.icon, '⚡');
      expect(output.text, '45%');
      expect(output.menu.length, 1);
    });

    test('auto-detects JSON vs text', () {
      expect(OutputParser.isJson('{"key":"value"}'), true);
      expect(OutputParser.isJson('Text output'), false);
    });

    test('handles malformed JSON gracefully', () {
      final output = OutputParser.parse('{"invalid":', Plugin.mock());
      expect(output.hasError, true);
      expect(output.errorMessage, contains('JSON'));
    });
  });
}
```

#### Teste de Integração (Plugin Real)

```dart
// test/integration/plugin_execution_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/script_runner.dart';

void main() {
  group('Plugin Execution', () {
    late ScriptRunner runner;

    setUp(() {
      runner = ScriptRunner();
    });

    test('executes bash plugin successfully', () async {
      final plugin = Plugin(
        id: 'clock.5s.sh',
        path: 'plugins/bash/clock.5s.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 5),
      );

      final output = await runner.run(plugin);

      expect(output.hasError, false);
      expect(output.text, isNotEmpty);  // "14:30" ou similar
      expect(output.icon, isNotNull);
    }, timeout: Timeout(Duration(seconds: 5)));

    test('handles timeout correctly', () async {
      final plugin = Plugin(
        id: 'infinite.sh',
        path: 'test/fixtures/infinite_loop.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 1),
      );

      final output = await runner.run(plugin);

      expect(output.hasError, true);
      expect(output.errorMessage, contains('Timeout'));
    });

    test('injects environment variables', () async {
      // test/fixtures/echo_env.sh: echo $CROSSBAR_OS
      final plugin = Plugin(
        id: 'echo_env.sh',
        path: 'test/fixtures/echo_env.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 1),
      );

      final output = await runner.run(plugin);

      expect(output.text, Platform.operatingSystem);  // "linux", "macos", etc
    });
  });
}
```

#### Teste de Widget (GUI)

```dart
// test/widget/plugin_config_dialog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:crossbar/ui/dialogs/plugin_config_dialog.dart';

void main() {
  group('PluginConfigDialog', () {
    testWidgets('renders all field types', (tester) async {
      final config = PluginConfig(
        name: 'Test Plugin',
        settings: [
          Setting(key: 'TEXT', type: 'text', label: 'Text Field'),
          Setting(key: 'NUMBER', type: 'number', label: 'Number'),
          Setting(key: 'COLOR', type: 'color', label: 'Color'),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: PluginConfigDialog(config: config),
      ));

      expect(find.text('Text Field'), findsOneWidget);
      expect(find.text('Number'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));  // text + number
      expect(find.byType(ColorPicker), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      final config = PluginConfig(
        settings: [
          Setting(key: 'API_KEY', type: 'text', required: true),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: PluginConfigDialog(config: config),
      ));

      // Tenta salvar sem preencher
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('respects grid layout (width)', (tester) async {
      final config = PluginConfig(
        settings: [
          Setting(key: 'A', type: 'text', width: 60),
          Setting(key: 'B', type: 'text', width: 40),  // Same row
          Setting(key: 'C', type: 'text', width: 100), // New row
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: PluginConfigDialog(config: config),
      ));

      // Verifica se A e B estão na mesma Row
      final rowFinder = find.ancestor(
        of: find.byKey(Key('field_A')),
        matching: find.byType(Row),
      );
      expect(find.descendant(of: rowFinder, matching: find.byKey(Key('field_B'))), findsOneWidget);

      // C deve estar em Row diferente
      expect(find.descendant(of: rowFinder, matching: find.byKey(Key('field_C'))), findsNothing);
    });
  });
}
```

### 8.4 Testes Adaptativos (Linguagens Opcionais)

Plugins em Go/Rust só testam se compilador instalado:

```dart
// test/integration/plugin_execution_test.dart
test('executes Go plugin', () async {
  final hasGo = await Process.run('which', ['go']).then((r) => r.exitCode == 0);

  if (!hasGo) {
    print('⚠️  Go not installed, skipping test');
    return;
  }

  final plugin = Plugin(
    id: 'cpu.10s.go',
    path: 'plugins/go/cpu.10s.go',
    interpreter: 'go',
    refreshInterval: Duration(seconds: 10),
  );

  final output = await runner.run(plugin);
  expect(output.hasError, false);
}, skip: !Platform.isLinux && !Platform.isMacOS);  // Windows: go run mais complexo
```

**Por quê**: CI pode não ter todos compiladores (Go, Rust). Testes adaptam-se ao ambiente.

### 8.5 Mocks e Fixtures

```
test/fixtures/
├── mock_plugin_output.json
├── mock_github_api_response.json
├── infinite_loop.sh              # Plugin que nunca termina (teste timeout)
├── echo_env.sh                   # echo $CROSSBAR_OS
└── invalid_json.txt              # JSON malformado
```

```dart
// test/helpers/mocks.dart
class MockDio extends Mock implements Dio {}

class MockTrayManager extends Mock implements TrayManager {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

// Usar em testes:
void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
  });

  test('fetches GitHub releases', () async {
    when(mockDio.get(any)).thenAnswer((_) async => Response(
      data: {'tag_name': 'v1.2.0'},
      statusCode: 200,
    ));

    final updater = Updater(dio: mockDio);
    final hasUpdate = await updater.checkUpdate();

    expect(hasUpdate, true);
    verify(mockDio.get('https://api.github.com/repos/verseles/crossbar/releases/latest')).called(1);
  });
}
```

### 8.6 Performance Tests

```dart
// test/performance/plugin_execution_benchmark.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plugin execution overhead < 50ms', () async {
    final runner = ScriptRunner();
    final plugin = Plugin.mock(path: 'plugins/bash/clock.5s.sh');

    final stopwatch = Stopwatch()..start();
    await runner.run(plugin);
    stopwatch.stop();

    final overhead = stopwatch.elapsedMilliseconds;
    expect(overhead, lessThan(50), reason: 'Process spawn + parse should be <50ms');
  });

  test('supports 10 concurrent plugins', () async {
    final runner = ScriptRunner();
    final plugins = List.generate(10, (i) => Plugin.mock(id: 'plugin_$i'));

    final stopwatch = Stopwatch()..start();
    await Future.wait(plugins.map((p) => runner.run(p)));
    stopwatch.stop();

    // 10 plugins em ~100ms (10ms cada em média)
    expect(stopwatch.elapsedMilliseconds, lessThan(200));
  });
}
```

### 8.7 Métricas Separadas para Plugins de Exemplo

Plugins em `plugins/` não contam na cobertura Dart (são scripts externos):

```yaml
# .github/workflows/ci.yml
- name: Test example plugins
  run: |
    # Bash
    bash plugins/bash/clock.5s.sh
    test $? -eq 0 || exit 1

    # Python
    python3 plugins/python/cpu.10s.py
    test $? -eq 0 || exit 1

    # Node
    node plugins/node/battery.30s.js
    test $? -eq 0 || exit 1

  continue-on-error: true # Linguagens podem não estar instaladas
```

**Métrica separada**: "% de plugins exemplo testados" (meta: 100% que CI consegue rodar).

---
