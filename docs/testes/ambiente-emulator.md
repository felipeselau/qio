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

## Dados de demonstração e prints

Com os emulators no ar, `node functions/scripts/seed-emulator.js` cria a conta
do dono, duas filas (`qdemo1`, `qdemo2`), histórico com horários variados,
avaliações e quatro pessoas na fila ativa. As telas novas do app (tour,
métricas, modo escuro, idiomas, histórico com avaliação) foram capturadas assim,
com o app rodando em `flutter run -d web-server --dart-define=USE_EMULATORS=true`.

Se a porta 5001 estiver ocupada, suba os emulators com outra porta para
functions (copie `firebase.json` trocando `emulators.functions.port`) e rode a
web com `VITE_FUNCTIONS_EMULATOR_PORT=<porta>`.

O `flutter build web` em release com `USE_EMULATORS` pode ficar em branco por
`MissingPluginException` do `shared_preferences`; use o servidor de debug.
