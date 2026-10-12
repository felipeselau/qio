import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/services/group_history.dart';

final base = DateTime(2025, 6, 15, 12);

HistoryEntry h(String id, int ticket, int minutesAgo, {String? phone}) =>
    HistoryEntry(
      id: id,
      ticket: ticket,
      name: 'C$ticket',
      phone: phone,
      result: 'served',
      joinedAt: base.subtract(Duration(minutes: minutesAgo + 10)),
      finishedAt: base.subtract(Duration(minutes: minutesAgo)),
    );

GroupHistorySlice slice(
  String id,
  String name,
  List<HistoryEntry> entries, {
  List<QueueFeedback> feedback = const [],
}) => GroupHistorySlice(
  queueId: id,
  queueName: name,
  entries: entries,
  feedback: feedback,
);

void main() {
  test('merges queues by finish time descending', () {
    final r = mergeGroupHistory([
      slice('a', 'Padaria', [h('1', 1, 5), h('2', 2, 30)]),
      slice('b', 'Clinica', [h('3', 3, 10), h('4', 4, 1)]),
    ]);
    expect(r.items.map((i) => i.entry.id), ['4', '1', '3', '2']);
    expect(r.items.map((i) => i.queueName), [
      'Clinica',
      'Padaria',
      'Clinica',
      'Padaria',
    ]);
    expect(r.queueCount, 2);
    expect(r.truncated, isFalse);
  });

  test('ties break by queue name, ticket desc, queue id and entry id', () {
    final r = mergeGroupHistory([
      slice('b', 'Beta', [h('x', 1, 5)]),
      slice('a', 'Alfa', [h('y', 2, 5), h('z', 7, 5)]),
      slice('c', 'Alfa', [h('w', 7, 5)]),
    ]);
    expect(r.items.map((i) => i.entry.id), ['z', 'w', 'y', 'x']);
  });

  test('is deterministic regardless of slice order', () {
    final a = slice('a', 'A', [h('1', 1, 5), h('2', 2, 5)]);
    final b = slice('b', 'A', [h('3', 2, 5)]);
    final one = mergeGroupHistory([a, b]).items.map((i) => i.entry.id);
    final two = mergeGroupHistory([b, a]).items.map((i) => i.entry.id);
    expect(one, two);
  });

  test('caps each queue and reports only the truncated ones', () {
    final r = mergeGroupHistory([
      slice('a', 'Cheia', [for (var i = 0; i < 5; i++) h('a$i', i, i)]),
      slice('b', 'Curta', [h('b0', 9, 0), h('b1', 10, 1)]),
    ], limitPerQueue: 5);
    expect(r.truncatedQueueNames, ['Cheia']);
    expect(r.items.length, 7);
    final capped = mergeGroupHistory([
      slice('a', 'Cheia', [for (var i = 0; i < 8; i++) h('a$i', i, i)]),
    ], limitPerQueue: 5);
    expect(capped.items.map((i) => i.entry.id), ['a0', 'a1', 'a2', 'a3', 'a4']);
    expect(capped.truncated, isTrue);
  });

  test('feedback of dropped entries is discarded', () {
    final r = mergeGroupHistory([
      slice(
        'a',
        'A',
        [h('keep', 1, 1), h('drop', 2, 99)],
        feedback: const [
          QueueFeedback(entryId: 'keep', rating: 5),
          QueueFeedback(entryId: 'drop', rating: 1),
        ],
      ),
    ], limitPerQueue: 1);
    expect(r.feedback.map((f) => f.entryId), ['keep']);
  });

  test('empty input and empty queues', () {
    final r = mergeGroupHistory(const []);
    expect(r.items, isEmpty);
    expect(r.queueCount, 0);
    final s = mergeGroupHistory([slice('a', 'A', const [])]);
    expect(s.items, isEmpty);
    expect(s.queueCount, 1);
    expect(s.truncated, isFalse);
  });

  test('pageOf grows by pages and never overshoots', () {
    final items = List.generate(120, (i) => i);
    expect(pageOf(items, 0).length, 50);
    expect(pageOf(items, 1).length, 100);
    expect(pageOf(items, 2).length, 120);
    expect(pageOf(items, 9).length, 120);
    expect(pageOf(<int>[], 0), isEmpty);
    expect(pageOf(items, 0, pageSize: 7).length, 7);
  });
}
