class ExpiryConfig {
  const ExpiryConfig({
    this.enabled = false,
    this.hours = defaultHours,
    this.clearOnClose = false,
    this.resetTicketDaily = false,
  });

  static const defaultHours = 12;
  static const hourOptions = [1, 2, 4, 6, 8, 12, 24, 36, 48];

  final bool enabled;
  final int hours;
  final bool clearOnClose;
  final bool resetTicketDaily;

  ExpiryConfig copyWith({
    bool? enabled,
    int? hours,
    bool? clearOnClose,
    bool? resetTicketDaily,
  }) {
    return ExpiryConfig(
      enabled: enabled ?? this.enabled,
      hours: hours ?? this.hours,
      clearOnClose: clearOnClose ?? this.clearOnClose,
      resetTicketDaily: resetTicketDaily ?? this.resetTicketDaily,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'hours': hours,
    'clearOnClose': clearOnClose,
    'resetTicketDaily': resetTicketDaily,
  };

  static ExpiryConfig? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final rawHours = raw['hours'];
    final hours = rawHours is num ? rawHours.toInt() : null;
    return ExpiryConfig(
      enabled: raw['enabled'] == true,
      hours: hours != null && hours >= 1 && hours <= 48 ? hours : defaultHours,
      clearOnClose: raw['clearOnClose'] == true,
      resetTicketDaily: raw['resetTicketDaily'] == true,
    );
  }
}
