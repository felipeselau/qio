# Limitações e trabalhos futuros

Fontes: [`../qualidade.md`](../qualidade.md) §5, `CLAUDE.md`, a issue #96 (backlog avaliado e adiado) e o roadmap #173. O estado das issues é o do momento da escrita (08/10/2026); conferir no GitHub antes de citar. Ver também [`modelo-de-ameacas.md`](./modelo-de-ameacas.md) e [`comparativo-concorrentes.md`](./comparativo-concorrentes.md).

## 1. Limitações atuais

### Evidência

- **Sem validação com usuários.** Não há teste de usabilidade executado nem piloto em estabelecimento real; o plano está em [`../usabilidade/`](../usabilidade/README.md) (#168, #169). Qualquer afirmação de ganho de tempo de espera ou de satisfação é **não medida**.
- Casos manuais foram executados na v1.1.0 e não foram reexecutados para as funcionalidades posteriores; entrega de push em aparelho real (CLI-11, INT-03), iOS (CLI-12) e App Check em produção (INT-04) estão pendentes.
- `web/` tem 10 arquivos de teste (vitest) rodando no CI (#140), mas `qualidade.md` ainda os lista como inexistentes (atualização em #171) e a cobertura da web não foi medida. A cobertura do app (60,11% das linhas) não entra no CI.

### Segurança e abuso

- **Auth anônima não prova presença física**: quem tem o link ou uma foto do QR entra remotamente. Rate limit e validação mitigam, não eliminam.
- **App Check implementado, mas sem enforcement** (`ENFORCE_APP_CHECK=false`); só vale para as callables, nunca para RTDB/Firestore/Storage, porque o APK fora da Play Store não passa no Play Integrity.
- Limite de 20 filas por dono e de 20 grupos checados só no app.

### Consistência e arquitetura

- **Dual-write** Firestore + RTDB sem transação entre os dois; divergência possível até o próximo `ensureMirror`.
- Contagem de `maxWaiting` e de vagas por slot sem transação (passa 1 a 2 vagas).
- Triggers separados sobre `entries` (`syncPublicTicket`, `onEntryCalled`, `onQueueAdvanced`) e `functions/index.js` e `QueuePage.tsx` grandes (#165).
- Reserva da chamada e avanço de `meta/serving` são transações separadas.
- Slots diários em fuso fixo `America/Sao_Paulo`, sem data nem reagendamento.

### Produto e dados pessoais (LGPD)

- Sem política de privacidade, termos nem aviso no formulário (#159).
- `history` e `feedback` sem prazo de expiração; CSV/PDF exportam telefone (#160).
- Sem fluxo de direitos do titular (acesso, correção, eliminação) (#162).
- Sem entrada manual pelo operador: cliente sem celular não consegue entrar (#154).
- Entradas esquecidas não expiram sozinhas (#155).
- Sem SMS/WhatsApp, vários guichês/serviços, log de auditoria ou scanner de QR no app (itens avaliados e adiados em #96).
- Sem integração externa nem API.

### Plataforma e operação

- Push web no iOS só com a PWA instalada (16.4+); deep links só em Android; PWA sem uso offline.
- Deploy de functions e rules manual, com ordem que importa; hosting depende de `FIREBASE_TOKEN` no CI (#166). Backups e alerta de orçamento não confirmados (#163).
- Relatórios em CSV usam vírgula e ponto decimal, o que atrapalha no Excel pt-BR.

## 2. Trabalhos futuros priorizados

Prioridade sugerida pelo autor, com base em risco para o TCC e para um eventual piloto. É uma proposta, sujeita às decisões pendentes em #172.

| Prioridade | Item | Issue | Por quê |
| --- | --- | --- | --- |
| 1 | Teste de usabilidade (ciclo 1) com SUS | #168 | Principal lacuna de evidência |
| 1 | Piloto com coleta das métricas do próprio Qio | #169 | Dados reais de espera e uso |
| 1 | Política de privacidade, retenção e direitos do titular | #159, #160, #162 | Pré-requisito de qualquer piloto com dados pessoais |
| 2 | Decidir e ligar o enforcement de App Check nas callables, após medir 3 a 7 dias | #172 (item 6), `../APPCHECK.md` | Fecha o vetor de scripts/bots |
| 2 | Exclusão robusta de fila e de conta | #161 | Obrigação em loja de apps e LGPD |
| 2 | Entrada manual pelo operador e expiração de entradas | #154, #155 | Gaps operacionais no uso diário |
| 2 | Backups, alerta de orçamento e restauração | #163 | Risco de custo e de perda de dados |
| 3 | Eliminar o dual-write por trigger Firestore para RTDB | #164 | Reduz inconsistência; esforço grande |
| 3 | Consolidar triggers e dividir arquivos grandes | #165 | Manutenibilidade |
| 3 | Cobertura de testes no CI e build de APK em PRs que mudam dependências | #139 | Fecha lacuna de qualidade |
| 3 | Avisos quando a fila está fechada ("me avise quando abrir") e reivindicar a própria senha | #146, #145 | Melhorias de UX do cliente |
| 4 | Link curto/slug, cartaz melhor e widget público de espera | #156, #157 | Valor de produto, não de TCC |
| 4 | Deploy automatizado com staging | #166 | Só se virar produto (#172, item 1) |
| 4 | SMS/WhatsApp, vários guichês, log de auditoria, scanner de QR | #96 | Adiados até haver demanda e consentimento |

Ideias de mitigação para o risco de entradas remotas, ainda sem issue: QR com token rotativo de curta duração e geolocalização na entrada (`../RESUMO_TECNICO.md` §6).

## 3. Decisões que dependem do dono

Listadas em #172: escopo (TCC ou produto), controlador dos dados e prazo de retenção, política para telefone, público (só Brasil?), prazo de expiração, data do enforcement do App Check, publicação na Play Store, piloto e deploy automático.
