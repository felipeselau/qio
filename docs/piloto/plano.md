# Plano do piloto

Minuta de planejamento. Metas e limiares abaixo são **propostas a validar com o orientador**, não resultados.

## 1. Objetivo

Observar o Qio em uso real, em um estabelecimento com atendimento por ordem de chegada, por 1 a 2 semanas, e medir com as métricas que o próprio app já coleta se a fila digital é utilizável no dia a dia.

- Estabelecimento: [a preencher]
- Tipo de atendimento: [a preencher]
- Período: [data inicial] a [data final] (mínimo 5 dias úteis de funcionamento)
- Responsável no local: [nome/contato]
- Pesquisador: [nome] · Orientador: [nome]

## 2. Hipóteses

| ID | Hipótese | Indicador |
| --- | --- | --- |
| H1 | Clientes entram na fila pelo QR sem ajuda na maioria dos casos | Entradas pela web / total de entradas (o restante é entrada manual no balcão) |
| H2 | O operador consegue conduzir a fila sem ajuda do pesquisador depois do treino | Ajudas do pesquisador no diário de campo, por dia |
| H3 | A taxa de não comparecimento é aceitável para o estabelecimento | % `no_show` sobre atendimentos finalizados |
| H4 | O tempo de espera é compatível com o que o estabelecimento considera aceitável | Mediana e p90 do tempo de espera |
| H5 | Clientes que avaliaram deram notas boas | Média de ★ e nº de avaliações |

Cada hipótese deve ser lida como pergunta; o piloto não tem grupo de controle nem poder estatístico.

## 3. Duração e rotina

1. Dia -7 a -1: checklist de preparação ([`checklist-preparacao.md`](./checklist-preparacao.md)) e treino do operador.
2. Dia 1: acompanhamento presencial integral; ajustes rápidos permitidos e registrados.
3. Dias 2 a N: acompanhamento reduzido (visita ou contato diário); preencher o diário ([`coleta-e-diario.md`](./coleta-e-diario.md)) ao fim de cada dia.
4. Último dia: exportar dados, entrevistar o responsável e o operador, aplicar SUS se houver.
5. Até 7 dias depois: relatório ([`relatorio-modelo.md`](./relatorio-modelo.md)).

Congele a versão do app e do web durante o piloto. Registre a versão (`app/pubspec.yaml`) e o commit publicado.

## 4. Métricas e origem

Todas vêm do `history` do app (Histórico e Métricas do dono). Convenções do projeto: tempo de atendimento = `finishedAt − calledAt` (somente `served`); `left` é "Desistiram" e não entra na taxa de no_show.

| Métrica | Como ler no app | Observação |
| --- | --- | --- |
| Tempo de espera | Métricas: espera | Registrar mediana e p90; a média sozinha esconde picos. Confira na tela quais estatísticas o app mostra e anote "não medido" para as ausentes |
| Tempo de atendimento | Métricas: atendimento | Inclui até ~5 s da janela de desfazer |
| No-show | Métricas: não compareceu | Poucas amostras tornam o percentual instável (sugestão: ≥ 20 finalizados) |
| Desistência | Métricas: desistiram (`left`) | Saídas automáticas por expiração/fechamento (`reason`) não contam |
| Feedback ★ | Histórico: média e contagem | Opcional para o cliente; taxa de resposta = avaliações / atendidos |
| Volume | Total de entradas por dia | Separar entradas manuais das pelo QR (diário) |

O que o app **não** mede e precisa de coleta manual: entradas pelo QR versus balcão (anotar no diário), problemas de rede, ajuda dada ao operador, percepção do responsável.

## 5. Critérios de sucesso (propostos)

Definir os limiares com o responsável do estabelecimento **antes** do dia 1 e escrevê-los aqui.

| Critério | Limiar proposto | Limiar acordado | Atingido? |
| --- | --- | --- | --- |
| Operador conduz a fila sem ajuda do pesquisador a partir do dia [3] | ≥ [80]% dos dias | [a preencher] | [ ] |
| Mediana de espera | ≤ [X] min (definido pelo local) | [a preencher] | [ ] |
| No-show | ≤ [X]% | [a preencher] | [ ] |
| Desistência | ≤ [X]% | [a preencher] | [ ] |
| Feedback médio | ≥ [4,0] com ≥ [10] avaliações | [a preencher] | [ ] |
| Incidentes graves (entrada perdida, fila indisponível > 15 min) | 0 | [a preencher] | [ ] |
| Estabelecimento aceitaria continuar usando | Sim (entrevista) | [a preencher] | [ ] |

Se a amostra for pequena demais, declarar "inconclusivo" em vez de forçar uma conclusão.

## 6. Exportar CSV/PDF sem telefone

1. No app (conta do dono): Histórico ou Métricas da fila, escolher o período do piloto e o escopo (fila ou grupo).
2. Usar **Exportar CSV** ou **Exportar PDF** comuns. Eles saem **sem telefone**.
3. **Não** usar os itens "Exportar ... com telefone". Se o app pedir confirmação LGPD, cancelar.
4. Conferir o arquivo: não deve haver coluna de telefone.
5. Guardar os arquivos em local acordado com o orientador; nomear por data (ex.: `piloto-AAAA-MM-DD.csv`).
6. Para análise, trocar nomes por códigos antes de compartilhar ou citar no TCC. Não publicar nome de cliente.

Opcional: ligar "Não guardar telefone no histórico" nas configurações da fila antes do dia 1; o `history` deixa de gravar telefone (vale só para arquivamentos novos).

## 7. Retenção ao fim do piloto

Combinar com o estabelecimento: manter a fila ou excluí-la (`deleteQueue`). Registros do `history` expiram pela retenção da fila (padrão 180 dias; `retentionDays` só por Admin/console). Se o aviso prometer prazo menor, ajustar ou excluir manualmente.
