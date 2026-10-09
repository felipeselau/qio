# Qio — Claude Code project guide

Sistema de filas presenciais. Owner cria filas no app Flutter e gera QR; cliente
entra pela web sem instalar nada. TCC.

## Módulos

| Path         | Stack                                             | Papel |
| ------------ | ------------------------------------------------- | ----- |
| `app/`       | Flutter 3.x + Firebase (Auth, Firestore, RTDB)    | App do proprietário |
| `web/`       | React 19 + TS + Vite + Firebase JS SDK            | Página do cliente (navegador) |
| `functions/` | Cloud Functions (Node 22, firebase-functions v2) | Trigger RTDB → push FCM |

## Comandos

### web/
```bash
npm ci
npm run dev        # dev server
npm run build      # tsc -b && vite build  (roda no CI)
npm run lint       # oxlint
```

### app/
```bash
flutter pub get
flutter analyze lib test   # roda no CI
flutter test               # roda no CI
flutter run
flutter test --update-goldens --tags golden   # regenera app/test/goldens
```
Goldens (Ahem, tolerância 0,5%, `app/test/goldens/README.md`) rodam no `flutter test`
e no CI; mudança visual intencional exige regenerá-los no PR.

### functions/
```bash
npm ci
npm test           # node --test (lógica pura em src/*.js)
```

### rules-tests/
```bash
npm ci
npm test           # sobe emulators firestore+database e roda node --test (roda no CI)
```
Precisa de `firebase-tools` e Java 21+. Testes em `rules-tests/test/`. Sobe também
os emulators `functions` e `auth` (`join-callable.test.js` chama a callable
`joinQueue`), então rode `npm ci` em `functions/` antes. Roda com
`--test-concurrency=1` (arquivos compartilham o mesmo namespace do RTDB). A porta
5001 do emulator de functions precisa estar livre.
`npm test` roda em duas passadas: `test:rules` (firestore+database+storage, sem
functions) e `test:callable` (com functions, só `join-callable.test.js`). Os
triggers (`syncPublicTicket` remove `entries/{id}` após `left`) reagiam tarde ao
seed do teste seguinte e apagavam a entry (flake em `database.test.js`); não
volte a subir functions junto das rules.

Sempre rode lint + analyze + test antes de dar uma tarefa como concluída (ver
`~/.claude/CLAUDE.md`). Não há testes em `web/`. Contagem de testes, cobertura e limitações
conhecidas: `docs/qualidade.md`.

## Modelo de dados

- **Firestore** (durável, lado owner): `owners/{uid}`, `queues/{queueId}`,
  `queues/{queueId}/history/{entryId}`. Rules: `firestore.rules`.
- **RTDB** (tempo real): `queues/{queueId}/meta`, `queues/{queueId}/entries/{id}`,
  `queues/{queueId}/public/{id}`, `owners/{queueId}/ownerUid` (espelho de posse p/
  rules), `tickets/{queueId}` (contador de senha, incrementado por transação na
  callable `joinQueue`), `rateLimits/{queueId}/{uid}` (timestamps dos joins).
  Rules: `database.rules.json`.
- Rules do RTDB validam `queues/{id}/entries/{entryId}`: `ticket` número, `status` ∈ waiting/called/served/no_show/left, `uid` imutável, `name` 1–60 chars e `phone` vazio ou `(DD) 9999-9999`/`(DD) 99999-9999` (os dois só são checados na criação ou quando mudam), campos fora de ticket/name/phone/uid/fcmToken/status/joinedAt/calledAt/operatorId (mais os de ordem/push e `slotId`/`slotStart`) são rejeitados. `.validate` não roda em `remove()`.
- O app faz **dual-write**: Firestore (fonte da verdade) + espelho no RTDB
  (`meta` + `owners/{queueId}`). `_ensureOwnerMirror` reconcilia antes de escritas;
  `_ensureOwnerMirrorIfOwner` fica em cache por sessão (`uid/queueId`).

## Entrada na fila (join)

- O cliente web **não escreve** em `entries` nem em `tickets`: chama a callable
  `joinQueue` (`functions/index.js`, região us-central1) com `{queueId, name, phone}`.
  Ela exige auth, valida nome (1–60) e telefone (vazio ou `(00) 00000-0000`),
  exige `meta/status == 'open'`, devolve a entry ativa existente do mesmo `uid`
  (`existing: true`), recusa telefone já ativo na fila (`already-exists`), aplica
  rate limit de 3 joins / 10 min por `uid` (`resource-exhausted`) e cria a entry
  com ticket por transação Admin. Lógica pura em `functions/src/join.js`.
- `entries` só é legível por dono, operador (`operatorUids`) e pelo autor
  (`uid == auth.uid`, por entry). O cliente só altera a própria entry para
  `status: 'left'` ou `fcmToken` (ticket/name/phone/joinedAt/calledAt/operatorId
  imutáveis para ele); dono/operador mantêm acesso total.
- Espelho público sem PII: trigger `syncPublicTicket` grava
  `queues/{id}/public/{entryId} = {ticket, status}` enquanto a entry está
  `waiting`/`called` e remove nos demais casos. `public` é legível por qualquer
  autenticado e não tem escrita por cliente. O web calcula posição a partir dele.
