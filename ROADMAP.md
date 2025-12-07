# Crossbar Technical Roadmap

Este documento é o **Manual de Execução Técnica** do Crossbar. Ele traduz a visão do `original_plan.md` em tarefas de engenharia atômicas, granulares e verificáveis.

**Status Atual:** v1.3.1 (UX Fixes & Plugin Management ✅)
**Próximo Ciclo:** v1.3.2 (Internationalization & Polish)

---

## 🔍 Auditoria do Estado Atual (v1.0.0)

Antes de avançar, reconhecemos o que existe e o que falta para atingir a promessa do "Write Once, Run Everywhere".

### ✅ O que está Sólido

- **Core Architecture:** `PluginManager` e `ScriptRunner` funcionam bem.
- **CLI Foundation:** Estrutura de comandos e parser de argumentos robustos.
- **UI Desktop:** Janela principal e abas implementadas.
- **Tray Básico:** Ícone único e menu funcionam via `tray_manager`.

### 🚧 O que é "Fachada" (Precisa de Implementação)

- **Configuração:** UI existe, mas não salva dados nem injeta no plugin.
- **Mobile Widgets:** `WidgetService` existe mas não comunica com layouts nativos (XML/SwiftUI).
- **Tray Avançado:** Modos "Smart Collapse" e "Overflow" são apenas enums sem lógica.
- **API Gaps:** Comandos como `--location` (geocoding) e `--qr` não têm lógica implementada.

---

## 🎯 Epic v1.1.0: The Configuration Engine

**Objetivo:** Permitir que plugins declarem configurações (JSON), o usuário preencha (UI), e o sistema injete (ENV vars) com segurança.

### Fase 1: Persistência e Segurança ✅

- [x] **Criar Service:** `lib/services/plugin_config_service.dart`.
  - [x] Implementar `loadValues(pluginId)` lendo de `~/.crossbar/configs/`.
  - [x] Implementar `saveValues(pluginId, map)` escrevendo JSON.
  - [x] Integrar `flutter_secure_storage` para detectar chaves definidas como `type: password` no schema e salvar separadamente.
- [x] **Vincular Plugin:** Em `lib/core/plugin_manager.dart`:
  - [x] No método `_createPluginFromFile`, verificar existência de `[plugin].config.json`.
  - [x] Parsear JSON para `PluginConfig` object.
  - [x] Adicionar campo `PluginConfig? config` ao model `Plugin`.
- [x] **Teste Unitário:** `test/unit/services/plugin_config_service_test.dart` cobrindo criptografia e I/O.

### Fase 2: Injeção de Variáveis ✅

- [x] **Update Runner:** Em `lib/core/script_runner.dart`:
  - [x] Injetar `PluginConfigService` no construtor.
  - [x] No método `run`, chamar `loadValues` via `_buildEnvironment`.
  - [x] Mesclar valores carregados ao mapa `environment` passado para `Process.start`.
  - [x] **Teste Funcional:** Criar `test/functional/fixtures/env_dump.sh` e validar se variáveis salvas aparecem no STDOUT.

### Fase 3: Conexão UI ✅

- [x] **Plugins Tab:** Em `lib/ui/tabs/plugins_tab.dart`:
  - [x] Adicionar botão "Configurar" (ícone engrenagem) se `plugin.config != null`.
  - [x] Carregar valores atuais antes de abrir o dialog.
  - [x] Chamar `saveValues` no callback `onSave` do `PluginConfigDialog`.

### Fase 4: Refinamentos e Limpeza ✅

- [x] **Consistência de Arquivos:** Renomear arquivos de definição de configuração de `.config.json` para `.schema.json` para evitar confusão com arquivos de valores salvos.

---

## 📱 Epic v1.2.0: Mobile Mastery (Widgets & Services)

**Objetivo:** Transformar o Crossbar em um cidadão de primeira classe no Android e iOS, usando o package `home_widget` corretamente.

### Fase 1: Android Native (XML & Receiver) ✅

