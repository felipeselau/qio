# Qualidade — quadro de resultados

Medições feitas em 08/10/2026 sobre `main` no commit `8948214` (app 1.4.0+5), em
máquina local (macOS), exceto o tempo de CI, que vem do GitHub Actions. O que não
foi medido está marcado como "não medido". Comandos de cada módulo: `CLAUDE.md`.

## 1. Testes por módulo

| Módulo | Comando | Arquivos de teste | Testes | Passaram | Falharam |
| --- | --- | --- | --- | --- | --- |
| `app/` (unidade, widget e goldens) | `flutter test` | 56 | 451 | 451 | 0 |
| `functions/` (lógica pura em `src/`) | `npm test` (`node --test`) | 14 | 155 | 155 | 0 |
| `rules-tests/` — rules (Firestore, RTDB, Storage) | `npm run test:rules` | 3 | 167 | 167 | 0 |
| `rules-tests/` — callable `joinQueue` nos emulators | `npm run test:callable` | 1 | 28 | 28 | 0 |
| `web/` | — | 0 | sem testes automatizados | — | — |
| **Total automatizado** | | **74** | **801** | **801** | **0** |

Outras verificações estáticas: `flutter analyze lib test` sem problemas;
`npm run lint` (oxlint) do `web/` sem erros; `npm run build` do `web/` conclui (aviso
de chunk acima de 500 kB).

Observações:

