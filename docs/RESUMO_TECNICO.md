# Qio — Resumo Técnico

## 1. O que é o Qio

Qio é um **sistema de filas para atendimentos presenciais**. O proprietário (owner) cria filas no aplicativo móvel e gera um QR Code. O cliente (client) escaneia o QR Code e entra na fila pelo navegador do celular — **sem precisar instalar nenhum aplicativo**. Quando chega a sua vez, o cliente recebe uma notificação (push notification ou alerta na página).

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
- **Tecnologia**: Flutter 3.x (Dart)
- **O que faz**:
  - Cadastro/login (email ou Google)
  - Criação de filas (nome, descrição)
  - Geração de QR Code com link para o cliente entrar
  - Controle de fila: chamar próximo, marcar como atendido/faltou
  - Visualização da lista de espera em tempo real

### Módulo 2: Web React (Cliente)

- **Função**: página web que o cliente acessa escaneando o QR Code. Não requer instalação.
- **Tecnologia**: React 19 + TypeScript + Vite
- **O que faz**:
  - Autenticação anônima (sem cadastro)
  - Formulário: nome + telefone (obrigatório o primeiro, opcional o segundo)
  - Exibe senha numérica, posição na fila e tempo estimado de espera
  - Recebe alerta visual + sonoro quando chamado
  - Botão para sair da fila voluntariamente

### Módulo 3: Firebase (Backend)

- **Função**: infraestrutura de backend completo (autenticação, banco de dados, funções serverless, hospedagem).
- **Serviços utilizados**:
  - **Authentication**: login do proprietário (email/Google) e do cliente (anônimo)
  - **Firestore**: banco de dados relacional para dados duráveis (proprietários, filas, histórico)
  - **Realtime Database (RTDB)**: banco de dados em tempo real para estado vivo das filas (posições, chamadas)
  - **Cloud Functions**: funções serverless que disparam notificações push
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

### Web Client (`web/package.json`)

| Biblioteca        | Versão  | Função                              |
| ----------------- | ------- | ----------------------------------- |
| `react`             | 19.2.8  | Framework UI                        |
| `react-dom`         | 19.2.8  | Renderização no DOM                 |
| `react-router-dom`  | 7.18.2  | Roteamento (URL `/q/{queueId}`)       |
| `firebase`          | 12.17.0 | SDK JS do Firebase (Auth, RTDB, FCM)|
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
   └─ Web React escreve no RTDB:
      ├─ Transação em tickets/{queueId} → próximo número de senha
      └─ Push em queues/{queueId}/entries/ → nova entry com status "waiting"

4. App Flutter (proprietário) recebe atualização em tempo real
   └─ Listener RTDB na lista de entries → nova entry aparece na tela
```

### Fluxo: Proprietário chama próximo

```
1. App Flutter: botão "Chamar Próximo"
   └─ Transação RTDB: entry com menor ticket vira "called"
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
  └─ { ownerId, name, description, status, avgServiceMin, createdAt, shortcode }

queues/{queueId}/history/{entryId}
  └─ { ticket, name, phone, result, joinedAt, calledAt, finishedAt }
```

### RTDB (estado em tempo real)

```
queues/{queueId}/
  ├─ meta/
  │   └─ { nextTicket, serving, status, name, updatedAt }
  ├─ entries/{entryId}
  │   └─ { ticket, name, phone, uid, fcmToken?, status, joinedAt, calledAt }
  └─ tickets/
      └─ { queueId: contador_numérico }

owners/{queueId}/ownerUid
  └─ espelho do ownerId para validação nas rules da RTDB
```

## 6. Segurança

- **Proprietário**: autenticação email/Google → só acessa suas próprias filas (rules Firestore)
- **Cliente**: autenticação anônima → só lê/escreve sua própria entry na fila (rules RTDB)
- **Regras RTDB**: escrita em `entries/{id}` só permitida pelo `uid` dono da entry OU pelo owner da fila
- **Regras Firestore**: escrita em `queues/{id}` só permitida pelo `ownerId` que criou a fila

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
| Firestore/RTDB   | Firebase (managed)           | `firebase deploy --only rules`     |

## 9. Custos (Free Tier Spark)

| Serviço                | Limite grátis           | Uso no Qio                        |
| ---------------------- | ----------------------- | --------------------------------- |
| Auth                   | Ilimitado               | OK                                |
| Firestore              | 50k reads/dia           | Baixo (1 read por entrada)        |
| RTDB                   | 100 conexões simultâneas| 1 por client com página aberta    |
| Hosting                | 10GB/mês                | Web React                         |
| Cloud Functions        | 2M invocações/mês       | 1 por chamada de cliente          |
| FCM                    | Gratuito                | Notificações push                 |

**Gargalo principal**: 100 conexões simultâneas no RTDB. Suficiente para validar o MVP; escalar exige plano Blaze.

## 10. Referências

- Especificação completa do MVP: [`docs/SPEC.md`](./SPEC.md)
- Guia de ativação do FCM: [`docs/FCM.md`](./FCM.md)
- Repositório: `github.com/felipeselau/qio`
