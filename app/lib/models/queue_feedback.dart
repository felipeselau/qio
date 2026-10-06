class QueueFeedback {
  const QueueFeedback({
    required this.entryId,
    required this.rating,
    this.comment = '',
  });

  final String entryId;
  final int rating;
  final String comment;

  factory QueueFeedback.fromDoc(String id, Map<String, dynamic> data) {
    return QueueFeedback(
      entryId: id,
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
    );
  }
}

class FeedbackSummary {
  const FeedbackSummary({required this.count, this.average});

  final int count;
  final double? average;
}

FeedbackSummary summarizeFeedback(
  Iterable<QueueFeedback> feedback, {
  Set<String>? onlyEntryIds,
}) {
  final valid = feedback.where(
    (f) =>
        f.rating >= 1 &&
        f.rating <= 5 &&
        (onlyEntryIds == null || onlyEntryIds.contains(f.entryId)),
  );
  if (valid.isEmpty) return const FeedbackSummary(count: 0);
  final total = valid.fold<int>(0, (s, f) => s + f.rating);
  return FeedbackSummary(count: valid.length, average: total / valid.length);
}
