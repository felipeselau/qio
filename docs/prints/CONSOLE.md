# Firebase Console — configuração usada (projeto `qio-app`)

Snapshot em 2026-09-08, coletado via Firebase MCP / CLI (conta
`felipeselau159@gmail.com`). Substitui screenshots do console.

## Projeto

| Item | Valor |
| --- | --- |
| Project ID | `qio-app` |
| Project Number | `981965097928` |
| Plano de billing | **Spark (gratuito)** — billing **não** habilitado |
| Região RTDB | `us-central1` (`qio-app-default-rtdb.firebaseio.com`) |
| Hosting site | `qio` → `https://qio.web.app` |

## Apps registrados (6)

| Plataforma | displayName | Package / Bundle | App ID |
| --- | --- | --- | --- |
| Android | qio_app (android) | `com.qio.qio_app` | `1:981965097928:android:1afa4bedefcdf0f6d4cefd` |
| Android | qio (android) | `com.example.qio` *(legado)* | `1:981965097928:android:31c4fd9f1a0aa4dfd4cefd` |
| iOS | qio_app (ios) | `com.qio.qioApp` | `1:981965097928:ios:b29b581959b843f7d4cefd` |
| iOS | qio (ios) | `com.example.qio` *(legado)* | `1:981965097928:ios:6638f3a65e4d34d3d4cefd` |
| Web | qio (web) | — | `1:981965097928:web:b08d7d1bfce182d3d4cefd` |
| Web | qio (windows) | — | `1:981965097928:web:bfd9c7c4e7edc778d4cefd` |

> Os apps `com.example.qio` e o web "windows" são de scaffolds antigos e não são
> usados pelo build atual (`app/lib/firebase_options.dart` aponta para
> `com.qio.*`). Podem ser removidos no console.

## Authentication — Sign-in methods

| Provedor | Status | Evidência |
| --- | --- | --- |
| **E-mail/senha** | Ativo | contas `felipetccqio@gmail.com`, `teste@teste.com` existem |
| **Anônimo** | Ativo | dezenas de usuários anônimos (clientes web) |
| **Google** | No código do app (`google_sign_in`, `signInWithGoogle`) — enablement no console não verificável via MCP; confirmar em Authentication → Sign-in method |

Contas de proprietário reais: `felipetccqio@gmail.com` (Felipe tcc),
`teste@teste.com` (Teste). O resto são clientes anônimos.

## Firestore — Regras (deploy ativo, confere com `firestore.rules` do repo)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /owners/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /queues/{queueId} {
      allow read:   if request.auth != null && resource.data.ownerId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
      match /history/{entryId} {
        allow read, write: if request.auth != null
          && get(/databases/$(database)/documents/queues/$(queueId)).data.ownerId == request.auth.uid;
      }
    }
  }
}
```

Coleções em uso: `owners/{uid}`, `queues/{queueId}`,
`queues/{queueId}/history/{entryId}`.

## Realtime Database — Regras

Versão do repo (`database.rules.json`) após correção desta branch — o nó
`owners/{queueId}` foi restringido a *criar-ou-dono* (antes qualquer usuário
autenticado podia se declarar dono de qualquer fila):

```json
{
  "rules": {
    "queues": {
      "$queueId": {
        "meta": {
          ".read": "auth != null",
          ".write": "root.child('owners').child($queueId).child('ownerUid').val() === auth.uid"
        },
        "entries": {
          ".read": "auth != null",
          "$entryId": {
            ".read": "auth != null",
            ".write": "(!data.exists() && newData.child('uid').val() === auth.uid) || (data.child('uid').val() === auth.uid) || (root.child('owners').child($queueId).child('ownerUid').val() === auth.uid)"
          }
        }
      }
    },
    "owners":  { "$queueId": { ".read": "auth != null", ".write": "auth != null && (!data.exists() || data.child('ownerUid').val() === auth.uid)" } },
    "tickets": { "$queueId": { ".read": "auth != null", ".write": "auth != null" } }
  }
}
```

> **Pendente:** `firebase deploy --only database` — a regra endurecida de
> `owners` ainda não está publicada.

Estrutura em uso:
- `queues/{queueId}/meta` — `{ name, description, status, serving, nextTicket, avgServiceMin, updatedAt }`
- `queues/{queueId}/entries/{entryId}` — `{ ticket, name, phone, uid, status, joinedAt, calledAt, fcmToken? }`
- `owners/{queueId}/ownerUid` — espelho de posse (para as rules)
- `tickets/{queueId}` — contador de senha (incrementado por transação no cliente web)

## Cloud Functions

**Nenhuma função deployada** (`functions:list` → vazio).

`functions/index.js` define `onEntryCalled` (trigger RTDB → push FCM), mas:
- Functions v2 exige plano **Blaze**; o projeto está no **Spark**.
- Consequência: **push notification quando a página do cliente está fechada
  não funciona em produção hoje.** Só funciona o alerta em foreground
  (`web/src/lib/fcm.ts` + som/vibração na `QueuePage`).

Para ativar: upgrade para Blaze → `firebase deploy --only functions`.

## Hosting

| Item | Valor |
| --- | --- |
| Site | `qio` (`qio.web.app`) |
| Último deploy | 3 ago 2026 19:56 — por `felipeselau159@gmail.com` |
| Origem | `web/dist` (build do Vite) |
| Rewrites | `**` → `/index.html` (SPA) |
| CI | deploy automático no push p/ `main` se `secrets.FIREBASE_TOKEN` existir (`.github/workflows/ci.yml`) |

## FCM / Web Push

- `web/public/firebase-messaging-sw.js` presente (service worker de background).
- Requer `VITE_VAPID_KEY` no `.env` (Cloud Messaging → Web Push certificates).
- Sem a chave, o cliente funciona sem push (degrada para alerta na página).

## App Check

- Provedor no código: reCAPTCHA v3 (`web/src/firebase.ts`), só ativa com
  `VITE_RECAPTCHA_SITE_KEY`.
- Enforcement no console: não verificado — checar App Check → APIs.

## Limpeza sugerida no console / RTDB

Dados legados de scaffolds antigos ainda no RTDB (schema anterior, não usados
pelo código atual):
- `queues/-OwoCFZ6-IfsQ_JKTZfz/info` (schema `info`/`currentNumber`/`professionalId`)
- nó `professionals/`
- vários órfãos em `tickets/` (IDs de filas que não existem mais)
- fila `1CqEreWsKcTzZFpfg2kv` (status `closed`, sem entries)
