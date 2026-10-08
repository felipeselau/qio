# Qio — Resumo Técnico

## 1. O que é o Qio

Qio é um **sistema de filas para atendimentos presenciais**. O proprietário (owner) cria filas no aplicativo móvel e gera um QR Code. O cliente (client) escaneia o QR Code e entra na fila pelo navegador do celular — **sem precisar instalar nenhum aplicativo**. Quando chega a sua vez, o cliente recebe uma notificação (push notification ou alerta na página).

> Estado deste documento: reflete `main` (app 1.4.0+5 em `app/pubspec.yaml` mais as mudanças em "Não lançado" do `CHANGELOG.md`). Resultados de testes e cobertura estão em [`docs/qualidade.md`](./qualidade.md).

**Objetivo**: eliminar filas físicas e listas de papel em estabelecimentos como clínicas, salões, consultórios, etc., oferecendo uma experiência digital simples tanto para o proprietor quanto para o cliente.

## 2. Arquitetura Geral

O sistema é composto por **3 módulos** que se comunicam via **Firebase** (BaaS — Backend as a Service):

```
┌──────────────────────┐        ┌─────────────────────────────────────┐
│   APP FLUTTER        │        │          FIREBASE (Backend)         │
│   (Proprietário)     │        │                                     │
│                      │  write │  Firestore (dados duráveis)         │
│  - Cria filas        ├───────►│    owners/{uid}                     │
│  - Gera QR Code      │        │    queues/{queueId}                 │
│  - Chama próximo     │        │    queues/{queueId}/history/{id}    │
│  - Gerencia fila     │        │                                     │
└──────────┬───────────┘        │  RTDB (estado em tempo real)        │
           │                    │    queues/{queueId}/meta             │
           │  lê/write         │    queues/{queueId}/entries/{id}     │
           ▼                    │    queues/{queueId}/tickets          │
┌──────────────────────┐        │                                     │
│   WEB REACT          │  read  │  Cloud Functions (Node.js)          │
│   (Cliente)          │◄──────►│    Trigger RTDB → FCM push          │
│                      │  live  │                                     │
│  - Entra na fila     │ sync   │  Auth (autenticação)                │
│  - Vê posição        │        │    email/Google (proprietário)      │
│  - Recebe notificação│        │    anônima (cliente)                │
└──────────────────────┘        └─────────────────────────────────────┘
```

### Módulo 1: App Flutter (Proprietário)

- **Função**: interface administrativa para criar filas, gerenciar atendimentos e visualizar status em tempo real.
- **Tecnologia**: Flutter (Dart; CI com Flutter 3.44.3)
- **O que faz**:
  - Cadastro/login (email ou Google)
  - Criação de filas (nome, tempo médio, cor e logo) com QR Code e cartaz para impressão
  - Controle de fila: chamar próximo, chamar de novo, chamar agora, mover para o fim, marcar como atendido/faltou
  - Visualização da lista de espera em tempo real, limite de espera, pausa/fechamento com mensagem
  - Horário de funcionamento automático e filas por hora marcada (slots diários)
  - Operadores por código de convite; grupos de filas
  - Histórico com filtros e avaliações; exportação em CSV e PDF
  - Métricas: espera (média, mediana, P90, faixas), atendimento, não comparecimento, re-chamadas, por atendente, demanda por dia da semana, heatmap dia×hora, tendência e comparação com o período anterior
  - Alertas operacionais (espera alta, não comparecimento alto, fila parada) e push quando alguém entra
  - i18n (pt/en/es), modo escuro, tour de onboarding, analytics com opt-out

### Módulo 2: Web React (Cliente)

- **Função**: página web que o cliente acessa escaneando o QR Code. Não requer instalação.
- **Tecnologia**: React 19 + TypeScript + Vite
- **O que faz**:
  - Autenticação anônima (sem cadastro)
  - Formulário: nome + telefone (obrigatório o primeiro, opcional o segundo); em filas por hora marcada, escolha do horário
  - Exibe senha numérica, posição na fila e tempo estimado de espera
  - Recebe alerta visual + sonoro quando chamado, e push em segundo plano (opt-in, pt/en/es)
  - Botão para sair da fila voluntariamente e avaliação de 1 a 5 estrelas após o atendimento
  - Modo escuro, i18n (pt/en/es), identidade da fila (cor e logo) e PWA instalável

