const fs = require('node:fs');
const path = require('node:path');

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-qio';

const mod = require(path.resolve(__dirname, '..', 'index.js'));
const out = {};
for (const name of Object.keys(mod).sort()) {
  const fn = mod[name];
  out[name] = fn?.__endpoint ?? { kind: typeof fn };
}
const json = JSON.stringify(out, null, 2);
const target = process.argv[2];
if (target) {
  fs.writeFileSync(target, `${json}\n`);
  console.log(`${Object.keys(out).length} exports -> ${target}`);
} else {
  console.log(json);
}
process.exit(0);
