# Crossbar Roadmap

Este documento descreve o roteiro de desenvolvimento do Crossbar. Ele começa com uma auditoria honesta do estado atual do projeto (v1.0.0), identifica funcionalidades cruciais que foram planejadas mas não implementadas, e estabelece um plano de ação claro e faseado para torná-las realidade.

## Auditoria do Estado Atual (v1.0.0)

O plano original descrevia um sistema robusto onde plugins poderiam declarar suas configurações em um arquivo JSON. O Crossbar seria responsável por gerar a UI de configuração, salvar os valores preenchidos pelo usuário e injetá-los como variáveis de ambiente na execução do plugin.

Após uma auditoria completa, o sistema de configuração é atualmente uma **"casca" funcional na UI, mas sem o "motor" no backend**.

### O que está Implementado (A "Casca"):

-   [x] **Modelos de Dados:** As classes `PluginConfig` e `Setting` existem em `lib/models/plugin_config.dart`.
-   [x] **Geração de UI:** O `PluginConfigDialog` e o `ConfigFormBuilder` em `lib/ui/` conseguem renderizar um formulário a partir de um objeto `PluginConfig`.
-   [x] **Scaffolding:** O comando `crossbar init` gera um arquivo `.config.json` de exemplo.

### O que está Ausente (O "Motor"):

-   [ ] **Descoberta de Configuração:** O `PluginManager` não lê os arquivos `.config.json`.
-   [ ] **Persistência de Valores:** Não há lógica para salvar ou carregar os valores de configuração dos plugins.
-   [ ] **Injeção de Variáveis:** O `ScriptRunner` não injeta as configurações do usuário nos plugins.
-   [ ] **Segurança para Senhas:** O `flutter_secure_storage` não está sendo usado para campos do tipo `password`.
-   [ ] **Conexão UI ↔ Backend:** O diálogo de configuração não salva os dados em lugar nenhum.

---

## Epic: v1.1.0 - The Configuration Engine

**Objetivo:** Implementar de ponta a ponta o sistema de configuração declarativa de plugins. Ao final deste epic, um usuário poderá configurar um plugin através da UI, e o plugin receberá esses valores como variáveis de ambiente.

---

### Fase 1: Core de Configuração e Persistência

**Meta:** Fazer o backend reconhecer as configurações dos plugins e ser capaz de salvar os valores inseridos pelo usuário em disco.

#### Tarefa 1.1: Vincular Configuração ao Plugin

-   [ ] **Modelo:** Em `lib/models/plugin.dart`, adicionar o campo `final PluginConfig? config;` à classe `Plugin`.
-   [ ] **Modelo:** Atualizar o construtor, `copyWith`, `fromJson`, `toJson` para incluir o novo campo `config`.
-   [ ] **Lógica:** Em `lib/core/plugin_manager.dart`, no método `_createPluginFromFile`, implementar a lógica para procurar um arquivo `[plugin_name].config.json`.
-   [ ] **Lógica:** Se o arquivo de configuração existir, fazer o parse do JSON para um objeto `PluginConfig`.
-   [ ] **Lógica:** Associar o objeto `PluginConfig` ao criar e retornar o objeto `Plugin`.
-   [ ] **Testes:** Em `test/unit/core/plugin_manager_test.dart`:
    -   [ ] Adicionar um teste que cria um plugin com um arquivo `.config.json` e verifica se o campo `plugin.config` não é nulo.
    -   [ ] Adicionar um teste para um plugin sem arquivo de configuração e verificar se `plugin.config` é nulo.

#### Tarefa 1.2: Criar Serviço de Persistência de Valores

-   [ ] **Estrutura:** Criar o novo arquivo `lib/services/plugin_config_service.dart`.
-   [ ] **Lógica:** Implementar a classe `PluginConfigService` como um singleton.
-   [ ] **Lógica:** Implementar um método `Future<String> _getConfigPath(String pluginId)` para retornar o caminho `~/.crossbar/configs/[plugin_id].values.json`.
-   [ ] **Lógica:** Implementar o método `Future<Map<String, dynamic>> loadValues(String pluginId)`.
-   [ ] **Lógica:** Implementar o método `Future<void> saveValues(String pluginId, Map<String, dynamic> values)`.
-   [ ] **Testes:** Criar o novo arquivo `test/unit/services/plugin_config_service_test.dart`.
    -   [ ] Adicionar um teste para `saveValues` e verificar se o arquivo `.values.json` é criado com o conteúdo correto.
    -   [ ] Adicionar um teste para `loadValues` que lê o arquivo salvo anteriormente.
    -   [ ] Adicionar um teste para `loadValues` de um plugin sem configuração salva, garantindo que retorne um mapa vazio.

