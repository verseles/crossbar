# Crossbar Technical Roadmap

Este documento é o **Manual de Execução Técnica** do Crossbar. Ele traduz a visão do `original_plan.md` em tarefas de engenharia atômicas, granulares e verificáveis.

**Status Atual:** v1.3.0-dev (Universal Plugins 🚧)
**Próximo Ciclo:** v1.4.0 (Advanced Desktop UI)

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

### Fase 2: iOS Native (WidgetKit) 🚧

- [x] **SwiftUI View:** Implementar `CrossbarWidget.swift` (placeholder ready).
  - [x] Criar TimelineProvider que lê JSON do `UserDefaults` (via `home_widget`).
  - [x] Desenhar View adaptativa (family: .systemSmall, .systemMedium).
- [ ] **XCode Target:** Adicionar target "Widget Extension" ao projeto iOS (requer macOS).
- [ ] **App Groups:** Configurar App Groups no XCode (Runner + Widget) para compartilhamento de dados `UserDefaults`.
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

### Fase 3: EmbeddedApi (API Dart Nativa)

> **Objetivo:** Implementar comandos da CLI diretamente em Dart para mobile.

- [ ] **Criar:** `lib/core/api/embedded_api.dart`
  - [ ] `EmbeddedApi.cpu()` - Uso de CPU
  - [ ] `EmbeddedApi.memory()` - RAM livre/total
  - [ ] `EmbeddedApi.battery()` - Nível e status
  - [ ] `EmbeddedApi.web(url, headers)` - HTTP requests via Dio
  - [ ] `EmbeddedApi.time(format)` - Hora atual
  - [ ] `EmbeddedApi.uptime()` - Tempo desde boot
  - [ ] `EmbeddedApi.os()` - Info do sistema
- [ ] **Platform Channels:** Implementar para Android (Kotlin) e iOS (Swift) quando necessário
- [ ] **Fallback:** Desktop usa Process.run como backup

### Fase 4: DartRunner

> **Objetivo:** Executar plugins `.dart` via Isolate com acesso à EmbeddedApi.

- [ ] **Criar:** `lib/core/runners/dart_runner.dart`
- [ ] **Isolate:** Executar código Dart em isolate separado
- [ ] **API Access:** Expor `EmbeddedApi` para plugins
- [ ] **Sandbox:** Limitar acesso a filesystem/network
- [ ] **Testes:** Validar execução em Android/iOS

### Fase 5: DeclarativeRunner (Plugins YAML)

> **Objetivo:** Plugins sem código, apenas configuração.

- [ ] **Formato YAML:** Definir schema
  ```yaml
  name: Weather
  interval: 30m
  source:
    type: http # ou "system"
    url: "https://api..."
  output:
    icon: "🌡️"
    text: "${response.main.temp}°C"
  ```
- [ ] **Criar:** `lib/core/runners/declarative_runner.dart`
- [ ] **Providers System:**
  - [ ] `http` - Fetch de APIs
  - [ ] `system` - cpu, memory, battery, etc (via EmbeddedApi)
- [ ] **JSONPath:** Suporte a extração de dados `${response.data.value}`
- [ ] **Conditions:** Cores condicionais baseadas em valores
- [ ] **Versões YAML:** Criar para os 6 plugins exemplo

### Fase 6: TermuxRunner (Android - Opcional)

> **Objetivo:** Para usuários avançados que têm Termux instalado.

- [ ] **Intent:** Usar `com.termux.RUN_COMMAND` para executar scripts
- [ ] **Permissões:** Documentar setup necessário
- [ ] **Fallback:** Se Termux não disponível, guiar para DeclarativeRunner
- [ ] **Detecção:** Auto-detectar se Termux está instalado

### Fase 7: Plugin Executor Unificado

- [ ] **Interface:** `abstract class PluginRunner { canRun(); run(); }`
- [ ] **Implementações:**
  - [ ] `ScriptRunner` (desktop only - já existe)
  - [ ] `DartRunner` (todas plataformas)
  - [ ] `DeclarativeRunner` (todas plataformas)
  - [ ] `TermuxRunner` (Android com Termux)
- [ ] **Auto-seleção:** Escolher runner baseado em extensão + plataforma
- [ ] **Prioridade:** Declarative > Dart > Script > Termux

### Fase 8: UI de Samples Melhorada

- [ ] **Indicadores:** Mostrar quais linguagens estão disponíveis por plugin
- [ ] **Compatibilidade:** Indicar "✅ Funciona nesta plataforma"
- [ ] **Agrupamento:** Por funcionalidade (todos os "clock" juntos)
- [ ] **Seleção de Variante:** Usuário escolhe linguagem preferida

### Fase 9: Documentação

- [ ] **README:** Seção "Plugin Types" explicando runners
- [ ] **docs/plugin-runners.md:** Guia detalhado
- [ ] **docs/writing-portable-plugins.md:** Best practices
- [ ] **GUI Onboarding:** Wizard ao adicionar primeiro plugin

---

## �🖥️ Epic v1.4.0: Advanced Desktop UI

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
