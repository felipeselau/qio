// Figuras do TCC Qio, versão 2: largura 900 px para texto legível a 15 cm (1 px ≈ 0,53 pt).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const C = path.join(__dirname, 'crops') + '/';
const img = f => 'data:image/png;base64,' + fs.readFileSync(C + f).toString('base64');

const CSS = `
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Inter,sans-serif;color:#111827;background:#fff;width:900px;padding:10px}
.fig{background:#F9FAFB;border-radius:22px;padding:24px 26px 26px}
h1{font-size:27px;font-weight:700;letter-spacing:-.3px}
.sub{font-size:17px;color:#4B5563;margin-top:4px;margin-bottom:20px}
.card{background:#fff;border:1.5px solid #E5E7EB;border-radius:14px;box-shadow:0 3px 10px rgba(17,24,39,.07);padding:12px}
.n{display:inline-flex;align-items:center;justify-content:center;width:32px;height:32px;border-radius:50%;background:#2563EB;color:#fff;font-weight:700;font-size:16px;flex:none}
.t{font-size:18px;font-weight:600;line-height:1.25}
.d{font-size:16px;color:#4B5563;line-height:1.3;margin-top:3px}
.arrow{color:#2563EB;font-size:28px;font-weight:700;flex:none;align-self:center;line-height:1}
.strip{margin-top:18px;background:#EFF6FF;border:1.5px solid #BFDBFE;border-radius:12px;padding:11px 14px;font-size:17px;text-align:center;color:#1E3A8A;font-weight:500}
.tag{display:inline-block;border-radius:999px;padding:4px 11px;font-size:15px;font-weight:600;color:#fff}
.red{background:#EF4444}.green{background:#059669}.blue{background:#2563EB}
.mono{font-family:"DejaVu Sans Mono",monospace}
.row{display:flex;gap:10px}
.lane-h{font-size:15px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;margin-bottom:8px}
.shot{background:#fff;border:1.5px solid #D1D5DB;border-radius:14px;overflow:hidden;box-shadow:0 4px 12px rgba(17,24,39,.10)}
.shot img{display:block;width:100%}
.cap{display:flex;gap:10px;align-items:flex-start;margin-top:10px}
`;
const ar = '<span class="arrow">→</span>';
const step = (n, t, d = '', extra = '') => `<div class="card" style="flex:1;display:flex;gap:10px;align-items:flex-start"><span class="n">${n}</span><div><div class="t">${t}</div>${d ? `<div class="d">${d}</div>` : ''}${extra}</div></div>`;
const shot = (n, f, t, d, style = '') => `<div style="${style}"><div class="shot"><img src="${img(f)}"></div><div class="cap"><span class="n">${n}</span><div><div class="t">${t}</div>${d ? `<div class="d" style="margin-top:1px">${d}</div>` : ''}</div></div></div>`;
const figs = {};

// Figura 5
figs['fig5-aviso-hibrido'] = `<h1>Aviso ao cliente: dois caminhos</h1><div class="sub">O alerta na página e o push partem da mesma mudança de status</div>
<div class="row" style="align-items:stretch;gap:10px">
 <div style="width:190px;flex:none;display:flex;flex-direction:column;gap:8px;justify-content:center">
  ${step(1, 'Proprietário ou operador toca “Chamar próximo”')}
  <div class="arrow" style="text-align:center">↓</div>
  ${step(2, 'Status da senha muda para “chamado”', 'Realtime Database')}
 </div>
 <div style="width:26px;flex:none;display:flex;align-items:center"><span class="arrow">→</span></div>
 <div style="flex:1;display:flex;flex-direction:column;gap:12px">
  <div style="background:#EFF6FF;border-radius:14px;padding:10px 12px"><div class="lane-h" style="color:#1D4ED8">Página aberta</div>
   <div class="row">${step('3A', 'Listener em tempo real', 'a página recebe a mudança')}${ar}${step('4A', 'Alerta visual e sonoro', 'tela “É a sua vez”')}</div></div>
  <div style="background:#FFFBEB;border-radius:14px;padding:10px 12px"><div class="lane-h" style="color:#B45309">Aba em segundo plano</div>
   <div class="row">${step('3B', 'Cloud Function acionada')}${ar}${step('4B', 'Envio pelo FCM')}${ar}${step('5B', 'Notificação push')}</div></div>
 </div>
</div>
<div class="strip" style="background:#FFFBEB;border-color:#FDE68A;color:#92400E">No iOS, o push só funciona com a página adicionada à tela de início</div>`;

