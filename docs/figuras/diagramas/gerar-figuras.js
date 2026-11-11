const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const P = '/mnt/user-data/uploads/qio/docs/prints/';
const img = f => 'data:image/png;base64,' + fs.readFileSync(P + f).toString('base64');

const CSS = `
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Inter,sans-serif;color:#111827;background:#fff;width:1200px;padding:18px}
.fig{background:#F9FAFB;border-radius:28px;padding:34px 40px 36px}
h1{font-size:30px;font-weight:700;letter-spacing:-.4px}
.sub{font-size:17px;color:#6B7280;margin-top:6px;margin-bottom:26px}
.card{background:#fff;border:1.5px solid #E5E7EB;border-radius:16px;box-shadow:0 4px 14px rgba(17,24,39,.07);padding:16px}
.n{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:50%;background:#2563EB;color:#fff;font-weight:700;font-size:16px;flex:none;box-shadow:0 0 0 3px #fff,0 2px 6px rgba(37,99,235,.4)}
.t{font-size:17px;font-weight:600;line-height:1.25}
.d{font-size:14px;color:#6B7280;line-height:1.35;margin-top:4px}
.arrow{color:#2563EB;font-size:30px;font-weight:600;flex:none;align-self:center;line-height:1}
.strip{margin-top:24px;background:#EFF6FF;border:1.5px solid #BFDBFE;border-radius:14px;padding:13px 18px;font-size:16px;text-align:center;color:#1E3A8A;font-weight:500}
.tag{display:inline-block;border-radius:999px;padding:4px 12px;font-size:13px;font-weight:600;color:#fff}
.red{background:#EF4444}.green{background:#10B981}.amber{background:#F59E0B}.gray{background:#6B7280}.blue{background:#2563EB}
code,.mono{font-family:"DejaVu Sans Mono",monospace;font-size:.92em}
.row{display:flex;gap:14px}
.stretch>.card{flex:1}
.phone{background:#fff;border:1.5px solid #E5E7EB;border-radius:22px;padding:9px;box-shadow:0 6px 18px rgba(17,24,39,.10);position:relative}
.phone .scr{border-radius:14px;overflow:hidden;height:330px;background:#F3F4F6}
.phone img{width:100%;height:100%;display:block;object-fit:cover}
.phone .n{position:absolute;top:-12px;left:-12px}
.cap{text-align:center;margin-top:14px}
`;

const step = (n, t, d = '', extra = '') => `<div class="card" style="flex:1;display:flex;gap:12px;align-items:flex-start;position:relative"><span class="n">${n}</span><div><div class="t">${t}</div>${d ? `<div class="d">${d}</div>` : ''}${extra}</div></div>`;
const ar = '<span class="arrow">→</span>';
const phone = (n, f, t, d, pos = 'top') => `<div style="flex:1"><div class="phone"><span class="n">${n}</span><div class="scr"><img style="object-position:${pos}" src="${img(f)}"></div></div><div class="cap"><div class="t">${t}</div><div class="d">${d}</div></div></div>`;

const figs = {};

figs['fig05-aviso-hibrido'] = `<h1>Aviso ao cliente: dois caminhos</h1><div class="sub">O alerta na página e a notificação push partem da mesma mudança de status</div>
<div style="display:flex;align-items:center;gap:0">
 <div style="display:flex;align-items:center;gap:12px;width:392px;flex:none">
  <div class="card" style="width:172px;height:170px"><span class="n">1</span><div class="t" style="margin-top:10px">Proprietário ou operador toca “Chamar próximo”</div></div>${ar}
  <div class="card" style="width:172px;height:170px"><span class="n">2</span><div class="t" style="margin-top:10px">Status da senha muda para “chamado”</div><div class="d">Realtime Database</div></div>
 </div>
 <svg width="64" height="364" viewBox="0 0 64 364" style="flex:none"><path d="M0 182 H24 Q32 182 32 174 V93 Q32 85 40 85 H56" fill="none" stroke="#2563EB" stroke-width="2.5"/><path d="M24 182 Q32 182 32 190 V271 Q32 279 40 279 H56" fill="none" stroke="#2563EB" stroke-width="2.5"/><path d="M50 79 L58 85 L50 91" fill="none" stroke="#2563EB" stroke-width="2.5"/><path d="M50 273 L58 279 L50 285" fill="none" stroke="#2563EB" stroke-width="2.5"/></svg>
 <div style="flex:1;display:flex;flex-direction:column;gap:24px">
  <div style="height:170px;background:#EFF6FF;border-radius:18px;padding:12px 16px">
   <div style="font-size:14px;font-weight:700;color:#1D4ED8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Página aberta</div>
   <div class="row" style="align-items:stretch;height:112px">${step('3A', 'Listener em tempo real', 'a página recebe a mudança')}${ar}${step('4A', 'Alerta visual e sonoro', 'tela “É a sua vez”')}</div>
  </div>
  <div style="height:170px;background:#FFFBEB;border-radius:18px;padding:12px 16px">
   <div style="font-size:14px;font-weight:700;color:#B45309;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Aba em segundo plano</div>
   <div class="row" style="align-items:stretch;height:112px">${step('3B', 'Cloud Function acionada')}${ar}${step('4B', 'Envio pelo Firebase Cloud Messaging')}${ar}${step('5B', 'Notificação push')}</div>
  </div>
 </div>
</div>
<div class="strip" style="background:#FFFBEB;border-color:#FDE68A;color:#92400E">No iOS, o push só funciona com a página adicionada à tela de início</div>`;

