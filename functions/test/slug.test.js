const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  RESERVED_SLUGS,
  normalizeSlug,
  isValidSlug,
  parseSlug,
  SLUG_RATE_USER,
  SLUG_RATE_IP,
  SLUG_RELEASE_DAYS,
  nextSlugRate,
  hashIp,
  isReleasedSlug,
} = require('../src/slug');
const { SHORT_PATH_PREFIX, shortUrl } = require('../src/urls');

const root = path.join(__dirname, '..', '..');
const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');

const VALID = ['abc', 'cafe-do-ze', 'a1b', 'loja-2', 'a'.repeat(40), '123', 'a--b'];
const INVALID = [
  '',
  'ab',
  'a'.repeat(41),
  '-abc',
  'abc-',
  'ab_c',
  'café',
  'a b c',
  'abc/def',
  'ABC',
  'abc.def',
  'abc\n',
];
const RESERVED = [
  'admin',
  'api',
  'app',
  'q',
  'c',
  'w',
  'n',
  'privacidade',
  'termos',
  'assets',
  'fonts',
  'icons',
];

describe('isValidSlug', () => {
  for (const slug of VALID) {
    it(`aceita ${JSON.stringify(slug)}`, () => assert.equal(isValidSlug(slug), true));
  }
  for (const slug of INVALID) {
    it(`rejeita ${JSON.stringify(slug)}`, () => assert.equal(isValidSlug(slug), false));
  }
  for (const slug of RESERVED) {
    it(`rejeita reservado ${slug}`, () => assert.equal(isValidSlug(slug), false));
  }
  it('rejeita não string', () => {
    assert.equal(isValidSlug(null), false);
    assert.equal(isValidSlug(42), false);
  });
  it('lista de reservados completa', () => {
    assert.deepEqual([...RESERVED_SLUGS].sort(), [...RESERVED].sort());
  });
});

describe('normalizeSlug e parseSlug', () => {
  it('faz trim e minúsculas', () => {
    assert.equal(normalizeSlug('  Cafe-Do-Ze '), 'cafe-do-ze');
    assert.equal(parseSlug('  Cafe-Do-Ze '), 'cafe-do-ze');
  });
  it('devolve null se inválido', () => {
    assert.equal(parseSlug('-x-'), null);
    assert.equal(parseSlug(undefined), null);
  });
});

describe('nextSlugRate', () => {
  const opts = { max: 3, windowMs: 1000 };

  it('bloqueia depois do limite e libera após a janela', () => {
    let current = null;
    for (let i = 0; i < 3; i += 1) {
      const st = nextSlugRate(current, 1000 + i, opts);
      assert.equal(st.limited, false);
      current = st.timestamps;
    }
    const blocked = nextSlugRate(current, 1500, opts);
    assert.equal(blocked.limited, true);
    assert.equal(blocked.timestamps.length, 3);
    assert.equal(nextSlugRate(current, 2500, opts).limited, false);
  });

  it('estado inválido conta como vazio', () => {
    assert.equal(nextSlugRate('lixo', 1000, opts).limited, false);
  });

  it('limites padrão: 30 por uid e 120 por IP por minuto', () => {
    assert.deepEqual(SLUG_RATE_USER, { max: 30, windowMs: 60000 });
    assert.deepEqual(SLUG_RATE_IP, { max: 120, windowMs: 60000 });
  });
});

describe('hashIp', () => {
  it('é estável, curto e não expõe o IP', () => {
    const h = hashIp('203.0.113.9');
    assert.equal(h, hashIp(' 203.0.113.9 '));
    assert.match(h, /^[0-9a-f]{24}$/);
    assert.ok(!h.includes('203'));
    assert.notEqual(h, hashIp('203.0.113.10'));
  });

  it('sem IP devolve null', () => {
    assert.equal(hashIp(undefined), null);
    assert.equal(hashIp(''), null);
  });
});

describe('tombstone', () => {
  it('reconhece slug liberado', () => {
    assert.equal(isReleasedSlug({ released: true }), true);
    assert.equal(isReleasedSlug({ queueId: 'q' }), false);
    assert.equal(isReleasedSlug(undefined), false);
  });

  it('reserva por 30 dias', () => {
    assert.equal(SLUG_RELEASE_DAYS, 30);
  });
});

describe('link curto sincronizado entre módulos', () => {
  it('monta a URL curta', () => {
    assert.equal(shortUrl('cafe'), 'https://qio.web.app/n/cafe');
  });

  const listFrom = (source, re) => {
    const m = source.match(re);
    assert.ok(m, 'lista não encontrada');
    return [...m[1].matchAll(/'([^']+)'/g)].map((x) => x[1]).sort();
  };
  const expected = [...RESERVED_SLUGS].sort();

  it('app Flutter usa o mesmo prefixo e o mesmo conjunto de reservados', () => {
    assert.ok(read('app/lib/services/join_url.dart').includes(`'${SHORT_PATH_PREFIX}'`));
    const slugDart = read('app/lib/services/slug.dart');
    assert.deepEqual(listFrom(slugDart, /slugReserved\s*=\s*<String>\[([^\]]*)\]/), expected);
  });

  it('rules do Firestore têm exatamente os mesmos reservados', () => {
    const rules = read('firestore.rules');
    assert.deepEqual(listFrom(rules, /!\(slug in \[([^\]]*)\]\)/), expected);
  });

  it('web tem exatamente os mesmos reservados', () => {
    const ts = read('web/src/lib/slug.ts');
    assert.deepEqual(listFrom(ts, /RESERVED_SLUGS\s*=\s*\[([^\]]*)\]/), expected);
  });

  it('lista de reservados bate com a esperada pela spec', () => {
    assert.deepEqual(expected, [...RESERVED].sort());
  });
});
