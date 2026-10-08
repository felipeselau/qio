const SPECIFIC_FLAGS = {
  joinQueue: 'ENFORCE_APP_CHECK_JOIN',
  submitFeedback: 'ENFORCE_APP_CHECK_FEEDBACK',
};

function isEnforced(callable, env = process.env) {
  const specific = env[SPECIFIC_FLAGS[callable]];
  if (specific === 'true' || specific === 'false') return specific === 'true';
  return env.ENFORCE_APP_CHECK === 'true';
}

module.exports = { isEnforced };
