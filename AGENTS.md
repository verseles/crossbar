# Crossbar - Contexto e Regras para Agentes

> **Este arquivo é a ÚNICA fonte de verdade para regras operacionais e contexto técnico.**
> Leia-o integralmente no início de cada sessão. Sempre que concluir tudo ou, chame adequadamente a tool play_notification para notificar o usuário.

Plano granndioso e teorico:
@./original_plan.md
Plano de execucao baseado em original_plan.md, pode estar defasado:
@./MASTER_PLAN.md
Roadmap de implementacao, atualizado regularmente:
@./ROADMAP.md

## 1. Regras Operacionais (Inflexíveis)

- **Idioma**: Português (pt-BR) para toda comunicação.
- **Postura**: Direta, técnica e concisa. Sem floreios, sem pedidos de desculpas.
- **Leitura Inicial**: Sempre leia @./original_plan.md, @./MASTER_PLAN.md e @./ROADMAP.md no início de cada sessão para esclarecer dúvidas sobre futuras implementações e discussões de planejamento.
- **Testes e Análise**: **JAMAIS** commite código sem rodar testes (`flutter test --coverage`), verificar coverage mínimo de 43% e análise estática (`flutter analyze --no-fatal-infos`). Se alterar UI/Lógica, adicione novos testes.
- **Commits**: Padrão Conventional Commits (`feat`, `fix`, `docs`, `test`, `ci`). Sem co-autores.
- **Pipeline**: Use `gh run list` e `gh run watch` para monitorar builds após push, já está autenticado no sistema.
- **Dependencies**: NUNCA assuma bibliotecas. Verifique `pubspec.yaml`.
- **Verificação Local CI**: Antes de qualquer `push`, **SEMPRE** execute e confirme a aprovação das pipelines localmente usando `act` ou simplesmente execute os comandos necessários diretamente.
- **Diagnóstico CI Remoto**: Em caso de falha de pipeline no GitHub, utilize `gh run watch` ou `gh run view --web` para diagnosticar e monitorar a correção.

---

## 2. Identidade do Projeto

- **Nome**: Crossbar (Universal Plugin System)
- **Versão Atual**: `1.0.1+2` (atualize ao final de cada sessão).
- **Stack**: Flutter `3.38.3` (CI), Dart `3.10+`.
- **Objetivo**: Sistema de plugins compatível com BitBar/Argos para Linux, Windows, macOS, Android e iOS.
- **Status**: Estável (v1.0+). Todas as fases do `MASTER_PLAN.md` concluídas.

---

## 3. Arquitetura de Execução (Tri-Binary)

O projeto compila **3 binários** para resolver problemas de dependência (GTK) e UX:

1.  **`crossbar` (Launcher)**:
    - Fonte: `bin/launcher.dart`
    - Função: Roteador. Se houver argumentos, chama CLI. Se não, chama GUI.
2.  **`crossbar-gui` (Flutter App)**:
    - Fonte: `lib/main.dart`
    - Função: Interface gráfica, Tray, Services. Depende de GTK/Cocoa.
3.  **`crossbar-cli` (Pure Dart)**:
    - Fonte: `bin/crossbar.dart` -> `lib/cli/cli_handler.dart`
    - Função: Comandos de sistema (`--cpu`, `--notify`). **Zero dependências de UI**.

---

## 4. Estrutura de Arquivos Chave

```text
crossbar/
├── bin/
│   ├── launcher.dart           # Entrypoint do Launcher (Router)
│   └── crossbar.dart           # Entrypoint da CLI
├── lib/
│   ├── main.dart               # Entrypoint da GUI Flutter
│   ├── cli/
│   │   ├── cli_handler.dart    # Switch-case gigante com ~75 comandos
│   │   └── plugin_scaffolding.dart # Lógica de 'crossbar init'
│   ├── core/
│   │   ├── plugin_manager.dart # Descoberta e ciclo de vida de plugins
│   │   ├── script_runner.dart  # Execução de scripts (Process.run com timeout)
│   │   └── output_parser.dart  # BitBar Text parser & JSON parser
│   ├── services/               # Singleton Services
│   │   ├── ipc_server.dart     # REST API (localhost:48291)
│   │   ├── tray_service.dart   # Gerenciamento de ícones de bandeja
│   │   ├── scheduler_service.dart # Timers para refresh de plugins
│   │   ├── notification_service.dart # Notificações push
│   │   ├── plugin_config_service.dart # Gestão de config e secrets
│   │   ├── marketplace_service.dart # Instalação de plugins
│   │   └── widget_service.dart    # Mobile Home Widgets
│   └── ui/                     # Widgets Flutter (Material 3)
├── plugins/                    # Exemplos de plugins (Go, Rust, Py, JS, Sh, Dart)
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

- **Runner**: `lib/core/script_runner.dart`
- **Interpreters**: Bash, Python3, Node, Dart, Go (`go run`), Rust (`rustc` temp build).
- **Output**: Suporta formato texto legado (BitBar) OU JSON estruturado (Crossbar).

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
- **Docker/Podman**:
  - `make container-shell`: Entra no ambiente dev containerizado.
  - `make container-build`: Roda build clean.
  - **Alternativa**: Se `podman` ou `podman-compose` não forem encontrados, tente usar `docker` e `docker-compose` como fallback.

### Armadilhas Comuns

1.  **Versão do Flutter**: O CI exige estritamente `3.38.3`. Versões mais novas/velhas quebram constraints do Dart `^3.10.0`.
2.  **Dependências Linux**: Requer `libayatana-appindicator3-dev` e `libsecret-1-dev`.
3.  **Caminhos em Mobile**: Nunca use paths absolutos (`/home/user`) em Android/iOS. Use `path_provider`.
4.  **CLI vs GUI**: Não importe `dart:ui` ou widgets Flutter dentro de `lib/cli/`. Isso quebra o binário CLI puro.
5.  **Testes de Hardware**: Testes em `cli_handler_hardware_test.dart` alteram volume, brilho, wifi e bluetooth. Use `--exclude-tags=hardware` localmente para evitar glitches.

### Validação Local CI (act)

- **Ferramenta**: `act`
- **Função**: Permite executar os workflows do GitHub Actions localmente, utilizando Docker.
- **Uso**: Simula o ambiente do CI/CD para testar pipelines antes de fazer `push`, prevenindo falhas remotas.

---

## 7. Status do Roadmap

- **Fase Atual**: Manutenção v1.0.1
- **Features Completas**:
  - [x] Core Plugin System (6 linguagens)
  - [x] CLI Avançada (Mídia, Sistema, Rede, Utils)
  - [x] GUI Desktop + Tray
  - [x] Mobile Widgets + Notifications
  - [x] IPC Server (HTTP)
  - [x] CI/CD Multi-plataforma
- **Pendente**:
  - [ ] Atalho global (Ctrl+Alt+C)
  - [ ] Marketplace real (Backend integration)
  - [ ] Sandboxing de plugins

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
   ```
2. **Depois rebuild e abra novamente**:
   ```bash
   flutter build linux --release
   ./build/linux/x64/release/bundle/crossbar gui
   ```

Ou use o comando combinado:

```bash
pkill -9 -f crossbar-gui; flutter build linux --release && ./build/linux/x64/release/bundle/crossbar gui
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

- Teste a compilação do código antes de commitar.
- Commite código funcional incrementalmente.
- Atualize a documentação do plano conforme avança.
- Aprenda com implementações existentes.
- Pare após 3 tentativas falhas e reavalie.
- Atualize o roadmap conforme avança.
- Sempre que concluir tudo, chame adequadamente a tool play_notification para notificar o usuário.

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
