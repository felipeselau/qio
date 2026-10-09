const slugReserved = <String>[
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

final _slugPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$');

enum SlugError { format, reserved }

String normalizeSlug(String value) => value.trim().toLowerCase();

SlugError? slugError(String value) {
  if (!_slugPattern.hasMatch(value)) return SlugError.format;
  if (slugReserved.contains(value)) return SlugError.reserved;
  return null;
}

bool isValidSlug(String value) => slugError(value) == null;
