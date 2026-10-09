const JOIN_HOST = 'qio.web.app';
const JOIN_PATH_PREFIX = '/q/';
const SHORT_PATH_PREFIX = '/n/';

function joinUrl(queueId) {
  return `https://${JOIN_HOST}${JOIN_PATH_PREFIX}${queueId}`;
}

function shortUrl(slug) {
  return `https://${JOIN_HOST}${SHORT_PATH_PREFIX}${slug}`;
}

module.exports = { JOIN_HOST, JOIN_PATH_PREFIX, SHORT_PATH_PREFIX, joinUrl, shortUrl };
