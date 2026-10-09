# Privacidade: mapa de dados e pendências

Minuta técnica, não é parecer jurídico. Decisões assumidas (#172): o estabelecimento é o controlador e o Qio é o operador; retenção-alvo do `history` de 180 dias; telefone opcional; exportação sem telefone por padrão (#160, implementada). As páginas públicas são `https://qio.web.app/privacidade` e `/termos` (textos em `web/src/i18n/legal/`).

## Mapa de dados

| Dado | Onde fica | Quem acessa | Retenção | Base (proposta) |
| --- | --- | --- | --- | --- |
| Nome (1-60) e telefone (opcional) da entry | RTDB `queues/{id}/entries/{entryId}` (escrita só pela callable `joinQueue`) | Dono, operadores (`operatorUids`) e o próprio `uid` da entry | Enquanto a entry está ativa; removida ao servir, sair (`left`) ou `deleteQueue` | Execução do serviço / consentimento ao digitar |
| `uid` anônimo, ticket, status, `lang`, `joinedAt`, `calledAt`, slot | Mesma entry | Idem | Idem | Execução do serviço |
| `fcmToken` do cliente (opcional) | Mesma entry | Idem; usado por `onEntryCalled`/`onQueueAdvanced` | Idem | Consentimento (botão "Ativar aviso") |
| Espelho público (ticket, status, order) | RTDB `queues/{id}/public/{entryId}` | Qualquer usuário autenticado; sem nome nem telefone | Enquanto `waiting`/`called` | Execução do serviço |
| Histórico (ticket, nome, telefone, resultado, horários, `calledBy`, `operatorId`, `recalls`, `skips`) | Firestore `queues/{id}/history/{entryId}` (app; `left` via trigger Admin) | Dono (leitura/escrita); operador cria `served`/`no_show` | 180 dias por padrão (`queues/{id}.retentionDays`, 30-730), expurgo diário por `purgeOldHistory`; apagado em `deleteQueue`; telefone omitido se `anonymizePhone` (inclusive `left` arquivado pelo trigger Admin) | Interesse do controlador / execução; revisar |
| Avaliação (nota, comentário, `uid`, `createdAt`) | Firestore `queues/{id}/feedback/{entryId}` (callable `submitFeedback`) | Só o dono lê/apaga | Mesmo prazo do `history` (`createdAt`), expurgo por `purgeOldHistory`; ou até o dono apagar / `deleteQueue` | Consentimento (envio voluntário) |
| Limite de tentativas (timestamps por `uid`) | RTDB `rateLimits/{queueId}/{uid}` | Só Admin (rules fecham leitura/escrita) | **Não removido por `deleteQueue`** nem expurgado | Segurança / abuso |
| Sessão anônima | Firebase Authentication (navegador) | Firebase/Google | Até limpar dados do site | Execução do serviço |
| Preferências e referência da entry | `localStorage`: `qio:entries`, `qio:feedback`, `qio:lang`, `qio:theme`, `qio:install-dismissed`, `qio:analytics-optout` | Só o navegador do titular | Até limpar dados do site | Execução / preferência |
| Estatísticas de uso | Google Analytics, só em build de produção com `VITE_MEASUREMENT_ID`, sem Do Not Track e sem opt-out | Estabelecimento/projeto via GA4 | Conforme configuração do GA4 | Consentimento (opt-out no rodapé) |
| Token push do dono | Firestore `owners/{uid}/devices/{token}` | Só o próprio dono | Até sair da conta ou token inválido | Consentimento (opt-in no app) |
| Pedido "avise quando abrir" (token FCM, idioma, `createdAt`; sem nome/telefone) | RTDB `queues/{id}/openWatchers/{uid}` | O próprio `uid` lê/grava/apaga; dono lê; trigger Admin envia | Até a fila abrir (apagado após o envio), 24 h (ignorado depois disso) ou `deleteQueue` | Consentimento (opt-in no navegador) |

Suboperador: Firebase/Google Cloud (Auth, RTDB, Firestore, Functions, FCM, Hosting, Analytics). Região das functions: us-central1; confirmar localização do RTDB/Firestore.

## Lacunas encontradas no código

- `deleteQueue` não limpa `rateLimits/{queueId}`.
- `history` guarda telefone completo, salvo se o dono ligar "Não guardar telefone no histórico" (`anonymizePhone`); registros já arquivados não são alterados. `retentionDays` não tem tela: só Admin/console. CSV/PDF saem sem telefone; incluir exige confirmação explícita.
- Exclusão de conta no app é a #161.

## Pendências do dono

1. Definir `VITE_PRIVACY_CONTACT` (e-mail ou URL https) em GitHub, Settings, Variables, Actions e em `web/.env.local`; sem ele a página mostra "contate o estabelecimento".
2. Preencher a data de vigência (placeholder `[data de vigência]` em `web/src/i18n/legal/*.ts`).
3. Revisar os textos com o orientador/jurídico e remover o cabeçalho "Minuta técnica" só depois disso.
4. Fazer o deploy de `purgeOldHistory` (ver CLAUDE.md, "Retenção e anonimização"); o expurgo só passa a valer depois disso.
5. Confirmar o texto sobre menores de 12 anos, a base legal e a localização dos dados.
6. Fazer deploy do hosting; no Play Console, usar a URL `https://qio.web.app/privacidade` se publicar.
7. Regerar os goldens do login (`test/goldens/login_*`) pelo artifact do CI, pois a tela ganhou os links.

## Como atender um pedido do titular (acesso, correção, eliminação)

O cliente é anônimo e não tem conta, então o canal do titular é o estabelecimento (controlador). O Qio (operador) fornece a ferramenta "Dados de um cliente" no app do dono (Minha conta). Só o dono usa; operadores não veem. Prazo legal sugerido para responder: 15 dias.

1. Confirme a identidade do titular por um meio seu (por exemplo, ligar para o telefone informado). A ferramenta não prova identidade.
2. No app: Minha conta, "Dados de um cliente". Digite o telefone (a máscara é automática) e toque em Buscar. O app pede login recente (até 5 min) e pode pedir a senha de novo.
3. O resultado mostra, por fila sua, quantos registros de histórico, avaliações e entradas ativas existem e o período. Não mostra dados de outros donos.
4. Acesso: "Exportar dados (CSV)" gera nome, telefone, horários, resultado, nota e comentário. Entregue o arquivo ao titular por canal seguro.
5. Correção: o histórico é registro de atendimento. Para corrigir um nome ou telefone errado, anonimize ou exclua os registros e, se o titular quiser, ele entra na fila de novo com os dados corretos.
6. Eliminação: "Anonimizar" troca o nome por "Anônimo", remove o telefone do histórico e apaga o comentário da avaliação (a nota fica, sem vínculo). "Excluir" apaga histórico e avaliações. Nos dois casos a entrada ativa na fila é removida. Para confirmar, digite o telefone de novo. Não dá para desfazer.
7. Responda ao titular dentro do prazo e guarde o registro: cada consulta, exportação e eliminação grava `owners/{uid}/dataRequests/{id}` (ação, modo, contagens por fila, hash do telefone e data), sem nome nem telefone. Só o dono lê.

Limites conhecidos:

- A busca é exata pelo telefone, nas duas formas: máscara `(11) 99999-9999` (a única que o `joinQueue`, o `addManualEntry` e as rules gravam hoje) e só dígitos. A forma só-dígitos é mantida só por tolerância a dados legados que não conseguimos descartar; não migramos dados antigos.
- Registros de `history` sem telefone (fila com `anonymizePhone`, ou já anonimizados) não são encontrados. Por isso o `feedback` desses atendimentos também não: ele só é alcançado pelo `entryId` de um history achado pelo telefone.
- "Anonimizar" apaga o comentário do feedback, mas mantém `rating`, `uid` (anônimo do navegador) e `createdAt`. Se isso for demais para o caso, use "Excluir".
- Corrida com o trigger `syncPublicTicket`: se o cliente sair da fila (`left`) no instante da eliminação, o trigger pode gravar um `history` novo com o telefone depois da varredura. Repita a busca após alguns segundos e elimine de novo se aparecer.
- Se a gravação do log de auditoria falhar, a ação continua valendo e a resposta é devolvida; o erro vai para o log de erros (sem PII). Em eliminação parcial o log traz `failedQueueIds`.
- O limite é de 20 pedidos por hora por conta (`rateLimits/_dsr/{uid}`, apagado junto com a conta).
- Backups (`docs/backup.md`) podem reter os dados até expirarem.
- O hash do telefone no log é pseudonimização, não anonimização: SHA-256 de `pepper:uid:telefone`. O pepper (`DSR_HASH_PEPPER`, opcional, segredo) dificulta a reversão por força bruta; sem ele, trate o log como dado pessoal. Excluir a conta apaga o log.
