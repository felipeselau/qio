# Diagramas de arquitetura

Diagramas em Mermaid (renderizados pelo GitHub), escritos a partir de `functions/index.js`, `app/lib/services/queue_service.dart`, `database.rules.json`, `firestore.rules` e `docs/RESUMO_TECNICO.md`. Simplificados de propósito: omitem grupos, alertas, horário de funcionamento e analytics. Ver também [`modelo-de-ameacas.md`](./modelo-de-ameacas.md) e [`limitacoes-e-trabalhos-futuros.md`](./limitacoes-e-trabalhos-futuros.md).

## 1. Componentes

```mermaid
flowchart LR
  subgraph Clientes
    APP["App Flutter<br/>dono e operador"]
    WEB["Web React<br/>cliente, sem instalação"]
  end

  subgraph Firebase
    HOST["Hosting<br/>qio.web.app"]
    AUTH["Auth<br/>email/Google e anônima"]
    FS[("Firestore<br/>dados duráveis")]
    RT[("Realtime Database<br/>estado vivo")]
    ST[("Storage<br/>logos")]
    FN["Cloud Functions v2<br/>callables, triggers, agendadas"]
    FCM["Cloud Messaging<br/>FCM"]
  end

  WEB -->|"carrega o site"| HOST
  WEB -->|"login anônimo"| AUTH
  APP -->|"login email ou Google"| AUTH
  WEB -->|"callables joinQueue e submitFeedback"| FN
  WEB -->|"lê meta, public e a própria entry"| RT
  APP -->|"escreve filas e history"| FS
  APP -->|"meta, entries, serving"| RT
  APP -->|"upload do logo"| ST
  FN -->|"Admin SDK: entries, tickets, rateLimits, public"| RT
  FN -->|"lê queues e grava history/feedback"| FS
  FN -->|"envia push"| FCM
  FCM -->|"push web"| WEB
  FCM -->|"push para dono e operadores"| APP
  RT -.->|"triggers de entries"| FN
  FS -.->|"trigger de history"| FN
```

Pontos de leitura:

- O cliente web **não escreve** em `entries` nem em `tickets`; só chama a callable `joinQueue`. Depois da entrada, ele altera na própria entry apenas `status: 'left'` e `fcmToken` (rules do RTDB).
- O app faz dual-write: Firestore é a fonte da verdade e o RTDB recebe um espelho (`meta`, `owners/{queueId}`, `operatorUids`).
- O App Check existe só nas callables (hoje sem enforcement); RTDB, Firestore e Storage não o usam porque o app Flutter não passa pelo Play Integrity fora da Play Store.

## 2. Sequência de `joinQueue`

Ordem das checagens conforme `functions/index.js` (callable `joinQueue`, região `us-central1`).

```mermaid
sequenceDiagram
  autonumber
  actor C as Cliente (web)
  participant A as Auth anônima
  participant J as joinQueue
  participant R as RTDB
  participant S as syncPublicTicket
  participant P as onEntryJoined

  C->>A: login anônimo (uid)
  C->>J: queueId, name, phone, lang, slotId?
  J->>J: exige auth e valida queueId, nome e telefone
  J->>R: lê queues/{id}/meta
  alt fila inexistente
    J-->>C: not-found
  else status diferente de open
    J-->>C: failed-precondition
  end
  J->>R: entries com uid igual ao do chamador
  alt já existe entry ativa do uid
    J-->>C: entryId e ticket existentes (existing true)
  end
  J->>R: entries com o mesmo phone
  alt telefone já ativo na fila
    J-->>C: already-exists
  end
  opt fila por hora marcada
    J->>J: valida slot (lotado ou já passou: erro)
  end
  opt maxWaiting definido
    J->>R: conta entries waiting (sem transação)
    J-->>C: resource-exhausted (queue-full) se cheia
  end
  J->>R: transação em rateLimits/{id}/{uid}
  alt 3 joins em 10 min
    J-->>C: resource-exhausted
  end
  J->>R: transação em tickets/{id}, próximo número
  J->>R: push() e set da entry (status waiting)
  J-->>C: entryId, ticket, existing false
  R-->>S: trigger de escrita em entries
  S->>R: grava public/{entryId} com ticket, status e order
  R-->>P: trigger de criação em entries
  P-->>P: push ao dono e aos operadores (FCM)
  C->>R: ouve a própria entry e public/ para calcular a posição
```

