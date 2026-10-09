const test = require('node:test');
const assert = require('node:assert/strict');

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-qio';

const mod = require('../index.js');

const EXPECTED = [
  'addManualEntry',
  'applyQueueSchedules',
  'deleteAccount',
  'deleteQueue',
  'eraseCustomerData',
  'evaluateQueueAlerts',
  'expireStaleEntries',
  'exportCustomerData',
  'findCustomerData',
  'joinQueue',
  'onQueueOpened',
  'purgeOldHistory',
  'reconcileWaitingCounts',
  'resolveSlug',
  'submitFeedback',
  'syncPublicTicket',
  'updateServiceEstimate',
];

test('index.js exporta exatamente as funcoes esperadas', () => {
  assert.deepEqual(Object.keys(mod).sort(), EXPECTED);
  for (const name of EXPECTED) {
    assert.ok(mod[name].__endpoint, `${name} sem __endpoint`);
    assert.deepEqual(mod[name].__endpoint.region, ['us-central1']);
  }
});

test('uma unica funcao escuta queues/{queueId}/entries/{entryId}', () => {
  const listeners = EXPECTED.filter(
    (name) =>
      mod[name].__endpoint.eventTrigger?.eventFilterPathPatterns?.ref ===
      'queues/{queueId}/entries/{entryId}',
  );
  assert.deepEqual(listeners, ['syncPublicTicket']);
});

test('configs preservadas: timeouts, memoria e retry', () => {
  const ep = (name) => mod[name].__endpoint;
  for (const name of ['deleteQueue', 'deleteAccount']) {
    assert.equal(ep(name).timeoutSeconds, 540);
    assert.equal(ep(name).availableMemoryMb, 512);
  }
  for (const name of ['findCustomerData', 'exportCustomerData', 'eraseCustomerData']) {
    assert.equal(ep(name).timeoutSeconds, 300);
    assert.equal(ep(name).availableMemoryMb, 512);
  }
  assert.equal(ep('expireStaleEntries').timeoutSeconds, 540);
  assert.equal(ep('purgeOldHistory').timeoutSeconds, 540);
  assert.equal(ep('applyQueueSchedules').timeoutSeconds, 300);
  assert.equal(ep('evaluateQueueAlerts').timeoutSeconds, 300);
  assert.equal(ep('onQueueOpened').eventTrigger.retry, true);
  assert.equal(ep('syncPublicTicket').eventTrigger.retry, false);
});

test('enforceAppCheck por callable: mesma origem (isEnforced) do original', () => {
  const fs = require('node:fs');
  const path = require('node:path');
  const { isEnforced } = require('../src/appcheck');
  const read = (file) =>
    fs.readFileSync(path.join(__dirname, '..', 'src', 'handlers', `${file}.js`), 'utf8');

  const viaIsEnforced = {
    joinQueue: 'join',
    submitFeedback: 'feedback',
    resolveSlug: 'slug',
    deleteQueue: 'delete',
    deleteAccount: 'delete',
  };
  for (const [name, file] of Object.entries(viaIsEnforced)) {
    assert.match(read(file), new RegExp(`enforceAppCheck: isEnforced\\('${name}'\\)`), name);
  }

  const dsr = read('dsr');
  assert.match(dsr, /enforceAppCheck: isEnforced\(name\)/);
  for (const name of ['findCustomerData', 'exportCustomerData', 'eraseCustomerData']) {
    assert.match(dsr, new RegExp(`dsrCallable\\('${name}'`), name);
  }

  const manual = read('manual');
  assert.match(manual, /enforceAppCheck: false/);
  assert.doesNotMatch(manual, /isEnforced/);

  const on = { ENFORCE_APP_CHECK: 'true' };
  assert.equal(isEnforced('joinQueue', on), true);
  assert.equal(isEnforced('submitFeedback', on), true);
  assert.equal(isEnforced('resolveSlug', on), true);
  for (const name of [
    'deleteQueue',
    'deleteAccount',
    'findCustomerData',
    'exportCustomerData',
    'eraseCustomerData',
  ]) {
    assert.equal(isEnforced(name, on), false, `${name} nao herda ENFORCE_APP_CHECK`);
  }
});
