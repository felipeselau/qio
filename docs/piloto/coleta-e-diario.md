# Coleta de dados e diário de campo

Identificar pessoas por código (O1, O2, R1), nunca por nome e telefone. Não copiar telefone de clientes para estas tabelas.

## 1. Planilha diária (preencher ao fim do dia, a partir do app)

Fonte: Métricas/Histórico do dono, filtrado para o dia. Onde não houver dado, "não medido".

| Data | Dia da sem. | Horário aberto | Entradas totais | Pelo QR | Manuais (balcão) | Atendidos | Não compareceu | Desistiram | Espera mediana (min) | Espera p90 (min) | Atendimento médio (min) | Avaliações (n) | Média ★ | Maior fila (pessoas) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | | | | | | | |

"Pelo QR" e "Manuais" não vêm do app: anotar pela contagem do operador ou pela origem da entry no painel, se visível.

## 2. Totais do piloto (a partir do CSV exportado sem telefone)

| Indicador | Valor | Observação |
| --- | --- | --- |
| Total de entradas | | |
| Atendidos / não compareceu / desistiram | | |
| % no_show | | |
| % desistência | | |
| Espera mediana / p90 | | |
| Média ★ e nº de avaliações | | |
| Taxa de resposta ★ (avaliações / atendidos) | | |

## 3. Diário de campo (um bloco por dia)

**Data:** ___/___/______ · **Pesquisador presente?** [sim/não] · **Operador(es):** [códigos]

| Hora | Tipo | O que aconteceu (fato observado) | Ação tomada | Ajuda do pesquisador? |
| --- | --- | --- | --- | --- |
| | dificuldade / incidente / elogio / pedido / sugestão | | | [s/n] |

Perguntas do fim do dia (1 linha cada):

1. Alguma queda de internet ou lentidão? Hora e duração: [a preencher]
2. Algum cliente teve dificuldade com o QR/página? Quantos e o quê: [a preencher]
3. O operador pediu ajuda? Em quê: [a preencher]
4. Alguém recusou entrar na fila ou pediu para não dar dados? [a preencher]
5. Pedido de titular (acesso/correção/eliminação)? [a preencher]
6. Mudança feita no sistema ou na rotina hoje: [a preencher]

## 4. Registro de incidentes

| ID | Data/hora | Descrição | Duração | Impacto (nenhum/leve/grave) | Causa provável | Issue |
| --- | --- | --- | --- | --- | --- | --- |
| I01 | | | | | | #[nº] |

Grave = entrada perdida, fila indisponível > 15 min ou dado pessoal exposto (este último: ver LGPD em [`riscos.md`](./riscos.md)).

## 5. Entrevista final (semi-estruturada, 15 a 20 min)

Responsável e operador, separados. Registrar respostas em tópicos, sem nome.

1. Como era o atendimento antes? O que mudou?
2. O que funcionou bem? O que atrapalhou?
3. Os clientes entenderam? Houve reclamações ou elogios?
4. A espera estimada e a ordem pareceram corretas?
5. O que você mudaria no sistema?
6. Continuaria usando? Por quê?
7. Houve preocupação com os dados dos clientes?

## 6. SUS (opcional)

Usar [`../usabilidade/formulario-sus.md`](../usabilidade/formulario-sus.md) e registrar em [`../usabilidade/resultados-modelo.csv`](../usabilidade/resultados-modelo.csv). Participantes: operador(es) e dono ao fim; clientes só em abordagem voluntária e anônima. Registrar n: com poucos respondentes o escore é só indicativo.