- `ENFORCE_APP_CHECK` (`functions/.env`, commitado com `false`) liga
  `enforceAppCheck` nas callables `joinQueue` e `submitFeedback` (nunca em RTDB/
  Firestore). Só mude para `true` depois de ativar App Check no web
  (`VITE_RECAPTCHA_SITE_KEY`), registrar o app no console e medir ≥95% das chamadas
  com token por 3–7 dias. Passo a passo e rollback em `docs/APPCHECK.md`.
- Backfill único do `public` para entries já existentes:
  `node functions/scripts/backfill-public.js` (credencial padrão do Admin SDK,
  ex. `GOOGLE_APPLICATION_CREDENTIALS`/`GOOGLE_CLOUD_PROJECT=qio-app`).
- **Ordem de deploy**: functions → backfill → hosting → database rules. Rules por
  último, senão o web antigo perde a escrita/leitura antes de o novo estar no ar.
  APK v1.1.0 (dono/operador) continua compatível com as rules novas. Web antigo em
  cache falha ao entrar na fila até recarregar.

## Limite de fila e mensagem de status

- `queues/{id}/meta/maxWaiting` (0 = sem limite, 1–1000), `statusMessage` (≤120) e
  `resumeAt` (ms) são escritos só pelo dono e espelham o doc do Firestore. A
  `joinQueue` conta entries `waiting` e recusa com `resource-exhausted` +
  `details.reason == 'queue-full'` (lógica em `functions/src/capacity.js`); quem
  já tem entry ativa recebe a própria. Joins simultâneos podem passar do limite
  em uma ou duas vagas (sem transação de contagem). O web também bloqueia o botão
  usando `public/` (`useQueue.full`).
- Pausar/fechar no app abre um diálogo com mensagem e horário de retorno; reabrir
  limpa os dois. Deploy: functions (`joinQueue`) antes das rules do RTDB.

## Agendamento por horário (slots)

- `queues/{id}.mode` (`'queue'` padrão | `'schedule'`) e `slots = [{id, start:'HH:mm',
  capacity 1–50}]` (máx. 24, horários únicos, ids estáveis) no Firestore (fonte da verdade,
  só o dono escreve). Espelho no RTDB: `meta/mode` e `meta/slots/{slotId} = {start,
  capacity}` (dual-write em `QueueService.updateModeAndSlots`/`createQueue`). Os slots são
  **diários** (repetem todo dia) e o fuso é fixo `America/Sao_Paulo`. Filas antigas e
  entries antigas não têm `mode`/`slotId` e funcionam como sempre.
- `joinQueue` (lógica pura em `functions/src/slots.js`): em `mode == 'schedule'`
  `slotId` é obrigatório (`invalid-argument`, `details.reason == 'slot-required'`; slot
  inexistente: `slot-invalid`). Aceita o slot até 15 min depois do início
  (`SLOT_GRACE_MS`); depois disso `failed-precondition` + `slot-passed`. Conta entries
  `waiting`/`called` com o mesmo `slotId` (sem olhar `slotStart`: entries ativas só existem no dia; editar o horário de um slot não zera a contagem e o editor avisa); lotado vira
  `resource-exhausted` + `details.reason == 'slot-full'`. Quem já tem entry ativa recebe a
  própria (antes dessas checagens). Grava `slotId`, `slotStart` (ms do slot de hoje) e
  `order = slotStart`, então a ordem de espera `(order ?? joinedAt, ticket)` já cobre.
  `public/{id}` ganha `slotId`. Modo `queue` ignora `slotId`. `maxWaiting` continua valendo.
- Sem transação de contagem: joins simultâneos podem passar a capacidade em 1–2 vagas
  (igual `maxWaiting`).
- Rules: RTDB valida `meta/mode` e `meta/slots` (só dono; start `HH:mm`, capacity 1–50, id
  `[A-Za-z0-9_-]{1,20}`), mas **não limita a 24** (RTDB rules não têm `numChildren`; a
  function corta em 24 ao ler). `slotId`/`slotStart` da entry são imutáveis para o cliente
  e há `.indexOn` em `slotId`. Firestore valida `mode`, `slots` (lista ≤ 24, `start`
  `HH:mm`, `capacity` int 1–50); não valida chaves extras, `id` nem unicidade (estourava o
  limite de 1000 expressões das rules) — o app valida tudo isso antes de gravar.
- App: seletor de modo + lista de horários (`SlotsEditor`) na criação e no painel
  (`QueueSlotsTile`); horário fora da janela de funcionamento só gera aviso no editor.
  Painel mostra o horário em cada entry. Web: lista de horários na entrada (cheios e
  passados desabilitados, contagem via `public/` por `slotId`),
  "Seu horário: HH:mm" na senha e sem estimativa de espera no modo schedule.
- **Deploy**: functions (`joinQueue`) → hosting → rules do RTDB → rules do Firestore → APK.
  Web antigo em modo schedule não envia `slotId` e recebe `slot-required` (a web nova mostra "recarregue a página" nesse caso). Se `meta/mode` não existe, a `joinQueue` lê `mode`/`slots` do doc do Firestore (fail-closed); `ensureMirror` reconcilia `mode`/`slots` do RTDB com o Firestore.