const dbItem = (name, a, b) => `<div class="card" style="display:flex;align-items:center;gap:14px;padding:11px 16px"><div class="mono" style="font-weight:700;font-size:16px;width:158px;flex:none">${name}</div><div class="d" style="margin:0">${a}${b ? '<br>' + b : ''}</div></div>`;
figs['fig08-dois-bancos'] = `<h1>Quem guarda o quê: dois bancos, duas funções</h1><div class="sub">Dados duráveis no Firestore, estado em tempo real no Realtime Database</div>
<div style="display:flex;gap:0;align-items:stretch">
 <div style="flex:1;background:#EFF6FF;border-radius:18px;padding:16px;display:flex;flex-direction:column">
  <div class="t" style="color:#1D4ED8;font-size:19px">Cloud Firestore</div><div class="d" style="margin-bottom:12px">Dados duráveis: configuração, permissões e histórico</div>
  <div class="stretch" style="display:flex;flex-direction:column;gap:9px;flex:1">
  ${dbItem('queues/{queueId}', 'configuração da fila')}${dbItem('operators', 'permissões dos operadores', 'e operatorRequests')}${dbItem('owners/{uid}', 'conta do proprietário')}${dbItem('history', 'atendimentos encerrados')}${dbItem('feedback', 'avaliações dos clientes')}${dbItem('groups', 'grupos de filas')}
  </div>
 </div>
 <div style="width:200px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;padding:0 10px;text-align:center">
  <div class="tag blue mono" style="font-size:12px">mirrorQueueToRtdb</div>
  <div class="tag blue mono" style="font-size:12px">mirrorOperatorToRtdb</div>
  <svg width="170" height="26"><path d="M4 13 H160" stroke="#2563EB" stroke-width="3"/><path d="M150 4 L162 13 L150 22" fill="none" stroke="#2563EB" stroke-width="3"/></svg>
  <div class="d" style="font-weight:600;color:#1E3A8A">replica em segundos,<br>em um só sentido</div>
 </div>
 <div style="flex:1;background:#ECFDF5;border-radius:18px;padding:16px">
  <div class="t" style="color:#047857;font-size:19px">Realtime Database</div><div class="d" style="margin-bottom:12px">Estado vivo, em tempo real</div>
  <div style="display:flex;flex-direction:column;gap:9px">
  ${dbItem('meta', 'dados da fila para a página', 'replicado do Firestore')}${dbItem('operatorUids', 'autorização dos operadores', 'replicado do Firestore')}${dbItem('entries', 'nome e telefone', 'escrito por joinQueue e app')}${dbItem('public', 'senha, status e ordem', 'escrito por syncPublicTicket')}${dbItem('tickets', 'contador de senha', 'escrito por joinQueue')}${dbItem('rateLimits', 'limite de tentativas', 'escrito pelas Cloud Functions')}
  </div>
 </div>
</div>
<div class="strip">Desde a v1.5.0, alterações de fila e de operadores são gravadas só no Firestore e replicadas por função</div>`;

