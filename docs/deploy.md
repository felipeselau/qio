# Deploy assistido (issue #166)

Decisão (#172, item 9): deploy de functions e rules continua **manual e disparado por
uma pessoa**, agora por um workflow assistido. **Não existe projeto de staging**: a
validação é `firebase deploy --dry-run` + testes com emulators; o primeiro ambiente real
é `qio-app`. Nada aqui foi executado contra produção na criação deste workflow.

## 1. O que existe

| Peça | Papel |
| --- | --- |
| `.github/workflows/deploy.yml` | `workflow_dispatch`: roda testes, `--dry-run` e, se `dry_run=false`, publica após aprovação |
| `.github/actions/firebase-setup` | Instala `firebase-tools@15.33.0` (mesma versão do `ci.yml`) e autentica |
| `.github/scripts/deploy-target.sh` | Mapeia o alvo para `firebase deploy --only ...` na ordem correta |
| `deploy-hosting` do `ci.yml` | Continua igual: publica hosting no push para `main` só se `FIREBASE_TOKEN` existir |

### Inputs

- `target`: `functions` | `rules-rtdb` | `rules-firestore` | `rules-storage` | `indexes` |
  `hosting` | `all-ordered`.
- `dry_run` (padrão **true**): só valida. Com `false`, o job `deploy` roda depois do
  `validate` e depende da aprovação do environment `production`.

### Jobs

1. `validate` (sempre): testes conforme o alvo, build do web (hosting) e dry-run.
   - `functions`, `all-ordered`: `npm test` em `functions/`.
   - `functions`, `rules-*`, `all-ordered`: `npm test` em `rules-tests/` (emulators
     firestore+database+storage+functions; Java 21).
   - `hosting`, `all-ordered`: `npm run lint` + `npm run build` do web (com as `vars.VITE_*`).
   - `indexes`: só dry-run (não há teste).
2. `deploy` (só com `dry_run=false`, `environment: production`): baixa o `dist` do web,
   publica na ordem abaixo.

### Ordem do `all-ordered`

`indexes` -> `functions` -> (backfill manual) -> `hosting` -> `database` (rules RTDB) ->
`firestore:rules` -> `storage` (rules).

Segue o CLAUDE.md (functions -> backfill -> hosting -> rules do RTDB -> rules do Firestore).
Acrescentamos `indexes` na frente (aditivo; functions e consultas novas dependem deles; a
criação do índice leva minutos, espere ficar `READY` antes de usar a feature) e `storage`
no fim (as rules do Storage não dependem de nada). O backfill **não** roda no workflow:
exige credencial Admin e julgamento humano (ver seção 5). Se o `all-ordered` precisar de
backfill, rode o alvo `functions`, faça o backfill, depois `hosting`, `rules-rtdb` e
`rules-firestore` separados.

Functions é publicado **sem `--force`**: o CLI não apaga função removida do código em modo
não interativo (o deploy falha apontando quais). Apague à mão com
`firebase functions:delete <nome> --region us-central1`.

## 2. Configuração única (dono do repositório)

### 2.1 Environment `production` com aprovação

GitHub -> Settings -> Environments -> New environment -> `production`:

1. Marque **Required reviewers** e adicione quem pode aprovar (o próprio dono; ative
   "Prevent self-review" só se houver um segundo revisor).
2. Em **Deployment branches and tags**, escolha *Selected branches* -> `main`.
3. (Opcional) **Wait timer** de alguns minutos.

O dry-run **não** usa o environment (não pede aprovação). Por isso as credenciais
precisam existir também no nível do repositório (ou ser repetidas no environment, se
preferir restringi-las: nesse caso o dry-run não autentica e falha na etapa de setup).
Recomendação: variáveis no repositório (não são segredos) e, se usar chave JSON,
secret no repositório.

### 2.2 Autenticação (preferência: Workload Identity Federation)

Prioridade aplicada pela action `firebase-setup`:

1. **WIF** (sem chave de longa duração): `vars.GCP_WORKLOAD_IDENTITY_PROVIDER` +
   `vars.GCP_SERVICE_ACCOUNT`.
2. **Chave JSON da service account**: `secrets.GCP_SA_KEY` (fallback se WIF não puder ser
   usado; tem validade indefinida, rotacione).
3. **`secrets.FIREBASE_TOKEN`** (obsoleto, `firebase login:ci`): último recurso, o job
   emite warning.

Sem nenhuma das três o job falha com mensagem clara.

Passo a passo WIF (gcloud, projeto `qio-app`; ajuste `OWNER/REPO`):

```bash
PROJECT=qio-app
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')
gcloud iam service-accounts create github-deploy --project "$PROJECT" \
  --display-name "GitHub Actions deploy"
gcloud iam workload-identity-pools create github --project "$PROJECT" \
  --location global --display-name "GitHub"
gcloud iam workload-identity-pools providers create-oidc github-oidc --project "$PROJECT" \
  --location global --workload-identity-pool github \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository=='felipeselau/qio'"
gcloud iam service-accounts add-iam-policy-binding \
  "github-deploy@$PROJECT.iam.gserviceaccount.com" --project "$PROJECT" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/felipeselau/qio"
```

Variáveis do repositório (Settings -> Secrets and variables -> Actions -> Variables):

- `GCP_WORKLOAD_IDENTITY_PROVIDER` =
  `projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github/providers/github-oidc`
- `GCP_SERVICE_ACCOUNT` = `github-deploy@qio-app.iam.gserviceaccount.com`

Papéis da service account (mínimo sugerido; confira no console se algum deploy pedir mais):

| Alvo | Papéis |
| --- | --- |
| rules RTDB / Firestore / Storage / índices | `roles/firebaserules.admin`, `roles/datastore.indexAdmin`, `roles/firebasedatabase.admin` |
| hosting | `roles/firebasehosting.admin` |
| functions | `roles/cloudfunctions.admin`, `roles/iam.serviceAccountUser`, `roles/artifactregistry.writer`, `roles/cloudscheduler.admin`, `roles/run.admin`, `roles/eventarc.admin`, `roles/pubsub.admin` (ou `roles/firebase.admin` + `roles/iam.serviceAccountUser` para simplificar) |

Habilite as APIs `iamcredentials.googleapis.com` e `cloudresourcemanager.googleapis.com`.
Ao ser a primeira vez de functions com a service account, o deploy pode precisar de
`roles/iam.serviceAccountUser` sobre a service account padrão de runtime.

### 2.3 Variáveis do build do web

As mesmas do `ci.yml`: `VITE_RECAPTCHA_SITE_KEY`, `VITE_VAPID_KEY`, `VITE_MEASUREMENT_ID`,
`VITE_OWNER_APP_URL`, `VITE_PRIVACY_CONTACT` (Actions Variables).

### 2.4 Migrar também o deploy automático do hosting (opcional, futuro)

O job `deploy-hosting` do `ci.yml` não foi alterado (continua com `FIREBASE_TOKEN`). Quando
o WIF estiver validado pelo workflow assistido, o caminho é trocar esse job para usar
`./.github/actions/firebase-setup` com `permissions: id-token: write` e remover o secret
`FIREBASE_TOKEN`. Até lá, hosting também pode ser publicado pelo alvo `hosting`.

## 3. Como usar

1. Actions -> **Deploy (assistido)** -> Run workflow.
2. Escolha o `target`, deixe `dry_run` marcado. Leia o log do dry-run.
3. Rode de novo com `dry_run` desmarcado; aprove no environment `production`.
4. Faça o checklist pós-deploy.

Pelo CLI: `gh workflow run deploy.yml -f target=functions -f dry_run=true`.

`firebase deploy --dry-run` valida a configuração e as rules (sintaxe e referências) sem
publicar. Não substitui os testes de rules, que o workflow roda antes (emulators). O MCP
`firebase_validate_security_rules` não está disponível para agentes aqui; use os testes de
`rules-tests/` e o dry-run.

## 4. Checklists

### Antes

- [ ] `main` verde no CI (flutter, web, functions, rules).
- [ ] Dry-run do alvo passou.
- [ ] Backup recente do Firestore (`docs/backup.md`); para mudança de rules/dados do RTDB,
      `ops/backup-rtdb.sh`.
- [ ] Ordem de deploy da feature relida no CLAUDE.md (cada seção traz a sua).
- [ ] Mudança em `functions/.env` conferida (`ENFORCE_APP_CHECK*` seguem `false` salvo rollout
      planejado, `docs/APPCHECK.md`).
- [ ] Orçamento/alertas ativos (`docs/monitoring.md`).

### Depois

- [ ] Functions: `firebase functions:list --project qio-app` (todas `ACTIVE`, runtime nodejs22);
      logs sem erro (`firebase functions:log` ou Cloud Logging) por alguns minutos.
- [ ] Fluxo de ponta a ponta: abrir `https://qio.web.app/q/<fila>`, entrar na fila, chamar no
      app, finalizar.
- [ ] Hosting: confira o bundle publicado em `qio.web.app` (hash do `index-*.js`).
- [ ] Rules: tente uma leitura/escrita negada pelo cliente e uma permitida.
- [ ] Índices: console Firestore -> Índices com estado `Ready`.
- [ ] Alertas de erro do Cloud Monitoring sem disparo.

## 5. Backfills (manuais, fora do workflow)

Credencial Admin, ex. `GOOGLE_APPLICATION_CREDENTIALS` e `GOOGLE_CLOUD_PROJECT=qio-app`:

```bash
node functions/scripts/backfill-public.js          # public/ para entries existentes
node functions/scripts/backfill-waiting-count.js   # contador de espera
```

Rode depois das functions e antes de hosting/rules.

## 6. Rollback

| Alvo | Como |
| --- | --- |
| Hosting | Console -> Hosting -> Histórico de versões -> **Rollback**; ou `firebase hosting:clone qio:<VERSION_ID> qio:live` |
| Functions | `git revert` do commit e novo deploy do alvo `functions` (não há rollback nativo). Para uma função com defeito, `firebase functions:delete <nome>` só se nada depender dela |
| Rules (RTDB, Firestore, Storage) | `git revert` e redeploy do alvo da rule. Console -> Rules mostra o histórico e permite republicar uma versão anterior |
| Índices | Aditivos; remover só se necessário, pelo console (remover derruba consultas que dependem deles) |
| Dados | Restaurar backup em banco **novo** (`docs/backup.md`) |
| App (APK) | Redistribuir o APK anterior; o app antigo continua compatível com as rules novas salvo nota em contrário no CLAUDE.md |

Antes de reverter rules, lembre da ordem: reverter rules **antes** de reverter hosting/app
quando a rule nova bloqueia o cliente, e o contrário quando a rule antiga bloqueia o
cliente novo.

## 7. O que o CI NÃO faz

- Não publica functions, rules (RTDB/Firestore/Storage) nem índices no push para `main`.
- Não roda backfills.
- Não publica o APK nem faz build mobile de release.
- Não cria/ativa App Check, Cloud Scheduler, orçamento, alertas, Analytics (ações do console).
- Não faz rollback automático nem smoke test pós-deploy.
- Não tem staging: o dry-run e os emulators são a única validação antes de produção.
- O `deploy-hosting` do `ci.yml` só funciona com `FIREBASE_TOKEN` (obsoleto).

## 8. Ações manuais acumuladas do roadmap

Marque conforme concluir. Use o alvo indicado do workflow ou o comando equivalente.
Conferir antes se já foi feito: `firebase functions:list --project qio-app`.

### Functions (alvo `functions`; ou `--only functions:<nome>`)

- [ ] `joinQueue` (claim/atualizações do join, slots, capacidade) -> antes das rules do RTDB.
- [ ] `resolveSlug` (callable nova).
- [ ] `findCustomerData`, `exportCustomerData`, `eraseCustomerData` (DSR; `ENFORCE_APP_CHECK_DSR=false`;
      `DSR_HASH_PEPPER` opcional como segredo, ver `functions/.env`).
- [ ] `expireStaleEntries` (agendada; exige Cloud Scheduler / Blaze).
- [ ] `onQueueOpened` (trigger RTDB; avisos "me avise quando abrir").
- [ ] `deleteQueue`, `deleteAccount` (antes de distribuir o APK; `ENFORCE_APP_CHECK_DELETE=false`).
- [ ] Demais já documentadas: `submitFeedback`, `updateServiceEstimate`, `evaluateQueueAlerts`,
      `applyQueueSchedules`, `onEntryCalled`, `onEntryJoined`, `onQueueAdvanced`,
      `syncPublicTicket`, `reconcileWaitingCounts`, `purgeOldHistory`, `addManualEntry`.
      Um deploy completo de `functions` cobre todas.

### Rules e índices

- [ ] Rules do RTDB (`database.rules.json`), por último entre functions/hosting.
- [ ] Rules do Firestore (`firestore.rules`); antes do APK que grava campos novos
      (`groupId`, `recalls`/`skips`, alertas, slots).
- [ ] Rules do Storage (`storage.rules`) se mudaram.
- [ ] Índices do Firestore (`firestore.indexes.json`), incl. `history: result ASC,
      finishedAt DESC` e os mais novos.

### Hosting, backfill e APK

- [ ] Hosting (`qio.web.app`): push para `main` com `FIREBASE_TOKEN`, ou alvo `hosting`.
- [ ] Backfill de `public/` e do contador de espera (seção 5), se faltarem dados.
- [ ] APK: `flutter build apk --release` (exige `app/android/key.properties`) e distribuição;
      depois das functions e rules correspondentes.
- [ ] Atualizar `web/public/.well-known/assetlinks.json` com o SHA-256 da chave de release.

### Console / ações do dono

- [ ] App Check: ativar e medir antes de `ENFORCE_APP_CHECK=true` (`docs/APPCHECK.md`).
- [ ] Teste manual do push em segundo plano (`docs/FCM.md`).
- [ ] Alertas de erro, uptime check, orçamento e Analytics (`docs/monitoring.md`).
- [ ] Backups agendados do Firestore (`docs/backup.md`, seção 7).
- [ ] Configurar WIF e o environment `production` (seção 2) e apagar `FIREBASE_TOKEN`.
