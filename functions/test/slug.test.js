const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  RESERVED_SLUGS,
  normalizeSlug,
  isValidSlug,
  parseSlug,
  slugRateLimited,
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

describe('slugRateLimited', () => {
  it('bloqueia depois do limite e libera após a janela', () => {
    const buckets = new Map();
    for (let i = 0; i < 3; i += 1) {
      assert.equal(slugRateLimited(buckets, 'u', 1000 + i, 3, 1000), false);
    }
    assert.equal(slugRateLimited(buckets, 'u', 1500, 3, 1000), true);
    assert.equal(slugRateLimited(buckets, 'outro', 1500, 3, 1000), false);
    assert.equal(slugRateLimited(buckets, 'u', 2500, 3, 1000), false);
  });
});

describe('link curto sincronizado entre módulos', () => {
  it('monta a URL curta', () => {
    assert.equal(shortUrl('cafe'), 'https://qio.web.app/n/cafe');
  });

  it('app Flutter usa o mesmo prefixo e reservados', () => {
    assert.ok(read('app/lib/services/join_url.dart').includes(`'${SHORT_PATH_PREFIX}'`));
    const slugDart = read('app/lib/services/slug.dart');
    for (const word of RESERVED_SLUGS) {
      assert.ok(slugDart.includes(`'${word}'`), `slug.dart sem ${word}`);
    }
  });

  it('rules do Firestore listam os mesmos reservados', () => {
    const rules = read('firestore.rules');
    for (const word of RESERVED_SLUGS) {
      assert.ok(rules.includes(`'${word}'`), `rules sem ${word}`);
    }
  });

  it('web tem a mesma lista', () => {
    const ts = read('web/src/lib/slug.ts');
    for (const word of RESERVED_SLUGS) {
      assert.ok(ts.includes(`'${word}'`), `slug.ts sem ${word}`);
    }
  });
});
