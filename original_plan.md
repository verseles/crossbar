# CROSSBAR - Plano Executivo Completo

**Sistema Universal de Plugins para Barra de Tarefas/Menu Bar**

**Repositório**: `verseles/crossbar`
**Licença**: AGPLv3 (garante que derivados e serviços SaaS retornem melhorias à comunidade)
**Tecnologia**: Dart 3.10+ + Flutter 3.38+
**Plataformas**: Linux, Windows, macOS, Android, iOS

---

## 1. VISÃO GERAL

### 1.1 Conceito

Crossbar é um sistema revolucionário de plugins cross-platform inspirado em BitBar (macOS) e Argos (Linux), que eleva o conceito para todas as plataformas desktop e mobile com uma API unificada.

**Diferenciais Revolucionários**:

1. **API CLI Unificada**: Plugin escreve `crossbar --cpu` uma única vez, funciona em 5 plataformas (BitBar/Argos forçam cada dev a reimplementar para cada OS).
2. **Widgets Adaptativos**: Plugin retorna dados estruturados, Crossbar renderiza automaticamente para tray icon, notificação Android, widget 1x1/2x2, menu bar macOS (nenhuma ferramenta existente faz isso).
3. **Controles Bidirecionais**: Além de mostrar informações (GET), permite controlar o sistema (SET): volume, mídia, notificações, wallpaper (BitBar/Argos são apenas leitura).
4. **Configuração Declarativa**: Plugin declara suas configurações em JSON, Crossbar gera GUI automaticamente com 25+ tipos de campos (text, password, color picker, file picker, etc).
5. **Múltiplos Ícones Dinâmicos**: Cada plugin pode ter seu próprio ícone na tray/menu bar que muda dinamicamente (BitBar tem ícone fixo).

### 1.2 Público-Alvo

- Desenvolvedores que querem monitorar sistemas
- Power users que customizam workflow
- DevOps com dashboards na barra de tarefas
- Comunidade open source (marketplace de plugins)

### 1.3 Filosofia "Write Once, Run Everywhere"

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

---

## 2. ARQUITETURA E TECH STACK

### 2.1 Decisões Técnicas

**Flutter 3.24+**:

- **Por quê**: Única framework madura com suporte a 5 plataformas (desktop + mobile) nativo.
- **Alternativas descartadas**: Electron (pesado, sem mobile), React Native (suporte desktop fraco), Tauri (sem mobile, Rust adiciona complexidade).

**Dart 3.x**:

- **Por quê**: Linguagem type-safe, null-safety nativo, tooling excelente, ecossistema pub.dev maduro.
- **CLI nativa**: `dart:io` permite criar CLI completa sem dependências externas.

**Packages Críticos**:

- `tray_manager` (^0.2.0): Sistema tray multi-plataforma (Windows/Linux/macOS)
- `dio` (^5.0.0): HTTP client robusto com interceptors, retries, timeout
- `intl` (^0.19.0): i18n oficial Google com compile-time safety
- `path_provider` (^2.1.0): Diretórios cross-platform (~/.crossbar/)
- `flutter_secure_storage` (^9.0.0): Keychain/KeyStore para passwords

### 2.2 Estrutura de Diretórios

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
│   │   ├── clock.5s.sh
│   │   ├── cpu.10s.sh
│   │   ├── battery.30s.sh
│   │   └── site-check.1m.sh
│   ├── python/
│   │   ├── clock.5s.py
│   │   ├── cpu.10s.py
│   │   ├── battery.30s.py
│   │   └── site-check.1m.py
│   ├── node/                      # JavaScript (Node.js)
│   ├── dart/
│   ├── go/
│   └── rust/
├── docker/
│   ├── Dockerfile.linux
│   ├── Dockerfile.android
│   ├── Dockerfile.macos           # Docker-OSX (experimental)
│   └── Dockerfile.windows         # Windows container
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
└── README.md                      # Setup, exemplos, FAQ (com accordion)
```

### 2.3 Fluxo de Execução

```
1. Crossbar inicia (silencioso, background)
   ↓
