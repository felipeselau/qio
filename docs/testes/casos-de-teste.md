# Casos de teste — Qio v1.1.0

Ambiente de produção: `https://qio.web.app` (hosting site `qio`, projeto `qio-app`),
app Flutter v1.1.0. Rules publicadas em 30/09/2026 (commit `e8fdc9c`), hosting
publicado em 30/09/2026 (commit `44e8b2d`).

Situação: **Aprovado** (executado, resultado = esperado), **Reprovado**
(executado, resultado ≠ esperado), **Pendente** (aguardando execução manual),
**Bloqueado** (não executável no ambiente atual). Um caso só tem "Resultado
obtido" depois de executado.

## Testes automatizados

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AUT-01 | Sistema | Testes unitários do app (modelos e lógica pura) | `cd app && flutter test` | Todos passam | 48 testes, todos passaram | Aprovado | 30/09/2026 |
| AUT-02 | Sistema | Análise estática do app | `cd app && flutter analyze lib test` | Nenhum problema | "No issues found!" | Aprovado | 30/09/2026 |
| AUT-03 | Sistema | Lint e build da página web | `cd web && npm run lint && npm run build` | Sem erros | oxlint sem erros (exit 0); build Vite concluído | Aprovado | 30/09/2026 |
| AUT-04 | Sistema | Rules do Firestore e do RTDB no emulator | `cd rules-tests && npm test` | Todos passam | 67 testes, 67 passaram, 0 falhas | Aprovado | 30/09/2026 |
| AUT-05 | Sistema | Os testes de rules detectam regressão | Remover `operatorId == auth.uid` da rule de `history` e rodar AUT-04 | Ao menos 1 teste falha | 1 falha ("operador não cria registro em nome de outro"); rule restaurada | Aprovado | 27/09/2026 |
| AUT-06 | Sistema | CI no PR | Abrir PR para `main` | Jobs `flutter`, `web` e `rules` verdes | Verdes no PR #35 (commit `89b1978`) | Aprovado | 28/09/2026 |

## Cliente (web)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CLI-01 | Cliente | Primeiro acesso pelo QR, em aba anônima | Limpar dados do site, abrir `/q/{id}` | Login anônimo e tela da fila, sem spinner infinito | Com fila inexistente e dados limpos: login anônimo (`accounts:signUp`) e tela "Fila não encontrada" em ~2 s. Antes do deploy de 30/09 o spinner ficava preso (bundle antigo). Falta repetir com fila existente | Aprovado (parcial) | 30/09/2026 |
| CLI-02 | Cliente | Nome vazio | Abrir fila aberta, deixar nome vazio, tocar "Entrar na fila" | Mensagem "Informe seu nome" e nenhuma entry criada | | Pendente | |
| CLI-03 | Cliente | Fila pausada | Dono pausa a fila; cliente abre o link | Badge "Pausada" e botão de entrar desabilitado | | Pendente | |
| CLI-04 | Cliente | Fila encerrada | Dono fecha a fila; cliente sem senha abre o link | Tela de fila fechada | | Pendente | |
| CLI-05 | Cliente | Fila inexistente | Abrir `https://qio.web.app/q/fila-inexistente-teste-2` | "Fila não encontrada" | "Fila não encontrada — Verifique o link ou escaneie o QR code novamente." | Aprovado | 30/09/2026 |
| CLI-06 | Cliente | Link inválido | Abrir `https://qio.web.app/link-qualquer` e `https://qio.web.app/q/` | "Link inválido" | "Link inválido — Escaneie o QR code da fila para entrar." nas duas URLs | Aprovado | 30/09/2026 |
| CLI-07 | Cliente | Acompanhar a posição | Entrar na fila com outras pessoas à frente; dono chama o próximo | Posição e espera estimada diminuem em tempo real | | Pendente | |
| CLI-08 | Cliente | Sair da fila | Com senha ativa, tocar "Sair da fila" e confirmar | Tela "Você saiu da fila"; entry some do painel do dono | | Pendente | |
| CLI-09 | Cliente | Recuperar a senha ao reabrir | Entrar na fila, fechar a aba, abrir o mesmo link | Mesma senha e posição exibidas | | Pendente | |
| CLI-10 | Cliente | Alerta na página | Aba aberta; dono chama a senha | Tela "É a sua vez", som e vibração | | Pendente | |
| CLI-11 | Cliente | Push com a aba em segundo plano (Android/Chrome) | Permitir notificações, minimizar o Chrome, dono chama | Notificação push | Cloud Function `onEntryCalled` não publicada: o projeto está no plano Spark e Functions v2 exigem Blaze | Bloqueado | 30/09/2026 |
| CLI-12 | Cliente | iOS: limitação | Abrir o link no Safari do iPhone | Funciona com alerta na página; push web só com a página instalada na tela inicial (iOS 16.4+) | | Pendente | |

