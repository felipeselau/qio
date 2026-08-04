import 'package:flutter/material.dart';
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

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

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
              _initials,
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
