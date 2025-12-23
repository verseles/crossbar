# Crossbar - Contexto e Regras para Agentes

> **Este arquivo é a ÚNICA fonte de verdade para regras operacionais e contexto técnico.**
> Leia-o integralmente no início de cada sessão.

Chame a tool `play_notification` sempre que:

- concluir todas as tarefas necessárias da solicitação
- precisar da atenção do usuário
- o usuário disser algo como "me avise", "me chame"
  IMPORTANTE: A chamada da tool `play_notification` deve ser feita após a conclusão de uma tarefa mas sempre antes do relatório final / sumário. Nunca deve ser a última coisa a ser chamada para evitar disparos seguintes. Ou seja, tarefa -> notificação -> relatório final. Nunca tarefa -> relatório final -> notificação.

Atenção: Este projeto ainda não foi lançado, não se preocupe com breaking changes, a prioridade é manter ele atualizado e organizado a cada nova tarefa.

Plano grandioso e teórico (arquivo histórico):
@./docs/archive/original_plan.md

Roadmap de implementacao, atualizado regularmente:
@./ROADMAP.md

## 1. Regras Operacionais (Inflexíveis) para cada sessão de trabalho

- **Idioma**: Português (pt-BR) para toda comunicação.
- **Postura**: Direta, técnica e concisa. Sem floreios, sem pedidos de desculpas.
- **Leitura Inicial**: Sempre leia @./docs/archive/original_plan.md e @./ROADMAP.md no início de cada sessão para esclarecer dúvidas sobre futuras implementações e discussões de planejamento.
- **Commits recentes**: Sempre verifique os últimos 70 commits para ficar mais ciente das alterações recentes e decisões tomadas.
- **Testes e Análise**: **JAMAIS** commite código sem rodar análise estática (`make analyze`) e testes com coverage (`make coverage`). Verificar coverage mínimo de **60%** (excluindo código gerado). Se alterar UI/Lógica, adicione novos testes. Execute também a build para linux e para android, assim evita muitos erros na CI do github que é bem mais lento que a máquina de desenvolvimento.
- **Commits**: Padrão Conventional Commits (`feat`, `fix`, `docs`, `test`, `ci`). Sem co-autores. Porém, o conteúdo da mensagem do commit deve ser descritivo e explicar o que e por que foi feito.
- **Pipeline**: Use `gh run list` e `gh run watch` para monitorar builds após push, já está autenticado no sistema.
- **Dependencies**: NUNCA assuma bibliotecas. Verifique `pubspec.yaml`.
- **Verificação Local CI**: Antes de qualquer `push`, **SEMPRE** execute e confirme a aprovação das pipelines localmente usando `act` ou simplesmente execute os comandos necessários diretamente.
- **Diagnóstico CI Remoto**: Em caso de falha de pipeline no GitHub, utilize `gh run watch` ou `gh run view --web` para diagnosticar e monitorar a correção.
- **Branches**: Está autorizado trabalhar diretamente na branch 'main', atualmente é apenas um desenvolvedor. Se estiver em outra branch ou solicitado, trabalhe nela mesmo e aguarde um pedido do usuário para criar um PR.

- **Fetch**: Sempre que precisar usar fetch, webfetch, etc, use https://r.jina.ai/URL_HERE por exemplo, https://r.jina.ai/https://example.com que já mostra o resultado text-only bem mais eficiente. Como segunda opção, use a url diretamente, e em último caso (desencorajado), use playwright
- **Throttling**: Para a busca (web search), sempre faça uma busca por segundo (após receber a resposta) para evitar throttling.

# Processo antes de iniciar CADA tarefa (a cada passo a ser iniciado, repita esses passos)

