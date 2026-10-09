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

function slugRateLimited(buckets, key, now, max = 30, windowMs = 60_000) {
  const recent = (buckets.get(key) ?? []).filter((t) => now - t < windowMs);
  if (recent.length >= max) {
    buckets.set(key, recent);
    return true;
  }
  recent.push(now);
  buckets.set(key, recent);
  if (buckets.size > 5000) {
    for (const [k, v] of buckets) {
      if (v.every((t) => now - t >= windowMs)) buckets.delete(k);
    }
  }
  return false;
}

module.exports = {
  SLUG_PATTERN,
  RESERVED_SLUGS,
  normalizeSlug,
  isValidSlug,
  parseSlug,
  slugRateLimited,
};