// Figura 8
const dbItem = (name, a, b) => `<div class="card" style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:8px 12px"><div class="mono" style="font-weight:700;font-size:16px">${name}</div><div class="d" style="margin-top:1px">${a}${b ? ' · ' + b : ''}</div></div>`;
figs['fig8-dois-bancos'] = `<h1>Quem guarda o quê: dois bancos</h1><div class="sub">Dados duráveis no Firestore, estado em tempo real no Realtime Database</div>
<div class="row" style="align-items:stretch;gap:0">
 <div style="flex:1;background:#EFF6FF;border-radius:14px;padding:12px;display:flex;flex-direction:column">
  <div class="t" style="color:#1D4ED8;font-size:20px">Cloud Firestore</div><div class="d" style="margin-bottom:10px">configuração, permissões e histórico</div>
  <div style="display:flex;flex-direction:column;gap:7px;flex:1">
  ${dbItem('queues/{id}', 'configuração da fila')}${dbItem('operators', 'operadores aprovados')}${dbItem('owners/{uid}', 'conta do proprietário')}${dbItem('history', 'atendimentos encerrados')}${dbItem('feedback', 'avaliações dos clientes')}${dbItem('groups', 'grupos de filas')}
  </div>
 </div>
 <div style="width:150px;flex:none;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;padding:0 8px;text-align:center">
  <div class="d" style="font-weight:600;color:#1E3A8A">funções de espelho</div>
  <svg width="130" height="24"><path d="M4 12 H120" stroke="#2563EB" stroke-width="3"/><path d="M110 3 L122 12 L110 21" fill="none" stroke="#2563EB" stroke-width="3"/></svg>
  <div class="d" style="font-weight:600;color:#1E3A8A">replica em segundos, em um só sentido</div>
 </div>
 <div style="flex:1;background:#ECFDF5;border-radius:14px;padding:12px;display:flex;flex-direction:column">
  <div class="t" style="color:#047857;font-size:20px">Realtime Database</div><div class="d" style="margin-bottom:10px">estado vivo da fila</div>
  <div style="display:flex;flex-direction:column;gap:7px;flex:1">
  ${dbItem('meta', 'dados da fila', 'espelho')}${dbItem('operatorUids', 'operadores', 'espelho')}${dbItem('entries', 'nome e telefone')}${dbItem('public', 'senha, status e ordem')}${dbItem('tickets', 'contador de senha')}${dbItem('rateLimits', 'limite de tentativas')}
  </div>
 </div>
</div>
<div class="strip">Desde a v1.5.0, alterações de fila e de operadores são gravadas só no Firestore e replicadas por função</div>`;

