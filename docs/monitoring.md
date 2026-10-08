# Monitoramento técnico (issue #120)

Divisão do que já está no código e do que **só você pode fazer no console**.

## 1. O que já é código

### Logging estruturado das functions

- `functions/src/log.js`: `logError(event, err, ctx)` grava no `firebase-functions/logger`
  (severidade `ERROR`, JSON no Cloud Logging) com `event`, `error {name, message, code,
  stack}` e o `ctx`. Remove do `ctx`, em qualquer nível: `name`, `entryName`, `phone`,
  `token`, `fcmToken`, `tokens`, `comment`, `email`. Passe só IDs (`queueId`, `entryId`).
  `message` e `stack` do erro são truncados (500 e 2000 caracteres) e têm telefone
  `(DD) 9999-9999`, e-mails e sequências longas (40+ caracteres, tokens) mascarados.
  **Limitação**: o mascaramento é por padrão; nomes ou outros textos livres dentro de uma
  mensagem de erro de biblioteca não são detectados. Não coloque dados do usuário em
  mensagens de `Error`. `event` e `error` nunca são sobrescritos pelo `ctx`.
- Usado em: callables `joinQueue` e `submitFeedback` (apenas erros inesperados; `HttpsError`
  de cliente, como `invalid-argument`, `not-found`, `already-exists` ou
  `resource-exhausted`, não é logado; `HttpsError('internal')`, `unavailable` e erros
  inesperados são; `queueId` é validado como string e cortado em 64 caracteres),
  `syncPublicTicket` (relança o erro), `onEntryCalled`, `onEntryJoined`, `onQueueAdvanced`,
  `updateServiceEstimate` e `applyQueueSchedules`.
- Consulta no Logs Explorer:
  `severity>=ERROR AND resource.type="cloud_run_revision"` (functions v2) ou filtre por
  `jsonPayload.event="joinQueue failed"`.

### Eventos de produto (Firebase Analytics, sem PII)

| Evento           | Origem | Quando                                         | Parâmetros |
| ---------------- | ------ | ---------------------------------------------- | ---------- |
| `queue_created`  | app    | `QueueService.createQueue` concluído           | `queue_id` |
| `entry_called`   | app    | `callNext`/`callEntry` reservou a entry        | `queue_id` |
| `entry_served`   | app    | `markServed` concluído                         | `queue_id` |
| `queue_joined`   | web    | `joinQueue` criou entry nova (`existing=false`) | `queue_id` |
| `feedback_sent`  | web    | `submitFeedback` aceito                        | `queue_id` |

Nunca enviar nome, telefone, token, e-mail ou comentário.

**App** (`app/lib/services/analytics_service.dart`)

- `AnalyticsService` (interface) com `NoopAnalytics` e `FirebaseAnalyticsService`.
  `AnalyticsController.instance.load()` roda no `main()` e só ativa o real quando
  **não** é debug, **não** tem `USE_EMULATORS` e o usuário não fez opt-out.
- A coleta nasce desligada no Android (`firebase_analytics_collection_enabled=false`) e
  no iOS (`FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`) e é ligada em runtime só quando
  permitido. Coleta do Advertising ID (Android) e do IDFV (iOS) está desligada nos
  manifestos.
- Opt-out: Minha conta → "Ajudar a melhorar o Qio" (pt/en/es), persistido em
  `shared_preferences` (`analytics_opt_out`).

**Web** (`web/src/lib/analytics.ts`)

- Carregado de forma lazy via `import('firebase/analytics')`; nada de Analytics no topo
  do módulo (mesmo cuidado de `getMessagingSafe`).
- Só em `import.meta.env.PROD`, sem `VITE_USE_EMULATORS`, com `VITE_MEASUREMENT_ID`
  definido, sem opt-out e sem Do Not Track. Opt-out do visitante:
  `localStorage['qio:analytics-optout'] = '1'` (`setAnalyticsOptOut(true)`), exposto como
  link discreto no rodapé da página do cliente ("Não coletar estatísticas de uso" /
  "Voltar a permitir", pt/en/es; só aparece quando a coleta está configurada).
- `send_page_view: false`: a web não envia `page_view` automático, então a URL
  `/q/{queueId}` não vai como página; o `queue_id` só segue nos dois eventos acima.
- `google_signals` e personalização de anúncios desligados na configuração do SDK.
- `VITE_MEASUREMENT_ID` vem de `vars.VITE_MEASUREMENT_ID` no GitHub Actions (já repassado
  no `ci.yml`) e de `web/.env.local`.