- **Fora de escopo**: slots por data/calendário, filas separadas por slot, reagendamento
  pelo cliente, lembrete 10 min antes (function agendada), recorrência por dia da semana e
  integração com `applyQueueSchedules` (o horário de funcionamento continua mandando em
  open/closed).

## Editar e duplicar fila

- `QueueService.updateQueueInfo` (nome 1–60, descrição ≤300, tempo médio 1–240; validação
  em `models/queue_info.dart`, erro `FormatException`) grava no Firestore e faz um único
  `update` em `meta` do RTDB. O `queueId` (e o QR) não muda. Painel: tiles "Editar fila" e
  "Duplicar fila" (só dono).
- `duplicateQueue` cria fila nova `<nome> (cópia)` copiando descrição, tempo médio, limite,
  grupo, modo/slots, horário de funcionamento, cor e alertas. Não copia entries, history,
  operadores, logo, mensagem de status nem `alertState`.
- Rules validam `name`/`description`/`avgServiceMin` no Firestore (create, e update só de cada
  campo que mudou, para não travar docs legados) e em `meta/{name,description,avgServiceMin}`
  no RTDB (valor legado inalterado passa). `updateQueueInfo` grava só os campos alterados,
  RTDB primeiro e Firestore por último; `ensureMirror` repara divergência de
  name/description/avgServiceMin no `meta` (normalizados por `QueueInfo.forMirror`: nome
  truncado a 60 ou "Fila", descrição a 300, tempo fora de 1–240 vira o default). O tempo
  manual só vale até existir `avgServiceMinAuto`. O Firestore limita a 1000 expressões por avaliação e `validSlots` já consome quase
  tudo: cuidado ao somar checagens no `update` de `queues/{id}`. Deploy: rules antes do APK.

## Criação de fila e botão voltar

- `CreateQueueScreen` exige só o nome; descrição, tempo médio, limite, grupo e modo/slots
  ficam em "Opções avançadas" (`ExpansionTile` com `maintainState`, reabre sozinho se um
  campo avançado for inválido). Tempo médio vazio vira o default único
  `defaultAvgServiceMin` (10, em `models/queue_info.dart`) dentro de `createQueue`.
- Voltar do painel/criação/edição é `QueueBackButton` (`BackButton` do Material, tooltip e
  semântica localizados, usa `maybePop` e portanto respeita o `PopScope`).

## Ordem da fila, chamar de novo e mover

- A ordem de espera é `(order ?? joinedAt, ticket)`. "Mover para o fim" grava
  `entries/{id}/order = now` e `skips++` (a senha não muda). `public/{id}` agora é
  `{ticket, status, order}` (`functions/src/ticket.js`); o web calcula a posição
  com `positionInQueue` e cai para a comparação por senha se `order` faltar.
- "Chamar de novo" grava `recalledAt = now` e `recalls++`; `onEntryCalled`
  reenvia o push quando `recalledAt` muda (`shouldRenotify`) e o web repete
  som/vibração. "Chamar agora" reaproveita `_claimEntry`.
- Só dono/operador escrevem `order/recalls/skips/recalledAt` (o cliente tem esses
  campos na lista de imutáveis das rules). `_archiveEntry` só envia `recalls` e
  `skips` quando > 0 (permission-denied no history é engolido: faça o deploy das
  rules do Firestore antes de distribuir o APK novo).

- "Atendido"/"Não compareceu" no app são adiados 5 s (SnackBar "Desfazer"); o
  flush ocorre ao agendar outra ação, chamar alguém, sair da tela ou pausar o
  app. Kill forçado dentro dos 5 s perde a ação pendente e a entry segue na fila
  (seguro). `finishedAt` segue `serverTimestamp`: o tempo de atendimento inclui até
  ~5 s da janela de desfazer (viés pequeno e conhecido; as rules do history não
  validam `finishedAt` e relógio de cliente distorceria ordenação/estimativa).
- `_finishEntry`: `get` valida `called` → `_archiveEntry` → transação de status
  (idempotente; `null` devolve `success(null)` p/ forçar round-trip com cache
  frio) → `remove`. Archive falho deixa a entry `called` (repetível). Corrida
  residual: outro operador finalizar com resultado diferente entre o `get` e a
  transação. Timeout de 10 s vira "sem conexão" e a entry volta à lista.

## Estimativa de espera automática

- `queues/{id}/meta/avgServiceMinAuto` (RTDB) é escrito só pela function
  `updateServiceEstimate` (Admin). Dono/operador/cliente não escrevem (rules).
- Convenção: **tempo de atendimento** = `finishedAt − calledAt` (igual a `service` em
  `app/lib/services/history_metrics.dart`), só `result == 'served'`. Não usa `joinedAt`.
- Cálculo em `functions/src/estimate.js`: últimas 20 amostras válidas, descarta
  > 3× a mediana, média com 1 casa; menos de 3 amostras → não grava.
- Trigger `onDocumentCreated('queues/{id}/history/{entryId}')`; não recria `meta`
  se a fila não existe no RTDB.
- Web usa `avgServiceMinAuto ?? avgServiceMin ?? 10` (`useQueue.ts`).
- Query exige índice composto `history: result ASC, finishedAt DESC`
  (`firestore.indexes.json`). Deploy manual: `firebase deploy --only
  firestore:indexes` e `--only functions:updateServiceEstimate`.

