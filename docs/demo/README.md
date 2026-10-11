# Universo demo (emulator)

Contas de demonstração 100% populadas para avaliar métricas, histórico, grupos, operadores,
alertas e o wizard de criação com dados críveis (TCC, banca, demo). Issue #236.

**Só emulator.** O seed recusa rodar se `FIRESTORE_EMULATOR_HOST`,
`FIREBASE_AUTH_EMULATOR_HOST` e `FIREBASE_DATABASE_EMULATOR_HOST` não existirem e não apontarem
para `localhost`/`127.0.0.1`/`::1` (`functions/scripts/demo/guard.js`, testado). Ele também
descarta `GOOGLE_APPLICATION_CREDENTIALS`: não há credencial de produção no caminho. Nada aqui
toca o projeto `qio-app` real.

## Subir

Pré-requisitos: Node 22, Java 21+, `firebase-tools` e `npm ci` em `functions/`.

```bash
ops/demo-up.sh              # seed novo (≈15 s) + emuladores completos
ops/demo-up.sh --reuse      # reaproveita .demo-data/export, sem refazer o seed
ops/demo-up.sh -- --days 90 # argumentos depois de -- vão para o seed
ops/demo-down.sh            # para só o PID que o demo-up registrou (--clean apaga .demo-data)
```

O que o `demo-up.sh` faz:

1. Confere as portas (auth 9099, firestore 8080 + websocket 9150, database 9000, storage 9199,
   functions 5001, hub 4400, logging 4500, eventarc 9299). Se alguma estiver ocupada, falha e
   mostra quem a usa; **nunca encerra processos de terceiros**. Override por env:
   `DEMO_PORT_AUTH`, `DEMO_PORT_FIRESTORE`, `DEMO_PORT_FIRESTORE_WS`, `DEMO_PORT_DATABASE`,
   `DEMO_PORT_STORAGE`, `DEMO_PORT_FUNCTIONS`, `DEMO_PORT_HUB`, `DEMO_PORT_LOGGING`,
   `DEMO_PORT_EVENTARC`, `DEMO_HOST`. O app Flutter e a web do cliente têm as portas padrão
   fixas no código, então use override só para testes.
2. Gera `.firebase.demo.generated.json` a partir do `firebase.json` (só a seção `emulators`
   muda; o `firebase.json` de produção/CI não é alterado). Ambos os arquivos gerados estão no
   `.gitignore`.
3. **Fase 1:** sobe auth/firestore/database/storage **sem functions** e roda o seed. Sem
   functions de propósito: os triggers (`syncPublicTicket`, `mirror*`, `updateServiceEstimate`)
   reagiriam a cada escrita do seed (e mexeriam em `public/`, `waitingCount` etc.).
4. Exporta tudo para `.demo-data/export` e derruba a fase 1.
5. **Fase 2:** sobe o conjunto completo, **incluindo functions**, com
   `--import .demo-data/export`. O import **não dispara triggers**; a partir daí as callables
   (`joinQueue`, `addManualEntry`, `deleteQueue`...) e os triggers de RTDB/Firestore funcionam
   para escritas novas (ex.: entrar na fila pela web atualiza `public/` e `waitingCount`).
   `DEMO_EXPORT_ON_EXIT=1` persiste as mudanças ao sair.

Limitações do ambiente: o emulator de Pub/Sub não sobe, então as funções agendadas
(`evaluateQueueAlerts`, `expireStaleEntries`, `applyQueueSchedules`, `reconcileWaitingCounts`,
`purgeOldHistory`) **não rodam**; o estado delas já vem semeado (`alertState`, `opensAt`,
`lastTicketResetDay`). Logos não são semeados (o host exigido é o do Storage de produção); a cor
da fila aparece e o logo pode ser enviado pelo app (o emulator de Storage está de pé).

## Apontar os clientes para os emuladores

```bash
# App do dono (Flutter web, porta fixa para o login por e-mail)
cd app && flutter run -d chrome --dart-define=USE_EMULATORS=true
# Android emulator: --dart-define=EMULATOR_HOST=10.0.2.2 (e DEMO_HOST=0.0.0.0 no demo-up)
# ou build web: flutter build web --dart-define=USE_EMULATORS=true

# Web do cliente (QR / entrada na fila)
cd web && npm ci && VITE_USE_EMULATORS=true npm run dev
# abra http://localhost:5173/q/demo-padaria-balcao  (ou /n/paopquente)
```

