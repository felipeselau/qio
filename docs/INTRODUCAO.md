# Introdução

## Contexto

O atendimento presencial continua sendo a principal forma de prestação de serviços em diversos segmentos — clínicas médicas, consultórios odontológicos, salões de beleza, academias, lojas de serviços e estabelecimentos comerciais em geral. Independentemente do porte ou do nicho, um elemento comum a esses ambientes é a **fila de espera**: o cliente chega, registra sua presença e aguarda ser chamado para ser atendido.

Esse modelo tradicional, baseado em listas de papel, bloquinhos de senha ou até mesmo na simples lista de nomes, apresenta uma série de problemas que afetam diretamente a experiência do cliente e a eficiência do estabelecimento.

## Problemas do Modelo Atual

### Para o cliente

- **Incerteza sobre o tempo de espera**: sem informação sobre a posição na fila ou tempo estimado, o cliente não sabe quanto tempo precisará aguardar. Isso gera ansiedade, frustração e a percepção de que o atendimento é lento — mesmo quando não é.
- **Necessidade de permanência física**: o cliente é obrigado a ficar presente no local durante toda a espera, sem poder realizar outras atividades. Em casos de espera longa, isso significa tempo produtivo perdido.
- **Falta de mobilidade**: ao sair do local para ir ao banheiro, buscar algo no carro ou atender uma ligação, o cliente pode perder sua vez sem ter como comprovar que estava presente.
- **Experiência negativa**: a sensação de "ser apenas mais um número" em uma fila desorganizada contribui para uma percepção negativa do atendimento e do estabelecimento.

### Para o estabelecimento (proprietário)

- **Desorganização operacional**: gerenciar filas manualmente consome tempo e atenção do staff, desviando foco do atendimento principal.
- **Perda de clientes**: clientes que desistem de aguardar saem do estabelecimento sem serem atendidos — e geralmente não voltam.
- **Falta de dados**: sem registro digital, não é possível analisar tempos de atendimento, picos de demanda ou desempenho da equipe — dados essenciais para tomada de decisão.
- **Imagem negativa**: estabelecimentos com filas desorganizadas passam a imagem de ineficiência, afetando a reputação e a retenção de clientes.

## Impactos de Não Ter uma Solução Digital

A ausência de um sistema de filas digital gera impactos mensuráveis, sustentados por dados de pesquisas recentes:

### Tempo perdido e abandono de filas

- **37 bilhões de horas/ano** são gastas por americanos esperando em filas físicas (Waitwhile, *The State of Waiting in Line*, 2024).
- **80% dos consumidores** só aceitam esperar até 15 minutos em uma fila física; apenas 5% esperam mais de 30 minutos (Waitwhile, 2024).
- O **limite médio de paciência** é de apenas **8 minutos** antes do cliente desistir da fila (ScanQueue, *47 Wait Time Statistics*, 2026).
- **61% dos consumidores** já saíram de uma fila antes de serem atendidos (Waitwhile, 2024).

### Perda de receita

- Filas mal gerenciadas custam **US$ 130 bilhões por ano** apenas nos Estados Unidos (ScanQueue, 2026).
- No Reino Unido, filas longas representam perdas de **£ 11,3 bilhões** anuais para varejistas, com £ 6,4 bilhões indo para concorrentes e £ 5,6 bilhões perdidos por clientes que desistem (QMinder, *60+ Queue Management Statistics*, 2021).
- **66% dos consumidores britânicos** já abandonaram uma compra por causa de filas, e apenas 22% voltaram depois para comprar (QMinder, 2021).
- Um estudo empírico com 94.404 clientes de restaurante mostrou que, **sem filas, a receita total aumentaria 15%** (de Vries, Roy & de Koster, *Journal of Operations Management*, 2018).
- **39% dos consumidores** mudam para um concorrente ou desistem da compra ao enfrentar uma fila física (Waitwhile, *State of Waiting in Line*, 2025).

### Impacto na satisfação e NPS

- **73% dos clientes** dizem que a espera é a parte mais frustrante de visitar um estabelecimento (Zendesk, *CX Trends*, 2025).
- **86% dos consumidores** evitam lojas onde percebem que a fila é longa (Loris, *Customer Expectations Survey*, 2025).
- **63% dos pacientes** de saúde escolheriam outro fornecedor se fossem consistentemente submetidos a tempos de espera longos (NRC Health, *Consumer Panel*, 2021).
- A percepção de espera é **superestimada em 36%** quando o cliente não recebe informação sobre o tempo (FasterLines, 2024).

