# Privacidade: mapa de dados e pendências

Minuta técnica, não é parecer jurídico. Decisões assumidas (#172): o estabelecimento é o controlador e o Qio é o operador; retenção-alvo do `history` de 180 dias; telefone opcional; exportação sem telefone por padrão (#160, implementada). As páginas públicas são `https://qio.web.app/privacidade` e `/termos` (textos em `web/src/i18n/legal/`).

## Mapa de dados

| Dado | Onde fica | Quem acessa | Retenção | Base (proposta) |
| --- | --- | --- | --- | --- |
| Nome (1-60) e telefone (opcional) da entry | RTDB `queues/{id}/entries/{entryId}` (escrita só pela callable `joinQueue`) | Dono, operadores (`operatorUids`) e o próprio `uid` da entry | Enquanto a entry está ativa; removida ao servir, sair (`left`) ou `deleteQueue` | Execução do serviço / consentimento ao digitar |
| `uid` anônimo, ticket, status, `lang`, `joinedAt`, `calledAt`, slot | Mesma entry | Idem | Idem | Execução do serviço |
| `fcmToken` do cliente (opcional) | Mesma entry | Idem; usado por `onEntryCalled`/`onQueueAdvanced` | Idem | Consentimento (botão "Ativar aviso") |
| Espelho público (ticket, status, order) | RTDB `queues/{id}/public/{entryId}` | Qualquer usuário autenticado; sem nome nem telefone | Enquanto `waiting`/`called` | Execução do serviço |
| Histórico (ticket, nome, telefone, resultado, horários, `calledBy`, `operatorId`, `recalls`, `skips`) | Firestore `queues/{id}/history/{entryId}` (app; `left` via trigger Admin) | Dono (leitura/escrita); operador cria `served`/`no_show` | 180 dias por padrão (`queues/{id}.retentionDays`, 30-730), expurgo diário por `purgeOldHistory`; apagado em `deleteQueue`; telefone omitido se `anonymizePhone` | Interesse do controlador / execução; revisar |
| Avaliação (nota, comentário, `uid`, `createdAt`) | Firestore `queues/{id}/feedback/{entryId}` (callable `submitFeedback`) | Só o dono lê/apaga | Mesmo prazo do `history` (`createdAt`), expurgo por `purgeOldHistory`; ou até o dono apagar / `deleteQueue` | Consentimento (envio voluntário) |
| Limite de tentativas (timestamps por `uid`) | RTDB `rateLimits/{queueId}/{uid}` | Só Admin (rules fecham leitura/escrita) | **Não removido por `deleteQueue`** nem expurgado | Segurança / abuso |
| Sessão anônima | Firebase Authentication (navegador) | Firebase/Google | Até limpar dados do site | Execução do serviço |
| Preferências e referência da entry | `localStorage`: `qio:entries`, `qio:feedback`, `qio:lang`, `qio:theme`, `qio:install-dismissed`, `qio:analytics-optout` | Só o navegador do titular | Até limpar dados do site | Execução / preferência |
| Estatísticas de uso | Google Analytics, só em build de produção com `VITE_MEASUREMENT_ID`, sem Do Not Track e sem opt-out | Estabelecimento/projeto via GA4 | Conforme configuração do GA4 | Consentimento (opt-out no rodapé) |
| Token push do dono | Firestore `owners/{uid}/devices/{token}` | Só o próprio dono | Até sair da conta ou token inválido | Consentimento (opt-in no app) |

Suboperador: Firebase/Google Cloud (Auth, RTDB, Firestore, Functions, FCM, Hosting, Analytics). Região das functions: us-central1; confirmar localização do RTDB/Firestore.

## Lacunas encontradas no código

- `deleteQueue` não limpa `rateLimits/{queueId}`.
- `history` guarda telefone completo, salvo se o dono ligar "Não guardar telefone no histórico" (`anonymizePhone`); registros já arquivados não são alterados. CSV/PDF saem sem telefone; incluir exige confirmação explícita.
- Exclusão de conta no app é a #161.

## Pendências do dono

1. Definir `VITE_PRIVACY_CONTACT` (e-mail ou URL https) em GitHub, Settings, Variables, Actions e em `web/.env.local`; sem ele a página mostra "contate o estabelecimento".
2. Preencher a data de vigência (placeholder `[data de vigência]` em `web/src/i18n/legal/*.ts`).
3. Revisar os textos com o orientador/jurídico e remover o cabeçalho "Minuta técnica" só depois disso.
4. Fazer o deploy de `purgeOldHistory` (ver CLAUDE.md, "Retenção e anonimização"); o expurgo só passa a valer depois disso.
5. Confirmar o texto sobre menores de 12 anos, a base legal e a localização dos dados.
6. Fazer deploy do hosting; no Play Console, usar a URL `https://qio.web.app/privacidade` se publicar.
7. Regerar os goldens do login (`test/goldens/login_*`) pelo artifact do CI, pois a tela ganhou os links.