- O app inclui widget tests das telas principais (#131) e goldens em claro/escuro
  (#137; 13 imagens em `app/test/goldens/`). Os goldens usam a fonte Ahem do
  `flutter_test`: protegem layout, cores e tema, não glifos.
- Os testes de `rules-tests/` rodaram com um `firebase.json` temporário em portas
  alternativas, porque 5001, 8080 e 9000 estavam ocupadas por outros processos. O
  teste da callable lê o host das functions de `FUNCTIONS_EMULATOR_HOST`; sem isso
  ele usa `localhost:5001`. O resultado vale para o código, não para as portas.
- Os 28 testes da callable exercitam `functions/index.js` (handlers) contra os
  emulators; os 155 testes de `functions/` cobrem só os módulos puros de `src/`.

## 2. Cobertura

| Módulo | Ferramenta | Linhas | Ramos | Funções |
| --- | --- | --- | --- | --- |
| `app/` | `flutter test --coverage` (`lcov.info`) | 60,11% (4761/7920) | não medido | não medido |
| `functions/src/` | `node --test --experimental-test-coverage` | 99,91% (linha "all files") | 97,05% | 98,86% |
| `web/` | — | não medido | não medido | não medido |
| `rules-tests/` | — | não medido | não medido | não medido |

Como ler os números:

- **App**: o lcov cobre 90 dos 92 arquivos de `app/lib/`; `main.dart` e
  `firebase_options.dart` não são carregados por nenhum teste e ficam fora do
  percentual. Por pasta (linhas): `models` 99,7%, `controllers` 95,7%, `theme` 94,9%,
  `widgets` 87,0%, `widgets/queue_panel` 64,2%, `services` 59,3%, `screens` 51,0%,
  `l10n` 42,3% (código gerado).
- **Functions**: a linha "all files" do relatório do Node inclui os próprios arquivos
  de teste. Dos módulos de `src/`, os menores valores são `webpush.js` (98,72% de
  linhas, 86,67% de ramos) e `schedule.js` (99,09% de linhas). `functions/index.js`
  (os handlers) não é carregado pelos testes unitários e não aparece no relatório;
  ele só é exercitado, sem medição de cobertura, pelos testes da callable.
- O CI não coleta cobertura nem aplica um limite mínimo.

## 3. CI (`.github/workflows/ci.yml`)

Dados de `gh run list --workflow ci.yml --limit 15`. Das 15 execuções, 14 estavam
concluídas (13 com sucesso, 1 com falha) e 1 em andamento, que foi descartada. A
duração é `updatedAt − startedAt` de cada execução (aproximação do tempo total).

| Métrica | Valor |
| --- | --- |
| Tempo médio (14 execuções concluídas) | 141 s (2 min 21 s) |
| Tempo médio só das 13 com sucesso | 143 s |
| Mínimo / máximo | 110 s / 184 s |
| Taxa de sucesso na amostra | 13/14 |

Checks (jobs) em `push` e `pull_request` para `main`:

| Job | Passos |
| --- | --- |
| `flutter` | Flutter 3.44.3, `flutter pub get`, `flutter analyze lib test`, `flutter test` (inclui goldens; em falha envia as imagens de diferença como artefato) |
| `web` | Node 22, `npm ci`, `npm run build` (`tsc -b && vite build`) |
| `functions` | Node 22, `npm ci`, `npm test` |
| `rules` | Java 21, Node 22, `npm ci` (e em `functions/`), `firebase-tools`, `npm test` (as duas passadas) |
| `deploy-hosting` | só em `push` para `main`, depois dos quatro anteriores; publica o hosting se `secrets.FIREBASE_TOKEN` existir, senão passa com aviso e **não** publica |

Não estão no CI: `npm run lint` do `web/`, cobertura, deploy de functions e de rules
(manuais).

## 4. Testes manuais e de integração

Os casos CLI, DON, OPE, CON e INT de `docs/testes/casos-de-teste.md` foram
executados em 30/09 e 01/10/2026 (app v1.1.0). Não foram reexecutados para as
funcionalidades posteriores; para elas só existe cobertura automatizada. Pendentes
ou bloqueados no registro: CLI-11 e INT-03 (entrega de push em aparelho real),
CLI-12 (iOS) e INT-04 (App Check em produção).

## 5. Limitações conhecidas

Dados e exportação

- CSV: separador vírgula e números com ponto decimal (`toStringAsFixed`). Abrir no
  Excel com configuração regional pt-BR pode juntar colunas ou tratar números como
  texto.
- PDF: usa a fonte padrão do pacote `pdf`; caracteres fora do que ela cobre (por
  exemplo emoji) não são renderizados.
- Métricas e exportações têm limite de histórico lido (`historyLimit`, com aviso de
  truncamento no relatório).

Consistência

- Contagem de vagas por slot (`slot-full`) e limite de fila (`queue-full`) não usam
  transação de contagem: joins simultâneos podem passar a capacidade em uma ou duas
  vagas.
- Dual-write: o app grava no Firestore (fonte da verdade) e espelha parte no RTDB
  (`meta`, `owners/{queueId}`, `operatorUids`, `slots`). Uma falha entre as duas
  escritas deixa os dois divergentes até o próximo `ensureMirror`.
- Slots são diários, em fuso fixo `America/Sao_Paulo`; sem data, calendário,
  reagendamento pelo cliente nem integração com o horário de funcionamento.
- Rules do RTDB não limitam `slots` a 24 (a function corta ao ler); rules do
  Firestore não validam `id` nem unicidade dos slots (o app valida antes de gravar).
  O limite de 20 grupos por dono é checado só no app.
- Alertas operacionais: se o envio FCM falhar depois da gravação de `alertState`, o
  alerta se perde até o fim do cooldown.

Segurança

- App Check sem enforcement: existe só nas callables `joinQueue` e `submitFeedback` e
  está desligado (`ENFORCE_APP_CHECK=false`). RTDB, Firestore e Storage não terão
  enforcement porque o app Flutter não usa App Check.
- Auth anônima não prova presença física: quem tem o link ou uma foto do QR entra na
  fila remotamente. Rate limit e validação mitigam, não eliminam.

Plataformas e entrega

- Push web no iOS só com a PWA instalada na tela inicial (iOS 16.4+). A entrega em
  aparelho real ainda não foi validada.
- Deep links: só Android App Links; iOS (Associated Domains) não foi feito.
- Aviso in-app ao dono funciona com o painel aberto; com o app fechado depende do
  push (`onEntryJoined`).
- Deploy do hosting depende de `secrets.FIREBASE_TOKEN`; functions e rules são
  publicadas manualmente, com ordem que importa (ver `CLAUDE.md`).
- PWA sem service worker de cache: não há uso offline.

Testes

- `web/` não tem testes automatizados.
- Goldens com Ahem não detectam mudança de glifo ou de fonte.
- Cobertura do app (60,11%) é medida só sobre arquivos carregados pelos testes e não
  entra no CI.
- Monitoramento técnico (alertas de erro, uptime check, orçamento, ativação do
  Analytics) é ação manual no console (`docs/monitoring.md`); não verificado aqui.