## Contas

Senha única de todas as contas, **válida só no emulator**: `qio-demo-2026`.

| E-mail | Papel | Quem é |
| --- | --- | --- |
| `padaria@qio.demo` | Dono | Helena Duarte, Padaria Pão Quente |
| `clinica@qio.demo` | Dono | Dra. Renata Albuquerque, Clínica Vida Plena |
| `barbearia@qio.demo` | Dono | Rodrigo Almeida, Barbearia Navalha |
| `cartorio@qio.demo` | Dono | Antônio Carvalho, Cartório Central |
| `foodtruck@qio.demo` | Dono | Bianca Rocha, Food Truck Festival |
| `otica@qio.demo` | Dono | Marcos Tavares, Rede Ótica Visão |
| `novo@qio.demo` | Dono (conta nova, sem filas) | Lívia Torres |
| `operador1@qio.demo` | Operador em **dois donos** | Marina Lopes: clínica (Consultas, Pediatria) e cartório (Certidões); a mais rápida |
| `operador2@qio.demo` | Operador | Rafael Teixeira: clínica (Consultas, Exames) |
| `operador3@qio.demo` | Operador | Juliana Prado: clínica (as 4 filas); a mais lenta |
| `operador4@qio.demo` | Operador | Carlos Mendes: cartório (Casamentos, Nascimentos, Escrituras) |
| `operador5@qio.demo` | Operador com **pedido pendente** | Beatriz Nunes: cartório (Casamentos) |
| `barbeiro1@qio.demo`, `barbeiro2@qio.demo` | Operadores | Thiago Ramos e Caio Freitas: barbearia (barbeiro2 também tem um pedido **rejeitado** na padaria) |
| `atendente1@qio.demo`, `atendente2@qio.demo`, `atendente3@qio.demo` | Operadores | Patrícia Gomes, Sérgio Batista e Luana Cardoso: cartório (atendente3 tem um pedido **removido** na clínica) |
| `balconista1@qio.demo` | Operador | Davi Ribeiro: padaria (Balcão) |

IDs de fila estáveis: `demo-<dono>-<fila>` (ex.: `demo-padaria-balcao`,
`demo-cartorio-firma`, `demo-otica-centro-exame`). Links curtos: `paopquente` (padaria),
`vidaplena` (clínica), `navalha` (barbearia), `cartorio-central`, `otica-visao-centro`.
Os códigos de convite de operador são gerados pelo seed; veja em "Operadores" na fila.

## Roteiro: o que olhar em cada conta

"Agora" é a hora em que o seed roda; o histórico cobre os últimos 120 dias terminando agora.
Números abaixo são faixas esperadas (cada execução diverge um pouco com outro "agora").

1. **padaria@** (2 filas: Balcão, Encomendas). Métricas do Balcão: heatmap com picos 7-9 h e
   16-18 h, sábado e domingo acima dos dias úteis, ~+15% de demanda no último mês na tendência,
   no-show ~1,5%, ★ ~4,6, espera média ~2 min e atendimento ~2,3 min. Histórico passa de 500 docs
   (aviso de truncamento nas métricas). Painel ao vivo: ~6 esperando + 1 chamado, entrada manual
   no meio (selo de balcão), convite de operador válido, link curto e QR em `/n/paopquente`.
2. **clinica@** (4 filas em 2 grupos). Home agrupada (Unidade Centro: Consultas e Exames; Unidade
   Norte: Pediatria e Retirada de resultados). Consultas e Pediatria em hora marcada (slots de 30
   min, capacidade 2 e 1; o seletor de horário na web do cliente). No-show ~12-15%, pior às
   segundas e no primeiro horário, caindo nas últimas ~4 semanas (efeito dos "lembretes"). Compare
   as filas dentro do grupo e a produtividade de operador1 (rápida) × operador3 (lenta).
   Pediatria **pausada** com mensagem e retorno em ~40 min, sem telefone no histórico
   (`anonymizePhone`). Retirada de resultados **fechada por horário** (`opensAt`). Alertas ligados
   (Exames tem `alertState` recente), expiração de 12 h em todas, convite expirado em Exames.