### Módulo 3: Firebase (Backend)

- **Função**: infraestrutura de backend completo (autenticação, banco de dados, funções serverless, hospedagem).
- **Serviços utilizados**:
  - **Authentication**: login do proprietário (email/Google) e do cliente (anônimo)
  - **Firestore**: banco de dados relacional para dados duráveis (proprietários, filas, histórico)
  - **Realtime Database (RTDB)**: banco de dados em tempo real para estado vivo das filas (posições, chamadas)
  - **Cloud Functions** (v2, Node 22): callables `joinQueue` e `submitFeedback`; gatilhos `syncPublicTicket`, `onEntryCalled`, `onEntryJoined`, `onQueueAdvanced` e `updateServiceEstimate`; agendadas `applyQueueSchedules` e `evaluateQueueAlerts`
  - **Storage**: logos das filas
  - **Hosting**: hospedagem do site do cliente (React)
  - **Cloud Messaging (FCM)**: envio de notificações push

## 3. Bibliotecas e Dependências

### App Flutter (`app/pubspec.yaml`)

| Biblioteca          | Versão  | Função                                   |
| ------------------- | ------- | ---------------------------------------- |
| `firebase_core`       | 4.13.0  | Inicialização do Firebase no Flutter     |
| `firebase_auth`       | 6.5.7   | Autenticação (email/Google/anônima)      |
| `cloud_firestore`     | 6.8.0   | Banco de dados Firestore                 |
| `firebase_database`   | 12.4.7  | Banco de dados Realtime Database (RTDB)  |
| `qr_flutter`          | 4.1.0   | Geração de QR Code na tela               |
| `google_sign_in`      | 7.2.0   | Login com conta Google                   |
| `provider`            | 6.1.5+1 | Gerenciamento de estado (padrão Provider)|
| `share_plus`          | 13.3.0  | Compartilhar link da fila via WhatsApp/etc|
| `pdf` / `printing`    | 3.13.1 / 5.15.1 | Exportação e impressão de PDF       |
| `firebase_messaging`  | 16.7.0  | Push para dono e operadores              |
| `firebase_analytics` / `firebase_crashlytics` | 12.0.0 / 5.4.0 | Eventos sem PII (com opt-out) e relatório de falhas |
| `firebase_storage` / `image_picker` | 13.6.0 / 1.2.4 | Logo da fila                  |
| `app_links`           | 7.2.2   | Android App Links para `/q/{id}`         |
| `shared_preferences`  | 2.5.6   | Preferências locais (tema, opt-out de analytics) |

### Web Client (`web/package.json`)

| Biblioteca        | Versão  | Função                              |
| ----------------- | ------- | ----------------------------------- |
| `react`             | 19.2.8  | Framework UI                        |
| `react-dom`         | 19.2.8  | Renderização no DOM                 |
| `react-router-dom`  | 7.18.2  | Roteamento (URL `/q/{queueId}`)       |
| `i18next` / `react-i18next` | 26.4.2 / 17.0.16 | Internacionalização pt/en/es |
| `firebase`          | 12.17.0 | SDK JS do Firebase (Auth, RTDB, Functions, FCM, App Check, Analytics)|
| `typescript`        | 6.0.2   | Tipagem estática                    |
| `vite`              | 8.2.0   | Build tool e dev server             |

### Cloud Functions (`functions/package.json`)

| Biblioteca          | Versão | Função                                |
| ------------------- | ------ | ------------------------------------- |
| `firebase-admin`      | 13.0.0 | SDK admin do Firebase (acesso total)  |
| `firebase-functions`  | 6.0.0  | Framework de Cloud Functions v2       |

## 4. Comunicação entre Módulos

### Fluxo principal: Cliente entra na fila

