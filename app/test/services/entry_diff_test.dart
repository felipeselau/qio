import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/services/entry_diff.dart';

QueueEntry entry(String id, EntryStatus status) => QueueEntry(
  id: id,
  ticket: 1,
  name: id,
  uid: 'u$id',
  status: status,
  joinedAt: DateTime(2026),
);

void main() {
  test('primeira emissão é ignorada', () {
    expect(newWaitingIds(null, [entry('a', EntryStatus.waiting)]), isEmpty);
  });

  test('nova entry waiting é detectada', () {
    final result = newWaitingIds(
      {'a'},
      [entry('a', EntryStatus.waiting), entry('b', EntryStatus.waiting)],
    );
    expect(result, {'b'});
  });

  test('entry que sai não conta', () {
    expect(
      newWaitingIds({'a', 'b'}, [entry('a', EntryStatus.waiting)]),
      isEmpty,
    );
  });

  test('entry called não conta', () {
    expect(newWaitingIds({}, [entry('a', EntryStatus.called)]), isEmpty);
  });

  test('múltiplas novas', () {
    final result = newWaitingIds(
      {'a'},
      [
        entry('a', EntryStatus.waiting),
        entry('b', EntryStatus.waiting),
        entry('c', EntryStatus.waiting),
      ],
    );
    expect(result, {'b', 'c'});
  });

  test('waitingIdsOf filtra por status', () {
    expect(
      waitingIdsOf([
        entry('a', EntryStatus.waiting),
        entry('b', EntryStatus.called),
      ]),
      {'a'},
    );
  });
}
