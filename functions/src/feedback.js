const MAX_COMMENT_LENGTH = 300;

function normalizeRating(value) {
  if (typeof value !== 'number' || !Number.isInteger(value)) return null;
  return value >= 1 && value <= 5 ? value : null;
}

function normalizeComment(value) {
  if (value === undefined || value === null) return '';
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length <= MAX_COMMENT_LENGTH ? trimmed : null;
}

function isValidId(value) {
  return (
    typeof value === 'string' &&
    value.length > 0 &&
    value.length <= 128 &&
    !/[\/.#$\[\]]/.test(value)
  );
}

function buildFeedbackDoc({ rating, comment, uid }, now) {
  return { rating, comment, uid, createdAt: now };
}

module.exports = {
  MAX_COMMENT_LENGTH,
  normalizeRating,
  normalizeComment,
  isValidId,
  buildFeedbackDoc,
};
