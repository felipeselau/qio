import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Haptics extends ChangeNotifier {
  Haptics._();

  static final Haptics instance = Haptics._();

  static const prefsKey = 'haptics_enabled';

  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(prefsKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
    if (value) await HapticFeedback.selectionClick();
  }

  bool get _active => _enabled && !kIsWeb;

  Future<void> selection() async {
    if (_active) await HapticFeedback.selectionClick();
  }

  Future<void> light() async {
    if (_active) await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (_active) await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (_active) await HapticFeedback.heavyImpact();
  }
}
