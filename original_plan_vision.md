# CROSSBAR - VISÃO E ARQUITETURA (Plan Docs Part 1/3)

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

**Flutter 3.35+**:

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

## 5. PORQUÊS ESSENCIAIS (DNA DO CROSSBAR)

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
