# Crossbar Technical Roadmap

Este documento é o **Manual de Execução Técnica** do Crossbar. Ele traduz a visão do `original_plan.md` em tarefas de engenharia atômicas, granulares e verificáveis.

**Status Atual:** v1.4.0 (Polimento e Expansão)
**Próximo Ciclo:** v1.5.0 (Advanced Desktop & Marketplace)

---

## 🔍 Auditoria do Estado Atual (v1.4.0)

Antes de avançar, reconhecemos o que existe e o que falta para atingir a promessa do "Write Once, Run Everywhere".

### ✅ O que está Sólido

- **Core Architecture:** `PluginManager` e `ScriptRunner` funcionam bem.
- **Refresh Engine:** `RefreshService` unificado gerencia atualizações periódicas, manuais e background de forma consistente.
- **CLI Foundation:** Estrutura de comandos e parser de argumentos robustos.
- **UI Desktop:** Janela principal e abas implementadas.
- **Tray Básico:** Ícone único e menu funcionam via `tray_manager`.
- **Configuration Engine:** Persistência, UI e injeção de variáveis implementados.
- **Mobile Widgets:** Integração nativa com Android (XML/Receiver) e iOS (WidgetKit/SwiftUI) via `home_widget`.

### 🚧 O que é "Fachada" (Precisa de Implementação)

- **Tray Avançado:** Modos "Smart Collapse" e "Overflow" são apenas enums sem lógica.
- **API Gaps:** Comandos como `--location` (geocoding) e `--qr` não têm lógica implementada.
- **Marketplace:** Ainda não integrado com a API do GitHub.

---

## 🎯 Epic v1.1.0: The Configuration Engine (Concluído)

**Objetivo:** Permitir que plugins declarem configurações (JSON), o usuário preencha (UI), e o sistema injete (ENV vars) com segurança.

### Fase 1: Persistência e Segurança

- [x] **Criar Service:** `lib/services/plugin_config_service.dart`.
  - [x] Implementar `loadValues(pluginId)` lendo de `~/.crossbar/configs/`.
  - [x] Implementar `saveValues(pluginId, map)` escrevendo JSON.
  - [x] Integrar `flutter_secure_storage` para detectar chaves definidas como `type: password` no schema e salvar separadamente.
- [x] **Vincular Plugin:** Em `lib/core/plugin_manager.dart`:
  - [x] No método `_createPluginFromFile`, verificar existência de `[plugin].config.json`.
  - [x] Parsear JSON para `PluginConfig` object.
  - [x] Adicionar campo `PluginConfig? config` ao model `Plugin`.
- [x] **Teste Unitário:** `test/unit/services/plugin_config_service_test.dart` cobrindo criptografia e I/O.

### Fase 2: Injeção de Variáveis

- [x] **Update Runner:** Em `lib/core/script_runner.dart`:
  - [x] Injetar `PluginConfigService` no construtor.
  - [x] No método `run`, chamar `loadValues`.
  - [x] Mesclar valores carregados ao mapa `environment` passado para `Process.start`.
- [x] **Teste Funcional:** Criar `test/functional/fixtures/env_dump.sh` e validar se variáveis salvas aparecem no STDOUT.

### Fase 3: Conexão UI

- [x] **Plugins Tab:** Em `lib/ui/tabs/plugins_tab.dart`:
  - [x] Adicionar botão "Configurar" (ícone engrenagem) se `plugin.config != null`.
  - [x] Carregar valores atuais antes de abrir o dialog.
  - [x] Chamar `saveValues` no callback `onSave` do `PluginConfigDialog`.

---

## 📱 Epic v1.2.0: Mobile Mastery (Widgets & Services) (Concluído)

**Objetivo:** Transformar o Crossbar em um cidadão de primeira classe no Android e iOS, usando o package `home_widget` corretamente.

### Fase 1: Android Native (XML & Receiver)

- [x] **Layouts:** Criar arquivos XML em `android/app/src/main/res/layout/`:
  - [x] `widget_layout_small.xml` (1x1: Ícone + Texto curto).
  - [x] `widget_layout_medium.xml` (2x1: Ícone + Texto + 1 Ação).
  - [x] `widget_layout_large.xml` (Lista/Grid para menu items).
- [x] **Kotlin Provider:** Criar `CrossbarWidgetProvider.kt` estendendo `HomeWidgetProvider`.
  - [x] Implementar lógica de atualização via `RemoteViews`.
  - [x] Mapear dados do JSON (salvo pelo Flutter) para os IDs do layout XML.
- [x] **Manifest:** Registrar o receiver e o provider no `AndroidManifest.xml`.

### Fase 2: iOS Native (WidgetKit)

- [x] **XCode Target:** Adicionar target "Widget Extension" ao projeto iOS.
- [x] **App Groups:** Configurar App Groups no XCode (Runner + Widget) para compartilhamento de dados `UserDefaults`.
- [x] **SwiftUI View:** Implementar `CrossbarWidget.swift`.
  - [x] Criar TimelineProvider que lê JSON do `UserDefaults` (via `home_widget`).
  - [x] Desenhar View adaptativa (family: .systemSmall, .systemMedium).

### Fase 3: Widget Service Logic

- [x] **Serialização:** Em `lib/services/widget_service.dart`:
  - [x] Implementar `updateWidget(pluginId, output)`.
  - [x] Serializar `PluginOutput` para formato plano (chave/valor) que o `home_widget` consome.
  - [x] Chamar `HomeWidget.updateWidget` com o nome correto do provider.
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