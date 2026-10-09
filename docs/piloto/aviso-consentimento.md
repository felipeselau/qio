# Aviso ao cliente e termo do estabelecimento (minuta)

> **Minuta técnica, revisar com orientador/jurídico antes do uso.** Não é parecer jurídico nem de comitê de ética. Alinhada a [`../privacidade.md`](../privacidade.md): o estabelecimento é o controlador dos dados dos clientes e o Qio é o operador; telefone é opcional; exportações saem sem telefone. As páginas públicas `https://qio.web.app/privacidade` e `/termos` também são minuta. Itens entre colchetes são do pesquisador.

## 1. Aviso ao cliente (cartaz A4 ao lado do QR)

> **Fila digital do [nome do estabelecimento]**
>
> Para entrar na fila você informa seu **nome** (obrigatório) e, se quiser, seu **telefone**. Usamos esses dados só para chamar você e organizar o atendimento. O **aviso no navegador** é opcional e só funciona se você permitir.
>
> Este local participa de um **piloto de pesquisa acadêmica** ([TCC, instituição]). Medimos, sem identificar você, tempo de espera, comparecimento e avaliações (★) para estudar o sistema. Telefones não entram nos relatórios.
>
> Seus dados saem da fila quando você é atendido ou sai dela. O registro do atendimento fica guardado por até [180] dias e depois é apagado.
>
> Você pode **sair da fila** quando quiser e **pedir acesso, correção ou eliminação** dos seus dados ao estabelecimento: [contato do estabelecimento]. Mais informações: `qio.web.app/privacidade`.
>
> Prefere não usar o celular? Peça ao atendente que te coloque na fila.

Conferir antes de imprimir:

- Prazo de retenção real da fila (`retentionDays`, padrão 180).
- Se "Não guardar telefone no histórico" está ligado (então ajustar a frase).
- Contato do titular (estabelecimento) e contato de privacidade do Qio (`VITE_PRIVACY_CONTACT`).
- Regra para menores de idade (a minuta pública menciona 12 anos: confirmar).

## 2. Termo de autorização do estabelecimento

**Pesquisa:** piloto do Qio em estabelecimento real (TCC). **Pesquisador:** [nome] · **Orientador:** [nome] · **Instituição:** [nome]

O estabelecimento [razão social/nome], por [nome do responsável, cargo], autoriza:

1. Uso do Qio de [data] a [data] em [local].
2. Coleta e análise de métricas de uso (espera, atendimento, não comparecimento, desistência, avaliações) de forma agregada, sem nome nem telefone de clientes.
3. Entrevista com o responsável e o operador e observação no local, com registro escrito. Gravação de áudio/imagem: [não / sim, com autorização específica].
4. Citação do estabelecimento no TCC como: [nome identificado / anonimizado como "Estabelecimento A"].

Compromissos do estabelecimento: fixar o aviso do item 1; atender pedidos de titulares (o Qio oferece a ferramenta "Dados de um cliente" no app do dono; passo a passo em [`../privacidade.md`](../privacidade.md)); poder interromper o piloto quando quiser, sem prejuízo.

Compromissos do pesquisador: não acessar nome ou telefone de clientes além do necessário ao suporte; não exportar telefone; guardar os dados por [prazo] em [local]; excluir a fila ou as exportações ao fim, conforme combinado.

Base legal prevista: [execução do serviço/legítimo interesse do estabelecimento para a fila; consentimento para telefone, aviso e pesquisa]. **Conferir com orientador/jurídico.** Avaliar necessidade de CEP.

Local e data: ____________  Responsável: ____________________  Pesquisador: ____________________

## 3. Operadores

Cada operador recebe explicação verbal e escrita do que o piloto mede (volume e tempos por fila, não desempenho individual) e confirma: ☐ Li e concordo. Código: ________ Data: ___/___/______.
