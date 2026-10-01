# Ambiente de teste local (emulators)

Usado para executar os casos de dono, operador e concorrência sem tocar em
produção. Auth, Firestore e RTDB rodam nos emulators com as rules do repo.

```bash
firebase emulators:start --only auth,firestore,database --project qio-app
cd app && flutter build web --dart-define=USE_EMULATORS=true
python3 -m http.server 5300 --directory app/build/web   # dono: http://localhost:5300, operador: http://127.0.0.1:5300
cd web && VITE_USE_EMULATORS=true npx vite --port 5180   # cliente: http://localhost:5180/q/{id}
```

Dono e operador usam origens diferentes (`localhost` x `127.0.0.1`) para ter
sessões de login separadas no mesmo navegador.

Contas de teste (existem só no emulator de auth):

| Papel | E-mail | Senha |
| --- | --- | --- |
| Dono | dono@qio.test | teste-qio-2026 |
| Operador | operador@qio.test | teste-qio-2026 |
