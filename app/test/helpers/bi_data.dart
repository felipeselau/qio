import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue_goals.dart';
import 'package:qio_app/services/metrics_export.dart';

import 'fake_services.dart';

final biNow = DateTime(2025, 6, 15, 12);

HistoryEntry biEntry(
  String id, {
  String result = 'served',
  required DateTime joined,
  DateTime? called,
  DateTime? finished,
  String? calledBy,
  int? estimateMin,
}) => HistoryEntry(
  id: id,
  ticket: 1,
  name: 'n$id',
  result: result,
  joinedAt: joined,
  calledAt: called,
  finishedAt: finished,
  calledBy: calledBy,
  estimateMin: estimateMin,
);

HistoryEntry _handled(
  String id,
  String who,
  DateTime called,
  int serviceMin, {
  String result = 'served',
}) => biEntry(
  id,
  result: result,
  joined: called.subtract(const Duration(minutes: 30)),
  called: called,
  finished: called.add(Duration(minutes: serviceMin)),
  calledBy: who,
);

List<HistoryEntry> attendantEntries() => [
  for (var k = 0; k < 4; k++)
    _handled('a$k', 'op1', DateTime.utc(2025, 6, 14, 15, 15 * k), 5),
  for (var k = 0; k < 4; k++)
    _handled('b$k', 'op2', DateTime.utc(2025, 6, 14, 18, 20 * k), 15),
  _handled('bn', 'op2', DateTime.utc(2025, 6, 13, 18), 0, result: 'no_show'),
];

HistoryEntry oldAttendantEntry() =>
    _handled('old', 'op1', DateTime.utc(2025, 5, 26, 15), 5);

List<HistoryEntry> abandonEntries({bool estimates = true}) {
  int? est(int v) => estimates ? v : null;
  return [
    for (var k = 0; k < 5; k++)
      biEntry(
        'h9-$k',
        joined: DateTime.utc(2025, 6, 14, 12, k),
        called: DateTime.utc(2025, 6, 14, 12, k + 2),
        finished: DateTime.utc(2025, 6, 14, 12, k + 5),
        estimateMin: est(3),
      ),
    for (var k = 0; k < 5; k++)
      biEntry(
        'h11-$k',
        joined: DateTime.utc(2025, 6, 14, 14, k),
        called: DateTime.utc(2025, 6, 14, 14, k + 20),
        finished: DateTime.utc(2025, 6, 14, 14, k + 25),
        estimateMin: est(12),
      ),
    for (var k = 0; k < 4; k++)
      biEntry(
        'l11-$k',
        result: 'left',
        joined: DateTime.utc(2025, 6, 14, 14, 10 + k),
        finished: DateTime.utc(2025, 6, 14, 14, 35 + k),
        estimateMin: est(12),
      ),
  ];
}

QueueOperator biOp(String uid, String name) => QueueOperator(
  uid: uid,
  queueId: 'a',
  queueName: 'Padaria',
  displayName: name,
);

const biGoals = QueueGoals(maxWaitMin: 10, maxServiceMin: 5, targetPct: 80);

List<HistoryEntry> goalEntries() {
  const waits = [5, 8, 10, 11, 20];
  const services = [3, 4, 5, 5, 9];
  return [
    for (var i = 0; i < 5; i++)
      biEntry(
        'g$i',
        joined: DateTime.utc(2025, 6, 14, 15),
        called: DateTime.utc(2025, 6, 14, 15, waits[i]),
        finished: DateTime.utc(2025, 6, 14, 15, waits[i] + services[i]),
        calledBy: 'op1',
      ),
  ];
}

List<HistoryEntry> planningEntries() {
  final out = <HistoryEntry>[];
  for (final monday in [
    DateTime.utc(2025, 5, 12),
    DateTime.utc(2025, 5, 19),
    DateTime.utc(2025, 5, 26),
    DateTime.utc(2025, 6, 2),
  ]) {
    for (var i = 0; i < 6; i++) {
      final at = monday.add(Duration(hours: 15, minutes: i));
      out.add(
        biEntry(
          'p${monday.month}${monday.day}-$i',
          joined: at,
          called: at,
          finished: at.add(const Duration(minutes: 20)),
          calledBy: i < 3 ? 'op1' : 'op2',
        ),
      );
    }
  }
  for (var i = 0; i < 4; i++) {
    final at = DateTime.utc(2025, 6, 9, 15, i);
    out.add(
      biEntry(
        'c$i',
        joined: at,
        called: at,
        finished: at.add(const Duration(minutes: 20)),
        calledBy: i < 2 ? 'op1' : 'op2',
      ),
    );
  }
  for (var i = 0; i < 2; i++) {
    final at = DateTime.utc(2025, 6, 10, 13, i);
    out.add(
      biEntry(
        'cl$i',
        result: 'left',
        joined: at,
        finished: at.add(const Duration(minutes: 1)),
      ),
    );
  }
  return out;
}

List<QueueHistoryInput> biData(
  List<HistoryEntry> entries, {
  List<QueueOperator>? operators,
  QueueGoals? goals,
}) => [
  QueueHistoryInput(
    fakeQueue('a', name: 'Padaria', goals: goals),
    entries,
    const [],
    operators ?? [biOp('op1', 'Ana'), biOp('op2', 'Bia')],
  ),
];
