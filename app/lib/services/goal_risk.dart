import '../models/queue_goals.dart';

const double defaultAvgServiceMin = 10;

double effectiveAvgServiceMin(num? auto, num? manual) {
  bool valid(num? n) => n != null && n.isFinite && n > 0;
  if (valid(auto)) return auto!.toDouble();
  if (valid(manual)) return manual!.toDouble();
  return defaultAvgServiceMin;
}

int estimatedWaitMin(int waiting, {num? auto, num? manual}) {
  if (waiting <= 0) return 0;
  return (waiting * effectiveAvgServiceMin(auto, manual)).round();
}

bool waitGoalAtRisk(int estimatedMin, QueueGoals? goals) {
  final max = goals?.maxWaitMin;
  return max != null && estimatedMin > max;
}
