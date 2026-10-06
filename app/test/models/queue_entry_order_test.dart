import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';

QueueEntry entry(String id, int ticket, int joined, {int? order}) => QueueEntry(
  id: id,
  ticket: ticket,
  name: id,
  uid: 'u$id',
  status: EntryStatus.waiting,
  joinedAt: DateTime.fromMillisecondsSinceEpoch(joined),
  order: order,
);

void main() {
  test('sorts by joinedAt when no order is set, ticket breaks ties', () {
    final list = [entry('c', 3, 300), entry('a', 1, 100), entry('b', 2, 100)]
      ..sort(QueueEntry.compareInQueue);
    expect(list.map((e) => e.id), ['a', 'b', 'c']);
  });

  test('an explicit order sends the entry behind later joiners', () {
    final list = [
      entry('a', 1, 100, order: 500),
      entry('b', 2, 200),
      entry('c', 3, 300),
    ]..sort(QueueEntry.compareInQueue);
    expect(list.map((e) => e.id), ['b', 'c', 'a']);
  });

  test('parses order, recalls, skips and recalledAt', () {
    final e = QueueEntry.fromSnapshot('x', {
      'ticket': 5,
      'status': 'called',
      'uid': 'u',
      'name': 'N',
      'joinedAt': 1000,
      'order': 2000,
      'recalls': 2,
      'skips': 1,
      'recalledAt': 3000,
    });
    expect(e.order, 2000);
    expect(e.recalls, 2);
    expect(e.skips, 1);
    expect(e.recalledAt, DateTime.fromMillisecondsSinceEpoch(3000));
    expect(e.sortOrder, 2000);
    final plain = QueueEntry.fromSnapshot('y', {
      'ticket': 1,
      'uid': 'u',
      'joinedAt': 7,
    });
    expect(plain.recalls, 0);
    expect(plain.skips, 0);
    expect(plain.sortOrder, 7);
  });
}
