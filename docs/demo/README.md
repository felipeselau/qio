# Universo demo (emulator)

Contas de demonstração 100% populadas para avaliar métricas, histórico, grupos, operadores,
alertas e o wizard de criação com dados críveis (TCC, banca, demo). Issue #236. Os indicadores de BI
(Por atendente e Desistências, `docs/metricas-bi.md`) têm padrões calibrados: ver o
[roteiro de demonstração](#roteiro-de-demonstração-de-bi) abaixo.

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
| `operador1@qio.demo` | Operador **Ana Lima**, a **rápida** (0,6x da mediana) | Padaria (Balcão), clínica (Consultas, Pediatria, Exames), cartório (Certidões) e ótica Loja Centro (Atendimento geral, Exame, Retirada) |
| `operador2@qio.demo` | Operador **Bruno Reis**, o **médio** (1,0x) | Padaria (Balcão), clínica (Consultas, Exames) e ótica Loja Centro (Atendimento geral, Exame, Retirada, Lentes) e Loja Norte (Atendimento geral) |
| `operador3@qio.demo` | Operador **Carla Souza**, a **lenta** (1,5x) | Padaria (Balcão), clínica (as 4 filas) e ótica Loja Centro (Atendimento geral, Assistência, Lentes) |
| `operador6@qio.demo` | Operador **Diego Alves**, o **ocioso** (1,0x, mas faz pausas com gente esperando) | Padaria (Balcão), clínica (Exames) e ótica Loja Centro (Atendimento geral, Assistência) |
| `operador4@qio.demo` | Operador | Carlos Mendes: cartório (Casamentos, Nascimentos, Escrituras) |
| `operador5@qio.demo` | Operador com **pedido pendente** | Beatriz Nunes: cartório (Casamentos) |
| `barbeiro1@qio.demo`, `barbeiro2@qio.demo` | Operadores | Thiago Ramos e Caio Freitas: barbearia (barbeiro2 também tem um pedido **rejeitado** na padaria) |
| `atendente1@qio.demo`, `atendente2@qio.demo`, `atendente3@qio.demo` | Operadores | Patrícia Gomes, Sérgio Batista e Luana Cardoso: cartório (atendente3 tem um pedido **removido** na clínica) |
| `balconista1@qio.demo` | Operador | Davi Ribeiro (0,85x): ótica Loja Rua XV (Atendimento geral), de segunda a sexta, das 9 às 11 h e das 13 às 18 h (não cobre as 12 h de segunda, as 18 h de sexta nem o sábado). Os scripts de `docs/testes/` também o vinculam a uma fila de teste |

IDs de fila estáveis: `demo-<dono>-<fila>` (ex.: `demo-padaria-balcao`,
`demo-cartorio-firma`, `demo-otica-centro-atendimento`). Links curtos: `paopquente` (padaria),
`vidaplena` (clínica), `navalha` (barbearia), `cartorio-central`, `otica-visao-centro`.
Os códigos de convite de operador são gerados pelo seed; veja em "Operadores" na fila.

## Roteiro de demonstração de BI

Este roteiro cobre os pontos pedidos pelo orientador (operadores, horários de pico, desistência,
espera x desistência, períodos, simulação ao vivo, filtros, capacidade e estimativa). Explicação
formal de cada indicador (o que é, como calcula, dados, utilidade): `docs/metricas-bi.md`; no app,
o botão "i" ao lado de cada título mostra o mesmo texto.

### Antes de começar

1. `ops/demo-up.sh` (aguarde o script terminar a fase 2; se uma porta estiver ocupada o script para e diz
   qual, não derrube o processo alheio: libere a porta ou use os overrides `DEMO_PORT_*`).
2. Em outro terminal: `cd app && flutter run -d chrome --dart-define=USE_EMULATORS=true`.
   Para o cenário ao vivo, em um terceiro: `cd web && VITE_USE_EMULATORS=true npm run dev`.
3. Entre com `otica@qio.demo` / `qio-demo-2026`. Na home abra "Métricas das
   filas" (ícone no AppBar). A tela abre em **7 dias** e no escopo "Todas as filas".
4. Para cada cenário: escolha o escopo (seletor "Escolher escopo": "Grupo: Loja Shopping Centro" e
   depois "Fila: Atendimento geral", ou direto a fila) e o período (chips Hoje, 7 dias, 30 dias,
   Personalizado, Tudo).

Dois fatos que valem para todos os cenários:

- O app lê só os **500 atendimentos mais recentes por fila** (`QueueService.historyFetchLimit`) e
  avisa "Mostrando só os 500 registros mais recentes...". Filas com mais de 500 atendimentos em
  poucos dias (padaria Balcão: 3 a 4 dias; clínica Exames: ~5 dias; Loja Centro: ~23 dias;
  cartório) mostram praticamente a mesma janela em 7 dias, 30 dias e Tudo. Para comparar períodos
  use a **ótica Loja Norte, Atendimento geral** (42, 156 e 342 atendimentos, todo o histórico cabe
  na janela) ou a Loja Centro (178 em 7 dias contra 500 em 30 dias e Tudo).
- Consequência para o **planejamento de equipe**: a sazonalidade exige 8 semanas completas dentro
  dos 500 mais recentes. Só filas com ~50 atendimentos por semana chegam lá: **Loja Norte** (cresce
  ~6 a 10% por semana) e **Loja Rua XV** (estável) têm histórico de ~100 dias e mostram as 8
  semanas. As filas densas (Centro, Exames, padaria) mostram poucas semanas ou "Dados
  insuficientes", e isso é o comportamento correto do app, não defeito do seed.
- Os números do seed variam com o "agora". O app usa o **relógio real** (a semana em andamento, o
  filtro 7/30 dias e a janela dos 500 mais recentes andam com o dia e a hora), e o seed é gerado
  para o instante em que roda. As tabelas "Resultado esperado" e o anexo foram gerados com
  `node functions/scripts/demo/expected.js --now 2026-11-25T15:00:00Z` (25/11/2026, 12:00 em São
  Paulo). Para ver os números do seu momento rode o mesmo comando sem `--now` (ou com
  `--now <ISO>` igual ao que passou ao `demo-up`; `--json` para a saída estruturada) e use o que o
  script imprime, não as tabelas deste arquivo. Espere variações de poucos pontos percentuais; os
  **padrões** (ordem dos atendentes, taxa crescente, horas do card, metas atingidas ou não,
  déficits nos picos, tendência e recorrência) são garantidos por `functions/test/demo-bi.test.js`
  em vários "agora". Para o seed e o script usarem o mesmo instante, passe o mesmo `--now` aos dois.

### Mapa: pedido do orientador, onde olhar

| Pedido | Onde na tela | Cenário |
| --- | --- | --- |
| Operadores com tempos médios diferentes | Por atendente (tabela, colunas Tempo médio e Desvio) | 1 |
| Ociosidade e ritmo por atendente | Por atendente (colunas Ociosidade e Atend./h) | 2 |
| Horários de maior concentração | "Picos de demanda"; gráfico por hora em Por atendente; barras em Desistências | 3 |
| Onde há mais desistência | Desistências: "Desistência por hora de chegada" | 4 |
| Espera maior x desistência | Desistências: "Taxa por faixa de espera" e ponto de inflexão | 5 |
| Estimativa mostrada x desistência | Desistências: "Taxa por estimativa mostrada" e precisão | 6 |
| Possível falta de capacidade | Desistências: card "Possível falta de capacidade" | 7 |
| Comparar períodos | Chips 7 dias, 30 dias, Tudo | 8 |
| Filtros e escopo | Seletor de escopo e "Filtrar por fila" | 9 |
| Simular atendimentos ao vivo | Web do cliente + painel da fila + Métricas | 10 |
| Definir ou editar a meta de uma fila | Configurações da fila > Metas de atendimento | 11 |
| Cumprimento das metas e períodos não atingidos | Métricas > Metas | 12 |
| Violação da meta ao vivo | Banner no painel, selo na home | 13 |
| Planejamento de equipe e sazonalidade | Métricas > Planejamento de equipe | 14 |
| O que muda ao trocar escopo e período | Seletor de escopo e chips de período | 15 |

### Cenário 1: operadores com tempos médios diferentes

1. Escopo "Fila: Atendimento geral" da **Loja Shopping Centro** (conta `otica@`), período **Tudo**.
2. Role até **Por atendente**. Ordene por "Tempo médio" (toque no cabeçalho da coluna).
3. Esperado: **Ana ~6,1 min (-46% vs média, posição 1)**, Bruno ~10,6 (-6%), Diego ~10,6 (-7%),
   **Carla ~16,0 (+41%, última)**. A coluna Desvio é "(média do atendente - média do escopo) ÷ média
   do escopo"; negativo é mais rápido.
4. Como explicar: o seed dá a cada pessoa um multiplicador sobre a mediana de serviço da fila
   (Ana 0,6x, Bruno 1,0x, Carla 1,5x, Diego 1,0x) com variação lognormal; a tabela recupera isso
   só olhando `calledAt` e `finishedAt` do histórico. Dados: `served`, `calledAt`, `finishedAt`,
   `calledBy`. Utilidade: treino, revisão do tempo médio configurado. Não mede qualidade
   (`docs/metricas-bi.md`, "Comparação entre atendentes").
5. Repita em **padaria `Balcão`** (Ana 3,3 / Bruno 5,4 / Diego 5,4 / Carla 8,3 min) e em
   **clínica `Exames`** (Ana 6,7 / Bruno 9,5 / Diego 11,4 / Carla 15,2): o mesmo "elenco" em três
   negócios, com os mesmos perfis.

### Cenário 2: ociosidade e atendimentos por hora

1. Mesma tela do cenário 1 (Loja Centro, Tudo). Olhe as colunas **Ociosidade** e **Atend./h**.
2. Esperado: **Diego ~16% de ociosidade** (entre ~15% e ~35%, depende da janela); Ana, Bruno e
   Carla ~0%. Em padaria Balcão Diego tem ~3% e em clínica Exames ~7% (as filas têm menos gente esperando nos horários dele, e a ociosidade
   só conta intervalo com cliente já na fila).
3. Como explicar: o seed faz Diego "sumir" 8 a 22 min depois da maioria dos atendimentos (café,
   celular). Se havia gente esperando, o intervalo entre o fim de um atendimento e a próxima chamada
   vira ociosidade (intervalos acima de 30 min contam como pausa, não ociosidade). Fila vazia não
   conta. Aproximação documentada em `docs/metricas-bi.md`, "Ociosidade".
4. **Atend./h** é atendidos ÷ horas da janela do dia (primeira chamada a último término). Pausas
   entram na janela; não é hora efetivamente trabalhada. O valor depende da escala de cada um
   (Bruno trabalha o dia todo, inclusive nas horas vazias, então aparece com ritmo menor).
5. Toque no filtro do gráfico ("atendimentos por hora ou turno", todos ou um atendente) e escolha
   Ana: vê em quais horas ela concentra o trabalho (a escala dela é 9-12 h e 14-16 h nessa fila).

### Cenário 3: horários de maior concentração

1. Escopo "Fila: Atendimento geral" da Loja Centro, **Tudo**.
2. **Picos de demanda** (pessoas que entraram por horário): concentração em **11-12 h e 17-18 h**
   (>85% das entradas). Na **clínica Exames** o pico é **7-9 h**; na **padaria Balcão**, 7-9 h e
   16-18 h.
3. Em **Desistências → "Desistência por hora de chegada"** as barras de contagem acompanham os
   mesmos horários. Sexta e sábado enchem mais: compare "Tendência diária" e use o chip
   Personalizado para escolher um sábado e uma terça.
4. Como explicar: chegadas Poisson por hora com pesos do perfil, mais rajadas às 12 h e 18 h na
   ótica Centro (almoço e saída do trabalho), multiplicadas por um fator de dia da semana
   (sexta 1,15 e sábado 1,5 na Loja Centro; terça a quinta ficam quase vazias, ~0,12 a 0,15, para
   que a meta de espera seja cumprida nesses dias e violada em sexta, sábado e segunda).

### Cenário 4: onde há mais desistência

1. Ótica Loja Centro, Atendimento geral, Tudo, seção **Desistências**.
2. **Desistência por hora de chegada**: maior taxa às **12 h (~51%)** e 18 h (~48%), depois 11 h
   (~26%) e 17 h (~24%); fora desses horários praticamente 0%. Compare com a **Loja Norte** (mesma
   rede, loja com poucas desistências): ~1% no total e no máximo ~5% em qualquer hora, sem
   horário crítico.
3. Compare lojas pelo seletor de escopo (Grupo: Loja Shopping Centro x Grupo: Loja Shopping Norte).
4. Como explicar: taxa = desistentes ÷ (atendidos + não compareceu + desistentes) por hora de
   chegada, ignorando remoções do sistema (expirada/fechada). Utilidade: achar o horário
   problemático. Cuidado: hora com menos de 5 pessoas não mostra taxa.

### Cenário 5: espera maior se associa a mais desistência

1. Mesma fila, seção **Taxa por faixa de espera**. As barras são "desistências a cada 10 min de
   espera, entre quem chegou a cada faixa".
2. Esperado (Tudo, Loja Centro): a **barra mostra a taxa por 10 min**: 0-5 min **~3%**, 5-10
   **~13%**, 10-20 **~15%**, 20-40 **~26%**, 40+ **~29%**. Em **clínica Exames**: 3%, 10%, 21%, 23%
   (40+ sem amostra). A taxa só cresce: quanto mais a pessoa espera, maior a chance de ir embora.
   Atenção: a tabela anterior deste roteiro trazia a proporção simples (desistentes ÷ em risco, ex.
   Loja Centro 2%, 7%, 15%, 52%), que **não é o que a tela mostra**: a tela divide pela largura da
   faixa (mínimo 5 min) e multiplica por 10 (`ratePer10Min`), para comparar faixas de larguras
   diferentes. As duas colunas estão no anexo.
3. O texto **Ponto de inflexão** diz a partir de qual faixa a desistência passa de 20% a cada 10
   min (Loja Centro: 20 min; Exames: 10 min; o limiar é estrito, 20%, e a taxa da faixa 20-40 min
   da Loja Centro fica perto de 25%). É o número para a "meta de espera máxima".
4. Como explicar: cada cliente tem uma paciência lognormal (mediana ~25 a 30 min, mais ~10% que
   desistem rápido). Se a espera prevista passa da paciência, ele sai no instante da paciência. A
   faixa é "condicional": só quem chegou nela entra no denominador. As faixas têm larguras
   diferentes, por isso a barra usa a taxa por 10 min. Limitação: quem ainda está na fila não
   aparece (censura à direita).

### Cenário 6: estimativa mostrada x desistência

1. Mesma fila, seção **Taxa por estimativa mostrada** (estimativa que o cliente viu ao entrar:
   (pessoas na frente + 1) × tempo médio configurado).
2. Esperado (Tudo, Loja Centro): estimativa 5-10 min **~0%**, 10-20 **~17%**, 20-40 **~40%**,
   40+ **~74%**. Clínica Exames: 0%, 15%, 31%, 61%. Estimativas altas desistem mais.
3. **Precisão da estimativa**: erro médio negativo (-9,5 min na Loja Centro, -9,8 em Exames):
   a estimativa superestima porque a conta supõe um único atendente e a fila tem vários. Dica de
   conversa: ajustar o tempo médio da fila (ou deixar o automático) reduz o erro.
4. Como explicar: o grupo é fixo no momento da entrada (proporção simples, sem condicional).
   Registros antigos sem `estimateMin` não aparecem; o seed grava `estimateMin` em todo o
   histórico de filas por ordem de chegada (não em hora marcada).

### Cenário 7: card "Possível falta de capacidade"

1. Escopo Loja Centro, Atendimento geral, Tudo → seção Desistências → card **Possível falta de
   capacidade**: aparece com as horas **12 e 18** (a 17 h entra em alguns "agora").
2. Em **clínica Exames** o card lista **7, 8 e 9**. Na **padaria Balcão** o card mostra "Nenhum
   horário crítico no período" (a espera média das horas 8 e 9 é de 8 a 9 min, abaixo do limiar de
   15). Na **Loja Norte** também não há horário crítico (contraste).
