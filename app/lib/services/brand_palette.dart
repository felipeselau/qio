import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrandColor {
  const BrandColor(this.hex, this.name);

  final String hex;
  final String name;

  Color get color => Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

const brandPalette = <BrandColor>[
  BrandColor('#2563EB', 'blue'),
  BrandColor('#0F766E', 'teal'),
  BrandColor('#047857', 'green'),
  BrandColor('#7C3AED', 'purple'),
  BrandColor('#BE185D', 'pink'),
  BrandColor('#B91C1C', 'red'),
  BrandColor('#C2410C', 'orange'),
  BrandColor('#334155', 'slate'),
];

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrastWithWhite(Color c) => 1.05 / (_luminance(c) + 0.05);

bool isValidBrandHex(String? value) =>
    value != null && brandPalette.any((c) => c.hex == value.toUpperCase());