// Figura 11
const vstep = (n, t, tag) => `<div class="card" style="flex:1;min-height:112px"><div style="display:flex;gap:8px;align-items:flex-start"><span class="n">${n}</span><div class="t">${t}</div></div>${tag ? `<div style="margin-top:8px">${tag}</div>` : ''}</div>`;
const W11 = 848 - 52;
figs['fig11-validacoes-joinqueue'] = `<h1>Entrar na fila: o que o servidor valida</h1><div class="sub">Oito etapas executadas pela função <span class="mono">joinQueue</span></div>
<div class="row">${vstep(1, 'Autenticação anônima')}${ar}${vstep(2, 'Nome (1 a 60) e telefone')}${ar}${vstep(3, 'Fila aberta?', '<span class="tag red">pausada ou fechada</span>')}${ar}${vstep(4, 'Limite e vagas do horário', '<span class="tag red">fila lotada</span>')}</div>
<svg width="${W11}" height="34" viewBox="0 0 ${W11} 34" style="display:block"><path d="M${W11 - 90} 0 V10 Q${W11 - 90} 17 ${W11 - 97} 17 H97 Q90 17 90 24 V31" fill="none" stroke="#2563EB" stroke-width="2.5"/><path d="M83 24 L90 33 L97 24" fill="none" stroke="#2563EB" stroke-width="2.5"/></svg>
<div class="row">${vstep(5, 'Telefone já ativo?', '<span class="d">mesmo nome: devolve a senha</span>')}${ar}${vstep(6, 'Até 3 entradas em 10 min', '<span class="tag red">muitas tentativas</span>')}${ar}${vstep(7, 'Transação do contador de senha')}${ar}${vstep(8, 'Cria a entrada', '<span class="tag green">Senha 042</span>')}</div>
<div class="strip" style="background:#F3F4F6;border-color:#E5E7EB;color:#111827">A página do cliente não grava direto em <span class="mono">entries</span>: as regras de segurança bloqueiam, e as regras de negócio ficam no servidor</div>`;

// Figura 12
figs['fig12-login-cadastro'] = `<h1>Acesso do proprietário</h1><div class="sub">Entrada com e-mail e senha ou conta Google</div>
<div class="row" style="gap:24px;align-items:flex-start">
 ${shot(1, '10-owner-tela-de-login.png', 'Login', 'E-mail e senha ou Google.', 'width:290px;flex:none')}
 ${shot(2, '17-owner-criar-conta.png', 'Criar conta', 'Nome, e-mail e senha.', 'flex:1')}
</div>`;

// Figura 13
const callout = (n, t, d) => `<div class="card" style="display:flex;gap:10px;align-items:flex-start"><span class="n">${n}</span><div><div class="t">${t}</div><div class="d">${d}</div></div></div>`;
figs['fig13-tela-inicial'] = `<h1>Tela inicial do proprietário</h1><div class="sub">“Minhas filas”: todas as filas em uma lista</div>
<div class="row" style="gap:26px;align-items:center">
 <div class="shot" style="width:360px;flex:none"><img src="${img('55-owner-home-com-filas-e-metricas.png')}"></div>
 <div style="flex:1;display:flex;flex-direction:column;gap:12px">
  ${callout(1, 'Cartão da fila', 'Nome, situação (aberta, pausada ou fechada) e pessoas esperando.')}
  ${callout(2, 'Ícones do topo', 'Acesso às métricas e à conta do proprietário.')}
 </div>
</div>`;

// Figura 16
const small = (n, f, t, d) => `<div style="display:flex;gap:12px;align-items:center"><div class="shot" style="width:230px;flex:none"><img src="${img(f)}"></div><div style="display:flex;gap:8px;align-items:flex-start"><span class="n">${n}</span><div><div class="t">${t}</div><div class="d">${d}</div></div></div></div>`;
figs['fig16-entrada-cliente'] = `<h1>Entrada do cliente pela página web</h1><div class="sub">Formulário de entrada e situações em que a página não permite entrar</div>
<div class="row" style="gap:24px;align-items:flex-start">
 ${shot(1, '01-cliente-tela-entrar-na-fila.png', 'Entrar na fila', 'Nome obrigatório e telefone opcional.', 'width:330px;flex:none')}
 <div style="flex:1;display:flex;flex-direction:column;gap:16px">
  ${small(2, '06-cliente-fila-fechada.png', 'Fila fechada', 'Não recebe novas entradas.')}
  ${small(3, '07-cliente-fila-nao-encontrada.png', 'Fila não encontrada', 'O endereço não é de uma fila.')}
  ${small(4, '08-cliente-link-invalido.png', 'Link inválido', 'Endereço fora do formato.')}
 </div>
</div>`;