3. Regra (`capacitySignalHours`): hora com espera média **>= 15 min** e desistência **>= 20%**, ambas
   na hora de chegada, com pelo menos 5 pessoas na hora. Os dois critérios juntos evitam alarme
   falso (hora cheia mas rápida, ou desistência por outro motivo).
4. Por que acontece no seed: na Loja Centro só trabalham 2 pessoas às 12 h (Bruno e Diego, que
   pausa) e às 17-18 h (Bruno e Carla, a lenta), com rajada de 12 a 18 clientes; na clínica, só
   Bruno e Carla entre 7 e 9 h antes do reforço.

### Cenário 8: comparar períodos (7 dias x 30 dias x Tudo)

1. Escopo "Fila: Atendimento geral" da **Loja Shopping Norte**. Clique em **7 dias**, **30 dias** e
   **Tudo** e anote o card de resumo (Atendimentos) e a desistência.
2. Esperado: 7 dias **42** atendimentos, ~2,4% de desistência; 30 dias **156**, ~1,9%; Tudo
   **342** (todo o histórico de ~100 dias cabe nos 500), ~0,9%. A semana recente tem mais volume
   porque a demanda da Loja Norte cresce semana a semana (cenário 14).
3. Na **Loja Centro** o contraste aparece em 7 dias (~178 atendimentos, ~44% de desistência) x 30
   dias/Tudo (500, ~38%), porque os 500 mais recentes cobrem só ~23 dias. O aviso de histórico
   truncado explica por que 30 dias e Tudo coincidem.
