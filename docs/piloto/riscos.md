# Riscos do piloto e mitigação

Probabilidade (P) e impacto (I): B/M/A (baixa/média/alta). Classificação inicial proposta; revisar com o orientador.

## LGPD e privacidade

| ID | Risco | P | I | Mitigação | Responsável |
| --- | --- | --- | --- | --- | --- |
| R1 | Cliente não é informado de que há coleta/pesquisa | M | A | Aviso impresso junto ao QR ([`aviso-consentimento.md`](./aviso-consentimento.md)); conferir no dia -1 | Pesquisador |
| R2 | Telefone exportado ou compartilhado por engano | M | A | Usar só a exportação padrão (sem telefone); ligar "Não guardar telefone no histórico"; revisar o arquivo antes de enviar | Pesquisador |
| R3 | Pedido de titular sem canal ou fora do prazo (15 dias sugeridos) | B | M | Contato do estabelecimento no aviso; dono treinado na ferramenta "Dados de um cliente" | Responsável do local |
| R4 | Retenção maior que a prometida no aviso | M | M | Conferir `retentionDays`; excluir a fila ao fim se combinado; backups podem reter dados por mais tempo (ver [`../backup.md`](../backup.md)) | Pesquisador |
| R5 | Textos legais ainda são minuta (privacidade/termos) | A | M | Revisar com orientador/jurídico antes do dia 1; não afirmar conformidade total | Pesquisador |
| R6 | Dados de menores | B | M | Confirmar a regra com o orientador; atendente orienta o responsável a digitar | Orientador |
| R7 | Exposição de dado pessoal (ex.: conta de operador compartilhada) | B | A | Conta por operador; remover operador ao fim; trocar senha se suspeito; registrar incidente e avisar o responsável | Pesquisador |
| R8 | Operador anota ou fotografa telefone fora do app | M | M | Regra no treino; registrar ocorrências no diário | Operador |

## Falha de rede e sistema

| ID | Risco | P | I | Mitigação | Responsável |
| --- | --- | --- | --- | --- | --- |
| R9 | Internet do local cai | M | A | Dados móveis no aparelho do operador; lista em papel; registrar depois por entrada manual; registrar incidente | Operador |
| R10 | Cliente sem sinal para abrir o QR | M | M | Atendente coloca manualmente ("Adicionar pessoa"); sugerir o Wi-Fi do local, se houver | Operador |
| R11 | Serviço indisponível (Firebase, Cloud Functions) | B | A | Congelar versão; plano B em papel; contato do pesquisador; sem deploys durante o piloto | Pesquisador |
| R12 | QR impresso deixa de funcionar (link curto trocado, fila excluída) | B | A | Não trocar o link curto depois de impresso; `/q/{id}` como alternativa fixa | Pesquisador |
| R13 | Fila abre ou fecha na hora errada (horário de funcionamento) | M | M | Testar no dia -1; dono sabe pausar e reabrir manualmente | Dono |
| R14 | Notificação não chega (iOS sem PWA, permissão negada) | A | M | O aviso é opcional; atendente chama em voz alta; a tela acompanha a posição | Operador |
| R15 | Entrada duplicada ou acima do limite (joins simultâneos) | B | B | Aceitar 1 a 2 vagas de folga (limitação conhecida); registrar no diário | Pesquisador |

## Adoção e pesquisa

| ID | Risco | P | I | Mitigação | Responsável |
| --- | --- | --- | --- | --- | --- |
| R16 | Poucos clientes usam o QR | A | A | Convite verbal do atendente; cartaz visível; entrada manual como porta de entrada; medir H1 sem culpar o cliente | Operador |
| R17 | Operador abandona o painel (atende por fora) | M | A | Treino de 10 min; acompanhamento no dia 1; lembrar de finalizar atendimentos | Pesquisador |
| R18 | Métricas distorcidas (atendimento não finalizado, no-show por esquecimento) | M | M | Regra "finalize cada atendimento"; revisar o histórico por dia; marcar dias atípicos | Operador |
| R19 | Amostra pequena torna os resultados inconclusivos | A | M | Declarar inconclusivo; estender o período; evitar estatística inferencial | Pesquisador |
| R20 | Estabelecimento desiste ou muda de rotina no meio | M | M | Autorização formal; ponto de contato; permitir encerramento sem prejuízo | Pesquisador |
| R21 | Pesquisador influencia o resultado (presença constante) | M | M | Reduzir a presença após o dia 1; registrar quando houve ajuda | Pesquisador |
| R22 | Reclamação de cliente sobre espera ou sistema | M | B | Script de atendimento; registrar no diário; encaminhar ao responsável | Operador |

Revisar esta tabela no dia -1 e ao fim de cada semana. Riscos que se materializarem vão para o registro de incidentes e para a seção 6 do relatório.
