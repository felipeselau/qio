# Qio

App para agendamentos e atendimentos presenciais, criação de filas.

## Estrutura

```
qio/
├── app/          # Flutter (owner)
├── web/          # React + Vite + TS (client)
├── functions/    # Cloud Functions (FCM)
├── docs/SPEC.md  # especificação do MVP
├── design/       # arquivos .pen (Pencil)
├── firebase.json
├── firestore.rules
├── database.rules.json
```

## Stack

- **Owner**: Flutter 3.x + Firebase (Auth, Firestore, RTDB, qr_flutter, share_plus)
- **Client**: React + Vite + TypeScript + Firebase JS SDK (https://qio.web.app/q/{queueId})
- **Backend**: Firebase (projeto `qio-app`)

## Setup Flutter

```bash
cd app
flutter pub get
flutterfire configure --project=qio-app  # se precisar regenerar firebase_options.dart
flutter run
```

## Setup Web

```bash
cd web
npm ci
npm run dev        # desenvolvimento
npm run build      # produção (dist/)
```

## Firebase

Projeto: `qio-app`

- Auth: email/password + Google (owner), anônima (client)
- Firestore: `owners/{uid}`, `queues/{queueId}`, `queues/{queueId}/history/{entryId}`
- RTDB: `queues/{queueId}/meta`, `queues/{queueId}/entries/{entryId}`, `queues/{queueId}/tickets`, `owners/{queueId}`

Deploy das rules:
```bash
firebase deploy --only firestore:rules,database:rules
```

Deploy do hosting:
```bash
firebase deploy --only hosting
```

## Release Android (assinatura)

- Keystore: `app/android/release.keystore` (alias `qio-key`) — **gitignored**
- Credenciais: `app/android/key.properties` (storePassword/keyPassword) — **gitignored**
- **Backup das credenciais**: `~/.qio/keystore-credentials.txt` (chmod 600)

Build do APK release:
```bash
cd app
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ Se perder o keystore/credenciais, o APK não pode ser atualizado sem re-assinar.

## MVP

Ver `docs/SPEC.md` para especificação completa. Ver `docs/FCM.md` para ativação de push notifications.