4. Use **Personalizado** para duas semanas específicas e compare o "vs. período anterior" nos
   cards de resumo.

### Cenário 9: alterar filtros e escopo (fila, grupo)

1. Escopo "Todas as filas" da conta `otica@`: a visão "Por grupo" lista os 4 grupos
   (lojas) com atendimentos, espera, P90, no-show, nota e variação. Toque em "Loja Shopping
   Centro": o escopo vira o grupo e a página sobe.
2. No grupo, "Por atendente" soma as 5 filas da loja; use **Filtrar por fila** (dentro de Por
   atendente) para isolar "Atendimento geral". Ana, Bruno, Carla e Diego mudam de número porque
   atuam em filas diferentes (Ana: Atendimento geral, Exame e Retirada; Carla: Atendimento geral,
   Assistência e Lentes). A soma por fila bate com o total do grupo.
3. Escolha escopo "Fila: ..." e depois "Todas as filas": os números do escopo maior são a soma
   dos menores (exceto as médias, que são ponderadas pelas amostras).
4. Como explicar: todos os indicadores de BI recebem o mesmo conjunto filtrado por escopo e
   período (`filterByScope`), então a tabela e as barras sempre correspondem ao escopo selecionado.

### Cenário 10: simular atendimentos ao vivo

Pré-requisito: `ops/demo-up.sh` completo (fase 2 com functions), web local em
`http://localhost:5173` e o app em Chrome. Use a **padaria** (`padaria@`), fila **Balcão**, que
tem 6 esperando e 1 sendo chamado.

1. No app (`padaria@`): ícone Métricas → "Fila: Balcão" → período **Hoje**. Anote o card
   **Atendimentos** e a linha **Dono** em Por atendente (provavelmente ausente: a padaria só tem
   Ana, Bruno, Carla e Diego). Volte.
2. Em outra aba abra `http://localhost:5173/q/demo-padaria-balcao`. Preencha **Nome** (ex.:
   "Visitante Banca"), telefone opcional e toque em **Entrar na fila**. A tela mostra a senha e a
   posição (a 7ª da fila).
3. No app: home → fila **Balcão** (painel). O novo cliente aparece em "Aguardando". Toque em
   **Chamar próximo**; no cartão chamado toque em **Atendido** (aparece "Desfazer" por 5 s; espere
   passar para o registro ir ao histórico). Repita até atender "Visitante Banca" (ou toque em
   **Chamar agora** no cartão dele). Na aba web a senha muda para "É a sua vez".
4. Saia do painel e abra Métricas de novo (a tela carrega o histórico ao abrir): período **Hoje**,
   "Fila: Balcão". O card **Atendimentos** subiu de acordo com o número de atendidos e a linha
   **Dono** aparece em Por atendente com os atendimentos que você fez. Se quiser ver um nome
   próprio, entre em outro navegador com `operador1@` (Ana), abra a fila em "Sou operador" e repita
   o passo 3; Ana ganha +1 em Por atendente.
5. Para "desistência ao vivo": entre de novo pela web e, antes de ser chamado, toque em **Sair da
   fila** e confirme em **Confirmar saída**. Em
   Métricas o contador de desistências sobe (a saída vai para o histórico como `left`).
6. Observação: os indicadores novos (atendimento por atendente, desistência por faixa) mostram o
   atendimento recém-feito com tempo de serviço de poucos segundos. É esperado: ele só serve para
   ver o contador mudar; os padrões continuam vindo do histórico semeado.

### Cenário 11 (j): definir ou editar a meta de uma fila

Metas são opcionais por fila (`queues/{id}.goals`, só Firestore, só o dono escreve). O seed já
define metas nas filas-chave e deixa as demais sem meta, para mostrar os dois estados.

1. No app (`otica@`): home → seção **Loja Shopping Rua XV** → fila **Atendimento geral** → ícone de
   Configurações (engrenagem) no painel → tile **Metas de atendimento**. Está em **"Sem metas
   definidas"** (a Rua XV é a fila-chave sem meta; qualquer fila de clínica, cartório, barbearia e
   food truck também).
2. Toque no tile. No diálogo preencha **Espera máxima (min)** = 15, **Atendimento máximo (min)** =
   12 e deixe **Alvo de cumprimento (%)** em branco (placeholder "Padrão 80"). Salve. O tile passa
   para "Espera até 15 min", "Atendimento até 12 min", "alvo 80%".
3. Validação: reabra e digite 0 ou 241 em um tempo ("Informe de 1 a 240 minutos."), 40 no alvo
   ("Informe de 50 a 100%.") ou apague tudo ("Defina pelo menos uma meta: espera ou atendimento.").
   Para **editar**, mude a espera para 10 e salve; **Remover metas** apaga o campo e volta ao estado
   vazio.
4. Esperado: o documento `queues/demo-otica-ruaxv-atendimento` no Firestore ganha
   `goals = {maxWaitMin: 15, maxServiceMin: 12}` (+ `targetPct` só se você informou). Nada vai
   para o RTDB. Operador não vê o tile (só o dono).
5. Metas que o seed já grava (`goals` em `accounts.js`):

   | Fila | Meta (espera / atendimento / alvo) | O que a tela mostra (Tudo, 25/11/2026) |
   | --- | --- | --- |
   | Ótica Loja Centro, Atendimento geral | 15 min / 12 min / 80% | espera **45% não atingida**, atendimento **68% não atingida** |
   | Clínica Exames | 30 min / 18 min / 80% | espera **92% atingida** (a sexta falha), atendimento **88% atingida** |
   | Padaria Balcão | 25 min / 10 min / 80% | espera **99%** e atendimento **94%**, **atingidas folgadas** |
   | Ótica Loja Norte, Atendimento geral | 15 min / 15 min / 80% | espera **98%** e atendimento **95%**, **atingidas** |
   | Todas as demais (inclui Loja Rua XV) | sem meta | estado "Defina metas de atendimento" |

6. Como explicar: meta = tempo aceitável e a parte das pessoas que deve cumpri-lo (alvo 50 a
   100%, padrão 80). Uma fila "tem meta" quando define espera ou atendimento; o alvo sozinho não é
   meta. Definição e regras: `docs/metricas-bi.md`, grupo 3, "Metas por fila".

### Cenário 12 (k): cumprimento e períodos em que a meta não foi atingida

1. Métricas (`otica@`) → escopo **Fila: Atendimento geral** da Loja Shopping Centro → período
   **Tudo** → role até a seção **Metas** (logo antes de "Planejamento de equipe").
2. Esperado (Loja Centro, 25/11): cartão **Espera dentro da meta** com **45%** ("206 de 456 dentro do
   limite", alvo 80%, selo **Não atingida**); cartão **Atendimento dentro da meta** com **68%** (202
   de 297, **Não atingida**). O gráfico **Cumprimento por dia** mostra as barras de **sexta, sábado e
   segunda** abaixo da linha do alvo (20% a 50%) e as de terça a quinta no alvo. **Períodos em que a
   meta não foi atingida** lista ~10 dias de espera (sex 06/11, sáb 07/11, seg 09/11, sex 13/11,
   sáb 14/11...) e as horas **11, 12, 17 e 18 h** (a 12 h e a 18 h são as piores, ~30%); a fora de
   pico (9-10 h, 14-16 h) cumpre. **Maior violação de espera**: ~36 min acima da meta (21/11).
3. Contraste: **Padaria Balcão** (Atingida, 99%, nenhum período abaixo do alvo), **Loja Norte**
   (Atingida, 98%) e **clínica Exames** (Atingida, 92%; quando a janela de 500 inclui uma sexta
   aparece "sex 20/11: 73%" em Períodos, porque a Carla e o Diego não trabalham às sextas no seed e
   o Bruno fica sozinho no pico das 7 às 9 h).
4. Sem meta: escopo **Fila: Atendimento geral** da **Loja Rua XV** mostra a chamada **"Defina metas
   de atendimento"** (`goals-empty-cta`). No escopo **Grupo: Loja Shopping Centro** o contador diz
   "Meta de 1 fila no escopo": só filas com meta entram, e cada amostra usa a meta da própria fila.