## Feedback pós-atendimento

- Web: quando a entry some do RTDB depois de ter estado `called`, mostra 1–5 estrelas
  + comentário opcional (≤300). `entryId` pendente fica em `localStorage`
  (`qio:feedback`) até enviar ou pular. `no_show` também vê a tela; a callable
  responde `failed-precondition` e o web trata como concluído, sem erro.
- Callable `submitFeedback` (`functions/index.js`, lógica pura em
  `functions/src/feedback.js`): exige auth, `history/{entryId}` existente com
  `result == 'served'` e grava `queues/{id}/feedback/{entryId}` com `create`
  (idempotente: 2ª avaliação não sobrescreve). O `entryId` (push key) é a
  capacidade; não há `uid` no history. Respeita `ENFORCE_APP_CHECK`.
- Firestore `queues/{id}/feedback/{entryId}` `{rating, comment, uid, createdAt}`:
  só o dono lê/apaga; ninguém escreve por cliente (rules). `deleteQueue` apaga.
- App: `HistoryScreen` mostra média/contagem (respeitando os filtros) e `★ n` por
  atendimento. Deploy: `--only functions:submitFeedback` e depois `--only firestore:rules`.

## Grupos de filas

- Uma fila está em no máximo um grupo; máx. 20 grupos por dono (checado no app
  em `GroupService.createGroup`, não nas rules). Fonte da verdade:
  `queues/{id}.groupId` (Firestore); o grupo é `owners/{uid}/groups/{gid} =
  {name (1–40), createdAt}`, só o dono lê/escreve. Operadores não veem grupos.
- Excluir grupo = batch que apaga `groupId` das filas (`FieldValue.delete()`) e o
  doc. `groupId` órfão (grupo inexistente) vale como "sem grupo" na leitura
  (`resolveGroupId`).
- `MetricsScreen` filtra por escopo (todas/grupo/fila) com `filterByScope`
  (`queue_analytics.dart`) antes de `buildMetricsReport`; o comparativo entre
  filas (`compareQueues`) só aparece no escopo de grupo. CSV/PDF levam o nome do
  escopo (`MetricsReport.scopeLabel`) no cabeçalho e no nome do arquivo.
- **Ordem de deploy**: rules do Firestore (`firebase deploy --only
  firestore:rules`) → APK. APK novo com rules antigas recebe `permission-denied`
  nas operações de grupo (o app mostra mensagem) e ao gravar `groupId`.

## Alertas operacionais

- Opt-in por fila (desligado por padrão), só o dono recebe. Config em
  `queues/{id}.alerts = {enabled, maxWaitMin 1–240, maxNoShowPct 1–100, idleMin
  5–240, cooldownMin}` (Firestore, dono escreve; rules validam). Sem espelho no RTDB.
  `alertState = {waitAt, noShowAt, idleAt}` é escrito só pela function (rules
  bloqueiam o cliente), em transação antes do envio, para não duplicar.
- `evaluateQueueAlerts` (a cada 5 min, `functions/src/alerts.js`) só avalia filas com
  `alerts.enabled` e `status == open`. Regras: espera estimada
  (`waiting × (avgServiceMinAuto ?? avgServiceMin ?? 10)`), no-show do dia em
  `America/Sao_Paulo` (mínimo 5 atendimentos) e fila parada (`max(meta/updatedAt,
  menor order em espera)`; `updatedAt` muda a cada chamada, mas também em edições do
  dono, o que só reduz alertas). Lê só `meta` e `public/` (sem PII), com
  concorrência 5 e `timeoutSeconds: 300`. Cooldown padrão 30 min (mín. 5) por regra/fila.
- Push reaproveita `push.js` (`data.type = 'queue-alert'`, tag `queueId-regra`) e
  respeita `owners/{uid}.notifyAlerts` (padrão ligado; switch na tela de alertas).
  `notifyAlerts == false` e ausência de tokens são checados antes da transação, então
  não consomem cooldown. Se o FCM falhar depois da transação de `alertState`, o alerta
  se perde até o próximo cooldown. Toque abre o painel.
- Deploy (Blaze + Cloud Scheduler): `--only functions:evaluateQueueAlerts` →
  `--only firestore:rules` → distribuir o APK.

## Limites e validações

- **Limite de filas por dono:** `maxQueuesPerOwner = 20` (`queue_service.dart`).
  `QueueService.createQueue` conta as filas do dono (`count()`) no início e lança
  `QueueLimitReached`; a tela de criação mostra `queueLimitReached` (pt/en/es).
  Vale **só no cliente**: rules do Firestore não contam documentos, então um
  cliente adulterado ainda passa do limite (contador/callable seria trabalho
  futuro). `duplicateQueue` passa por `createQueue` e herda o limite; `queueErrorMessage`
  (`queue_info_fields.dart`) traduz `QueueLimitReached` na criação e no duplicar.
  Novos fluxos de criação devem chamar `ensureUnderQueueLimit`.
- **Convites só para contas não anônimas:** `notAnonymous()` em `firestore.rules`
  (`sign_in_provider != 'anonymous'`) é exigido para ler `operatorInvites/{code}`
  e criar/recriar `operatorRequests/{uid}`. O app só autentica com e-mail/Google
  (`auth_service.dart`), então o fluxo de operador não muda.
