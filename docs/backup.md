# Backups, orçamento e restauração (issue #163)

Separação: **código no repo** (scripts em `ops/`, esta doc) e **ações manuais do dono**
(seção 7). Nada aqui foi executado contra o projeto `qio-app`; os scripts têm `--dry-run`
que só imprime os comandos.

## 1. Estratégia: o que é backup de quê

| Dado | Papel | Prioridade | Mecanismo |
| --- | --- | --- | --- |
| Firestore (`queues`, `history`, `feedback`, `operators`, `owners`...) | **Fonte da verdade**: histórico alimenta métricas e estimativa | Alta | Backup agendado gerenciado (diário + semanal) e, opcionalmente, PITR; export manual antes de mudanças arriscadas |
| RTDB (`entries`, `public`, `meta`, `tickets`, `operatorUids`) | Espelho/estado transitório da fila; `meta` é reconstruído pelo app (`_ensureOwnerMirror`) e `public` pelo trigger/backfill | Média/baixa | Backup automático do console (Blaze) ou `ops/backup-rtdb.sh` antes de mexer em rules/dados |
| Rules, functions, web, app | Já versionados no git | n/a | Git |
| Storage (`queue-logos/`) | Logos; reenviáveis pelo dono | Baixa | Fora do escopo |

Consequência: a perda do RTDB é recuperável (entries ativas se perdem, o resto é
reconstruído). A perda do Firestore não é, daí o foco nele.

## 2. Mecanismos e comandos

Comandos confirmados na documentação (ver seção 8).

### Firestore: backup agendado (`ops/backup-firestore.sh schedule`)

```bash
gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=7d
gcloud firestore backups schedules create --database='(default)' --recurrence=weekly --day-of-week=SUN --retention=8w
```

- Cada banco aceita **uma** agenda diária e **uma** semanal; não dá para escolher o horário.
- Retenção máxima: 14 semanas (`14w`). Recorrência não pode ser alterada depois
  (`schedules update` muda só a retenção).
- Lista: `gcloud firestore backups list --format="table(name, database, state)"`
  (`--location=` para filtrar).
- PITR (opcional, `ENABLE_PITR=true`): janela de 7 dias, permite export/restore de um
  instante. Tem custo por armazenamento de versões; o flag `--enable-pitr` no
  `databases update` não foi conferido nesta sessão (ver seção 9).

### Firestore: export manual (`ops/backup-firestore.sh export`)

```bash
gcloud firestore export gs://BUCKET/firestore/<timestamp> --database='(default)' --async
gcloud firestore import gs://BUCKET/firestore/<timestamp>/ --database=DESTINO   # restauração
```

Use antes de deploys de rules/migrações. O bucket deve ficar perto da região do banco, não
pode ser Requester Pays, e o projeto precisa de faturamento.

### RTDB (`ops/backup-rtdb.sh`)

- **Recomendado**: backup automático do console (Realtime Database, aba Backups): diário,
  JSON (dados e rules) em bucket do Cloud Storage, gzip, política opcional de 30 dias.
  Exige Blaze, sem custo extra além do armazenamento.
- **Complemento manual**: `firebase database:get / --project qio-app --output arquivo.json`
  (flags conferidas em `firebase database:get --help`). O script comprime e, com `BUCKET`,
  copia para `gs://BUCKET/rtdb/`. Para bancos grandes, `database:get /` pode ficar lento
  ou estourar; o limite não está documentado, então prefira o backup do console. O banco
  do Qio é pequeno (só filas ativas).
- O arquivo tem **PII** (nome e telefone das entries). Pasta `backups/` está no
  `.gitignore`.

### Orçamento (`ops/create-budget.sh`)

```bash
gcloud billing budgets create --billing-account=ID --display-name="qio mensal" \
  --budget-amount=20BRL --calendar-period=month --filter-projects=projects/qio-app \
  --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
```

A moeda deve ser a da conta de faturamento. Orçamento **só alerta** (e-mail para
administradores da conta de faturamento); não corta o gasto. Limite real exigiria
Pub/Sub + function que desvincula o faturamento, fora do escopo.

## 3. Retenção

| Camada | Retenção |
| --- | --- |
| Backup diário Firestore | 7 dias |
| Backup semanal Firestore | 8 semanas |
| PITR (se ligado) | 7 dias |
| Export manual / JSON do RTDB no bucket | lifecycle do bucket: apagar após 30 dias (ação manual 3) |

## 4. Custo estimado

Estimativa de ordem de grandeza, **não verificada** com a tabela de preços atual: o banco
do Qio é pequeno (milhares de docs de history, poucos MB). Backups são cobrados por GB-mês
armazenado, então ficam em centavos por mês; restaurações e exports cobram leituras e
armazenamento pontuais, também desprezíveis neste tamanho. O alerta de R$ 20/mês cobre
isso com folga. Confirme na calculadora do Google Cloud antes de ligar o PITR.

## 5. RPO / RTO

| Cenário | RPO | RTO |
| --- | --- | --- |
| Exclusão acidental, com backup diário | até 24 h | minutos a poucas horas (restore em banco novo, validar, repontar ou copiar docs) |
| Com PITR | ~1 min | igual |
| RTDB perdido | n/a (reconstruível) | minutos: reabrir filas no app, `backfill-public.js` |

Restaurar **cria um banco novo**: não sobrescreve o `(default)`. Para voltar à produção
é preciso exportar do banco restaurado e importar no `(default)` (ou apontar o app/web
para o banco novo, o que exige mudar o código). Isso é decisão do dono no incidente.

