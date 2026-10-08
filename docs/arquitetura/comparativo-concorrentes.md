# Comparativo com alternativas de gestão de fila

Responde à issue #170 (parte comparativa). Este documento **não é uma pesquisa de mercado**: compara o Qio com categorias e produtos pelo que é publicamente conhecido, e marca como **verificar na fonte** tudo que o autor não confirmou diretamente. As informações sobre o Qio vêm do repositório (`CLAUDE.md`, `docs/RESUMO_TECNICO.md`, `docs/qualidade.md`).

**Data da consulta às fontes dos concorrentes:** `____/____/______` (a preencher pelo dono). Até preencher, trate todas as células de terceiros como não verificadas.

## Alternativas comparadas

| Alternativa | O que é | Fonte para conferir |
| --- | --- | --- |
| **Qio** | Fila presencial; dono usa app Flutter, cliente usa página web via QR | Este repositório |
| **Qminder** | Produto SaaS de gestão de filas e fluxo de visitantes | Site oficial do produto (URL a preencher) |
| **Waitwhile** | Produto SaaS de lista de espera virtual e agendamento | Site oficial do produto (URL a preencher) |
| **Senha de papel / totem** | Ficha numerada física ou totem de emissão de senha com painel | Não aplicável (categoria genérica) |

## Tabela de critérios

Legenda: **(V)** verificado neste repositório; **(VF)** verificar na fonte, informação pública não confirmada pelo autor.

| Critério | Qio | Qminder | Waitwhile | Senha de papel / totem |
| --- | --- | --- | --- | --- |
| Instalação para o cliente | Nenhuma: abre a página pelo QR no navegador, auth anônima (V). iOS: push só com PWA instalada (V) | Em geral o cliente não instala app; entrada por tablet/quiosque, link ou QR e avisos por SMS (VF) | Em geral o cliente entra por link/QR e é avisado por SMS (VF) | Nenhuma; o cliente retira a senha no local |
| Instalação para o estabelecimento | Dono instala o app Flutter (APK; sem Play Store até agora, V); operador entra por código de convite (V) | Painel web e apps para equipe (VF) | Painel web e apps para equipe (VF) | Papel ou equipamento (totem, impressora, painel) |
| Custo | Código próprio; infraestrutura Firebase (plano Blaze) dentro da cota gratuita no volume do TCC (V, ver `RESUMO_TECNICO.md` §9). Sem preço de produto definido (decisão #172) | Assinatura (planos e preços: VF) | Assinatura, pode haver plano gratuito limitado (VF) | Custo de papel ou de hardware e manutenção; sem mensalidade de software |
| Tempo real | Sim: RTDB com listeners para posição e chamada (V) | Sim (VF) | Sim (VF) | Painel/chamada presencial; sem acompanhamento remoto |
| Notificações ao cliente | Push web (FCM, opt-in) e alerta sonoro/vibração com a página aberta (V). Sem SMS/WhatsApp (decisão em #96). Entrega em aparelho real ainda não validada (V, `qualidade.md` §4) | SMS e outros canais (VF) | SMS e outros canais (VF) | Painel sonoro/visual no local; o cliente precisa ficar por perto |
| Métricas | Espera média/mediana/P90, atendimento, não comparecimento, por atendente, heatmap, tendência, exportação CSV/PDF (V) | Relatórios e análises (VF) | Relatórios e análises (VF) | Manual ou inexistente |
| LGPD / privacidade | Dados mínimos (nome; telefone opcional); `public/` sem PII; rules por papel (V). Faltam política de privacidade, retenção do `history` e direitos do titular (V, #159 a #162) | Política e conformidade do fornecedor (VF; operador/controlador a definir no contrato) | Idem (VF) | Sem dado pessoal, a menos que se anote nome ou telefone |
| Integração | Sem API pública nem integração com agenda ou outros sistemas (V). Agendamento só por slots diários (V) | Integrações e API (VF) | Integrações e API (VF) | Nenhuma |
| Vários guichês/serviços | Não (avaliado e adiado, #96) | Sim (VF) | Sim (VF) | Depende do equipamento |
| Maturidade e suporte | Projeto acadêmico, um desenvolvedor, sem piloto em estabelecimento real (#169) | Produto comercial com suporte (VF) | Produto comercial com suporte (VF) | Prática consolidada |

## Ponto forte do Qio

O cliente **não instala nada e não cria conta**: escaneia o QR, informa o nome (telefone é opcional) e acompanha posição e espera na própria página, com aviso por push opcional. Para um estabelecimento pequeno isso reduz a barreira de entrada do lado do cliente, e a identificação anônima mantém o volume de dados pessoais baixo. Esse é o diferencial defendido no TCC; **não há ainda teste de usabilidade que o comprove** (ver [`../usabilidade/`](../usabilidade/README.md)).

## Limitações reais do Qio frente às alternativas

Resumo; detalhes e priorização em [`limitacoes-e-trabalhos-futuros.md`](./limitacoes-e-trabalhos-futuros.md).

- Sem SMS/WhatsApp: se o cliente fecha a página e não ativou o push, não é avisado. No iOS o push exige PWA instalada.
- Um guichê por fila: sem múltiplos serviços ou guichês (#96).
- Presença física não é provada: quem tem o link ou a foto do QR entra remotamente (rate limit e validação mitigam).
- LGPD incompleta: sem política publicada, sem prazo de retenção do `history` e sem fluxo de direitos do titular; CSV/PDF exportam telefone.
- Sem validação com usuários reais nem piloto: não há dado de adoção, satisfação ou redução de espera.
- App Check implementado nas callables, mas **sem enforcement**.
- Sem API ou integrações; sem painel multi-loja/organização; entrada manual pelo operador (cliente sem celular) ainda não existe (#154).
- Operação: deploy de functions e rules é manual; cobertura de testes não é medida no CI.

## Pendências do dono

- [ ] Preencher a data da consulta e as URLs oficiais de cada produto.
- [ ] Conferir cada célula marcada (VF) nos sites e nas páginas de preço, e trocar por dado verificado ou "não confirmado".
- [ ] Decidir se a comparação será por produto ou apenas por categoria (SaaS de fila com SMS / senha de papel e totem).
- [ ] Se citar preços, registrar moeda, plano e data.
