# Indicadores de BI (grupos 1 a 4: lógica pura e interface)

Todos os indicadores abaixo são calculados no app a partir do `history` do Firestore
(`HistoryEntry`), sem telefone e sem PII. Horas e dias seguem `America/Sao_Paulo`
(UTC-3 fixo, `app/lib/services/sp_time.dart`). Código em
`app/lib/services/attendant_metrics.dart`, `abandonment_metrics.dart`, `goal_metrics.dart`,
`goal_risk.dart` e `staffing_metrics.dart`; testes em `app/test/services/`.

Convenções comuns:

- Atendente = `calledBy`, senão `operatorId`; o dono (e `null`) caem no mesmo balde,
  como em `computeOperatorMetrics`.
- Tempo de atendimento = `finishedAt - calledAt`; espera = `calledAt - joinedAt`.
- `left` com `reason` `expired` ou `closed` (remoção pelo sistema) nunca entra nos
  indicadores de desistência (`HistoryEntry.isSystemRemoved`).
- Fuso: as métricas novas usam UTC-3 fixo, então o resultado não depende do aparelho
  (há teste na virada do dia com horários locais e UTC). `queue_analytics.dart`
  (`hourlyDistribution`, matriz de demanda) usa o fuso do aparelho; em aparelho fora de
  UTC-3 as horas dos dois podem divergir.
- Censura à direita: o `history` só guarda quem já terminou. Quem ainda está na fila não
  aparece, então esperas longas em andamento ficam sub-representadas (a desistência e a
  espera dos períodos mais recentes tendem a parecer menores do que serão).
- Amostra mínima: abaixo do mínimo o indicador é `null` (não zero).
- Entradas com `joinedAt` na época 0 (documento sem data) são descartadas por todos os
  indicadores que dependem da entrada na fila: desistência, estimativa, precisão e
  ociosidade.
- Os textos de ajuda da interface (botão "i") recebem os limites (amostra mínima, 20%,
  15 min, 30 min etc.) como parâmetros a partir das constantes do código, e um teste falha se
  as constantes e os textos divergirem.

## Grupo 1: desempenho de atendentes

### Vazão por atendente (hora, dia e turno)

- **O que é:** quantos atendimentos cada atendente concluiu, distribuídos por hora do
  dia (0-23), por dia e por turno (manhã 6-12, tarde 12-18, noite 18-6).
- **Como é calculado:** conta de `served` agrupada pelo instante `finishedAt` (ou
  `calledAt` se faltar) convertido para São Paulo. `no_show` e `left` não contam.
- **Dados usados:** `result`, `finishedAt`, `calledAt`, `calledBy`/`operatorId`.
- **Para que serve:** ver em que horários e turnos cada pessoa concentra o trabalho e
  dimensionar escala.
- **Função:** `computeOperatorThroughput`.

### Atendimentos por janela de atuação

- **O que é:** ritmo do atendente dentro da janela em que atuou no dia. Não é "hora
  efetivamente trabalhada": pausas, almoço e intervalos entre atendimentos entram na
  janela.
- **Como é calculado:** por atendente e por dia (dia do `calledAt`), `served / horas`,
  onde horas = último `finishedAt` menos primeiro `calledAt` do dia (`windowHours`).
  A janela considera `served` e `no_show`; só `served` entra no numerador. O dia só vale
  com pelo menos `minSamples` atendimentos (padrão 3) **e** janela de pelo menos
  `minWindowMin` minutos (padrão 30), para não inflar o ritmo com janelas curtas. O
  agregado do atendente soma os atendimentos e as horas dos dias válidos.
- **Atenção:** `OperatorRate.served` exclui os dias com poucas amostras ou janela
  curta, então pode ser menor que `OperatorThroughput.total` (que conta todos os
  `served`). Os dois não devem ser somados nem comparados diretamente.
- **Dados usados:** `calledAt`, `finishedAt`, `result`, atendente.
- **Para que serve:** comparar produtividade sem o viés de quem trabalhou poucas horas.
- **Função:** `computeOperatorRates`.

### Ociosidade

