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
  `test` e do `dry-run` e depende da aprovação do environment `production`.
- `backfill_done` (padrão false): **obrigatório `true` para `all-ordered`** (confirma que o
  backfill foi feito ou é desnecessário; ver seção 5). O job `test` falha logo no início sem isso.

### Jobs

Todos usam `ref: ${{ github.sha }}`. Os jobs com credenciais só rodam em `refs/heads/main`
(disparo de outra branch executa apenas os testes).

1. `test` (sem credenciais): testes conforme o alvo e build do web.
   - `functions`, `all-ordered`: `npm test` em `functions/` e `npm test` em `rules-tests/`
     (rules + callables; Java 21).
   - `rules-rtdb`, `rules-firestore`, `rules-storage`: `npm run test:rules` em `rules-tests/`
     (sem functions).
   - `hosting`, `all-ordered`: `npm run lint` + `npm run build` do web (com as `vars.VITE_*`).
   - `indexes`: não há teste.
2. `dry-run` (credencial **somente leitura**, sem environment): `firebase deploy --dry-run`.
3. `deploy` (só com `dry_run=false` em `main`, `environment: production`): baixa o `dist`
   do web, autentica com a credencial de **escrita** (que só existe no environment) e publica
   na ordem abaixo. `npm ci` roda antes da autenticação.

Concorrência: `group: deploy-<dry_run>`, sem cancelar execução em andamento. Dry-runs não
enfileiram atrás de deploys reais. O GitHub mantém só um item pendente por grupo: um segundo
deploy real disparado enquanto outro roda substitui o que estava pendente.

### Ordem do `all-ordered`

`indexes` -> `functions` -> (backfill manual) -> `hosting` -> `database` (rules RTDB) ->
`firestore:rules` -> `storage` (rules).

Segue o CLAUDE.md (functions -> backfill -> hosting -> rules do RTDB -> rules do Firestore).
Acrescentamos `indexes` na frente (aditivo; functions e consultas novas dependem deles; a
criação do índice leva minutos, espere ficar `READY` antes de usar a feature) e `storage`
no fim (as rules do Storage não dependem de nada). O backfill **não** roda no workflow:
exige credencial Admin e julgamento humano (ver seção 5). Por isso o `all-ordered` exige
`backfill_done=true`. Se o backfill for necessário, rode o alvo `functions`, faça o backfill,
e então `all-ordered` com `backfill_done=true` (ou `hosting`, `rules-rtdb` e `rules-firestore`
separados).

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

**Credenciais de escrita ficam só no environment `production`** (variáveis e secrets do
environment, não do repositório). Assim nenhum outro workflow, branch ou PR as enxerga.
O dry-run não usa o environment (não pede aprovação) e por isso usa uma service account
**somente leitura** distinta, configurada no repositório (seção 2.2). Os testes rodam sem
nenhuma credencial.

### 2.2 Autenticação (preferência: Workload Identity Federation)

Prioridade aplicada pela action `firebase-setup`:

Prioridade aplicada pela action `firebase-setup` (a mesma ordem vale para leitura e escrita,
sem o item 3 no dry-run):

1. **WIF** (sem chave de longa duração).
2. **Chave JSON da service account** (fallback se WIF não puder ser usado; validade
   indefinida, rotacione).
3. **`secrets.FIREBASE_TOKEN`** (obsoleto, `firebase login:ci`): último recurso do job
   `deploy`; emite warning.

Sem nenhuma o job falha com mensagem clara.

| Uso | Onde configurar | Variáveis / secrets |
| --- | --- | --- |
| Escrita (job `deploy`) | **Environment `production`** | `vars.GCP_WORKLOAD_IDENTITY_PROVIDER`, `vars.GCP_SERVICE_ACCOUNT`; fallbacks `secrets.GCP_SA_KEY`, `secrets.FIREBASE_TOKEN` |
| Leitura (job `dry-run`) | Repositório | `vars.GCP_RO_WORKLOAD_IDENTITY_PROVIDER`, `vars.GCP_RO_SERVICE_ACCOUNT`; fallback `secrets.GCP_RO_SA_KEY` |

Passo a passo WIF (gcloud, projeto `qio-app`): um pool/provider, duas service accounts. O
`sub` do token do GitHub distingue o job com environment
(`repo:felipeselau/qio:environment:production`) do job sem environment em `main`
(`repo:felipeselau/qio:ref:refs/heads/main`), e cada service account só aceita o seu.

```bash
PROJECT=qio-app
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')
POOL="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github"
gcloud iam service-accounts create github-deploy --project "$PROJECT" \
  --display-name "GitHub Actions deploy (escrita)"
gcloud iam service-accounts create github-dryrun --project "$PROJECT" \
  --display-name "GitHub Actions dry-run (leitura)"
gcloud iam workload-identity-pools create github --project "$PROJECT" \
  --location global --display-name "GitHub"
gcloud iam workload-identity-pools providers create-oidc github-oidc --project "$PROJECT" \
  --location global --workload-identity-pool github \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository=='felipeselau/qio' && assertion.ref=='refs/heads/main'"
gcloud iam service-accounts add-iam-policy-binding \
  "github-deploy@$PROJECT.iam.gserviceaccount.com" --project "$PROJECT" \
  --role roles/iam.workloadIdentityUser \
  --member "principal://iam.googleapis.com/$POOL/subject/repo:felipeselau/qio:environment:production"
gcloud iam service-accounts add-iam-policy-binding \
  "github-dryrun@$PROJECT.iam.gserviceaccount.com" --project "$PROJECT" \
  --role roles/iam.workloadIdentityUser \
  --member "principal://iam.googleapis.com/$POOL/subject/repo:felipeselau/qio:ref:refs/heads/main"
```

