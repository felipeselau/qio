import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingTour {
  home('onboarding_home_completed'),
  panel('onboarding_panel_completed');

  const OnboardingTour(this.key);

  final String key;
}

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  static String prefsKey(OnboardingTour tour, String uid) => '${tour.key}_$uid';

  Future<bool> isCompleted(OnboardingTour tour, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey(tour, uid)) ?? false;
  }

  Future<void> markCompleted(OnboardingTour tour, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey(tour, uid), true);
  }
}
