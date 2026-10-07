import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AnalyticsService {
  Future<void> queueCreated(String queueId);
  Future<void> entryCalled(String queueId);
  Future<void> entryServed(String queueId);
}

class NoopAnalytics implements AnalyticsService {
  const NoopAnalytics();

  @override
  Future<void> queueCreated(String queueId) async {}

  @override
  Future<void> entryCalled(String queueId) async {}

  @override
  Future<void> entryServed(String queueId) async {}
}

typedef AnalyticsEventSink =
    Future<void> Function(String name, Map<String, Object> parameters);

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._sink);

  factory FirebaseAnalyticsService.firebase() => FirebaseAnalyticsService(
    (name, parameters) =>
        FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters),
  );

  final AnalyticsEventSink _sink;

  Future<void> _log(String name, String queueId) async {
    try {
      await _sink(name, {'queue_id': queueId});
    } catch (_) {}
  }

  @override
  Future<void> queueCreated(String queueId) => _log('queue_created', queueId);

  @override
  Future<void> entryCalled(String queueId) => _log('entry_called', queueId);

  @override
  Future<void> entryServed(String queueId) => _log('entry_served', queueId);
}

bool analyticsAllowed({
  required bool debug,
  required bool emulators,
  required bool optedOut,
}) => !debug && !emulators && !optedOut;

class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    bool? debug,
    bool? emulators,
    AnalyticsService Function()? serviceFactory,
    Future<void> Function(bool enabled)? setCollectionEnabled,
  }) : _debug = debug ?? kDebugMode,
       _emulators = emulators ?? const bool.fromEnvironment('USE_EMULATORS'),
       _serviceFactory = serviceFactory ?? FirebaseAnalyticsService.firebase,
       _setCollectionEnabled =
           setCollectionEnabled ??
           ((enabled) => FirebaseAnalytics.instance
               .setAnalyticsCollectionEnabled(enabled));

  static final AnalyticsController instance = AnalyticsController();

  static const prefsKey = 'analytics_opt_out';

  final bool _debug;
  final bool _emulators;
  final AnalyticsService Function() _serviceFactory;
  final Future<void> Function(bool enabled) _setCollectionEnabled;

  bool _optedOut = false;
  AnalyticsService _service = const NoopAnalytics();

  bool get optedOut => _optedOut;

  bool get active =>
      analyticsAllowed(
        debug: _debug,
        emulators: _emulators,
        optedOut: _optedOut,
      ) &&
      !kIsWeb;

  AnalyticsService get service => _service;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _optedOut = prefs.getBool(prefsKey) ?? false;
    await _apply();
  }

  Future<void> setOptOut(bool value) async {
    if (value == _optedOut) return;
    _optedOut = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
    await _apply();
  }

  Future<void> _apply() async {
    final on = active;
    _service = on ? _serviceFactory() : const NoopAnalytics();
    try {
      await _setCollectionEnabled(on);
    } catch (_) {}
  }
}