- **Ordem de deploy:** indiferente. O limite de filas é só do cliente, então a
  ordem das rules não afeta a mensagem. As rules só mudam o comportamento para
  contas anônimas. APK antigo + rules novas: operador por e-mail/Google segue
  funcionando. APK novo + rules antigas: só falta o endurecimento dos convites.
  As rules não quebram nenhum APK.

## Operadores

- **Convite**: `operatorInvites/{code}` (6 chars, validade padrão 24 h) é a fonte
  da verdade. `queues/{id}.operatorInviteCode`/`operatorInviteExpiresAt` são só
  ponteiro p/ o dono exibir/revogar; os dois são gravados no mesmo batch. Não há
  link de convite: o operador digita o código no app.
- **Pedido**: `queues/{id}/operatorRequests/{uid}` com status
  `pending → approved | rejected | removed`. Só o dono muda status (rules).
- **Operador ativo**: `queues/{id}/operators/{uid}`. Home do operador usa
  `collectionGroup` filtrado por `uid`.
- **Espelho RTDB** `queues/{id}/operatorUids/{uid}: true`: escrito pelo dono em
  `syncOperatorMirror` ao aprovar/remover. Rules do RTDB usam esse espelho p/
  liberar `meta/serving`, `meta/updatedAt` e `entries` ao operador. Remover o
  operador apaga do espelho → perde acesso na hora; o painel escuta
  `operators/{uid}` e fecha com aviso.
- `callNext` reserva a entry por transação (`_claimEntry`) e avança
  `meta/serving` por transação (nunca volta). Histórico grava `calledBy` e
  `operatorId`; rule exige `operatorId == auth.uid` p/ operador.
- Home do app: busca/ordenação (> 5 filas) valem só para as filas de dono; a
  seção "Sou operador" não é filtrada nem ordenada. Cards de dono têm atalhos
  de pausar/reabrir e QR; os de operador não.

## Fluxo de estados da entry

`waiting → called → served | no_show` (owner) ou `→ left` (cliente).
`served`/`no_show` arquivam em `history/` e removem do RTDB. `_finishEntry` faz
(1) `_archiveEntry` (history `set`; `permission-denied` em re-tentativa é tratado
como sucesso, pois o doc já existe), (2) update de status/operatorId, (3) remove.
`left`: o trigger `syncPublicTicket` grava `history/{entryId}` com
`result: 'left'` via Admin (só se o doc da fila existir; `create` idempotente),
remove `entries/{id}` e `public/{id}` do RTDB. A rule de create de history do
operador segue restrita a `served`/`no_show`. O app conta `left` como
"Desistiram" (não entra na taxa de no_show). Web limpa o `entryId` de
`localStorage` quando a entry some do RTDB (`useQueue.ts`) e mantém a tela
"Você saiu da fila" com estado local (`hasLeft`) após `leaveQueue`.
- `watchWaitingCount` (home) lê `queues/{id}/public` (sem PII), não `entries`.
- O dono ainda pode remover `public` (rule só permite delete); as rules não mudaram
  com a exclusão via callable (Admin ignora rules, nada foi afrouxado).

## Exclusão de fila e de conta

- Callables Admin em `functions/index.js` (us-central1, timeout 540 s), lógica pura e
  ordem em `functions/src/delete.js` (deps injetadas; testes em
  `functions/test/delete.test.js`; emulator em `rules-tests/test/delete-callable.test.js`).
  O app chama via `app/lib/services/delete_service.dart` (`cloud_functions`);
  `QueueService.deleteQueue(queueId)` só delega a ele.
- `deleteQueue({queueId})`: só o dono (`queues/{id}.ownerId == auth.uid`, senão
  `permission-denied`; `queueId` precisa casar `[A-Za-z0-9_-]{1,128}`). Ordem: (1) marca
  `deleting: true` + `status: 'closed'` no doc e no `meta` (o `joinQueue` recusa
  `meta/deleting`; as rules do RTDB impedem o dono de escrever em `meta` enquanto
  `meta/deleting == true`; `applyQueueSchedules` ignora filas `deleting`); (2) RTDB
  `entries`, `public`, `operatorUids`, `tickets/{id}`, `rateLimits/{id}` e só então
  `meta`; (3) `recursiveDelete` de cada subcoleção de `queues/{id}`; (4) convites
  `operatorInvites` com `queueId == id` e `ownerId == dono` (consulta, não confia no
  `operatorInviteCode`); (5) Storage `queue-logos/{id}/` no bucket
  `STORAGE_BUCKET` || bucket do app Admin || `qio-app.firebasestorage.app`; bucket
  inexistente gera log de erro `delete-queue:bucket-missing` e a exclusão segue; (6) RTDB
  `owners/{id}`; (7) `recursiveDelete` do doc da fila (pega subcoleções criadas na janela),
  por último. Falhou no meio: o doc segue vivo e o dono repete a chamada (idempotente;
  doc já inexistente devolve `alreadyGone: true`). O app esconde filas `deleting` da home.