## 6. Restauração em projeto de teste (passo a passo)

Objetivo: provar que o backup serve. Faça uma vez e anote a data (seção 7, item 8).

Restore de backup gerenciado, no próprio projeto, em banco novo:

```bash
export PROJECT=qio-app LOCATION=<região do banco>
./ops/restore-firestore-test.sh list                       # escolha o BACKUP_ID
BACKUP_ID=<id> ./ops/restore-firestore-test.sh restore      # cria o banco restore-test
./ops/restore-firestore-test.sh status                     # espere terminar
```

Alternativa em **outro projeto** (isola de produção): use um export manual e importe no
projeto de teste.

```bash
gcloud firestore export gs://BUCKET/firestore/<ts> --project=qio-app --database='(default)'
gcloud firestore import gs://BUCKET/firestore/<ts>/ --project=qio-teste --database='(default)'
```

O service agent `service-<PROJECT_NUMBER>@gcp-sa-firestore.iam.gserviceaccount.com` do
projeto de teste precisa de leitura no bucket (ação manual 4).

RTDB (opcional, só em projeto de teste, nunca em produção sem decisão consciente):

```bash
gunzip rtdb-....json.gz
firebase database:set / rtdb-....json --project qio-teste --force --disable-triggers
```

`--disable-triggers` evita disparar `syncPublicTicket`, push etc. durante a carga. Depois
rode `functions/scripts/backfill-public.js` apontando para o projeto de teste para
recriar `public/`.

### Checklist de validação

- [ ] A operação terminou sem erro (`status`) e o banco aparece no console.
- [ ] Contagem de docs: `queues` e `queues/{id}/history` do banco restaurado batem com a
      produção na data do backup (console, ou `gcloud firestore export` + conferência).
- [ ] Abrir 2 ou 3 docs de `queues/{id}` e conferir campos (`ownerId`, `schedule`,
      `operatorInviteCode`, `brandColor`).
- [ ] `history` tem `result` (`served`/`no_show`/`left`), `calledAt`, `finishedAt`.
- [ ] `feedback` e `operators` presentes.
- [ ] O índice composto `history: result ASC, finishedAt DESC` existe no banco novo
      (`firestore.indexes.json`; índices não vêm no restore, reimplante com
      `firebase deploy --only firestore:indexes`). Esta afirmação sobre índices não foi
      confirmada na doc.
- [ ] Apagar o banco de teste: `./ops/restore-firestore-test.sh delete`.

## 7. AÇÕES MANUAIS DO DONO

Nada abaixo é feito pelo repo.

1. **Habilitar APIs** no projeto: `firestore.googleapis.com`, `storage.googleapis.com`,
   `billingbudgets.googleapis.com` (para o orçamento, também `cloudbilling`
   se o gcloud pedir).
   `gcloud services enable billingbudgets.googleapis.com --project=qio-app`
2. **Criar o bucket** de backups na região do Firestore, uniform access, não público:
   `gcloud storage buckets create gs://BUCKET --project=qio-app --location=REGIAO --uniform-bucket-level-access`.
3. **Lifecycle** do bucket (apagar objetos com mais de 30 dias): arquivo
   `{"rule":[{"action":{"type":"Delete"},"condition":{"age":30}}]}` e
   `gcloud storage buckets update gs://BUCKET --lifecycle-file=lifecycle.json`.
4. **Papéis**: quem roda os scripts precisa de `Cloud Datastore Import Export Admin` (ou
   Owner) e `Storage Admin` no bucket, e `Billing Account Costs Manager` na conta de
   faturamento. Para importar em outro projeto, dar ao service agent do Firestore desse
   projeto acesso ao bucket (`Storage Admin` ou `Firestore Service Agent`).
5. **Rodar**: `ops/backup-firestore.sh schedule`, `ops/create-budget.sh` (com
   `BILLING_ACCOUNT`), confirmar com `ops/backup-firestore.sh list`. Rode antes com
   `--dry-run`.
6. **RTDB**: ligar o backup automático no console (Realtime Database > Backups) e o
   lifecycle de 30 dias oferecido lá; ou rodar `ops/backup-rtdb.sh` quando necessário.
7. **Confirmar o orçamento** no console de Billing (Budgets & alerts) e que os e-mails
   chegam aos administradores certos.
8. **Testar a restauração** (seção 6) em banco/projeto de teste e anotar aqui:
   `Restauração validada em: ____-__-__ por ______` (critério de aceite da #163).
9. Repetir o teste de restauração a cada alteração grande de modelo de dados.

Um workflow do GitHub Actions para isso foi deliberadamente não criado: exigiria uma
chave de conta de serviço longeva nas secrets, risco maior que o ganho para um backup que
já roda gerenciado pelo Google.

## 8. Fontes

- Backups do Firestore (agenda, retenção, restore): https://docs.cloud.google.com/firestore/native/docs/backups
- Export/import: https://docs.cloud.google.com/firestore/native/docs/manage-data/export-import
- `gcloud billing budgets create`: https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create
- Orçamentos e permissões: https://docs.cloud.google.com/billing/docs/how-to/budgets
- Backups do RTDB: https://firebase.google.com/docs/database/backups
- Flags de `database:get`/`database:set`: `firebase database:get --help` e `database:set --help`.

## 9. Não verificado

- Nenhum comando foi executado (sem credenciais, sem `gcloud`/`shellcheck` na máquina).
- `gcloud firestore databases update --enable-pitr` e o custo de PITR.
- Se índices compostos são recriados no restore.
- Preços atuais de armazenamento de backup.
- Limite de tamanho do `database:get /` do RTDB.