- [x] **Layouts:** Criar arquivos XML em `android/app/src/main/res/layout/`:
  - [x] `crossbar_widget_small.xml` (1x1: Ícone + Texto curto).
  - [x] `crossbar_widget_medium.xml` (2x1: Ícone + Texto + 1 Ação).
  - [x] `crossbar_widget_large.xml` (Lista/Grid para menu items).
- [x] **Kotlin Provider:** Criar `CrossbarWidgetProvider.kt` estendendo `HomeWidgetProvider`.
  - [x] Implementar lógica de atualização via `RemoteViews`.
  - [x] Mapear dados do JSON (salvo pelo Flutter) para os IDs do layout XML.
- [x] **Manifest:** Registrar o receiver e o provider no `AndroidManifest.xml`.
- [x] **Recursos:** Criar arquivos de suporte:
  - [x] `crossbar_widget_info.xml` (configuração do widget).
  - [x] `widget_background.xml` e `widget_background_dark.xml` (drawables).
  - [x] `strings.xml` (labels e descrições).

### Fase 2: iOS Native (WidgetKit) ✅

- [x] **SwiftUI View:** Implementar `CrossbarWidget.swift` (functional).
  - [x] Criar TimelineProvider que lê JSON do `UserDefaults` (via `home_widget`).
  - [x] Desenhar View adaptativa (family: .systemSmall, .systemMedium).
- [x] **XCode Target:** Adicionar target "Widget Extension" ao projeto iOS (requer macOS).
- [x] **App Groups:** Configurar App Groups no XCode (Runner + Widget) para compartilhamento de dados `UserDefaults`.
- [x] **Documentação:** Criar guia de setup `docs/ios-widget-setup.md`.

### Fase 3: Widget Service Logic ✅

- [x] **Serialização:** Em `lib/services/widget_service.dart`:
  - [x] Implementar `updateWidget(pluginId, output)`.
  - [x] Serializar `PluginOutput` para formato plano (chave/valor) que o `home_widget` consome.
  - [x] Chamar `HomeWidget.updateWidget` com o nome correto do provider.
- [x] **SchedulerService Integration:** Chamar `updateWidget` após cada execução de plugin.
- [ ] **Background Sync:** Implementar Android Headless Task para updates em background (enhancement futuro).

---

## � Epic v1.3.0: Universal Plugins (Multi-Runner Architecture)

**Status: 🚧 EM PROGRESSO**

**Objetivo:** Permitir que plugins funcionem em TODAS as plataformas através de múltiplos runners e uso extensivo da API CLI do Crossbar.

### Fase 1: Reescrever Plugins Exemplo (API-First) ✅

> **Problema:** Plugins atuais usam `curl`, `top`, `/proc` diretamente, quebrando portabilidade.
> **Solução:** Reescrever para usar `crossbar --cpu`, `crossbar --web`, etc.

- [x] **Definir Catálogo:** 6 plugins × 6 linguagens = 36 arquivos
  - [x] clock (tempo) - 6 linguagens
  - [x] cpu (sistema) - 6 linguagens
  - [x] battery (sistema) - 6 linguagens
  - [x] memory (sistema) - 6 linguagens
  - [x] weather (API + config) - 6 linguagens + schema
  - [x] bitcoin (API) - 6 linguagens
- [x] **Reescrever Bash:** Usar `$(crossbar --cpu)` em vez de `top | grep`
- [x] **Reescrever Python:** Usar `subprocess.run(['crossbar', '--cpu'])`
- [x] **Reescrever Node:** Usar `execSync('crossbar --cpu')`
- [x] **Reescrever Dart:** Usar `Process.runSync('crossbar', ['--cpu'])`
- [x] **Reescrever Go:** Usar `exec.Command("crossbar", "--cpu")`
- [x] **Reescrever Rust:** Usar `Command::new("crossbar").arg("--cpu")`
- [x] **Estrutura de Pastas:** Reorganizar `plugins/` por funcionalidade

