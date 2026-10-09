import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/queue_entry.dart';

Map<Object?, Object?>? claimedEntryData(
  Object? current,
  String uid,
  int provisionalCalledAt,
) {
  if (current is! Map) return null;
  if (current['status'] != EntryStatus.waiting.value) return null;
  final data = Map<Object?, Object?>.from(current);
  data['status'] = EntryStatus.called.value;
  data['calledAt'] = provisionalCalledAt;
  data['operatorId'] = uid;
  return data;
}

Timestamp? historyTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
