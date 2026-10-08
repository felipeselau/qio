# Casos de teste — Qio

Versão atual do app em `main`: 1.4.0+5 (`app/pubspec.yaml`). Os testes automatizados
(AUT-01 a AUT-08) foram reexecutados em 08/10/2026 sobre `main` (commit `8948214`).
Os casos manuais e de integração (CLI, DON, OPE, CON, INT) foram executados entre
30/09 e 01/10/2026 contra o ambiente de produção (`https://qio.web.app`, hosting
site `qio`, projeto `qio-app`) e os emulators, com o app Flutter v1.1.0 (rules
publicadas em 30/09/2026, commit `e8fdc9c`; hosting em 30/09/2026, commit
`44e8b2d`). **Não foram reexecutados** para as funcionalidades posteriores à
1.1.0 (push do dono, branding, horário de funcionamento, limite de fila,
re-chamada, grupos, alertas, slots, métricas novas, exportação das métricas,
App Check nas callables). Para essas, a cobertura é a dos testes automatizados;
números em [`../qualidade.md`](../qualidade.md).

Casos marcados **[emulator]** rodaram localmente nos emulators do Firebase
(auth, Firestore, RTDB) com as rules do repositório, o app Flutter compilado
para web e a página do cliente, no navegador do Claude Code. Ver
`ambiente-emulator.md`. Os prints desses casos têm a faixa "Running in emulator
mode".

Situação: **Aprovado** (executado, resultado = esperado), **Reprovado**
(executado, resultado ≠ esperado), **Pendente** (aguardando execução manual),
**Bloqueado** (não executável no ambiente atual). Um caso só tem "Resultado
obtido" depois de executado.

## Testes automatizados

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AUT-01 | Sistema | Testes do app (unidade, widget e goldens) | `cd app && flutter test` | Todos passam | 451 testes em 56 arquivos, todos passaram (era 48 em 30/09/2026) | Aprovado | 08/10/2026 |
| AUT-02 | Sistema | Análise estática do app | `cd app && flutter analyze lib test` | Nenhum problema | "No issues found!" | Aprovado | 08/10/2026 |
| AUT-03 | Sistema | Lint e build da página web | `cd web && npm run lint && npm run build` | Sem erros | oxlint sem erros (exit 0); build Vite concluído (aviso de chunk > 500 kB) | Aprovado | 08/10/2026 |
| AUT-04 | Sistema | Rules (Firestore, RTDB, Storage) e callable `joinQueue` nos emulators | `cd rules-tests && npm test` (duas passadas: `test:rules` e `test:callable`) | Todos passam | 167 testes das rules + 28 da callable = 195, 0 falhas (era 67 em 30/09/2026). Executado com firebase.json temporário em outras portas porque 5001/8080/9000 estavam ocupadas | Aprovado | 08/10/2026 |
| AUT-05 | Sistema | Os testes de rules detectam regressão | Remover `operatorId == auth.uid` da rule de `history` e rodar AUT-04 | Ao menos 1 teste falha | 1 falha ("operador não cria registro em nome de outro"); rule restaurada | Aprovado | 27/09/2026 |
| AUT-06 | Sistema | CI no PR | Abrir PR para `main` | Jobs `flutter`, `web`, `functions` e `rules` verdes | Verdes no PR #35 (commit `89b1978`, 28/09/2026); nas 14 execuções recentes de `ci.yml`, 13 terminaram em sucesso e 1 em falha (ver `docs/qualidade.md`) | Aprovado | 08/10/2026 |
| AUT-07 | Sistema | Testes das Cloud Functions (lógica pura) | `cd functions && npm test` | Todos passam | 155 testes em 14 arquivos, todos passaram | Aprovado | 08/10/2026 |
| AUT-08 | Sistema | Cobertura | `cd app && flutter test --coverage`; `cd functions && node --test --experimental-test-coverage` | Medir | App: 60,11% das linhas instrumentadas (4761/7920); functions `src/`: 99,91% de linhas. Ver `docs/qualidade.md` | Aprovado (medição) | 08/10/2026 |