5. Como explicar: espera = `calledAt - joinedAt` (e a saída, para quem desistiu); **quem desistiu
   com espera até a meta não conta** (não se sabe se seria atendido a tempo), quem desistiu depois
   dela conta como descumprimento. "Atingida" quando cumpriram ×100 >= alvo, sem arredondar; dia ou
   hora só entra em "não atingido" com 5 ou mais avaliados; com menos de 5 no total o selo some e
   aparece "Amostra pequena". Fórmulas: `docs/metricas-bi.md`, grupo 3, "Espera dentro da meta",
   "Atendimento dentro da meta" e "Períodos em que a meta não foi atingida". Cada cartão tem o
   botão "i" com o mesmo texto.
6. Atenção ao "agora": o app lê os 500 mais recentes, então Exames mostra ~5 dias e a Padaria 3 a 4;
   "dias específicos" só aparecem se a janela contiver uma sexta. Para ver a série longa de
   Exames use o script (`expected.js` imprime os dias não atingidos da janela) ou confirme no
   teste `demo-bi.test.js`, que mede o efeito da sexta no histórico inteiro.

### Cenário 13 (l): simular ao vivo a violação da meta de espera

Pré-requisito: `ops/demo-up.sh` completo, o app em Chrome e a web do cliente em
`http://localhost:5173`. Fila: **Loja Centro, Atendimento geral** (meta de espera 15 min, tempo
médio manual 6 min, automático ~9,6 min). Fora dos horários de pico (11-13 h e 17-19 h, fuso de
São Paulo) ela tem **1 esperando + 1 chamado**; em horário de pico pode já haver fila e o banner
já aparecer (use o horário de pico como ponto de partida alternativo).

1. Em `otica@`, abra a home e depois o painel da fila. Esperado: **sem banner** (estimativa =
   1 × 9,6 = ~10 min, abaixo de 15) e sem selo no card.
2. Entre na fila pela web do cliente: abra `http://localhost:5173/q/demo-otica-centro-atendimento`,
   informe nome (telefone opcional) e **Entrar na fila**. Cada janela anônima é um cliente e cada
   cliente só tem uma entrada ativa; para o segundo, terceiro... use outra janela anônima ou outro
   navegador (e telefones diferentes), ou, mais rápido, use **Adicionar pessoa** na barra do painel
   (entrada manual, até 30 por 10 min). Qualquer caminho serve: o painel só precisa ver a
   contagem de "Aguardando" subir.
3. Com **2 esperando** (estimativa 2 × 9,6 = ~19 min > 15) o painel mostra o banner **"Meta de
   espera em risco"** ("Com 2 na fila, a espera estimada é de 19 min, acima da meta de 15 min") e a
   sugestão "chame mais um atendente ou abra outro balcão". Volte à home: o **selo** "Meta de espera
   em risco" no card aparece só com **3 esperando**, porque a home usa o tempo **manual** (3 × 6 = 18
   > 15) e o painel usa o automático. Essa divergência é documentada (`docs/metricas-bi.md`,
   "Tempo real").
4. Chame e atenda pessoas até a estimativa voltar a 15 min ou menos: o banner some (a regra é
   "estritamente maior que a meta").
5. Já em risco no seed: **Padaria Balcão** (6 esperando × 6,2 = ~37 min, meta 25) e **clínica
   Exames** (5 × 12,2 = ~61 min, meta 30) mostram o banner no painel logo de início, sem selo na
   home (6 × 3 = 18 e 5 × 5 = 25 ficam dentro da meta). O histórico delas cumpre a meta (99% e 92%),
   mas a previsão ao vivo avisa: a conta é "esperando × tempo médio" e **não divide pelo número de
   atendentes**, por isso é conservadora quando há vários balcões.
6. Como explicar: o painel usa `waiting × (avgServiceMinAuto ?? avgServiceMin ?? 10)`, a mesma
   fórmula da regra de espera dos alertas. O único listener novo é o do tempo automático e só
   existe se a fila tem meta de espera. Fórmula e limites: `docs/metricas-bi.md`, grupo 3, "Tempo
   real: meta de espera em risco".

### Cenário 14 (m): planejamento de equipe (recomendado x observado x diferença)

1. Métricas (`otica@`) → escopo **Fila: Atendimento geral** da **Loja Shopping Rua XV**, período
   **Tudo** → seção **Planejamento de equipe**. É a fila feita para este cenário: ~50
   atendimentos por semana, 8 semanas completas dentro dos 500 mais recentes.
2. **Tempo médio de atendimento** ~7,3 min, **ocupação-alvo 85%**, **base** ~81 dias. A grade
   **Atendentes por dia e hora** tem os modos **Recomendado**, **Observado** e **Diferença**
   (chips). Esperado em Rua XV: **Recomendado 2** em **seg 12 h, sex 18 h e sáb 11 h** (cerca de 9
   chegadas por hora) e 1 nos demais horários com chegadas; **Observado 1,0** nesses três picos
   (só o dono: o Davi está fora das 11 às 13 h, depois das 18 h e aos sábados);
   **Diferença +1,0** (célula de "Falta") nos três picos e **negativa** (folga, ~-0,5 a -1) em
   **terça a quinta, 15-16 h**, onde há dois atendentes para 2 a 4 chegadas por hora.
3. **Maiores déficits** (até 5): em Rua XV são exatamente 3 ("seg 12 h: precisa de 2, tem 1,0";
   "sex 18 h"; "sáb 11 h"). Na **Loja Centro** são 5, todos em picos de fim de semana e segunda,
   ex. "sáb 12 h: precisa de 6, tem 2,3", "sáb 18 h: precisa de 5, tem 2,0", "sex 18 h: precisa de
   4, tem 2,0".
4. **Volume semanal e sazonalidade**: Rua XV, 8 semanas de ~36 a 48 chegadas, **"Volume estável"**
   (tendência perto de 0%); **Loja Norte**: 8 semanas (~24 → ~42), **"Tendência de alta: cerca de
   +6% a +10% por semana"** (o seed cresce 8% por semana, a regressão linear mede ~6 a 10%).
   **Padrão recorrente** nas duas: **seg 12 h, sex 18 h e sáb 11 h** "entre as mais cheias em 8 de 8
   semanas" (em Rua XV também ter 16 h em 6 de 8). Na **Loja Centro** (fila densa) só cabem ~3
   semanas na janela de 500, então a tendência é pouco confiável; em **Padaria Balcão** a tela diz
   **"Dados insuficientes: são necessárias pelo menos 3 semanas completas"**.
5. Como explicar: **recomendados = ceil(chegadas por hora × tempo médio ÷ 60 ÷ ocupação-alvo)**.
   Rua XV, seg 12 h: 9,0 × 7,3 ÷ 60 ÷ 0,85 = 1,29, logo **2**. **Observados** = média, por dia da
   semana e hora, de atendentes distintos com atendimento em andamento (o dono conta como um).
   **Diferença** = recomendados - observados (positivo falta gente, negativo sobra). A sazonalidade
   usa todo o histórico carregado do escopo (não o período escolhido), só semanas completas e
   termina na semana anterior à atual. Fórmulas: `docs/metricas-bi.md`, grupo 4. O botão "i" da
   grade muda de texto com o modo.
6. Uso: escalar o segundo atendente nos três picos recorrentes e tirar folga das tardes de terça a
   quinta. No seed isso é o que o desenho da escala (`staff` em `accounts.js`) cria de propósito.

### Cenário 15 (n): o que muda ao trocar escopo e período

1. **Período** (chips Hoje, 7 dias, 30 dias, Tudo, Personalizado): **Metas** e a **grade de
   equipe** passam a usar só os atendimentos do período. Loja Centro: espera dentro da meta **42%**
   em 7 dias (163 avaliados) contra **45%** em 30 dias e Tudo (456), atendimento 73% (96) contra
   68% (297). Em "Hoje" a amostra costuma ficar abaixo de 5 e o selo vira "Amostra pequena". Na
   grade, com 7 dias cada dia da semana ocorre uma vez, então "chegadas por hora" é a de
   **aquela semana**; com Tudo é a média por ocorrência do dia da semana. O card de **Volume semanal
   e sazonalidade ignora o período**: usa sempre as 8 semanas completas anteriores à semana atual.
2. **Escopo "Fila"**: só as metas e as chegadas daquela fila. **Grupo** (ex. Loja Shopping Centro):
   Metas soma só as filas do grupo que têm meta ("Meta de 1 fila no escopo") e o alvo mostrado é a
   média ponderada; a grade soma as chegadas das filas e conta atendentes distintos de todas elas.
   **Todas as filas** (`otica@`): Metas junta Centro e Norte (as duas com meta) e a sazonalidade
   junta o histórico de todas as filas (cada uma limitada a 500 documentos).
3. **Filtrar por fila** dentro de "Por atendente" **não** altera Metas nem Planejamento (só a
   tabela e o gráfico de atendentes).
4. Padaria e Exames: trocar entre 7 dias, 30 dias e Tudo quase não muda nada (janela de 500 de
   poucos dias); para ver mudança de período use Loja Norte (42 / 156 / 342) ou Loja Centro.
