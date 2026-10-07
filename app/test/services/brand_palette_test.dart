import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/brand_palette.dart';

void main() {
  test('every brand color keeps white text readable (AA)', () {
    for (final c in brandPalette) {
      expect(
        contrastWithWhite(c.color),
        greaterThanOrEqualTo(4.5),
        reason: '${c.hex} ${contrastWithWhite(c.color).toStringAsFixed(2)}',
      );
    }
  });

  test('hex values are unique and well formed', () {
    final hexes = brandPalette.map((c) => c.hex).toSet();
    expect(hexes.length, brandPalette.length);
    for (final h in hexes) {
      expect(RegExp(r'^#[0-9A-F]{6}$').hasMatch(h), isTrue, reason: h);
    }
  });

  test('isValidBrandHex only accepts palette colors', () {
    expect(isValidBrandHex('#2563eb'), isTrue);
    expect(isValidBrandHex('#123456'), isFalse);
    expect(isValidBrandHex(null), isFalse);
    expect(isValidBrandHex('azul'), isFalse);
  });
}
