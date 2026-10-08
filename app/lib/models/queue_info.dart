const defaultAvgServiceMin = 10;
const queueNameMaxLength = 60;
const queueDescriptionMaxLength = 300;
const avgServiceMinRange = (1, 240);

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
}

String duplicateQueueName(String name, String suffix) {
  final room = queueNameMaxLength - suffix.length;
  final base = name.trim();
  final cut = base.length > room ? base.substring(0, room).trimRight() : base;
  return '$cut$suffix';
}
