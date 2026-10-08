# Teste de usabilidade do Qio

Material para planejar, aplicar e relatar testes de usabilidade com donos/operadores (app Flutter) e clientes (web). Responde à issue #168.

**Estado:** material pronto; **nenhum ciclo foi executado até agora**. Não há resultados de usabilidade neste repositório. O que foi medido até aqui é técnico (ver [`../qualidade.md`](../qualidade.md)).

## Objetivo

1. Verificar se donos e operadores conseguem, sem ajuda, instalar o app, criar uma fila, imprimir o QR, chamar o próximo e finalizar atendimentos.
2. Verificar se clientes conseguem, sem instalar nada, escanear o QR, entrar na fila, entender posição e espera, perceber o aviso de chamada e sair da fila.
3. Medir a percepção geral de usabilidade com o System Usability Scale (SUS).
4. Transformar os problemas observados em issues com severidade.

## Método

Teste de usabilidade moderado, presencial ou remoto, com observação e protocolo "pensar em voz alta".

- Cada participante recebe um cenário e as tarefas de [`roteiro-tarefas.md`](./roteiro-tarefas.md), uma por vez, sem instruções de como fazer.
- O moderador registra tempo, sucesso, erros e comentários em [`ficha-observacao.md`](./ficha-observacao.md). Ajuda dada pelo moderador conta como sucesso assistido, não como sucesso.
- Ao final, o participante responde o SUS ([`formulario-sus.md`](./formulario-sus.md)).
- Antes de tudo, o participante lê e aceita o [`termo-consentimento.md`](./termo-consentimento.md).
- Os dados vão para [`resultados-modelo.csv`](./resultados-modelo.csv) e o relatório segue [`relatorio-modelo.md`](./relatorio-modelo.md).

## Participantes alvo

| Perfil | Meta | Observação |
| --- | --- | --- |
| Donos e operadores de estabelecimentos com atendimento por ordem de chegada | 5 a 8 | Incluir ao menos 1 operador (entra por código de convite) |
| Clientes finais | 15 a 20 | Variar idade, familiaridade com celular e sistema (Android/iOS) |

Esses números são metas de planejamento, não um resultado. Com amostras pequenas, os achados são qualitativos e o escore SUS é indicativo, sem inferência estatística.

## Ciclos

Planejados 2 a 3 ciclos curtos (um por rodada de correções):

1. **Ciclo 1:** linha de base com o produto atual. Corrigir os achados críticos e altos.
2. **Ciclo 2:** repetir as tarefas com falha e comparar tempo, sucesso e SUS com o ciclo 1.
3. **Ciclo 3 (opcional):** verificação final.

Em cada ciclo, usar participantes novos para tarefas de descoberta; o mesmo participante só deve repetir se o objetivo for medir aprendizado, e isso deve ser registrado.

## Ambiente

- Usar uma fila de teste criada para o ciclo; evitar o ambiente de produção com dados reais.
- Registrar versão do app (`app/pubspec.yaml`), commit do web publicado e dispositivos usados.
- Não gravar tela ou áudio sem autorização expressa no termo.

## Cuidados éticos e LGPD

Ver [`termo-consentimento.md`](./termo-consentimento.md). Identificar participantes por código (ex.: D01, C07), sem nome nem telefone na planilha. Revisar com o orientador e, se aplicável, com o Comitê de Ética em Pesquisa (CEP) antes do primeiro ciclo.

## Pendências do dono

- [ ] Definir datas, local e estabelecimentos de recrutamento.
- [ ] Validar tempos-alvo do roteiro após um ensaio piloto com 1 ou 2 pessoas.
- [ ] Revisar o termo com o orientador/CEP.
- [ ] Decidir se haverá gravação (e ajustar o termo).
- [ ] Citar a fonte da tradução pt-BR do SUS usada.
- [ ] Registrar resultados do ciclo 1 e abrir as issues dos achados.

## Documentos relacionados

[`../qualidade.md`](../qualidade.md) · [`../testes/casos-de-teste.md`](../testes/casos-de-teste.md) · [`../arquitetura/limitacoes-e-trabalhos-futuros.md`](../arquitetura/limitacoes-e-trabalhos-futuros.md)