### Custos operacionais

- Funcionários dedicados a gerenciar filas em vez de atender clientes representam custo de mão de obra direto e desperdício de capacidade produtiva.
- O turnover médio em varejo é de **60%**, e filas mal gerenciadas aumentam a frustração tanto de clientes quanto de funcionários (Waitwhile, 2025).

## A Solução: Qio

O **Qio** surge como uma solução digital para modernizar o gerenciamento de filas em estabelecimentos presenciais. O sistema permite que:

1. **O proprietário** crie e gerencie filas diretamente pelo aplicativo móvel, sem necessidade de infraestrutura complexa.
2. **O cliente** entre na fila escaneando um QR Code — sem precisar instalar nenhum aplicativo, bastando o navegador do celular.
3. **Ambos** acompanhem o andamento da fila em tempo real, com notificações automáticas quando chegar a vez do cliente.

### Diferenciais

- **Zero barreira de entrada para o cliente**: não há app para instalar. O QR Code direciona para uma página web que funciona em qualquer navegador moderno.
- **Notificação em tempo real**: o cliente é alertado visual e sonoramente quando chamado, podendo estar em outra parte do estabelecimento.
- **Funciona offline (quase)**: a página do cliente mantém conexão em tempo real com o servidor, atualizando posição e status automaticamente.
- **Custo zero para o cliente**: o sistema roda na camada gratuita do Firebase (Spark), viável para validação do MVP e pequenos estabelecimentos.
- **Experiência mobile-first**: projetado para o contexto real de uso — celular do cliente escaneando QR Code, proprietário usando o app no dia a dia.

### Evidências de que filas virtuais funcionam

- **52% dos consumidores** preferem filas virtuais às filas físicas tradicionais (Waitwhile, 2024).
- Atualizações em tempo real reduzem o tempo de espera percebido em **35%**, mesmo quando o tempo real não muda (Journal of Service Research, 2025).
- Filas virtuais aumentam a satisfação do cliente em **10,8%** em comparação com filas físicas (SSRN, *The Psychology of Virtual Queue*, 2024).
- **45% dos clientes** em filas virtuais continuam comprando enquanto esperam, gerando receita adicional (Waitwhile, 2025).
- Clientes em filas virtuais são **quase 5 vezes mais propensos** a tolerar esperas de 30+ minutos (Waitwhile, 2025).

## Objetivo do Trabalho

Este trabalho tem como objetivo desenvolver e validar o **Qio** como solução para o problema de gerenciamento de filas presenciais, abordando:

- Arquitetura de software distribuído com comunicação em tempo real
- Experiência do usuário em dois contextos distintos (proprietário no app, cliente no navegador)
- Uso de tecnologias serverless para redução de custos e complexidade de infraestrutura
- Notificações push em ambiente web (Progressive Web App)
- Validação do MVP com usuários reais

## Referências

1. Waitwhile. *The State of Waiting in Line 2024*. Disponível em: https://waitwhile.com/blog/consumer-survey-waiting-in-line-2024/
2. Waitwhile. *The State of Waiting in Line 2025: Retail as the Global Waiting Crisis Epicenter*. Disponível em: https://www.mynewsdesk.com/waitwhile/blog_posts/the-state-of-waiting-in-line-2025
3. ScanQueue. *47 Wait Time Statistics (2026): Customers Leave at 8 Min*. Disponível em: https://scanqueue.com/blog/state-of-customer-waiting-2026
4. de Vries, J., Roy, D., & de Koster, R. (2018). Worth the wait? How restaurant waiting time influences customer behavior and revenue. *Journal of Operations Management*, 64(3), 294-310. DOI: 10.1016/j.jom.2018.05.001
5. Qminder. *60+ Queue Management Facts and Statistics*. Disponível em: https://www.qminder.com/blog/queue-management/queue-management-statistics-facts/
6. Zendesk. *CX Trends 2025*.
7. NRC Health. *2021 Consumer Panel: The Impact of Wait Times on NPS Scores*. Disponível em: https://nrchealth.com/2021-consumer-panel-highlights-the-impact-of-wait-times-on-nps-scores/
8. Buell, R. W. & Norton, M. I. (2011). Think Customers Hate Waiting? Not So Fast... *Harvard Business Review*, 89(5).
9. FasterLines. (2024). *Queue Perception Study*.
10. SSRN. *The Psychology of Virtual Queue: When Waiting Feels Less Like Waiting*. (2024).