## Cliente (web)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CLI-01 | Cliente | Primeiro acesso pelo QR, em aba anônima | Limpar dados do site, abrir `/q/{id}` | Login anônimo e tela da fila, sem spinner infinito | Produção, fila inexistente com dados limpos: login anônimo e "Fila não encontrada" em ~2 s. Emulator, fila real: formulário da fila em ~3 s no primeiro acesso | Aprovado | 30/09/2026 |
| CLI-02 | Cliente | Nome vazio | Abrir fila aberta, deixar nome vazio, tocar "Entrar na fila" | Mensagem "Informe seu nome" e nenhuma entry criada | [emulator] Mensagem "Informe seu nome"; nenhuma entry criada | Aprovado | 30/09/2026 |
| CLI-03 | Cliente | Fila pausada | Dono pausa a fila; cliente abre o link | Badge "Pausada" e botão de entrar desabilitado | [emulator] Badge "Pausada" e botão "Entrar na fila" desabilitado (print 37) | Aprovado | 30/09/2026 |
| CLI-04 | Cliente | Fila encerrada | Dono fecha a fila; cliente sem senha abre o link | Tela de fila fechada | [emulator] "Fechada — Esta fila não está recebendo novos participantes." em tempo real (print 39) | Aprovado | 30/09/2026 |
| CLI-05 | Cliente | Fila inexistente | Abrir `https://qio.web.app/q/fila-inexistente-teste-2` | "Fila não encontrada" | "Fila não encontrada — Verifique o link ou escaneie o QR code novamente." | Aprovado | 30/09/2026 |
| CLI-06 | Cliente | Link inválido | Abrir `https://qio.web.app/link-qualquer` e `https://qio.web.app/q/` | "Link inválido" | "Link inválido — Escaneie o QR code da fila para entrar." nas duas URLs | Aprovado | 30/09/2026 |
| CLI-07 | Cliente | Acompanhar a posição | Entrar na fila com outras pessoas à frente; dono chama o próximo | Posição e espera estimada diminuem em tempo real | [emulator] Senha #7: 4º/~20 min → 3º/~15 min quando o dono chamou o próximo, sem recarregar | Aprovado | 30/09/2026 |
| CLI-08 | Cliente | Sair da fila | Com senha ativa, tocar "Sair da fila" e confirmar | Tela "Você saiu da fila"; entry some do painel do dono | [emulator] "Tem certeza?" → "Confirmar saída" → "Você saiu da fila"; entry sumiu da lista do dono | Aprovado | 30/09/2026 |
| CLI-09 | Cliente | Recuperar a senha ao reabrir | Entrar na fila, fechar a aba, abrir o mesmo link | Mesma senha e posição exibidas | [emulator] Após recarregar a página: mesma senha #7 e posição 3º | Aprovado | 30/09/2026 |
| CLI-10 | Cliente | Alerta na página | Aba aberta; dono chama a senha | Tela "É a sua vez", som e vibração | [emulator] "É a sua vez! Senha #1 — Dirija-se ao atendimento." em tempo real. Som e vibração não verificáveis no navegador de teste | Aprovado (visual) | 30/09/2026 |
| CLI-11 | Cliente | Push com a aba em segundo plano (Android/Chrome) | Permitir notificações, minimizar o Chrome, dono chama | Notificação push | Function `onEntryCalled` publicada em 01/10/2026, mas o build publicado da web não tem `VITE_VAPID_KEY`: o cliente não obtém token FCM | Bloqueado | 01/10/2026 |
| CLI-12 | Cliente | iOS: limitação | Abrir o link no Safari do iPhone | Funciona com alerta na página; push web só com a página instalada na tela inicial (iOS 16.4+) | | Pendente | |

Nota CLI-03 (01/10/2026): a partir da 1.2.0 a `joinQueue` também bloqueia a entrada em fila pausada ou fechada no servidor, não só pela interface. O resultado obtido acima (30/09/2026) foi na interface e não foi reexecutado contra a function.