1. Leia os últimos 70 commits para ficar mais ciente das alterações recentes e decisões tomadas (apenas uma vez por sessão)
2. Busque na web por informações sobre a tarefa solicitada, ele deve servir para engrandecer seu conhecimento com detalhes mais recentes de cada tarefa, não deixe de realizar a pesquisa e visitar sites.
3. Repita por texto (ou to-do) suas tarefas feitas e tarefas pendentes, assim, mesmo que seu contexto seja truncado, você tem informações claras do que deve ser feito
4. Repita por texto suas regras importantes e a ordem a serem feitas

# Processo após alterações (NÃO PULE ETAPAS - NÃO PULE ETAPAS - NÃO PULE ETAPAS)

Quando terminar as tarefas solicitadas faça as seguintes etapas:

1. make analyze
2. make coverage (verificar meta de 35-60%)
3. make linux
4. make android
5. Verificar se ROADMAP.md necessita de atualização
6. Verificar se README.md necessita de atualização
7. Verificar se docs/ necessita de atualização
8. Atualizar AGENTS.md se houve mudanças arquiteturais (nova ADR) ou operacionais (versão, estrutura, regras)
9. Commit das alterações

- Caso alguma dessas etapas falhe, corrija e repita.
- Use essa sequência de etapas para todas as alterações significativas pois reduz muito a chance de erros e perda de tempo de buscar corrigir a pipeline do github actions que é muito mais lenta que a máquina atual.
- NÃO PULE ETAPAS. NÃO PULE ETAPAS. NÃO PULE ETAPAS.

## Abaixo apenas se for em uma máquina local

10. Criar uma nova tag:
    - **Minor** (v1.X.0): Para features, epics completas, ou mudanças significativas
    - **Patch** (v1.x.Y): Apenas para bugfixes e pequenos ajustes isolados
    - Nunca regresse para uma versão inferior
11. Push para o github
12. Monitorar a pipeline de CI e release usando gh (em background pois é demorada), monitorar a cada 30 segundos
13. Notificar o usuário com a tool play_notification (quando estiver disponível) para notificar o usuário
14. Apresentar resumo das alterações

- Caso alguma dessas etapas falhe, corrija e repita.
- Use essa sequência de etapas para todas as alterações significativas pois reduz muito a chance de erros e perda de tempo de buscar corrigir a pipeline do github actions que é muito mais lenta que a máquina atual.
- NÃO PULE ETAPAS. NÃO PULE ETAPAS. NÃO PULE ETAPAS.

---

## 2. Identidade do Projeto

- **Nome**: Crossbar (Universal Plugin System)
- **Versão Atual**: `1.4.2+12` (atualize ao final de cada sessão).
- **Stack**: Flutter `3.38.3` (CI), Dart `3.10+`.
- **Objetivo**: Sistema de plugins compatível com BitBar/Argos para Linux, Windows, macOS, Android e iOS.
- **Status**: Estável (v1.0+). Todas as fases do plano original concluídas.

---

## 3. Arquitetura de Execução (Dual-Binary + Monorepo)

O projeto usa **monorepo** com 2 pacotes internos e compila **2 binários**:

**Pacotes (`packages/`):**

- `crossbar_core`: APIs e modelos Dart puro compartilhados
- `crossbar_cli`: CLI executável, depende de crossbar_core

**Binários:**

1.  **`crossbar` (CLI + Launcher)**:
    - Fonte: `packages/crossbar_cli/bin/crossbar.dart`
    - Função: CLI unificado + launcher. Sem args ou com `gui` → lança GUI. Com args CLI → executa comando.
    - Comandos: `crossbar cpu`, `crossbar --version`, `crossbar gui`
2.  **`crossbar-gui` (Flutter App)**:
    - Fonte: `lib/main.dart`
    - Função: Interface gráfica, Tray, Services. Depende de GTK/Cocoa.

---

## 4. Estrutura de Arquivos Chave