5. Como explicar: todos os indicadores recebem o mesmo conjunto filtrado por escopo e período
   (`filterByScope`, `filterHistory`), exceto a sazonalidade, que precisa de semanas inteiras.
   `docs/metricas-bi.md`, "Interface (MetricsScreen)".

### Resultado esperado

Valores-chave por fila de referência (período Tudo, como o app mostra, janela de 500), gerados
com `node functions/scripts/demo/expected.js --now 2026-11-25T15:00:00Z`. A saída completa, com as
faixas, os períodos, as metas e a equipe, está no anexo. **Na coluna de espera a tela mostra a taxa
por 10 min** (largura mínima 5 min, teto 100%), não a proporção simples; a proporção está no anexo
só para conferência. Os números mudam com a data (ver "Antes de começar").

| Fila | Atendentes (tempo médio, ociosidade) | Espera → desistência a cada 10 min (0-5, 5-10, 10-20, 20-40, 40+) | Estimativa → desistência (5-10, 10-20, 20-40, 40+) | Card de capacidade | 7 dias / 30 dias / Tudo (atendimentos) |
| --- | --- | --- | --- | --- | --- |
| Ótica Loja Centro, Atendimento geral | Ana 6,1 (0%), Bruno 10,6 (0%), Diego 10,6 (**16%**), Carla 16,0 (0%) | 3%, 13%, 15%, **26%**, 29% (inflexão em 20-40 min) | 0%, 17%, 40%, 74% | **12, 18 h** | 178 / 500 / 500 |
| Clínica Exames | Ana 6,7 (0%), Bruno 9,5 (1%), Diego 11,4 (**7%**), Carla 15,2 (1%) | 3%, 10%, **21%**, 23% (inflexão em 10 min) | 0%, 15%, 31%, 61% | **7, 8, 9 h** | 500 / 500 / 500 |
| Padaria Balcão | Ana 3,3, Bruno 5,4, Diego 5,4 (**3%**), Carla 8,3 | 1%, 7%, 16%, 7% (poucas amostras nas últimas) | 1%, 13%, 32%, sem amostra | nenhum | 500 / 500 / 500 |
| Ótica Loja Norte, Atendimento geral | dono 7,9 e Bruno 7,7 (1%) | 1%, 5%, 6% (sem amostra acima de 20 min) | 0%, 9%, 0%, sem amostra (poucas amostras) | nenhum | 42 / 156 / 342 |
| Ótica Loja Rua XV, Atendimento geral | dono 7,6 e Davi 6,4 | 1%, **31%**, **40%**, 12% (inflexão em 5 min) | 2%, 23%, 53%, 67% | nenhum (hora 11 em 7 e 30 dias) | 48 / 192 / 500 |

Metas e equipe (mesma data):

| Fila | Meta | Espera dentro da meta | Atendimento dentro da meta | Equipe e sazonalidade |
| --- | --- | --- | --- | --- |
| Ótica Loja Centro, Atendimento geral | 15 / 12 min, alvo 80% | **45%** (206 de 456), **não atingida**; 10 dias e as horas 11, 12, 17 e 18 h abaixo do alvo; maior violação +36 min | **68%**, **não atingida** | déficits em sáb 12 h (6 x 2,3), sáb 18 h (5 x 2,0), sex 18 h (4 x 2,0), seg 11 h e seg 17 h; 3 semanas (117, 160, 176) |
| Clínica Exames | 30 / 18 min, alvo 80% | **92%**, **atingida**; sex 20/11 abaixo do alvo (73%) | **88%**, atingida | sem sazonalidade útil (janela de ~5 dias) |
| Padaria Balcão | 25 / 10 min, alvo 80% | **99%**, **atingida folgada** | **94%**, atingida | "Dados insuficientes" (janela de 3 a 4 dias) |
| Ótica Loja Norte, Atendimento geral | 15 / 15 min, alvo 80% | **98%**, atingida | **95%**, atingida | sem déficit (2 atendentes); 8 semanas (24, 24, 20, 21, 25, 39, 39, 42), **+6% a +10% por semana**; recorrente seg 12 h, sex 18 h, sáb 11 h (8 de 8) |
| Ótica Loja Rua XV, Atendimento geral | sem meta | estado "Defina metas de atendimento" | idem | déficit **+1,0** em seg 12 h, sex 18 h, sáb 11 h; folga ter a qui 15-16 h; 8 semanas estáveis (~36 a 48); recorrente seg 12 h, sex 18 h, sáb 11 h (8 de 8) |

Faixas de tolerância para conferir sem ensaio: tempos médios dos atendentes ±1 min; ociosidade do
Diego na Loja Centro entre 10% e 35% (depende dos 500 mais recentes) e dos demais abaixo de 3%; taxa
por 10 min crescente nas quatro primeiras faixas em Exames e Loja Centro; card de capacidade da
Loja Centro sempre com as horas 12 e 18 (e às vezes 11 e 17); padaria e Loja Norte sem card na
série completa (a janela de 500 da padaria cobre 3 a 4 dias e, em dias de sábado/segunda, pode
mostrar o card nas horas 8 a 10: não é erro); Loja Centro com espera **não atingida** e sexta e
sábado abaixo do alvo; Exames, padaria e Norte com espera **atingida**; Rua XV com 3 déficits nos
picos recorrentes; Loja Norte com tendência de alta (5% a 11% por semana) e Rua XV estável (menos
de 5% em módulo).

### Perfis dos atendentes no seed (para explicar a modelagem)

| Pessoa | Multiplicador sobre a mediana de serviço | Comportamento |
| --- | --- | --- |
| Ana Lima (`operador1`) | 0,6x | Rápida; escala parcial nas filas de pico |
| Bruno Reis (`operador2`) | 1,0x | Médio; trabalha o dia todo |
| Carla Souza (`operador3`) | 1,5x | Lenta; cobre o fim da tarde |
| Diego Alves (`operador6`) | 1,0x | Após 90% dos atendimentos faz uma pausa de 8 a 22 min (`pause` em `accounts.js`) |

O código está em `functions/scripts/demo/` (`accounts.js` perfis, escalas e metas, `simulate.js`
paciência/pausas/rajadas, `bi.js` espelho em JS das fórmulas de `docs/metricas-bi.md` dos grupos 1 a
4, `expected.js` tabelas acima). O espelho `bi.js` só existe para teste e para o script; o cálculo
real está em `app/lib/services/abandonment_metrics.dart`, `attendant_metrics.dart`,
`goal_metrics.dart`, `goal_risk.dart` e `staffing_metrics.dart` (o Dart é a fonte da verdade).

## Roteiro: o que olhar em cada conta

"Agora" é a hora em que o seed roda; o histórico cobre os últimos 120 dias terminando agora.
Números abaixo são faixas esperadas (cada execução diverge um pouco com outro "agora").

1. **padaria@** (2 filas: Balcão, Encomendas). Métricas do Balcão: heatmap com picos 7-9 h e
   16-18 h, sábado e domingo acima dos dias úteis, ~+15% de demanda no último mês na tendência,
   no-show ~1,6%, ★ ~4,6, espera média ~3 min e atendimento ~5 min, meta de espera 25 min e de
   atendimento 10 min **atingidas folgadas** (e o banner de meta em risco já aparece no painel). Quatro atendentes com perfis
   distintos (Ana rápida, Bruno médio, Carla lenta, Diego ocioso); manhã com ~10-20% de desistência
   às 8-9 h (janela recente), tarde calma. Histórico passa de 500 docs (aviso de truncamento nas métricas). Painel ao
   vivo: ~6 esperando + 1 chamado, entrada manual no meio (selo de balcão), convite de operador
   válido, link curto e QR em `/n/paopquente`.
2. **clinica@** (4 filas em 2 grupos). Home agrupada (Unidade Centro: Consultas e Exames; Unidade
   Norte: Pediatria e Retirada de resultados). Consultas e Pediatria em hora marcada (slots de 30
   min, capacidade 2 e 1; o seletor de horário na web do cliente). No-show ~12-15%, pior às
   segundas e no primeiro horário, caindo nas últimas ~4 semanas (efeito dos "lembretes"). **Exames**
   é a fila de BI: pico das 7 às 9 h com ~30% de desistência, card de capacidade nas horas 7-9, os
   quatro perfis de atendente e **meta de espera de 30 min cumprida, exceto às sextas** (Carla e
   Diego não trabalham às sextas). Compare Ana (rápida) × Carla (lenta) nas filas do grupo.
   Pediatria **pausada** com mensagem e retorno em ~40 min, sem telefone no histórico
   (`anonymizePhone`). Retirada de resultados **fechada por horário** (`opensAt`). Alertas ligados
   (Exames tem `alertState` recente), expiração de 12 h em todas, convite expirado em Exames.