## Dono (app)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DON-01 | Dono | Criar fila | Home → "+" → nome e tempo médio → criar | Fila aparece em "Minhas filas" com status Aberta | [emulator] Fila "Balcão Teste" criada; Firestore + espelho RTDB (`meta`, `owners`) gravados | Aprovado | 30/09/2026 |
| DON-02 | Dono | QR | Abrir a fila | QR e link `qio.web.app/q/{id}`; copiar e compartilhar funcionam | [emulator] QR e link `qio.web.app/q/{id}` exibidos (print 19) | Aprovado | 30/09/2026 |
| DON-03 | Dono | Chamar próximo | Com clientes na fila, tocar "Chamar próximo" | Menor senha vai para "Chamando agora"; cliente é alertado (print 11) | [emulator] Diego #3 foi para "Chamando agora"; `meta/serving` = 3 (print 11) | Aprovado | 30/09/2026 |
| DON-04 | Dono | Atendido | Com senha chamada, tocar "Atendido" | Entry sai do painel e vai para o histórico com `result: served` (print 12) | [emulator] Diego #3 arquivado com `result: served`, removido do RTDB | Aprovado | 30/09/2026 |
| DON-05 | Dono | Não compareceu | Com senha chamada, tocar "Não compareceu" | Entry sai do painel e vai para o histórico com `result: no_show` (print 12) | [emulator] Carla #2 arquivada com `result: no_show` (print 12) | Aprovado | 30/09/2026 |
| DON-06 | Dono | Pausar e encerrar | Tocar "Pausar", depois "Reabrir", depois "Fechar" | Badge muda no app e na web em tempo real | [emulator] Pausar → badge "Pausada" no app e na web; Fechar → "Fechada" e botão "Excluir fila" (prints 36 e 38) | Aprovado | 30/09/2026 |
| DON-07 | Dono | Excluir fila | Com a fila fechada, "Excluir fila" → confirmar | Fila some da home; link mostra "Fila não encontrada"; operadores perdem a fila | [emulator] Fila, histórico, operadores, pedidos e convite apagados; link mostra "Fila não encontrada"; fila sumiu da home do operador (prints 40 a 42). Sobrou `tickets/{id}` no RTDB (corrigido no código, ainda não reexecutado) | Aprovado com ressalva | 30/09/2026 |
| DON-08 | Dono | Histórico com `operatorId` | Após DON-04 e OPE-05, ver `queues/{id}/history` no console | `calledBy` = quem chamou, `operatorId` = quem finalizou | [emulator] Senha #1: `calledBy` = operador, `operatorId` = operador; #2: dono/dono. Registro do operador com os 9 campos aceito pela rule | Aprovado | 30/09/2026 |

## Operador (app)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OPE-01 | Operador | Convite válido | Dono: fila → "Operadores e convites" → gerar código (24 h). Operador: home → ícone de crachá → digitar o código | Tela "Aguardando aprovação" (prints 13 e 14) | [emulator] Código `X7QKFC` (24 h) digitado em minúsculas foi aceito; tela "Aguardando aprovação" (prints 13, 14, 21) | Aprovado | 30/09/2026 |
| OPE-02 | Operador | Convite expirado ou inválido | Digitar código inexistente; depois um código revogado | "Código inválido ou revogado." (expirado: "Código expirado. Peça um novo ao dono.") | [emulator] Código inexistente: "Código inválido ou revogado." (print 22). Expirado: coberto só pelas rules (AUT-04) | Aprovado (inválido) | 30/09/2026 |
| OPE-03 | Dono/Operador | Aprovação | Dono vê o pedido e aprova | Operador vê "Pedido aprovado"; fila aparece em "SOU OPERADOR" (print 15) | [emulator] Dono viu o pedido ao vivo e aprovou; operador viu "Pedido aprovado"; home do operador com seção "SOU OPERADOR" (prints 15, 25, 32) | Aprovado | 30/09/2026 |
| OPE-04 | Dono/Operador | Recusa | Dono recusa o pedido | Operador vê "Pedido recusado"; card com opção de dispensar na home | [emulator] Operador viu "Pedido recusado" ao vivo; home com card e botão de dispensar (prints 23, 24). Novo pedido depois da recusa funcionou | Aprovado | 30/09/2026 |
| OPE-05 | Operador | Atendimento | Operador abre a fila, chama, marca atendido | Só aparecem "Chamar próximo", "Atendido" e "Não compareceu" (print 16) | [emulator] Operador chamou Ana #1 e marcou "Atendido"; histórico `served` (print 16) | Aprovado | 30/09/2026 |
| OPE-06 | Operador | Tentativa de ação administrativa | Verificar que não há pausar, fechar, excluir nem convite na tela do operador | Controles ausentes; rules negam a escrita | [emulator] Painel do operador sem Pausar, Fechar, Excluir e "Operadores e convites" (print 26). Rules negam as escritas (AUT-04) | Aprovado | 30/09/2026 |
| OPE-07 | Dono/Operador | Remoção no meio do uso | Operador com o painel aberto; dono remove o operador | Operador vê "Acesso encerrado", volta para a home e vê "Você foi removido desta fila" | [emulator] Com o painel aberto: diálogo "Acesso encerrado"; home mostra "Você foi removido desta fila"; `operatorUids` apagado; pedido `removed` (prints 30, 31) | Aprovado | 30/09/2026 |

