# Roteiro de demonstração para a banca — Qio

Duração prevista: cerca de 10 minutos. Ambiente: produção (`https://qio.web.app`,
projeto `qio-app`, plano Blaze). Os prints citados estão em `docs/prints/`;
vários foram tirados no emulator e servem só como referência visual do que
aparece na tela.

## 1. Preparação (antes da banca)

1. Aquecer as functions: 5 minutos antes, faça uma entrada de teste pela web
   (evita a partida a frio da `joinQueue`) e saia da fila em seguida.
2. Conferir as functions publicadas: `firebase functions:list --project qio-app`
   deve listar `joinQueue`, `syncPublicTicket`, `onEntryCalled` e
   `updateServiceEstimate`.
3. Rate limit: o padrão é 3 entradas por usuário a cada 10 minutos
   (`JOIN_RATE_LIMIT_MAX=3`, `JOIN_RATE_LIMIT_WINDOW_MIN=10` em
   `functions/.env`). Se for repetir entradas, aumente `JOIN_RATE_LIMIT_MAX` e
   republique só a function: `firebase deploy --only functions:joinQueue --project qio-app`.
4. Telefones: use telefones diferentes em cada aparelho ou deixe o campo vazio.
   A `joinQueue` recusa telefone que já está ativo na fila.
5. Conferir o bundle publicado: abra `https://qio.web.app` e confirme que a
   versão é a atual (o deploy automático do hosting só roda com o secret
   `FIREBASE_TOKEN`; sem ele o site não é atualizado).
6. Material: app do dono logado em um aparelho, app do operador (outra conta)
   em outro, navegador com aba anônima para o cliente.

## 2. Fluxo da demonstração

| Passo | Ação | O que mostrar | Print de referência |
| --- | --- | --- | --- |
| 1 | Dono cria a fila (nome e tempo médio) | Fila em "Minhas filas" com status Aberta | `18-owner-nova-fila-preenchida.png` |
| 2 | Dono abre o QR e o cartaz de QR | QR e link `qio.web.app/q/{id}`; cartaz imprimível | `19-owner-painel-qr-e-link.png` |
| 3 | Cliente escaneia o QR em aba anônima e entra | Tela de entrada, nome (telefone opcional) | `01-cliente-tela-entrar-na-fila.png` |
| 4 | Cliente vê senha, posição e estimativa | Senha e posição atualizando em tempo real | `02-cliente-senha-e-posicao.png` |
| 5 | Operador entra com o código de convite; dono aprova | Código de 24 h, pedido pendente, aprovação | `20-owner-operadores-gerar-convite.png`, `21-owner-codigo-convite-gerado-24h.png`, `13-operador-codigo-convite.png`, `14-operador-aguardando-aprovacao.png`, `15-owner-pedidos-operadores.png` |
| 6 | Operador abre o painel | Só controles de atendimento, sem admin | `16-operador-painel-atendimento.png`, `26-operador-painel-sem-controles-admin.png` |
| 7 | Dono ou operador toca "Chamar próximo" | Senha em "Chamando agora" | `11-owner-painel-chamar-proximo.png` |
| 8 | Cliente recebe "É a sua vez" | Tela de chamada na página | `04-cliente-e-sua-vez.png` |
| 9 | Finalizar: "Atendido" e, em outra senha, "Não compareceu" | Entry sai do painel e vai ao histórico | `12-owner-encerramento-atendido-nao-compareceu.png` |
| 10 | Dono abre o histórico | Métricas: atendidos, não compareceram, desistências | sem print disponível |
| 11 | Outro cliente entra e sai da fila | "Tem certeza?" e "Você saiu da fila"; vira desistência no histórico | `03-cliente-confirmar-saida.png`, `05-cliente-saiu-da-fila.png` |
| 12 | Dono pausa e depois fecha a fila | Badge muda no app e na web; entrada bloqueada | `36-owner-fila-pausada.png`, `37-cliente-fila-pausada-entrada-desabilitada.png`, `38-owner-fila-fechada-botao-excluir.png`, `39-cliente-fila-fechada.png` |

Notas por passo:

- Passo 3: com a fila pausada ou fechada a própria `joinQueue` recusa a entrada
  no servidor, não só a interface.
- Passo 7: o dono também recebe o aviso in-app quando alguém entra, mas só com
  o painel aberto e sem som no Android.
- Passo 10: a estimativa automática de atendimento se ajusta conforme o
  histórico cresce; com poucos registros ela pode não mudar.

## 3. Armadilhas conhecidas e como contornar

| Armadilha | Sintoma | Contorno |
| --- | --- | --- |
| Rate limit da `joinQueue` | "Muitas tentativas. Aguarde alguns minutos." | Aumentar `JOIN_RATE_LIMIT_MAX` e republicar a function, ou aguardar a janela |
| Telefone repetido | "Este telefone já está na fila." | Telefones diferentes ou campo vazio |
| Mesma aba/sessão anônima | A `joinQueue` devolve a entry já ativa em vez de criar outra | Usar outra aba anônima ou outro aparelho para cada cliente |
| Partida a frio da function | Primeira entrada demora alguns segundos | Aquecer 5 minutos antes |
| Bundle antigo no hosting | Spinner preso ou "Fila não encontrada" no primeiro acesso | Conferir o bundle publicado e fazer deploy manual do hosting (`firebase deploy --only hosting`) |
| App Check retorna 403 | Erros de App Check no console do navegador | Ver seção 4; não é bloqueio do fluxo enquanto o enforcement estiver desligado |
| Fila pausada ou fechada | Cliente não consegue entrar | Esperado; reabrir a fila antes de repetir o fluxo |

## 4. O que dizer sobre as limitações

- **App Check**: a web usa o provedor reCAPTCHA Enterprise, mas as requisições
  ainda retornam 403 em produção (pendente). Por isso o enforcement não é
  obrigatório e a proteção contra abuso fica nas rules do RTDB, na validação da
  `joinQueue` e no rate limit.
- **Push web**: a function `onEntryCalled` está publicada, mas o build da web
  não tem `VITE_VAPID_KEY`; o cliente não registra token FCM. Com a aba aberta
  o alerta aparece na página (som e vibração dependem do navegador). No iOS o
  push web só funciona com a página instalada na tela inicial (iOS 16.4+).
- **Aviso ao dono**: o aviso de nova entrada só funciona com o painel aberto no
  app, e não toca som no Android.
- **Deploy**: o hosting só é publicado automaticamente se o secret
  `FIREBASE_TOKEN` existir; rules e functions são publicadas manualmente.
- **Custo**: projeto no plano Blaze desde 01/10/2026; no volume do TCC o uso
  esperado fica dentro da cota gratuita.

Os resultados de teste registrados estão em `casos-de-teste.md`; este roteiro
não registra resultados.