- `deleteAccount()`: autenticado. Apaga todas as filas do uid (mesma rotina), remove
  `operators`/`operatorRequests` do uid em filas de terceiros (collectionGroup por
  `uid` + `operatorUids/{uid}` no RTDB; a fila alheia fica intacta), depois
  `owners/{uid}` recursivo (devices, groups) e por fim `auth.deleteUser`. Se qualquer
  fila ou vínculo falhar, **não** apaga owner nem conta e responde `aborted` com
  `details.reason == 'partial'`; repetir conclui. Login recente é exigido no
  **servidor** (`assertRecentLogin`: `auth_time` de até 300 s, senão `failed-precondition`
  com `details.reason == 'recent-login'`, que o app trata pedindo nova reautenticação) e
  também no **cliente** (`AccountScreen` → `DeleteAccountDialog`: confirmação digitando EXCLUIR
  ou o e-mail, senha ou Google de novo e só então a callable; ao fim, `signOut`).
- Limites: histórico no `history` de filas alheias com `operatorId`/`calledBy` do uid
  e `feedback.uid` de avaliações dadas por esse uid como cliente não são varridos; uma
  entry criada por join concorrente durante a exclusão pode sobrar por instantes
  (`joinQueue` recusa `meta/deleting`; a janela é o join já em andamento).
- App Check: `deleteQueue`/`deleteAccount` usam `ENFORCE_APP_CHECK_DELETE` e **não**
  herdam `ENFORCE_APP_CHECK` (o app Flutter não usa App Check). Mantenha `false`.
- Deploy: `--only functions:deleteQueue,functions:deleteAccount` (e
  `functions:applyQueueSchedules`) **antes** de distribuir o APK; o APK novo não
  apaga mais direto no Firestore/RTDB.

## Gotchas

- Aviso ao dono quando alguém entra na fila (som + vibração + SnackBar) é
  in-app: `QueuePanelScreen` assina `watchEntries` e usa `entry_diff.dart`. Só
  funciona com o painel aberto; push com o app fechado é trabalho futuro.
- Painel (dono/operador): `WaitingTile` e `CurrentCalledCard` mostram o telefone e o
  `PhoneCallButton` abre `tel:` (`phoneToTelUri` em `services/phone_call.dart`; só com
  10–11 dígitos; `UrlLauncher` injetável). Telefone nunca aparece em `public/` nem na web.
- `web/src/lib/messaging.ts`: `getMessaging()` lança em navegadores sem suporte a
  FCM. Use sempre `await getMessagingSafe()` (assíncrono, import dinâmico via
  `messagingModule.ts`): `null` (em cache) = sem suporte; falha de rede ao baixar o
  chunk rejeita com `MessagingLoadError` e não é cacheada (retry). Nunca importe
  `firebase/messaging` estaticamente nem chame `getMessaging` no topo de um módulo.
- A landing `/` carrega o bundle inteiro (Auth/Database/Functions/App Check): a
  `QueuePage` não usa `React.lazy` porque o caminho do QR é o principal e o lazy
  adicionaria uma ida e volta de rede nele.
- Landing em `/` (`web/src/routes/Landing.tsx`); `*` mostra "link inválido" só
  para caminhos desconhecidos. O link do app do dono só aparece se
  `VITE_OWNER_APP_URL` (https) estiver definida.
- FCM é **opcional**: sem `VITE_VAPID_KEY` o app funciona só com alerta na página.
  App Check é opcional sem `VITE_RECAPTCHA_SITE_KEY`; usa **reCAPTCHA Enterprise**
  (Fraud Defense), não v3. A chave não aceita `localhost` e não roda com
  emulators. No CI, as chaves vêm de `vars.VITE_RECAPTCHA_SITE_KEY` e
  `vars.VITE_VAPID_KEY` (GitHub → Actions → Variables). `VITE_APPCHECK_DEBUG_TOKEN`
  (só `npm run dev`, ignorado em produção) habilita debug token. O app Flutter não usa App
  Check: APK fora da Play Store não passa no Play Integrity, então nunca ligue
  enforcement em RTDB/Firestore, só nas callables `joinQueue` e `submitFeedback` (chamadas só pela web).
- PWA instalável (`web/public/manifest.webmanifest` + ícones PNG) **sem cache
  offline e sem service worker próprio**: a fila é tempo real e bundle velho em
  cache é risco. Banner via `useInstallPrompt.ts` (só aparece na fase `ticket`).
  O Chrome pode não disparar `beforeinstallprompt` sem SW com `fetch` handler
  cobrindo `/`; o menu "Instalar app" e o fluxo iOS funcionam só com o manifest.
- `firebaseConfig` tem fonte única em `web/src/firebaseConfig.ts` (`firebase.ts`
  só acrescenta `measurementId` via env). O service worker é gerado: o plugin
  `web/vite-plugins/swConfig.ts` renderiza
  `web/vite-plugins/firebase-messaging-sw.template.js` (placeholder
  `__FIREBASE_CONFIG__`) em `dist/firebase-messaging-sw.js` no build e o serve
  no dev server. Não crie `web/public/firebase-messaging-sw.js`. Mudanças no
  config valem para os dois só após novo build.
