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
