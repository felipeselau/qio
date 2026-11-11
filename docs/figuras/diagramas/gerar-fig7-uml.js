// Diagrama UML de casos de uso do Qio (Figura 7).
const { chromium } = require('playwright');
const W = 1000, H = 965;
const EW = 240, EH = 50;
const C = { ink: '#1b1f24', line: '#3d4650', admin: '#eef4fb', aten: '#f2f7ef', cli: '#fbf3ea', acc: '#1f5f8b' };

const L = 330, R = 700;
const admin = [
  'Cadastrar-se e entrar', 'Criar e gerir filas', 'Gerar QR Code e link', 'Gerar e revogar convite',
  'Aprovar, recusar ou\nremover operador', 'Consultar métricas e\nexportar relatórios', 'Organizar filas\nem grupos',
  'Configurar hora marcada\ne abertura automática', 'Atender direitos\ndo titular dos dados',
].map((t, i) => ({ t, x: L, y: 98 + i * 66 }));
const aten = ['Pedir acesso com código', 'Chamar o próximo cliente', 'Finalizar como atendido\nou não compareceu', 'Registrar entrada manual']
  .map((t, i) => ({ t, x: L, y: 728 + i * 62 }));
const cli = ['Entrar na fila\npelo QR Code', 'Acompanhar posição e\ntempo estimado', 'Recuperar a senha\nao reabrir o link', 'Sair da fila', 'Receber aviso\nde chamada', 'Avaliar o atendimento']
  .map((t, i) => ({ t, x: R, y: 210 + i * 74 }));
const extAbertura = { t: 'Pedir aviso de abertura', x: R, y: 104 };
const extCorrigir = { t: 'Corrigir chamada (chamar\nde novo, mover, desfazer)', x: 698, y: 790, w: 290 };

const actors = { dono: { x: 62, y: 340, n: 'Proprietário' }, oper: { x: 62, y: 800, n: 'Operador' }, cli: { x: 940, y: 420, n: 'Cliente' } };

function ell(u, dashed) {
  const lines = u.t.split('\n'), fs = 15.5, lh = 18;
  const y0 = u.y - ((lines.length - 1) * lh) / 2 + 5;
  return `<ellipse cx="${u.x}" cy="${u.y}" rx="${(u.w || EW) / 2}" ry="${EH / 2}" fill="#fff" stroke="${C.line}" stroke-width="1.6"${dashed ? ' stroke-dasharray="5 4"' : ''}/>` +
    lines.map((l, i) => `<text x="${u.x}" y="${y0 + i * lh}" text-anchor="middle" font-size="${fs}">${l}</text>`).join('');
}
function actor(a) {
  const { x, y } = a;
  return `<g stroke="${C.ink}" stroke-width="2" fill="none"><circle cx="${x}" cy="${y - 34}" r="12"/><line x1="${x}" y1="${y - 22}" x2="${x}" y2="${y + 12}"/><line x1="${x - 18}" y1="${y - 10}" x2="${x + 18}" y2="${y - 10}"/><line x1="${x}" y1="${y + 12}" x2="${x - 14}" y2="${y + 36}"/><line x1="${x}" y1="${y + 12}" x2="${x + 14}" y2="${y + 36}"/></g>` +
    `<text x="${x}" y="${y + 58}" text-anchor="middle" font-size="16" font-weight="600">${a.n}</text>`;
}
const assoc = (ax, ay, u, side) => `<line x1="${ax}" y1="${ay}" x2="${side === 'L' ? u.x - EW / 2 : u.x + EW / 2}" y2="${u.y}" stroke="${C.line}" stroke-width="1.2"/>`;
function dep(x1, y1, x2, y2, label, lx, ly) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${C.line}" stroke-width="1.4" stroke-dasharray="6 4" marker-end="url(#open)"/>` +
    `<text x="${lx}" y="${ly}" font-size="13.5" font-style="italic" fill="${C.acc}">${label}</text>`;
}

let s = '';
// faixas
s += `<rect x="150" y="34" width="370" height="628" rx="10" fill="${C.admin}"/>`;
s += `<rect x="150" y="676" width="700" height="272" rx="10" fill="${C.aten}"/>`;
s += `<rect x="540" y="34" width="310" height="628" rx="10" fill="${C.cli}"/>`;
s += `<text x="162" y="54" font-size="12.5" font-weight="700" fill="#4a6a86" letter-spacing="0.6">ADMINISTRAÇÃO</text>`;
s += `<text x="162" y="696" font-size="12.5" font-weight="700" fill="#4f7344" letter-spacing="0.6">ATENDIMENTO</text>`;
s += `<text x="552" y="54" font-size="12.5" font-weight="700" fill="#8a6136" letter-spacing="0.6">ENTRADA E ACOMPANHAMENTO</text>`;
// fronteira
s += `<rect x="140" y="12" width="720" height="944" rx="4" fill="none" stroke="${C.ink}" stroke-width="2"/>`;
s += `<text x="850" y="32" text-anchor="end" font-size="15" font-weight="700">Sistema Qio</text>`;
// associações
admin.forEach(u => (s += assoc(80, 330, u, 'L')));
aten.forEach(u => (s += assoc(80, 790, u, 'L')));
cli.forEach(u => (s += assoc(922, 410, u, 'R')));
// generalização Proprietário -> Operador
s += `<line x1="62" y1="420" x2="62" y2="740" stroke="${C.ink}" stroke-width="1.6"/><polygon points="62,752 52,734 72,734" fill="#fff" stroke="${C.ink}" stroke-width="1.6"/>`;
// include e extend
s += dep(L, admin[1].y + EH / 2, L, admin[2].y - EH / 2, '«include»', L + 10, (admin[1].y + admin[2].y) / 2 + 5);
s += dep(R, extAbertura.y + EH / 2, R, cli[0].y - EH / 2, '«extend»', R + 8, (extAbertura.y + cli[0].y) / 2 + 5);
s += dep(extCorrigir.x - extCorrigir.w / 2, extCorrigir.y, L + EW / 2, aten[1].y, '«extend»', 470, aten[1].y - 10);
s += ell(extAbertura, true) + ell(extCorrigir, true);
[...admin, ...aten, ...cli].forEach(u => (s += ell(u)));
s += actor(actors.dono) + actor(actors.oper) + actor(actors.cli);

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="Inter" fill="${C.ink}">
<defs><marker id="open" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto"><path d="M1,1 L10,6 L1,11" fill="none" stroke="${C.line}" stroke-width="1.5"/></marker></defs>
<rect width="${W}" height="${H}" fill="#fff"/>${s}</svg>`;

(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2.3 });
  await p.setContent(`<html><body style="margin:0">${svg}</body></html>`);
  await p.screenshot({ path: __dirname + '/out2/fig7-casos-de-uso-uml.png', clip: { x: 0, y: 0, width: W, height: H } });
  await b.close();
})();