3. **barbearia@**. Hora marcada (20 horários, 1 por horário) + Fila de passagem. Atendimento
   25-45 min, sábado lotado (maior demanda e espera), recalls e skips ("Mover para o fim"
   e "Chamar de novo") no histórico, 2 barbeiros, ★ ~4,8.
4. **cartorio@** (6 filas em 2 grupos: Registro Civil, Notas e Protestos). Esperas longas
   (P90 acima de 60 min em Certidões, Casamentos e Reconhecimento de firma), atendimento com
   outliers, ★ ~3,4, demanda e tempo de atendimento **piorando** ao longo dos meses, 5
   operadores (Ana também atua em Certidões). **Reconhecimento de firma está cheia agora**
   (`maxWaiting 30` = 30 esperando: tente entrar em `/q/demo-cartorio-firma` e veja `queue-full`);
   Certidões tem limite 60 e 38 esperando, com alerta de espera alta ativo (`alertState.waitAt`
   recente). Operador4 e operador5 (pedido pendente para aprovar em Casamentos). Desistência alta
   (~29% em Firma, ~25% em Casamentos).
5. **foodtruck@** (1 fila, fechada agora). Só ~14 dias de histórico, concentrado em dois fins de
   semana (sex-dom) com rajadas de chegada e ~50% de desistência; no meio, dias sem dados. Serve
   para os estados de "poucos dados" nas métricas e tendências.
6. **otica@** (20 filas = o limite, 4 grupos de lojas). Home agrupada com 20 cartões; criar a 21ª
   fila mostra o gate do limite no wizard antes de pedir os passos. Histórico leve (30-100 dias),
   perfis variados (exame de vista em hora marcada, filas pausadas e fechadas, algumas com
   `maxWaiting`). **Loja Shopping Centro** é a loja de BI: o Atendimento geral tem picos às 12 h e
   18 h (e 11 h e 17 h), ~38% de desistência, card de capacidade, os quatro atendentes e **meta de
   espera violada nos picos e às sextas e sábados**; **Loja Norte** (Atendimento geral) cresce
   semana a semana com a meta cumprida; **Loja Rua XV** (Atendimento geral) é estável, sem meta e
   com déficit de atendentes nos picos recorrentes de segunda 12 h, sexta 18 h e sábado 11 h;
   Jardins e as demais filas servem de contraste (poucas desistências, só o dono atende).
7. **novo@** (sem filas). Onboarding, tour da primeira abertura e wizard de criação do zero.
8. **Operadores**: entre com `operador1@` e veja a seção "Sou operador" com filas de quatro
   estabelecimentos; `operador5@` mostra o pedido pendente; a produtividade por atendente aparece nas
   métricas do dono.

## Seed (CLI)

```bash
node functions/scripts/demo/index.js [--reset] [--days 120] [--seed qio-demo-v1] [--now ISO] [--only padaria,clinica] [--dry-run]
node functions/scripts/demo/expected.js [--now ISO] [--seed qio-demo-v1] [--days 120] [--json]
```

`--dry-run` não precisa de emulator: imprime a tabela de métricas por fila (atendimentos,
no-show %, desistência %, espera média/P90, ★, ao vivo). Sem `--dry-run` exige as três variáveis
de emulator. `expected.js` também não precisa de emulator: imprime os indicadores de BI das cinco
filas de referência (desistência, atendentes, metas, risco ao vivo, equipe e sazonalidade) com as
mesmas fórmulas do app (janela dos 500 mais recentes por fila, períodos 7/30/Tudo, o "agora" de
`--now`; sem ele, o relógio real).

- **Determinismo:** mesma `--seed` e mesmo `--now` geram os mesmos dados (PRNG mulberry32 com
  seed por fila). Por padrão `--now` é a hora atual.
- **Idempotente:** cada execução apaga os dados das filas e contas demo (lista de ids
  determinísticos `demo-*`, slugs e convites do universo) e regrava tudo; rodar duas vezes não
  duplica nada, mesmo em dias diferentes. `--reset` também varre qualquer id com prefixo `demo-`
  e qualquer conta `@qio.demo` que sobrou de versões antigas. Nenhum doc fora desse escopo é
  apagado.
- **Simulação** (`functions/scripts/demo/simulate.js`): chegadas Poisson por dia da semana e hora
  (e rajadas em horários fixos, `bursts.at`, ou por dia da semana, `bursts.byDow` com `offset`
  para não cruzar a hora cheia), servidores/operadores com produtividade distinta e
  escalas por turno (`staff.shifts`, `staff.days` e `staff.off({ daysAgo, dow })` para ausências
  em dias específicos), **pausas** (`staff.pause`: após o atendimento o servidor fica indisponível
  por X a Y min com probabilidade P), atendimento lognormal, desistência por **paciência**
  lognormal (mais uma fração `quickShare` que desiste logo), no-show por perfil/dia/tendência,
  re-chamadas e skips, nomes e telefones mascarados, feedback ★ correlacionado com a espera,
  horários (slots) com capacidade, entradas manuais, feriados fixos e dias fechados. A estimativa
  mostrada (`estimateMin`) é a de `joinEstimateMin` (pessoas na frente + 1 x tempo médio
  configurado). Empates de servidor livre vão para quem está parado há mais tempo. Reaproveita
  `estimate.js` (`avgServiceMinAuto`), `ticket.js` (`public/`) e `schedule.js` (`opensAt`).
- **Ao vivo:** o dia de hoje é simulado até agora; filas com `live` ganham uma janela de 40 min
  com entradas injetadas para garantir o estado esperado (ex.: 6 esperando na padaria) mesmo
  que o seed rode de madrugada. Filas fechadas/pausadas não recebem chegadas novas.
- Tickets reiniciam por dia só nas filas com `expiry.resetTicketDaily`; nas demais a senha
  continua crescendo, como na produção.
- Testes: `cd functions && npm test` (`test/demo-guard.test.js`, `test/demo-universe.test.js`,
  `test/demo-bi.test.js`; `DEMO_TEST_NOW=<ISO>` roda os mesmos invariantes com outro "agora").
  `demo-bi.test.js` calcula os indicadores direto no dataset com `scripts/demo/bi.js` (espelho das
  fórmulas de `docs/metricas-bi.md`) e exige: Ana < Bruno < Carla em tempo médio e Diego com a
  maior ociosidade (padaria, clínica, ótica), taxa de desistência crescente por faixa de espera e
  por estimativa, horas do card de capacidade (ótica Centro 12 e 17/18, Exames 8, sem card na
  padaria nem na loja tranquila), sazonalidade de sexta/sábado e determinismo. Para metas e
  equipe: `goals` válidos (faixas 1-240, 1-240 e 50-100) só nas filas-chave e filas sem meta; Centro
  não atinge a meta de espera (sexta, sábado e picos abaixo do alvo, terça a quinta e fora do pico
  no alvo) e a meta de atendimento é coerente com Ana (cumpre) e Carla (viola); Exames, padaria e Norte
  atingem; o banner de risco aparece ao somar uma pessoa na fila do Centro e o selo da home só com
  mais uma; 8 semanas na Norte (alta, +5% a +15% por semana) e na Rua XV (estável) com recorrência
  em seg 12 h, sex 18 h e sáb 11 h; déficit de 1 atendente nos picos da Rua XV e folga nas tardes de
  terça a quinta; e as fórmulas espelhadas do Dart (metas, grade de equipe, sazonalidade, taxa por
  10 min).

## Anexo: saída de `expected.js`

Gerado por `node functions/scripts/demo/expected.js --now 2026-11-25T15:00:00.000Z` (seed `qio-demo-v1`, 120 dias).

### Padaria, Balcão (manhã cheia, tarde calma)

`demo-padaria-balcao`: 19276 atendimentos no histórico (o app lê só os 500 mais recentes).

Por atendente (período Tudo, como o app mostra):

| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bruno | 208 | 5,4 | +2% | 5,8 | 0% |
| Ana | 136 | 3,3 | -38% | 4,4 | 0% |
| Carla | 77 | 8,3 | +58% | 2,6 | 0% |
| Diego | 56 | 5,4 | +3% | 2,7 | 3% |

Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:

| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |
| --- | ---: | ---: | ---: | ---: |
| 0-5 min | 500 | 2 | 1% | 0% |
| 5-10 min | 110 | 4 | 7% | 4% |
| 10-20 min | 49 | 8 | 16% | 16% |
| 20-40 min | 7 | 1 | 7% | 14% |
| 40+ min | 0 | 0 | — | — |

Desistência por estimativa mostrada (Tudo):

