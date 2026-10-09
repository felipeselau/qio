import 'dart:convert';

import 'package:qio_app/services/create_queue_draft_store.dart';

class FakeCreateQueueDraftStore implements CreateQueueDraftStore {
  FakeCreateQueueDraftStore({Map<String, Object?>? initial})
    : data = {...?initial};

  final Map<String, Object?> data;
  final List<String> calls = [];
  Future<void>? clearGate;

  @override
  Future<Object?> load(String uid) async {
    calls.add('load:$uid');
    return data[uid];
  }

  @override
  Future<void> save(String uid, Map<String, Object?> json) async {
    calls.add('save:$uid');
    data[uid] = jsonDecode(jsonEncode(json));
  }

  @override
  Future<void> clear(String uid) async {
    calls.add('clear:$uid');
    await clearGate;
    data.remove(uid);
  }
}
