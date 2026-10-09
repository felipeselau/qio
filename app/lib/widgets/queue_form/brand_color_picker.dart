import 'package:flutter/material.dart';

import '../../services/brand_palette.dart';

class BrandColorPicker extends StatelessWidget {
  const BrandColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        for (final c in brandPalette)
          Semantics(
            button: true,
            selected: value == c.hex,
            label: c.hex,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onChanged(c.hex) : null,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                    ),
                    child: value == c.hex
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
