# Qio — Especificação do MVP

> **Documento histórico.** Descreve o desenho do MVP. Várias funcionalidades listadas
> como "fase 2" na seção 9 já estão em `main` (app 1.4.0+5 em `app/pubspec.yaml`, mais as
> mudanças listadas em `CHANGELOG.md` em "Não lançado"). Para o estado atual, ver
> `docs/RESUMO_TECNICO.md`, `CLAUDE.md` e `docs/qualidade.md`.

## 1. Visão

Qio é um sistema de filas para atendimentos presenciais. Owners criam filas e geram QR Codes; clients escaneiam o QR, entram na fila pelo navegador (sem instalar app) e recebem notificação quando chega a sua vez.

### Personas

| Persona | Superfície | Auth |
|---------|-----------|------|
| **Owner** (dono da fila) | App Flutter (instala) | Email/Google — conta real |
| **Client** (usuário da fila) | Web React (sem instalar) | Auth anônima Firebase (grátis, ilimitado) |

## 2. Stack

- **App Owner**: Flutter + Firebase (Auth, Firestore, RTDB, qr_flutter; hoje também Messaging, Analytics e Crashlytics)
- **Web Client**: React + Vite + TypeScript + Firebase JS SDK + Firebase Hosting
- **Backend**: Firebase (projeto `qio-app`)
  - Firestore: dados duráveis (owners, queues, histórico)
  - RTDB: estado vivo das filas (posições, contador, entries)
  - Cloud Functions v2 (plano Blaze desde 01/10/2026): no MVP, `joinQueue`, `syncPublicTicket` e `updateServiceEstimate`; hoje também `submitFeedback`, `applyQueueSchedules` e `evaluateQueueAlerts`
  - Auth: email/Google (owner) + anônima (client)

## 3. Arquitetura

```
┌─────────────┐         ┌──────────────────────────────┐
│ Flutter App │ writes  │ FIRESTORE (durável, grátis)   │
│  (Owner)    ├────────►│ owners, queues, histórico     │
└──────┬──────┘         └──────────────────────────────┘
       │  ▲                          ▲ referência
       │  │ lê/comanda               │
       ▼  │                 ┌────────┴─────────────────┐
┌─────────────────┐  live   │ RTDB (estado vivo)        │
│  React Web      │◄───────►│ filas/{id}/entries, meta  │
│  (Client)       │  sync   │ contador, posições        │
└─────────────────┘         └──────────────────────────┘
       ▲
       │ QR Code = URL https://qio.web.app/q/{queueId}
```

**Divisão Firestore × RTDB**: Firestore guarda quem/quê (owner, config da fila, histórico). RTDB guarda o estado vivo (posições, quem está sendo chamado) — atualizações em ms, listener grátis. Firestore referencia RTDB via `queueId` igual nos dois.

## 4. Notificações — Híbrida

```
Client entra na fila
  ├─ browser pede permissão de notificação
  │    ├─ concedida (Android Chrome, desktop) → getToken(vapidKey) → salva fcmToken na entry
  │    └─ negada/indisponível (iOS Safari) → segue só in-page
  └─ página fica aberta: listener RTDB = aviso garantido (som + tela "SUA VEZ")

Owner chama próximo → entry.status = "called"
  ├─ todos os listeners disparam → página do client chamado reage na hora
  └─ Cloud Function (trigger RTDB) → lê fcmToken da entry → FCM push
       → client com aba em background/no Android recebe push de verdade
```

**Limite duro de plataforma**: iOS Safari não entrega web push em aba comum — só se o site for instalado na tela de início (iOS 16.4+). Sem app instalado, não existe workaround gratuito. No iOS o MVP depende da aba aberta (banner na página: "mantenha esta aba aberta"). FCM cobre Android/desktop.

**Requisitos**: VAPID key (console Firebase → Cloud Messaging → Web Push certificates) + service worker `firebase-messaging-sw.js` no Hosting + Cloud Function `syncPublicTicket` (roteador de `entries`; passo "called" envia o push; plano Blaze, dentro da cota gratuita de 2M invocações/mês; FCM grátis).

## 5. Modelo de dados

### Firestore
```
owners/{uid}        { name, businessName, createdAt }
queues/{queueId}    { ownerId, name, description, status: open|paused|closed,
                      avgServiceMin, createdAt, shortcode }
queues/{queueId}/history/{entryId}   { ticket, name, phone, result, joinedAt, calledAt, finishedAt }
```

### RTDB (fonte de verdade do ao-vivo)
```
queues/{queueId}/
  meta/      { nextTicket: 12, serving: 10, status, name, updatedAt }
  entries/{entryId}  { ticket, name, phone, uid, fcmToken?,
                       status: waiting|called|served|no_show|left,
                       joinedAt, calledAt }
owners/{queueId}/ownerUid    ← espelho p/ rules da RTDB
```

- **Senha numérica** via transação em `meta.nextTicket` (RTDB transaction, sem race).
- **Posição** = nº de `waiting` com ticket menor. Cliente calcula local do snapshot (1 leitura, zero custo extra).

## 6. Fluxos

**F1 — Cadastro owner**: Flutter → Auth email/Google → doc `owners/{uid}` → tela inicial lista filas do owner (query Firestore `ownerId == uid`).

**F2 — Criar fila**: Owner dá nome → escreve Firestore `queues/{id}` + inicializa RTDB (`meta`, `owners/{id}`) → tela exibe QR Code apontando `https://qio.web.app/q/{queueId}` + botão compartilhar. Fila nasce `open`.

