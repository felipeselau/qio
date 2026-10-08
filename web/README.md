# Qio — página do cliente

React 19 + TypeScript + Vite + Firebase JS SDK. É a página aberta pelo QR
(`https://qio.web.app/q/{queueId}`): o cliente entra na fila pela callable
`joinQueue`, acompanha a posição em tempo real e recebe o aviso de chamada.
Visão geral do monorepo: [`../README.md`](../README.md) e [`../CLAUDE.md`](../CLAUDE.md).

## Comandos

```bash
npm ci
cp .env.example .env   # VITE_VAPID_KEY, VITE_RECAPTCHA_SITE_KEY, VITE_MEASUREMENT_ID (todas opcionais)
npm run dev
npm run build          # tsc -b && vite build (roda no CI)
npm run lint           # oxlint
```

Não há testes automatizados neste módulo; o CI roda apenas `npm run build`.

## Variáveis de ambiente

- `VITE_VAPID_KEY` — push em segundo plano (FCM); ver [`../docs/FCM.md`](../docs/FCM.md).
- `VITE_RECAPTCHA_SITE_KEY` — App Check (reCAPTCHA Enterprise); ver [`../docs/APPCHECK.md`](../docs/APPCHECK.md).
- `VITE_MEASUREMENT_ID` — Analytics com opt-out; ver [`../docs/monitoring.md`](../docs/monitoring.md).
- `VITE_USE_EMULATORS` — usa os emulators locais (desliga App Check e Analytics).

`src/firebase.ts` e `public/firebase-messaging-sw.js` duplicam o `firebaseConfig`;
mantenha os dois em sincronia.
