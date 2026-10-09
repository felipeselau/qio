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
npm test           # vitest (roda no CI)
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
`test:callable` define `MANUAL_MAX_ACTIVE_ENTRIES=40`: `resolveActiveCeiling`
(`functions/src/manual.js`) só aceita esse override com `FUNCTIONS_EMULATOR=true` e só abaixo de
1000 (produção sempre usa 1000). Semear 1000 entries disparava ~2000 triggers no emulator e a
callable `addManualEntry` falhava com `functions/internal` no CI (teste "teto absoluto").

Sempre rode lint + analyze + test antes de dar uma tarefa como concluída (ver
`~/.claude/CLAUDE.md`). Em `web/` há testes vitest (`npm test`, `npm run test:coverage`); o CI roda lint, testes e build. Contagem de testes, cobertura e limitações
conhecidas: `docs/qualidade.md`. Kit do piloto em estabelecimento real (plano, checklist,
modelos; ainda sem dados): `docs/piloto/`.

## Modelo de dados

- **Firestore** (durável, lado owner): `owners/{uid}`, `queues/{queueId}`,
  `queues/{queueId}/history/{entryId}`. Rules: `firestore.rules`.
- **RTDB** (tempo real): `queues/{queueId}/meta`, `queues/{queueId}/entries/{id}`,
  `queues/{queueId}/public/{id}`, `owners/{queueId}/ownerUid` (espelho de posse p/
  rules), `tickets/{queueId}` (contador de senha, incrementado por transação na
  callable `joinQueue`), `rateLimits/{queueId}/{uid}` (timestamps dos joins).
  Rules: `database.rules.json`.
