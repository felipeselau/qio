# Relatório final do piloto (modelo para o TCC)

Preencher só com dados coletados. Onde não houver, escrever "não medido". Não extrapolar além do contexto do estabelecimento.

## 1. Contexto

- Estabelecimento (ou "Estabelecimento A"): [a preencher]; ramo, porte, fluxo típico de clientes: [a preencher]
- Como era a fila antes (senha em papel, ordem de chegada, outra): [a preencher]
- Período: [data] a [data]; dias de funcionamento cobertos: [n]; horário: [a preencher]
- Versão do app: [versão]; web (commit): [hash]; aparelhos e navegadores usados: [a preencher]
- Pessoas envolvidas: [n] operador(es), [n] responsável(is)
- Aprovações e termos: [orientador/CEP/autorização do estabelecimento]

## 2. Método

Resumo do [`plano.md`](./plano.md): hipóteses, critérios de sucesso acordados, coleta (app, diário, entrevistas), exportação sem telefone. Desvios do plano: [a preencher].

## 3. Números

| Indicador | Valor | Critério acordado | Atingido? |
| --- | --- | --- | --- |
| Total de entradas | | | |
| Pelo QR / manuais | | | |
| Atendidos | | | |
| Não compareceu (%) | | | |
| Desistência (%) | | | |
| Espera mediana / p90 (min) | | | |
| Atendimento médio (min) | | | |
| Média ★ (n avaliações) | | | |
| Taxa de resposta ★ | | | |
| Incidentes graves | | | |

Tabela diária e gráficos: [anexo]. Amostra pequena ou dias atípicos: [a preencher].

## 4. SUS (se houver)

| Grupo | n | Média | Mín | Máx |
| --- | --- | --- | --- | --- |
| Operador/dono | | | | |
| Cliente | | | | |

Sem SUS: "não medido".

## 5. Achados

Separar fato observado de interpretação.

| ID | Achado (fato) | Evidência (diário/entrevista/número) | Severidade | Issue |
| --- | --- | --- | --- | --- |
| P01 | | | | #[nº] |

Hipóteses H1 a H5 de [`plano.md`](./plano.md): registrar "sustentada / não sustentada / inconclusiva" com a justificativa em uma linha.

## 6. Incidentes e riscos que se materializaram

Resumo do registro de incidentes e comparação com [`riscos.md`](./riscos.md): [a preencher].

## 7. Privacidade

Pedidos de titulares: [n]; exportações com telefone: [0 / n e motivo]; destino dos dados ao fim (fila excluída, retenção): [a preencher].

## 8. Limitações

Manter o que se aplica e completar, sem suavizar:

- Um único estabelecimento; sem grupo de controle; resultados não generalizáveis.
- Duração de [n] dias; sazonalidade e dias atípicos: [a preencher].
- Efeito do pesquisador presente (Hawthorne); suporte dado no local.
- Autosseleção: quem usa o QR e quem avalia ★ pode não representar todos os clientes.
- Métricas medidas pelo próprio sistema; `finishedAt` inclui até ~5 s da janela de desfazer; atendimentos fora do app (papel, contingência) ficam fora do histórico: [a preencher].
- Fuso fixo `America/Sao_Paulo`.
- Limitações técnicas conhecidas: [`../arquitetura/limitacoes-e-trabalhos-futuros.md`](../arquitetura/limitacoes-e-trabalhos-futuros.md).

## 9. Conclusões e trabalhos futuros

Resposta à pergunta do piloto em até 5 linhas: [a preencher]. Próximos passos (issues): [a preencher].

## Anexos

Diário de campo (anonimizado), planilha diária, CSV agregado sem telefone, roteiro de entrevista. Termo assinado: arquivar fora do repositório.