A service account de escrita só é assumível por `assertion.sub ==
'repo:felipeselau/qio:environment:production'` (e o environment só aceita `main`). Não use
`attribute.repository` como único critério do binding: qualquer workflow do repo
assumiria a conta de escrita.

Valores a gravar (provider = `projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github/providers/github-oidc`):

- Environment `production`: `GCP_WORKLOAD_IDENTITY_PROVIDER` = provider;
  `GCP_SERVICE_ACCOUNT` = `github-deploy@qio-app.iam.gserviceaccount.com`.
- Repositório: `GCP_RO_WORKLOAD_IDENTITY_PROVIDER` = provider;
  `GCP_RO_SERVICE_ACCOUNT` = `github-dryrun@qio-app.iam.gserviceaccount.com`.

Papéis da service account de **escrita** (mínimo sugerido; confira se algum deploy pedir mais):

| Alvo | Papéis |
| --- | --- |
| Todos | `roles/serviceusage.serviceUsageConsumer` |
| rules RTDB / Firestore / Storage / índices | `roles/firebaserules.admin`, `roles/datastore.indexAdmin`, `roles/firebasedatabase.admin` |
| hosting | `roles/firebasehosting.admin` |
| functions | `roles/cloudfunctions.admin`, `roles/cloudbuild.builds.editor`, `roles/artifactregistry.writer`, `roles/run.admin`, `roles/cloudscheduler.admin`, `roles/eventarc.admin`, `roles/pubsub.admin`, `roles/storage.objectAdmin` no bucket `gcf-sources-<PROJECT_NUMBER>-us-central1` e **obrigatoriamente** `roles/iam.serviceAccountUser` (nas service accounts de runtime/build usadas pelas functions) |

(`roles/firebase.admin` + `roles/iam.serviceAccountUser` simplifica, com mais privilégio.)

Service account de **leitura** (dry-run): `roles/serviceusage.serviceUsageConsumer`,
`roles/firebase.viewer`, `roles/firebaserules.viewer`, `roles/cloudfunctions.viewer`,
`roles/datastore.viewer`, `roles/firebasedatabase.viewer`, `roles/firebasehosting.viewer`.
O dry-run do CLI nem sempre se limita a leituras; se falhar por permissão, o dry-run
com a conta de escrita pode ser feito rodando o alvo com `dry_run=false` somente depois de
revisar os logs, ou ampliando o papel de leitura caso a caso. Nunca dê papéis de escrita à
conta do repositório.

Habilite as APIs `iamcredentials.googleapis.com` e `cloudresourcemanager.googleapis.com`.

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
2. Escolha o `target` (a partir de `main`), deixe `dry_run` marcado. Leia o log do dry-run.
   Para `all-ordered`, marque `backfill_done`.
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
- [ ] `mirrorQueueToRtdb`, `mirrorOperatorToRtdb` (#164; triggers Firestore -> RTDB; antes de qualquer
      APK; `--only functions:mirrorQueueToRtdb,functions:mirrorOperatorToRtdb`; só escrevem no RTDB,
      rollback = `firebase functions:delete` das duas só vale enquanto o APK distribuído for anterior à
      1.5.0; com o APK 1.5.0 em uso, as duas são obrigatórias).
- [ ] `deleteQueue`, `deleteAccount` (antes de distribuir o APK; `ENFORCE_APP_CHECK_DELETE=false`).
- [ ] Demais já documentadas: `submitFeedback`, `updateServiceEstimate`, `evaluateQueueAlerts`,
      `applyQueueSchedules`, `syncPublicTicket` (roteador único de `entries/{id}`: sync do
      `public`, push de nova entry, "é a sua vez" e "você é o próximo"),
      `reconcileWaitingCounts`, `purgeOldHistory`, `addManualEntry`.
      Um deploy completo de `functions` cobre todas.
- [ ] Consolidação dos triggers de entries (#165): o deploy completo de `functions` apaga
      `onEntryCalled`, `onEntryJoined` e `onQueueAdvanced` (ver CLAUDE.md, "Estrutura das
      functions"). Sem TTY o CLI recusa apagar funções; por isso `deploy-target.sh` passa
      `--force` **só** no deploy real (não no dry-run) dos alvos `functions` e `all-ordered`,
      nunca em rules/hosting/índices. Atenção: `--force` remove do projeto **qualquer** função
      que não exista mais no código, não só estas três. A remoção das 3 antigas é um passo
      único, no primeiro deploy após o merge. Durante a transição (segundos) o push de "nova
      entry" (`onEntryJoined` não tem dedupe) e o de "é a sua vez" podem chegar duplicados;
      "você é o próximo" é protegido por `nextNotifiedAt`. Não use `--only functions:syncPublicTicket`
      isolado (as antigas continuariam e duplicariam push até serem apagadas).

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
      **APK 1.5.0 exige `mirrorQueueToRtdb` e `mirrorOperatorToRtdb` no ar antes de ser
      distribuído** (#164 etapa 2): ele só escreve no Firestore nos setters de fila/operador;
      sem os triggers o RTDB (e a web) ficam desatualizados. Confira com
      `firebase functions:list --project qio-app`. APK antigo segue funcionando.
- [ ] Atualizar `web/public/.well-known/assetlinks.json` com o SHA-256 da chave de release.

### Console / ações do dono

- [ ] App Check: ativar e medir antes de `ENFORCE_APP_CHECK=true` (`docs/APPCHECK.md`).
- [ ] Teste manual do push em segundo plano (`docs/FCM.md`).
- [ ] Alertas de erro, uptime check, orçamento e Analytics (`docs/monitoring.md`).
- [ ] Backups agendados do Firestore (`docs/backup.md`, seção 7).
- [ ] Configurar WIF e o environment `production` (seção 2) e apagar `FIREBASE_TOKEN`.
