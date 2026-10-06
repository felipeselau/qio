import 'package:flutter/material.dart';
import '../../theme/qio_text_styles.dart';

class StatusButton extends StatelessWidget {
  const StatusButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: QioTextStyles.caption.copyWith(fontSize: 12, color: color),
        ),
      ),
    );
  }
}
