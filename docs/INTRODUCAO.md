# Introdução

## Contexto

O atendimento presencial continua sendo a principal forma de prestação de serviços em diversos segmentos — clínicas médicas, consultórios odontológicos, salões de beleza, academias, lojas de serviços e estabelecimentos comerciais em geral. Independentemente do porte ou do nicho, um elemento comum a esses ambientes é a **fila de espera**: o cliente chega, registra sua presença e aguarda ser chamado para ser atendido.

Esse modelo tradicional, baseado em listas de papel, bloquinhos de senha ou até mesmo na simples lista de nomes, apresenta uma série de problemas que afetam diretamente a experiência do cliente e a eficiência do estabelecimento.

## Problemas do Modelo Atual

### Para o cliente

- **Incerteza sobre o tempo de espera**: sem informação sobre a posição na fila ou tempo estimado, o cliente não sabe quanto tempo precisará aguardar. Isso gera ansiedade, frustração e a percepção de que o atendimento é lento — mesmo quando não é.
- **Necessidade de permanência física**: o cliente é obrigado a ficar presentes no local durante toda a espera, sem poder realizar outras atividades. Em casos de espera longa, isso significa tempo produtivo perdido.
- **Falta de mobilidade**: ao sair do local para ir ao banheiro, buscar algo no carro ou atender uma ligação, o cliente pode perder sua vez sem ter como comprovar que estava presente.
- **Experiência negativa**: a sensação de "ser apenas mais um número" em uma fila desorganizada contribui para uma percepção negativa do atendimento e do estabelecimento.

### Para o estabelecimento (proprietário)

- **Desorganização operacional**: gerenciar filas manualmente consome tempo e atenção do staff, desviando foco do atendimento principal.
- **Perda de clientes**: clientes que desistem de aguardar saem do estabelecimento sem serem atendidos — e geralmente não voltam. Pesquisas indicam que **86% dos clientes pagam mais por uma experiência melhor**, e a espera é um dos maiores fatores de insatisfação.
- **Falta de dados**: sem registro digital, não é possível analisar tempos de atendimento, picos de demanda ou desempenho da equipe — dados essenciais para tomada de decisão.
- **Imagem negativa**: estabelecimentos com filas desorganizadas passam a imagem de ineficiência, afetando a reputação e a retenção de clientes.

## Impactos de Não Ter uma Solução Digital

A ausência de um sistema de filas digital gera impactos mensuráveis:

| Impacto                         | Consequência                                                       |
| ------------------------------- | ------------------------------------------------------------------ |
| **Tempo perdido pelo cliente**    | Média de 20-30 minutos por visita em filas presenciais (IBGE, 2023) |
| **Taxa de desistência**           | Estimativa de 30% dos clientes desistem de espera superior a 15 min |
| **Perda de receita**              | Cada cliente que desiste representa receita direta perdida          |
| **Custo de mão de obra**          | Staff dedicado a gerenciar fila em vez de atender                   |
| **Falta de inteligência**         | Decisões tomadas sem dados sobre demanda e tempos                   |
| **Experiência do cliente**        | NPS (Net Promoter Score) impactado negativamente pela espera        |

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

## Objetivo do Trabalho

Este trabalho tem como objetivo desenvolver e validar o **Qio** como solução para o problema de gerenciamento de filas presenciais, abordando:

- Arquitetura de software distribuído com comunicação em tempo real
- Experiência do usuário em dois contextos distintos (proprietário no app, cliente no navegador)
- Uso de tecnologias serverless para redução de custos e complexidade de infraestrutura
- Notificações push em ambiente web (Progressive Web App)
- Validação do MVP com usuários reais

## Estrutura do Documento

As seções seguintes detalham a arquitetura do sistema, as tecnologias utilizadas, o modelo de dados, os fluxos de comunicação entre módulos e as decisões de projeto tomadas durante o desenvolvimento.
