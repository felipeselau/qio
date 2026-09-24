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
```

Sempre rode lint + analyze + test antes de dar uma tarefa como concluída (ver
`~/.claude/CLAUDE.md`). Não há testes em `web/` nem `functions/`.

## Modelo de dados

- **Firestore** (durável, lado owner): `owners/{uid}`, `queues/{queueId}`,
  `queues/{queueId}/history/{entryId}`. Rules: `firestore.rules`.
- **RTDB** (tempo real): `queues/{queueId}/meta`, `queues/{queueId}/entries/{id}`,
  `owners/{queueId}/ownerUid` (espelho de posse p/ rules), `tickets/{queueId}`
  (contador de senha, incrementado por transação no cliente web). Rules:
  `database.rules.json`.
- O app faz **dual-write**: Firestore (fonte da verdade) + espelho no RTDB
  (`meta` + `owners/{queueId}`). `_ensureOwnerMirror` reconcilia antes de escritas.

## Fluxo de estados da entry

`waiting → called → served | no_show` (owner) ou `→ left` (cliente).
`served`/`no_show` arquivam em `history/` e removem do RTDB. Web limpa o
`entryId` de `localStorage` quando a entry some do RTDB (`useQueue.ts`).

## Gotchas

- `web/src/firebase.ts`: `getMessaging()` lança em navegadores sem suporte a FCM.
  Use sempre `getMessagingSafe()` (lazy, retorna `null`). Nunca chame
  `getMessaging` no topo de um módulo.
- FCM é **opcional**: sem `VITE_VAPID_KEY` o app funciona só com alerta na página.
  App Check é opcional sem `VITE_RECAPTCHA_SITE_KEY`.
- `firebaseConfig` é duplicado em `web/src/firebase.ts` e
  `web/public/firebase-messaging-sw.js` — mantenha os dois em sincronia.
- URL de join: `https://qio.web.app/q/{queueId}` (hosting site `qio`). Duplicada em
  `functions/index.js` e `app/lib/services/queue_service.dart`.
- Deploy hosting é automático no push p/ `main` (`.github/workflows/ci.yml`), se
  `secrets.FIREBASE_TOKEN` existir. Functions e rules **não** têm deploy no CI.

## Tooling (adaptado do OpenCode)

O framework de agentes (product → builder → reviewer → advisor) e as regras de
shell/estilo são globais em `~/.claude/`. Slash commands: `/architect`,
`/implement`, `/review`, `/advise`. MCP Firebase via `@firebase-agent`.