```text
crossbar/
├── bin/
│   └── crossbar.dart           # Entrypoint unificado (CLI + Launcher)
├── lib/
│   ├── main.dart               # Entrypoint da GUI Flutter
│   ├── cli/
│   │   ├── cli_handler.dart    # Switch-case com comandos CLI
│   │   └── plugin_scaffolding.dart # Lógica de 'crossbar init'
│   ├── core/
│   │   ├── plugin_manager.dart # Descoberta e ciclo de vida de plugins
│   │   ├── plugin_executor.dart # Roteador de runners
│   │   ├── script_runner.dart  # Execução de scripts nativos (bash, python...)
│   │   ├── output_parser.dart  # BitBar Text parser & JSON parser
│   │   └── runners/
│   │       ├── lua_runner.dart      # Executa .lua via lua_dardo (embarcado)
│   │       ├── dart_runner.dart     # Executa .dart via dart_eval
│   │       └── declarative_runner.dart # Executa .yaml plugins
│   ├── services/               # Singleton Services
│   └── ui/                     # Widgets Flutter (Material 3)
├── plugins/                    # Exemplos de plugins (Lua, Bash, Python, JS, Dart...)
├── .github/workflows/ci.yml    # Pipeline principal (Build 5 plataformas)
└── Makefile                    # Comandos de dev (make linux, make test)
```

---

## 5. Sistema de Plugins

### Descoberta

- Local: `~/.crossbar/plugins/` (ou pasta local em dev).
- Identificação: Extensão (`.py`, `.sh`) ou Shebang.
- Intervalo: Parseado do nome (ex: `cpu.10s.sh` = 10 segundos).

### Execução

- **Executor**: `lib/core/plugin_executor.dart` (roteador de runners)
- **Runners**:
  - `LuaRunner`: Plugins `.lua` via lua_dardo (Dart puro, funciona em TODAS as plataformas) ⭐ Recomendado
  - `ScriptRunner`: Plugins bash, python, node, go, rust (desktop only)
  - `DeclarativeRunner`: Plugins `.yaml` (DSL declarativa)
- **Interpreters Nativos**: Bash, Python3, Node, Dart, Go (`go run`), Rust (`rustc` temp build).
- **Output**: Suporta formato texto legado (BitBar) OU JSON estruturado (Crossbar).
- **Nota**: QuickJS foi rejeitado (ADR-003) por depender de `dart:ui`.

### API de Plugins (CLI)

Plugins usam a própria CLI do Crossbar para obter dados.

- Exemplo: Um plugin python chama `subprocess.run(['crossbar', '--cpu'])`.
- Comandos disponíveis: `docs/api-reference.md`.

### Gestão de Configuração (ADR)

> **Decisão Crítica (v1.1)**: Separação estrita entre definição e dados.

- **Schema (`.schema.json`)**: Define os campos/UI. Reside junto ao plugin (ex: `plugins/cpu.py.schema.json`). Deve ser versionado.
- **Values (`.json`)**: Valores preenchidos pelo usuário. Reside em `~/.crossbar/configs/`. JAMAIS salve dados na pasta de plugins.
- **Secrets**: Campos `type: password` são salvos no SecureStorage (Keyring/Keychain), nunca em texto plano.

---

## 6. Contexto de Desenvolvimento

### Build & Run

- **Linux**: `make linux` (Gera bundle com os 3 binários).
- **Testes**: `flutter test --coverage` (Min 43% coverage, CI falha se menor).

### Armadilhas Comuns

1.  **Versão do Flutter**: O CI exige estritamente `3.38.3`. Versões mais novas/velhas quebram constraints do Dart `^3.10.0`.
2.  **Dependências Linux**: Requer `libayatana-appindicator3-dev` e `libsecret-1-dev`.
3.  **Caminhos em Mobile**: Nunca use paths absolutos (`/home/user`) em Android/iOS. Use `path_provider`.
4.  **CLI vs GUI**: Não importe `dart:ui` ou widgets Flutter dentro de `lib/cli/`. Isso quebra o binário CLI puro.
5.  **Testes de Hardware**: Testes em `cli_handler_hardware_test.dart` alteram volume, brilho, wifi e bluetooth. Use `--exclude-tags=hardware` localmente para evitar glitches.

