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
```

### functions/
```bash
npm ci
npm test           # node --test (lógica pura em lib/join.js)
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

Sempre rode lint + analyze + test antes de dar uma tarefa como concluída (ver
`~/.claude/CLAUDE.md`). Não há testes em `web/`.

## Modelo de dados

- **Firestore** (durável, lado owner): `owners/{uid}`, `queues/{queueId}`,
  `queues/{queueId}/history/{entryId}`. Rules: `firestore.rules`.
- **RTDB** (tempo real): `queues/{queueId}/meta`, `queues/{queueId}/entries/{id}`,
  `queues/{queueId}/public/{id}`, `owners/{queueId}/ownerUid` (espelho de posse p/
  rules), `tickets/{queueId}` (contador de senha, incrementado por transação na
  callable `joinQueue`), `rateLimits/{queueId}/{uid}` (timestamps dos joins).
  Rules: `database.rules.json`.
- Rules do RTDB validam `queues/{id}/entries/{entryId}`: `ticket` número, `status` ∈ waiting/called/served/no_show/left, `uid` imutável, `name` 1–60 chars e `phone` vazio ou `(DD) 9999-9999`/`(DD) 99999-9999` (os dois só são checados na criação ou quando mudam), campos fora de ticket/name/phone/uid/fcmToken/status/joinedAt/calledAt/operatorId são rejeitados. `.validate` não roda em `remove()`.
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
- `deleteQueue`: remove do RTDB entries, `public`, `meta`, `tickets`,
  `deleteOperatorData` (operatorUids + docs de operadores/convite) e por último
  `owners/{id}` (rules de meta/entries dependem dele); só então apaga history e
  o doc da fila no Firestore. O dono pode remover `public` (rule só permite delete).

## Gotchas

- Aviso ao dono quando alguém entra na fila (som + vibração + SnackBar) é
  in-app: `QueuePanelScreen` assina `watchEntries` e usa `entry_diff.dart`. Só
  funciona com o painel aberto; push com o app fechado é trabalho futuro.
- `web/src/firebase.ts`: `getMessaging()` lança em navegadores sem suporte a FCM.
  Use sempre `getMessagingSafe()` (lazy, retorna `null`). Nunca chame
  `getMessaging` no topo de um módulo.
- FCM é **opcional**: sem `VITE_VAPID_KEY` o app funciona só com alerta na página.
  App Check é opcional sem `VITE_RECAPTCHA_SITE_KEY`; usa **reCAPTCHA Enterprise**
  (Fraud Defense), não v3. A chave não aceita `localhost` e não roda com
  emulators. No CI, as chaves vêm de `vars.VITE_RECAPTCHA_SITE_KEY` e
  `vars.VITE_VAPID_KEY` (GitHub → Actions → Variables). O app Flutter não usa App
  Check: APK fora da Play Store não passa no Play Integrity, então nunca ligue
  enforcement em RTDB/Firestore, só nas callables `joinQueue` e `submitFeedback` (chamadas só pela web).
- PWA instalável (`web/public/manifest.webmanifest` + ícones PNG) **sem cache
  offline e sem service worker próprio**: a fila é tempo real e bundle velho em
  cache é risco. Banner via `useInstallPrompt.ts` (só aparece na fase `ticket`).
  O Chrome pode não disparar `beforeinstallprompt` sem SW com `fetch` handler
  cobrindo `/`; o menu "Instalar app" e o fluxo iOS funcionam só com o manifest.
- `firebaseConfig` é duplicado em `web/src/firebase.ts` e
  `web/public/firebase-messaging-sw.js` — mantenha os dois em sincronia.
- URL de join: `https://qio.web.app/q/{queueId}` (hosting site `qio`). Duplicada em
  `functions/index.js` e `app/lib/services/queue_service.dart`.
- `web/src/lib/useQueue.ts`: listeners do RTDB só são anexados com `ready`
  (auth anônima concluída). Anexar antes faz a leitura ser negada e o `onValue`
  morre sem retry → spinner infinito no primeiro acesso pelo QR.
- Deploy hosting é automático no push p/ `main` (`.github/workflows/ci.yml`) **só
  se** `secrets.FIREBASE_TOKEN` existir; sem ele o job passa verde com um warning
  e o site **não** é atualizado. Confira o bundle publicado em `qio.web.app`.
  Functions e rules **não** têm deploy no CI.
- Projeto no plano **Blaze** desde 01/10/2026; `onEntryCalled` publicada. Push
  em segundo plano só funciona com `VITE_VAPID_KEY` no build da web (ainda não
  configurada).

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

## Tooling (adaptado do OpenCode)

O framework de agentes (product → builder → reviewer → advisor) e as regras de
shell/estilo são globais em `~/.claude/`. Slash commands: `/architect`,
`/implement`, `/review`, `/advise`. MCP Firebase via `@firebase-agent`.
