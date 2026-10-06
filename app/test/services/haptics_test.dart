import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await Haptics.instance.setEnabled(true);
  });

  test('vibrates with the right intensity when enabled', () async {
    await Haptics.instance.load();
    await Haptics.instance.selection();
    await Haptics.instance.light();
    await Haptics.instance.medium();
    await Haptics.instance.heavy();
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  test('is silent when disabled and remembers the preference', () async {
    await Haptics.instance.setEnabled(false);
    calls.clear();
    await Haptics.instance.medium();
    expect(calls, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(Haptics.prefsKey), isFalse);
    SharedPreferences.setMockInitialValues({Haptics.prefsKey: false});
    await Haptics.instance.load();
    expect(Haptics.instance.enabled, isFalse);
  });

  test('re-enabling gives a confirmation tick', () async {
    await Haptics.instance.setEnabled(false);
    calls.clear();
    await Haptics.instance.setEnabled(true);
    expect(calls, ['HapticFeedbackType.selectionClick']);
  });
}