// Figura 17
figs['fig17-acompanhamento-chamada'] = `<h1>Acompanhamento e chamada</h1><div class="sub">Da espera à chamada, e a saída voluntária da fila</div>
<div class="row" style="gap:14px;align-items:stretch">
 <div style="flex:1;background:#EFF6FF;border-radius:14px;padding:12px"><div class="lane-h" style="color:#1D4ED8">Espera e chamada</div>
  <div class="row" style="gap:8px;align-items:flex-start">${shot(1, '02-cliente-senha-e-posicao.png', 'Senha e posição', '', 'flex:1')}<span class="arrow" style="margin-top:70px">→</span>${shot(2, '04-cliente-e-sua-vez.png', 'É a sua vez', '', 'flex:1')}</div></div>
 <div style="flex:1;background:#F3F4F6;border-radius:14px;padding:12px"><div class="lane-h" style="color:#4B5563">Saída voluntária</div>
  <div class="row" style="gap:8px;align-items:flex-start">${shot(3, '03-cliente-confirmar-saida.png', 'Confirmar saída', '', 'flex:1')}<span class="arrow" style="margin-top:70px">→</span>${shot(4, '05-cliente-saiu-da-fila.png', 'Saiu da fila', '', 'flex:1')}</div></div>
</div>`;

// Figura 18
const pill = (x, y, w, c, t, s) => `<rect x="${x}" y="${y}" width="${w}" height="${s ? 70 : 56}" rx="14" fill="${c}"/><text x="${x + w / 2}" y="${y + (s ? 30 : 36)}" text-anchor="middle" fill="#fff" font-size="21" font-weight="700">${t}</text>${s ? `<text x="${x + w / 2}" y="${y + 54}" text-anchor="middle" fill="#fff" font-size="15">${s}</text>` : ''}`;
const mk = (id, c) => `<marker id="${id}" markerUnits="userSpaceOnUse" markerWidth="14" markerHeight="14" refX="11" refY="7" orient="auto"><path d="M2 2 L12 7 L2 12" fill="none" stroke="${c}" stroke-width="2.2"/></marker>`;
figs['fig18-estados-entrada'] = `<h1>Estados de uma senha na fila</h1><div class="sub">Quem muda cada estado</div>
<svg width="848" height="250" viewBox="0 0 848 250" style="display:block;font-family:Inter">
<defs>${mk('a', '#2563EB')}${mk('g', '#6B7280')}${mk('r', '#EF4444')}</defs>
${pill(0, 30, 190, '#3B82F6', 'Aguardando')}${pill(329, 30, 190, '#1D4ED8', 'Chamado')}${pill(658, 30, 190, '#059669', 'Atendido')}
<path d="M190 58 H325" stroke="#2563EB" stroke-width="2.5" marker-end="url(#a)"/><text x="259" y="20" text-anchor="middle" font-size="16" font-weight="600" fill="#111827">Operador</text><text x="259" y="40" text-anchor="middle" font-size="16" font-weight="600" fill="#111827">chama</text>
<path d="M519 58 H654" stroke="#2563EB" stroke-width="2.5" marker-end="url(#a)"/><text x="588" y="20" text-anchor="middle" font-size="16" font-weight="600" fill="#111827">Operador</text><text x="588" y="40" text-anchor="middle" font-size="16" font-weight="600" fill="#111827">conclui</text>
${pill(90, 170, 300, '#6B7280', 'Saiu da fila', 'Cliente desiste ou a senha expira')}${pill(470, 170, 300, '#EF4444', 'Não compareceu', 'Operador registra a ausência')}
<path d="M95 86 V122 Q95 130 103 130 H200 Q208 130 208 138 V166" fill="none" stroke="#6B7280" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#g)"/>
<path d="M380 86 V122 Q380 130 372 130 H290 Q282 130 282 138 V166" fill="none" stroke="#6B7280" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#g)"/>
<path d="M470 86 V122 Q470 130 478 130 H612 Q620 130 620 138 V166" fill="none" stroke="#EF4444" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#r)"/>
</svg>
<div class="strip">Só quem aguarda pode expirar: uma senha chamada nunca expira</div>`;