**F3 — Client entra na fila**: Scan QR → React abre `/q/{queueId}` → Auth anônima automática → lê meta da fila (está aberta?) → pede nome + telefone → callable `joinQueue` (transação em `tickets/{queueId}`, Admin SDK) cria `entries/{entryId}` → tela do ticket: "Senha 11 · 3 na sua frente · mantenha a página aberta".

**F4 — Espera ao vivo**: Página client mantém listener RTDB na fila → recalcula posição a cada mudança → anima posição. Owner vê lista ao vivo no Flutter (mesmo listener).

**F5 — Chamar próximo**: Owner toca "Chamar próximo" → transaction: menor `waiting` vira `called`, `meta.serving` atualiza → todos os listeners disparam → a página do client chamado detecta `entry.uid == meu && status == called` → som + notificação local + tela cheia "SUA VEZ".

**F6 — Finalizar atendimento**: Owner marca `served` ou `no_show` → entry sai do ao-vivo → arquivada em `history` (escreve o próprio app do owner — sem Cloud Function no MVP).

**F7 — Client sai da fila**: Botão "sair da fila" → `status: left` → some da lista do owner.

**F8 — Client recupera ticket**: Fechou a aba → reabre link/QR → Auth anônima persiste no browser → busca entry com seu `uid` ainda `waiting|called` → restaura tela na posição atual. Se já foi chamado (`no_show`), mostra aviso.

**F9 — Pausar/fechar fila**: Owner pausa (ninguém entra, mantém posições) ou fecha (avisa restantes — página de todos mostra "fila encerrada").

**F10 — Múltiplas filas por owner**: Owner alterna entre filas no app (lista F1). Cada uma com QR próprio. MVP: permitir, mas UI foca em 1 ativa.

## 7. Segurança (rules)

As rules citadas na versão inicial deste documento (escrita direta do cliente em
`entries`, `owners/{queueId}` aberto) foram substituídas. O estado atual está em
`firestore.rules`, `database.rules.json` e `storage.rules`, cobertas por
`rules-tests/` (ver `docs/qualidade.md`). Em resumo:

- O cliente web não escreve em `entries` nem em `tickets`: entra pela callable
  `joinQueue` (Admin SDK) e só altera a própria entry para `status: 'left'` ou `fcmToken`.
- `entries` só é legível por dono, operadores e pelo autor; o espelho público sem PII
  (`public/{entryId}`) é gravado pela function `syncPublicTicket`.
- `meta` é escrito só pelo dono (e, em parte, pelo operador); campos como
  `avgServiceMinAuto` só pela function `updateServiceEstimate`.
- Detalhes por funcionalidade: `CLAUDE.md`.

## 8. Orçamento (plano Blaze, cota gratuita)

Projeto no plano Blaze desde 01/10/2026 (Cloud Functions v2). Custo esperado dentro da cota gratuita no volume do TCC.

| Serviço | Limite grátis | Uso Qio | Risco |
|---------|--------------|---------|-------|
| Auth email/Google/anônimo | ilimitado | ok | — |
| Firestore | 50k reads, 20k writes/dia | baixo (1 read por entrada de client) | — |
| RTDB | 100 conexões simultâneas, 10GB/mês tráfego | 1 conexão por client com página aberta + owner | ⚠️ gargalo do MVP |
| Hosting | 10GB/mês | web React | — |
| FCM/Functions | 2M invocações/mês (Functions); FCM grátis | `joinQueue`, `syncPublicTicket`, `updateServiceEstimate` e as demais listadas na seção 2 | dentro da cota no volume do TCC |

100 conexões simultâneas ≈ ~100 clientes com página aberta ao mesmo tempo no projeto todo. Suficiente p/ validar; monitorar.

## 9. Escopo

**IN MVP**: F1–F10, 1 owner por fila, fila por ordem de chegada, notificação híbrida (in-page + FCM), histórico básico, telefone sem verificação.

**OUT (fase 2) no desenho original, e situação em `main`:**

| Item | Situação |
|------|----------|
| Agendamento com hora marcada | Entregue em versão mínima: slots diários por fila (#136) |
| Múltiplos atendentes | Entregue: operadores por código de convite (1.2.0) e métricas por atendente (#124) |
| Estatísticas / dashboard | Entregue: tela de Métricas, heatmap, tendência e exportação CSV/PDF |
| Tema/branding da fila | Entregue: cor e logo da fila (1.4.0) |
| SMS | Não implementado |
| Verificação de telefone | Não implementado |

## 10. Estrutura do repositório

```
qio/
├── app/          # Flutter (owner)
├── web/          # React + Vite + TS (client)
├── functions/    # Cloud Functions v2 (lista em functions/index.js)
├── rules-tests/  # testes das rules e da callable joinQueue nos emulators
├── docs/SPEC.md  # este desenho
├── design/       # arquivos .pen
├── firebase.json
├── .firebaserc
├── firestore.rules
├── database.rules.json
├── storage.rules
```

## 11. Fases de build

1. **Fundação** — monorepo, Firebase wiring no `qio-app` (Auth email/Google + anônimo, Firestore, RTDB, rules, Hosting)
2. **Traçante ponta-a-ponta** — owner cria fila → QR → client escaneia → entra com nome+telefone → aparece na lista ao vivo do owner
3. **Operação** — chamar próximo, served/no_show, sair da fila, recuperar ticket, pausar/fechar
4. **Notificações** — in-page + FCM + Cloud Function
5. **Polimento** — histórico, estados vazios, erros, deploy