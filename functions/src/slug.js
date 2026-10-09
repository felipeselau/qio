const crypto = require('node:crypto');
const { pruneTimestamps, isRateLimited } = require('./join');

const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
const RESERVED_SLUGS = [
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

function normalizeSlug(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function isValidSlug(value) {
  return (
    typeof value === 'string' &&
    SLUG_PATTERN.test(value) &&
    !RESERVED_SLUGS.includes(value)
  );
}

function parseSlug(value) {
  const slug = normalizeSlug(value);
  return isValidSlug(slug) ? slug : null;
}

const SLUG_RATE_USER = { max: 30, windowMs: 60_000 };
const SLUG_RATE_IP = { max: 120, windowMs: 60_000 };
const SLUG_RELEASE_DAYS = 30;

function nextSlugRate(current, now, options) {
  const recent = pruneTimestamps(current, now, options.windowMs);
  if (isRateLimited(recent, now, options)) {
    return { limited: true, timestamps: recent };
  }
  return { limited: false, timestamps: [...recent, now] };
}

function hashIp(ip) {
  if (typeof ip !== 'string' || ip.trim() === '') return null;
  return crypto.createHash('sha256').update(ip.trim()).digest('hex').slice(0, 24);
}

function isReleasedSlug(data) {
  return !!data && data.released === true;
}

module.exports = {
  SLUG_PATTERN,
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
};
