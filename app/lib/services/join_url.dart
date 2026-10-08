const joinHost = 'qio.web.app';
const joinPathPrefix = '/q/';
const clientPathPrefix = '/c/';

String joinUrl(String queueId) => 'https://$joinHost$joinPathPrefix$queueId';

Uri clientUrl(String queueId) => Uri.https(joinHost, '$clientPathPrefix$queueId');
