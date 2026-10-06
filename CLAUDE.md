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
  `enforceAppCheck` na callable. Só mude para `true` depois de ativar App Check no
  web (`VITE_RECAPTCHA_SITE_KEY`) e registrar o app no console.
- Backfill único do `public` para entries já existentes:
  `node functions/scripts/backfill-public.js` (credencial padrão do Admin SDK,
  ex. `GOOGLE_APPLICATION_CREDENTIALS`/`GOOGLE_CLOUD_PROJECT=qio-app`).
- **Ordem de deploy**: functions → backfill → hosting → database rules. Rules por
  último, senão o web antigo perde a escrita/leitura antes de o novo estar no ar.
  APK v1.1.0 (dono/operador) continua compatível com as rules novas. Web antigo em
  cache falha ao entrar na fila até recarregar.

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
  enforcement em RTDB/Firestore, só na callable `joinQueue` (chamada só pela web).
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
