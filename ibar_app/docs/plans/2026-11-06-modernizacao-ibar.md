# Modernização do app IBAR Implementation Plan

> **For Copilot:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Modernizar a experiência do app IBAR e tornar a sessão e as integrações existentes consistentes sem alterar as regras de negócio.

**Architecture:** Separar a apresentação, a sessão autenticada e o acesso HTTP em componentes testáveis. Persistir o token com armazenamento seguro, compartilhar o cliente de API entre as operações e manter as telas de Consultas e Workflow como indisponíveis até que seus requisitos sejam definidos.

**Tech Stack:** Flutter/Dart, Provider, `http`, `flutter_secure_storage`, `flutter_test`.

---

## Contexto e bloqueios conhecidos

- O app Flutter fica em `ibar_app/`; os comandos abaixo devem ser executados nesse diretório.
- O teste existente ainda espera o contador do template e falha no baseline porque `MyApp` abre a tela de login. Substituí-lo por um teste do IBAR é parte deste trabalho.
- A cópia original tem mudanças locais não commitadas em `catraca.dart`, `copia_catraca.dart`, `orders_screen.dart` e `protheus_auth.dart`. Este plano será executado na worktree isolada e não deve sobrescrevê-las.
- Os endpoints atuais usam HTTP e as requisições autenticadas enviam `Authorization: Bearer <token>`. Não enviar credenciais ou tokens por HTTP em builds de produção. Os URLs de produção podem ser fornecidos pelos defines `PROTHEUS_SERVICE_BASE_URL` e `PROTHEUS_APPROVAL_BASE_URL` após a equipe Protheus disponibilizar HTTPS; até lá, as chamadas de autenticação e operações falham fechadas em release.

## Task 1: Substituir o teste de contador do template

**Files:**
- Modify: `test/widget_test.dart`

**Step 1: Escrever a expectativa da tela inicial real**

Trocar as expectativas do contador por uma verificação de que `MyApp` renderiza o título de boas-vindas e os campos de usuário e senha.

**Step 2: Confirmar a falha do teste de template atual**

Run: `flutter test test/widget_test.dart`
Expected: O teste atual falha porque não existem widgets do contador. Essa falha de baseline já foi observada; não a atribuir à implementação.

**Step 3: Substituir o teste obsoleto pelo teste do login**

Trocar as expectativas do contador por asserções de widgets reais do login e executar o teste atualizado. Como a tela já existe, ele deve passar sem mudanças de produção.

**Step 4: Confirmar o teste**

Run: `flutter test test/widget_test.dart`
Expected: PASS para a tela do IBAR; nenhuma expectativa de contador permanece.