- URL de join: `https://qio.web.app/q/{queueId}` (hosting site `qio`). Fonte por
  módulo: `functions/src/urls.js` (`joinUrl`) e `app/lib/services/join_url.dart`
  (`joinUrl`, `clientUrl`). `functions/test/urls.test.js` falha se host/path
  divergirem entre os dois e o `AndroidManifest.xml` (App Links), ou se alguém
  voltar a hardcodar o host nesses arquivos. O web não monta essa URL.
- `web/src/lib/useQueue.ts`: listeners do RTDB só são anexados com `ready`
  (auth anônima concluída). Anexar antes faz a leitura ser negada e o `onValue`
  morre sem retry → spinner infinito no primeiro acesso pelo QR.
- Deploy hosting é automático no push p/ `main` (`.github/workflows/ci.yml`) **só
  se** `secrets.FIREBASE_TOKEN` existir; sem ele o job passa verde com um warning
  e o site **não** é atualizado. Confira o bundle publicado em `qio.web.app`.
  Functions e rules **não** têm deploy no CI.
- `FIREBASE_TOKEN` está obsoleto; a migração para WIF/service account está na
  issue #166. O CI usa `firebase-tools` fixo (15.33.0) e o deploy reaproveita o
  artefato `web-dist` do job `web`.
- Projeto no plano **Blaze** desde 01/10/2026; `onEntryCalled` publicada. A
  `VITE_VAPID_KEY` já está nas Actions variables e no bundle publicado. Falta o
  teste manual do push em segundo plano (ação do dono, checklist em
  `docs/FCM.md`).

## Release do app

- `flutter build apk --release` exige `app/android/key.properties`; sem ele o
  Gradle falha (escape: `QIO_ALLOW_DEBUG_SIGNING=true`). R8 e shrink ligados
  (`proguard-rules.pro`). Crashlytics só reporta fora de debug e sem
  `USE_EMULATORS`. Depois de mexer em dependências Firebase, rode um build de
  release: versões desalinhadas de `firebase_core`/`firebase_auth` quebram a
  compilação Android.

## Horário de funcionamento

- `queues/{id}.schedule = {enabled, timezone, windows:[{days:[1..7 seg=1], open, close}]}`
  (Firestore, só o dono escreve). `applyQueueSchedules` (a cada 5 min,
  `functions/src/schedule.js`) aplica **apenas na virada** do horário
  (`scheduleLastDesired`): ao abrir põe `open`, ao sair da janela põe `closed` e
  grava `meta/opensAt` (ms). Mudança manual vale até a próxima virada. Editar a
  agenda apaga `scheduleLastDesired` e a function reaplica na rodada seguinte.
- Janela que passa da meia-noite é suportada (`close <= open`). O app usa fixo
  `America/Sao_Paulo`. Requer Cloud Scheduler (Blaze); deploy:
  `--only functions:applyQueueSchedules`.

## Identidade da fila (cor e logo)

- `queues/{id}.brandColor` (uma das 8 cores de `brand_palette.dart`) e `logoUrl`
  espelhados em `meta/` (RTDB valida `#RRGGBB` e `logoUrl` só de
  `https://firebasestorage.googleapis.com/`). O web (`safeBrandColor`/
  `safeLogoUrl`) ignora qualquer outro valor, aplica `--brand` e mostra o logo,
  com a inicial colorida como fallback.
- Upload: `image_picker` (512 px, JPEG q85) → `queue-logos/{queueId}/logo.jpg`.
  `storage.rules`: leitura pública, escrita só do dono (lê `ownerId` no
  Firestore), < 300 KB, `image/png|jpeg|webp`, nome `logo.(png|jpg|webp)`.
  O bucket `qio-app.firebasestorage.app` já existe e as rules estão publicadas;
  rules testadas no emulator de Storage.

## Push (dono e cliente)

- **Dono:** o app registra o token em `owners/{uid}/devices/{token}`
  (`PushService`, `{token, platform, lang, updatedAt}`; rules só do próprio uid)
  depois do opt-in; `owners/{uid}.notifyNewEntries` (padrão ligado) desliga. Sair
  da conta apaga o token. Só mobile. A function `onEntryJoined` avisa dono +
  `operatorUids`, agrupa por idioma, usa `collapseKey/tag = queueId` e apaga
  tokens inválidos (`functions/src/push.js`). Canal Android `qio_new_entries`
  criado no `MainActivity`; permissão `POST_NOTIFICATIONS`; o toque abre o painel.
- **Cliente (web):** o botão "Ativar aviso" na tela da senha pede a permissão e
  grava `fcmToken` na entry; `joinQueue` grava `lang`; `onEntryCalled` e
  `onQueueAdvanced` ("Você é o próximo", uma vez por `nextNotifiedAt`) enviam em
  pt/en/es (`functions/src/webpush.js`). Precisa de `VITE_VAPID_KEY` no build
  (variável do GitHub Actions + `web/.env.local`). iOS: só com a PWA instalada.
  Detalhes em `docs/FCM.md`.

## Deep links

- Android App Links para `https://qio.web.app/q/*` (`AndroidManifest.xml`,
  `autoVerify`). O arquivo `web/public/.well-known/assetlinks.json` precisa estar
  no ar com o SHA-256 da chave de **release** (e do Play App Signing, se usar a
  Play Store). O `firebase.json` não pode ignorar dotfiles: `**/.*` foi removido
  do `hosting.ignore` por causa do `.well-known`.