const vstep = (n, t, d, tag) => `<div class="card" style="flex:1;min-height:128px"><div style="display:flex;gap:10px;align-items:center"><span class="n">${n}</span><div class="t">${t}</div></div>${d ? `<div class="d" style="margin-top:8px">${d}</div>` : ''}${tag ? `<div style="margin-top:10px">${tag}</div>` : ''}</div>`;
figs['fig11-validacoes-joinqueue'] = `<h1>Entrar na fila: o que o servidor valida</h1><div class="sub">Oito etapas executadas pela função <span class="mono">joinQueue</span></div>
<div class="row">${vstep(1, 'Autenticação anônima')}${ar}${vstep(2, 'Valida nome e telefone', 'nome de 1 a 60 caracteres')}${ar}${vstep(3, 'A fila está aberta?', '', '<span class="tag red">Recusa: fila pausada ou fechada</span>')}${ar}${vstep(4, 'Limite de espera e capacidade do horário', '', '<span class="tag red">Recusa: fila lotada</span>')}</div>
<div style="text-align:right;color:#2563EB;font-size:26px;font-weight:600;line-height:1;padding:6px 120px 6px 0">↓</div>
<div class="row" style="flex-direction:row-reverse">${vstep(5, 'Telefone já ativo?', 'mesmo nome: devolve a senha')}<span class="arrow">←</span>${vstep(6, 'Limite de 3 entradas por 10 minutos', '', '<span class="tag red">Recusa: muitas tentativas</span>')}<span class="arrow">←</span>${vstep(7, 'Transação do contador de senha')}<span class="arrow">←</span>${vstep(8, 'Cria a entrada', '', '<span class="tag green">Senha 042</span>')}</div>
<div class="strip" style="display:flex;align-items:center;justify-content:center;gap:14px;background:#F3F4F6;border-color:#E5E7EB;color:#111827"><b>Página do cliente</b><span style="color:#9CA3AF;letter-spacing:3px">·····</span><span class="tag red">✕ escrita direta bloqueada pelas regras</span><span style="color:#9CA3AF;letter-spacing:3px">····→</span><b>Realtime Database (<span class="mono">entries</span>)</b><span class="tag blue" style="margin-left:18px">Regras de negócio no servidor</span></div>`;

// order of row 2 visually: 8 ← 7 ← 6 ← 5 would read backwards; rebuild as left-to-right 5..8 with a return arrow
figs['fig11-validacoes-joinqueue'] = figs['fig11-validacoes-joinqueue']
  .replace(/<div style="text-align:right;color:#2563EB[^]*?<\/div>\n<div class="row" style="flex-direction:row-reverse">[^]*?<\/div>\n<div class="strip"/, () =>
    `<svg width="1120" height="40" viewBox="0 0 1120 40" style="display:block"><path d="M1000 0 V12 Q1000 20 992 20 H128 Q120 20 120 28 V36" fill="none" stroke="#2563EB" stroke-width="2.5"/><path d="M113 29 L120 38 L127 29" fill="none" stroke="#2563EB" stroke-width="2.5"/></svg>
<div class="row">${vstep(5, 'Telefone já ativo?', 'mesmo nome: devolve a senha')}${ar}${vstep(6, 'Limite de 3 entradas por 10 minutos', '', '<span class="tag red">Recusa: muitas tentativas</span>')}${ar}${vstep(7, 'Transação do contador de senha')}${ar}${vstep(8, 'Cria a entrada', '', '<span class="tag green">Senha 042</span>')}</div>
<div class="strip"`);

figs['fig16-entrada-cliente'] = `<h1>Entrada do cliente pela página web</h1><div class="sub">Formulário de entrada e situações em que a página não permite entrar</div>
<div class="row" style="gap:34px;padding:8px 6px 0">
${phone(1, '01-cliente-tela-entrar-na-fila.png', 'Entrar na fila', 'Nome obrigatório e telefone opcional.')}
${phone(2, '06-cliente-fila-fechada.png', 'Fila fechada', 'A fila existe, mas não recebe novas entradas.', '50% 66%')}
${phone(3, '07-cliente-fila-nao-encontrada.png', 'Fila não encontrada', 'O endereço não corresponde a uma fila.', '50% 66%')}
${phone(4, '08-cliente-link-invalido.png', 'Link inválido', 'Endereço fora do formato esperado.', '50% 66%')}
</div>`;

