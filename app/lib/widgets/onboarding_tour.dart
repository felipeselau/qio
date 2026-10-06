import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../theme/qio_text_styles.dart';

class OnboardingStep {
  const OnboardingStep({
    required this.key,
    required this.title,
    required this.body,
    this.shape = ShapeLightFocus.RRect,
    this.above = false,
  });

  final GlobalKey key;
  final String title;
  final String body;
  final ShapeLightFocus shape;
  final bool above;
}

Future<void> showOnboardingTour(
  BuildContext context,
  OnboardingTour tour,
  List<OnboardingStep> steps,
) async {
  final uid = AuthService.instance.currentUser?.uid;
  if (uid == null) return;
  if (await OnboardingService.instance.isCompleted(tour, uid)) return;
  if (!context.mounted) return;
  final visible = steps.where((s) => s.key.currentContext != null).toList();
  if (visible.isEmpty) return;

  Future<void> done() => OnboardingService.instance.markCompleted(tour, uid);

  TutorialCoachMark(
    targets: [
      for (var i = 0; i < visible.length; i++)
        TargetFocus(
          identify: visible[i].title,
          keyTarget: visible[i].key,
          shape: visible[i].shape,
          enableOverlayTab: true,
          alignSkip: visible[i].above
              ? Alignment.topRight
              : Alignment.bottomRight,
          radius: 12,
          contents: [
            TargetContent(
              align: visible[i].above ? ContentAlign.top : ContentAlign.bottom,
              child: _StepText(
                step: visible[i],
                index: i + 1,
                total: visible.length,
              ),
            ),
          ],
        ),
    ],
    colorShadow: Colors.black,
    opacityShadow: 0.85,
    textSkip: AppLocalizations.of(context).skip,
    paddingFocus: 6,
    onFinish: () {
      done();
    },
    onSkip: () {
      done();
      return true;
    },
  ).show(context: context);
}

class _StepText extends StatelessWidget {
  const _StepText({
    required this.step,
    required this.index,
    required this.total,
  });

  final OnboardingStep step;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context).stepOf(index, total),
          style: QioTextStyles.caption.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          step.title,
          style: QioTextStyles.heading2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          step.body,
          style: QioTextStyles.body.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).tapToContinue,
          style: QioTextStyles.caption.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
