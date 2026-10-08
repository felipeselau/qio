import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/services/queue_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_services.dart';

void main() {
  final a = fakeQueue('a', name: 'Padaria');
  final b = fakeQueue('b', name: 'Açougue');
  final c = fakeQueue('c', name: 'banco');
  final queues = [a, b, c];

  List<String> ids(List<Queue> l) => l.map((q) => q.id).toList();

  test('tools only above five queues', () {
    expect(showQueueTools(5), isFalse);
    expect(showQueueTools(6), isTrue);
  });

  test('sorts by name ignoring case and accents', () {
    expect(ids(filterAndSortQueues(queues)), ['b', 'c', 'a']);
  });

  test('sorts by most recent first', () {
    final old = Queue(
      id: 'old',
      ownerId: 'u',
      name: 'Velha',
      createdAt: DateTime(2020),
    );
    final fresh = Queue(
      id: 'fresh',
      ownerId: 'u',
      name: 'Nova',
      createdAt: DateTime(2026),
    );
    expect(ids(filterAndSortQueues([old, fresh], sort: QueueSort.recent)), [
      'fresh',
      'old',
    ]);
  });

  test('sorts by waiting count descending with name tiebreak', () {
    expect(
      ids(
        filterAndSortQueues(
          queues,
          sort: QueueSort.waiting,
          waiting: {'a': 2, 'b': 2, 'c': 5},
        ),
      ),
      ['c', 'b', 'a'],
    );
  });

  test('filters by accent-insensitive substring', () {
    expect(ids(filterAndSortQueues(queues, query: ' acou ')), ['b']);
    expect(filterAndSortQueues(queues, query: 'zzz'), isEmpty);
  });

  test('does not mutate the input', () {
    filterAndSortQueues(queues);
    expect(ids(queues), ['a', 'b', 'c']);
  });

  test('prefs round trip and fall back to name', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await QueueSortPrefs.load(), QueueSort.name);
    await QueueSortPrefs.save(QueueSort.waiting);
    expect(await QueueSortPrefs.load(), QueueSort.waiting);
    SharedPreferences.setMockInitialValues({QueueSortPrefs.key: 'bogus'});
    expect(await QueueSortPrefs.load(), QueueSort.name);
  });
}
