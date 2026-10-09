# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Não lançado]

## [1.5.0] - 2026-10-09 (teste)

Versão do app: 1.5.0+6.

<!-- TODO #164: incluir aqui o espelho Firestore→RTDB por trigger (branch feat/mirror-trigger) quando o PR for mergeado -->

### Adicionado
- Métricas por atendente no painel gerencial (#124).
- Exportação das métricas em CSV e PDF (#125).
- Métricas de espera (mediana, P90 e faixas) e de re-chamadas (#126).
- Demanda por dia da semana e heatmap dia×hora (#129).
- Tendência diária e comparação com o período anterior nas métricas (#133).
- Alertas operacionais para o dono: espera alta, não comparecimento alto e fila
  parada, com push e configuração por fila (function `evaluateQueueAlerts`, #127).
- Grupos de filas e indicadores por grupo (#130).
- Agendamento por horário (slots diários, fuso `America/Sao_Paulo`): fila em modo
  hora marcada, editor de horários no app e escolha de horário na web (#136).
- Editar e duplicar fila; a criação passou a exigir só o nome, com opções
  avançadas recolhidas, e o botão voltar ficou padronizado (#180).
- Entrada manual pelo operador (cliente sem celular): callable `addManualEntry`,
  botão "Adicionar pessoa" e selo "Balcão" no painel (#190).
- Exclusão robusta de fila e exclusão de conta pelo app, via callables Admin
  `deleteQueue` e `deleteAccount`, com login recente (#191).
- Operador vê o telefone do cliente e liga com um toque (#192).
- Desfazer "Atendido" e "Não compareceu" por 5 s e mensagens de erro específicas
  no painel (#179).
- Cartaz de QR (A4, A5 e cartão de mesa) com impressão e compartilhamento, e link
  curto `qio.web.app/n/{slug}` (callable `resolveSlug`, #197).
- Widget público de espera `/w/{id|slug}`, para embed por iframe (#202,
  `docs/embed.md`).
- Aviso "me avise quando abrir" na web para fila fechada ou pausada (trigger
  `onQueueOpened`, #200).
- Recuperar a própria senha por telefone e nome ao entrar de novo na fila
  (`joinQueue`, #201).
- Expirar entradas esquecidas, limpar a fila ao fechar e reiniciar a senha por
  dia, por fila (function `expireStaleEntries`, #199).
- Contador agregado `meta/waitingCount` na home, sem listener pesado por card
  (function `reconcileWaitingCounts` e backfill, #195).
- Web: espera visível antes de entrar, "Tentar de novo", aviso de falta de
  conexão, wake lock e "Entrar de novo" (#176); landing em `/` e Messaging
  carregado sob demanda (#182).
- App: home enxuta com ações rápidas, busca e ordenação (#183) e painel que
  prioriza a fila no celular, com QR e configurações em tela própria (#184).
- App Check nas callables `joinQueue` e `submitFeedback` com log de chamadas,
  debug token e flags de enforcement por callable (#134, `docs/APPCHECK.md`);
  enforcement continua desligado (`ENFORCE_APP_CHECK=false`).
- Monitoramento técnico (logging estruturado sem PII nas functions) e analytics
  com opt-out no app e na web (#128, `docs/monitoring.md`).

### Segurança e privacidade
- Política de privacidade e termos (minuta técnica) em `/privacidade` e
  `/termos`, aviso no formulário de entrada e links no app (#193,
  `docs/privacidade.md`).
- Retenção real do histórico: `purgeOldHistory` apaga `history` e `feedback` com
  mais de 180 dias; exportação sem telefone por padrão; opção de não guardar
  telefone no histórico (#196).
- Ferramenta de direitos do titular (LGPD): consulta, exportação e eliminação
  por telefone, com auditoria (`findCustomerData`, `exportCustomerData`,
  `eraseCustomerData`, #198).
- Limite de filas por dono (20, só no cliente) e convites de operador restritos a
  contas não anônimas (#181).
- Rules do Firestore: `ownerId`, `deleting` e `alertState` deixam de ser
  escrevíveis pelo cliente (#196).
- `calledAt` passa a usar o relógio do servidor (`ServerValue.timestamp`), sem
  depender do aparelho do operador (#205).

### Alterado
- Limite de horários por fila caiu de 24 para 20 (limite de expressões das rules
  do Firestore); filas existentes com 21–24 seguem funcionando (#196).
- Refactor das functions: `index.js` dividido por domínio e triggers de `entries`
  consolidados em `syncPublicTicket` (4 → 1 invocação por escrita); removidas
  `onEntryCalled`, `onEntryJoined` e `onQueueAdvanced` (#208).
- Refactor da web: `QueuePage` dividida em componentes por fase (#207).
- `QioColors` passou a ser um `ThemeExtension` (`QioPalette`) (#135).
- Fonte única do `firebaseConfig` (service worker gerado no build) e da URL de
  join (#187).
- Ajustes da auditoria da epic #97: voltar preditivo, tour, docs de VAPID,
  contraste, fonte Inter na web e painel (#174).

### Corrigido
- Rules: aceitam `lang` e `nextNotifiedAt` na entry; "Chamar próximo" falhava em
  entradas novas (#114).
- Teste de slot passado em `rules-tests` não depende mais da hora do dia (#194).
- Teste do teto de entries manuais estabilizado (o seed de 1000 entries derrubava
  o emulator, #206).
- Rules rodando em duas passadas, sem functions na primeira, eliminam o flaky de
  `entries` (#132).

### Infra e CI
- CI: lint da web, `dart format`, `firebase-tools` fixo e reuso do build no
  deploy (#175); cobertura de testes no resumo e build de APK debug em PRs que
  mudam dependências (#185).
- Deploy assistido (`workflow_dispatch`, dry-run por padrão, environment
  `production` com aprovação, ordem fixa), `docs/deploy.md` (#204).
- Testes: vitest na web (#178), widget tests das telas principais (#131) e
  goldens em claro/escuro (#137).
- Scripts e documentação de backup, orçamento e restauração (#186, `docs/backup.md`).

### Documentação
- Quadro de qualidade e alinhamento das docs com o `main` (#177,
  `docs/qualidade.md`).
- Roteiro de usabilidade (SUS), comparativo, diagramas, modelo de ameaças e
  limitações (#188).
- Kit do piloto: plano, checklist, treinamento, consentimento, diário e relatório
  (#203, `docs/piloto/`).

## [1.4.0] - 2026-10-06 (teste)

### Adicionado
- Push para o dono e operadores quando alguém entra na fila, com o app fechado
  (`onEntryJoined`; título = nome da fila, corpo com o nome sem telefone, idioma
  do aparelho). Opt-in em Minha conta e pergunta única na home.
- Aviso no celular do cliente com a aba fechada (push web): ativação por botão
  na tela da senha, textos em pt/en/es e "Você é o próximo" (precisa da chave
  VAPID no build da web).
- Identidade da fila: cor (paleta de 8 cores com contraste AA) e logo aparecem
  na página do cliente; o dono escolhe no painel. Logos ficam no Firebase
  Storage (`queue-logos/{queueId}/logo.jpg`).
- Horário de funcionamento: a fila abre e fecha sozinha (dias, abre/fecha, fuso
  de Brasília) pela function `applyQueueSchedules`, a cada 5 minutos; o cliente
  vê "Abre ..." quando está fechada por horário.
- Links de fila (`qio.web.app/q/{id}`) abrem o painel direto no app para dono e
  operador (Android App Links); para quem não é da equipe o app repassa ao
  navegador em `/c/{id}`, que o app não captura.
- Operação da fila: "Chamar de novo" (reenvia o aviso ao cliente e conta as
  chamadas), "Chamar agora" uma pessoa específica e "Mover para o fim" (mantém
  a senha, muda só a ordem). O histórico guarda `recalls` e `skips`.
- Limite de pessoas esperando por fila (`maxWaiting`, validado no servidor pela
  `joinQueue` e nas rules do RTDB); a web mostra "fila lotada" e bloqueia a
  entrada, o painel mostra o contador `n/limite` e permite editar o limite.
- Pausar/fechar com mensagem e previsão de retorno exibidas ao cliente.
- Login: autofill, teclado (próximo/enviar), botão de mostrar senha e
  "esqueci a senha" por e-mail.
- Vibração (haptics) nos botões e em chamar/atendido/não compareceu, com opção
  em Minha conta.
- Aviso de falta de conexão no topo do app.
- Estados vazios e de erro ilustrados, com botão de tentar de novo.
- Skeletons no lugar dos spinners nas listas; web com transições entre fases e
  esqueleto no primeiro carregamento.

### Segurança e release
- Build de release com R8 (minify e shrink de recursos) e Crashlytics; sem
  `android/key.properties` o build de release falha em vez de assinar com a
  chave de debug (`QIO_ALLOW_DEBUG_SIGNING=true` libera para uso local).

### Alterado
- Acessibilidade do app: tiles e cartões lidos como um item só, resumo falado do
  gráfico de picos e testes de tamanho de toque, contraste e texto ampliado.
- Tablets: conteúdo limitado em largura e painel da fila em duas colunas a
  partir de 900 dp.
- Voltar: confirmação ao sair da criação de fila com campos preenchidos e
  bloqueio durante ações no painel; o tour não fecha com o botão voltar.
- Identidade visual: símbolo do Qio (Q com fila de pontos), ícone do app
  (adaptativo e monocromático), splash nativa (Android 12+ e iOS), tela de
  carregamento e logo no login, ícones/favicon/manifest da web, fonte Inter
  embutida, nome do app "Qio".
- Contraste AA nos dois temas e acessibilidade da web (zoom, aria-live, foco).
- Transições de página e navegação de login/logout pelo estado de auth.

## [1.3.0] - 2026-10-06 (teste)

### Adicionado
- Tour de onboarding para novos donos (botão de criar fila, QR code e "Chamar
  próximo"), com opção de pular.
- Exportação do histórico em CSV e PDF, respeitando os filtros ativos.
- Modo escuro no app (Sistema/Claro/Escuro em Minha conta) e na página do
  cliente.
- Internacionalização em português, inglês e espanhol no app e na web, com
  seletor de idioma.
- Avaliação pós-atendimento: o cliente dá de 1 a 5 estrelas (callable
  `submitFeedback`); o dono vê a média e a nota por atendimento no histórico.
- Tela de Métricas: espera e atendimento médios, taxa de não comparecimento,
  gráfico de demanda por horário e filas mais ativas.

### Corrigido
- Tour de onboarding só avançava tocando no destaque; agora avança tocando em
  qualquer ponto da tela.
- Web: seletor de idioma e botão de tema cobriam o título da fila no celular;
  a tela do cliente ficava presa em "É a sua vez!" depois do atendimento
  porque o RTDB cancela o listener da entry removida (tratado no `useQueue`).
- Login com Google na release: SHA-1/SHA-256 da chave de release registrados no
  Firebase e `google-services.json` atualizado com os clientes OAuth.

### Requer deploy
- `firebase deploy --only functions:submitFeedback` e depois
  `--only firestore:rules` (a avaliação não funciona antes disso).
- A web nova sobe pelo CI no push para `main` (se `FIREBASE_TOKEN` existir).

### Limitações conhecidas
- Notificação push enviada pela function continua em português.
- Telas novas do app (modo escuro, idiomas, métricas) sem teste visual em
  dispositivo.

## [1.2.0] - 2026-10-01 (teste)

### Adicionado
- Entrada na fila pela Cloud Function `joinQueue` (callable): reaproveita a
  entry ativa do mesmo usuário, recusa telefone já presente na fila, valida
  telefone opcional e aplica rate limit configurável
  (`JOIN_RATE_LIMIT_MAX` e `JOIN_RATE_LIMIT_WINDOW_MIN` em `functions/.env`).
  Bloqueia fila pausada ou fechada no servidor.
- Entries privadas no RTDB com espelho público (`syncPublicTicket`): o cliente
  lê só o próprio registro e o que é público da fila.
- Validação de entries nas rules do RTDB (nome até 60 caracteres, campos e
  status permitidos); testes das rules cobrindo entries, tickets e rate limit.
- App Check com reCAPTCHA Enterprise na web (opcional, via
  `VITE_RECAPTCHA_SITE_KEY`).
- Tela de Conta no app (dados do usuário e sair).
- Aviso in-app para dono e operador quando alguém entra na fila (sem som no
  Android).
- Tela de histórico com métricas (atendidos, não compareceram, desistências).
- Estimativa automática de tempo de atendimento (`updateServiceEstimate` grava
  `avgServiceMinAuto` a cada registro de histórico).
- PWA na web: manifest, ícones e banner de instalação após entrar na fila (sem
  cache offline).
- Cartaz de QR imprimível no app, com presets de cor e checagem de contraste.
- Desistências (`left`) arquivadas no histórico e removidas do RTDB.

### Alterado
- Entrada na fila deixa de escrever direto no RTDB: a web usa a `joinQueue` e
  o contador de senha passa a ser incrementado no backend.
- Fim de atendimento mais robusto: `finishEntry` atômico, `deleteQueue` em
  ordem definida e contagem de espera sem dados pessoais.
- Web mantém a tela "Você saiu da fila" depois de sair.

### Corrigido
- Fila órfã: se o espelho no RTDB falha ao criar a fila, o Firestore sofre
  rollback; ao abrir a fila o app repara o espelho ausente (`ensureMirror`).
- `joinQueue` publicada com invoker público (antes recusava chamadas web).
- Nome do cliente limitado a 60 caracteres na web, igual às rules.

### Limitações conhecidas
- App Check: requisições ainda retornam 403 em produção (pendente).
- Push web não chega com a aba em segundo plano: o build não tem
  `VITE_VAPID_KEY`.
- Aviso in-app ao dono só funciona com o painel aberto.
- Deploy automático do hosting não roda sem o secret `FIREBASE_TOKEN`; rules e
  functions também não têm deploy no CI.

## [1.1.0] - 2026-09-30 (teste)

### Adicionado
- Operadores: o dono gera um código de convite (validade padrão de 24 h),
  aprova ou recusa pedidos e remove operadores. O operador vê a fila só com os
  controles de atendimento (chamar próximo, atendido, não compareceu).
- Home separa as filas em "Sou dono" e "Sou operador" e mostra pedidos
  pendentes, recusados e removidos.
- Operador removido com o painel aberto vê "Acesso encerrado" e volta à home.
- Histórico registra quem chamou (`calledBy`) e quem finalizou (`operatorId`).
- Testes das rules do Firestore e do RTDB com o emulator (`rules-tests/`), no CI.
- Modo emulator no app (`--dart-define=USE_EMULATORS=true`) e na web
  (`VITE_USE_EMULATORS=true`) para testes locais.

### Alterado
- `callNext` reserva a senha por transação: dois atendentes nunca pegam a mesma.
  `meta/serving` só avança.
- Rules endurecidas: posse da fila no RTDB, permissões de operador e validação
  do registro de histórico criado por operador.
- Erros de login exibidos em português.

### Corrigido
- Web: spinner infinito no primeiro acesso pelo QR (listeners anexados antes
  do login anônimo). Tela "Não foi possível conectar" quando a leitura falha.
- Convite gravado em um único batch (sem código órfão).
- Excluir a fila agora remove também o contador de senhas no RTDB.
- CI: o deploy do hosting era pulado sem aviso.

### Limitações conhecidas
- Push com a aba em segundo plano ainda não chega: a Cloud Function
  `onEntryCalled` foi publicada (plano Blaze), mas o build da web não tem
  `VITE_VAPID_KEY`, então o cliente não registra token FCM.
- App Check desativado em produção (sem chave reCAPTCHA no build).
- Fila pausada é bloqueada só na interface; o cliente pode alterar a própria
  entry no RTDB.
  Nota (1.2.0): a partir da 1.2.0 a `joinQueue` também bloqueia fila pausada ou
  fechada no servidor.
