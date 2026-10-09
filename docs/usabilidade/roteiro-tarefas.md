# Roteiro de tarefas

Leia ao participante apenas o **cenário** e o **enunciado** de cada tarefa. Não diga como fazer. Os tempos-alvo são estimativas iniciais **a validar em ensaio piloto**; não são resultados medidos.

Definições:

- **Sucesso:** concluiu a tarefa sozinho, no caminho previsto ou em outro equivalente.
- **Sucesso assistido:** concluiu após dica do moderador (não entra na taxa de sucesso, mas deve ser registrado).
- **Falha:** desistiu, ou o moderador teve que fazer a tarefa.
- **Tempo-alvo:** tempo acima do qual a tarefa é marcada como lenta. Registrar o tempo real mesmo assim.
- **Limite:** após esse tempo sem sucesso, encerrar a tarefa como falha.

## Parte A: dono e operador (app Flutter)

Cenário: "Você tem uma barbearia pequena e quer organizar a fila de espera dos clientes com o Qio."

| ID | Tarefa (enunciado) | Critério de sucesso | Tempo-alvo | Limite |
| --- | --- | --- | --- | --- |
| D1 | Instale o app (ou abra o já instalado) e entre com sua conta. | Chega à tela inicial autenticado. | 3 min | 6 min |
| D2 | Crie uma fila chamada "Barbearia" com tempo médio de 15 minutos. | Fila aparece na home com o nome e o tempo corretos. | 2 min | 5 min |
| D3 | Mostre como imprimir o QR da fila para colar na porta. | Abre o QR/cartaz e aciona imprimir ou compartilhar PDF. | 1 min 30 s | 4 min |
| D4 | Um cliente entrou na fila (o moderador entra pelo celular de apoio). Chame o próximo cliente. | Entry passa para "chamado" e a senha aparece como em atendimento. | 1 min | 3 min |
| D5a | O cliente chamado foi atendido. Registre o atendimento. | Marca como atendido. | 30 s | 2 min |
| D5b | Chame outro cliente que não apareceu. Registre que não compareceu. | Marca como não compareceu. | 45 s | 2 min |
| D6 | Descubra quanto tempo, em média, os clientes esperaram. | Abre as métricas e lê corretamente a espera média (ou mediana). | 2 min | 5 min |
| D7 (só operador) | Entre como operador usando o código `______` e chame o próximo. | Pedido aprovado pelo dono e chamada feita. | 3 min | 6 min |

Pergunta de fechamento: "O que foi mais confuso? O que você mudaria primeiro?"

## Parte B: cliente (web, sem instalar nada)

Cenário: "Você chegou a uma barbearia e há um QR na porta. Quer entrar na fila e esperar fora."

| ID | Tarefa (enunciado) | Critério de sucesso | Tempo-alvo | Limite |
| --- | --- | --- | --- | --- |
| C1 | Abra a fila usando o QR da porta. | Câmera/leitor abre a página da fila. | 30 s | 2 min |
| C2 | Entre na fila com seu nome (telefone é opcional). | Vê a tela da senha. | 1 min | 3 min |
| C3 | Diga qual é a sua senha, em que posição você está e quanto acha que vai esperar. | Informa corretamente os três itens (comparar com a tela). | 30 s | 2 min |
| C4 | Se quiser ser avisado quando for chamado, faça o necessário e deixe o celular bloqueado. O moderador chamará você. | Percebe a chamada (som, vibração ou push) e diz que é a sua vez. Registrar se ativou o aviso e qual canal funcionou. | 1 min após a chamada | 3 min |
| C5 | Mude de ideia e saia da fila. | Confirma a saída e vê a tela de saída. | 45 s | 2 min |
| C6 (opcional) | Avalie o atendimento com estrelas. | Envia ou pula a avaliação. | 45 s | 2 min |

Pergunta de fechamento: "Você saberia o que fazer se a fila estivesse fechada ou cheia?"

## Observações para o moderador

- Registrar dispositivo, navegador e sistema do cliente (Android/iOS). Push no iOS só funciona com a PWA instalada; anotar quando o aviso não chegar por esse motivo, sem classificar como falha do participante.
- Para C4, o aviso em segundo plano depende de `VITE_VAPID_KEY` no build publicado; confirmar antes se o push está ativo no ambiente do teste (ver [`../FCM.md`](../FCM.md)).
- Como C5 encerra a participação na fila, C4 e C5 precisam de uma entrada nova por participante; C6 só ocorre após atendimento.
- Cada tarefa deve ser cronometrada do fim da leitura do enunciado até o critério de sucesso.
- Se houver dúvida sobre se algo é erro de usabilidade ou defeito técnico, registrar nos comentários e separar na análise.
