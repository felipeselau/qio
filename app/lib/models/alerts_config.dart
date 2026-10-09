enum AlertsError { noRule, maxWait, maxNoShow, idle, cooldown }

class AlertsConfig {
  const AlertsConfig({
    this.enabled = false,
    this.maxWaitMin,
    this.maxNoShowPct,
    this.idleMin,
    this.cooldownMin = defaultCooldownMin,
  });

  static const defaultCooldownMin = 30;
  static const cooldownOptions = [5, 15, 30, 60, 120];
  static const waitRange = (1, 240);
  static const noShowRange = (1, 100);
  static const idleRange = (5, 240);
  static const cooldownRange = (5, 1440);

  final bool enabled;
  final int? maxWaitMin;
  final int? maxNoShowPct;
  final int? idleMin;
  final int cooldownMin;

  int get activeRules =>
      [maxWaitMin, maxNoShowPct, idleMin].where((v) => v != null).length;

  static int? _limit(Object? v, (int, int) range) {
    if (v is! num) return null;
    final n = v.toInt();
    return n >= range.$1 && n <= range.$2 ? n : null;
  }

  static AlertsConfig? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final cooldown = (raw['cooldownMin'] as num?)?.toInt();
    return AlertsConfig(
      enabled: raw['enabled'] == true,
      maxWaitMin: _limit(raw['maxWaitMin'], waitRange),
      maxNoShowPct: _limit(raw['maxNoShowPct'], noShowRange),
      idleMin: _limit(raw['idleMin'], idleRange),
      cooldownMin: cooldown != null && cooldown >= 5 && cooldown <= 1440
          ? cooldown
          : defaultCooldownMin,
    );
  }

  AlertsConfig copyWith({
    bool? enabled,
    int? Function()? maxWaitMin,
    int? Function()? maxNoShowPct,
    int? Function()? idleMin,
    int? cooldownMin,
  }) => AlertsConfig(
    enabled: enabled ?? this.enabled,
    maxWaitMin: maxWaitMin != null ? maxWaitMin() : this.maxWaitMin,
    maxNoShowPct: maxNoShowPct != null ? maxNoShowPct() : this.maxNoShowPct,
    idleMin: idleMin != null ? idleMin() : this.idleMin,
    cooldownMin: cooldownMin ?? this.cooldownMin,
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'maxWaitMin': ?maxWaitMin,
    'maxNoShowPct': ?maxNoShowPct,
    'idleMin': ?idleMin,
    'cooldownMin': cooldownMin,
  };

  static bool _inRange(int? v, (int, int) range) =>
      v == null || (v >= range.$1 && v <= range.$2);

  AlertsError? validate() {
    if (!enabled) return null;
    if (!_inRange(maxWaitMin, waitRange)) return AlertsError.maxWait;
    if (!_inRange(maxNoShowPct, noShowRange)) return AlertsError.maxNoShow;
    if (!_inRange(idleMin, idleRange)) return AlertsError.idle;
    if (!_inRange(cooldownMin, cooldownRange)) return AlertsError.cooldown;
    if (activeRules == 0) return AlertsError.noRule;
    return null;
  }
}
