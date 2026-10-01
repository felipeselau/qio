import 'package:flutter/material.dart';
import '../services/account_format.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';

class QioAvatar extends StatelessWidget {
  const QioAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
  });

  final String name;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Avatar: $name',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? QioColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: ExcludeSemantics(
          child: Center(
            child: Text(
              initialsOf(name),
              style: QioTextStyles.heading3.copyWith(
                color: QioColors.primary,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