### Fase 2: Sistema de Tags/Categorias Unificado ✅

- [x] **Modelo:** Criar `PluginMetadata` com category, tags, language, type
- [x] **Reutilização:** Atualizar `SamplePluginsDialog` com filtros
  - [x] Filtro por categoria
  - [x] Filtro por linguagem
  - [x] Indicador de compatibilidade mobile
- [x] **Multi-linguagem:** Cada plugin pode ter múltiplas variantes de linguagem
- [x] **WebCommand:** Implementar `crossbar web` para HTTP requests (Dio-powered)

### Fase 3: CrossbarBridge (APIs Unificadas) ✅

> **Objetivo:** Criar uma ponte que expõe as APIs existentes para plugins Dart.

- [x] **Criar:** `lib/core/bridge/crossbar_bridge.dart`
  - [x] Wrapper unificado sobre `SystemApi`, `UtilsApi`, `NetworkApi`
  - [x] Expõe métodos: `cpu()`, `memory()`, `battery()`, `web()`, `time()`, `date()`, etc.
  - [x] Funciona em TODAS as plataformas (desktop + mobile)
  - [x] Global instance: `crossbar.cpu()`, `crossbar.web(url)`, etc.
- [x] **APIs implementadas:**
  - [x] System: `cpu()`, `memory()`, `battery()`, `uptime()`, `disk()`, `os()`, `osDetails()`
  - [x] Time: `time(format)`, `date(format)`
  - [x] Network: `web()`, `netStatus()`, `localIp()`, `publicIp()`, `wifiSsid()`, `ping()`
  - [x] Utils: `clipboard()`, `setClipboard()`, `exec()`, `notify()`, `openUrl()`, `openFile()`
  - [x] Environment: `env()`, `homeDir`, `tempDir`, `platform`, `isMobile`, `isDesktop`
  - [x] Encoding: `hash()`, `uuid()`, `base64Encode()`, `base64Decode()`, `random()`
- [x] **Testes:** 20 testes passando para todas as APIs

### Fase 4: DartRunner (Plugins Interpretados) ✅

> **Objetivo:** Executar plugins `.dart` simples via `dart_eval` em runtime.

**Quando usar:** Plugins simples que usam apenas a API do Crossbar.

```dart
// plugins/clock.1s.dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final crossbar = CrossbarBridge();
  final time = crossbar.time();
  print('⏰ $time');
}
```

- [x] **Dependência:** dart_eval ^0.8.2 adicionado ao pubspec.yaml
- [x] **Criar:** `lib/core/runners/dart_runner.dart`
- [x] **CrossbarPlugin:** Registra CrossbarBridge como binding para dart_eval
- [x] **Sandbox:** Plugins só acessam APIs via CrossbarBridge
- [x] **Zone-based output:** Captura print() statements via Zone
- [x] **Testes:** 10 testes passando (basic execution + bridge integration)

### Fase 5: crossbar_api Package (Plugins Compilados) ✅

> **Objetivo:** Package Dart para plugins avançados que precisam ser compilados.

**Quando usar:** Plugins que precisam de packages externos, FFI, ou performance máxima.

```dart
// plugins/advanced.1s.dart
import 'package:crossbar_api/crossbar_api.dart';
import 'package:html/parser.dart'; // Package externo ✅

void main() async {
  final html = await Crossbar.web('https://example.com');
  final doc = parse(html.text);
  print(doc.querySelector('title')?.text);
}

// Compilar: dart compile exe plugins/advanced.1s.dart -o plugins/advanced.1s.dart.exe
```

- [x] **Criar:** `packages/crossbar_api/` (package separado)
  - [x] `Crossbar.cpu()`, `memory()`, `battery()`, `uptime()`, `disk()`
  - [x] `Crossbar.time()`, `date()` com formatação
  - [x] `Crossbar.web()`, `netStatus()`, `localIp()`, `publicIp()`, `ping()`
  - [x] `Crossbar.exec()`, `notify()`, `clipboard()`, `openUrl()`
  - [x] `Crossbar.env()`, `homeDir`, `platform`, `isMobile`, `isDesktop`
  - [x] `Crossbar.hashMd5()`, `hashSha256()`, `uuid()`, `base64*()`
