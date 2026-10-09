# FCM Push Notifications — Guia de ativação (fase 2)

## Atualização (v1.4)

- O pedido de permissão deixou de ser automático: na tela da senha o cliente
  toca em **Ativar aviso** (gesto do usuário). Se a permissão já foi concedida
  antes, o token é registrado sozinho; se foi negada, a página mostra um texto.
- `joinQueue` grava o idioma (`lang`) na entry e as notificações saem em
  pt/en/es (`functions/src/webpush.js`).
- Passo `advanced` do `syncPublicTicket` (antes `onQueueAdvanced`): quando alguém sai da espera (chamado, saiu, removido), o novo
  primeiro da fila recebe **"Você é o próximo"** uma única vez (`nextNotifiedAt`).
- O service worker só desenha a notificação quando o payload não traz
  `notification` (evita duplicar o aviso que o FCM já exibe).
- A chave **VAPID** (`VITE_VAPID_KEY`) já está configurada nas Actions
  variables do GitHub e presente no bundle publicado. No iOS o push web só
  funciona com a PWA instalada na tela inicial.

## Status atual

O projeto está no plano **Blaze (pay-as-you-go)** desde 01/10/2026 (Cloud
Functions não rodam no plano Spark grátis — `cloudbuild.googleapis.com` só
habilita com billing) e as functions v2 estão publicadas: `joinQueue`,
`submitFeedback`, `syncPublicTicket` (roteador que também envia os pushes de
nova entry, "é a sua vez" e "você é o próximo"), `updateServiceEstimate`,
`applyQueueSchedules` e `evaluateQueueAlerts` (lista em `functions/index.js`). O custo esperado
fica dentro da cota gratuita no volume do TCC. A `VITE_VAPID_KEY` já está
configurada (Actions variables e bundle publicado); falta só validar o push em
segundo plano num aparelho real.

### Teste manual pendente (ação do dono)

- [ ] Android/Chrome: entrar na fila pelo QR, tocar em **Ativar aviso**, fechar
  a aba, chamar a senha pelo app e confirmar que a notificação chega.
- [ ] iOS: instalar a PWA na tela inicial, ativar o aviso, fechar a PWA, chamar a
  senha pelo app e confirmar a notificação.

O alerta **in-page** continua funcionando (listener RTDB no client
web: som + vibração + tela verde quando a senha é chamada).

## O que já está pronto (commit XXXX)

- `functions/src/handlers/push.js` (`notifyEntryCalled`, roteado por `syncPublicTicket`): trigger RTDB
  `queues/{queueId}/entries/{entryId}`, quando status vira `called` → envia FCM
  push com título "É a sua vez!" + senha + nome da fila (lido de `meta/name`),
  com `webpush.fcmOptions.link` apontando pra `https://qio.web.app/q/{queueId}`.
  Requer `fcmToken` salvo na entry (o client web salva depois que o cliente toca em **Ativar aviso**).
- `functions/package.json` — node 22, firebase-admin ^13, firebase-functions ^6.
- `web/public/firebase-messaging-sw.js` — service worker (compat CDN 12.17.0),
  mostra a notificação em background.
- `web/src/lib/fcm.ts` — `getFcmToken()` (isSupported + getToken com VAPID key,
  null se indisponível/negado) e `listenForMessages()` (foreground, mostra
  `new Notification` só quando a aba está oculta — o RTDB já cuida da tela).
- `web/src/routes/QueuePage.tsx` — na tela do ticket, salva o token na entry
  (uma vez por entry); tudo **guardado pela presença de `VITE_VAPID_KEY`** —
  sem a key, zero mudança de comportamento (in-page segue normal).
- `firebase.json` — seção `functions` (source: functions, codebase: default,
  runtime nodejs22).

## Passos pra ativar (quando quiser, ~5 min)

1. **Upgrade pra Blaze**: https://console.firebase.google.com/project/qio-app/usage/details
   (adiciona cartão; free tier cobre ~2M invocações/mês + FCM — só cobra acima).
2. **VAPID key**: https://console.firebase.google.com/project/qio-app/settings/cloudmessaging
   → Web Push certificates → Generate key pair → Copy (começa com `B...`).
3. Crie `web/.env`:
   ```
   VITE_VAPID_KEY=<chave copiada>
   ```
4. Deploy da function:
   ```
   cd functions && npm install && cd ..
   firebase deploy --only functions --project qio-app
   ```
5. Rebuild + deploy do hosting (o client precisa do build com a env var):
   ```
   cd web && npm run build && cd ..
   firebase deploy --only hosting --project qio-app
   ```
6. Teste: entre numa fila pelo celular (Chrome/Edge), confirme a permissão de
   notificação na tela do ticket, feche a aba, e chame a pessoa pelo app.

## Limitações conhecidas

- **iOS Safari**: push web só funciona com PWA instalada na home screen
  (limitação da Apple). Sem PWA, o usuário iOS só tem o alerta in-page.
- O token FCM é salvo na entry; quem entrou ANTES da ativação não tem token
  (precisa sair e entrar de novo).