2. Lê ~/.crossbar/plugins/* (detecta linguagem via shebang/extensão)
   ↓
3. Para cada plugin:
   a. Parse refresh interval do nome (ex: "cpu.10s.sh" = 10 segundos)
   b. Carrega configurações (~/.crossbar/configs/<plugin>.json)
   c. Injeta ENV vars (CROSSBAR_OS, configs do usuário)
   d. Executa script (Process.run com timeout)
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

## 6. UI/UX MULTI-PLATAFORMA

### 6.1 Renderização Adaptativa

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

**Exemplo prático**:

Plugin retorna:

```json
{
  "icon": "⚡",
  "text": "45%",
  "menu": [
    { "text": "Core 1: 50%" },
    { "text": "Core 2: 40%" },
    { "text": "Details", "bash": "/usr/bin/top" }
  ]
}
```

Crossbar renderiza:

- **macOS menu bar**: `[⚡ 45%]` → clica → dropdown com 3 itens
- **Windows tray**: `[⚡]` (texto "45%" no tooltip) → clica → menu
- **Android widget 2x2**: Card com ícone ⚡, texto "45%", botão "Details"
- **iOS widget small**: Só ⚡ (45% no long-press)

**Por quê renderização adaptativa**: Plugin é agnóstico de UI. Dev não precisa saber iOS/Android/Desktop.

### 6.2 Múltiplos Ícones de Tray (Desktop)

**Decisão**: Cada plugin = 1 ícone na tray (configurável para consolidado).

**Implementação**:

```dart
// lib/services/tray_service.dart
class TrayService {
  final _trayIcons = <String, TrayManager>{};  // plugin.id → TrayManager

  Future<void> createTray(Plugin plugin, PluginOutput output) async {
    final tray = TrayManager();
    await tray.setIcon(output.icon);  // Emoji ou file:///path.png
    await tray.setTitle(output.text);  // macOS: mostra texto, Win: tooltip
    await tray.setContextMenu(Menu(items: _buildMenu(output.menu)));

    // Ação ao clicar
    tray.addListener((event) {
      if (event == TrayEvent.click) {
        tray.popUpContextMenu();
      }
    });

    _trayIcons[plugin.id] = tray;
  }

  Future<void> updateTray(Plugin plugin, PluginOutput output) async {
    final tray = _trayIcons[plugin.id];
    if (tray == null) {
      await createTray(plugin, output);
      return;
    }

    // Hot update (sem piscar)
    await tray.setIcon(output.icon);
    await tray.setTitle(output.text);
    await tray.setContextMenu(Menu(items: _buildMenu(output.menu)));
  }
}
```

**Ícones dinâmicos**:

```python
# Plugin pode mudar ícone baseado em estado
cpu_usage = float(subprocess.run(['crossbar', '--cpu'], ...).stdout)

if cpu_usage > 80:
    icon = "🔥"  # Crítico
elif cpu_usage > 50:
    icon = "⚡"  # Alto
else:
    icon = "✓"   # Normal

print(json.dumps({"icon": icon, "text": f"{cpu_usage}%"}))
```

**Por quê múltiplos ícones**: BitBar tem ícone fixo. Crossbar permite dashboard completo na tray (clock, CPU, network, cada um com seu ícone).

**Modo consolidado** (Settings → "Single tray icon"):

```
Em vez de: [🕐] [⚡45%] [📶12Mbps]
Fica:      [📊] → menu:
              Clock
              CPU: 45%
              Network: 12Mbps
```

### 6.3 Android - Notificações Persistentes

**Foreground Service obrigatório** (Android mata apps em background sem isso):

```kotlin
// android/app/src/main/kotlin/.../ForegroundService.kt
class CrossbarForegroundService : Service() {
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("Crossbar")
      .setContentText("3 plugins active")
      .setSmallIcon(R.drawable.ic_crossbar)
      .setOngoing(true)  // Não pode ser dismissed
      .build()

    startForeground(NOTIFICATION_ID, notification)
    return START_STICKY
  }
}
```

**Múltiplas notificações** (até 3 plugins):

- Até 3 plugins ativos → 1 notificação por plugin
- Mais de 3 → Notificação consolidada "Crossbar (5 plugins)" + expand mostra lista

**Botões de ação** (até 3 por notificação):

```kotlin
.addAction(R.drawable.ic_play, "Play", playPendingIntent)
.addAction(R.drawable.ic_next, "Next", nextPendingIntent)
.addAction(R.drawable.ic_more, "More", morePendingIntent)
```

**Por quê foreground service**: Android 12+ mata processos em background agressivamente. Notificação persistente = garantia de execução.

### 6.4 Widgets (Android \& iOS)

**Android (App Widget Framework)**:

```kotlin
// android/app/src/main/kotlin/.../CrossbarWidget.kt
class CrossbarWidget : AppWidgetProvider() {
  override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
    for (id in ids) {
      val views = RemoteViews(context.packageName, R.layout.widget_small)

      // Executa plugin
      val output = runPlugin("cpu.10s.py")

      views.setTextViewText(R.id.icon, output.icon)
      views.setTextViewText(R.id.text, output.text)

      manager.updateAppWidget(id, views)
    }
  }
}
```

**iOS (WidgetKit)**:

```swift
// ios/WidgetExtension/CrossbarWidget.swift
struct CrossbarWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "Crossbar") { entry in
      WidgetView(entry: entry)
    }
    .configurationDisplayName("CPU Monitor")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct WidgetView: View {
  var entry: PluginEntry

  var body: some View {
    VStack {
      Text(entry.icon).font(.largeTitle)
      Text(entry.text).font(.caption)
    }
  }
}
```

**Timeline (iOS)**:

```swift
func getTimeline(completion: @escaping (Timeline<Entry>) -> ()) {
  let entries = [PluginEntry(date: Date(), icon: "⚡", text: "45%")]
  let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(60)))
  completion(timeline)
}
```

**Por quê iOS widgets atualizam pouco**: iOS controla refresh (budget de bateria). Pode ser 1x/hora em condições adversas. **Documentar** isso explicitamente no README.

### 6.5 GUI Principal (3 Abas)

```dart
// lib/ui/main_window.dart
class MainWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossbar',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,  // Auto dark/light

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

#### Aba 1: Plugins

- Lista todos plugins (`~/.crossbar/plugins/*`)
- Status: ativo/inativo/erro
- Preview da saída (miniatura do tray/widget)
- Botões: ⚙️ Configurar | ▶️ Ativar/Pausar | 🗑️ Remover

#### Aba 2: Settings

```
┌─────────────────────────────────┐
│ General                         │
│ ☐ Start with system             │
│ ☐ Show tray icon                │
│ ☑ Check updates on startup      │
│                                 │
│ Appearance                      │
│ Theme: ( ) Light (•) Dark ( ) Auto│
│ Tray mode: (•) Multiple icons    │
│            ( ) Single consolidated│
│                                 │
│ Language                        │
│ [Auto (System)  ▼]              │
│                                 │
│ Shortcuts                       │
│ Open GUI: [Ctrl+Alt+C]          │
│                                 │
│ Advanced                        │
│ Log level: [Info ▼]             │
│ Max concurrent plugins: [10]    │
└─────────────────────────────────┘
```

#### Aba 3: Marketplace

```
┌─────────────────────────────────┐
│ Search: [____________] [🔍]      │
│ Filter: [All ▼] [Language ▼]    │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🌤️ Weather Widget          │ │
│ │ Shows weather for location  │ │
│ │ ⭐ 245  📥 1.2k  Python      │ │
│ │ [Install]                   │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📊 GitHub Stats             │ │
│ │ Monitor GitHub repos        │ │
│ │ ⭐ 189  📥 850  Node.js      │ │
│ │ [Installed ✓]               │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Busca no Marketplace**:

```dart
// lib/services/marketplace_service.dart
Future<List<Plugin>> searchGitHub(String query) async {
  final response = await dio.get(
    'https://api.github.com/search/repositories',
    queryParameters: {
      'q': 'topic:crossbar $query',
      'sort': 'stars',
      'order': 'desc',
    },
  );

  return (response.data['items'] as List)
    .map((item) => Plugin.fromGitHub(item))
    .toList();
}
```

**Instalação**:

```bash
crossbar install https://github.com/user/weather-plugin
# 1. Clone repo
# 2. Detecta linguagem (shebang/extensão)
# 3. Move pra ~/.crossbar/plugins/<language>/
# 4. chmod +x
# 5. Ativa plugin
```

## 7. INTERNACIONALIZAÇÃO (i18n)

### 7.1 Sistema de Tradução

**Package**: `intl` (oficial Google, compile-time safety)

**Por quê intl em vez de easy_localization**:

- Compile-time checks detectam traduções faltando
- Suporte oficial de longo prazo pelo time Flutter
- ICU completo (plurais complexos, gênero, formatação)
- Melhor para projetos sérios que precisam escalar

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

### 7.2 Formato ARB (Application Resource Bundle)

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Crossbar",
  "pluginsTab": "Plugins",
  "settingsTab": "Settings",
  "marketplaceTab": "Marketplace",

  "pluginStatus_active": "Active",
  "pluginStatus_inactive": "Inactive",
  "pluginStatus_error": "Error",

  "configDialog_title": "Configure: {pluginName}",
  "@configDialog_title": {
    "description": "Config dialog title with plugin name",
    "placeholders": {
      "pluginName": {
        "type": "String",
        "example": "Weather Widget"
      }
    }
  },

  "refreshInterval_override": "Override refresh interval",
  "refreshInterval_warning": "Updates < 5s may impact battery and CPU",

  "marketplace_install": "Install",
  "marketplace_installed": "Installed",
  "marketplace_stars": "{count, plural, =0{No stars} =1{1 star} other{{count} stars}}",
  "@marketplace_stars": {
    "description": "GitHub stars count",
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

```json
// lib/l10n/app_pt_BR.arb
{
  "@@locale": "pt_BR",
  "appTitle": "Crossbar",
  "pluginsTab": "Plugins",
  "settingsTab": "Configurações",
  "marketplaceTab": "Marketplace",

  "pluginStatus_active": "Ativo",
  "pluginStatus_inactive": "Inativo",
  "pluginStatus_error": "Erro",

  "configDialog_title": "Configurar: {pluginName}",
  "refreshInterval_override": "Sobrescrever intervalo de atualização",
  "refreshInterval_warning": "Atualizações < 5s podem impactar bateria e CPU",

  "marketplace_install": "Instalar",
  "marketplace_installed": "Instalado",
  "marketplace_stars": "{count, plural, =0{Sem estrelas} =1{1 estrela} other{{count} estrelas}}"
}
```

### 7.3 Uso no Código

```dart
// lib/ui/tabs/plugins_tab.dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PluginsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(l10n.pluginsTab),  // "Plugins" ou "Plugins" (pt_BR)

        // Com placeholder
        Text(l10n.configDialog_title('Weather Widget')),
        // EN: "Configure: Weather Widget"
        // PT_BR: "Configurar: Weather Widget"

        // Plurais
        Text(l10n.marketplace_stars(245)),
        // EN: "245 stars"
        // PT_BR: "245 estrelas"
      ],
    );
  }
}
```

### 7.4 Detecção Automática de Idioma

```dart
// lib/main.dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // Flutter detecta automaticamente:
  // - iOS: Settings → General → Language
  // - Android: Settings → System → Languages
  // - Desktop: Locale do sistema operacional

  locale: _userOverride,  // null = auto, ou Locale('pt', 'BR') se user forçou
)
```

**Fallback**:

```
Sistema pt_PT (Portugal) → busca pt_PT.arb (não existe) → fallback pt_BR.arb → fallback en.arb
```

### 7.5 Suporte RTL (Árabe)

Flutter detecta automaticamente direção de texto:

```dart
// app_ar.arb (árabe)
{
  "@@locale": "ar",
  "appTitle": "كروسبار",
  "pluginsTab": "الإضافات"
}
```

UI inverte automaticamente:

```
LTR (Inglês):  [Plugins] [Settings] [Marketplace]
RTL (Árabe):   [Marketplace] [Settings] [Plugins]
```

**Testar**: Mudar idioma do sistema pra árabe, Crossbar deve refletir RTL instantaneamente.

### 7.6 Tradução pela IA

**Instruções para IA implementadora**:

1. **Base**: `app_en.arb` é source of truth (inglês)
2. **Traduzir** todos 10 idiomas mantendo:
   - Placeholders: `{pluginName}`, `{count}`
   - Plurais ICU: `{count, plural, ...}`
   - Contexto técnico (não traduzir "Plugin", "API Key", "JSON")
3. **Validar**:
   - Todos keys presentes em todos arquivos
   - Placeholders com mesmo nome
   - Plurais com formas corretas (pt_BR: zero/one/other, ar: zero/one/two/few/many/other)
4. **Testar** no preview Flutter mudando locale

**Exemplo de plural complexo (árabe)**:

```json
{
  "marketplace_stars": "{count, plural, =0{لا نجوم} =1{نجمة واحدة} =2{نجمتان} few{{count} نجوم} many{{count} نجمة} other{{count} نجوم}}"
}
```

---

## 8. TESTES E QUALIDADE

### 8.1 Meta de Cobertura

**Obrigatório**: ≥ 90% coverage no código Dart (core + CLI + parsers + services)

**Por quê 90%**: Padrão pragmático (100% é perfeccionismo, <80% é arriscado para projeto crítico).

**Enforcement no CI**:

```yaml
# .github/workflows/ci.yml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Check coverage >= 90%
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 90" | bc -l) )); then
      echo "❌ Coverage $COVERAGE% < 90%"
      exit 1
    fi
    echo "✅ Coverage: $COVERAGE%"
```

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
│   ├── plugin_execution_test.dart  # Executa plugins reais, valida saída
│   ├── cli_test.dart              # Testa crossbar --cpu etc
│   └── marketplace_test.dart      # GitHub API mock
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
      expect(output.color, Colors.orange);
      expect(output.menu.length, 1);
      expect(output.menu[0].text, 'Details');
      expect(output.menu[0].action?.bash, '/usr/bin/top');
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

## 9. BUILD \& CI/CD

### 9.1 Desenvolvimento Local (Makefile + Docker/Podman)

**Filosofia**: Dev escolhe nativo (Flutter instalado) OU Docker (sem instalar nada).

#### Makefile (Comandos Unificados)

```makefile
# Crossbar Makefile
# Detecta automaticamente: Flutter nativo > Docker > Podman

COMPOSE := $(shell command -v docker-compose 2>/dev/null || command -v podman-compose 2>/dev/null)
FLUTTER := $(shell command -v flutter 2>/dev/null)

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Crossbar Build Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup        Install dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make run          Run app (hot reload)"
	@echo "  make test         Run tests"
	@echo "  make lint         Lint code"
	@echo ""
	@echo "Build:"
	@echo "  make build-linux   Build Linux release"
	@echo "  make build-android Build Android APK"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build  Build Docker images"
	@echo "  make docker-shell  Open shell in container"

.PHONY: setup
setup:
ifdef FLUTTER
	@echo "✅ Using native Flutter"
	flutter pub get
	flutter precache
else ifdef COMPOSE
	@echo "🐳 Using Docker/Podman"
	$(COMPOSE) build flutter-dev
	$(COMPOSE) run --rm flutter-dev flutter pub get
else
	@echo "❌ Neither Flutter nor Docker/Podman found"
	@echo "Install: https://flutter.dev or https://docker.com"
	exit 1
endif

.PHONY: run
run:
ifdef FLUTTER
	flutter run -d linux
else
	$(COMPOSE) up flutter-dev
endif

.PHONY: test
test:
ifdef FLUTTER
	flutter test --coverage
	@echo "Coverage: coverage/lcov.info"
else
	$(COMPOSE) run --rm flutter-test
endif

.PHONY: lint
lint:
ifdef FLUTTER
	flutter analyze
	dart format --set-exit-if-changed lib/ test/
else
	$(COMPOSE) run --rm flutter-dev flutter analyze
endif

.PHONY: build-linux
build-linux:
ifdef FLUTTER
	flutter build linux --release
	@echo "✅ Binary: build/linux/x64/release/bundle/crossbar"
else
	$(COMPOSE) run --rm flutter-linux
endif

.PHONY: build-android
build-android:
ifdef FLUTTER
	flutter build apk --release
	@echo "✅ APK: build/app/outputs/flutter-apk/app-release.apk"
else
	$(COMPOSE) run --rm flutter-android
endif

.PHONY: docker-build
docker-build:
	$(COMPOSE) build

.PHONY: docker-shell
docker-shell:
	$(COMPOSE) run --rm flutter-linux bash

.PHONY: clean
clean:
	rm -rf build/ .dart_tool/
ifdef FLUTTER
	flutter clean
endif
```

#### Docker Compose (Dev Local)

```yaml
# docker-compose.yml
version: "3.8"

services:
  flutter-dev:
    build:
      context: .
      dockerfile: docker/Dockerfile.linux
    volumes:
      - .:/workspace
      - flutter-pub-cache:/root/.pub-cache
      - /tmp/.X11-unix:/tmp/.X11-unix
    environment:
      - DISPLAY=${DISPLAY}
    network_mode: host
    working_dir: /workspace
    command: flutter run -d linux

  flutter-test:
    build:
      dockerfile: docker/Dockerfile.linux
    volumes:
      - .:/workspace
      - flutter-pub-cache:/root/.pub-cache
    working_dir: /workspace
    command: flutter test --coverage

  flutter-linux:
    build:
      dockerfile: docker/Dockerfile.linux
    volumes:
      - .:/workspace
      - flutter-pub-cache:/root/.pub-cache
    working_dir: /workspace
    command: flutter build linux --release

  flutter-android:
    build:
      dockerfile: docker/Dockerfile.android
    volumes:
      - .:/workspace
      - flutter-pub-cache:/root/.pub-cache
      - android-gradle-cache:/root/.gradle
    working_dir: /workspace
    command: flutter build apk --release

volumes:
  flutter-pub-cache:
  android-gradle-cache:
```

#### Dockerfiles

```dockerfile
# docker/Dockerfile.linux
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
RUN git clone -b stable --depth 1 https://github.com/flutter/flutter.git $FLUTTER_HOME
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN flutter doctor
RUN flutter precache --linux

WORKDIR /workspace
CMD ["flutter", "run", "-d", "linux"]
```

```dockerfile
# docker/Dockerfile.android
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils openjdk-17-jdk wget \
    && rm -rf /var/lib/apt/lists/*

# Android SDK
ENV ANDROID_HOME=/opt/android-sdk
RUN mkdir -p $ANDROID_HOME/cmdline-tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline.zip
RUN unzip -q /tmp/cmdline.zip -d $ANDROID_HOME/cmdline-tools && mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
RUN git clone -b stable --depth 1 https://github.com/flutter/flutter.git $FLUTTER_HOME
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN flutter doctor --android-licenses

WORKDIR /workspace
CMD ["flutter", "build", "apk", "--release"]
```

**Por quê Docker/Podman para dev local**:

- Onboarding instantâneo (só precisa Docker)
- Ambiente isolado (não "suja" máquina)
- Reproduzível (mesmo ambiente que CI)

**Podman**: 100% compatível com docker-compose (alias `docker=podman` funciona).

### 9.2 GitHub Actions CI/CD (Runners Nativos)

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

env:
  FLUTTER_VERSION: "3.24.0"

jobs:
  # ==================== LINT & TEST ====================
  analyze:
    name: Lint & Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Check formatting
        run: dart format --set-exit-if-changed lib/ test/

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

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Verify coverage >= 90%
        run: |
          sudo apt-get install -y lcov
          COVERAGE=$(lcov --summary coverage/lcov.info | grep "lines" | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 90" | bc -l) )); then
            echo "❌ Coverage $COVERAGE% < 90%"
            exit 1
          fi
          echo "✅ Coverage passed: $COVERAGE%"

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
          flags: unittests

  # ==================== BUILD MATRIX ====================
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

      - name: Build Linux
        run: flutter build linux --release

      - name: Package tarball
        run: |
          cd build/linux/x64/release/bundle
          tar czf ../../../../crossbar-linux-x64.tar.gz *

      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-linux
          path: build/crossbar-linux-x64.tar.gz

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: "zulu"
          java-version: "17"
          cache: "gradle"

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

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

      - name: Build Windows
        run: flutter build windows --release

      - name: Package ZIP
        run: |
          cd build/windows/x64/runner/Release
          7z a ../../../../crossbar-windows-x64.zip *

      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-windows
          path: build/crossbar-windows-x64.zip

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

      - name: Build macOS
        run: flutter build macos --release

      - name: Package DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "Crossbar" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --app-drop-link 600 185 \
            "build/Crossbar.dmg" \
            "build/macos/Build/Products/Release/Crossbar.app"

      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-macos
          path: build/Crossbar.dmg

  build-ios:
    name: Build iOS
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - run: flutter pub get

      - name: Build iOS (no codesign)
        run: flutter build ios --release --no-codesign

      - uses: actions/upload-artifact@v4
        with:
          name: crossbar-ios
          path: build/ios/iphoneos/Runner.app

  # ==================== RELEASE ====================
  release:
    name: Create Release
    if: github.event_name == 'release'
    needs: [build-linux, build-android, build-windows, build-macos, build-ios]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          path: artifacts

      - name: Upload to Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            artifacts/crossbar-linux/crossbar-linux-x64.tar.gz
            artifacts/crossbar-android/app-release.apk
            artifacts/crossbar-windows/crossbar-windows-x64.zip
            artifacts/crossbar-macos/Crossbar.dmg
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Por quê runners nativos no CI**:

- Velocidade (3-5x mais rápido que Docker-OSX/Windows containers)
- Confiabilidade (runners mantidos pelo GitHub)
- Zero manutenção
- iOS/macOS funcionam perfeitamente (assinatura, entitlements)

**Tempo total de CI**: ~10-15 minutos (todos jobs paralelos).

### 9.3 Versionamento (SemVer + Changelog)

**Semantic Versioning**:

```
v1.0.0  - Lançamento inicial
v1.1.0  - Nova feature (ex: novo comando --screenshot)
v1.1.1  - Bugfix (ex: corrige crash no parser)
v2.0.0  - Breaking change (ex: muda formato .config.json)
```

**Conventional Commits**:

```
feat: add --screenshot command
fix: resolve tray icon crash on Windows
docs: update plugin development guide
chore: upgrade Flutter to 3.25
refactor: simplify output parser
test: add integration tests for CLI
```

**Changelog automático**:

```yaml
# .github/workflows/release.yml (trigger em tag push)
on:
  push:
    tags:
      - "v*"

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Histórico completo

      - name: Generate Changelog
        uses: conventional-changelog-action@v5
        with:
          preset: conventionalcommits
          output-file: CHANGELOG.md
```

Gera:

```markdown
# Changelog

## [1.1.0] - 2025-12-01

### Features

- add --screenshot command (#123)
- add --wallpaper-set (#124)

### Bug Fixes

- resolve tray icon crash on Windows (#125)
- fix JSON parser handling of malformed input (#126)

### Documentation

- update plugin development guide (#127)
```

---

## 10. MARKETPLACE E ECOSSISTEMA

### 10.1 Busca no GitHub

**Tag padrão**: `#crossbar` (devs marcam repos de plugins)

```dart
// lib/services/marketplace_service.dart
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
      options: Options(headers: {
        'Accept': 'application/vnd.github.v3+json',
      }),
    );

    return (response.data['items'] as List)
      .map((item) => PluginRepo.fromJson(item))
      .toList();
  }
}

class PluginRepo {
  final String name;
  final String fullName;  // "user/repo"
  final String description;
  final int stars;
  final int downloads;  // Aproximado por clone count
  final String language;
  final String cloneUrl;

  PluginRepo.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      fullName = json['full_name'],
      description = json['description'] ?? 'No description',
      stars = json['stargazers_count'],
      downloads = json['watchers_count'] * 10,  // Estimativa
      language = json['language'] ?? 'Unknown',
      cloneUrl = json['clone_url'];
}
```

### 10.2 Instalação de Plugin

```bash
crossbar install https://github.com/user/weather-plugin
```

**Processo**:

1. Clone repo temporário (`/tmp/crossbar-install-xyz`)
2. Detecta arquivos executáveis (shebang ou extensão)
3. Valida estrutura mínima (README, LICENSE)
4. Move pra `~/.crossbar/plugins/<language>/`
5. `chmod +x` (Linux/macOS)
6. Detecta `.config.json` (se existir)
7. Ativa plugin automaticamente

```dart
// lib/services/plugin_installer.dart
class PluginInstaller {
  Future<void> install(String repoUrl) async {
    final tmpDir = Directory.systemTemp.createTempSync('crossbar-install-');

    try {
      // 1. Clone
      await Process.run('git', ['clone', '--depth', '1', repoUrl, tmpDir.path]);

      // 2. Find executable
      final executable = await _findExecutable(tmpDir);
      if (executable == null) {
        throw Exception('No executable script found (must have shebang or .sh/.py/.js extension)');
      }

      // 3. Detect language
      final language = _detectLanguage(executable);

      // 4. Copy to plugins dir
      final destDir = Directory(path.join(
        _crossbarHome,
        'plugins',
        language,
      ));
      await destDir.create(recursive: true);

      final destPath = path.join(destDir.path, path.basename(executable.path));
      await executable.copy(destPath);

      // 5. Make executable
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', destPath]);
      }

      // 6. Copy config if exists
      final configFile = File(path.join(tmpDir.path, '${path.basenameWithoutExtension(executable.path)}.config.json'));
      if (await configFile.exists()) {
        await configFile.copy(path.join(destDir.path, path.basename(configFile.path)));
      }

      print('✅ Installed: ${path.basename(destPath)}');

    } finally {
      await tmpDir.delete(recursive: true);
    }
  }

  File? _findExecutable(Directory dir) {
    final files = dir.listSync(recursive: true).whereType<File>();

    for (var file in files) {
      // Check shebang
      final firstLine = file.readAsLinesSync().firstOrNull ?? '';
      if (firstLine.startsWith('#!')) return file;

      // Check extension
      final ext = path.extension(file.path);
      if (['.sh', '.py', '.js', '.dart', '.go', '.rs'].contains(ext)) {
        return file;
      }
    }

    return null;
  }

  String _detectLanguage(File file) {
    final shebang = file.readAsLinesSync().firstOrNull ?? '';
    if (shebang.contains('python')) return 'python';
    if (shebang.contains('node')) return 'node';
    if (shebang.contains('bash')) return 'bash';

    final ext = path.extension(file.path);
    switch (ext) {
      case '.py': return 'python';
      case '.js': return 'node';
      case '.sh': return 'bash';
      case '.dart': return 'dart';
      case '.go': return 'go';
      case '.rs': return 'rust';
      default: return 'bash';  // Fallback
    }
  }
}
```

### 10.3 Template de Plugin (`crossbar init`)

```bash
crossbar init --lang python --type clock
```

**Gera**:

```
~/.crossbar/plugins/python/clock.5s.py
~/.crossbar/plugins/python/clock.config.json
~/.crossbar/plugins/python/clock_test.py
```

**Template**:

```python
#!/usr/bin/env python3
"""
CROSSBAR_CONFIG:
{
  "name": "Clock",
  "description": "Shows current time",
  "icon": "🕐",
  "config_required": "optional",
  "settings": [
    {
      "key": "CLOCK_FORMAT",
      "label": "Time Format",
      "type": "select",
      "options": [
        {"value": "12h", "label": "12-hour"},
        {"value": "24h", "label": "24-hour"}
      ],
      "default": "24h"
    }
  ]
}
"""

import subprocess
import json
import os

def main():
    # Get config
    format_type = os.environ.get('CLOCK_FORMAT', '24h')

    # Use Crossbar API
    time = subprocess.run(
        ['crossbar', '--time', f'fmt={format_type}'],
        capture_output=True,
        text=True
    ).stdout.strip()

    # Return structured output
    output = {
        "icon": "🕐",
        "text": time,
        "menu": [
            {"text": f"Current time: {time}"},
            {"separator": True},
            {"text": "Settings", "bash": "crossbar config clock.5s.py --gui"}
        ]
    }

    print(json.dumps(output))

if __name__ == '__main__':
    main()
```

**Por quê `crossbar init`**: Onboarding instantâneo - dev não precisa ler docs, já começa com template funcional.

---

## 11. DOCUMENTAÇÃO

### 11.1 README.md (Estrutura Completa)

```markdown
# 🚀 Crossbar

Universal plugin system for menu bar / system tray / notifications.  
Write once in any language, run on **Linux**, **Windows**, **macOS**, **Android**, **iOS**.

[![CI](https://github.com/verseles/crossbar/workflows/CI/badge.svg)](https://github.com/verseles/crossbar/actions)
[![Coverage](https://codecov.io/gh/verseles/crossbar/branch/main/graph/badge.svg)](https://codecov.io/gh/verseles/crossbar)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](LICENSE)

---

## ✨ Features

- 🌍 **Cross-platform**: One plugin works on 5 OSes
- 🔌 **Unified API**: 45+ commands (`--cpu`, `--web`, `--media-play`)
- 🎨 **Auto-rendering**: Plugin returns data, UI adapts (tray/notification/widget)
- ⚙️ **Declarative config**: Define fields in JSON, GUI auto-generates
- 🔄 **Hot reload**: Edit plugin, see changes instantly
- 🛒 **Marketplace**: GitHub-based plugin discovery
- 🌐 **10 languages**: EN, PT_BR, ES, FR, ZH, HI, AR, BN, RU, JA

---

<details>
<summary>📦 Installation</summary>

### Linux
```

wget https://github.com/verseles/crossbar/releases/latest/download/crossbar-linux-x64.tar.gz
tar xzf crossbar-linux-x64.tar.gz
sudo mv crossbar /usr/local/bin/

```

### macOS
```

brew install verseles/tap/crossbar

```

### Windows
Download `crossbar-windows-x64.zip` from [Releases](https://github.com/verseles/crossbar/releases), extract, add to PATH.

### Android
Install APK from [Releases](https://github.com/verseles/crossbar/releases).

</details>

<details>
<summary>🚀 Quick Start</summary>

```

# Start Crossbar (runs in background)

crossbar

# Open GUI

crossbar --gui

# or press Ctrl+Alt+C

# Create your first plugin

crossbar init --lang python --type clock

```

</details>

<details>
<summary>🔧 Plugin Development</summary>

### Simple Example (Bash)
```

\#!/bin/bash

# ~/.crossbar/plugins/bash/clock.5s.sh

echo "🕐 \$(crossbar --time fmt=24h)"

```

### Advanced Example (Python)
```

\#!/usr/bin/env python3
import subprocess, json

cpu = subprocess.run(['crossbar', '--cpu'], capture_output=True, text=True)

print(json.dumps({
"icon": "⚡",
"text": f"{cpu.stdout.strip()}%",
"menu": [
{"text": "Details", "bash": "/usr/bin/top"}
]
}))

```

See [Plugin Development Guide](docs/plugin-development.md).

</details>

<details>
<summary>📚 API Reference</summary>

### System
- `crossbar --cpu` - CPU usage (%)
- `crossbar --memory` - RAM free/total
- `crossbar --battery` - Battery level + charging
- `crossbar --uptime` - Time since boot

### Network
- `crossbar --web <url>` - HTTP request (GET/POST/PUT)
- `crossbar --net-status` - Connection type (wifi/ethernet/offline)
- `crossbar --net-ip` - Local IP address

### Media
- `crossbar --media-play` - Resume playback
- `crossbar --media-pause` - Pause
- `crossbar --audio-volume-set 50` - Set volume

Full list: [API Reference](docs/api-reference.md)

</details>

<details>
<summary>🛠️ Development Setup</summary>

### Option 1: Native Flutter
```

# Install Flutter: https://flutter.dev/get-started

make setup
make run

```

### Option 2: Docker/Podman
```

make docker-build
make setup
make run

```

### Run Tests
```

make test \# Requires >= 90% coverage

```

</details>

<details>
<summary>🤝 Contributing</summary>

See [CONTRIBUTING.md](CONTRIBUTING.md).

</details>

---

## 📄 License

AGPLv3 - Ensures derivative works and SaaS remain open source.
See [LICENSE](LICENSE).

---

## 🙏 Acknowledgments

Inspired by [BitBar](https://github.com/matryer/bitbar) (macOS) and [Argos](https://github.com/p-e-w/argos) (Linux).
```

**Por quê accordion**: README grande (~500 linhas), mas colapsável = não assusta iniciantes.

### 11.2 Outros Arquivos

- **CONTRIBUTING.md**: Como contribuir, padrão de commits, PR template
- **LICENSE**: AGPLv3 completa
- **SECURITY.md**: Como reportar vulnerabilidades (email privado)
- **docs/plugin-development.md**: Tutorial passo-a-passo
- **docs/api-reference.md**: Lista completa de 45 comandos CLI
- **docs/config-schema.md**: Todos 25 tipos de campos de configuração
- **docs/advanced-build.md**: Docker-OSX/Windows containers (experimental)

---

## 12. ROADMAP FUTURO (Pós-V1)

### V2.0 (6-12 meses após lançamento)

- **Telemetria opt-in**: OpenTelemetry + Grafana (métricas de uso, crashes)
- **Package managers**: Homebrew, Snap, Flatpak, winget, AUR
- **Plugin sandboxing** (opcional): Permissões granulares (rede, filesystem)
- **Sync de configs**: Backup automático via GitHub Gists ou serviço próprio
- **Theme customization**: Além de dark/light, temas custom (cores, fontes)
- **Voice commands**: Integração com assistentes (Siri, Google Assistant)
- **Widgets maiores**: 4x4, full-screen widgets
- **Remote plugins**: Plugins rodando em servidores (webhooks, APIs)

### Community-driven

- **50+ plugins oficiais**: Kubernetes, Docker, Terraform, AWS, etc
- **Translations**: +20 idiomas via Crowdin
- **Video tutorials**: YouTube, TikTok (onboarding visual)
- **Discord/Matrix**: Comunidade ativa para suporte

---

## 13. PERFORMANCE TARGETS

**Boot Time** (app startup até primeiro tray icon):

- Desktop: < 2s
- Android: < 3s (cold start)

**Memory Footprint** (idle, 3 plugins ativos):

- Desktop: < 150MB RAM
- Android: < 100MB RAM

**Plugin Execution Overhead** (spawn + parse):

- < 50ms por plugin

**Hot Reload**:

- < 1s após salvar arquivo

**Builds CI/CD**:

- Total (5 plataformas): < 15 minutos

---

## 14. CONSIDERAÇÕES FINAIS

### 14.1 Por Que Este Plano é Executável

1. **Tech stack madura**: Flutter 3.24 é estável, packages bem mantidos
2. **Arquitetura simples**: Process.run + parsers + Flutter UI (sem magia)
3. **Inspiração comprovada**: BitBar/Argos já validaram conceito (7+ anos)
4. **Testes obrigatórios**: 90% coverage garante qualidade desde V1
5. **CI/CD automatizado**: Zero intervenção manual após merge

### 14.2 Complexidade vs. Valor

**Mais complexo**: Sistema de configuração declarativa (25 tipos de campos)
**Por quê vale**: Diferencial competitivo absoluto - nenhuma ferramenta tem isso

**Mais complexo**: Renderização adaptativa (tray/notificação/widget)
**Por quê vale**: "Write once, run everywhere" real - não é marketing

**Mais complexo**: 45 comandos CLI cross-platform
**Por quê vale**: Plugins se tornam triviais (3 linhas de bash)

### 14.3 Riscos e Mitigações

| Risco                   | Probabilidade | Impacto | Mitigação                                           |
| :---------------------- | :------------ | :------ | :-------------------------------------------------- |
| Flutter depreca desktop | Baixa         | Alto    | Flutter Desktop é GA desde 2022, Google investe     |
| Packages quebram        | Média         | Médio   | Pin versões, testes cobrem integrações              |
| iOS restringe mais      | Alta          | Médio   | Widgets já são limitados, documentar claramente     |
| Comunidade não adota    | Média         | Alto    | Marketplace + 24 plugins oficiais + docs excelentes |

### 14.4 Métricas de Sucesso (6 meses pós-lançamento)

- 1.000+ stars no GitHub
- 50+ plugins comunitários
- 10.000+ downloads
- 5+ contribuidores ativos
- 0 issues críticas abertas por >48h

---

**FIM DO PLANO EXECUTIVO**

---

## ANEXO: Checklist de Implementação

### Fase 1: Core (Semanas 1-2)

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

**PLANO EXECUTIVO COMPLETO - VERSÃO 1.0**
**Gerado em**: 30 de novembro de 2025
**Repositório**: verseles/crossbar
**Licença**: AGPLv3

## ANEXO B: Documentação e Recursos Técnicos

### 📚 Documentação Oficial

#### Flutter & Dart

- **Flutter Documentation**: https://docs.flutter.dev/
- **Flutter Desktop**: https://docs.flutter.dev/platform-integration/desktop
- **Flutter Android**: https://docs.flutter.dev/platform-integration/android
- **Flutter iOS**: https://docs.flutter.dev/platform-integration/ios
- **Dart Language Tour**: https://dart.dev/language
- **Dart Packages**: https://pub.dev/
- **Flutter Testing**: https://docs.flutter.dev/testing
- **Flutter Architecture**: https://docs.flutter.dev/app-architecture

#### APIs Nativas por Plataforma

- **Android Foreground Services**: https://developer.android.com/develop/background-work/services/fgs
- **Android App Widgets**: https://developer.android.com/develop/ui/views/appwidgets
- **Android Notification**: https://developer.android.com/develop/ui/views/notifications
- **iOS WidgetKit**: https://developer.apple.com/documentation/widgetkit
- **iOS Background Tasks**: https://developer.apple.com/documentation/backgroundtasks
- **macOS Menu Bar**: https://developer.apple.com/design/human-interface-guidelines/the-menu-bar
- **Windows System Tray**: https://learn.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications/
- **Linux System Tray (libappindicator)**: https://wiki.ubuntu.com/DesktopExperienceTeam/ApplicationIndicators

#### i18n e Localização

- **Flutter Internationalization**: https://docs.flutter.dev/ui/internationalization
- **Intl Package**: https://pub.dev/packages/intl
- **ARB Format Spec**: https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification
- **ICU Message Format**: https://unicode-org.github.io/icu/userguide/format_parse/messages/

#### HTTP & Networking

- **Dio Documentation**: https://pub.dev/documentation/dio/latest/
- **Dio GitHub**: https://github.com/cfug/dio
- **HTTP Status Codes**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

#### Segurança

- **Flutter Secure Storage**: https://pub.dev/packages/flutter_secure_storage
- **Keychain Services (iOS/macOS)**: https://developer.apple.com/documentation/security/keychain_services
- **Android KeyStore**: https://developer.android.com/privacy-and-security/keystore
- **Windows Credential Manager**: https://learn.microsoft.com/en-us/windows/win32/secauthn/credential-manager

---

### 📦 Packages Flutter (Dependências Principais)

#### UI & Sistema

```yaml
dependencies:
  flutter:
    sdk: flutter

  # System Tray (Desktop)
  tray_manager: ^0.2.3
  # https://pub.dev/packages/tray_manager
  # Multi-platform system tray: Windows, Linux, macOS

  # Window Management
  window_manager: ^0.4.2
  # https://pub.dev/packages/window_manager
  # Controla janela: hide, show, posição, tamanho

  # Path Provider (Diretórios cross-platform)
  path_provider: ^2.1.4
  # https://pub.dev/packages/path_provider
  # ~/.crossbar/, temp dirs, app data dirs

  # File Picker
  file_picker: ^8.1.2
  # https://pub.dev/packages/file_picker
  # Native file/folder picker para campos "file" e "directory"
```

#### Networking & HTTP

```yaml
# HTTP Client
dio: ^5.7.0
# https://pub.dev/packages/dio
# Client HTTP robusto: interceptors, retries, timeout, SSL

# Connectivity Status
connectivity_plus: ^6.1.0
# https://pub.dev/packages/connectivity_plus
# Detecta wifi/cellular/ethernet/offline para --net-status
```

#### Armazenamento & Dados

```yaml
# Secure Storage (Keychain/KeyStore)
flutter_secure_storage: ^9.2.2
# https://pub.dev/packages/flutter_secure_storage
# Salva passwords em Keychain (iOS/macOS), KeyStore (Android), Credential Manager (Windows)

# Shared Preferences (Config global)
shared_preferences: ^2.3.2
# https://pub.dev/packages/shared_preferences
# Settings: tema, idioma, refresh overrides

# SQLite (Histórico/logs opcional)
sqflite: ^2.3.3+2
# https://pub.dev/packages/sqflite
# Se quiser histórico de execuções, logs estruturados
```

#### i18n

```yaml
# Internationalization (Oficial Google)
intl: ^0.19.0
# https://pub.dev/packages/intl
# Traduções, plurais, formatação de data/número

flutter_localizations:
  sdk: flutter
```

#### Device Info

```yaml
# Device Information
device_info_plus: ^10.1.2
# https://pub.dev/packages/device_info_plus
# Para --device-model, --device-screen, detalhes do hardware

# Battery Info
battery_plus: ^6.0.2
# https://pub.dev/packages/battery_plus
# Para --battery (nível, charging status)

# Package Info (Versão do app)
package_info_plus: ^8.0.2
# https://pub.dev/packages/package_info_plus
# Para CROSSBAR_VERSION no ENV
```

#### Widgets Mobile

```yaml
# Home Screen Widgets (Android/iOS)
home_widget: ^0.6.0
# https://pub.dev/packages/home_widget
# Bridge Flutter ↔ WidgetKit (iOS) / App Widget (Android)
```

#### Process & Sistema

```yaml
# Process Runner (built-in dart:io já cobre, mas para parsing avançado)
process_run: ^1.2.0
# https://pub.dev/packages/process_run
# Alternativa com melhor API que dart:io Process
```

#### Notificações

```yaml
# Local Notifications
flutter_local_notifications: ^17.2.3
# https://pub.dev/packages/flutter_local_notifications
# Notificações locais (Android persistent notifications, iOS alerts)
```

#### Clipboard

```yaml
# Clipboard Manager
clipboard: ^0.1.3
# https://pub.dev/packages/clipboard
# Para --clipboard e --clipboard-set
```

#### URL Launcher

```yaml
# URL Launcher
url_launcher: ^6.3.1
# https://pub.dev/packages/url_launcher
# Para --open-url, --open-file, deep links crossbar://
```

#### Markdown & Rich Text (Opcional)

```yaml
# Markdown Editor (se implementar tipo "markdown" em configs)
flutter_markdown: ^0.7.3+1
# https://pub.dev/packages/flutter_markdown

# Code Editor (se implementar tipo "code")
flutter_code_editor: ^0.3.5
# https://pub.dev/packages/flutter_code_editor
```

#### Color Picker

```yaml
# Color Picker
flutter_colorpicker: ^1.1.0
# https://pub.dev/packages/flutter_colorpicker
# Para tipo "color" em configurações
```

---

### 🛠️ Dev Dependencies (Testes, Lint, Build)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linting
  flutter_lints: ^4.0.0
  # https://pub.dev/packages/flutter_lints
  # Regras de lint recomendadas pelo Flutter team

  # Mocking
  mockito: ^5.4.4
  # https://pub.dev/packages/mockito
  # Mock classes para testes (Dio, TrayManager, etc)

  # Build Runner (geração de código)
  build_runner: ^2.4.13
  # https://pub.dev/packages/build_runner
  # Para gerar código (mockito, intl, json_serializable)

  # JSON Serialization
  json_serializable: ^6.8.0
  # https://pub.dev/packages/json_serializable
  # Para models (Plugin, PluginConfig, etc)

  # Coverage
  coverage: ^1.9.2
  # https://pub.dev/packages/coverage
  # Gerar lcov.info

  # Integration Tests
  integration_test:
    sdk: flutter
```

---

### 📖 Referências Técnicas

#### BitBar & Argos (Inspiração)

- **BitBar GitHub**: https://github.com/matryer/bitbar
- **BitBar Plugin Format**: https://github.com/matryer/bitbar#writing-plugins
- **Argos GitHub**: https://github.com/p-e-w/argos
- **Argos Extensions**: https://extensions.gnome.org/extension/1176/argos/

#### System Tray Implementations

- **tray_manager Source**: https://github.com/leanflutter/tray_manager
- **Electron System Tray**: https://www.electronjs.org/docs/latest/api/tray (referência de API)
- **Qt System Tray**: https://doc.qt.io/qt-6/qsystemtrayicon.html

#### CI/CD & DevOps

- **GitHub Actions Flutter**: https://github.com/marketplace/actions/flutter-action
- **GitHub Actions Matrix**: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/

#### Docker & Containerization

- **Docker-OSX**: https://github.com/sickcodes/Docker-OSX
- **Flutter Docker Images**: https://github.com/cirruslabs/docker-images-flutter
- **Podman Compose**: https://github.com/containers/podman-compose

#### Open Source Best Practices

- **GitHub Community Standards**: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions
- **Open Source Guides**: https://opensource.guide/
- **AGPL-3.0 License**: https://www.gnu.org/licenses/agpl-3.0.html
- **SPDX License List**: https://spdx.org/licenses/

---

### 🎨 Design Resources (Ícones, UI)

- **Material Icons**: https://fonts.google.com/icons (ícones padrão Flutter)
- **Emoji Database**: https://emojipedia.org/ (para ícones emoji em plugins)
- **Flutter Widget Catalog**: https://docs.flutter.dev/ui/widgets
- **Material Design 3**: https://m3.material.io/
- **Cupertino (iOS Style)**: https://docs.flutter.dev/ui/widgets/cupertino

---

### 📝 Exemplos de Código Relevantes

#### Flutter Desktop Tray Examples

- **Tray Manager Example**: https://github.com/leanflutter/tray_manager/tree/main/example
- **Window Manager Example**: https://github.com/leanflutter/window_manager/tree/main/example

#### Flutter Widget Examples

- **Home Widget Example**: https://github.com/ABausG/home_widget/tree/main/example
- **Flutter Widget Tests**: https://github.com/flutter/flutter/tree/main/examples/flutter_gallery/test

#### Process Execution Examples

- **Dart Process Examples**: https://api.dart.dev/stable/dart-io/Process-class.html
- **Shell Command Runner**: https://github.com/google/dart-process

#### GitHub API Integration

- **GitHub REST API**: https://docs.github.com/en/rest
- **Search Repositories**: https://docs.github.com/en/rest/search/search#search-repositories
- **Releases API**: https://docs.github.com/en/rest/releases/releases

---

### 🧪 Ferramentas de Desenvolvimento

#### IDE & Editores

- **VS Code Flutter Extension**: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
- **Android Studio**: https://developer.android.com/studio
- **IntelliJ IDEA Flutter Plugin**: https://plugins.jetbrains.com/plugin/9212-flutter

#### Debugging & Profiling

- **Flutter DevTools**: https://docs.flutter.dev/tools/devtools/overview
- **Dart Observatory**: https://dart.dev/tools/dart-devtools
- **Android Studio Profiler**: https://developer.android.com/studio/profile

#### Testing Tools

- **Flutter Test**: https://docs.flutter.dev/testing/overview
- **Integration Testing**: https://docs.flutter.dev/testing/integration-tests
- **Golden Tests**: https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test

#### Code Quality

- **Dart Analyzer**: https://dart.dev/tools/analysis
- **Codecov**: https://codecov.io/ (coverage reporting)
- **Dependabot**: https://github.com/dependabot (dependency updates)

---

### 🌐 Community & Support

- **Flutter Community**: https://flutter.dev/community
- **Flutter Discord**: https://discord.gg/flutter
- **r/FlutterDev**: https://www.reddit.com/r/FlutterDev/
- **Stack Overflow [flutter]**: https://stackoverflow.com/questions/tagged/flutter
- **Dart Language Discord**: https://discord.gg/dart-lang

---

### 📚 Tutoriais Relevantes

#### Flutter Desktop Development

- **Building Desktop Apps with Flutter**: https://codelabs.developers.google.com/codelabs/flutter-desktop-to-web
- **System Tray Tutorial**: https://medium.com/@leanflutter/flutter-system-tray-guide

#### Plugin Architecture

- **Flutter Platform Channels**: https://docs.flutter.dev/platform-integration/platform-channels
- **Method Channels Deep Dive**: https://medium.com/flutter/flutter-platform-channels-ce7f540a104e

#### Testing Best Practices

- **Flutter Testing Guide**: https://verygood.ventures/blog/guide-to-flutter-testing
- **Widget Testing Patterns**: https://medium.com/flutter-community/flutter-widget-testing-the-essential-guide

---

### 🔧 Ferramentas CLI Úteis

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

### 📊 Monitoramento (Futuro - V2)

- **OpenTelemetry Dart**: https://pub.dev/packages/opentelemetry
- **Sentry Flutter**: https://pub.dev/packages/sentry_flutter
- **Firebase Crashlytics**: https://firebase.google.com/docs/crashlytics/get-started?platform=flutter
- **Grafana**: https://grafana.com/docs/
- **Prometheus**: https://prometheus.io/docs/

---

**FIM DO ANEXO B - RECURSOS TÉCNICOS**

Todos os links foram verificados e apontam para documentação oficial, packages estáveis (pub.dev), ou recursos comunitários relevantes. Priorize sempre as versões mais recentes dos packages no momento da implementação.

## ANEXO C: Toolchains e Dependências (Linux) - VERSÕES ATUALIZADAS (Nov 2025)

### 🐧 Ambiente de Desenvolvimento Linux Completo

#### 1. Sistema Base

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

---

#### 2. Flutter SDK (Obrigatório)

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

**Versão atual (Nov 2025)**: Flutter 3.35.2 / Dart 3.10.0[1][2]
**Versão mínima recomendada**: Flutter 3.24.0+

**Verificação**:

```bash
flutter --version
# Flutter 3.35.2 • channel stable
# Dart 3.10.0 • DevTools 2.38.2

dart --version
# Dart SDK version: 3.10.0 (stable) (Mon Nov 12 2025)
```

**Por quê Flutter 3.35+**: Dart 3.10 inclui melhorias de performance significativas e novas features de linguagem. Hot reload disponível para web sem flags experimentais.[3]

---

#### 3. Dependências Linux Desktop (Obrigatório)

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

**Por quê**:

- `clang`: Compilador C++ (Flutter Linux usa Clang 14+)
- `cmake`: Build system (3.22+)
- `ninja-build`: Build executor (mais rápido que make)
- `libgtk-3-dev`: GTK3 3.24+ (UI nativa Linux)
- `pkg-config`: Detecção de bibliotecas

**Verificação**:

```bash
clang --version
# Ubuntu clang version 14.0.0 ou superior

cmake --version
# cmake version 3.22.1 ou superior

pkg-config --modversion gtk+-3.0
# 3.24.33 ou superior
```

---

#### 4. Android SDK (Obrigatório para APK)

```bash
# Java 25 LTS (última versão LTS lançada em Set 2025)
# Ubuntu/Debian
sudo apt-get install -y openjdk-25-jdk

# Fedora
sudo dnf install -y java-25-openjdk-devel

# Arch
sudo pacman -S jdk25-openjdk

# Verificar
java -version
# openjdk version "25" 2025-09-16

# Definir JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64' >> ~/.bashrc

# Android Command Line Tools (última versão estável)
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools

wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest

# Adicionar ao PATH
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc

# Instalar SDK essenciais (Android 16 / API 36 é a mais recente)
sdkmanager "platform-tools"
sdkmanager "platforms;android-36"
sdkmanager "build-tools;36.0.0"
sdkmanager "ndk;27.1.12297006"

# IMPORTANTE: Para Google Play, target mínimo é API 35 (Android 15)
sdkmanager "platforms;android-35"
sdkmanager "build-tools;35.0.0"

# Aceitar licenças
flutter doctor --android-licenses
```

**Versões atuais (Nov 2025)**:[4][5][6]

- **Android 16** (API 36) - Última versão disponível
- **Android 15** (API 35) - Obrigatório para Google Play desde Ago 2025
- **Java 25 LTS** - Lançado em Set 2025[7][8]

**Por quê Java 25**: É a versão LTS mais recente (suporte até Set 2030+), sucedendo Java 21.[8]

**Por quê API 35**: Google Play exige target API 35+ desde 31 de agosto de 2025.[6][9]

**Verificação**:

```bash
adb --version
# Android Debug Bridge version 1.0.41 ou superior

sdkmanager --list | head -30
# Installed packages:
#   build-tools;35.0.0
#   build-tools;36.0.0
#   ndk;27.1.12297006
#   platform-tools
#   platforms;android-35
#   platforms;android-36
```

---

#### 5. Linguagens de Plugins (Todas Obrigatórias)

##### A. Bash (Pré-instalado)

```bash
bash --version
# GNU bash, version 5.1.16 ou superior
```

##### B. Python 3.14 (Versão mais recente)

```bash
# Ubuntu/Debian (pode precisar PPA para 3.14)
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.14 python3.14-venv python3-pip

# Fedora (geralmente já tem versão recente)
sudo dnf install -y python3.14 python3-pip

# Arch (sempre atual)
sudo pacman -S python python-pip

# Verificar
python3.14 --version
# Python 3.14.0

# Criar alias (opcional, para manter compatibilidade)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1

# Pip
pip3 --version
# pip 24.2 ou superior
```

**Versão atual (Nov 2025)**: Python 3.14.0 (lançado em 07 Out 2025)[10][11]
**Suporte até**: Outubro 2030 (Security Support)[11]

**Por quê Python 3.14**: Nova versão estável com melhorias significativas de performance e runtime. Python 3.9 atingiu end-of-life em outubro 2025.[10][11]

**Alternativa**: Python 3.13.9 (LTS com suporte até 2029) se 3.14 ainda não estiver em repos oficiais.[11]

##### C. Node.js 24 LTS "Krypton"

```bash
# Via NodeSource (método recomendado)
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs

# Ou via nvm (recomendado para múltiplas versões)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 24
nvm use 24

# Verificar
node --version
# v24.11.1

npm --version
# 10.9.0
```

**Versão atual (Nov 2025)**: Node.js 24.11.1 LTS "Krypton"[12][13][14]
**Status**: Entrou em LTS em 28 Out 2025[13]
**Suporte até**: Abril 2028[13]

**Por quê Node 24 LTS**: Versão mais recente em Long Term Support, com V8 14.1 e melhorias significativas em `JSON.stringify`.[14]

**Alternativa**: Node.js 20.19.6 LTS "Iron" (suporte até Out 2026).[15]

##### D. Dart (Já incluído no Flutter SDK)

```bash
dart --version
# Dart SDK version: 3.10.0 (stable)
```

**Versão incluída**: Dart 3.10.0 com Flutter 3.35+[2]

##### E. Go 1.25

```bash
# Download Go 1.25 (última versão lançada em Ago 2025)
wget https://go.dev/dl/go1.25.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.linux-amd64.tar.gz

# Adicionar ao PATH
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verificar
go version
# go version go1.25 linux/amd64
```

**Versão atual (Nov 2025)**: Go 1.25 (lançado em Ago 2025)[16][17]
**Features**: Novo garbage collector experimental, encoding/json/v2, GOMAXPROCS CPU limit awareness, testing/synctest estável.[17]

**Por quê Go 1.25**: Melhorias significativas de performance e novas features para desenvolvimento moderno.[17]

##### F. Rust 1.91

```bash
# Via rustup (gerenciador oficial)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Seguir prompts (escolher instalação padrão)
source $HOME/.cargo/env

# Atualizar para versão mais recente
rustup update stable

# Verificar
rustc --version
# rustc 1.91.1 (stable)

cargo --version
# cargo 1.91.0
```

**Versão atual (Nov 2025)**: Rust 1.91.1 (stable)[18]
**Próximas versões**:

- Beta: 1.92.0 (11 Dez 2025)
- Nightly: 1.93.0 (22 Jan 2026)[18]

**Nota**: Rust 2024 edition foi lançado junto com 1.85 em Fev 2025.[19]

---

#### 6. Ferramentas de Teste e Qualidade (Obrigatório)

```bash
# LCOV (cobertura de testes)
# Ubuntu/Debian
sudo apt-get install -y lcov

# Fedora
sudo dnf install -y lcov

# Arch
sudo pacman -S lcov

# Verificar
lcov --version
# lcov: LCOV version 1.16 ou superior

# BC (cálculo matemático para checar coverage no CI)
sudo apt-get install -y bc  # Ubuntu/Debian
sudo dnf install -y bc      # Fedora
sudo pacman -S bc           # Arch

bc --version
# bc 1.07.1 ou superior
```

---

#### 7. Docker/Podman (Opcional para Dev, Obrigatório para CI alternativo)

##### Opção A: Docker

```bash
# Ubuntu/Debian (via Docker oficial)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker (evita sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker --version
# Docker version 27.3.1 ou superior

# Docker Compose V2
sudo apt-get install -y docker-compose-plugin

docker compose version
# Docker Compose version v2.30.0 ou superior
```

##### Opção B: Podman (Alternativa open-source)

```bash
# Ubuntu/Debian
sudo apt-get install -y podman podman-compose

# Fedora (pré-instalado geralmente)
sudo dnf install -y podman podman-compose

# Arch
sudo pacman -S podman podman-compose

# Verificar
podman --version
# podman version 5.2.0 ou superior

podman-compose --version
# podman-compose version 1.2.0 ou superior
```

---

#### 8. Ferramentas Auxiliares (Recomendado)

```bash
# Make (Makefile)
sudo apt-get install -y make

make --version
# GNU Make 4.3 ou superior

# JQ (parsing JSON em scripts)
sudo apt-get install -y jq

jq --version
# jq-1.7 ou superior

# Tree (visualizar estrutura de diretórios)
sudo apt-get install -y tree

# HTTPie (testar API GitHub manualmente)
sudo apt-get install -y httpie

http --version
# 3.2.3 ou superior

# Vim/Nano (editar plugins rapidamente)
sudo apt-get install -y vim nano
```

---

### ✅ Verificação Completa do Ambiente

#### Script de Verificação Automática (Atualizado)

```bash
#!/bin/bash
# check_environment.sh - Versão Nov 2025

echo "🔍 Verificando Ambiente de Desenvolvimento Crossbar (Nov 2025)"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 instalado: $(command -v $1)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NÃO encontrado"
        return 1
    fi
}

check_version() {
    echo -e "${YELLOW}ℹ${NC} $1: $($2)"
}

check_min_version() {
    local name=$1
    local current=$2
    local minimum=$3

    if [ "$(printf '%s\n' "$minimum" "$current" | sort -V | head -n1)" = "$minimum" ]; then
        echo -e "${GREEN}✓${NC} $name: $current (>= $minimum)"
    else
        echo -e "${RED}✗${NC} $name: $current (< $minimum requerido)"
    fi
}

echo "=== Sistema Base ==="
check_command git
check_command curl
check_command unzip

echo ""
echo "=== Flutter & Dart ==="
check_command flutter && {
    flutter_version=$(flutter --version | head -1 | grep -oP 'Flutter \K[0-9.]+')
    check_min_version "Flutter" "$flutter_version" "3.24.0"
}
check_command dart && {
    dart_version=$(dart --version 2>&1 | grep -oP 'Dart SDK version: \K[0-9.]+')
    check_min_version "Dart" "$dart_version" "3.5.0"
}

echo ""
echo "=== Build Tools Linux ==="
check_command clang
check_command cmake && {
    cmake_version=$(cmake --version | head -1 | grep -oP '[0-9.]+')
    check_min_version "CMake" "$cmake_version" "3.22.0"
}
check_command ninja
check_command pkg-config

echo ""
echo "=== Android ==="
check_command java && {
    java_version=$(java -version 2>&1 | head -1 | grep -oP 'version "\K[0-9]+')
    check_min_version "Java" "$java_version" "17"
}
if [ -d "$HOME/Android/Sdk" ]; then
    echo -e "${GREEN}✓${NC} ANDROID_HOME: $HOME/Android/Sdk"
    if [ -f "$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
        echo -e "${YELLOW}ℹ${NC} Android SDK Platform Tools:"
        $HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --list | grep "platforms;android-" | head -5
    fi
else
    echo -e "${RED}✗${NC} ANDROID_HOME não configurado"
fi

echo ""
echo "=== Linguagens de Plugins ==="
check_command bash && check_version "Bash" "bash --version | head -1"

if command -v python3.14 &> /dev/null; then
    check_version "Python 3.14" "python3.14 --version"
elif command -v python3.13 &> /dev/null; then
    check_version "Python 3.13" "python3.13 --version"
elif command -v python3 &> /dev/null; then
    python_ver=$(python3 --version | grep -oP '[0-9.]+')
    check_min_version "Python" "$python_ver" "3.10.0"
else
    echo -e "${RED}✗${NC} Python 3 não encontrado"
fi

check_command node && {
    node_version=$(node --version | grep -oP '[0-9.]+')
    check_min_version "Node.js" "$node_version" "20.0.0"
}

check_command go && {
    go_version=$(go version | grep -oP 'go\K[0-9.]+')
    check_min_version "Go" "$go_version" "1.21.0"
}

check_command rustc && {
    rust_version=$(rustc --version | grep -oP '[0-9.]+')
    check_min_version "Rust" "$rust_version" "1.75.0"
}

echo ""
echo "=== Testes & Qualidade ==="
check_command lcov
check_command bc

echo ""
echo "=== Docker/Podman (Opcional) ==="
if check_command docker; then
    docker_version=$(docker --version | grep -oP '[0-9.]+' | head -1)
    check_min_version "Docker" "$docker_version" "24.0.0"
elif check_command podman; then
    podman_version=$(podman --version | grep -oP '[0-9.]+')
    check_min_version "Podman" "$podman_version" "4.0.0"
fi

echo ""
echo "=== Ferramentas Auxiliares ==="
check_command make
check_command jq

echo ""
echo "🏁 Verificação Completa!"
echo ""
echo "Execute 'flutter doctor -v' para diagnóstico detalhado do Flutter"
echo ""
echo "Versões recomendadas (Nov 2025):"
echo "  - Flutter: 3.35+"
echo "  - Dart: 3.10+"
echo "  - Java: 25 (LTS)"
echo "  - Android SDK: API 35+ (obrigatório para Google Play)"
echo "  - Python: 3.14 ou 3.13"
echo "  - Node.js: 24 LTS"
echo "  - Go: 1.25"
echo "  - Rust: 1.91+"
```

**Uso**:

```bash
chmod +x check_environment.sh
./check_environment.sh
```

---

### 📋 Checklist de Instalação Mínima (Versões Atualizadas Nov 2025)

#### Para Build Linux + Android (Desenvolvimento Completo)

- [x] Git, curl, unzip, build-essential
- [x] **Flutter SDK 3.35+ / Dart 3.10+**
- [x] Clang 14+, CMake 3.22+, Ninja
- [x] GTK3 3.24+ development libraries
- [x] **Java 25 LTS** (ou mínimo Java 17)
- [x] Android SDK (API 35+, API 36 recomendado)
- [x] **Python 3.14 ou 3.13**
- [x] **Node.js 24 LTS** (ou mínimo Node 20 LTS)
- [x] **Go 1.25**
- [x] **Rust 1.91+**
- [x] LCOV, BC

#### Para Testes Apenas (CI Runner)

- [x] Flutter SDK 3.35+
- [x] Clang, CMake, GTK3 (build Linux)
- [x] LCOV, BC (coverage)
- [x] Bash, Python3.13+ (rodar plugins exemplo)

---

### ⚙️ Configuração Pós-Instalação

#### 1. Flutter Doctor

```bash
flutter doctor -v

# Saída esperada:
# [✓] Flutter (Channel stable, 3.35.2)
# [✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
# [✓] Linux toolchain - develop for Linux desktop
# [✓] Connected device (1 available)
# [✓] Network resources
```

#### 2. Variáveis de Ambiente Consolidadas

Adicionar ao `~/.bashrc` ou `~/.zshrc`:

```bash
# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# Android (API 35+ obrigatório para Google Play)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Java 25 LTS
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64

# Go 1.25
export PATH=$PATH:/usr/local/go/bin

# Rust (automaticamente adicionado por rustup)
source $HOME/.cargo/env

# Python 3.14 (se instalado via deadsnakes)
alias python3=python3.14

# Crossbar (após instalação)
export PATH=$PATH:$HOME/.local/bin
```

#### 3. Testes de Sanidade

```bash
# Build exemplo Flutter Desktop
cd /tmp
flutter create test_app
cd test_app
flutter build linux --release
./build/linux/x64/release/bundle/test_app
# Deve abrir janela com contador

# Build Android APK (target API 35)
flutter build apk --debug --target-platform android-arm64
# Deve gerar build/app/outputs/flutter-apk/app-debug.apk
```

---

### 💾 Espaço em Disco Necessário (Atualizado)

- Flutter SDK 3.35: ~2.5 GB
- Android SDK (API 35+36): ~6 GB
- Node.js 24 + NPM packages: ~600 MB
- Go 1.25: ~180 MB
- Rust 1.91: ~1.8 GB
- Python 3.14: ~150 MB
- Build artifacts (temporários): ~2.5 GB
- **Total recomendado**: 18 GB livres

---

### ⏱️ Tempo de Instalação Estimado

- Sistema base: 5 min
- Flutter SDK 3.35: 12 min (download + precache)
- Android SDK (API 35+36): 18 min (download + licenças)
- Java 25: 3 min
- Linguagens (Python 3.14/Node 24/Go 1.25/Rust 1.91): 25 min
- Configuração e testes: 12 min

**Total**: ~75 minutos (primeira vez)

---

**FIM DO ANEXO C - TOOLCHAINS LINUX (VERSÕES NOV 2025)**

Este setup atualizado garante:

- ✅ Compliance com Google Play (API 35+)[9][6]
- ✅ Versões LTS mais recentes (Java 25, Node 24)[7][13]
- ✅ Performance otimizada (Go 1.25, Python 3.14, Rust 1.91)[16][18][10]
- ✅ Features modernas (Dart 3.10, Flutter 3.35)[1][2]
- ✅ Suporte de longo prazo (todas versões com 3+ anos de patches)

[1](https://docs.flutter.dev/install/archive)
[2](https://dart.dev/resources/whats-new)
[3](https://docs.flutter.dev/release/whats-new)
[4](https://developer.android.com/tools/releases/platforms)
[5](https://developer.android.com/tools/releases/platform-tools)
[6](https://developer.android.com/google/play/requirements/target-sdk)
[7](https://openjdk.org/projects/jdk/25/)
[8](https://www.jrebel.com/blog/java-25)
[9](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
[10](https://realpython.com/python-news-november-2025/)
[11](https://endoflife.date/python)
[12](https://nodejs.org/pt/blog/release/v24.11.1)
[13](https://nodejs.org/pt/blog/release/v24.11.0)
[14](https://github.com/nodejs/node/releases)
[15](https://nodejs.org/en/blog/release/v20.19.6)
[16](https://www.developer-tech.com/news/go-language-1-25-improves-performance-and-developer-tools/)
[17](https://www.bytesizego.com/go-125)
[18](https://releases.rs)
[19](https://endoflife.date/rust)
[20](https://docs.flutter.dev/release/release-notes)
[21](https://docs.flutter.dev/install)
[22](https://liudonghua123.github.io/flutter_website/release/archive/)
[23](https://situm.com/docs/flutter-sdk-changelog/)
[24](https://developer.android.com/tools/releases/cmdline-tools)
[25](https://community.chocolatey.org/packages/dart-sdk)
[26](https://developer.android.com/tools)
[27](https://nodejs.org/en/about/previous-releases)
[28](https://nodejs.org/en/blog/release/v25.2.1)
[29](https://www.androidacy.com/google-play-api-level-requirement-2025/)
[30](https://orangeoma.zendesk.com/hc/en-us/articles/21001579350172-Google-Play-s-Target-API-level-requirements-for-2025)
