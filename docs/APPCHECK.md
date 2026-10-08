# App Check (issue #14)

## Arquitetura e escopo

- Provedor: **reCAPTCHA Enterprise** (tipo Web) no projeto `qio-app`. Só o **web** usa App Check
  (`web/src/firebase.ts`, `initializeAppCheck` com `ReCaptchaEnterpriseProvider`, ativo só com
  `VITE_RECAPTCHA_SITE_KEY` e sem `VITE_USE_EMULATORS`).
- Enforcement **somente nas callables** `joinQueue` e `submitFeedback`
  (`enforceAppCheck` em `functions/index.js`, controlado por `ENFORCE_APP_CHECK` em
  `functions/.env`, commitado com `false`).
- **Sem enforcement** em Realtime Database, Firestore e Storage: o app Flutter (dono/operador)
  não usa App Check e um APK fora da Play Store não passa no Play Integrity. Ligar
  enforcement nesses serviços no console derrubaria o app.
- Fora de escopo: `firebase_app_check` no Flutter, `request.app` nas rules, reCAPTCHA v3.
- Com enforcement ligado, o SDK web envia o token no header `X-Firebase-AppCheck`; sem token
  válido a callable responde `unauthenticated` antes de executar o handler. O web mostra
  "Recarregue a página" nesse caso.

## Checklist do console (AÇÕES MANUAIS DO USUÁRIO)

1. [ ] Habilitar a API **reCAPTCHA Enterprise** no projeto `qio-app`
   (https://console.cloud.google.com/apis/library/recaptchaenterprise.googleapis.com).
2. [ ] Criar chave reCAPTCHA Enterprise tipo **Web (site/score)** no **mesmo projeto
   `qio-app`**, com os domínios `qio.web.app`, `qio-app.web.app` e `qio-app.firebaseapp.com`.
   **Sem `localhost`** (para dev use debug token, ver abaixo).
3. [ ] Firebase Console > App Check > Apps: registrar o app **Web** com reCAPTCHA Enterprise
   e a site key criada.
4. [ ] GitHub > Settings > Secrets and variables > Actions > **Variables**: definir
   `VITE_RECAPTCHA_SITE_KEY` com a site key.
5. [ ] Redeploy do hosting (push em `main` com `FIREBASE_TOKEN` ou `firebase deploy --only
   hosting`) e conferir o bundle em `qio.web.app`.
6. [ ] Criar a log-based metric e o alerta descritos em `docs/monitoring.md` (seção App Check).
7. [ ] Só depois do rollout abaixo: `ENFORCE_APP_CHECK=true` em `functions/.env`, deploy de
   `functions:joinQueue` e, depois de validar, `functions:submitFeedback`.

Não ative "Enforce" para Realtime Database, Firestore ou Storage em App Check > APIs.

## Rollout em etapas

1. **Observação**: com a flag `false`, o web já envia o token quando a chave está configurada.
   As functions registram `appCheck: present|absent` em cada chamada de `joinQueue` e
   `submitFeedback` (evento `appcheck`). Acompanhe também App Check > Apps > métricas.
2. **Critério para ligar**: pelo menos **95%** das chamadas com `appCheck=present` durante
   **3 a 7 dias** seguidos. Chamadas `absent` residuais costumam ser abas antigas em cache
   (sem App Check) e scripts.
3. **Enforcement em `joinQueue`**: `ENFORCE_APP_CHECK_JOIN=true` (ou `ENFORCE_APP_CHECK=true`)
   e `firebase deploy --only functions:joinQueue`. Monitore erros `unauthenticated` e
   entradas na fila por 24 h.
4. **Enforcement em `submitFeedback`**: `ENFORCE_APP_CHECK_FEEDBACK=true` e
   `firebase deploy --only functions:submitFeedback`.

## Rollback

Definir a flag como `false` (ou removê-la) em `functions/.env` e refazer o deploy da function
afetada (`--only functions:joinQueue` / `functions:submitFeedback`). Não é preciso mexer no
web nem no console.

## Dev local

Com `VITE_USE_EMULATORS=true` o App Check não é inicializado. Para testar contra o projeto
real em `npm run dev`:

1. Rode o dev server com `VITE_RECAPTCHA_SITE_KEY` definida e `VITE_APPCHECK_DEBUG_TOKEN=true`
   (o SDK gera um token e o imprime no console do navegador) ou um UUID já registrado.
2. Registre o token em Firebase Console > App Check > Apps > Web > Gerenciar tokens de debug.

O debug token só é aplicado em `import.meta.env.DEV`; nunca em build de produção.
