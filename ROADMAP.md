# Crossbar Technical Roadmap

Este documento é o **Manual de Execução Técnica** do Crossbar. Ele traduz a visão do `original_plan.md` em tarefas de engenharia atômicas, granulares e verificáveis.

**Status Atual:** v1.0.0 (MVP lançado)
**Próximo Ciclo:** v1.1.0 (Configuration Engine)

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

### Fase 1: Persistência e Segurança

- [ ] **Criar Service:** `lib/services/plugin_config_service.dart`.
  - [ ] Implementar `loadValues(pluginId)` lendo de `~/.crossbar/configs/`.
  - [ ] Implementar `saveValues(pluginId, map)` escrevendo JSON.
  - [ ] Integrar `flutter_secure_storage` para detectar chaves definidas como `type: password` no schema e salvar separadamente.
- [ ] **Vincular Plugin:** Em `lib/core/plugin_manager.dart`:
  - [ ] No método `_createPluginFromFile`, verificar existência de `[plugin].config.json`.
  - [ ] Parsear JSON para `PluginConfig` object.
  - [ ] Adicionar campo `PluginConfig? config` ao model `Plugin`.
- [ ] **Teste Unitário:** `test/unit/services/plugin_config_service_test.dart` cobrindo criptografia e I/O.

### Fase 2: Injeção de Variáveis

- [ ] **Update Runner:** Em `lib/core/script_runner.dart`:
  - [ ] Injetar `PluginConfigService` no construtor.
  - [ ] No método `run`, chamar `loadValues`.
  - [ ] Mesclar valores carregados ao mapa `environment` passado para `Process.start`.
- [ ] **Teste Funcional:** Criar `test/functional/fixtures/env_dump.sh` e validar se variáveis salvas aparecem no STDOUT.

### Fase 3: Conexão UI

- [ ] **Plugins Tab:** Em `lib/ui/tabs/plugins_tab.dart`:
  - [ ] Adicionar botão "Configurar" (ícone engrenagem) se `plugin.config != null`.
  - [ ] Carregar valores atuais antes de abrir o dialog.
  - [ ] Chamar `saveValues` no callback `onSave` do `PluginConfigDialog`.

---

## 📱 Epic v1.2.0: Mobile Mastery (Widgets & Services)

**Objetivo:** Transformar o Crossbar em um cidadão de primeira classe no Android e iOS, usando o package `home_widget` corretamente.

### Fase 1: Android Native (XML & Receiver)

- [x] **Layouts:** Criar arquivos XML em `android/app/src/main/res/layout/`:
  - [x] `widget_layout_small.xml` (1x1: Ícone + Texto curto).
  - [x] `widget_layout_medium.xml` (2x1: Ícone + Texto + 1 Ação).
  - [x] `widget_layout_large.xml` (Lista/Grid para menu items).
- [x] **Kotlin Provider:** Criar `CrossbarWidgetProvider.kt` estendendo `HomeWidgetProvider`.
  - [x] Implementar lógica de atualização via `RemoteViews` e `RemoteViewsService` (ListView).
  - [x] Mapear dados do JSON (salvo pelo Flutter) para os IDs do layout XML.
- [x] **Manifest:** Registrar o receiver e o provider no `AndroidManifest.xml`.

### Fase 2: iOS Native (WidgetKit)

- [ ] **XCode Target:** Adicionar target "Widget Extension" ao projeto iOS.
- [ ] **App Groups:** Configurar App Groups no XCode (Runner + Widget) para compartilhamento de dados `UserDefaults`.
- [ ] **SwiftUI View:** Implementar `CrossbarWidget.swift`.
  - [ ] Criar TimelineProvider que lê JSON do `UserDefaults` (via `home_widget`).
  - [ ] Desenhar View adaptativa (family: .systemSmall, .systemMedium).

### Fase 3: Widget Service Logic

- [ ] **Serialização:** Em `lib/services/widget_service.dart`:
  - [ ] Implementar `updateWidget(pluginId, output)`.
  - [ ] Serializar `PluginOutput` para formato plano (chave/valor) que o `home_widget` consome.
  - [ ] Chamar `HomeWidget.updateWidget` com o nome correto do provider.
- [x] **Background Sync:** Implementado via WorkManager para atualização de widgets em background (Android).
  - Criado `lib/services/background_service.dart` com `callbackDispatcher`
  - Tarefa periódica de 15 minutos para atualizar widgets
  - Suporta plugins Lua, YAML e Dart (sem dependências externas)

---

## 🖥️ Epic v1.3.0: Advanced Desktop UI

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

## 🌐 Epic v1.4.0: API & Marketplace Completion

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
