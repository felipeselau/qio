import 'history_metrics.dart';

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  int get days => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  DateRange previous() {
    final n = days;
    return DateRange(DateTime(start.year, start.month, start.day - n), start);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start, $end)';
}

DateRange? rangeFor(HistoryPeriod period, DateTime now, {DateRange? custom}) {
  final today = _dayStart(now);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  switch (period) {
    case HistoryPeriod.today:
      return DateRange(today, tomorrow);
    case HistoryPeriod.last7Days:
      return DateRange(DateTime(now.year, now.month, now.day - 6), tomorrow);
    case HistoryPeriod.all:
      return null;
  }
}
