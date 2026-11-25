const Duration _spOffset = Duration(hours: 3);

DateTime spLocal(DateTime t) => t.toUtc().subtract(_spOffset);

DateTime spDay(DateTime t) {
  final l = spLocal(t);
  return DateTime.utc(l.year, l.month, l.day);
}

int spHour(DateTime t) => spLocal(t).hour;