Observações: a checagem de limite e a de slot **não** são transacionais com a criação da entry; joins simultâneos podem ultrapassar a capacidade em uma ou duas vagas.

## 3. Sequência de `callNext`

Do app Flutter (`QueueService.callNext`, `_claimEntry`, `_advanceServing`) até o cliente.

```mermaid
sequenceDiagram
  autonumber
  actor O as Dono ou operador (app)
  participant Q as QueueService
  participant R as RTDB
  participant T1 as syncPublicTicket
  participant T2 as onEntryCalled
  participant T3 as onQueueAdvanced
  actor C as Cliente (web)

  O->>Q: Chamar próximo
  Q->>R: ensureOwnerMirrorIfOwner (dono, cacheado por sessão)
  Q->>R: entries com status waiting
  Q->>Q: ordena por (order ou joinedAt, ticket)
  loop candidatos em ordem
    Q->>R: _claimEntry: transação na entry
    Note over Q,R: só vira called se ainda estiver waiting, grava calledAt e operatorId
    alt outro operador reservou antes
      R-->>Q: transação abortada
      Note over Q: tenta o próximo candidato
    else reserva confirmada
      R-->>Q: entry called
      Q->>R: _advanceServing: transação em meta/serving (nunca volta)
      Q->>R: update meta/updatedAt
      Note over Q: encerra o loop
    end
  end
  R-->>T1: entry mudou
  T1->>R: atualiza public/{entryId}
  R-->>T2: entry mudou
  T2-->>C: push FCM de chamada se houver fcmToken (shouldRenotify)
  R-->>T3: entry saiu de waiting
  T3-->>C: push de próximo da fila ao novo primeiro, uma vez (nextNotifiedAt)
  R-->>C: listener da própria entry: status called
  C->>C: tela, som e vibração
```

Observação: a reserva é por transação na entry; o `serving` é uma transação separada que só avança. Se o app cair entre as duas, a entry fica `called` com `serving` atrasado até a próxima chamada.

## 4. Fluxo de finalização (atendido ou não compareceu)

`QueueService._finishEntry`: arquivar, reservar por transação e só então remover.

```mermaid
sequenceDiagram
  autonumber
  actor O as Dono ou operador (app)
  participant Q as QueueService
  participant R as RTDB
  participant F as Firestore
  participant T1 as syncPublicTicket
  participant T4 as updateServiceEstimate

  O->>Q: Marcar atendido ou não compareceu
  Q->>R: lê a entry
  alt entry já sumiu
    Q-->>O: nada a fazer
  else entry mudou desde a tela
    Q-->>O: EntryChangedException
  end
  Q->>F: set queues/{id}/history/{entryId} (archive)
  Note over Q,F: permission-denied em nova tentativa é tratado como sucesso (doc já existe)
  Q->>R: transação na entry: finishedEntryData (claim)
  Q->>R: remove entries/{entryId}
  R-->>T1: entry removida
  T1->>R: remove public/{entryId}
  F-->>T4: history criado
  T4->>R: grava meta/avgServiceMinAuto (só served, mínimo 3 amostras)
```

Cliente que sai (`left`) segue outro caminho: o cliente grava `status: 'left'`, e `syncPublicTicket` cria `history/{entryId}` com `result: 'left'` via Admin, remove `entries/{entryId}` e `public/{entryId}`.

Ordem e falhas: se o arquivamento falhar com erro que não seja `permission-denied`, a entry permanece no RTDB e o dono pode tentar de novo. Se cair depois do arquivamento e antes do `remove`, a nova tentativa grava o mesmo `history` (mesmo `entryId`) e conclui.

## 5. Modelo de dados (ER simplificado)

Não são tabelas relacionais: o Firestore tem coleções e subcoleções; o RTDB é uma árvore JSON. As relações abaixo são por identificador. Campos listados são os principais, não todos.

