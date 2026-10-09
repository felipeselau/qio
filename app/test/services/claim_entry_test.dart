import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/services/claim_entry.dart';

void main() {
  Map<String, Object?> entry(String status) => {
    'uid': 'c1',
    'ticket': 4,
    'name': 'Ana',
    'phone': '',
    'status': status,
    'joinedAt': 1000,
  };

  test('claims a waiting entry with operator and provisional calledAt', () {
    final data = claimedEntryData(entry('waiting'), 'op1', 5000)!;
    expect(data['status'], 'called');
    expect(data['operatorId'], 'op1');
    expect(data['calledAt'], 5000);
    expect(data['ticket'], 4);
  });

  test('serverNowMs applies the server offset to the local clock', () {
    expect(serverNowMs(-90000, 1790000100000), 1790000010000);
    expect(serverNowMs(2500.4, 1000), 3500);
    expect(serverNowMs(0, 1000), 1000);
  });

  test('serverNowMs falls back to the local clock without a valid offset', () {
    expect(serverNowMs(null, 1000), 1000);
    expect(serverNowMs('x', 1000), 1000);
  });

  test('does not claim missing or non-waiting entries', () {
    expect(claimedEntryData(null, 'op1', 5000), isNull);
    expect(claimedEntryData(entry('called'), 'op1', 5000), isNull);
    expect(claimedEntryData(entry('left'), 'op1', 5000), isNull);
  });

  test('server calledAt (ms) round-trips into the history Timestamp', () {
    const serverMs = 1790000123456;
    final parsed = QueueEntry.fromSnapshot('e1', {
      ...entry('called'),
      'calledAt': serverMs,
      'operatorId': 'op1',
    });
    final ts = historyTimestamp(parsed.calledAt)!;
    expect(ts.millisecondsSinceEpoch, serverMs);
    expect(historyTimestamp(null), isNull);
  });

  test('wait and service durations follow the stored values', () {
    final h = HistoryEntry(
      id: 'h1',
      ticket: 1,
      name: 'Ana',
      result: 'served',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(1790000000000),
      calledAt: DateTime.fromMillisecondsSinceEpoch(1790000060000),
      finishedAt: DateTime.fromMillisecondsSinceEpoch(1790000240000),
    );
    expect(h.wait, const Duration(minutes: 1));
    expect(h.service, const Duration(minutes: 3));
  });
}