```
1. Cliente escaneia QR Code
   └─ Navegador abre: https://qio.web.app/q/{queueId}

2. Web React (cliente)
   ├─ Firebase Auth: login anônimo automático (uid único por browser)
   ├─ Lê RTDB: queues/{queueId}/meta → verifica se fila está aberta
   └─ Exibe formulário (nome + telefone)

3. Cliente preenche e envia
   └─ Web React chama a callable joinQueue (exige auth anônima, App Check opcional)
      ├─ Valida nome/telefone, status da fila, limite de espera, horário e rate limit
      ├─ Transação (Admin SDK) em tickets/{queueId} → próximo número de senha
      └─ Cria queues/{queueId}/entries/{id} com status "waiting"
      (o cliente não escreve em entries nem em tickets; o espelho público public/{id} é gravado por syncPublicTicket)

4. App Flutter (proprietário) recebe atualização em tempo real
   └─ Listener RTDB na lista de entries → nova entry aparece na tela
```

### Fluxo: Proprietário chama próximo

```
1. App Flutter: botão "Chamar Próximo"
   └─ Reserva por transação RTDB: entry com menor ordem vira "called"
      └─ meta.serving atualizado

2. Web React (cliente chamado) detecta mudança
   └─ Listener RTDB: entry.status == "called" && entry.uid == meu_uid
      ├─ Tela verde: "É a sua vez!"
      ├─ Som de alerta (880Hz, 1.2s)
      └─ Vibração (se suportado)

3. Cloud Function dispara (se FCM ativo)
   └─ Trigger: entry.write com status "called"
      ├─ Lê fcmToken da entry
      └─ Envia push notification via FCM
```

### Firestore vs RTDB: por que dois bancos?

| Aspecto         | Firestore                              | RTDB                                    |
| --------------- | -------------------------------------- | --------------------------------------- |
| **Dados**         | Configuração, histórico, dados do owner | Estado vivo: posições, quem está na fila |
| **Latência**      | ~100ms                                 | ~10ms (listener em tempo real)           |
| **Custo**         | 50k reads/dia grátis                   | 100 conexões simultâneas grátis          |
| **Padrão de uso** | One-time reads, queries                | Listeners contínuos (sync automático)   |

**Regra de ouro**: Firestore guarda **quem** e **o quê** (dados persistentes). RTDB guarda **o estado atual** (posições, chamadas, tempo real).

## 5. Modelo de Dados

### Firestore (dados duráveis)

```
owners/{uid}
  └─ { name, businessName, createdAt }

queues/{queueId}
  └─ { ownerId, name, description, status, avgServiceMin, createdAt, shortcode,
       brandColor?, logoUrl?, schedule?, mode?, slots?, groupId?, alerts?, alertState? }

queues/{queueId}/{history, feedback, operators, operatorRequests}/...
owners/{uid}/{devices, groups}/...
operatorInvites/{code}

queues/{queueId}/history/{entryId}
  └─ { ticket, name, phone, result, joinedAt, calledAt, finishedAt }
```

### RTDB (estado em tempo real)

```
queues/{queueId}/
  ├─ meta/
  │   └─ { nextTicket (legado, fixo em 0; o contador real é tickets/{queueId}), serving, status, name, updatedAt, maxWaiting?, statusMessage?, resumeAt?, opensAt?,
  │        avgServiceMinAuto?, mode?, slots?, brandColor?, logoUrl? }
  ├─ entries/{entryId}  (legível só por dono, operadores e autor)
  │   └─ { ticket, name, phone, uid, fcmToken?, status, joinedAt, calledAt, order?, recalls?, skips?, slotId?, ... }
  ├─ public/{entryId}   (sem PII)
  │   └─ { ticket, status, order, slotId? }
  └─ operatorUids/{uid}: true

tickets/{queueId}        → contador numérico da senha
rateLimits/{queueId}/{uid} → timestamps dos joins

owners/{queueId}/ownerUid
  └─ espelho do ownerId para validação nas rules da RTDB
```

## 6. Segurança