## Dono (app)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DON-01 | Dono | Criar fila | Home → "+" → nome e tempo médio → criar | Fila aparece em "Minhas filas" com status Aberta | | Pendente | |
| DON-02 | Dono | QR | Abrir a fila | QR e link `qio.web.app/q/{id}`; copiar e compartilhar funcionam | | Pendente | |
| DON-03 | Dono | Chamar próximo | Com clientes na fila, tocar "Chamar próximo" | Menor senha vai para "Chamando agora"; cliente é alertado (print 11) | | Pendente | |
| DON-04 | Dono | Atendido | Com senha chamada, tocar "Atendido" | Entry sai do painel e vai para o histórico com `result: served` (print 12) | | Pendente | |
| DON-05 | Dono | Não compareceu | Com senha chamada, tocar "Não compareceu" | Entry sai do painel e vai para o histórico com `result: no_show` (print 12) | | Pendente | |
| DON-06 | Dono | Pausar e encerrar | Tocar "Pausar", depois "Reabrir", depois "Fechar" | Badge muda no app e na web em tempo real | | Pendente | |
| DON-07 | Dono | Excluir fila | Com a fila fechada, "Excluir fila" → confirmar | Fila some da home; link mostra "Fila não encontrada"; operadores perdem a fila | | Pendente | |
| DON-08 | Dono | Histórico com `operatorId` | Após DON-04 e OPE-05, ver `queues/{id}/history` no console | `calledBy` = quem chamou, `operatorId` = quem finalizou | | Pendente | |

## Operador (app)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OPE-01 | Operador | Convite válido | Dono: fila → "Operadores e convites" → gerar código (24 h). Operador: home → ícone de crachá → digitar o código | Tela "Aguardando aprovação" (prints 13 e 14) | | Pendente | |
| OPE-02 | Operador | Convite expirado ou inválido | Digitar código inexistente; depois um código revogado | "Código inválido ou revogado." (expirado: "Código expirado. Peça um novo ao dono.") | Rules no emulator: pedido com convite expirado, de outra fila ou inexistente é negado (AUT-04) | Pendente (UI) | |
| OPE-03 | Dono/Operador | Aprovação | Dono vê o pedido e aprova | Operador vê "Pedido aprovado"; fila aparece em "SOU OPERADOR" (print 15) | | Pendente | |
| OPE-04 | Dono/Operador | Recusa | Dono recusa o pedido | Operador vê "Pedido recusado"; card com opção de dispensar na home | | Pendente | |
| OPE-05 | Operador | Atendimento | Operador abre a fila, chama, marca atendido | Só aparecem "Chamar próximo", "Atendido" e "Não compareceu" (print 16) | | Pendente | |
| OPE-06 | Operador | Tentativa de ação administrativa | Verificar que não há pausar, fechar, excluir nem convite na tela do operador | Controles ausentes; rules negam a escrita | Rules no emulator: operador não altera status nem convite, não exclui a fila, não escreve `meta/status`/`meta/name` (AUT-04) | Pendente (UI) | |
| OPE-07 | Dono/Operador | Remoção no meio do uso | Operador com o painel aberto; dono remove o operador | Operador vê "Acesso encerrado", volta para a home e vê "Você foi removido desta fila" | Rules no emulator: operador removido perde escrita em `meta/serving` e `entries` (AUT-04) | Pendente (UI) | |

## Concorrência

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CON-01 | Cliente | Duas entradas simultâneas | Dois aparelhos com o formulário preenchido tocam "Entrar na fila" ao mesmo tempo | Senhas diferentes e consecutivas (transação em `tickets/{id}`) | | Pendente | |
| CON-02 | Dono/Operador | Dois atendentes chamam ao mesmo tempo | Dono e operador, com 2+ clientes na fila, tocam "Chamar próximo" juntos | Cada um recebe uma senha diferente; `meta/serving` fica na maior | | Pendente | |

## Integração (por fronteira)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| INT-01 | Sistema | Web ↔ RTDB | Cliente anônimo lê `queues/{id}/meta` em produção | Leitura liberada após o login anônimo | SDK web 12.x em produção: login anônimo e `get(queues/{id}/meta)` retornaram `null` para fila inexistente, sem erro de permissão | Aprovado | 30/09/2026 |
| INT-02 | Sistema | App ↔ Firestore/RTDB | Executar DON-01 a DON-05 | Dual-write: Firestore e espelho `meta`/`owners` no RTDB | | Pendente | |
| INT-03 | Sistema | RTDB → Cloud Function → FCM | Executar CLI-11 | Push entregue | Function não publicada (plano Spark) | Bloqueado | 30/09/2026 |
| INT-04 | Sistema | App Check ↔ web | Verificar `VITE_RECAPTCHA_SITE_KEY` no build publicado | App Check ativo | Build publicado sem chave do reCAPTCHA: App Check desativado em produção | Bloqueado | 30/09/2026 |
| INT-05 | Sistema | Operador ↔ rules | Rodar AUT-04 e executar OPE-05 a OPE-07 | Rules liberam só atendimento | Emulator: ver AUT-04 | Pendente (produção) | |

## Limitações conhecidas

- Push com a aba em segundo plano não funciona em produção: o projeto está no
  plano Spark e Cloud Functions v2 exigem Blaze.
- App Check desativado em produção (sem `VITE_RECAPTCHA_SITE_KEY` no build).
- Fila pausada: o bloqueio de entrada é só na interface; as rules do RTDB não
  impedem a criação de entry com a fila pausada.
- O cliente pode alterar campos da própria entry no RTDB (ticket, status).
- Deploy automático do hosting depende do secret `FIREBASE_TOKEN`, que não está
  configurado no repositório.
