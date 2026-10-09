typedef UrlLauncher = Future<bool> Function(Uri uri);

Uri? phoneToTelUri(String? phone) {
  if (phone == null) return null;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10 && digits.length != 11) return null;
  return Uri(scheme: 'tel', path: digits);
}