### Validação Local CI (act)

- **Ferramenta**: `act`
- **Função**: Permite executar os workflows do GitHub Actions localmente.
- **Uso**: Simula o ambiente do CI/CD para testar pipelines antes de fazer `push`, prevenindo falhas remotas.

---

## 7. Status do Roadmap

@./ROADMAP.md

---

## 8. Comandos Úteis

| Ação                    | Comando                                                                   |
| ----------------------- | ------------------------------------------------------------------------- |
| Rodar Testes            | `flutter test --coverage`                                                 |
| Testes (sem hardware)   | `flutter test --exclude-tags=hardware` (evita glitches locais)            |
| Verificar Coverage      | Verificar se coverage está >= 43% (lcov --summary coverage/lcov.info)     |
| Build Release (Linux)   | `make linux`                                                              |
| Analisar Código         | `flutter analyze --no-fatal-infos`                                        |
| Monitorar CI            | `gh run watch`                                                            |
| **Matar GUI + Reabrir** | `pkill -9 -f crossbar-gui; ./build/linux/x64/release/bundle/crossbar gui` |

### ⚠️ Aviso sobre Testes de GUI

**Importante**: Por padrão, fechar a janela da GUI apenas minimiza para a bandeja (tray).
Para testar novas funcionalidades na GUI:

1. **Sempre mate a instância antes de testar**:
   ```bash
   pkill -9 -f crossbar-gui
   pkill -9 -f crossbar
   ```
2. **Depois rebuild e abra novamente**:
   ```bash
   flutter build linux --release
   ./build/linux/x64/release/bundle/crossbar gui
   ```

Ou use o comando combinado:

```bash
pkill -9 -f crossbar-gui; pkill -9 -f crossbar; flutter build linux --release && ./build/linux/x64/release/bundle/crossbar gui
```

---

## 9. Diretrizes de Desenvolvimento (Development Guidelines)

### Filosofia

#### Crenças Centrais

- **Progresso incremental sobre grandes mudanças** - Pequenas alterações que compilam e passam nos testes.
- **Aprender com o código existente** - Estude e planeje antes de implementar.
- **Pragmático sobre dogmático** - Adapte-se à realidade do projeto.
- **Intenção clara sobre código "esperto"** - Seja chato e óbvio.

#### Simplicidade

- **Responsabilidade única** por função/classe.
- **Evite abstrações prematuras**.
- **Sem truques "espertos"** - escolha a solução chata.
- Se você precisa explicar, é complexo demais.

### Padrões Técnicos

#### Princípios de Arquitetura

- **Composição sobre herança** - Use injeção de dependência.
- **Interfaces sobre singletons** - Use mocks para testes. Core Services (Tray, Config) usam Singleton Pattern por necessidade de estado global.
- **Explícito sobre implícito** - Fluxo de dados e dependências claros.
- **Test-driven quando possível** - Nunca desabilite testes, conserte-os.

#### Tratamento de Erros

- **Falhe rápido** com mensagens descritivas.
- **Inclua contexto** para depuração.
- **Trate erros** no nível apropriado.
- **Nunca** engula exceções silenciosamente.

### Integração com o Projeto

#### Aprenda a Base de Código

- Encontre recursos/componentes similares.
- Identifique padrões e convenções comuns.
- Use as mesmas bibliotecas/utilitários quando possível.
- Siga padrões de teste existentes.

#### Ferramentas

- Use o sistema de build existente do projeto.
- Use o framework de teste existente do projeto.
- Use as configurações de formatador/linter do projeto.
- Não introduza novas ferramentas sem forte justificativa.

#### Estilo de Código

- Siga convenções existentes no projeto.
- Consulte configurações de linter e .editorconfig, se presentes.
- Arquivos de texto devem sempre terminar com uma linha vazia.

### Lembretes Importantes