- **O que é:** tempo em que o atendente ficou parado havendo gente esperando.
- **Como é calculado:** por atendente, ordenam-se os atendimentos do dia por
  `calledAt`. Para cada atendimento, o gap é
  `próximo.calledAt - maiorFinishedAt`, onde `maiorFinishedAt` é o maior `finishedAt`
  acumulado dos atendimentos anteriores (assim atendimentos sobrepostos não geram gap
  falso). Se o próximo foi chamado antes disso, não há gap. O gap conta se: for maior que zero; for
  menor ou igual a `idleCapMin` (padrão 30 min; acima disso presume-se pausa, não
  ociosidade); ambos caírem no mesmo dia de São Paulo; e `próximo.joinedAt <=
  maiorFinishedAt` (o próximo já estava na fila quando o atendente liberou, ou seja,
  havia alguém esperando). Resultado: `idleMin` (soma dos gaps), `gaps`
  (quantidade), `observedMin` (soma, por dia, do intervalo primeiro `calledAt` a
  último `finishedAt`) e `idlePct = idleMin / observedMin` (`null` se
  `observedMin == 0`).
- **Aproximação:** o history não guarda o tamanho da fila em cada instante, então
  "havia fila" é inferido pelo próximo atendido. Se a fila esvaziou e outra pessoa
  chegou depois, o gap não conta (correto); se havia fila mas o atendente chamou
  alguém de dentro dela mais tarde, conta (correto); períodos em que a fila existia
  mas o atendente nunca atendeu depois não aparecem.
- **Dados usados:** `joinedAt`, `calledAt`, `finishedAt`, atendente.
- **Para que serve:** achar tempo perdido entre atendimentos (troca lenta, distração)
  separado de fila vazia.
- **Função:** `computeOperatorIdle`.

### Comparação entre atendentes

- **O que é:** desvio do tempo médio de atendimento de cada atendente contra a média
  do escopo, mais ranking.
- **Como é calculado:** reaproveita `OperatorStats` (`computeOperatorMetrics`). Só
  atendentes com `avgServiceMin != null` e `serviceSamples >= minSamples` (padrão
  `minServiceSamples` = 3) participam. Média do escopo = média ponderada pelas
  amostras (equivale à média de todos os atendimentos válidos). `deviationPct =
  (média do atendente - média do escopo) / média do escopo * 100` (negativo = mais
  rápido). Ranking: 1 = menor tempo médio; empate desempata por volume maior e depois
  pelo id. Quem não atinge a amostra mínima fica sem desvio e sem posição.
- **Dados usados:** `service` dos `served`, atendente.
- **Para que serve:** identificar quem destoa do padrão, para treino ou revisão do
  tempo médio da fila. Não é medida de qualidade (um atendimento mais longo pode ser
  mais complexo).
- **Função:** `compareOperators`.

## Grupo 2: abandono

### Taxa de desistência por faixa de espera

- **O que é:** de quem esperou pelo menos até certo ponto, que fração desistiu
  naquela faixa.
- **Como é calculado:** a espera de cada pessoa é `wait` para `served`/`no_show` e
  `finishedAt - joinedAt` para `left`. Entradas com `joinedAt` na época 0, espera
  negativa ou maior que 24 h são descartadas. Faixas padrão `[0,5)`, `[5,10)`,
  `[10,20)`, `[20,40)`, `[40,∞)` minutos (configuráveis por `edges`, que devem ser
  positivas e estritamente crescentes; há `assert`). Para cada faixa com início `s` e
  fim `e`:
  - em risco = pessoas (de qualquer resultado) que **atingiram** a faixa, isto é, com
    espera `>= s`. Isso inclui quem esperou além do fim `e` (atendido ou desistente
    mais tarde): essa pessoa passou pela faixa inteira;
  - desistentes = `left` com `s <= espera < e`;
  - `rate = desistentes / em risco`;
  - `hazardPerMin = rate / largura`, onde largura = `e - s`; na faixa aberta usa-se a
    maior espera observada menos `s`. A largura usada no divisor nunca é menor que
    `minBandWidthMin` (5 min): sem isso, 5 pessoas entre 40,0 e 40,5 min dariam 20 vezes
    a taxa real. `ratePer10Min = hazardPerMin * 10` é limitado a 100% (a taxa por 10 min é
    uma taxa de risco, não uma probabilidade, e pode passar de 1 em faixa curta).
  É uma taxa condicional: quem atendeu ou desistiu antes da faixa sai do denominador.
  Faixa com menos de `minSamples` em risco (padrão 5) fica com `rate` e
  `hazardPerMin` `null`.