- **Proprietário**: autenticação email/Google → só acessa suas próprias filas (rules Firestore)
- **Cliente**: autenticação anônima → entra pela callable `joinQueue`; lê só a própria entry (e `public/`, sem PII) e altera nela apenas `status: 'left'` e `fcmToken` (rules RTDB)
- **Regras RTDB**: escrita em `entries/{id}` pelo dono ou operador da fila; o cliente não cria entry nem escreve em `tickets`
- **Regras Firestore**: escrita em `queues/{id}` só permitida pelo `ownerId` que criou a fila
- **App Check (reCAPTCHA Enterprise)**: o cliente web (`web/src/firebase.ts`) inicializa o App Check com `ReCaptchaEnterpriseProvider` quando `VITE_RECAPTCHA_SITE_KEY` está configurada. O enforcement é aplicado **somente nas callables** `joinQueue` e `submitFeedback`, por flags em `functions/.env` (`ENFORCE_APP_CHECK`, `ENFORCE_APP_CHECK_JOIN`, `ENFORCE_APP_CHECK_FEEDBACK`), hoje todas `false`; as functions registram `appCheck: present|absent` por chamada. RTDB, Firestore e Storage ficam **sem enforcement** porque o app Flutter não usa App Check (um APK fora da Play Store não passa no Play Integrity). Rollout, rollback e debug token em [`docs/APPCHECK.md`](./APPCHECK.md).
- **Rate limit e validação**: a `joinQueue` aplica (por padrão) 3 entradas por `uid` a cada 10 minutos, recusa telefone já ativo e valida nome/telefone no servidor.

### Limitação conhecida: entradas falsas via QR Code

A auth anônima do cliente **não distingue** alguém fisicamente presente no estabelecimento de alguém que fotografou o QR Code (ou reencaminhou o link) e entra na fila remotamente. Com o enforcement ligado nas callables, o App Check bloquearia o vetor mais grave — scripts/bots automatizando entradas em massa fora do navegador — mas hoje o enforcement está desligado e, mesmo ligado, não impede um humano determinado de abrir algumas abas anônimas manualmente e criar entradas falsas em pequena escala; esse risco residual é inerente a qualquer QR Code físico e fica registrado como trabalho futuro (ex.: geolocalização na entrada, QR Code com token rotativo de curta duração).

## 7. Notificações Push (FCM)

O sistema usa uma abordagem **híbrida** para notificar o cliente:

1. **In-page** (sempre funciona): enquanto a página está aberta, listener RTDB detecta mudança de status → alerta visual + sonoro
2. **Push notification** (quando ativo): Cloud Function detecta mudança no RTDB → envia push via FCM → funciona mesmo com aba fechada (Android/desktop)

**Limitação iOS**: push web só funciona se o site for instalado na tela de início (PWA, iOS 16.4+). No MVP, iOS depende da página aberta.

## 8. Infraestrutura e Deploy

| Componente       | Onde roda                    | Deploy                           |
| ---------------- | ---------------------------- | -------------------------------- |
| App Flutter      | Dispositivo do proprietário  | `flutter build apk --release`      |
| Web Client       | Firebase Hosting             | `firebase deploy --only hosting`   |
| Cloud Functions  | Google Cloud (serverless)    | `firebase deploy --only functions` |
| Firestore/RTDB/Storage | Firebase (managed)     | `firebase deploy --only firestore:rules,database:rules,storage` (ordem em `CLAUDE.md`) |

## 9. Custos (plano Blaze, cota gratuita)

O projeto está no plano Blaze desde 01/10/2026 (exigido pelas Cloud Functions v2). O custo esperado no volume do TCC fica dentro da cota gratuita.

| Serviço                | Limite grátis           | Uso no Qio                        |
| ---------------------- | ----------------------- | --------------------------------- |
| Auth                   | Ilimitado               | OK                                |
| Firestore              | 50k reads/dia           | Baixo (1 read por entrada)        |
| RTDB                   | 100 conexões simultâneas| 1 por client com página aberta    |
| Hosting                | 10GB/mês                | Web React                         |
| Cloud Functions        | 2M invocações/mês       | `joinQueue` por entrada; gatilhos de RTDB/Firestore |
| FCM                    | Gratuito                | Notificações push                 |

**Gargalo principal**: conexões simultâneas no RTDB. No Spark o limite era 100; no Blaze sobe para 200 mil por instância, bem acima do necessário para o MVP.

## 10. Referências

- Especificação original do MVP: [`docs/SPEC.md`](./SPEC.md)
- Quadro de resultados (testes, cobertura, CI, limitações): [`docs/qualidade.md`](./qualidade.md)
- App Check: [`docs/APPCHECK.md`](./APPCHECK.md); monitoramento e analytics: [`docs/monitoring.md`](./monitoring.md)
- Guia de ativação do FCM: [`docs/FCM.md`](./FCM.md)
- Repositório: `github.com/felipeselau/qio`