---

### Fase 2: Injeção de Configurações na Execução

**Meta:** Fazer com que os valores salvos na Fase 1 cheguem efetivamente ao ambiente de execução do plugin.

#### Tarefa 2.1: Modificar o ScriptRunner para Injetar Configs

-   [ ] **Lógica:** Em `lib/core/script_runner.dart`, no método `_buildEnvironment`, injetar a dependência do `PluginConfigService`.
-   [ ] **Lógica:** Dentro de `_buildEnvironment`, chamar `pluginConfigService.loadValues(plugin.id)` para obter as configurações salvas.
-   [ ] **Lógica:** Iterar sobre os valores carregados e adicioná-los ao mapa de `environment`.
-   [ ] **Testes:** Criar um novo arquivo de fixture `test/functional/fixtures/config_check.1s.sh` que faz `echo "MY_VAR_IS=$MY_VAR"`.
-   [ ] **Testes:** Em `test/functional/plugin_execution_test.dart`, adicionar um novo teste que:
    -   [ ] Salva um valor de configuração `{'MY_VAR': 'hello_world'}` usando o `PluginConfigService`.
    -   [ ] Executa o plugin `config_check.1s.sh` através do `ScriptRunner`.
    -   [ ] Verifica se a saída do plugin (`output.text`) contém `MY_VAR_IS=hello_world`.

---

### Fase 3: Integração da UI e Segurança

**Meta:** Conectar a interface do usuário ao novo sistema de persistência e implementar o armazenamento seguro de senhas.

#### Tarefa 3.1: Conectar a UI ao Backend de Configuração

-   [ ] **UI:** Em `lib/ui/tabs/plugins_tab.dart`, implementar a ação do botão "Configurar" em `_showPluginDetails` ou `_PluginCard`.
-   [ ] **UI:** Antes de abrir o diálogo, usar o `PluginConfigService` para carregar os valores já salvos para aquele plugin.
-   [ ] **UI:** Abrir o `PluginConfigDialog`, passando o `plugin.config` e os valores carregados.
-   [ ] **UI:** Ao receber os novos valores do diálogo, chamar `PluginConfigService.saveValues()`.
-   [ ] **Testes:** Em `test/widget/plugins_tab_test.dart`, adicionar um teste de widget que simula o clique, a abertura do diálogo e a chamada do método `saveValues`.

#### Tarefa 3.2: Implementar Armazenamento Seguro para Senhas

-   [ ] **Lógica:** Em `lib/services/plugin_config_service.dart`, modificar o método `saveValues`:
    -   [ ] Receber o `PluginConfig` como parâmetro para saber o tipo de cada campo.
    -   [ ] Se um campo for do tipo `password`, salvá-lo usando `flutter_secure_storage.write()` e removê-lo do mapa que vai para o JSON.
-   [ ] **Lógica:** Em `lib/services/plugin_config_service.dart`, modificar o método `loadValues`:
    -   [ ] Receber o `PluginConfig` como parâmetro.
    -   [ ] Após carregar do JSON, iterar sobre os campos `password` e carregar seus valores usando `flutter_secure_storage.read()`.
-   [ ] **Lógica:** Assegurar que `lib/core/script_runner.dart` chame a nova versão de `loadValues` para que as senhas sejam injetadas no ambiente.
-   [ ] **Testes:** Em `test/unit/services/plugin_config_service_test.dart`, mockar o `FlutterSecureStorage` e adicionar testes para verificar se `write` e `read` são chamados para campos de senha, e que esses campos não estão no arquivo JSON.

---

## Backlog de Features (Pós v1.1.0)

-   [ ] **Global Hotkey:** Implementar o atalho `Ctrl+Alt+C` para abrir a GUI.
-   [ ] **Refresh Override:** Permitir que o usuário sobrescreva o intervalo de atualização de um plugin.
-   [ ] **Utilitários CLI:** Implementar os comandos restantes (`--qr-generate`, `--location`, etc.).
-   [ ] **Documentação:** Finalizar os guias em `docs/`.
-   [ ] **Docker/Podman:** Finalizar a infraestrutura de contêineres.