## Concorrência

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CON-01 | Cliente | Duas entradas simultâneas | Dois aparelhos com o formulário preenchido tocam "Entrar na fila" ao mesmo tempo | Senhas diferentes e consecutivas (transação em `tickets/{id}`) | [emulator] 5 clientes anônimos entrando ao mesmo tempo via SDK, mesma lógica de `join.ts`: senhas #2 a #6, todas distintas e consecutivas | Aprovado | 30/09/2026 |
| CON-02 | Dono/Operador | Dois atendentes chamam ao mesmo tempo | Dono e operador, com 2+ clientes na fila, tocam "Chamar próximo" juntos | Cada um recebe uma senha diferente; `meta/serving` fica na maior | [emulator] Dono e operador tocaram "Chamar próximo" com < 1 s de intervalo: operador pegou #1, dono #2; `meta/serving` = 2 | Aprovado | 30/09/2026 |

## Integração (por fronteira)

| ID | Perfil | Cenário | Passos | Resultado esperado | Resultado obtido | Situação | Data |
| --- | --- | --- | --- | --- | --- | --- | --- |
| INT-01 | Sistema | Web ↔ RTDB | Cliente anônimo lê `queues/{id}/meta` em produção | Leitura liberada após o login anônimo | SDK web 12.x em produção: login anônimo e `get(queues/{id}/meta)` retornaram `null` para fila inexistente, sem erro de permissão | Aprovado | 30/09/2026 |
| INT-02 | Sistema | App ↔ Firestore/RTDB | Executar DON-01 a DON-05 | Dual-write: Firestore e espelho `meta`/`owners` no RTDB | [emulator] Dual-write conferido nos emulators após DON-01 a DON-05 | Aprovado | 30/09/2026 |
| INT-03 | Sistema | RTDB → Cloud Function → FCM | Executar CLI-11 | Push entregue | Function publicada (v2, gatilho `ref.v1.written`); entrega não testada por falta de token FCM no cliente (ver CLI-11) | Bloqueado | 01/10/2026 |
| INT-04 | Sistema | App Check ↔ web | Verificar `VITE_RECAPTCHA_SITE_KEY` no build publicado | App Check ativo | Build publicado sem chave do reCAPTCHA: App Check desativado em produção | Bloqueado | 30/09/2026 |
| INT-05 | Sistema | Operador ↔ rules | Rodar AUT-04 e executar OPE-05 a OPE-07 | Rules liberam só atendimento | [emulator] OPE-05 a OPE-07 executados com as rules do repo nos emulators | Aprovado (emulator) | 30/09/2026 |

## Limitações conhecidas

- Push com a aba em segundo plano: em 01/10/2026 o build da web não tinha
  `VITE_VAPID_KEY` (CLI-11 e INT-03 ficaram bloqueados). `docs/FCM.md` registra a
  chave como configurada depois disso; falta validar a entrega em aparelho real
  e reexecutar CLI-11/INT-03.
- App Check: sem chave no build em 30/09/2026 (INT-04). Hoje o enforcement existe
  só nas callables e está desligado (`ENFORCE_APP_CHECK=false`); RTDB, Firestore e
  Storage nunca terão enforcement enquanto o app Flutter não usar App Check
  (`docs/APPCHECK.md`).
- Fila pausada: o bloqueio de entrada é só na interface; as rules do RTDB não
  impedem a criação de entry com a fila pausada.
  Nota de 01/10/2026: a Cloud Function `joinQueue` (1.2.0) passou a recusar
  entrada em fila pausada ou fechada no servidor (`failed-precondition`). O
  resultado registrado acima é anterior a isso e não foi reexecutado.
- (Resolvido) Na versão testada em 30/09/2026 o cliente podia alterar campos da própria entry no RTDB. Hoje as rules só permitem ao cliente `status: 'left'` e `fcmToken` na própria entry, e a entrada é pela callable `joinQueue`; coberto por `rules-tests/`.
- O app Flutter compilado para web perde a sessão ao recarregar a página
  (observado só no ambiente de teste com emulator; o app é distribuído como
  APK).
- Deploy automático do hosting depende do secret `FIREBASE_TOKEN`, que não está
  configurado no repositório.