- [x] **Models:** `MemoryInfo`, `BatteryInfo`, `WebResponse`
- [x] **Docs:** README.md com API completa
- [x] **Example:** `example/cpu_monitor.dart`

### Arquitetura de Plugins Dart (Resumo)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PLUGINS DART                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────┐    ┌──────────────────────────────────┐  │
│  │   Modo Interpretado      │    │      Modo Compilado              │  │
│  │   (DartRunner)           │    │      (crossbar_api)              │  │
│  ├──────────────────────────┤    ├──────────────────────────────────┤  │
│  │ • Sem imports externos   │    │ • Pode usar qualquer package     │  │
│  │ • Usa objeto `crossbar`  │    │ • import 'package:crossbar_api/' │  │
│  │ • Executa em runtime     │    │ • Compilado para binário         │  │
│  │ • Mobile-friendly ✅     │    │ • Desktop only                   │  │
│  │ • Sandboxed              │    │ • Performance máxima             │  │
│  │                          │    │ • IntelliSense/Autocomplete ✅   │  │
│  │ Extensão: .dart          │    │ Extensão: .dart.exe / .dart.bin  │  │
│  └──────────────────────────┘    └──────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Fase 6: DeclarativeRunner (Plugins YAML) ✅

> **Objetivo:** Plugins sem código, apenas configuração. Ultra-portátil.

```yaml
# plugins/weather.30m.yaml
name: Weather
interval: 30m
requires:
  - WEATHER_API_KEY

source:
  type: http
  url: "https://api.openweathermap.org/data/2.5/weather?q=London&appid=${WEATHER_API_KEY}"

output:
  icon: "🌡️"
  text: "${response.main.temp}°C"
  tooltip: "${response.weather[0].description}"

menu:
  - title: "Humidity: ${response.main.humidity}%"
  - title: "Wind: ${response.wind.speed} m/s"
  - separator
  - title: "Refresh"
    action: refresh
```

- [x] **Criar:** `lib/core/runners/declarative_runner.dart`
- [x] **Providers:**
  - [x] `http` - Fetch de APIs (via CrossbarBridge.web)
  - [x] `system` - cpu, memory, battery, time, date, uptime, network
  - [x] `exec` - Executar comandos shell
  - [x] `static` - Dados estáticos no próprio YAML
- [x] **Template Engine:** Interpolação `${response.path.to.value}`
- [x] **Menu Support:** Items com título, action, separadores
- [x] **Environment Variables:** Interpolação `${VAR_NAME}` no URL/templates
- [x] **Plugins Exemplo:** 6 plugins YAML em `plugins/yaml/`
  - clock.1s.yaml, cpu.5s.yaml, memory.10s.yaml
  - battery.1m.yaml, bitcoin.5m.yaml, network.30s.yaml
- [x] **Testes:** 14 testes passando

### Fase 7: Plugin Executor Unificado ✅

- [x] **Criar:** `lib/core/plugin_executor.dart`
- [x] **RunnerType enum:** declarative, dart, script, unknown
- [x] **Auto-detecção:** Baseado em extensão do arquivo
  - `.yaml`, `.yml` → DeclarativeRunner
  - `.dart` → DartRunner
  - `.sh`, `.py`, `.js`, `.go`, `.rs` → ScriptRunner
  - `.dart.exe` → ScriptRunner (compiled)
- [x] **Platform Check:** `canRunOnPlatform()` para mobile compatibility
- [x] **Integração:** PluginManager agora usa PluginExecutor
- [x] **Extensões:** `.yaml` e `.yml` adicionados a allowedExtensions
- [x] **Testes:** 13 testes unitários passando
- [x] **Build:** 337 testes totais passando

