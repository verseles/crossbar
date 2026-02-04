# Crossbar Technical Roadmap

Este documento é o **Manual de Execução Técnica** do Crossbar. Ele traduz a visão do `original_plan.md` em tarefas de engenharia atômicas, granulares e verificáveis.

**Status Atual:** v1.9.0 (Plugin Display Titles)
**Próximo Ciclo:** v1.9.1 (Code Quality & Robustness)

---

## 🔍 Auditoria do Estado Atual (v1.4.0)

Antes de avançar, reconhecemos o que existe e o que falta para atingir a promessa do "Write Once, Run Everywhere".

### ✅ O que está Sólido

- **Core Architecture:** `PluginManager` e `ScriptRunner` funcionam bem.
- **Documentation:** `CODEBASE.md` provides a comprehensive architectural guide.
- **Refresh Engine:** `RefreshService` unificado gerencia atualizações periódicas, manuais e background de forma consistente.
- **CLI Foundation:** Estrutura de comandos e parser de argumentos robustos.
- **UI Desktop:** Janela principal e abas implementadas.
- **Tray:** Fixes for initialization race conditions and support for multi-icon SNI.
- **Configuration Engine:** Persistência, UI e injeção de variáveis implementados.
- **Mobile Widgets:** Integração nativa com Android (XML/Receiver) e iOS (WidgetKit/SwiftUI) via `home_widget`.
- **Mobile Stability:** Cache persistente do `crossbar.web` no mobile e proteção contra varreduras vazias de plugins.
- **Lua API:** Helpers `web/env/config/json` integrados nos plugins de exemplo.
- **Marketplace:** Sistema de busca e instalação via GitHub implementado (`MarketplaceService`).

### 🚧 O que é "Fachada" (Precisa de Implementação)

- **Tray Avançado:** Modos "Smart Collapse" e "Overflow" são apenas enums sem lógica.
- **API Gaps:** Comandos como `--location` (geocoding) e `--qr` não têm lógica implementada.

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

- [x] **GitHub API:** Em `lib/services/marketplace_service.dart`:
  - [x] Implementar busca real usando `api.github.com/repos/{owner}/{repo}/contents/plugins`.
  - [x] Implementar cache de resultados para evitar rate limiting.
- [x] **Instalação:** Melhorar `InstallCommand`:
  - [x] Clonar/Baixar plugin.
  - [x] Validar integridade do arquivo.
  - [x] Copiar para `~/.crossbar/plugins`.
  - [x] Executar `chmod +x` automaticamente.

---

## 🧩 Epic v1.8.1: Plugin Display Titles (Concluído)

**Objetivo:** Permitir título customizado por usuário com fallback automático para o nome padrão (UI e widgets).

- [x] Adicionar override de título salvo por usuário e propagar para UI/Widgets. (Commit hash: 969c394)

---

## 🔧 Epic v1.9.1: Code Quality & Robustness

**Objetivo:** Resolver dívidas técnicas identificadas no code review dos commits 32faafb..73d8515, focando em prevenção de memory leaks, robustez de recursos e cobertura de testes.

**Context:** Code review identificou áreas críticas que precisam de melhorias para garantir estabilidade em execuções longas e edge cases.

### Fase 1: Resource Management (Alta Prioridade)

- [ ] **LRU Cache para `_webCache`:** Em `packages/crossbar_core/lib/src/core/lua_runner.dart`:
  - [ ] Implementar limite de tamanho para `Map<String, dynamic> _webCache`
  - [ ] Adicionar estratégia LRU (Least Recently Used) ou limitar a 100 entradas
  - [ ] Adicionar métrica de hit/miss rate para monitoramento
  - [ ] Teste: Validar que cache não cresce indefinidamente após 500+ requests

- [ ] **Rotação de Logs Android:** Em `android/app/src/main/kotlin/com/verseles/crossbar/WidgetLogStore.kt`:
  - [ ] Implementar `MAX_LOG_ENTRIES = 500` com FIFO
  - [ ] Adicionar método `clear()` para limpeza manual
  - [ ] Expor contador de logs descartados na UI de debug
  - [ ] Teste: Verificar que logs não excedem limite após 1000+ entradas

- [ ] **Empty Discovery Guard Documentation:** Em `lib/core/plugin_manager.dart`:
  - [ ] Documentar lógica do `_emptyDiscoveryStreak >= 3` com comentário inline
  - [ ] Adicionar reset do contador quando plugins são encontrados novamente
  - [ ] Considerar tornar threshold configurável via `ConfigService`
  - [ ] Teste: Validar comportamento em cenário "diretório realmente vazio"

### Fase 2: Test Coverage Expansion (Média Prioridade)

- [ ] **Output Parser Edge Cases:** Em `test/unit/core/output_parser_test.dart`:
  - [ ] Adicionar teste: Strings com pipes escapados (`text | inner=pipe\|here`)
  - [ ] Adicionar teste: Atributos multi-valor com quotes (`bash="/bin/sh -c 'echo test'"`)
  - [ ] Adicionar teste: Atributos com espaços e caracteres especiais
  - [ ] Adicionar teste: Parsing de atributos vazios ou malformados
  - [ ] Target: Aumentar coverage de `output_parser.dart` para 99%+

