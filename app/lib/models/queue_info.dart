const defaultAvgServiceMin = 10;
const queueNameMaxLength = 60;
const fallbackQueueName = 'Fila';
const queueDescriptionMaxLength = 300;
const avgServiceMinRange = (1, 240);

const maxWaitingRange = (1, 1000);

enum MaxWaitingError { invalid }

MaxWaitingError? validateMaxWaitingText(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final n = int.tryParse(text);
  if (n == null || n < maxWaitingRange.$1 || n > maxWaitingRange.$2) {
    return MaxWaitingError.invalid;
  }
  return null;
}

enum QueueInfoError {
  nameRequired,
  nameTooLong,
  descriptionTooLong,
  avgServiceInvalid,
}

class QueueInfo {
  const QueueInfo({
    required this.name,
    this.description,
    this.avgServiceMin = defaultAvgServiceMin,
  });

  final String name;
  final String? description;
  final int avgServiceMin;

  static String? normalizeDescription(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static QueueInfoError? validateName(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return QueueInfoError.nameRequired;
    if (text.length > queueNameMaxLength) return QueueInfoError.nameTooLong;
    return null;
  }

  static QueueInfoError? validateDescription(String? raw) {
    if ((raw?.trim().length ?? 0) > queueDescriptionMaxLength) {
      return QueueInfoError.descriptionTooLong;
    }
    return null;
  }

  static QueueInfoError? validateAvgServiceMin(int? value) {
    if (value == null ||
        value < avgServiceMinRange.$1 ||
        value > avgServiceMinRange.$2) {
      return QueueInfoError.avgServiceInvalid;
    }
    return null;
  }

  static int? parseAvgServiceMin(String? raw) =>
      int.tryParse(raw?.trim() ?? '');

  QueueInfoError? get error =>
      validateName(name) ??
      validateDescription(description) ??
      validateAvgServiceMin(avgServiceMin);

  QueueInfo normalized() => QueueInfo(
    name: name.trim(),
    description: normalizeDescription(description),
    avgServiceMin: avgServiceMin,
  );

  Map<String, Object?> toFields() => {
    'name': name,
    'description': description,
    'avgServiceMin': avgServiceMin,
  };

  factory QueueInfo.forMirror({
    required String name,
    String? description,
    required int avgServiceMin,
  }) {
    final trimmed = name.trim();
    final safeName = trimmed.isEmpty
        ? fallbackQueueName
        : trimmed.length > queueNameMaxLength
        ? trimmed.substring(0, queueNameMaxLength).trimRight()
        : trimmed;
    final desc = normalizeDescription(description);
    return QueueInfo(
      name: safeName.isEmpty ? fallbackQueueName : safeName,
      description: desc != null && desc.length > queueDescriptionMaxLength
          ? desc.substring(0, queueDescriptionMaxLength)
          : desc,
      avgServiceMin: validateAvgServiceMin(avgServiceMin) == null
          ? avgServiceMin
          : defaultAvgServiceMin,
    );
  }

  Map<String, Object?> changesFrom(QueueInfo current) {
    final from = current.normalized();
    final to = normalized();
    return {
      if (to.name != from.name) 'name': to.name,
      if (to.description != from.description) 'description': to.description,
      if (to.avgServiceMin != from.avgServiceMin)
        'avgServiceMin': to.avgServiceMin,
    };
  }

  QueueInfoError? errorForChanges(Map<String, Object?> changes) {
    if (changes.containsKey('name')) {
      final e = validateName(name);
      if (e != null) return e;
    }
    if (changes.containsKey('description')) {
      final e = validateDescription(description);
      if (e != null) return e;
    }
    if (changes.containsKey('avgServiceMin')) {
      return validateAvgServiceMin(avgServiceMin);
    }
    return null;
  }
}

Map<String, Object?>? mirrorInfoPatch(
  Map<dynamic, dynamic>? meta,
  QueueInfo doc,
) {
  if (meta == null) return null;
  final expected = QueueInfo.forMirror(
    name: doc.name,
    description: doc.description,
    avgServiceMin: doc.avgServiceMin,
  );
  final rawDesc = meta['description'];
  final current = (
    name: meta['name'],
    description: rawDesc is String && rawDesc.isNotEmpty ? rawDesc : null,
    avg: meta['avgServiceMin'] is num
        ? (meta['avgServiceMin'] as num).toDouble()
        : null,
  );
  final patch = <String, Object?>{
    if (current.name != expected.name) 'name': expected.name,
    if (current.description != expected.description)
      'description': expected.description,
    if (current.avg != expected.avgServiceMin.toDouble())
      'avgServiceMin': expected.avgServiceMin,
  };
  return patch.isEmpty ? null : patch;
}

String duplicateQueueName(String name, String copyWord) {
  final base = name.trim();
  final match = RegExp(
    '^(.*?) \\(${RegExp.escape(copyWord)}(?: (\\d+))?\\)\$',
  ).firstMatch(base);
  final root = match != null ? match.group(1)! : base;
  final n = match == null ? 1 : (int.tryParse(match.group(2) ?? '') ?? 1) + 1;
  final suffix = n == 1 ? ' ($copyWord)' : ' ($copyWord $n)';
  final room = queueNameMaxLength - suffix.length;
  final cut = root.length > room ? root.substring(0, room).trimRight() : root;
  return '$cut$suffix';
}
