const _hosts = {'qio.web.app', 'www.qio.web.app'};
final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

String? queueIdFromLink(Uri uri) {
  if (uri.scheme != 'https' || !_hosts.contains(uri.host)) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 || segments.first != 'q') return null;
  final id = segments[1];
  return _idPattern.hasMatch(id) ? id : null;
}

Uri clientUrlForQueue(String queueId) =>
    Uri.https('qio.web.app', '/c/$queueId');