- [ ] **Widget Tests para Plugins Tab:** Criar `test/widget/tabs/plugins_tab_test.dart`:
  - [ ] Testar filtro "Enabled only" com lista mista de plugins
  - [ ] Testar ordenação por nome, interval, status
  - [ ] Testar busca/search functionality
  - [ ] Testar ações de enable/disable via UI
  - [ ] Target: Aumentar coverage de `plugins_tab.dart` de 10% para 60%+

- [ ] **Integration Test: Web Cache Persistence:** Criar `test/integration/web_cache_persistence_test.dart`:
  - [ ] Validar que cache sobrevive a restart do app
  - [ ] Validar estratégia stale-while-revalidate em caso de erro de rede
  - [ ] Validar limpeza de cache obsoleto (>7 dias)

### Fase 3: Code Organization & Maintainability (Baixa Prioridade)

- [ ] **Mover `customTitleKey` para Core:** Em `packages/crossbar_core/lib/src/models/plugin_config.dart`:
  - [ ] Mover constante `customTitleKey` de `PluginConfigService` para `PluginConfig`
  - [ ] Adicionar documentação sobre convenção de chaves reservadas (prefixo `_crossbar_`)
  - [ ] Atualizar referências em `plugin_config_service.dart`

- [ ] **Avaliar Compressão de Cache:** Em `packages/crossbar_core/lib/src/core/lua_runner.dart`:
  - [ ] Medir tamanho médio de cache em disco após 1 semana de uso
  - [ ] Se > 10MB, implementar compressão gzip para arquivos `.json` do cache
  - [ ] Adicionar métrica de espaço em disco salvo na UI de debug

- [ ] **Refactor: Widget Log Storage Abstraction:** Em `lib/services/widget_log_store.dart`:
  - [ ] Criar interface `LogStore` com implementações `MemoryLogStore` e `FileLogStore`
  - [ ] Permitir switch entre in-memory (rápido) e persistente (diagnóstico)
  - [ ] Adicionar toggle na UI de Settings

### Success Metrics (Definition of Done)

- ✅ Zero memory leaks detectados em execução de 24h+ (Android Profiler)
- ✅ Coverage geral aumentado para 42%+ (atualmente 39.5%)
- ✅ Todos os testes de edge cases do `output_parser` passando
- ✅ Widget tests para `plugins_tab.dart` implementados
- ✅ Documentação inline adicionada para lógicas complexas

---

## 🧪 Estratégia de Qualidade

Para cada Epic, a seguinte "Definition of Done" deve ser respeitada:

1.  **Código:** Implementado seguindo `flutter_lints`.
2.  **Testes Unitários:** Classes de lógica (Services, ViewModels) com >90% coverage.
3.  **Testes de Integração:** Pelo menos 1 teste end-to-end para o fluxo crítico (ex: Salvar config -> Executar Plugin -> Verificar Output).
4.  **Multi-plataforma:** Verificar se a implementação não quebra o build em Linux/Android (CI matrix).

### Status Atual de Testes

**Coverage atual:** 39.3% (meta: 35%)

#### Arquivos com Boa Cobertura (>70%)

- [x] `output_parser.dart` - 97.5%
- [x] `refresh_service.dart` - 96.5%
- [x] `plugin_output.dart` - 96.6%
- [x] `cli_handler.dart` - 95.3%
- [x] `lua_runner.dart` - 90.1%
- [x] `plugin_config.dart` - 85.3%
- [x] `plugin_config_service.dart` - 87.5%
- [x] `script_runner.dart` - 80.3%
- [x] `plugin_manager.dart` - 77.2%
- [x] `scheduler_service.dart` - 75.0%
- [x] `declarative_runner.dart` - 71.0%
- [x] `logger_service.dart` - 70.1%

#### Arquivos que Precisam de Mais Testes (<50%)

- [ ] `plugins_tab.dart` - 10.0%
- [ ] `marketplace_service.dart` - 21.9%
- [ ] `android_native_bridge.dart` - 7.3%
- [ ] `utils_api.dart` - 2.7%
- [ ] Comandos CLI de hardware (audio, bluetooth, screen, etc.)

#### Próximas Melhorias de Testes

- [ ] Refatorar `scheduler_service_test.dart` para usar classe real
- [ ] Adicionar testes de widget/UI para `plugins_tab.dart` (ver Epic v1.9.1)
- [ ] Adicionar edge cases para `output_parser.dart` (ver Epic v1.9.1)
- [ ] Excluir arquivos `l10n/*` do cálculo de coverage (gerados automaticamente)

**Nota:** Melhorias detalhadas de testes estão documentadas no **Epic v1.9.1: Code Quality & Robustness**.