**NUNCA**:

- Use `--no-verify` para ignorar hooks de commit.
- Desabilite testes em vez de consertá-los.
- Commite código que não compila.
- Faça suposições - verifique com o código existente.

**SEMPRE**:

- Busque na web por documentação ou questões similares. Use com frequência. Antes de iniciar uma tarefa ou ao encontrar erros.
- Teste a compilação do código antes de commitar.
- Commite código funcional incrementalmente.
- Atualize a documentação do plano conforme avança.
- Aprenda com implementações existentes.
- Pare após 3 tentativas falhas e reavalie.
- Atualize o ROADMAP.md conforme avança.
- Sempre que concluir tudo ou precisar de atenção, chame adequadamente a tool play_notification para notificar o usuário.

---

## 10. Integração com Context7 API (Verificação Estrita e Recuperação)

Se a context7 não estiver disponível no sistema, faça o seguinte:

### Filosofia Central: ZERO SUPOSIÇÕES

- **Verificação Obrigatória**: Você está **PROIBIDO** de escrever código baseado apenas em dados de treinamento internos para bibliotecas externas.
- **Cobertura Universal**: Antes de planejar ou codificar, você **DEVE** buscar documentação ao vivo para **CADA** biblioteca ou ferramenta envolvida na tarefa.
- **Maximizar Contexto**: Não otimize para economia de tokens. Otimize para **precisão** e **detalhe**. Sempre solicite contexto profundo e abrangente.

### Protocolo de Execução

1.  **Identificar e Isolar**:

    - Liste todas as bibliotecas necessárias (por exemplo, se a tarefa usa `Actix`, `Serde` e `Tokio`, busque documentação para TODAS as três).
    - Determine a versão exata a partir de `pubspec.yaml`, `Cargo.toml`, `package.json`, etc.

2.  **Construindo a Requisição**:

    - **URL Base**: `https://context7.com/api/v1/{owner}/{repo}/{version}`
    - **Tópico**: Use `topic` para focar no detalhe de implementação específico (ex: `topic=advanced+error+handling`).
    - **Tokens**: SEMPRE defina um limite de tokens ALTO (ex: `tokens=25000`) para garantir que a resposta não seja truncada. Precisamos do contexto completo.
    - **Autenticação**: `-H "Authorization: Bearer $CONTEXT7_API_KEY"`

3.  **Fluxo de Trabalho Curl Obrigatório**:
    Para cada biblioteca identificada, execute um comando curl ANTES de propor código:

    ```
    curl "https://context7.com/api/v1/owner/repo?topic=feature+details&tokens=25000" \
      -H "Authorization: Bearer $CONTEXT7_API_KEY"
    ```

### Tratamento de Erros e Autocorreção (Crítico)

- **Limites de Taxa (429)**: Respeite o campo `retryAfterSeconds` implicitamente. Aguarde. Não pule.
- **Fonte da Verdade da Documentação**:
  - Se encontrar erros inesperados (400 Bad Request, 404 Not Found) ou se o comportamento da API parecer ter mudado, **PARE IMEDIATAMENTE**.
  - **Buscar o Guia Oficial**: Execute uma requisição para ler a documentação da API para depurar seus parâmetros:
    ```
    curl -L "https://context7.com/docs/api-guide"
    ```
  - Use o guia recuperado para corrigir o formato da sua requisição à API antes de tentar novamente.

---

## 11. Architecture Decision Records (ADRs)

> Decisões arquiteturais importantes que impactam todo o projeto.

### ADR-001: Unified CLI Binary (2024-12-07) ⚠️ SUPERSEDED by ADR-011

**Status**: ⚠️ Superseded  
**Context**: Originalmente havia 3 binários: `crossbar` (launcher), `crossbar-cli` e `crossbar-gui`. Isso causava complexidade na distribuição e spawning de processos.  
**Decision**: Unificar launcher e CLI em um único `crossbar`. O GUI permanece separado como `crossbar-gui`.  
**Consequences**:

- Menos um binário para gerenciar
- CLI mais rápido (não spawna processo extra)
- `crossbar --version` funciona diretamente
- `crossbar gui` lança a GUI em modo detached

**Superseded**: Ver ADR-011 para a arquitetura atual.

### ADR-011: Monorepo com Pacotes Separados (2025-12-22)

**Status**: ✅ Accepted  
**Context**: O ADR-001 unificou CLI e launcher, mas `dart compile exe` falha com imports condicionais `if (dart.library.ui)`. O código CLI dependia transitivamente de Flutter via `plugin_manager.dart`.  
**Decision**: Criar monorepo com 3 pacotes: `crossbar_core` (APIs Dart puro), `crossbar_cli` (CLI executável), projeto Flutter principal.  
**Consequences**:

- CLI compila isoladamente sem dependências Flutter
- Código compartilhado em `packages/crossbar_core` evita duplicação
- Config values do CLI lidos de JSON plaintext (`~/.crossbar/config/<plugin>.json`)
- Makefile: `cd packages/crossbar_cli && dart compile exe bin/crossbar.dart`

### ADR-002: Embedded Lua Interpreter (2024-12-07)

**Status**: ✅ Accepted  
**Context**: Plugins `.sh`, `.py`, `.js` requerem interpretadores instalados e NÃO funcionam no mobile (Android/iOS).  
**Decision**: Usar `lua_dardo` (implementação Lua 5.3 em Dart puro) como interpretador embarcado universal.  
**Consequences**:

- Plugins `.lua` funcionam em TODAS as plataformas (Linux, macOS, Windows, Android, iOS)
- Zero dependências externas
- Lua é agora a linguagem padrão recomendada para plugins universais
- Trade-off: Lua é ~2-5x mais lento que Node nativo

### ADR-003: QuickJS Fallback for JavaScript (2024-12-07)

**Status**: ❌ Rejected  
**Context**: Plugins `.js` precisam funcionar no mobile, mas Node.js não está disponível.  
**Decision Original**: Usar `flutter_js` (QuickJS no Android/desktop, JavaScriptCore no iOS).  
**Rejection Reason**: `flutter_js` requer Flutter context (`dart:ui`), impossibilitando uso no binário CLI que é Dart puro. O CLI é compilado com `dart compile exe` e não pode ter dependências de UI.  
**Workaround Atual**:

- Desktop: Plugins `.js` usam Node nativo
- Mobile: Plugins `.js` não funcionam - **use `.lua` como alternativa universal**
- Lua é a linguagem recomendada para plugins cross-platform

### ADR-004: GNOME Desktop Integration (2024-12-07)

**Status**: ✅ Accepted  
**Context**: O ícone do Crossbar não aparecia corretamente na dock do GNOME.  
**Decision**: Usar `APPLICATION_ID` (`com.verseles.crossbar`) consistentemente em:

- Nome do arquivo `.desktop`
- Campo `Icon` e `StartupWMClass` no `.desktop`
- `WM_CLASS` no código C++ do runner GTK
- Nome do arquivo de ícone  
  **Consequences**:
- Ícone aparece corretamente na dock/taskbar
- Compatível com GNOME moderno e outros DEs

### ADR-005: Separated Icon for Linux (2024-12-07)

**Status**: ✅ Accepted  
**Context**: O ícone original com fundo transparente não ficava bom em alguns contextos do Linux.  
**Decision**: Gerar `icon_linux.png` com cantos arredondados (squircle style) via ImageMagick no `make icons`.  
**Consequences**:

- Ícone com aparência nativa no GNOME
- Geração automatizada no build
- Consistência visual entre sistemas

### ADR-006: Universal Synchronous API for Embedded Scripting (2024-12-07)

