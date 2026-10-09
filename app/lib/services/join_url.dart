const joinHost = 'qio.web.app';
const joinPathPrefix = '/q/';
const clientPathPrefix = '/c/';
const shortPathPrefix = '/n/';

String joinUrl(String queueId) => 'https://$joinHost$joinPathPrefix$queueId';

String shortUrl(String slug) => 'https://$joinHost$shortPathPrefix$slug';

String queueLinkUrl(String queueId, String? slug) =>
    slug == null || slug.isEmpty ? joinUrl(queueId) : shortUrl(slug);

Uri clientUrl(String queueId) =>
    Uri.https(joinHost, '$clientPathPrefix$queueId');
