const SPECIFIC_FLAGS = {
  joinQueue: 'ENFORCE_APP_CHECK_JOIN',
  submitFeedback: 'ENFORCE_APP_CHECK_FEEDBACK',
};

function normalize(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function isEnforced(callable, env = process.env) {
  const specific = normalize(env[SPECIFIC_FLAGS[callable]]);
  if (specific === 'true' || specific === 'false') return specific === 'true';
  return normalize(env.ENFORCE_APP_CHECK) === 'true';
}

module.exports = { isEnforced };