- Rules do RTDB validam `queues/{id}/entries/{entryId}`: `ticket` número, `status` ∈ waiting/called/served/no_show/left, `uid` imutável, `name` 1–60 chars e `phone` vazio ou `(DD) 9999-9999`/`(DD) 99999-9999` (os dois só são checados na criação ou quando mudam), campos fora de ticket/name/phone/uid/fcmToken/status/joinedAt/calledAt/operatorId (mais os de ordem/push e `slotId`/`slotStart`) são rejeitados. `.validate` não roda em `remove()`.
- **Espelho Firestore → RTDB (issue #164, etapa 2):** a partir do APK 1.5.0 o app **não faz
  mais dual-write nos setters** (`updateQueueStatus`, `updateQueueInfo`, `updateMaxWaiting`,
  `updateBrandColor`, `uploadLogo`/`removeLogo`, `updateModeAndSlots`, aprovar/remover operador):
  escrevem só no Firestore e os triggers `mirrorQueueToRtdb`/`mirrorOperatorToRtdb` replicam
  `meta`, `owners/{id}/ownerUid` e `operatorUids`. Continuam no RTDB, de propósito: (a) o write
  inicial de `createQueue` (`owners` + `meta`; `duplicateQueue` herda), porque o dono usa a fila
  na hora (QR, rules de `entries` dependem de `owners/{id}/ownerUid`, a web precisa de `meta`) e
  o trigger leva segundos; (b) `ensureMirror`/`_ensureOwnerMirror`/`syncOperatorMirror` como
  **reparo** (só escrevem se diverge; rede de segurança de filas legadas; `ensureMirror` só
  repara name/description/avgServiceMin/mode/slots quando há `meta`, e recria `meta` ausente completo; o resto fica com o trigger);
  `_ensureOwnerMirrorIfOwner` fica em cache por sessão (`uid/queueId`); (c) campos que são do
  app e não espelho: `meta/serving`, `meta/updatedAt` (`callNext`/entries; o trigger só o carimba quando o `status` muda, então outras edições do dono não adiam o alerta de "fila parada"), `entries`. **Ordem de deploy OBRIGATÓRIA:** functions `mirror*` (no ar e
  verificadas) → … → APK. APK novo com functions antigas deixa o RTDB desatualizado (web
  mostra status/nome/limite velhos). APK antigo continua funcionando (faz dual-write; o trigger
  só confirma). Triggers com `retry: true` (handlers idempotentes relançam o erro) e patch sobre todos os
  campos espelhados, então uma falha do RTDB é reexecutada e converge; o retorno antecipado
  (nenhum campo espelhado mudou) é seguro porque só pula eventos que não alteram `meta`.
  Fila existente sem `meta` continua sem ser recriada pelo trigger (nunca zerar `serving`):
  `ensureMirror` recria incluindo limite, cor, logo e aviso. Delete do doc (`after == null`)
  é ignorado: `deleteQueue` já limpa o RTDB. Latência: web vê a mudança de status/limite segundos depois (cold start do
  trigger). Rules do RTDB **não** foram alteradas: restringir `meta` (menos `serving`/
  `updatedAt` de operador) e `owners` ao Admin só quando o APK antigo sumir.
- **Trigger de espelho (issue #164, rede de segurança):** `mirrorQueueToRtdb`
  (`onDocumentWritten('queues/{queueId}')`, us-central1) replica Firestore → RTDB via Admin.
  Estrutura: lógica pura em `functions/src/mirror.js`, handlers com `deps` injetadas em
  `functions/src/handlers/mirror.js`, wiring em `functions/src/triggers/mirror.js` e só
  `Object.assign(exports, require('./src/triggers/mirror'))` no `index.js`. Testes:
  `functions/test/mirror*.test.js` e `rules-tests/test/mirror-callable.test.js`.
  - **Não confia no evento:** o `after` só decide *se* agir. Ele compara `before`/`after` nos
    campos espelhados (`changedFields`) e retorna cedo se nenhum mudou (updates só de
    `alertState`, `scheduleLastDesired`, `lastTicketResetDay` etc. não custam leitura nem
    escrita). Se algo mudou, relê `queues/{id}` atual e `meta` atual e calcula o patch sobre
    eles, só nos campos que mudaram (eventos fora de ordem convergem para o estado atual).
    Doc inexistente, `deleting` ou `meta.deleting` → nada.
  - **Campos:** `owners/{id}/ownerUid` e, em `meta`, `name`, `description`, `avgServiceMin`,
    `maxWaiting`, `status`, `statusMessage`, `resumeAt`, `brandColor`, `logoUrl`, `mode`, `slots`.
    Normalização como `QueueInfo.forMirror` e `Queue.fromDoc` (nome 60 ou "Fila", descrição ≤300,
    `avgServiceMin`/`maxWaiting` fracionário truncam como o `toInt()` do app, tempo fora de 1–240
    vira 10). `status` desconhecido é ignorado (não vira `open`); `resumeAt` só inteiro finito;
    valores que as rules do RTDB recusariam viram "ausente" para não derrubar o `update`. Slots:
    id `[A-Za-z0-9_-]{1,20}`, início `HH:mm`, capacidade 1–50, ordenados por início e cortados
    em `MAX_SLOTS` de `functions/src/slots.js` (o mesmo corte da `joinQueue`, hoje 20).
  - **Nunca toca** `nextTicket` (só inicializa), `serving`, `updatedAt` (só grava na criação),
    `avgServiceMinAuto`, `waitingCount`, `opensAt`, `deleting`, `nextNotifiedAt`.
  - **`meta` ausente:** criado (transação, só se continuar ausente) **somente** quando o evento
    é a criação do doc (`!before.exists`) e o doc relido existe e não está `deleting`. Fila
    existente sem `meta` só gera log de aviso; o `ensureMirror` do app repara. O trigger nunca
    zera `serving`/`nextTicket` de fila existente.
  - **Operadores:** `mirrorOperatorToRtdb` (`queues/{id}/operators/{uid}`) relê o doc do
    operador: existe → `operatorUids/{uid} = true` (só se a fila existe e não está `deleting`);
    não existe → remove. Evento de add atrasado depois de remove não re-adiciona.
  - Custo: ao mudar campo espelhado, 1 leitura do doc + `meta` (+ `owners` se `ownerId`
    mudou) e escrita só se diverge. O trigger escreve só no RTDB (sem eco). Escritas em
    `meta/status` disparam `onQueueOpened` apenas se o valor de fato mudou.
  - **Migração gradual:** (1) deploy das functions (este PR; APKs antigos seguem com dual-write
    e o trigger só confirma); (2) APK novo (1.5.0, **feito no código**; precisa do passo 1
    em produção) para de escrever `meta`/`owners`/`operatorUids` nos setters; (3) quando o APK antigo sumir, rules do RTDB restringem
    `meta` (menos `serving`/`updatedAt` de operador) e `owners` ao Admin.
  - **Fora deste PR (etapa 1; o cliente foi tratado na etapa 2):** alterar o cliente Flutter, endurecer rules do RTDB, backfill em massa
    (o trigger só age quando o doc é escrito), espelhar `updatedAt`/`opensAt`, recriar `meta`
    de fila existente. Deploy: `--only functions:mirrorQueueToRtdb,functions:mirrorOperatorToRtdb`
    antes de qualquer APK.

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
  APK antigo (dono/operador) continua compatível com as rules do join (conferir a ordem de deploy de cada feature). Web antigo em
  cache falha ao entrar na fila até recarregar.

## Reivindicar a própria senha (#145)

- `joinQueue` com telefone igual ao de entry de **outro** uid: só entries `waiting` são
  reivindicáveis (quem já foi `called` e perdeu o aparelho fala com o balcão). Se o nome
  também bate (`namesMatch` em `functions/src/join.js`: sem acento, sem caixa, trim,
  espaços colapsados), a entry é reatribuída ao uid chamador por transação Admin
  (`claimEntryUpdate`: troca `uid`, apaga `fcmToken`; ticket/joinedAt/order intactos) e a
  resposta é `{existing: true, claimed: true}`. O uid antigo perde a leitura na hora (rule
  `uid == auth.uid`). `public/` não tem uid; nada mais depende do uid antigo.
  Nome errado ou entry `called`: `already-exists` como antes, sem vazar nome/ticket alheios.
  Perdeu a corrida (a entry mudou entre a leitura e a transação): `aborted` +
  `details.reason == 'claim-lost'` (web: `errors.claimLost`).
- Só reivindica quem informa telefone: entry sem telefone não é reivindicável. A fila precisa
  estar `open` (a checagem de `meta/status` vem antes). Entries manuais (sem uid) são
  reivindicáveis. O log guarda `claimed`, `queueId`, `entryId` e `previousUidHash` (hash
  curto do uid antigo), sem nome/telefone.
- Limites (mitigação, **não autenticação**): 3 tentativas por 10 min por uid
  (`CLAIM_RATE_LIMIT`, `rateLimits/{queueId}/_claim/uid/{uid}`) **e** 5 por 10 min por fila +
  telefone (`CLAIM_PHONE_RATE_LIMIT`, `rateLimits/{queueId}/_claim/phone/{hash}`, hash sha256
  do telefone com `DSR_HASH_PEPPER` se existir, sem PII em claro; barra uids anônimos novos
  em série). Cada tentativa consome os dois contadores quando o telefone casa com entry de
  outro uid. Estourou: `resource-exhausted` + `details.reason == 'claim-rate'`. O prefixo
  `_claim` não colide com uids; `deleteQueue` apaga `rateLimits/{queueId}` inteiro. Um
  atacante paciente ainda pode tentar 5 nomes por 10 min por telefone.
- Web mostra o aviso `queue.claimed` ("Recuperamos a sua senha") na tela da senha.
- Risco aceito: quem sabe nome **e** telefone de outra pessoa na fila consegue sequestrar a
  senha dela (e ela deixa de ver a entry). Baixa gravidade em fila presencial; verificação
  por SMS fica em #96.
- Deploy: functions (`joinQueue`) → hosting. Sem mudança de rules.

## Limite de fila e mensagem de status

- `queues/{id}/meta/maxWaiting` (0 = sem limite, 1–1000), `statusMessage` (≤120) e
  `resumeAt` (ms) são escritos só pelo dono e espelham o doc do Firestore. A
  `joinQueue` conta entries `waiting` e recusa com `resource-exhausted` +
  `details.reason == 'queue-full'` (lógica em `functions/src/capacity.js`); quem
  já tem entry ativa recebe a própria. Joins simultâneos podem passar do limite
  em uma ou duas vagas (sem transação de contagem). O web também bloqueia o botão
  usando `public/` (`useQueue.full`).
- Pausar/fechar no app abre um diálogo com mensagem e horário de retorno; reabrir
  limpa os dois. O app grava só no Firestore; `mirrorQueueToRtdb` replica `status`,
  `statusMessage`, `resumeAt` e `maxWaiting` no `meta` (segundos de latência) e carimba
  `meta/updatedAt` quando o `status` muda. Deploy: functions (`joinQueue`) antes das rules do RTDB.

## Agendamento por horário (slots)

- `queues/{id}.mode` (`'queue'` padrão | `'schedule'`) e `slots = [{id, start:'HH:mm',
  capacity 1–50}]` (máx. 20, horários únicos, ids estáveis) no Firestore (fonte da verdade,
  só o dono escreve). Espelho no RTDB: `meta/mode` e `meta/slots/{slotId} = {start,
  capacity}` (o app escreve só no Firestore em `QueueService.updateModeAndSlots`; `createQueue` faz o write inicial no RTDB e o trigger replica as edições). Os slots são
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
  `[A-Za-z0-9_-]{1,20}`), mas **não limita a 20** (RTDB rules não têm `numChildren`; a
  function corta em 20 ao ler). `slotId`/`slotStart` da entry são imutáveis para o cliente
  e há `.indexOn` em `slotId`. Firestore valida `mode`, `slots` (lista ≤ 20, `start`
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
  em `models/queue_info.dart`, erro `FormatException`) grava só no Firestore (o
  trigger `mirrorQueueToRtdb` replica no `meta`). O `queueId` (e o QR) não muda. Painel: tiles "Editar fila" e
  "Duplicar fila" (só dono).
- `duplicateQueue` cria fila nova `<nome> (cópia)` copiando descrição, tempo médio, limite,
  grupo, modo/slots, horário de funcionamento, cor, alertas e expiração (`expiry`). Não copia entries, history,
  operadores, logo, mensagem de status nem `alertState`.
- Rules validam `name`/`description`/`avgServiceMin` no Firestore (create, e update só de cada
  campo que mudou, para não travar docs legados) e em `meta/{name,description,avgServiceMin}`
  no RTDB (valor legado inalterado passa). `updateQueueInfo` grava só os campos alterados
  no Firestore (sem segundo write); `ensureMirror` repara divergência de
  name/description/avgServiceMin no `meta` (normalizados por `QueueInfo.forMirror`: nome
  truncado a 60 ou "Fila", descrição a 300, tempo fora de 1–240 vira o default). O tempo
  manual só vale até existir `avgServiceMinAuto`. O Firestore limita a 1000 expressões por avaliação; `MAX_SLOTS`/`maxQueueSlots` = 20
  (rules, app, functions e web iguais) é o maior valor que cabe no pior caso testado
  (create/update com slots + alerts + groupId + nome/descrição + privacidade). Subir o limite
  ou somar checagens em `queues/{id}` exige rodar o teste "pior caso" em rules-tests. Deploy: rules antes do APK.

## Criação de fila e botão voltar

- `CreateQueueScreen` é um **wizard de 6 passos** (uma decisão por tela, `PageView` sem
  swipe, `animateToPage` 250 ms; sem animação se `disableAnimations`): 1 Nome (obrigatório;
  "Mais detalhes" recolhível com descrição e grupo; "Criar agora" cria direto com defaults),
  2 Entrada (cartões Fila por chegada / Hora marcada; hora marcada mostra chips de sugestão
  `suggestSlots` e o `SlotsEditor` com `showModeSelector: false`), 3 Tempo médio e limite
  (opcional), 4 Cor (`BrandColorPicker`, opcional), 5 Funcionamento (`ScheduleForm` +
  `ExpiryForm(showExtras: false)`: só `enabled`+`hours`; `clearOnClose`/`resetTicketDaily`
  ficam nas configurações; opcional), 6 Revisão com "Editar" por seção (volta ao passo e
  retorna à revisão) e defaults explícitos ("10 min", "Sem limite", "Sempre aberta", "Não
  expirar"). Alertas, logo, link curto, operadores e mensagem de status ficam **fora** do
  create. Tempo médio vazio vira `defaultAvgServiceMin` (10, `models/queue_info.dart`).
- Estado e validação por passo ficam em `CreateQueueController`/`CreateQueueDraft`
  (`controllers/create_queue_*.dart`); a tela só liga campos ao draft e chama `createQueue`
  com `controller.toCreateArgs()` (inclui `expiry`). "Pular" restaura os defaults do passo
  (cor, tempo/limite, horário+expiração; o grupo do passo 1 não é afetado). Botão primário
  fixo no rodapé (`CreateQueueFooter`), barra com `Semantics('Passo X de Y')` e anúncio da
  troca de passo; o rodapé reserva o espaço do botão secundário (altura estável). O passo 1
  fica vivo (`CreateQueueKeepAlive`; sem reabrir o teclado ao voltar). Horários: máx. 20
  (`maxQueueSlots`); as sugestões **acumulam** (rótulo "Adicionar horários...", sem duplicar
  nem passar de 20). A revisão mostra grupo (nome via `GroupService`), cor (amostra) e todas
  as janelas do horário. `createQueue` tem timeout de 20 s (`TimeoutException` →
  `cqCreateTimeout`); enquanto cria, voltar (sistema e botão) fica **bloqueado** e o botão
  primário mostra o spinner. Risco conhecido: após o timeout a criação pode ter concluído no
  servidor, e um retry gera fila duplicada (o aviso manda conferir a lista). Erro de
  `createQueue` (`queueErrorMessage`) aparece num banner
  (`create-error`) e a tela segue aberta. Sucesso: `pushReplacement` para `QueueCreatedScreen`.
- **Limite antecipado (#222):** ao abrir o wizard, `initState` chama
  `QueueService.isAtQueueLimit(uid)` (mesmo `count()` do `ensureUnderQueueLimit`, que passou a
  usá-lo). Enquanto checa, `QueueLimitGate(checking: true)` mostra spinner; no limite mostra
  `cqLimitTitle` + `queueLimitReached` + botão Voltar e **não** monta os passos; falha de rede
  segue para o wizard. A checagem final em `createQueue` continua (corrida/cliente adulterado).
  Testes de widget que montam `CreateQueueScreen` direto precisam de `pumpAndSettle` antes de
  interagir (`pumpCreate` já faz).
- **Tela "Fila criada" (#220):** `QueueCreatedScreen(queue:)` (recebe o `Queue` devolvido por
  `createQueue`) mostra ✓, nome, QR, link `joinUrl(id)` (toque copia), "Compartilhar link"
  (`onShare` injetável, padrão `SharePlus`) e "Abrir painel" (`pushReplacement` para
  `QueuePanelScreen`, que mantém o tour da primeira abertura). Atalhos "deixe mais bonita":
  Logo e cor / Link curto abrem `QueueSettingsScreen` (os tiles de logo e slug só existem
  lá), Operadores abre `OperatorsScreen` e Alertas `AlertsSettingsScreen`, via `push`
  (voltar retorna à tela). Voltar do sistema = Abrir painel (`PopScope(canPop: false)`); a
  fila já existe, nunca volta ao wizard nem recria. Testes usam `destinationBuilder`
  (`@visibleForTesting`).
- Voltar do sistema e `QueueBackButton` voltam **um passo** (`PopScope(canPop: primeiro
  passo && !dirty)`); no passo 1 com draft sujo vale a confirmação de descarte. Widgets em
  `widgets/create_queue/`. Testes usam `ValueKey` (`create-name`, `create-continue`,
  `create-skip`, `create-quick`, `create-submit`, `create-back`, `create-mode-schedule`,
  `create-edit-<seção>`, `slots-add`...) e `test/helpers/create_queue_flow.dart`; evite
  seletores posicionais.
- Voltar do painel/criação/edição é `QueueBackButton` (`BackButton` do Material, tooltip e
  semântica localizados, usa `maybePop` e portanto respeita o `PopScope`).

## Contador de espera no meta

- `queues/{id}/meta/waitingCount` = número de entries `waiting` (só `waiting`; `called`
  não conta, igual à contagem antiga da home). Escrito pela function (Admin); a rule
  do RTDB tem `.validate: false` no campo, então ninguém grava um valor pelo cliente
  (leitura como o resto do `meta`). Ressalva: o dono pode **apagar** o campo
  (`remove`/`null`, `.validate` não roda em remoção) e o app cai no fallback; um
  `set` completo do `meta` pelo dono (ensureMirror/createQueue com `meta` ausente)
  também o apaga até a próxima trigger ou reconciliação.
- Estratégia: **recontagem**, não delta (`functions/src/waiting.js`). Quando a entry
  entra/sai de `waiting` (`waitingChanged`), `syncPublicTicket` lê `public/` (só
  `{ticket,status,order}`), grava, **relê** e regrava se mudou (até 2 escritas), o
  que cobre corrida entre eventos. Reentrega é idempotente. Roda também quando o
  arquivamento do `left` falha (depois de remover `public/`), e então a trigger relança.
- A escrita é `transaction` no nó `meta`: aborta se `meta` não existe, não tem `name`
  ou tem `deleting === true` (não recria fila apagada nem mexe em fila sendo apagada);
  com `meta` nulo no cache local devolve o valor inalterado para o SDK reconferir no servidor.
- Reconciliação: `reconcileWaitingCounts` (a cada 15 min) lista as filas pelo
  Firestore (só ids, sem ler `entries`), recontagem de `public/` com concorrência 5 e
  corrige divergência.
- App: `QueueService.watchWaitingCount` lê só `meta/waitingCount` (um número por
  card). Se o campo não existe, cai para a contagem por `public/`
  (`app/lib/services/waiting_count.dart`) e abandona o `public/` quando o campo
  aparece (e volta a ele se sumir). Web continua contando por `public/`. APK antigo
  segue contando por `public/`.
- Backfill: `GOOGLE_CLOUD_PROJECT=qio-app node functions/scripts/backfill-waiting-count.js
  [--dry-run]` (opcional `FIREBASE_DATABASE_URL`). Conta a partir de `public/` com a
  mesma regra da trigger, pula filas sem `meta/name` ou com `deleting`, pula valores
  já corretos e grava só o campo, via a mesma transação. **Ordem de deploy**:
  functions → backfill → rules do RTDB → APK.

## Ordem da fila, chamar de novo e mover

- A ordem de espera é `(order ?? joinedAt, ticket)`. "Mover para o fim" grava
  `entries/{id}/order = now` e `skips++` (a senha não muda). `public/{id}` agora é
  `{ticket, status, order}` (`functions/src/ticket.js`); o web calcula a posição
  com `positionInQueue` e cai para a comparação por senha se `order` faltar.
- "Chamar de novo" grava `recalledAt = now` e `recalls++`; `syncPublicTicket` (passo `called`)
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
- `calledAt` usa o relógio do **servidor estimado**: `_claimEntry` lê
  `.info/serverTimeOffset` (timeout 2 s, offset 0 se falhar) e a transação de claim por
  status grava `calledAt = DateTime.now() + offset` (`serverNowMs`/`claimedEntryData`,
  `services/claim_entry.dart`). Erro < 1 RTT, independente do relógio do aparelho; sem
  segundo write, sem releitura. Não se usa `ServerValue.timestamp` dentro do
  `runTransaction` (suporte nativo não verificado). O `_archiveEntry` converte o ms para
  `Timestamp` (`historyTimestamp`). Espera e atendimento (`calledAt − joinedAt`,
  `finishedAt − calledAt`) deixam de depender do relógio do operador. Rules:
  `entries/*/calledAt` exige número e `status` existente na entry (impede nó fantasma).
  `shouldRenotify` ignora `calledAt`. O `CalledTimer` do web compara `calledAt` com
  `Date.now()` do cliente (clamp em 0 via `elapsedSince`): relógio errado do cliente
  distorce só o contador na tela. Deploy: rules do RTDB antes do APK; APK antigo segue
  compatível com as rules novas (grava `calledAt` numérico junto do `status`).
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

- **Create de fila no pior caso (#212):** `allow create` de `queues/{id}` aceita num
  único `add()` o payload completo do wizard (modo `schedule` com 20 slots de capacity 50,
  `alerts` completo, `schedule` com janelas, `groupId` de 40, `brandColor`, `expiry`,
  `retentionDays`, `anonymizePhone`, nome 60, descrição 300, `avgServiceMin`, `maxWaiting`);
  teste "create do wizard no pior caso cabe num único add()" em `rules-tests/test/
  firestore.test.js`. Conclusão: não há necessidade de gravar `slots` num segundo `update`.
  **A folga é mínima** (~2%, 10–20 das 1000 expressões): somar ~10 termos triviais
  (`&& true`) ao `allow create` já estoura. Qualquer validação nova no create (ex.:
  `schedule`, `brandColor`, `expiry`) deve ser feita no cliente; se for inevitável, rode o
  teste e, se falhar, grave `slots` num `update` logo após o `add()`. Como medir:
  `docs/qualidade.md` (seção "Margem do create").
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

## Retenção e anonimização

- Política efetiva: `history` e `feedback` com mais de **180 dias** são apagados. A function
  agendada `purgeOldHistory` (diária 03:30 America/Sao_Paulo, `functions/src/retention.js`)
  percorre as filas (ignora `deleting`) e apaga em lotes de 450, paginando com
  `where(f,'<',cutoff).orderBy(f).limit(450)`: `history.finishedAt` e `feedback.createdAt`.
  Prazo por fila em `queues/{id}.retentionDays` (int 30-730; ausente/0/inválido = 180).
  Sem índice composto novo (usa o índice single-field automático). Idempotente; loga só
  contagens (`event: purgeOldHistory`) e `logError` por fila, sem PII.
- `queues/{id}.anonymizePhone` (bool, tile "Não guardar telefone no histórico" nas
  configurações): `_archiveEntry` grava `phone: null` no history, e o trigger Admin que
  arquiva `left` também respeita o campo. Só Firestore (sem espelho RTDB); vale para
  arquivamentos novos. O valor vem do `watchQueue` já assinado pelo painel (cache em
  `QueueService`), com `get` só se não houver cache; se a leitura falhar, grava `phone: null`
  (falha fechada, `history_privacy.dart`).
- `retentionDays` não tem UI: é configurável só por Admin/console (ou rules do dono via
  cliente próprio). Padrão 180.
- Exportação CSV/PDF do Histórico **sem telefone por padrão**; os itens "Exportar ... com
  telefone" pedem confirmação com aviso LGPD. `metrics_export.dart` nunca exporta telefone.
- Rules do Firestore: `retentionDays` e `anonymizePhone` só são validados quando mudam.
  O update de `queues` valida tudo por campo alterado (`queueUpdateFieldsOk`, um único
  `diff`), inclusive `mode`/`slots`/`alerts`, por causa do limite de 1000 expressões; não
  volte a validar `slots` em todo update. O cliente não escreve `ownerId`, `deleting` nem
  `alertState` (só Admin); campos desconhecidos continuam permitidos (ex.: `slug`).
  `validSlots` usa `concat` para repetir a lista e evitar um teste de tamanho por slot.
- Deploy: `--only functions:purgeOldHistory` → `--only firestore:rules` → APK. Sem a
  function nada é apagado; as rules novas só adicionam validação dos dois campos.

## Entrada manual (balcão)

- Callable `addManualEntry` (`functions/index.js`, lógica pura em
  `functions/src/manual.js`, região us-central1) com `{queueId, name, phone?, slotId?}`.
  Chamada só pelo app (botão "Adicionar pessoa" na AppBar do painel, dono e operador;
  `ManualEntryService` + `add_person_dialog.dart`).
- Autorização igual às rules do RTDB: `owners/{queueId}/ownerUid == uid` ou
  `queues/{id}/operatorUids/{uid} == true`; senão `permission-denied`.
- Mesma validação da `joinQueue` (nome 1–60, telefone vazio ou máscara BR),
  `meta/status == 'open'` (pausada/fechada recusa com `failed-precondition`, igual ao
  join), `maxWaiting` (`queue-full`) e, em fila `schedule`, `slotId` válido com
  capacidade (`slot-required|slot-invalid|slot-passed|slot-full`). Ticket por transação
  Admin em `tickets/{queueId}`.
- Limites: telefone não vazio já ativo na fila (inclusive de cliente da web) →
  `already-exists`; rate limit de 30 adições / 10 min por uid em
  `rateLimits/{queueId}/manual-{uid}` (`resource-exhausted`, `reason: 'rate-limited'`;
  Admin escreve sem rule, `rateLimits` é fechado a clientes); sem `maxWaiting`, teto
  absoluto de 1000 entries `waiting`+`called` (`queue-full`). Lógica em `manual.js`.
- A entry é criada por Admin com `manual: true`, **sem `uid` e sem `fcmToken`/`lang`**.
  Rules: `manual` booleano permitido; o create exige `uid` **ou** `manual == true`; o
  cliente não escreve em entry sem `uid` e `manual` é imutável para ele. Dono/operador
  já tinham write total em `entries`.
- `syncPublicTicket` espelha normalmente em `public/`; o passo `joined` do `syncPublicTicket` ignora entries
  manuais (não notifica quem acabou de adicionar). History/métricas não usam `uid`.
  Sem cliente, não há `left`, push nem feedback.
- `enforceAppCheck: false` é **fixo e deliberado** nesta callable (o app Flutter não usa
  App Check; APK fora da Play Store não passa no Play Integrity). Diferente de
  `ENFORCE_APP_CHECK_JOIN`/`ENFORCE_APP_CHECK_FEEDBACK`, ela ignora `ENFORCE_APP_CHECK`
  e não tem flag; a proteção é auth + posse da fila + os limites acima.
- Deploy: functions (`addManualEntry`, `syncPublicTicket`) → rules do RTDB → APK. Rules antes
  das functions deixaria entries manuais sem criador; o APK antigo lê entry sem `uid`
  como `''` e não mostra o selo.
- Limitações: duas pessoas manuais com o mesmo nome/telefone são permitidas; limite de
  fila pode passar em uma ou duas vagas sob concorrência (como no join).

## Operadores

- **Convite**: `operatorInvites/{code}` (6 chars, validade padrão 24 h) é a fonte
  da verdade. `queues/{id}.operatorInviteCode`/`operatorInviteExpiresAt` são só
  ponteiro p/ o dono exibir/revogar; os dois são gravados no mesmo batch. Não há
  link de convite: o operador digita o código no app.
- **Pedido**: `queues/{id}/operatorRequests/{uid}` com status
  `pending → approved | rejected | removed`. Só o dono muda status (rules).
- **Operador ativo**: `queues/{id}/operators/{uid}`. Home do operador usa
  `collectionGroup` filtrado por `uid`.
- **Espelho RTDB** `queues/{id}/operatorUids/{uid}: true`: escrito pelo trigger
  `mirrorOperatorToRtdb` ao aprovar/remover (o app não escreve mais; `syncOperatorMirror`
  é só reparo, lê `ownerId` do doc e só grava se diverge). Rules do RTDB usam esse espelho
  p/ liberar `meta/serving`, `meta/updatedAt` e `entries` ao operador. Aprovar/remover
  agora leva **segundos** (trigger), não é imediato: o operador recém-aprovado recebe
  `permission-denied` em `entries` até o espelho chegar, por isso `watchEntries` reanexa
  (`retryOnPermissionDenied`, 2,5 s, máx. 5 tentativas, zera a cada evento). Operador
  removido perde acesso em segundos; o painel escuta `operators/{uid}` (Firestore) e fecha
  com aviso na hora.
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

## Expiração de entradas

- Opt-in por fila: `queues/{id}.expiry = {enabled, hours 1–48 (padrão 12), clearOnClose,
  resetTicketDaily}` (Firestore, só o dono escreve; sem espelho no RTDB). As rules só exigem
  `expiry is map` (validar os campos estourava o limite de 1000 expressões do update de
  `queues`); `normalizeExpiry` (`functions/src/expire.js`) corrige valores inválidos
  (horas fora de 1–48 viram 12). `enabled` é o interruptor mestre: `clearOnClose` e
  `resetTicketDaily` só valem com ele ligado.
- `expireStaleEntries` (a cada 15 min, us-central1): por fila com `expiry.enabled` e sem
  `deleting`, lê `entries` (Admin) e arquiva como `result: 'left'` + `reason: 'expired'` as
  `waiting` cuja última atividade (`max(joinedAt, order, recalledAt)`) tem ≥ N h. `called`
  nunca expira. Reaproveita `archiveLeftEntry`/`historyFromLeftEntry` (respeita
  `anonymizePhone`; `create` idempotente), depois remove `entries/{id}` por transação
  (só se ainda `waiting` e velha) e `public/{id}`. Lotes de 25; erros por entry vão para
  `logError` só com IDs. Corrida residual: se a entry for chamada entre a leitura e a
  remoção, a transação aborta mas o doc `history` já criado fica (janela de ms).
- "Limpar ao fechar": quando `applyQueueSchedules` fecha a fila por horário e
  `clearOnClose` está ligado, arquiva as `waiting` restantes com `reason: 'closed'`
  (`called` fica). Além disso, `expireStaleEntries` repete a limpeza (idempotente) em toda
  fila com `meta/status == 'closed'` (inclusive fechamento manual) e `clearOnClose`, o que
  cobre falhas da virada. Se a fila reabrir antes da próxima rodada, nada é limpo.
- Se a releitura mostra entry ativa ou a fila sumiu do RTDB, o reinício da senha é adiado.
- App: `HistoryEntry.reason`; `left` com `reason` expired/closed não entra em
  "Desistiram" (`left`) das métricas, mas segue em `total` e na lista (rótulo "Desistiu").
- Reinício diário da senha: em `expireStaleEntries`, se o dia em `America/Sao_Paulo` mudou
  em relação a `queues/{id}.lastTicketResetDay` (escrito via Admin) e a fila não tem
  `waiting`/`called` (depois da expiração), remove `tickets/{id}` e grava o dia. Primeira
  execução só marca o dia. Com entries ativas adia até a fila esvaziar (pode zerar no meio
  do dia seguinte). Sem transação entre o reset e `joinQueue` (há releitura de `entries`/`meta/status` antes de remover): um join na mesma janela de
  ms pode receber a senha antiga + 1.
- Web: a entry some do RTDB sem passar por `called`, então `derivePhase` cai em `join`
  (não há `feedback`/`left`); o cliente não sabe o motivo e não há mensagem "senha expirou"
  (exigiria tombstone em `public/`). Quem já tinha sido chamado segue o fluxo normal.
- App: tile "Expirar entradas esquecidas" (`expiry_tile.dart`) em `QueueSettingsSections`.
  `QueueService.createQueue({ExpiryConfig? expiry})` grava `expiry` (`toMap()`) só quando
  `expiry != null && expiry.enabled`; desligado/ausente não cria o campo. `duplicateQueue` copia
  `expiry` da origem.
- **Deploy**: `--only functions:expireStaleEntries,functions:applyQueueSchedules` →
  `--only firestore:rules` → APK. Requer Cloud Scheduler (Blaze). Rules antigas aceitam
  `expiry` sem validar (não há lista de campos), então a ordem só evita config inválida.

## Direitos do titular (LGPD)

- Ferramenta do dono em `app/lib/screens/data_subject_screen.dart` (Minha conta, só
  com filas) + `data_subject_service.dart`. Callables Admin `findCustomerData`,
  `exportCustomerData` e `eraseCustomerData` (`{phone, mode: 'delete'|'anonymize'}`),
  lógica pura em `functions/src/dsr.js`. Só filas com `ownerId == uid`; login recente
  (`assertRecentLogin`, 300 s); 20 pedidos/h por uid em `rateLimits/_dsr/{uid}`.
- Telefone normalizado (10–11 dígitos) e buscado nas duas formas (`(11) 99999-9999` e só
  dígitos) em `history` (`where phone in`, lotes de 450) e RTDB `entries`; `feedback`
  casa pelo mesmo `entryId`. Sem migração de dados antigos. Anonimizar: nome
  `Anônimo`, `phone: null`, `comment: ''`; excluir apaga. Entries ativas saem de
  `entries`/`public`.
- Auditoria sem PII em `owners/{uid}/dataRequests/{id}` (Admin escreve; dono lê; rules).
  Falha ao gravar o log não derruba a resposta (vai para `logError`); erase parcial grava
  `failedQueueIds`. O hash do telefone é pseudonimização (pepper opcional
  `DSR_HASH_PEPPER`). `deleteAccount` apaga `rateLimits/_dsr/{uid}`.
  App Check: `ENFORCE_APP_CHECK_DSR` (false, não herda `ENFORCE_APP_CHECK`).
- Limites: history sem telefone (e seu feedback) não é achado; anonymize mantém
  `feedback.rating/uid/createdAt`; um `left` simultâneo pode recriar history (repetir a
  busca); a forma só-dígitos é só tolerância a legado. Detalhes em `docs/privacidade.md`.
- Passo a passo em `docs/privacidade.md`. Deploy: functions → rules do Firestore → APK.

## Estrutura das functions e roteador de entries

- `functions/index.js` é só ponto de registro: `initializeApp()` e `exports.X =
  require('./src/handlers/<dominio>').X`. Uma função nova entra com um arquivo próprio em
  `src/handlers/` e **uma linha** no `index.js` (sem mexer nos outros handlers).
- Handlers por domínio (`functions/src/handlers/`): `join`, `manual`, `feedback`, `slug`,
  `delete` (`deleteQueue`/`deleteAccount`), `dsr`, `entries` (`syncPublicTicket` + `reconcileWaitingCounts`),
  `push` (envio de FCM de entry, sem export de função), `schedule`, `alerts`, `expire`,
  `openwatch`, `estimate`, `history` (`purgeOldHistory`). `mirror` (#164) guarda só as fábricas
  de handler com `deps` injetadas; os triggers `mirrorQueueToRtdb`/`mirrorOperatorToRtdb` são
  registrados em `src/triggers/mirror.js` e entram no `index.js` por `Object.assign`. `_shared.js` guarda o que é comum
  (`findActive`, `resolveSlot`, `archiveLeftEntry`, `expireDeps`). Lógica pura continua em
  `functions/src/*.js`; nomes exportados, região, timeout, memória, `retry`,
  `guarded`/`isEnforced` e mensagens de `logError` não mudaram.
- **Roteador de entries**: `syncPublicTicket` (`handlers/entries.js`) é o **único** trigger
  em `queues/{queueId}/entries/{entryId}` (RTDB `onValueWritten`). Lê before/after uma vez e
  `routeEntryWrite` (`src/entryRouter.js`, puro e testado) despacha em paralelo
  (`Promise.allSettled`; a falha de um passo não impede os outros e é repropagada):
  `sync` (`applyEntryChange`, sempre), `joined` (create; era `onEntryJoined`), `called`
  (`shouldRenotify`; era `onEntryCalled`) e `advanced` (`advancedFromWaiting`; era
  `onQueueAdvanced`). Os passos de push estão em `handlers/push.js` e mantêm os mesmos
  guards e logs. `onEntryJoined`, `onEntryCalled` e `onQueueAdvanced` **deixaram de ser
  exports**: mencionados neste guia e em `docs/` como nome de lógica, não de função deployada.
- **NUNCA ligar `retry: true` em `syncPublicTicket`**: a reentrega repetiria os passos `called` e
  `joined` (push duplicado; `joined` não tem dedupe) e reaplicaria `sync`. O roteador relança o
  erro de um passo só para ele ficar visível no log.
- Invocações por escrita em `entries/{id}`: **4 → 1** (contagem de triggers registrados:
  `test/exports.test.js` falha se mais de uma função escutar o path). Cada escrita
  de entry (join, chamada, `fcmToken`, `order`, `left`...) custava 4 invocações, a maioria
  retornando `null` logo no início.
- Verificação: `node functions/scripts/dump-exports.js <arquivo.json>` grava nome e `__endpoint`
  (região, timeout, memória, trigger, retry) de cada export; compare com um dump da `main`
  via `diff`. Dumps versionados: `functions/scripts/exports-before.main.json` (main antes da #165) e
  `exports-after.json`. Na migração a única diferença foi a remoção das 3 funções acima.
- **Deploy da consolidação**: `firebase deploy --only functions` com `--force` (o CLI pede
  confirmação para apagar `onEntryCalled`, `onEntryJoined`, `onQueueAdvanced`; sem TTY o deploy
  falha sem `--force`; `.github/scripts/deploy-target.sh` passa `--force` só no deploy real de
  `functions`/`all-ordered`, e `--force` apaga qualquer função ausente do código). Alertas por
  `function_name` das três antigas devem apontar para `syncPublicTicket` (mensagens `logError`
  preservadas). Faça num único deploy: o `syncPublicTicket` novo já cobre os
  quatro caminhos, então entre o update dele e a remoção das antigas pode haver segundos com
  push duplicado de "É a sua vez" (o aviso "Você é o próximo" é protegido por
  `nextNotifiedAt`). Deploy parcial `--only functions:syncPublicTicket` **não** remove as
  antigas (duplicaria push até apagá-las com `firebase functions:delete onEntryCalled
  onEntryJoined onQueueAdvanced --region us-central1 --force`). Rollback: `git revert` e novo
  deploy recria as três.
- **`minInstances: 1` em `onEntryCalled` (avaliado, não ligado)**: o cold start de Node 22 em
  gen2 costuma ser de ~1–3 s sobre um evento RTDB que já tem latência variável de alguns
  segundos; o push "É a sua vez" não é interativo. Custo de manter 1 instância ociosa é fixo
  (poucos dólares/mês na memória padrão, estimativa: confirmar na calculadora do GCP) contra
  o orçamento de R$20/mês do projeto (`docs/monitoring.md`). A consolidação já ajuda: um único
  trigger recebe todo o tráfego de entries, então a instância fica quente com mais frequência
  e o número de cold starts cai. Reavaliar com medição (p95 de `execution_times` do
  `syncPublicTicket` e latência chamada→push em aparelho real); se passar ~5 s com fila ativa,
  ligar `minInstances: 1` **no `syncPublicTicket`** (agora é o dono do caminho), não em função
  nova. `onQueueAdvanced` ainda lê todas as entries `waiting` (índice `status`) a cada saída da
  espera; filas grandes (>1000 waiting) deveriam trocar por consulta limitada em futuro trabalho.

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
- `web/src/routes/QueuePage.tsx` é só o orquestrador (hooks, estado, efeitos e handlers);
  cada fase é um componente de apresentação em `web/src/routes/queue/` (`JoinForm`,
  `TicketView`, `CalledView`, `FeedbackView`, `StateViews` com erro/carregando/inexistente/
  fechada/obrigado/saiu, `Banners`, `QueueLogo`). Estado e ordem dos hooks ficam na página;
  a conta das opções de horário é `buildSlotOptions` (`lib/slots.ts`, testada).
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
  Functions e rules **não** têm deploy automático no CI (só pelo workflow assistido, `docs/deploy.md`).
- `FIREBASE_TOKEN` está obsoleto; é usado pelo `deploy-hosting` do `ci.yml` e é o último
  fallback de autenticação do `deploy.yml`.
  Deploy assistido (functions, rules, índices, hosting) é o workflow manual
  `.github/workflows/deploy.yml` (`workflow_dispatch`, só em `main`, `dry_run` padrão true,
  `all-ordered` exige `backfill_done`). Testes rodam sem credenciais, o dry-run usa service
  account somente leitura (`GCP_RO_*`) e o deploy real roda no environment `production`
  (aprovação), autenticando por WIF (`vars.GCP_WORKLOAD_IDENTITY_PROVIDER` +
  `vars.GCP_SERVICE_ACCOUNT`, definidos no environment), chave `GCP_SA_KEY` ou, por último,
  `FIREBASE_TOKEN`. Não há staging. Setup, ordem, rollback, o que o CI não faz e ações manuais acumuladas: `docs/deploy.md`.
  O CI usa `firebase-tools` fixo (15.33.0) e o deploy reaproveita o artefato `web-dist`
  do job `web`.
- Projeto no plano **Blaze** desde 01/10/2026; o roteador `syncPublicTicket` (que envia o push de "é a sua vez", antes `onEntryCalled`) publicado. A
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

## Aviso "me avise quando abrir" (web)

- Em `paused` a `QueuePage` já esconde o formulário (mensagem/`resumeAt` via `StatusNotice`); em
  `closed` e `paused` o componente `NotifyOpen` oferece "Me avise quando abrir". Só aparece se
  `pushSupport()` não for `unsupported` (precisa de `VITE_VAPID_KEY`). Sem telefone novo.
- Pedido: RTDB `queues/{id}/openWatchers/{uid} = {fcmToken, lang pt|en|es, createdAt}`
  (`web/src/lib/openWatch.ts`; `createdAt` é `serverTimestamp`, as rules exigem `=== now`).
  Rules: o próprio `uid` cria/lê/apaga o seu (só se `meta/name` existe e `meta/deleting` não
  é `true`; token 1–4096); só o dono lista; operador e outros clientes não leem.
- Trigger `onQueueOpened` (`meta/status`, `retry: true`, `processQueueOpened` em
  `functions/src/openwatch.js`): só em `closed|paused → open`. `.indexOn: ["createdAt"]`;
  pagina de 500 em 500 (até 20 rodadas) os pedidos com `createdAt >= now-24h`. Cada lote é
  **capturado antes do envio** com um único `update({uid: null})`, então reentrega do evento
  não duplica push. Envia `buildOpenMessage` (pt/en/es, `tag = queueId`); token inválido some;
  falha transitória do FCM (por mensagem ou do lote) regrava o pedido (vale até o TTL). Vencidos
  (> 24 h) também são apagados no open, em lotes. Falha no fetch/update inicial relança o erro
  para o retry da plataforma, sem ter enviado nada. `deleteQueue` apaga `openWatchers`
  (`QUEUE_RTDB_PATHS`).
- Limites: o pedido é renovável (novo `set` renova o `createdAt` e o TTL de 24 h). Pedidos em
  filas de terceiros ou que nunca abrem só saem pelo TTL: o RTDB não expira sozinho, então
  ficam no banco até a fila abrir (vencidos ignorados/apagados), ser apagada ou o cliente
  cancelar. A `tag = queueId` é a mesma do push de "chamado": o aviso de abertura pode ser
  substituído por ele (intencional; os dois só existem em momentos diferentes).
- Deploy: functions (`onQueueOpened`) → hosting → rules do RTDB. Web novo com rules antigas
  recebe `permission_denied` ao gravar (o botão mostra erro, nada quebra).

## Push (dono e cliente)

- **Dono:** o app registra o token em `owners/{uid}/devices/{token}`
  (`PushService`, `{token, platform, lang, updatedAt}`; rules só do próprio uid)
  depois do opt-in; `owners/{uid}.notifyNewEntries` (padrão ligado) desliga. Sair
  da conta apaga o token. Só mobile. O passo `joined` do `syncPublicTicket` (antes `onEntryJoined`) avisa dono +
  `operatorUids`, agrupa por idioma, usa `collapseKey/tag = queueId` e apaga
  tokens inválidos (`functions/src/push.js`). Canal Android `qio_new_entries`
  criado no `MainActivity`; permissão `POST_NOTIFICATIONS`; o toque abre o painel.
- **Cliente (web):** o botão "Ativar aviso" na tela da senha pede a permissão e
  grava `fcmToken` na entry; `joinQueue` grava `lang`; os passos `called` e
  `advanced` do `syncPublicTicket` ("Você é o próximo", uma vez por `nextNotifiedAt`) enviam em
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

## Widget público de espera (`/w/{idOuSlug}`)

- Página somente leitura "N na fila · ~X min" + estado (aberta/pausa/fechada, `statusMessage`,
  `resumeAt`, `opensAt`) para embed/TV; doc e iframe em `docs/embed.md`. Lê só `meta` e `public/`
  (nunca `entries`), auth anônima, listeners só com `ready` (`web/src/lib/useWidget.ts`).
  Lógica pura em `web/src/lib/widget.ts`: estimativa `(waiting + 1) × (avgServiceMinAuto ??
  avgServiceMin ?? 10)`, sem estimativa em `mode == 'schedule'`.
- **Entrada Vite separada**: `web/widget.html` → `src/widgetMain.tsx` (não carrega `QueuePage`,
  Messaging nem Functions). `firebase.json` reescreve `/w/**` → `/widget.html` (antes do `**`);
  no dev, `widgetRewritePlugin` em `vite.config.ts` faz o mesmo. `firebase.ts` não exporta mais
  `functions`: use `firebaseFunctions.ts` (import dinâmico no widget, só quando o valor é slug).
- Slug: valor que casa `isValidSlug` chama `resolveSlug` e faz `replace` para `/w/{queueId}`;
  `not-found` cai para tratar como queueId. Header `frame-ancestors *` só em `/w/**`; qualquer
  proteção global futura contra framing deve excluir essa rota.
- Deploy: só hosting (`web/dist` com `widget.html`). Nada de functions/rules.

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

## Link curto e cartaz

- **Slug**: `queueSlugs/{slug}` no Firestore `{queueId, ownerId, createdAt}`. O
  slug é o ID do doc, então a unicidade vem das rules. Formato `[a-z0-9-]{3,40}`
  sem `-` no início/fim; reservados: admin, api, app, q, c, w, n, privacidade,
  termos, assets, fonts, icons. Regras duplicadas em `app/lib/services/slug.dart`,
  `functions/src/slug.js`, `web/src/lib/slug.ts` e `firestore.rules`
  (`validSlugId`); `functions/test/slug.test.js` exige que os 4 tenham
  exatamente o mesmo conjunto de reservados, e os 3 módulos testam os mesmos casos.
- **Tombstone (30 dias)**: trocar/remover o slug (app) ou excluir fila/conta
  (`deleteQueue`/`deleteAccount`, `slugsToRelease`) **não apaga** o doc: grava
  `released: true` + `releasedAt` (serverTimestamp), mantendo `createdAt`. Durante
  30 dias só o dono anterior retoma o slug; depois qualquer dono não anônimo pode
  tomá-lo. Isso evita sequestro de QR já impresso. Ninguém apaga doc de slug
  (`delete: false`).
- **Rules**: `get` do slug ativo só pelo dono; tombstone e doc inexistente são
  legíveis por qualquer logado (o app usa isso para checar disponibilidade). `list`
  negado. `create` (e a retomada de tombstone, que é um `update`) exige `notAnonymous()`,
  `ownerId == auth.uid`, `queueId` casando `^[A-Za-z0-9_-]{1,128}$`, as 3 chaves,
  `createdAt == request.time` e dono da fila (`get(queues/{queueId})`, um único
  `get` por escrita). Retomar exige `released == true` e (mesmo dono ou
  `request.time > releasedAt + 30d`). Liberar (`update`) só pelo dono do doc, só
  `released`/`releasedAt == request.time`. Nenhuma validação nova no `update` de
  `queues` (limite de 1000 expressões; `history-retention` reescreve essa regra):
  `slug` e `posterTitle` (≤ 60) são campos livres lá, e o `posterTitle` só é
  validado no app. Um slug por fila: `setSlug` substitui o anterior.
- **App**: tile "Link curto" em Configurações (`queue_slug_tile.dart`), com aviso
  de que trocar o link invalida QRs impressos e que o antigo fica reservado por 30
  dias. `QueueService.setSlug` lê o doc novo (livre / meu tombstone / tombstone
  vencido = ok; ativo ou tombstone de outro dentro de 30 dias = `SlugTaken`) e o
  atual (só vira tombstone se existir, for meu, ativo e da mesma fila; senão é
  ignorado), e grava tudo em um batch com `queues/{id}.slug`. Se o batch der
  `permission-denied`, relê o novo e só então reporta "em uso". Slug vazio remove.
  Com slug, QR, copiar e compartilhar usam `https://qio.web.app/n/{slug}`; sem
  slug, `/q/{id}`.
- **Web**: `/n/:slug` (`SlugRedirect.tsx`) chama a callable `resolveSlug` (auth
  anônima) e faz `replace` para `/q/{queueId}`. Slug inexistente, inválido ou
  tombstone mostra "Fila não encontrada". A web **não** inicializa o Firestore SDK
  (pesaria no bundle); por isso a callable. `/q/{id}` e `/c/{id}` seguem iguais.
- **Rate limit de `resolveSlug`**: persistido no RTDB como no join (timestamps em
  transação Admin): `rateLimits/slug/{uid}` (30/min) e `rateLimits/slugIp/{hash}`
  (120/min; hash SHA-256 truncado de `request.rawRequest.ip`, sem IP em claro).
  `parseSlug` roda antes de qualquer contagem ou leitura, então slug inválido não
  custa nada. IP é fraco atrás de NAT/proxy compartilhado. O freio mais efetivo é
  o App Check (`ENFORCE_APP_CHECK`), que continua **desligado**; não ligue sem
  ativar App Check no web.
- **Cartaz** (`qr_poster_screen.dart`, PDF em `services/poster.dart`): A4, A5 e
  cartão de mesa (100×150 mm), faixa na cor da fila (`brandColor`, senão a cor do
  QR), logo (`logoUrl` só se `https://firebasestorage.googleapis.com/`; baixado
  pelo SDK do Storage com teto de 1 MB e timeout de 6 s; qualquer falha segue sem
  logo), nome (fallback "Fila"), frase opcional `posterTitle`, instruções pt/en/es
  e o link. O PDF usa a fonte padrão (Latin-1): `pdfSafeText` troca ★/—/aspas etc.
  e descarta emoji/CJK, e a tela avisa quando isso acontece. Compartilhar imagem
  (PNG da prévia), compartilhar PDF e imprimir.
- **Deploy**: functions (`resolveSlug`, `deleteQueue`, `deleteAccount`) → rules do
  Firestore → hosting → APK. Hosting antes das functions deixa `/n/` sem resolver;
  APK antes das rules falha ao salvar slug.
- **Limitações**: QR impresso com `/q/{id}` continua válido; QR impresso com
  `/n/{slug}` para de resolver se o dono trocar/remover o slug (o antigo só é
  reservado, não redireciona). O Android App Link cobre só `/q/*`, então `/n/`
  abre no navegador (que redireciona para `/q/`). Goldens não cobrem o cartaz.

## Tooling (adaptado do OpenCode)

O framework de agentes (product → builder → reviewer → advisor) e as regras de
shell/estilo são globais em `~/.claude/`. Slash commands: `/architect`,
`/implement`, `/review`, `/advise`. MCP Firebase via `@firebase-agent`.