// Figura 23
const slot = (h, s, c, ok) => `<div style="display:flex;align-items:center;justify-content:space-between;border-radius:12px;padding:10px 14px;background:${c};color:#fff"><div><div style="font-size:21px;font-weight:700">${h}</div><div style="font-size:15px">${s}</div></div><div style="font-size:15px;font-weight:600;background:rgba(255,255,255,.22);border-radius:999px;padding:4px 10px">${ok ? 'disponível' : 'desabilitado'}</div></div>`;
figs['fig23-hora-marcada'] = `<h1>Hora marcada</h1><div class="sub">O cliente escolhe um horário com vagas na página de entrada</div>
<div class="row" style="gap:22px;align-items:center">
 <div class="card" style="width:330px;flex:none;padding:14px"><div class="t" style="margin-bottom:10px">Escolha o horário</div><div style="display:flex;flex-direction:column;gap:8px">
 ${slot('08:30', 'Já passou', '#6B7280', false)}${slot('09:00', '3 de 5 vagas', '#059669', true)}${slot('09:30', 'Lotado', '#EF4444', false)}${slot('10:00', '1 de 5 vagas', '#D97706', true)}</div></div>
 <div style="flex:1;display:flex;flex-direction:column;gap:10px">
 ${callout(1, 'Vagas por horário', 'Cada horário tem a capacidade definida pelo proprietário.')}
 ${callout(2, 'Passados ou lotados', 'Ficam desabilitados e são recusados pelo servidor.')}
 ${callout(3, 'Tolerância de 15 minutos', 'Entrada aceita até 15 min depois do início.')}
 </div>
</div>
<div class="strip">Todos os horários seguem o fuso de Brasília</div>`;

// Figura 24
const ok = '<span style="display:inline-flex;width:32px;height:32px;border-radius:50%;background:#059669;color:#fff;align-items:center;justify-content:center;font-weight:700;font-size:18px">✓</span>';
const no = '<span style="display:inline-flex;width:32px;height:32px;border-radius:50%;background:#EF4444;color:#fff;align-items:center;justify-content:center;font-weight:700;font-size:18px">✕</span>';
const cell = 'padding:12px 6px;text-align:center;border-top:1.5px solid #E5E7EB';
figs['fig24-quem-le-cada-dado'] = `<h1>Quem lê cada dado</h1><div class="sub">Nome e telefone ficam separados do que todos podem ver</div>
<div class="card" style="padding:4px 14px 6px"><table style="width:100%;border-collapse:collapse">
<tr><th style="width:200px"></th>${['Proprietário', 'Operador aprovado', 'Cliente<div class="d" style="font-weight:400;margin:1px 0 0">a própria entrada</div>', 'Outros clientes'].map(h => `<th style="padding:12px 6px;font-size:18px;font-weight:600;vertical-align:top">${h}</th>`).join('')}</tr>
<tr><td style="${cell};text-align:left"><div class="t mono">entries</div><div class="d">nome e telefone</div></td>${[ok, ok, ok, no].map(c => `<td style="${cell}">${c}</td>`).join('')}</tr>
<tr><td style="${cell};text-align:left"><div class="t mono">public</div><div class="d">senha, status e ordem</div></td>${[ok, ok, ok, ok].map(c => `<td style="${cell}">${c}</td>`).join('')}</tr>
</table></div>
<div class="strip">As regras de segurança do Realtime Database impõem essa separação</div>`;

(async () => {
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 900, height: 900 }, deviceScaleFactor: 2.6 });
  const out = path.join(__dirname, 'out2'); fs.mkdirSync(out, { recursive: true });
  for (const [name, html] of Object.entries(figs)) {
    await pg.setContent(`<!doctype html><meta charset="utf-8"><style>${CSS}</style><body><div class="fig">${html}</div></body>`);
    await pg.evaluate(() => document.fonts.ready);
    const bb = await pg.locator('.fig').boundingBox();
    await pg.locator('.fig').screenshot({ path: path.join(out, name + '.png') });
    const over = await pg.evaluate(() => [...document.querySelectorAll('.fig *')].filter(e => e.scrollWidth > e.clientWidth + 2 && getComputedStyle(e).overflow !== 'hidden').length);
    console.log(name, Math.round(bb.width), Math.round(bb.height), 'overflow', over);
  }
  await b.close();
})();