```mermaid
erDiagram
  OWNER ||--o{ QUEUE : "ownerId"
  QUEUE ||--o{ HISTORY : "subcoleção"
  QUEUE ||--o{ FEEDBACK : "subcoleção"
  QUEUE ||--o{ OPERATOR : "subcoleção"
  QUEUE ||--o{ OPERATOR_REQUEST : "subcoleção"
  QUEUE ||--o| OPERATOR_INVITE : "operatorInviteCode"
  QUEUE ||--|| RTDB_META : "espelho, mesmo queueId"
  QUEUE ||--|| RTDB_OWNER_MIRROR : "owners/queueId/ownerUid"
  QUEUE ||--o{ RTDB_ENTRY : "queues/queueId/entries"
  RTDB_ENTRY ||--o| RTDB_PUBLIC : "mesmo entryId, sem PII"
  RTDB_ENTRY ||--o| HISTORY : "mesmo entryId ao finalizar"
  HISTORY ||--o| FEEDBACK : "mesmo entryId"
  QUEUE ||--|| RTDB_TICKETS : "tickets/queueId"
  QUEUE ||--o{ RTDB_RATE_LIMIT : "rateLimits/queueId/uid"
  QUEUE ||--o{ RTDB_OPERATOR_UID : "operatorUids/uid"

  OWNER {
    string uid
    string businessName
  }
  QUEUE {
    string queueId
    string ownerId
    string name
    string status
    number avgServiceMin
    string mode
  }
  HISTORY {
    string entryId
    number ticket
    string name
    string phone
    string result
    timestamp joinedAt
    timestamp calledAt
    timestamp finishedAt
    string operatorId
  }
  FEEDBACK {
    string entryId
    number rating
    string comment
    string uid
  }
  OPERATOR {
    string uid
  }
  OPERATOR_REQUEST {
    string uid
    string status
  }
  OPERATOR_INVITE {
    string code
    timestamp expiresAt
  }
  RTDB_META {
    string status
    number serving
    number maxWaiting
    number avgServiceMinAuto
  }
  RTDB_OWNER_MIRROR {
    string ownerUid
  }
  RTDB_ENTRY {
    string entryId
    number ticket
    string name
    string phone
    string uid
    string status
    number joinedAt
    string fcmToken
  }
  RTDB_PUBLIC {
    string entryId
    number ticket
    string status
    number order
  }
  RTDB_TICKETS {
    number counter
  }
  RTDB_RATE_LIMIT {
    string uid
    number timestamps
  }
  RTDB_OPERATOR_UID {
    string uid
    boolean active
  }
```

Nomes com prefixo `RTDB_` estão na Realtime Database; os demais estão no Firestore. `operatorInvites/{code}` (Firestore, na raiz) é a fonte da verdade do convite; o campo na fila é só ponteiro.

## 6. Por que dois bancos

Resumo de `docs/RESUMO_TECNICO.md` §4, com ressalvas.

| Aspecto | Firestore | RTDB |
| --- | --- | --- |
| Papel | Configuração, histórico, feedback, operadores, dados do dono (fonte da verdade) | Estado vivo: entries, `public`, `meta`, contador de senha |
| Padrão de acesso | Consultas e leituras pontuais; agregações de métricas sobre o `history` | Listeners contínuos com sincronização automática |
| Transações | Disponíveis, mas o fluxo de chamada usa as do RTDB por nó | Transações por nó (`_claimEntry`, `serving`, `tickets`, `rateLimits`) |
| Regras | Por papel (dono, operador, anônimo) em `firestore.rules` | Por nó, com `.validate` de formato em `database.rules.json` |

Custo da escolha, que o TCC deve declarar: o **dual-write** (app grava no Firestore e espelha no RTDB). Uma falha entre as duas escritas deixa os dois divergentes até o próximo `ensureMirror`. A alternativa de replicar Firestore para RTDB por trigger está em #164 e não foi feita. Os números de latência e de cota citados em `RESUMO_TECNICO.md` §4 e §9 são ordens de grandeza do documento, **não medidos neste projeto**.
