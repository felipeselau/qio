const JOIN_HOST = 'qio.web.app';
const JOIN_PATH_PREFIX = '/q/';

function joinUrl(queueId) {
  return `https://${JOIN_HOST}${JOIN_PATH_PREFIX}${queueId}`;
}

module.exports = { JOIN_HOST, JOIN_PATH_PREFIX, joinUrl };