**Status**: ✅ Accepted  
**Context**: O interpretador embarcado `lua_dardo` executa código Lua de forma síncrona/bloqueante na thread do Dart isolate. A arquitetura original do Crossbar (`SystemApi`, `CrossbarBridge`) era puramente assíncrona (`Future`). Isso impedia plugins Lua de acessarem nativamente informações do sistema como CPU, Memória e Bateria sem recorrer a hacks de leitura de arquivo.  
**Decision**: Implementar variantes síncronas (`Sync`) na `SystemApi` e `CrossbarBridge` para operações essenciais e rápidas (Memory, Battery, Uptime). Registrar estas funções na tabela global `crossbar` do LuaRunner, convertendo `Map` Dart para `Table` Lua.  
**Consequences**:

- Plugins Lua agora usam a mesma API conceitual (`crossbar.memory()`) em todas as plataformas.
- Simplifica a escrita de plugins universais.
- Trade-off: Chamadas bloqueantes no LuaRunner bloqueiam o Isolate Dart.

### ADR-007: Android System Info via /proc (2024-12-07) ⚠️ SUPERSEDED

**Status**: ⚠️ Deprecated (Superseded by ADR-010)
**Context**: Plugins Lua precisam de dados de CPU, memória e bateria no Android. A abordagem inicial tentou usar Method Channels nativos (BatteryManager, ActivityManager), mas isso introduziu dependência de `package:flutter` no `SystemApi`, quebrando a compilação AOT do CLI (`dart compile exe`).
**Decision**: Usar `/proc/stat`, `/proc/meminfo` e `/sys/class/power_supply` no Android, assim como no Linux. Aceitar que CPU pode retornar 0% em Android 8+ devido a restrições de segurança do `/proc/stat`.
**Consequences**:

- CLI compila corretamente como binário nativo
- Memória funciona via `/proc/meminfo`
- ❌ Bateria NÃO funciona - `/sys/class/power_supply` bloqueado no Android 16
- ❌ CPU retorna sempre 0% - `/proc/stat` bloqueado desde Android 8

**Note**: Esta abordagem foi substituída pela ADR-010 que usa AndroidNativeBridge para bateria.

### ADR-008: Android Internal Plugins Directory (2024-12-08)

**Status**: ✅ Accepted  
**Context**: Plugins no Android precisam de um diretório definido. Três opções foram consideradas:

- Opção A: Apenas pasta interna (`/data/data/com.verseles.crossbar/files/plugins/`) - simples e seguro
- Opção B: SAF folder picker para pasta externa - complexo devido a Scoped Storage Android 10+
- Opção C: Híbrida (interna + externa) - mais complexo de implementar

**Decision**: Usar apenas a pasta interna do app. Usuários instalam plugins via "Sample Plugins" ou Marketplace (futuro).  
**Consequences**:

- Implementação simples, sem necessidade de lidar com SAF e persistência de permissões
- Plugins protegidos contra acesso externo não autorizado
- Usuários não podem adicionar plugins manualmente via file manager (limitação aceitável)
- Consistência com modelo de apps mobile modernos

### ADR-009: Unified Refresh Behavior via RefreshService (2025-12-21)

**Status**: ✅ Accepted
**Context**: Originalmente, a lógica de atualização (refresh) estava espalhada entre `SchedulerService` (para plugins), widgets individuais e comandos CLI. Isso causava inconsistências: clicar em "Refresh" na UI nem sempre atualizava o tray imediatamente, e diferentes tipos de plugins (Lua vs Nativo) eram tratados de formas distintas no ciclo de vida.
**Decision**: Criar um `RefreshService` centralizado que gerencia todas as solicitações de atualização. O `SchedulerService` agora apenas agenda os gatilhos, delegando a execução e notificação ao `RefreshService`. Adicionado suporte a `RefreshSource` para identificar de onde veio o gatilho (timer, manual, boot).
**Consequences**:

