import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tour not completed by default', () async {
    expect(
      await OnboardingService.instance.isCompleted(OnboardingTour.home, 'u1'),
      isFalse,
    );
  });

  test('markCompleted persists per uid and tour', () async {
    await OnboardingService.instance.markCompleted(OnboardingTour.home, 'u1');
    expect(
      await OnboardingService.instance.isCompleted(OnboardingTour.home, 'u1'),
      isTrue,
    );
    expect(
      await OnboardingService.instance.isCompleted(OnboardingTour.panel, 'u1'),
      isFalse,
    );
    expect(
      await OnboardingService.instance.isCompleted(OnboardingTour.home, 'u2'),
      isFalse,
    );
  });
}
