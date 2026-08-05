# Qio

Sistema de filas para atendimentos presenciais. Proprietários criam filas no app móvel e geram QR Codes; clientes escaneiam o QR e entram na fila pelo navegador — sem instalar app.

## Documentação

| Documento                        | Descrição                                        |
| -------------------------------- | ------------------------------------------------ |
| [`docs/RESUMO_TECNICO.md`](docs/RESUMO_TECNICO.md) | **Resumo técnico completo** — stack, bibliotecas, arquitetura, comunicação entre módulos, modelo de dados, segurança, custos |
| [`docs/SPEC.md`](docs/SPEC.md)           | Especificação do MVP — personas, fluxos, escopo, rules |
| [`docs/FCM.md`](docs/FCM.md)             | Guia de ativação de push notifications (FCM)     |

## Estrutura

```
qio/
├── app/          # Flutter — app do proprietário (Android/iOS)
├── web/          # React + Vite + TypeScript — página do cliente (navegador)
├── functions/    # Cloud Functions — notificações push (FCM)
├── docs/         # Documentação do projeto
├── design/       # Arquivos de design (Pencil .pen)
├── firebase.json
├── firestore.rules
├── database.rules.json
```

## Stack

| Módulo       | Tecnologia                                              |
| ------------ | ------------------------------------------------------- |
| **App Owner**  | Flutter 3.x + Firebase (Auth, Firestore, RTDB) + Provider |
| **Web Client** | React 19 + TypeScript + Vite + Firebase JS SDK          |
| **Backend**    | Firebase: Auth, Firestore, RTDB, Cloud Functions, Hosting, FCM |

## Setup

### Flutter (proprietário)

```bash
cd app
flutter pub get
flutterfire configure --project=qio-app
flutter run
```

### Web (cliente)

```bash
cd web
npm ci
npm run dev        # desenvolvimento
npm run build      # produção (dist/)
```

### Firebase

```bash
# Regras
firebase deploy --only firestore:rules,database:rules

# Hosting
firebase deploy --only hosting
```

## Release Android

- Keystore: `app/android/release.keystore` (alias `qio-key`) — **gitignored**
- Credenciais: `app/android/key.properties` — **gitignored**
- Backup: `~/.qio/keystore-credentials.txt` (chmod 600)

```bash
cd app
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ Se perder o keystore/credenciais, o APK não pode ser atualizado sem re-assinar.

## MVP

Ver [`docs/RESUMO_TECNICO.md`](docs/RESUMO_TECNICO.md) para visão técnica completa.
Ver [`docs/SPEC.md`](docs/SPEC.md) para especificação detalhada de personas, fluxos e escopo.