- **Dados usados:** `result`, `joinedAt`, `calledAt`, `finishedAt`, `reason`.
- **Para que serve:** mostrar a partir de que espera o cliente começa a ir embora.
- **Limitação:** as faixas têm larguras diferentes (5, 5, 10, 20 min e aberta); a
  proporção `rate` de uma faixa larga é naturalmente maior que a de uma estreita.
  Por isso a comparação justa é `hazardPerMin` (ou `ratePer10Min`, que é
  `hazardPerMin * 10`). Ainda é uma aproximação: supõe risco constante dentro da faixa
  e, na faixa aberta, a largura depende da maior espera observada. `no_show` conta a
  espera até ser chamado; o desistente é medido pelo instante da saída.
- **Função:** `abandonmentByWait`.

### Ponto de inflexão

- **O que é:** a primeira faixa em que a desistência passa do tolerável.
- **Como é calculado:** primeira faixa, em ordem crescente, com `ratePer10Min >
  limiar` (padrão 0,20, isto é, mais de 20% de desistência a cada 10 minutos;
  comparação estrita). Usa-se a taxa por 10 minutos, e não a proporção `rate`, para que
  faixas de larguras diferentes sejam comparáveis (a faixa de 5 min com 2 de 15 em
  risco, `rate` 13%, equivale a 27% por 10 min e passa; a de 10 min com 2 de 9, `rate`
  22%, equivale a 22% por 10 min). Faixas sem taxa (amostra insuficiente) são puladas.
  `null` se nenhuma passar. A limitação de largura da faixa aberta vale aqui também.
- **Dados usados:** saída de `abandonmentByWait`.
- **Para que serve:** definir a meta de espera máxima e o texto de aviso ao cliente.
- **Função:** `findInflection`.

### Desistência por hora do dia

- **O que é:** taxa e contagem de desistências por hora de chegada.
- **Como é calculado:** agrupa por hora (São Paulo) de `joinedAt`. `total` = served +
  no_show + left (sem remoções do sistema), `left` = desistentes, `taxa = left /
  total` (`null` se `total < minSamples`, padrão 5), e `avgWaitMin` = espera média do
  grupo (a mesma espera da faixa, incluindo a dos que desistiram).
- **Dados usados:** `joinedAt`, `result`, espera, `reason`.
- **Para que serve:** localizar os horários de pico problemáticos.
- **Função:** `abandonmentByHour`.

### Sinal de capacidade

- **O que é:** horas em que a fila parece subdimensionada.
- **Como é calculado:** horas com `avgWaitMin >= waitThresholdMin` (padrão 15) **e**
  `taxa >= limiar` (padrão 0,20). Horas sem taxa (amostra insuficiente) não entram.
  Retorna a lista de horas.
- **Dados usados:** saída de `abandonmentByHour`.
- **Para que serve:** indicar onde reforçar atendentes ou ajustar horários.
- **Função:** `capacitySignalHours`.

### Desistência por estimativa mostrada

- **O que é:** a taxa de desistência separada pela estimativa de espera que o cliente viu
  ao entrar na fila (`HistoryEntry.estimateMin`, em minutos).
- **Como é calculado:** agrupa em faixas `[0,5)`, `[5,10)`, `[10,20)`, `[20,40)` e
  `[40,∞)` min (configuráveis por `edges`, positivas e estritamente crescentes). Em cada
  faixa, `total` = served + no_show + left com `estimateMin` naquela faixa e `rate = left
  / total`; abaixo de `minSamples` (padrão 5) a taxa é `null`. Entradas sem `estimateMin`
  (ou negativo) e remoções do sistema (`expired`/`closed`) ficam de fora. Diferente da
  desistência por faixa de espera, aqui não há condicional de "quem chegou à faixa": o
  grupo é fixo no momento da entrada, então a taxa é a proporção simples.
