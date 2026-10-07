import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String pushLanguageCode(String languageCode) {
  final code = languageCode.toLowerCase();
  return const {'pt', 'en', 'es'}.contains(code) ? code : 'pt';
}

const alertPushType = 'queue-alert';

String? queueIdFromPush(Map<String, dynamic> data) {
  final id = data['queueId'];
  return id is String && id.isNotEmpty ? id : null;
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const promptedKey = 'push_prompted';

  String? _token;
  StreamSubscription<String>? _refreshSub;

  bool get supported => !kIsWeb;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> hasPermission() async {
    if (!supported) return false;
    final s = await _fcm.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> isEnabled() async {
    final uid = _uid;
    if (!supported || uid == null) return false;
    final doc = await FirebaseFirestore.instance.doc('owners/$uid').get();
    final wants = doc.data()?['notifyNewEntries'] != false;
    return wants && await hasPermission();
  }

  Future<bool> enable() async {
    final uid = _uid;
    if (!supported || uid == null) return false;
    final settings = await _fcm.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    await FirebaseFirestore.instance.doc('owners/$uid').set({
      'notifyNewEntries': granted,
    }, SetOptions(merge: true));
    if (granted) await registerDevice();
    return granted;
  }

  Future<void> disable() async {
    final uid = _uid;
    if (!supported || uid == null) return;
    await FirebaseFirestore.instance.doc('owners/$uid').set({
      'notifyNewEntries': false,
    }, SetOptions(merge: true));
    await unregisterDevice();
  }

  Future<void> registerIfAllowed() async {
    if (!supported || _uid == null) return;
    if (!await hasPermission()) return;
    final uid = _uid!;
    final doc = await FirebaseFirestore.instance.doc('owners/$uid').get();
    if (doc.data()?['notifyNewEntries'] == false) return;
    await registerDevice();
  }

  Future<void> registerDevice() async {
    final uid = _uid;
    if (!supported || uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await _save(uid, token);
    _refreshSub ??= _fcm.onTokenRefresh.listen((fresh) async {
      final current = _uid;
      if (current == null) return;
      final old = _token;
      await _save(current, fresh);
      if (old != null && old != fresh) {
        await FirebaseFirestore.instance
            .doc('owners/$current/devices/$old')
            .delete();
      }
    });
  }

  Future<void> _save(String uid, String token) async {
    _token = token;
    await FirebaseFirestore.instance.doc('owners/$uid/devices/$token').set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'lang': pushLanguageCode(PlatformDispatcher.instance.locale.languageCode),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unregisterDevice() async {
    final uid = _uid;
    final token = _token ?? (supported ? await _fcm.getToken() : null);
    if (uid != null && token != null) {
      try {
        await FirebaseFirestore.instance
            .doc('owners/$uid/devices/$token')
            .delete();
      } on FirebaseException {
        // stale device doc is cleaned by the function
      }
    }
    await _refreshSub?.cancel();
    _refreshSub = null;
    _token = null;
  }

  Future<bool> shouldPrompt() async {
    if (!supported || await hasPermission()) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(promptedKey) ?? false);
  }

  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(promptedKey, true);
  }
}