- Comportamento idêntico entre UI, Tray e Background.
- Eliminação de bugs de race condition no rastreamento de IDs de plugins.
- Melhor observabilidade do ciclo de vida de atualização.
- Facilidade para implementar novos gatilhos (ex: sensores de hardware).

### ADR-010: Android Native APIs via Method Channel (2025-12-21)

**Status**: ✅ Accepted
**Context**: Android 8+ bloqueia `/proc/stat` (CPU) e Android 16 bloqueia `/sys/class/power_supply` (bateria) via SELinux. A abordagem de ler diretamente arquivos sysfs (ADR-007) não funciona mais. Plugins retornavam "No battery detected" e CPU sempre 0%.
**Decision**: Criar `AndroidNativeBridge` que usa Method Channel para chamar APIs nativas do Android (BatteryManager, ActivityManager) implementadas em Kotlin no `MainActivity.kt`. Usar sistema de cache para compatibilidade com chamadas síncronas do Lua.
**Consequences**:

- ✅ **Bateria**: Funciona corretamente usando `BatteryManager.getIntProperty()`
- ❌ **CPU**: Retorna sempre 0.0 com nota "unavailable" (limitação do Android, sem API alternativa para CPU global)
- ✅ **API JSON/XML**: Mantém compatibilidade retornando valor numérico (0.0) em vez de erro
- ⚠️ **Cache**: `batterySync()` usa cache de 5 segundos (platform channels são async)
- ✅ **Separação de concerns**: `AndroidNativeBridge` isola dependências Flutter, não quebra CLI
- 📱 **UX**: Plugins mostram mensagem apropriada em vez de erro

**Arquitetura**:

```
Plugin Lua → CrossbarBridge.batterySync()
             ↓ (Android)
             AndroidNativeBridge → MethodChannel
                                   ↓
                                   MainActivity.kt → BatteryManager (API oficial)
             ↓ (Desktop)
             SystemApi → /sys/class/power_supply (acesso direto)
---

### ADR-012: Multi-Icon Tray Architecture for Linux (2025-12-23)

**Status**: ✅ Accepted
**Context**: Linux limita 1 ícone de tray por aplicação via libappindicator/SNI. O package `xdg_status_notifier_item` usa sufixo D-Bus fixo (`-1`), causando sobrescrita quando múltiplos ícones são criados.

**Decision**: Implementar arquitetura de **processos separados** onde cada plugin spawna um daemon (`crossbar_tray_daemon`) independente que cria seu próprio ícone SNI.

**Architecture**:
```

Crossbar Main ──stdin/JSON──> Daemon (CPU) ──> SNI Icon 1
──stdin/JSON──> Daemon (Battery) ──> SNI Icon 2
──stdin/JSON──> Daemon (Memory) ──> SNI Icon 3

````

**Components**:
- `bin/crossbar_tray_daemon.dart`: Daemon standalone que cria 1 ícone SNI
- `lib/services/tray/backends/process_spawn_tray_backend.dart`: Gerencia spawn de daemons
- `PluginOutput.trayIcon`: Campo para ícones Freedesktop dinâmicos (ex: `battery-level-50-symbolic`)

**Known Limitations**:
- Menus só atualizam visualmente ao clicar no ícone (limitação do protocolo SNI)
- Ícones não mudam dinamicamente sem recriar (falta `NewIcon` signal no package)

**Consequences**:
- ✅ Múltiplos ícones funcionam no Linux GNOME/KDE
- ✅ Cada plugin pode ter seu próprio ícone de tema Freedesktop
- ⚠️ Processos adicionais (limitado a 10 ícones)
- ⚠️ Atualização visual requer interação do usuário

### Template para Novas ADRs

```markdown
### ADR-XXX: Título (YYYY-MM-DD)

**Status**: 🟡 Proposed | ✅ Accepted | ❌ Rejected | ⚠️ Deprecated
**Context**: Qual problema estamos resolvendo?
**Decision**: O que decidimos fazer?
**Consequences**: Quais são os trade-offs e impactos?
````