- `HomeScreen` trata o link (`queueIdFromLink`): dono/operador abre o painel;
  os outros são mandados ao navegador em `/c/{id}` (mesma página do cliente), e
  não em `/q/`, para não cair em laço com o App Link. O QR e o link
  compartilhado continuam `/q/{id}`.
- Verificação no aparelho: `adb shell pm get-app-links com.qio.qio_app` deve
  mostrar `qio.web.app: verified`. iOS (Associated Domains) não foi feito.

## Monitoramento e analytics

- Functions logam erros com `logError` (`functions/src/log.js`): remove name/phone/token
  do contexto; passe só IDs. `HttpsError` de validação não vira log de erro.
- Eventos Analytics sem PII (`queue_id` apenas): app `queue_created`/`entry_called`/
  `entry_served` (`analytics_service.dart`, desligado em debug/`USE_EMULATORS`, opt-out em
  Minha conta); web `queue_joined`/`feedback_sent` (`web/src/lib/analytics.ts`, lazy, só
  PROD, exige `VITE_MEASUREMENT_ID`, respeita opt-out `qio:analytics-optout` e Do Not Track).
- Alertas de erro, uptime check, orçamento R$20/mês e ativação do Analytics são **ação
  manual no console** (passo a passo em `docs/monitoring.md`). Deploy: functions → hosting
  → APK.

## Marca

- Fonte da verdade em `design/brand/` (SVGs, PNGs, `generate.py`, regras de uso).
  Símbolo = "Q" em anel + pontos de fila; `icon-small.svg` para 32 px ou menos.
- App: ícones via `app/flutter_launcher_icons.yaml`, splash via
  `app/flutter_native_splash.yaml` (`dart run flutter_launcher_icons` e
  `dart run flutter_native_splash:create`). Depois de rodar, **reverta**
  `ios/Runner/Info.plist` (reindenta tudo) e `ios/Runner.xcodeproj/project.pbxproj`
  (o gerador troca `GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` por `AppIcon`).
- O foreground do ícone adaptativo já considera o inset de 16% do gerador; não
  reduzir de novo.
- Web: `web/public/` tem favicon, ícones PWA e `apple-touch-icon.png` gerados do
  mesmo kit.

## Cores e tema (app)

- Cores que mudam com o tema vêm de `QioPalette` (`ThemeExtension`, registrada em
  `QioTheme.light/dark`): use `context.qio.surface`, `context.qio.gray500`,
  `context.qio.textPrimary` etc. Estilos de texto: `context.qioText.body`
  (`QioTextStyles`, já com a cor da paleta). Importe `theme/qio_palette.dart` e
  `theme/qio_text_styles.dart`.
- `QioColors` guarda só constantes independentes de tema (`primary*`, `secondary*`,
  `error`, `warning`, `success`, `info`, `status*`, `*Strong`). Não há mais `apply`,
  `isDark` nem rebuild forçado: `MaterialApp` usa `theme`/`darkTheme`/`themeMode`.
- Nunca leia `context.qio` em `initState`, campo `final`/`late final` ou `static
  const`: não reage à troca de tema. Leia em `build` (ou passe `context`). Para
  saber o modo, use `Theme.of(context).brightness`. Em testes, `QioPalette.light`/
  `QioPalette.dark` dão os valores esperados.

## Backups e orçamento (ops)

- Scripts em `ops/` (`backup-firestore.sh`, `backup-rtdb.sh`, `create-budget.sh`,
  `restore-firestore-test.sh`), com `PROJECT`/`BUCKET`/`BILLING_ACCOUNT` por env e
  `--dry-run` (só imprime). Estratégia, restauração e RPO/RTO em `docs/backup.md`.
- Firestore é a fonte da verdade (backup diário 7d + semanal 8w); RTDB é espelho
  (backup do console). Restore cria **banco novo**, nunca sobrescreve `(default)`.
- Agentes não têm credenciais: nunca rodar esses scripts sem `--dry-run` contra
  `qio-app`. As ações manuais do dono estão em `docs/backup.md` seção 7.

## Privacidade

- Estabelecimento = controlador; Qio = operador. Minuta técnica (não é parecer
  jurídico): `/privacidade` e `/termos` na web (`routes/Privacy.tsx`, `Terms.tsx`,
  textos em `web/src/i18n/legal/{pt,en,es}.ts`, carregados por `React.lazy`/import
  dinâmico fora do bundle principal; pt é a versão de referência).
- Contato do controlador: `VITE_PRIVACY_CONTACT` (variável do GitHub Actions + CI);
  vazio mostra "contate o estabelecimento". Vigência ainda é placeholder.
- O formulário de entrada tem aviso com link; rodapé e landing linkam as páginas;
  o app (login e conta) abre as URLs via `LegalLinks`.
- Retenção-alvo do `history`: 180 dias, **ainda não aplicada pelo código**. Mapa de
  dados e pendências do dono em `docs/privacidade.md`. Export sem telefone é a #160.

## Tooling (adaptado do OpenCode)

O framework de agentes (product → builder → reviewer → advisor) e as regras de
shell/estilo são globais em `~/.claude/`. Slash commands: `/architect`,
`/implement`, `/review`, `/advise`. MCP Firebase via `@firebase-agent`.