figs['fig17-acompanhamento-chamada'] = `<h1>Acompanhamento e chamada na página do cliente</h1><div class="sub">Da espera à chamada, e a saída voluntária da fila</div>
<div style="display:flex;gap:26px;padding:8px 6px 0">
 <div style="flex:1;background:#EFF6FF;border-radius:20px;padding:26px 22px 18px"><div style="font-size:14px;font-weight:700;color:#1D4ED8;text-transform:uppercase;letter-spacing:.5px;margin:-10px 0 18px">Espera e chamada</div><div class="row" style="gap:12px">
 ${phone(1, '02-cliente-senha-e-posicao.png', 'Senha e posição', 'Posição e espera estimada.')}<span class="arrow" style="margin-top:-80px">→</span>
 ${phone(2, '04-cliente-e-sua-vez.png', 'É a sua vez', 'Alerta ao ser chamado.')}</div></div>
 <div style="flex:1;background:#F3F4F6;border-radius:20px;padding:26px 22px 18px"><div style="font-size:14px;font-weight:700;color:#4B5563;text-transform:uppercase;letter-spacing:.5px;margin:-10px 0 18px">Saída voluntária</div><div class="row" style="gap:12px">
 ${phone(3, '03-cliente-confirmar-saida.png', 'Confirmar saída', 'A página pede confirmação.')}<span class="arrow" style="margin-top:-80px">→</span>
 ${phone(4, '05-cliente-saiu-da-fila.png', 'Saiu da fila', 'A entrada é encerrada.')}</div></div>
</div>`;

const pill = (x, y, w, c, t, s) => `<rect x="${x}" y="${y}" width="${w}" height="${s ? 74 : 62}" rx="16" fill="${c}"/><text x="${x + w / 2}" y="${y + (s ? 32 : 39)}" text-anchor="middle" fill="#fff" font-size="21" font-weight="700">${t}</text>${s ? `<text x="${x + w / 2}" y="${y + 55}" text-anchor="middle" fill="#fff" font-size="14">${s}</text>` : ''}`;
figs['fig18-estados-entrada'] = `<h1>Estados de uma senha na fila</h1><div class="sub">Quem muda cada estado</div>
<svg width="1120" height="280" viewBox="0 30 1120 280" style="display:block;font-family:Inter">
<defs><marker id="a" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" refX="11" refY="7" orient="auto"><path d="M2 2 L12 7 L2 12" fill="none" stroke="#2563EB" stroke-width="2"/></marker><marker id="g" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" refX="11" refY="7" orient="auto"><path d="M2 2 L12 7 L2 12" fill="none" stroke="#6B7280" stroke-width="2"/></marker><marker id="r" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" refX="11" refY="7" orient="auto"><path d="M2 2 L12 7 L2 12" fill="none" stroke="#EF4444" stroke-width="2"/></marker></defs>
${pill(40, 50, 240, '#3B82F6', 'Aguardando')}${pill(440, 50, 240, '#1D4ED8', 'Chamado')}${pill(840, 50, 240, '#10B981', 'Atendido')}
<path d="M280 81 H436" stroke="#2563EB" stroke-width="2.5" marker-end="url(#a)"/><text x="360" y="68" text-anchor="middle" font-size="15" font-weight="600" fill="#111827">Operador chama</text>
<path d="M680 81 H836" stroke="#2563EB" stroke-width="2.5" marker-end="url(#a)"/><text x="760" y="68" text-anchor="middle" font-size="15" font-weight="600" fill="#111827">Operador conclui</text>
${pill(200, 220, 300, '#6B7280', 'Saiu da fila', 'Cliente desiste ou a senha expira')}${pill(640, 220, 300, '#EF4444', 'Não compareceu', 'Operador registra a ausência')}
<path d="M160 112 V170 Q160 180 170 180 H300 Q310 180 310 190 V216" fill="none" stroke="#6B7280" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#g)"/>
<path d="M500 112 V170 Q500 180 490 180 H400 Q390 180 390 190 V216" fill="none" stroke="#6B7280" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#g)"/>
<path d="M620 112 V170 Q620 180 630 180 H780 Q790 180 790 190 V216" fill="none" stroke="#EF4444" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#r)"/>
</svg>
<div class="strip">Só quem aguarda pode expirar: uma senha chamada nunca expira</div>`;