| Estimativa | Pessoas | Desistiram | Taxa |
| --- | ---: | ---: | ---: |
| 0-5 min | 342 | 0 | 0% |
| 5-10 min | 88 | 1 | 1% |
| 10-20 min | 45 | 6 | 13% |
| 20-40 min | 25 | 8 | 32% |
| 40+ min | 0 | 0 | — |

Ponto de inflexão: nenhum. Erro médio da estimativa: -2,7 min (absoluto 3,3). Card de capacidade (Tudo): não aparece.

Períodos (atendimentos no período / % desistência / card de capacidade):

| Período | Atendimentos | Desistência | Horas do card |
| --- | ---: | ---: | --- |
| 7 dias | 500 | 3,0% | — |
| 30 dias | 500 | 3,0% | — |
| Tudo | 500 | 3,0% | — |

Horas mais movimentadas (Tudo): 7 h (53, desist. 0%, espera 0,2 min); 8 h (52, desist. 0%, espera 1,9 min); 9 h (75, desist. 7%, espera 6,5 min); 12 h (59, desist. 0%, espera 1,3 min).

Metas (`goals` = {"maxWaitMin":25,"maxServiceMin":10,"targetPct":80}), período Tudo (500 mais recentes):

- Espera até 25 min, alvo 80%: **99%** (484 de 486), atingida; maior violação +2 min em 22/11. Dias não atingidos (0): nenhum. Horas não atingidas: nenhuma.
- Atendimento até 10 min, alvo 80%: **94%** (452 de 477), atingida; maior violação +7 min em 24/11. Dias não atingidos (0): nenhum. Horas não atingidas: nenhuma.

Metas por período (espera / atendimento, % dentro do limite):

| Período | Espera | Atendimento |
| --- | --- | --- |
| 7 dias | 99% (486) atingida | 94% (477) atingida |
| 30 dias | 99% (486) atingida | 94% (477) atingida |
| Tudo | 99% (486) atingida | 94% (477) atingida |

Meta de espera ao vivo: 6 esperando, estimativa do painel 37 min (6,2 min automático, 3 min manual), meta 25 min: banner APARECE; selo da home (só tempo manual) 18 min: não aparece. Faltam 0 entrada(s) para o banner e 3 para o selo (com o tempo de hoje).

### Clínica, Exames (pico das 7 às 9 h)

`demo-clinica-exames`: 10924 atendimentos no histórico (o app lê só os 500 mais recentes).

Por atendente (período Tudo, como o app mostra):

| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bruno | 155 | 9,5 | -12% | 4,4 | 1% |
| Carla | 70 | 15,2 | +42% | 3,4 | 1% |
| Diego | 39 | 11,4 | +6% | 2,1 | 7% |
| Ana | 37 | 6,7 | -38% | 3,2 | 0% |

Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:

| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |
| --- | ---: | ---: | ---: | ---: |
| 0-5 min | 499 | 8 | 3% | 2% |
| 5-10 min | 361 | 18 | 10% | 5% |
| 10-20 min | 311 | 66 | 21% | 21% |
| 20-40 min | 143 | 66 | 23% | 46% |
| 40+ min | 2 | 0 | — | — |

Desistência por estimativa mostrada (Tudo):

| Estimativa | Pessoas | Desistiram | Taxa |
| --- | ---: | ---: | ---: |
| 0-5 min | 0 | 0 | — |
| 5-10 min | 125 | 0 | 0% |
| 10-20 min | 71 | 11 | 15% |
| 20-40 min | 129 | 40 | 31% |
| 40+ min | 174 | 107 | 61% |

Ponto de inflexão: faixa a partir de 10 min. Erro médio da estimativa: -9,8 min (absoluto 10,7). Card de capacidade (Tudo): horas 7, 8, 9.

Períodos (atendimentos no período / % desistência / card de capacidade):

| Período | Atendimentos | Desistência | Horas do card |
| --- | ---: | ---: | --- |
| 7 dias | 500 | 31,6% | 7, 8, 9 |
| 30 dias | 500 | 31,6% | 7, 8, 9 |
| Tudo | 500 | 31,6% | 7, 8, 9 |

Horas mais movimentadas (Tudo): 7 h (117, desist. 38%, espera 17,4 min); 8 h (113, desist. 52%, espera 19,7 min); 9 h (97, desist. 35%, espera 15,9 min); 10 h (54, desist. 26%, espera 12,8 min).

Metas (`goals` = {"maxWaitMin":30,"maxServiceMin":18,"targetPct":80}), período Tudo (500 mais recentes):

- Espera até 30 min, alvo 80%: **92%** (326 de 354), atingida; maior violação +20 min em 25/11. Dias não atingidos (1): sex 20/11 (73%, 75). Horas não atingidas: nenhuma.
- Atendimento até 18 min, alvo 80%: **88%** (267 de 301), atingida; maior violação +51 min em 24/11. Dias não atingidos (0): nenhum. Horas não atingidas: 12 h (78%, 14).

Metas por período (espera / atendimento, % dentro do limite):

| Período | Espera | Atendimento |
| --- | --- | --- |
| 7 dias | 92% (354) atingida | 88% (301) atingida |
| 30 dias | 92% (354) atingida | 88% (301) atingida |
| Tudo | 92% (354) atingida | 88% (301) atingida |

Meta de espera ao vivo: 5 esperando, estimativa do painel 61 min (12,2 min automático, 5 min manual), meta 30 min: banner APARECE; selo da home (só tempo manual) 25 min: não aparece. Faltam 0 entrada(s) para o banner e 2 para o selo (com o tempo de hoje).

### Ótica Loja Centro, Atendimento geral (picos 11-13 h e 17-19 h)

`demo-otica-centro-atendimento`: 1200 atendimentos no histórico (o app lê só os 500 mais recentes).

Por atendente (período Tudo, como o app mostra):

| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |
| --- | ---: | ---: | ---: | ---: | ---: |
| Bruno | 159 | 10,6 | -6% | 1,6 | 0% |
| Carla | 63 | 16,0 | +41% | 2,9 | 0% |
| Diego | 46 | 10,6 | -7% | 1,8 | 16% |
| Ana | 29 | 6,1 | -46% | 0,8 | 0% |

Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:

| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |
| --- | ---: | ---: | ---: | ---: |
| 0-5 min | 500 | 8 | 3% | 2% |
| 5-10 min | 320 | 21 | 13% | 7% |
| 10-20 min | 280 | 43 | 15% | 15% |
| 20-40 min | 206 | 108 | 26% | 52% |
| 40+ min | 27 | 9 | 29% | 33% |

Desistência por estimativa mostrada (Tudo):

| Estimativa | Pessoas | Desistiram | Taxa |
| --- | ---: | ---: | ---: |
| 0-5 min | 0 | 0 | — |
| 5-10 min | 182 | 0 | 0% |
| 10-20 min | 42 | 7 | 17% |
| 20-40 min | 65 | 26 | 40% |
| 40+ min | 211 | 156 | 74% |

Ponto de inflexão: faixa a partir de 20 min. Erro médio da estimativa: -9,5 min (absoluto 10,3). Card de capacidade (Tudo): horas 12, 18.

Períodos (atendimentos no período / % desistência / card de capacidade):

| Período | Atendimentos | Desistência | Horas do card |
| --- | ---: | ---: | --- |
| 7 dias | 178 | 43,8% | 12, 18 |
| 30 dias | 500 | 37,8% | 12, 18 |
| Tudo | 500 | 37,8% | 12, 18 |

Horas mais movimentadas (Tudo): 11 h (73, desist. 26%, espera 13,6 min); 12 h (151, desist. 51%, espera 18,7 min); 17 h (82, desist. 24%, espera 11,3 min); 18 h (153, desist. 48%, espera 19,1 min).

Metas (`goals` = {"maxWaitMin":15,"maxServiceMin":12,"targetPct":80}), período Tudo (500 mais recentes):

- Espera até 15 min, alvo 80%: **45%** (206 de 456), não atingida; maior violação +36 min em 21/11. Dias não atingidos (10): sex 06/11 (46%, 39), sáb 07/11 (47%, 44), dom 08/11 (53%, 13), seg 09/11 (46%, 30), sex 13/11 (36%, 46), sáb 14/11 (29%, 54), seg 16/11 (36%, 38), sex 20/11 (38%, 44), sáb 21/11 (26%, 63), seg 23/11 (47%, 38). Horas não atingidas: 11 h (55%, 69), 12 h (29%, 139), 17 h (56%, 76), 18 h (32%, 131).
- Atendimento até 12 min, alvo 80%: **68%** (202 de 297), não atingida; maior violação +59 min em 23/11. Dias não atingidos (13): qua 04/11 (60%, 5), sex 06/11 (78%, 28), sáb 07/11 (61%, 31), dom 08/11 (60%, 10), seg 09/11 (66%, 18), sex 13/11 (58%, 29), sáb 14/11 (74%, 31), seg 16/11 (57%, 26), ter 17/11 (50%, 6), qua 18/11 (66%, 6), sex 20/11 (73%, 26), sáb 21/11 (72%, 29), seg 23/11 (70%, 24). Horas não atingidas: 12 h (69%, 82), 15 h (77%, 9), 17 h (55%, 36), 18 h (57%, 88), 19 h (63%, 11).