### Fase 8: Documentação Completa ✅

- [x] **README.md:** Seção "Plugin Types" com tabela comparativa e links
- [x] **docs/plugin-types.md:** Comparativo detalhado de todos os tipos
- [x] **docs/dart-plugins.md:** Guia completo (interpretado + compilado)
- [x] **docs/yaml-plugins.md:** Guia de plugins declarativos
- [x] **docs/writing-portable-plugins.md:** Best practices cross-platform
- [x] **packages/crossbar_api/README.md:** Documentação da API

---

## 🔧 Epic v1.3.1: UX Fixes & Plugin Management

**Status: ✅ CONCLUÍDO**

**Objetivo:** Corrigir bugs, melhorar UX de gerenciamento de plugins e polir a experiência do usuário.

### Fase 1: Bug Fixes ✅

- [x] **CPU output unificado:** `crossbar cpu` retorna apenas número (ex: "15.3"), plugins adicionam %
- [x] **Ícone da janela Linux:** Carregamento via paths relativos ao executável
- [x] **Tray tooltip:** Adicionado tooltip e title "Crossbar" inicial
- [x] **Test fix:** Atualizado regex do teste de CPU para aceitar número sem %

### Fase 2: Plugin Management UX ✅

- [x] **Double-click to delete:** Removido dialog de confirmação, requer dois cliques em 3s
- [x] **Edit button:** Abre o plugin no editor padrão do sistema
- [x] **Copy Live Output:** Botão para copiar saída do plugin
- [x] **Copy Last Error:** Botão para copiar mensagem de erro
- [x] **Refresh automático:** Lista e tray atualizam após fechar Sample Plugins dialog

### Fase 3: Sample Plugins Dialog ✅

- [x] **Grid layout:** Telas > 700px usam grid (2 colunas), > 1000px (3 colunas)
- [x] **Height reduzida:** Aumentado childAspectRatio para cards mais compactos
- [x] **Multiple variants:** Permite instalar mesmo plugin em múltiplas linguagens
- [x] **Language indicator:** Dropdown mostra checkmark em linguagens já instaladas

### Fase 4: Android & Linux ✅

- [x] **Android notifications:** Adicionado request de permissão para Android 13+
- [x] **Foreground service:** Adicionadas permissões no AndroidManifest
- [x] **Linux .desktop:** Criado arquivo crossbar.desktop com StartupWMClass
- [x] **WM_CLASS:** Adicionado gtk_window_set_wmclass() no código GTK
- [x] **make install:** Comando para instalar no ~/.local/ com ícones e .desktop

---

## 🌍 Epic v1.3.2: Internationalization & Polish

**Status: 🚧 EM PROGRESSO**

**Objetivo:** Internacionalizar a aplicação e finalizar integração desktop.

### Fase 1: i18n Strings ✅

- [x] **Identificar:** Mapear todas as strings hardcoded em lib/ui/
  - [x] `plugins_tab.dart` - "Sample Plugins", "plugin(s) installed", etc.
  - [x] `sample_plugins_dialog.dart` - títulos e labels
  - [x] `settings_tab.dart` - labels de configuração
  - [x] `plugin_config_dialog.dart` - campos e botões
  - [x] `plugin_card.dart` - status e ações
- [x] **Adicionar ao arb:** Criar ~73 novas chaves em `app_en.arb`
- [x] **Traduzir:** Atualizar os 12 arquivos de idiomas (ar, bn, de, es, fr, hi, it, ja, ko, pt, ru, zh)
- [x] **Substituir:** Trocar strings por `l10n.keyName` em todo o código

### Fase 2: Linux Desktop Integration ✅

- [x] **Testar install:** Verificar se `make install` funciona corretamente
- [x] **Ícone taskbar:** Confirmar que WM_CLASS funciona com diferentes DEs (GNOME, KDE, etc.)
- [x] **Auto-start:** Adicionar opção de criar autostart entry (~/.config/autostart/crossbar.desktop)

