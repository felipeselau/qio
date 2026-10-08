const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JOIN_HOST, JOIN_PATH_PREFIX, joinUrl } = require('../src/urls');

const root = path.join(__dirname, '..', '..');
const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');

function dartConst(source, name) {
  const m = source.match(new RegExp(`const\\s+${name}\\s*=\\s*'([^']*)'`));
  assert.ok(m, `constante ${name} não encontrada em join_url.dart`);
  return m[1];
}

describe('joinUrl', () => {
  it('monta a URL de entrada na fila', () => {
    assert.equal(joinUrl('abc'), 'https://qio.web.app/q/abc');
  });
});

describe('URL de join sincronizada entre módulos', () => {
  const dart = read('app/lib/services/join_url.dart');

  it('app Flutter usa o mesmo host e path', () => {
    assert.equal(dartConst(dart, 'joinHost'), JOIN_HOST);
    assert.equal(dartConst(dart, 'joinPathPrefix'), JOIN_PATH_PREFIX);
  });

  it('App Links do AndroidManifest usam o mesmo host e path', () => {
    const manifest = read('app/android/app/src/main/AndroidManifest.xml');
    assert.ok(manifest.includes(`android:host="${JOIN_HOST}"`));
    assert.ok(manifest.includes(`android:pathPrefix="${JOIN_PATH_PREFIX}"`));
  });

  it('nenhum outro arquivo de código hardcoda a URL de join', () => {
    const files = [
      'app/lib/services/queue_service.dart',
      'app/lib/services/deep_link.dart',
      'functions/index.js',
      'functions/src/webpush.js',
      'functions/src/push.js',
    ];
    for (const f of files) {
      assert.ok(!read(f).includes(JOIN_HOST), `${f} não deve repetir ${JOIN_HOST}`);
    }
  });
});
