# Qio

App para agendamentos e atendimentos presenciais, criação de filas.

## Estrutura

```
qio/
├── app/          # Flutter (owner)
├── web/          # React + Vite + TS (client) — em breve
├── functions/    # Cloud Functions — em breve
├── docs/SPEC.md  # especificação do MVP
├── design/       # arquivos .pen (Pencil)
├── firebase.json
├── firestore.rules
├── database.rules.json
```

## Stack

- **Owner**: Flutter 3.x + Firebase (Auth, Firestore, RTDB, qr_flutter)
- **Client**: React + Vite + TypeScript + Firebase JS SDK (em breve)
- **Backend**: Firebase (projeto `qio-app`)

## Setup Flutter

```bash
cd app
flutter pub get
flutterfire configure --project=qio-app  # se precisar regenerar firebase_options.dart
flutter run
```

## Firebase

Projeto: `qio-app`

- Auth: email/password + Google (owner), anônima (client)
- Firestore: `owners/{uid}`, `queues/{queueId}`, `queues/{queueId}/history/{entryId}`
- RTDB: `queues/{queueId}/meta`, `queues/{queueId}/entries/{entryId}`, `owners/{queueId}`

Deploy das rules:
```bash
firebase deploy --only firestore:rules,database:rules
```

## MVP

Ver `docs/SPEC.md` para especificação completa.