### Fase 3: Android Polish

- [ ] **Testar notification:** Verificar que persistent notification aparece após build
- [ ] **Widget styling:** Melhorar visual dos widgets Android

---

## 🖥️ Epic v1.4.0: Advanced Desktop UI

**Objetivo:** Polimento da experiência desktop e gerenciamento avançado de ícones de bandeja.

### Fase 1: Global Hotkey

- [ ] **Dependência:** Adicionar `hotkey_manager` ao `pubspec.yaml`.
- [ ] **Implementação:** Em `lib/services/window_service.dart`:
  - [ ] Registrar `Ctrl+Alt+C` (ou `Cmd+Alt+C` no macOS).
  - [ ] Handler deve fazer toggle de `show()` / `hide()`.
- [ ] **Settings:** Adicionar opção na aba Settings para customizar/desativar o atalho.

### Fase 2: Tray Overflow Logic

- [ ] **Lógica:** Em `lib/services/tray_service.dart`:
  - [ ] Implementar lógica para `TrayDisplayMode.smartOverflow`.
  - [ ] Se `plugins.length > threshold`, renderizar apenas 1 ícone genérico na tray.
  - [ ] Renderizar o menu de contexto contendo submenus para cada plugin ativo.
- [ ] **Menu Builder:** Refatorar a construção do menu para suportar aninhamento dinâmico (Plugin A -> [Output, Actions]).

### Fase 3: Window State Persistence

- [ ] **Persistência:** Em `lib/services/window_service.dart`:
  - [ ] Salvar `Rect` (posição e tamanho) no `shared_preferences` ao fechar/ocultar.
  - [ ] Restaurar `Rect` ao iniciar o app (evitar que abra sempre no centro ou tamanho default).

---

## 🌐 Epic v1.5.0: API & Marketplace Completion

**Objetivo:** Preencher as lacunas nos comandos CLI e tornar o Marketplace funcional.

### Fase 1: CLI Gaps

- [ ] **Geolocation:** Implementar `lib/cli/commands/location_command.dart`.
  - [ ] Usar `geolocator` (se permissão concedida) ou API IP-based (ipapi.co) como fallback.
  - [ ] Implementar geocoding reverso (lat/long -> Cidade).
- [ ] **QR Code:** Implementar `lib/cli/commands/utility_commands.dart` (subcomando `qr`).
  - [ ] Gerar QR code em ASCII para terminal.
  - [ ] Gerar PNG base64 se flag `--image` for passada.
- [ ] **Screenshot:** Finalizar implementação multiplataforma em `lib/core/api/utils_api.dart`.
  - [ ] Linux: `gnome-screenshot` ou `scrot` ou `import` (ImageMagick).
  - [ ] Windows: PowerShell snippet para captura.
  - [ ] macOS: `screencapture`.

### Fase 2: Marketplace Engine

- [ ] **GitHub API:** Em `lib/services/marketplace_service.dart`:
  - [ ] Implementar busca real usando `api.github.com/search/code?q=crossbar+extension:sh`.
  - [ ] Implementar cache de resultados para evitar rate limiting.
- [ ] **Instalação:** Melhorar `InstallCommand`:
  - [ ] Clonar repositório temporariamente.
  - [ ] Validar integridade do arquivo.
  - [ ] Copiar para `~/.crossbar/plugins`.
  - [ ] Executar `chmod +x` automaticamente.

---

## 🧪 Estratégia de Qualidade

Para cada Epic, a seguinte "Definition of Done" deve ser respeitada:

1.  **Código:** Implementado seguindo `flutter_lints`.
2.  **Testes Unitários:** Classes de lógica (Services, ViewModels) com >90% coverage.
3.  **Testes de Integração:** Pelo menos 1 teste end-to-end para o fluxo crítico (ex: Salvar config -> Executar Plugin -> Verificar Output).
4.  **Multi-plataforma:** Verificar se a implementação não quebra o build em Linux/Android (CI matrix).
