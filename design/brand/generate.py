import sys
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONT = sys.argv[1] if len(sys.argv) > 1 else 'Inter-Variable.ttf'
BLUE = '#2563EB'
BLUE_DARK_MODE = '#60A5FA'
INK = '#111827'
PAPER = '#F9FAFB'

RING = dict(cx=225, cy=225, r=123, sw=51)
DOTS = [dict(cx=368, cy=368, r=34, op=1), dict(cx=428, cy=428, r=22, op=0.6)]
BBOX_MIN, BBOX_MAX = 76.5, 450
CENTER = 246


def symbol(color, extra=''):
    parts = [f'<circle cx="{RING["cx"]}" cy="{RING["cy"]}" r="{RING["r"]}" fill="none" stroke="{color}" stroke-width="{RING["sw"]}"/>']
    for d in DOTS:
        op = '' if d['op'] == 1 else f' opacity="{d["op"]}"'
        parts.append(f'<circle cx="{d["cx"]}" cy="{d["cy"]}" r="{d["r"]}" fill="{color}"{op}/>')
    return f'<g{extra}>' + ''.join(parts) + '</g>'


def svg(viewbox, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}" role="img">'
            f'<title>{title}</title>{body}</svg>\n')


def symbol_small(color, extra=''):
    ring = f'<circle cx="{RING["cx"]}" cy="{RING["cy"]}" r="{RING["r"]}" fill="none" stroke="{color}" stroke-width="{RING["sw"]}"/>'
    dot = f'<circle cx="378" cy="378" r="48" fill="{color}"/>'
    return f'<g{extra}>' + ring + dot + '</g>'


def centered(color, scale, canvas=512, small=False):
    c = canvas / 2
    t = f' transform="translate({c} {c}) scale({scale}) translate({-CENTER} {-CENTER})"'
    return (symbol_small if small else symbol)(color, t)


def write(name, content):
    open(name, 'w').write(content)


def wordmark(text, color):
    f = TTFont(FONT)
    f = instancer.instantiateVariableFont(f, {'wght': 700, 'opsz': 32})
    upem = f['head'].unitsPerEm
    cap = f['OS/2'].sCapHeight
    ring_diameter = 2 * RING['r'] + RING['sw']
    s = ring_diameter / cap
    baseline = RING['cy'] + ring_diameter / 2
    gs = f.getGlyphSet()
    cmap = f.getBestCmap()
    x = BBOX_MIN + ring_diameter + 54
    paths = []
    for ch in text:
        name = cmap[ord(ch)]
        pen = SVGPathPen(gs)
        tp = TransformPen(pen, (s, 0, 0, -s, x, baseline))
        gs[name].draw(tp)
        paths.append(f'<path d="{pen.getCommands()}" fill="{color}"/>')
        x += gs[name].width * s
    return ''.join(paths), x


def logo(symbol_color, text_color, title):
    word, end = wordmark('io', text_color)
    body = symbol(symbol_color) + word
    pad = 36
    vb = f'{BBOX_MIN - pad:.1f} {BBOX_MIN - pad:.1f} {end - BBOX_MIN + 2 * pad:.1f} {BBOX_MAX - BBOX_MIN + 2 * pad:.1f}'
    return svg(vb, body, title)


pad = 30
sym_vb = f'{BBOX_MIN - pad} {BBOX_MIN - pad} {BBOX_MAX - BBOX_MIN + 2 * pad} {BBOX_MAX - BBOX_MIN + 2 * pad}'
write('symbol.svg', svg(sym_vb, symbol(BLUE), 'Qio'))
write('symbol-white.svg', svg(sym_vb, symbol('#FFFFFF'), 'Qio'))
write('symbol-mono.svg', svg(sym_vb, symbol(INK), 'Qio'))
write('symbol-dark.svg', svg(sym_vb, symbol(BLUE_DARK_MODE), 'Qio'))
write('icon.svg', svg('0 0 512 512', f'<rect width="512" height="512" rx="112" fill="{BLUE}"/>' + centered('#FFFFFF', 0.8), 'Qio'))
write('icon-small.svg', svg('0 0 512 512', f'<rect width="512" height="512" rx="112" fill="{BLUE}"/>' + centered('#FFFFFF', 0.86, small=True), 'Qio'))
write('icon-foreground.svg', svg('0 0 512 512', centered('#FFFFFF', 0.58), 'Qio'))
write('icon-monochrome.svg', svg('0 0 512 512', centered('#000000', 0.58), 'Qio'))
write('logo.svg', logo(BLUE, INK, 'Qio'))
write('logo-dark.svg', logo(BLUE_DARK_MODE, PAPER, 'Qio'))
print('ok')
