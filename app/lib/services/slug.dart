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

const slugReleaseDays = 30;

enum SlugAvailability { free, mine, taken }

SlugAvailability slugAvailability({
  required bool exists,
  required String uid,
  required DateTime now,
  bool released = false,
  String? ownerId,
  DateTime? releasedAt,
}) {
  if (!exists) return SlugAvailability.free;
  if (!released) return SlugAvailability.taken;
  if (ownerId == uid) return SlugAvailability.mine;
  if (releasedAt != null &&
      now.isAfter(releasedAt.add(const Duration(days: slugReleaseDays)))) {
    return SlugAvailability.free;
  }
  return SlugAvailability.taken;
}

bool canReleaseSlug({
  required bool exists,
  required String uid,
  required String queueId,
  bool released = false,
  String? ownerId,
  String? docQueueId,
}) => exists && !released && ownerId == uid && docQueueId == queueId;
