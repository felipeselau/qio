import 'history_entry.dart';
import 'operator.dart';
import 'queue.dart';
import 'queue_feedback.dart';

class QueueHistoryInput {
  const QueueHistoryInput(
    this.queue,
    this.entries,
    this.feedback,
    this.operators,
  );

  final Queue queue;
  final List<HistoryEntry> entries;
  final List<QueueFeedback> feedback;
  final List<QueueOperator> operators;
}