3. **barbearia@**. Hora marcada (20 horários, 1 por horário) + Fila de passagem. Atendimento
   25-45 min, sábado lotado (maior demanda e espera), recalls e skips ("Mover para o fim"
   e "Chamar de novo") no histórico, 2 barbeiros, ★ ~4,8.
4. **cartorio@** (6 filas em 2 grupos: Registro Civil, Notas e Protestos). Esperas longas
   (P90 acima de 60 min em Certidões, Casamentos e Reconhecimento de firma), atendimento com
   outliers, ★ ~3,4, demanda e tempo de atendimento **piorando** ao longo dos meses, 5
   operadores. **Reconhecimento de firma está cheia agora** (`maxWaiting 30` = 30 esperando:
   tente entrar em `/q/demo-cartorio-firma` e veja `queue-full`); Certidões tem limite 60 e 38
   esperando, com alerta de espera alta ativo (`alertState.waitAt` recente). Operador4 e
   operador5 (pedido pendente para aprovar em Casamentos).
5. **foodtruck@** (1 fila, fechada agora). Só ~14 dias de histórico, concentrado em dois fins de
   semana (sex-dom) com rajadas de chegada e ~50% de desistência; no meio, dias sem dados. Serve
   para os estados de "poucos dados" nas métricas e tendências.
6. **otica@** (20 filas = o limite, 4 grupos de lojas). Home agrupada com 20 cartões; criar a 21ª
   fila mostra o gate do limite no wizard antes de pedir os passos. Histórico leve (30-60 dias),
   perfis variados (exame de vista em hora marcada, filas pausadas e fechadas, algumas com
   `maxWaiting`).
7. **novo@** (sem filas). Onboarding, tour da primeira abertura e wizard de criação do zero.
8. **Operadores**: entre com `operador1@` e veja a seção "Sou operador" com filas de dois
   estabelecimentos; `operador5@` mostra o pedido pendente; a produtividade por atendente aparece nas
   métricas do dono.

## Seed (CLI)

```bash
node functions/scripts/demo/index.js [--reset] [--days 120] [--seed qio-demo-v1] [--now ISO] [--only padaria,clinica] [--dry-run]
```

`--dry-run` não precisa de emulator: imprime a tabela de métricas por fila (atendimentos,
no-show %, desistência %, espera média/P90, ★, ao vivo). Sem `--dry-run` exige as três variáveis
de emulator.

- **Determinismo:** mesma `--seed` e mesmo `--now` geram os mesmos dados (PRNG mulberry32 com
  seed por fila). Por padrão `--now` é a hora atual.
- **Idempotente:** cada execução apaga os dados das filas e contas demo (lista de ids
  determinísticos `demo-*`, slugs e convites do universo) e regrava tudo; rodar duas vezes não
  duplica nada, mesmo em dias diferentes. `--reset` também varre qualquer id com prefixo `demo-`
  e qualquer conta `@qio.demo` que sobrou de versões antigas. Nenhum doc fora desse escopo é
  apagado.
- **Simulação** (`functions/scripts/demo/simulate.js`): chegadas Poisson por dia da semana e hora,
  servidores/operadores com produtividade distinta, atendimento lognormal, desistência por
  paciência, no-show por perfil/dia/tendência, re-chamadas e skips, nomes e telefones
  mascarados, feedback ★ correlacionado com a espera, horários (slots) com capacidade, entradas
  manuais, feriados fixos e dias fechados. Reaproveita `estimate.js` (`avgServiceMinAuto`),
  `ticket.js` (`public/`) e `schedule.js` (`opensAt`).
- **Ao vivo:** o dia de hoje é simulado até agora; filas com `live` ganham uma janela de 40 min
  com entradas injetadas para garantir o estado esperado (ex.: 6 esperando na padaria) mesmo
  que o seed rode de madrugada. Filas fechadas/pausadas não recebem chegadas novas.
- Tickets reiniciam por dia só nas filas com `expiry.resetTicketDaily`; nas demais a senha
  continua crescendo, como na produção.
- Testes: `cd functions && npm test` (`test/demo-guard.test.js`, `test/demo-universe.test.js`;
  `DEMO_TEST_NOW=<ISO>` roda os mesmos invariantes com outro "agora").