- **Dados usados:** `estimateMin`, `result`, `reason`.
- **Para que serve:** saber se prometer uma espera longa afasta clientes e se vale mostrar
  a estimativa de outra forma.
- **Limitação:** o histórico anterior ao deploy que grava `estimateMin` não tem o campo.
  Enquanto não houver registro com estimativa, a tela explica isso em vez de mostrar o
  gráfico.
- **Função:** `abandonmentByEstimate`.

### Precisão da estimativa

- **O que é:** o erro médio, em minutos, da estimativa mostrada ao cliente.
- **Como é calculado:** para `served` e `no_show` com `estimateMin` e espera
  (`calledAt - joinedAt`, entre 0 e 24 h), `erro = espera real - estimateMin`. Devolve
  `meanErrorMin` (média com sinal: positivo = a espera foi maior que o prometido) e
  `meanAbsErrorMin` (média do valor absoluto, que não deixa erros positivos e negativos se
  anularem). Abaixo de `minSamples` (padrão 5) as médias são `null`. `left` não entra
  (não tem espera até a chamada).
- **Dados usados:** `estimateMin`, `joinedAt`, `calledAt`, `result`.
- **Para que serve:** avaliar se o tempo médio configurado (ou a estimativa automática)
  reflete a realidade e quando ajustá-lo.
- **Limitação:** mesma do indicador anterior (sem `estimateMin` em registros antigos).
- **Função:** `estimateAccuracy`.

## Grupo 3: metas e monitoramento em tempo real

### Metas por fila

- **Dado:** `queues/{id}.goals = {maxWaitMin 1-240, maxServiceMin 1-240, targetPct 50-100}`,
  todos opcionais; `goals` ausente = sem meta. Só Firestore (sem espelho no RTDB), só o
  dono escreve. `targetPct` ausente vale 80 (`QueueGoals.defaultTargetPct`). Uma fila
  "tem meta" quando define `maxWaitMin` ou `maxServiceMin` (`QueueGoals.hasGoal`);
  `targetPct` sozinho não é meta.