## 2. Ações MANUAIS (exigem você, no console)

Nada abaixo foi feito pelo código. Projeto: `qio-app`.

1. **Ativar Analytics no projeto**: Console Firebase → Analytics → ativar/vincular a
   propriedade GA4. Copiar o ID de métrica do app Web (`G-XXXXXXXXXX`) e cadastrar em
   GitHub → Settings → Secrets and variables → Actions → **Variables** →
   `VITE_MEASUREMENT_ID` (e em `web/.env.local` se for testar).
2. **Desativar Google Signals e Ad ID**: GA4 → Admin → Configurações de dados → Coleta de
   dados → desligar Google Signals; Admin → Fluxos de dados → não ativar personalização
   de anúncios. Mantenha o IP anonimizado (padrão do GA4).
3. **Alerta de taxa de erro das functions** (Cloud Monitoring → Alerting → Create policy):
   - Métrica: `Cloud Run Revision > Request count` filtrada por `response_code_class =
     5xx` (callables) e/ou métrica baseada em log para `severity>=ERROR` com
     `jsonPayload.event` em `joinQueue failed`, `submitFeedback failed`,
     `syncPublicTicket failed`, `onEntryCalled failed`, `updateServiceEstimate failed`.
   - Condição sugerida: taxa/contagem de erros acima de 5 em 5 min.
   - Criar um **canal de notificação por e-mail** (Notification channels → Email) e
     anexar à política.
   - Teste (critério de aceite): forçar um erro e confirmar o e-mail.
4. **Uptime check**: Monitoring → Uptime checks → Create: HTTPS, host `qio.web.app`, path
   `/`, intervalo 5 min, ao menos 3 regiões; criar alerta ligado ao mesmo canal de e-mail.
5. **Orçamento**: Billing → Budgets & alerts → Create budget de **R$ 20/mês** com alertas
   em **50%, 90% e 100%** e e-mail ao administrador de faturamento.
6. **Validar no DebugView**: Firebase → Analytics → DebugView. No Android, build de
   release com `adb shell setprop debug.firebase.analytics.app com.qio.qio_app`
   (debug/emulators ficam sem Analytics por design). Na web, extensão "Google Analytics
   Debugger" no site de produção. Conferir que os 5 eventos acima chegam só com
   `queue_id`. O SDK/GA4 também emitem eventos automáticos (`first_open`,
   `session_start`, `user_engagement`, `screen_view` no app); a web não envia
   `page_view` (`send_page_view: false`, ver acima). Para reduzir ainda mais no app, desligue
   `screen_view`/eventos automáticos em GA4 → Admin → Fluxos de dados → Medição
   otimizada.

## 3. Ordem de deploy

functions (`firebase deploy --only functions`) → hosting (push na `main`, com
`VITE_MEASUREMENT_ID` configurada antes) → APK novo. As functions não dependem do web
nem do app para o logging; o web e o app não dependem de mudanças de rules.

## 4. App Check: métrica de chamadas com token

`joinQueue` e `submitFeedback` registram, a cada chamada, um log `INFO` sem PII:
`jsonPayload.event="appcheck"`, `jsonPayload.callable` e `jsonPayload.appCheck`
(`present` quando `request.app` existe, `absent` caso contrário). Função em
`functions/src/log.js` (`logAppCheck`).

Filtros do Logs Explorer:

- Todas as chamadas: `jsonPayload.event="appcheck"`
- Sem token: `jsonPayload.event="appcheck" AND jsonPayload.appCheck="absent"`

**Ação MANUAL (console)**: em Logging > Log-based metrics, criar duas métricas de contador
(`appcheck_calls_total` com o primeiro filtro e `appcheck_calls_absent` com o segundo) e um
alerta quando `absent / total` ficar acima de 5% após o rollout. O critério para ligar o
enforcement (≥95% com token por 3 a 7 dias) está em `docs/APPCHECK.md`. Com o enforcement
ligado, chamadas sem token são barradas antes do handler e não geram mais este log; use o
erro `unauthenticated` nas métricas de callables.

Atenção: `absent` mistura "sem token" e "token inválido" (`request.app` só existe com token
válido). Após ligar o enforcement a métrica fica cega para as rejeições; acompanhe-as pela
métrica de App Check do console (Firebase Console > App Check).
