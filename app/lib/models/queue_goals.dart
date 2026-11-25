enum GoalsError { maxWait, maxService, targetPct, noGoal }

class QueueGoals {
  const QueueGoals({this.maxWaitMin, this.maxServiceMin, this.targetPct});

  static const defaultTargetPct = 80;
  static const waitRange = (1, 240);
  static const serviceRange = (1, 240);
  static const targetRange = (50, 100);

  final int? maxWaitMin;
  final int? maxServiceMin;
  final int? targetPct;

  int get effectiveTargetPct => targetPct ?? defaultTargetPct;

  bool get hasGoal => maxWaitMin != null || maxServiceMin != null;

  static int? _read(Object? v, (int, int) range) {
    if (v is! num || v != v.truncate()) return null;
    final n = v.toInt();
    return n >= range.$1 && n <= range.$2 ? n : null;
  }

  static QueueGoals? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return QueueGoals(
      maxWaitMin: _read(raw['maxWaitMin'], waitRange),
      maxServiceMin: _read(raw['maxServiceMin'], serviceRange),
      targetPct: _read(raw['targetPct'], targetRange),
    );
  }

  Map<String, dynamic> toMap() => {
    'maxWaitMin': ?maxWaitMin,
    'maxServiceMin': ?maxServiceMin,
    'targetPct': ?targetPct,
  };

  static bool _inRange(int? v, (int, int) range) =>
      v == null || (v >= range.$1 && v <= range.$2);

  GoalsError? validate() {
    if (!_inRange(maxWaitMin, waitRange)) return GoalsError.maxWait;
    if (!_inRange(maxServiceMin, serviceRange)) return GoalsError.maxService;
    if (!_inRange(targetPct, targetRange)) return GoalsError.targetPct;
    if (!hasGoal) return GoalsError.noGoal;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is QueueGoals &&
      other.maxWaitMin == maxWaitMin &&
      other.maxServiceMin == maxServiceMin &&
      other.targetPct == targetPct;

  @override
  int get hashCode => Object.hash(maxWaitMin, maxServiceMin, targetPct);
}