- **Rules (Firestore):** `validGoals` roda **só no update**, dentro de `queueUpdateFieldsOk`
  e apenas quando `goals` está entre os campos alterados (mesmo padrão de `alerts`):
  mapa, chaves `hasOnly` as três, cada valor `int` na faixa (ou ausente/`null`), campo
  removível. **Não há validação no create**: o cliente valida (`QueueGoals.validate`) e o
  orçamento de 1000 expressões do create do wizard fica intocado (o teste "create do wizard
  no pior caso" inclui `goals` e passa). Atenção: o update sintético "todos os campos
  validados" (20 slots + nome + descrição + alerts + privacidade + expiry) estourava as 1000
  expressões ao somar `goals`; o app grava `goals` sozinho (tile), então o teste do pior
  caso do update não inclui `goals` e há um teste próprio de `slots + goals` no mesmo update.
- **App:** `QueueGoals` (`models/queue_goals.dart`: leitura tolerante, `validate()` com
  `GoalsError`, `toMap`), `QueueService.updateGoals(queueId, goals?)` (`null` remove com
  `FieldValue.delete()`; meta inválida lança `FormatException`), `createQueue(goals:)` (só
  grava com meta; `duplicateQueue` copia) e o tile "Metas de atendimento" em
  `QueueSettingsSections` (só dono; diálogo com espera, atendimento e alvo, validação por
  campo e "Remover metas").

### Espera dentro da meta

- **O que é:** parte das pessoas que esperou até `maxWaitMin`.
- **Como é calculado:** para cada fila com `maxWaitMin`, avaliam-se `served` e `no_show`
  com `wait = calledAt - joinedAt` e `left` (sem `expired`/`closed`) com `finishedAt -
  joinedAt`. **Decisão sobre `left`:** só entra quem esperou **mais** que a meta, e conta
  como descumprimento; quem desistiu com espera até a meta fica de fora (não se sabe se
  a espera seria cumprida e a pessoa não foi atendida). Espera negativa, maior que 24 h,
  sem `calledAt` ou `joinedAt` na época 0 é descartada. Cumpre quem tem espera `<=` meta.
  `pct = cumpriram / avaliados`; a meta é **atingida** quando `cumpriram * 100 >= soma dos
  alvos das amostras` (inteiros, sem arredondar). Com várias filas cada amostra usa a meta e
  o alvo da própria fila; o alvo mostrado é a média ponderada pelas amostras (`targetPct`
  de `GoalBucket`) e o percentual exibido é truncado (`pctFloor`), para nunca mostrar 80%
  em meta não atingida. Abaixo de `defaultGoalMinSamples` (5) avaliados o cartão mostra
  "amostra pequena" e esconde o selo atingida/não atingida.
- **Dados usados:** `result`, `joinedAt`, `calledAt`, `finishedAt`, `reason`, `goals`.
- **Função:** `computeGoalReport` (`GoalReport.wait`).

### Atendimento dentro da meta

- **Como é calculado:** só `served` com `service = finishedAt - calledAt >= 0`; cumpre
  quem tem `service <= maxServiceMin`. Mesmas regras de percentual, alvo e amostra.
  `no_show` e `left` não entram.
- **Função:** `computeGoalReport` (`GoalReport.service`).

### Períodos em que a meta não foi atingida e maior violação

- **Como é calculado:** agrupa as amostras por dia (São Paulo, `spDay`) e por hora do dia
  (`spHour`), sempre pelo `joinedAt` na espera e pelo `calledAt` no atendimento. Lista os
  **dias** e as **horas do dia** (agregadas no período) com pelo menos `minSamples` (5)
  avaliados e `met == false`. A série diária (`days`) alimenta o gráfico, que só aparece
  com mais de um dia. A maior violação é o maior `valor - limite` em minutos e o dia em
  que ocorreu (`worstOverMin`/`worstDay`).
- **Função:** `computeGoalReport` (`GoalIndicator.missedDays`, `missedHours`).

### Tempo real: meta de espera em risco

- **Cálculo:** `goal_risk.dart`. Espera estimada = `waiting x (avgServiceMinAuto ??
  avgServiceMin ?? 10)` (mesma escolha de `effectiveAvgMin` da web e mesma fórmula da regra
  de espera dos alertas; o widget web usa `waiting + 1` por tratar de quem entra agora).
  Em risco quando a estimativa é **estritamente maior** que `goals.maxWaitMin`.
- **Painel (dono e operador):** `GoalRiskBanner` mostra "Meta de espera em risco", a
  estimativa, a meta e a sugestão "chame mais um atendente ou abra outro balcão". `waiting`
  vem do `watchEntries` que o painel já assina; o único listener novo é
  `QueueService.watchAvgServiceMinAuto` (um número, `meta/avgServiceMinAuto`), assinado só
  se a fila tem `maxWaitMin`.
- **Home (dono):** selo discreto no card usando o `waitingCount` que a home já mantém e o
  `avgServiceMin` **manual** do doc da fila. **Limitação:** a home não lê
  `avgServiceMinAuto` (exigiria um listener por card), então o selo pode divergir do
  banner do painel quando a estimativa automática é bem diferente do tempo manual.

## Grupo 4: planejamento e dimensionamento

Todos os cálculos de `staffing_metrics.dart` usam São Paulo (UTC-3 fixo). Dia da semana:
segunda = 0 (igual à matriz de demanda existente).

### Demanda média por dia da semana e hora

- **Como é calculado:** chegadas = todas as entradas com `joinedAt` válido (inclui
  `left` e `no_show`, e remoções do sistema) agrupadas por (dia da semana, hora) de
  `joinedAt`. Chegadas por hora de cada célula = total da célula **÷ número de ocorrências
  daquele dia da semana entre o primeiro e o último dia coberto pelos dados** (dias de
  `joinedAt` e de `calledAt`), e não o número de dias com dado. Ex.: dados de segunda 4/5 a
  segunda 11/5 cobrem 8 dias, com 2 segundas; 6 chegadas às 12h de segunda = 3 por hora.
- **Escopo:** usa o período escolhido na tela (os filtros do restante das métricas).
  Com 7 dias cada dia da semana ocorre uma vez.
- **Função:** `computeStaffingGrid` (`StaffingCell.arrivals`).

### Tempo médio de atendimento

- Média de `finishedAt - calledAt` dos `served` do escopo/período (entre 0 e 24 h).
  Menos de `defaultMinServiceSamples` (3) amostras: `avgServiceMin == null`, e a
  recomendação fica indisponível (a tela explica e só oferece o modo "observado").

### Atendentes recomendados

- **Fórmula:** `ceil(chegadasPorHora x tempoMédioMin / 60 / ocupaçãoAlvo)`, mínimo 1 em
  célula com chegadas, 0 sem chegadas. `ocupaçãoAlvo` é parâmetro de `computeStaffingGrid`
  (`defaultTargetOccupancy = 0,85`). A tela não expõe o parâmetro (o texto "i" mostra o
  valor usado). Tolerância de `1e-9` antes do `ceil`, para que 3/h x 20 min com ocupação 1,0
  dê 1 e não 2.
- Exemplo: 3 chegadas/h, 20 min médios, 85% => `3 x 20/60 / 0,85 = 1,18` => 2 atendentes.

### Atendentes observados

- **Como é calculado:** para cada `served`/`no_show` com `calledAt`, o atendente
  (`calledBy`/`operatorId`; dono e sem id viram um só) conta em cada hora **cheia**
  (data + hora de São Paulo) que o atendimento atravessa, da chamada ao fim (limite de 24
  horas; término exatamente na virada da hora não conta a hora seguinte; sem `finishedAt`
  conta só a hora da chamada). Para cada (data, hora) conta-se operadores **distintos**;
  soma-se por (dia da semana, hora) e divide-se pelas **mesmas ocorrências** do dia da
  semana usadas nas chegadas (dias sem atendimento contam como 0, coerente com as chegadas).

### Déficit e folga

- `gap = recomendados - observados` (positivo = falta gente, negativo = folga). Os
  `N` (5) maiores déficits são as células com recomendados > 0 e `gap > 0`, ordenadas por
  `gap` decrescente, depois recomendados, dia e hora. Ex.: "terça-feira 10h: precisa de 3,
  tem 1,6". Na grade a cor usa tolerância de 0,25 (abaixo disso, equilibrado).

### Sazonalidade: volume semanal, tendência e padrão recorrente

- **Base:** usa **todo o histórico carregado** do escopo (não o período escolhido), porque
  8 semanas não cabem em "7 dias". Semanas de segunda a domingo (São Paulo); as
  `seasonWeeks` (8) semanas **completas** anteriores à semana de `now` (a semana em andamento
  fica de fora). Começa na primeira semana com dados (semanas antes disso não são zero, são
  "sem histórico"); semanas sem dados **depois** da primeira contam como 0.
- **Dados insuficientes:** menos de `minSeasonWeeks` (3) semanas observadas: a tela mostra
  a mensagem e não calcula tendência nem padrão.
- **Tendência:** inclinação da regressão linear dos volumes semanais, em **% da média
  semanal por semana**; abaixo de `stableTrendPct` (5%) é "estável".
- **Padrão recorrente:** em cada semana observada pega as `seasonTopCells` (5) células
  (dia x hora) com mais chegadas (apenas contagem > 0; empate por ordem dia/hora); uma
  célula é recorrente se aparece nesse grupo em pelo menos `recurrencePct` (70%) das semanas
  observadas (`tally * 100 >= 70 * semanas`).
- **Limitação:** o `history` é limitado a 500 documentos por fila; em filas movimentadas as
  semanas mais antigas podem estar incompletas (a tela de atendentes já avisa o corte).
- **Funções:** `computeSeasonality`, `buildStaffingReport`.

## Interface (MetricsScreen)

As seções aparecem na tela de métricas com o mesmo escopo (todas/grupo/sem grupo/fila) e
período dos demais cards. Textos de ajuda de cada indicador (botão "i": o que é, como é
calculado, dados usados, para que serve) vêm do l10n (`bi*` nos arb) e seguem este
documento.

- **Por atendente** (`attendants-section`): `AttendantsTable` (colunas ordenáveis:
  atendimentos, tempo médio, desvio vs média, atend./h na janela, ociosidade, não
  compareceu, nota; `—` quando a amostra é insuficiente) e `AttendantsChart`
  (atendimentos por hora do dia ou por turno, para todos ou um atendente). Substitui os
  cartões da seção antiga e mantém o filtro por fila e o aviso de histórico truncado.
  Cálculo em `buildAttendantRows` (`attendant_metrics.dart`). A ociosidade só aparece com
  pelo menos 3 atendimentos concluídos. Tabela e gráfico usam a **mesma base**: antes de
  calcular, descartam-se entradas com `joinedAt` na época 0 e `served` sem `finishedAt` nem
  `calledAt` (`isUsableForAttendants`), então a soma do gráfico por hora/turno de um
  atendente é igual ao "atendimentos" da tabela.
- **Desistências** (`abandon-section`): só aparece quando há amostras. Respeita o mesmo
  filtro de fila da seção "Por atendente" (a seção mostra a fila escolhida e o aviso de
  histórico truncado dessa seleção); escopo e período são os da tela. Taxa por faixa de
  espera (barras da taxa a cada 10 min, com o ponto de inflexão marcado), por estimativa
  mostrada, precisão da estimativa, barras por hora de chegada (taxa e contagem) e o card
  "Possível falta de capacidade" (`capacitySignalHours`). Cálculo em
  `buildAbandonmentReport` (`abandonment_metrics.dart`).
- **Metas** (`goals-section`): cartões "Espera dentro da meta" e "Atendimento dentro da
  meta" (percentual, alvo, selo Atingida/Não atingida com ícone e texto, contagem, gráfico
  diário com a linha do alvo e as barras abaixo do alvo destacadas) e "Períodos em que a meta
  não foi atingida" (até 10 dias por indicador, mais as horas e a maior violação). Aparece
  sempre que há dados; sem nenhuma fila com meta no escopo mostra a chamada para configurar
  (`goals-empty-cta`); com meta e sem amostras mostra o estado vazio de cada cartão.