Metas por período (espera / atendimento, % dentro do limite):

| Período | Espera | Atendimento |
| --- | --- | --- |
| 7 dias | 42% (163) não atingida | 73% (96) não atingida |
| 30 dias | 45% (456) não atingida | 68% (297) não atingida |
| Tudo | 45% (456) não atingida | 68% (297) não atingida |

Meta de espera ao vivo: 1 esperando, estimativa do painel 10 min (9,6 min automático, 6 min manual), meta 15 min: banner não aparece; selo da home (só tempo manual) 6 min: não aparece. Faltam 1 entrada(s) para o banner e 2 para o selo (com o tempo de hoje).

Planejamento de equipe (tempo médio 11,3 min, ocupação-alvo 85%, 23 dias de base):

- Déficit 1: sáb 12 h, precisa de 6, tem 2,3 (25,3 chegadas/h).
- Déficit 2: sáb 18 h, precisa de 5, tem 2,0 (22,3 chegadas/h).
- Déficit 3: sex 18 h, precisa de 4, tem 2,0 (14,7 chegadas/h).
- Déficit 4: seg 11 h, precisa de 3, tem 2,0 (10,0 chegadas/h).
- Déficit 5: seg 17 h, precisa de 3, tem 2,0 (9,3 chegadas/h).
- Folga (diferença <= -0,25): sáb 11 h (precisa 1, tem 2,7); qui 12 h (precisa 1, tem 2,3); qui 18 h (precisa 1, tem 2,0).
- Sazonalidade (semanas completas, mais antiga primeiro): 117, 160, 176; tendência +19,5%/semana (crescendo).
- Padrão recorrente: sáb 12 h (3/3).

### Ótica Loja Norte, Atendimento geral (crescimento semanal)

`demo-otica-norte-atendimento`: 342 atendimentos no histórico.

Por atendente (período Tudo, como o app mostra):

| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |
| --- | ---: | ---: | ---: | ---: | ---: |
| Dono | 185 | 7,9 | +1% | 2,6 | 0% |
| Bruno | 153 | 7,7 | -2% | 3,1 | 1% |

Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:

| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |
| --- | ---: | ---: | ---: | ---: |
| 0-5 min | 342 | 1 | 1% | 0% |
| 5-10 min | 41 | 1 | 5% | 2% |
| 10-20 min | 18 | 1 | 6% | 6% |
| 20-40 min | 0 | 0 | — | — |
| 40+ min | 0 | 0 | — | — |

Desistência por estimativa mostrada (Tudo):

| Estimativa | Pessoas | Desistiram | Taxa |
| --- | ---: | ---: | ---: |
| 0-5 min | 0 | 0 | — |
| 5-10 min | 300 | 1 | 0% |
| 10-20 min | 23 | 2 | 9% |
| 20-40 min | 19 | 0 | 0% |
| 40+ min | 0 | 0 | — |

Ponto de inflexão: nenhum. Erro médio da estimativa: -7,0 min (absoluto 7,2). Card de capacidade (Tudo): não aparece.

Períodos (atendimentos no período / % desistência / card de capacidade):

| Período | Atendimentos | Desistência | Horas do card |
| --- | ---: | ---: | --- |
| 7 dias | 42 | 2,4% | — |
| 30 dias | 156 | 1,9% | — |
| Tudo | 342 | 0,9% | — |

Horas mais movimentadas (Tudo): 12 h (62, desist. 0%, espera 2,6 min); 15 h (84, desist. 0%, espera 0,5 min); 16 h (77, desist. 0%, espera 0,1 min); 18 h (60, desist. 5%, espera 2,4 min).

Metas (`goals` = {"maxWaitMin":15,"maxServiceMin":15,"targetPct":80}), período Tudo (500 mais recentes):

- Espera até 15 min, alvo 80%: **98%** (335 de 339), atingida; maior violação +4 min em 25/09. Dias não atingidos (0): nenhum. Horas não atingidas: nenhuma.
- Atendimento até 15 min, alvo 80%: **95%** (323 de 338), atingida; maior violação +8 min em 10/10. Dias não atingidos (0): nenhum. Horas não atingidas: nenhuma.

Metas por período (espera / atendimento, % dentro do limite):

| Período | Espera | Atendimento |
| --- | --- | --- |
| 7 dias | 100% (41) atingida | 100% (41) atingida |
| 30 dias | 98% (153) atingida | 96% (152) atingida |
| Tudo | 98% (339) atingida | 95% (338) atingida |

Meta de espera ao vivo: 0 esperando, estimativa do painel 0 min (7,2 min automático, 7 min manual), meta 15 min: banner não aparece; selo da home (só tempo manual) 0 min: não aparece. Faltam 3 entrada(s) para o banner e 3 para o selo (com o tempo de hoje).

Planejamento de equipe (tempo médio 7,8 min, ocupação-alvo 85%, 100 dias de base):

- Maiores déficits: nenhum.
- Folga (diferença <= -0,25): seg 12 h (precisa 1, tem 2,0); sex 18 h (precisa 1, tem 2,0); sáb 11 h (precisa 1, tem 2,0).
- Sazonalidade (semanas completas, mais antiga primeiro): 24, 24, 20, 21, 25, 39, 39, 42; tendência +10,7%/semana (crescendo).
- Padrão recorrente: seg 12 h (8/8), sex 18 h (8/8), sáb 11 h (8/8).

### Ótica Loja Rua XV, Atendimento geral (estável, déficit nos picos)

`demo-otica-ruaxv-atendimento`: 648 atendimentos no histórico (o app lê só os 500 mais recentes).

Por atendente (período Tudo, como o app mostra):

| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |
| --- | ---: | ---: | ---: | ---: | ---: |
| Dono | 272 | 7,6 | +4% | 4,7 | 1% |
| Davi | 84 | 6,4 | -13% | 2,9 | 0% |

Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:

| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |
| --- | ---: | ---: | ---: | ---: |
| 0-5 min | 500 | 2 | 1% | 0% |
| 5-10 min | 263 | 41 | 31% | 16% |
| 10-20 min | 191 | 76 | 40% | 40% |
| 20-40 min | 43 | 10 | 12% | 23% |
| 40+ min | 0 | 0 | — | — |

Desistência por estimativa mostrada (Tudo):

| Estimativa | Pessoas | Desistiram | Taxa |
| --- | ---: | ---: | ---: |
| 0-5 min | 0 | 0 | — |
| 5-10 min | 258 | 4 | 2% |
| 10-20 min | 39 | 9 | 23% |
| 20-40 min | 146 | 78 | 53% |
| 40+ min | 57 | 38 | 67% |

Ponto de inflexão: faixa a partir de 5 min. Erro médio da estimativa: -7,4 min (absoluto 7,9). Card de capacidade (Tudo): não aparece.

Períodos (atendimentos no período / % desistência / card de capacidade):

| Período | Atendimentos | Desistência | Horas do card |
| --- | ---: | ---: | --- |
| 7 dias | 48 | 25,0% | 11 |
| 30 dias | 192 | 22,9% | 11 |
| Tudo | 500 | 25,8% | — |

Horas mais movimentadas (Tudo): 11 h (101, desist. 40%, espera 13,2 min); 12 h (108, desist. 45%, espera 12,2 min); 16 h (105, desist. 0%, espera 0,4 min); 18 h (99, desist. 40%, espera 11,8 min).

Metas: sem meta configurada (a tela mostra o estado "configure").

Planejamento de equipe (tempo médio 7,3 min, ocupação-alvo 85%, 81 dias de base):

- Déficit 1: seg 12 h, precisa de 2, tem 1,0 (9,0 chegadas/h).
- Déficit 2: sex 18 h, precisa de 2, tem 1,0 (9,0 chegadas/h).
- Déficit 3: sáb 11 h, precisa de 2, tem 1,0 (8,4 chegadas/h).
- Folga (diferença <= -0,25): ter 16 h (precisa 1, tem 2,0); qua 15 h (precisa 1, tem 1,6); qui 16 h (precisa 1, tem 1,6).
- Sazonalidade (semanas completas, mais antiga primeiro): 48, 44, 36, 41, 44, 44, 41, 45; tendência -0,2%/semana (estável).
- Padrão recorrente: seg 12 h (8/8), sex 18 h (8/8), sáb 11 h (8/8), ter 16 h (6/8).
