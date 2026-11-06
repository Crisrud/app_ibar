# Desenho: modernização do app IBAR

## Contexto

O app Flutter atende operações internas e já contém login no Protheus, consulta e
decisão sobre requisições de compra e solicitação de liberação de catraca.
Consultas e Workflow ainda não têm integração ou comportamento funcional
completo. A modernização deve melhorar a experiência e a confiabilidade sem
alterar as regras de negócio existentes ou inventar funcionalidades.

## Objetivos

- Manter login, aprovações de compras e liberação de catraca.
- Padronizar identidade visual, navegação, formulários e estados de carregamento,
  erro e ausência de dados, usando o azul atual como base e preservando o logo.
- Centralizar autenticação e comunicação com APIs, removendo credenciais fixas
  das telas e usando o token da sessão nas operações.
- Persistir a sessão em armazenamento seguro do dispositivo e limpá-la ao sair.
- Manter Consultas e Workflow no menu como funcionalidades indisponíveis até
  que seus requisitos e integrações sejam definidos.
- Substituir o teste de exemplo do contador por testes relacionados aos fluxos
  do aplicativo.

## Fora de escopo

- Criar novos casos de uso para Consultas ou Workflow.
- Alterar os tipos ou regras de negócio de aprovação e liberação de catraca.
- Presumir contratos, cabeçalhos, credenciais ou endpoints que não tenham sido
  confirmados pela equipe responsável pelo Protheus.

## Estrutura proposta

Separar a interface da sessão e do acesso remoto:

- **Interface:** telas e componentes reutilizáveis para tema, formulários,
  mensagens, carregamento, vazio e erro.
- **Sessão/autenticação:** login, token em memória, persistência segura no
  dispositivo, expiração e logout.
- **Cliente de API:** configuração de base por ambiente, cabeçalhos comuns,
  serialização, tratamento explícito de status/erros e limites de espera.
- **Operações:** serviços específicos para requisições de compra e catraca,
  consumidos pelas telas sem montar cabeçalhos ou URLs diretamente.

O token não deve ser registrado em logs, nem armazenado em preferências comuns.
Ao sair, a sessão persistida deve ser removida e a navegação retornar ao login.
O tratamento de expiração deve solicitar autenticação novamente; suporte a
renovação depende do contrato OAuth disponível no servidor.

## Dependências do ambiente Protheus

O código atual usa HTTP e contém valores de autorização fixos ou mascarados em
chamadas de API. Antes de concluir a integração, confirmar com a equipe
Protheus:

1. URLs e ambientes de desenvolvimento/homologação/produção.
2. Disponibilidade de HTTPS e requisitos de certificado.
3. Formato de autenticação aceito por cada endpoint e como o token deve ser
   enviado.
4. Contratos de resposta, códigos de erro e expiração/renovação do token.
5. Se aprovar e rejeitar recebem identificadores de item ou de requisição e
   quais respostas indicam sucesso parcial.

Não incluir segredos no app ou em arquivos versionados de configuração. Não
considerar HTTP adequado para produção; se HTTPS não estiver disponível, essa
limitação deve ser explicitada e resolvida com os responsáveis pelo serviço.

## Etapas sugeridas

1. **Confirmar contratos e configuração:** registrar requisitos da API e
   ambientes sem credenciais.
2. **Implementar sessão e cliente de API:** persistência segura, autenticação
   centralizada, erros explícitos e testes unitários com respostas simuladas.
3. **Modernizar a experiência base:** tema azul, componentes consistentes,
   navegação, login e estados de carregamento/erro/vazio.
4. **Migrar os fluxos existentes:** requisições e catraca usando os serviços
   centrais, sem mudar suas regras funcionais.
5. **Validar e preparar entrega:** testes de widgets e unitários, análise
   estática, revisão de configuração e validação em homologação.

## Validação

- Testes unitários da sessão, validações de formulário e interpretação de
  respostas, sem dependência de rede real.
- Testes de widgets para login, carregamento, erro, ausência de dados,
  confirmações, logout e estados das operações.
- Análise estática e testes Flutter existentes.
- Verificação manual dos fluxos integrados em homologação, usando configuração
  e credenciais fornecidas pela equipe Protheus; não usar credenciais reais em
  testes versionados.

## Critérios de aceite

- As telas existentes usam a sessão autenticada e não contêm credenciais fixas
  nem montam autenticação por conta própria.
- Logout remove a sessão e retorna à tela de login.
- Falhas de rede, sessão expirada e respostas inválidas são exibidas sem
  apresentar operações como bem-sucedidas.
- As telas compartilham padrões visuais e representam corretamente os estados
  de carregamento, erro e ausência de dados.
- Consultas e Workflow não apresentam conteúdo de exemplo como se fosse dado
  real.
- Os testes cobrem os principais caminhos e erros sem chamar serviços reais.
