import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class CreateQueueDraftStore {
  Future<Object?> load(String uid);

  Future<void> save(String uid, Map<String, Object?> json);

  Future<void> clear(String uid);
}

String createQueueDraftKey(String uid) => 'create_queue_draft_$uid';

class SharedPrefsCreateQueueDraftStore implements CreateQueueDraftStore {
  const SharedPrefsCreateQueueDraftStore();

  @override
  Future<Object?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(createQueueDraftKey(uid));
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      await prefs.remove(createQueueDraftKey(uid));
      return null;
    }
  }

  @override
  Future<void> save(String uid, Map<String, Object?> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(createQueueDraftKey(uid), jsonEncode(json));
  }

  @override
  Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(createQueueDraftKey(uid));
  }
}
