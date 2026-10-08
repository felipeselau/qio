import '../models/queue_entry.dart';

enum FinishCheck { proceed, gone, changed }

FinishCheck checkFinishable(Object? current, EntryStatus result) {
  if (current is! Map) return FinishCheck.gone;
  final status = current['status'];
  if (status == EntryStatus.called.value || status == result.value) {
    return FinishCheck.proceed;
  }
  return FinishCheck.changed;
}

Map<Object?, Object?>? finishedEntryData(
  Object? current,
  EntryStatus result,
  String uid,
) {
  if (checkFinishable(current, result) != FinishCheck.proceed) return null;
  final data = Map<Object?, Object?>.from(current as Map);
  data['status'] = result.value;
  data['operatorId'] = uid;
  return data;
}
