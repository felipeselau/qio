const SPECIFIC_FLAGS = {
  joinQueue: 'ENFORCE_APP_CHECK_JOIN',
  submitFeedback: 'ENFORCE_APP_CHECK_FEEDBACK',
  deleteQueue: 'ENFORCE_APP_CHECK_DELETE',
  deleteAccount: 'ENFORCE_APP_CHECK_DELETE',
  findCustomerData: 'ENFORCE_APP_CHECK_DSR',
  exportCustomerData: 'ENFORCE_APP_CHECK_DSR',
  eraseCustomerData: 'ENFORCE_APP_CHECK_DSR',
};

const OPT_IN_ONLY = new Set([
  'deleteQueue',
  'deleteAccount',
  'findCustomerData',
  'exportCustomerData',
  'eraseCustomerData',
]);

function normalize(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function isEnforced(callable, env = process.env) {
  const specific = normalize(env[SPECIFIC_FLAGS[callable]]);
  if (specific === 'true' || specific === 'false') return specific === 'true';
  if (OPT_IN_ONLY.has(callable)) return false;
  return normalize(env.ENFORCE_APP_CHECK) === 'true';
}

module.exports = { isEnforced };