## Task 2: Adicionar armazenamento seguro de sessão

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/services/protheus_auth.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/login_screen.dart`
- Create: `lib/services/token_storage.dart`
- Test: `test/services/protheus_auth_test.dart`

**Step 1: Criar testes de sessão com armazenamento falso**

Testar que a inicialização restaura um token salvo, que logout o remove e que uma autenticação bem-sucedida persiste o token. Usar um armazenamento falso e um cliente HTTP controlado pelo teste, sem rede real.

**Step 2: Rodar os testes e verificar a falha**

Run: `flutter test test/services/protheus_auth_test.dart`
Expected: FAIL inicialmente por falta da interface de persistência e comportamento de restauração.

**Step 3: Implementar armazenamento seguro e injetável**

Adicionar `flutter_secure_storage` e uma abstração pequena de armazenamento de token, com implementação real segura e implementação falsa apenas no teste. Tornar a restauração e logout assíncronos; nunca guardar senha, registrar token ou usar preferências comuns para a sessão.

**Step 4: Ligar restauração e saída à navegação**

Inicializar a sessão antes de decidir entre Home e Login. Enquanto a inicialização estiver em andamento, mostrar carregamento; se o armazenamento falhar, exibir erro recuperável em vez de esconder a falha. Logout deve apagar a sessão e retornar ao login.

**Step 5: Verificar sessão e app**

Run: `flutter test test/services/protheus_auth_test.dart test/widget_test.dart`
Expected: PASS, sem chamadas de rede real.

## Task 3: Centralizar configuração e chamadas de API

**Files:**
- Create: `lib/services/protheus_api_client.dart`
- Create: `lib/services/api_config.dart`
- Test: `test/services/protheus_api_client_test.dart`

**Step 1: Escrever testes de requisição**

Cobrir construção da URL, envio do token segundo o contrato confirmado, interpretação de resposta JSON e propagação de status de erro com um `http.Client` falso/controlado.

**Step 2: Rodar o teste e observar a falha**

Run: `flutter test test/services/protheus_api_client_test.dart`
Expected: FAIL porque o cliente central ainda não existe.

**Step 3: Implementar cliente compartilhado mínimo**

Injetar `http.Client`, centralizar timeouts e configuração por ambiente, e expor erros identificáveis pela camada de apresentação. Não adicionar fallback de sucesso nem colocar segredo em configuração versionada.

**Step 4: Verificar o cliente**

Run: `flutter test test/services/protheus_api_client_test.dart`
Expected: PASS para sucesso, JSON inválido e status HTTP não bem-sucedido.

**Gate de integração:** O formato da autorização é `Authorization: Bearer <token>`, mas os serviços só estão disponíveis por HTTP. Não enviar tokens por HTTP em builds de produção. A configuração de desenvolvimento pode manter os endereços atuais para testes na rede interna; em release, recusar qualquer requisição HTTP com uma mensagem explícita e acionável até a equipe Protheus disponibilizar HTTPS. Não trocar o esquema/hosts dos endpoints nem identificadores de operação sem confirmação.

## Task 4: Migrar as operações existentes para o cliente compartilhado

**Files:**
- Modify: `lib/screens/orders_screen.dart`
- Modify: `lib/screens/catraca.dart`
- Test: `test/services/` (testes dos serviços e contratos confirmados)

**Step 1: Adicionar testes para os contratos recebidos**

Cobrir listagem de requisições abertas, aprovação/rejeição e solicitação de catraca com respostas controladas; confirmar se ações recebem IDs de item ou de requisição.

**Step 2: Verificar a falha**

Run: `flutter test test/services/`
Expected: Os casos novos falham antes da implementação.

**Step 3: Migrar cada tela sem mudar regra de negócio**

Usar o cliente compartilhado e o token atual. Preservar tipos de solicitação e feedbacks existentes; tratar sessão expirada, rede e respostas inesperadas sem sucesso falso. Remover cabeçalhos mascarados e não logar tokens.

**Step 4: Validar testes focados**

Run: `flutter test test/services/ test/widget_test.dart`
Expected: PASS, sem conexão com ambiente Protheus real.

## Task 5: Padronizar aparência e estados das telas

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/constants/colors.dart`
- Modify: `lib/screens/login_screen.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/approvals_screen.dart`
- Modify: `lib/screens/orders_screen.dart`
- Modify: `lib/screens/queries_screen.dart`
- Modify: `lib/screens/workflow_screen.dart`
- Modify: `lib/screens/catraca.dart`
- Modify: `lib/widgets/`
- Test: `test/widget_test.dart` e testes de widgets pertinentes

**Step 1: Adicionar testes de widget para estados observáveis**

Cobrir validação de login, carregamento/erro/vazio onde aplicável, confirmação de ações e indicação de indisponibilidade nas telas não integradas.

**Step 2: Confirmar as falhas esperadas**

Run: `flutter test test/widget_test.dart`
Expected: FAIL apenas nos estados/elementos visuais ainda não implementados.

**Step 3: Aplicar o tema azul e componentes consistentes**

Reutilizar os widgets existentes quando apropriado; padronizar tipografia, espaçamento, botões, feedback e navegação. Evitar alturas fixas e preservar o logo. Consultas e Workflow devem informar que não estão disponíveis, sem mostrar exemplos como dados reais.

**Step 4: Rodar testes e análise**

Run: `flutter test`
Expected: PASS.

Run: `flutter analyze`
Expected: sem novos erros introduzidos.

## Critérios de aceite

- A sessão pode ser restaurada com armazenamento seguro e é apagada ao sair.
- Requisições autenticadas usam o token da sessão conforme contrato verificado.
- Nenhuma tela contém segredo fixo nem mostra sucesso para resposta não confirmada.
- Aprovações e catraca preservam seus fluxos atuais.
- Estados de carregamento, vazio, indisponibilidade e erro são visíveis e coerentes.
- Consultas e Workflow não apresentam conteúdo de exemplo como informação real.
- Testes rodam sem acessar servidor ou credenciais reais.
