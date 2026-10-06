# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Não lançado]

### Adicionado
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