- **Planejamento de equipe** (`staffing-section`): grade dia x hora rolável na horizontal
  com os modos Recomendado/Observado/Diferença (`staffing-mode-*`, células
  `staffing-cell-<dia>-<hora>`), tempo médio e ocupação-alvo, os 5 maiores déficits
  (`staffing-top-<i>`) e o card de volume semanal com tendência e padrão recorrente. O
  "i" muda com o modo da grade.
- **Exportação:** a seção "Por atendente" do CSV e do PDF passou a ser uma só tabela, com
  todas as colunas da tela (a tabela antiga, sem desvio, ritmo e ociosidade, foi removida);
  o CSV e o PDF ganham também "Taxa por faixa de
  espera", "Taxa por estimativa mostrada" (só com dados) e "Desistência por hora de
  chegada", sem telefone, respeitando escopo e período. Os valores com sinal (desvio e erro
  da estimativa) saem como `+50.0`/`-50.0` sem o apóstrofo de proteção do CSV.
- **Exportação de metas e planejamento:** o CSV e o PDF trazem "Metas" (por indicador:
  avaliados, dentro do limite, %, alvo, atingida, maior violação e dia), "Períodos em que a
  meta não foi atingida" (dias e horas), "Planejamento de equipe" (tempo médio, ocupação-alvo,
  dias de base e a grade com chegadas por hora, recomendados, observados e diferença só nas
  células com atividade), "Maiores déficits", "Volume semanal e sazonalidade" (com
  tendência) e "Padrão recorrente". Sem metas nas filas do escopo, a seção de metas não
  existe; sem semanas observadas, a de sazonalidade some. Sem telefone nem nome de pessoa.