const slot = (h, s, c, ok) => `<div style="display:flex;align-items:center;justify-content:space-between;border-radius:14px;padding:13px 18px;background:${c};color:#fff;opacity:${ok ? 1 : .85}"><div><div style="font-size:22px;font-weight:700">${h}</div><div style="font-size:14px">${s}</div></div><div style="font-size:14px;font-weight:600;background:rgba(255,255,255,.22);border-radius:999px;padding:5px 12px">${ok ? 'disponível' : 'desabilitado'}</div></div>`;
const note = (n, t, d) => `<div class="card" style="display:flex;gap:14px;align-items:flex-start"><span class="n">${n}</span><div><div class="t">${t}</div><div class="d">${d}</div></div></div>`;
figs['fig23-hora-marcada'] = `<h1>Hora marcada</h1><div class="sub">O cliente escolhe um horário com vagas na página de entrada</div>
<div style="display:flex;gap:40px;align-items:center">
 <div class="card" style="width:470px;padding:20px"><div class="t" style="margin-bottom:14px">Escolha o horário</div><div style="display:flex;flex-direction:column;gap:10px">
 ${slot('08:30', 'Já passou', '#6B7280', false)}${slot('09:00', '3 de 5 vagas', '#10B981', true)}${slot('09:30', 'Lotado', '#EF4444', false)}${slot('10:00', '1 de 5 vagas', '#F59E0B', true)}</div></div>
 <div style="flex:1;display:flex;flex-direction:column;gap:14px">
 ${note(1, 'Vagas por horário', 'Cada horário tem uma capacidade definida pelo proprietário.')}
 ${note(2, 'Horários passados ou lotados', 'Ficam desabilitados na lista e são recusados pelo servidor.')}
 ${note(3, 'Tolerância de 15 minutos', 'A entrada é aceita até 15 minutos depois do início do horário.')}
 </div>
</div>
<div class="strip">Todos os horários seguem o fuso de Brasília</div>`;

const ok = '<span style="display:inline-flex;width:34px;height:34px;border-radius:50%;background:#10B981;color:#fff;align-items:center;justify-content:center;font-weight:700;font-size:18px">✓</span>';
const no = '<span style="display:inline-flex;width:34px;height:34px;border-radius:50%;background:#EF4444;color:#fff;align-items:center;justify-content:center;font-weight:700;font-size:18px">✕</span>';
const cell = 'padding:16px 10px;text-align:center;border-top:1.5px solid #E5E7EB';
figs['fig24-quem-le-cada-dado'] = `<h1>Quem lê cada dado</h1><div class="sub">Nome e telefone ficam separados do que todos podem ver</div>
<div class="card" style="padding:6px 20px 10px"><table style="width:100%;border-collapse:collapse">
<tr><th style="width:290px"></th>${['Proprietário', 'Operador aprovado', 'Cliente<div class="d" style="font-weight:400;margin:2px 0 0">somente a própria entrada</div>', 'Outros clientes'].map(h => `<th style="padding:16px 10px;font-size:17px;font-weight:600;vertical-align:top">${h}</th>`).join('')}</tr>
<tr><td style="${cell};text-align:left"><div class="t mono">entries</div><div class="d">nome e telefone</div></td>${[ok, ok, ok, no].map(c => `<td style="${cell}">${c}</td>`).join('')}</tr>
<tr><td style="${cell};text-align:left"><div class="t mono">public</div><div class="d">senha, status e ordem</div></td>${[ok, ok, ok, ok].map(c => `<td style="${cell}">${c}</td>`).join('')}</tr>
</table></div>
<div class="strip">As regras de segurança do Realtime Database impõem essa separação</div>`;

(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 1236, height: 900 }, deviceScaleFactor: 2 });
  const out = path.join(__dirname, 'out'); fs.mkdirSync(out, { recursive: true });
  for (const [name, html] of Object.entries(figs)) {
    await pg.setContent(`<!doctype html><meta charset="utf-8"><style>${CSS}</style><body><div class="fig">${html}</div></body>`);
    await pg.evaluate(() => document.fonts.ready);
    await pg.locator('.fig').screenshot({ path: path.join(out, name + '.png') });
    console.log(name, (await pg.locator('.fig').boundingBox()).height);
  }
  await b.close();
})();
