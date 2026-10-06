import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_feedback.dart';

void main() {
  test('summarize empty', () {
    final s = summarizeFeedback(const []);
    expect(s.count, 0);
    expect(s.average, isNull);
  });

  test('summarize averages ratings', () {
    final s = summarizeFeedback(const [
      QueueFeedback(entryId: 'a', rating: 5),
      QueueFeedback(entryId: 'b', rating: 4),
      QueueFeedback(entryId: 'c', rating: 3),
    ]);
    expect(s.count, 3);
    expect(s.average, 4);
  });

  test('summarize ignores invalid ratings and applies entry filter', () {
    final s = summarizeFeedback(
      const [
        QueueFeedback(entryId: 'a', rating: 5),
        QueueFeedback(entryId: 'b', rating: 0),
        QueueFeedback(entryId: 'c', rating: 1),
      ],
      onlyEntryIds: {'a', 'b'},
    );
    expect(s.count, 1);
    expect(s.average, 5);
  });

  test('fromDoc maps fields with defaults', () {
    final f = QueueFeedback.fromDoc('x', {'rating': 4});
    expect(f.entryId, 'x');
    expect(f.rating, 4);
    expect(f.comment, '');
  });
}
