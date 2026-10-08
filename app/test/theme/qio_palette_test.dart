import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/theme/qio_palette.dart';
import 'package:qio_app/theme/qio_text_styles.dart';
import 'package:qio_app/theme/qio_theme.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('probe'),
      color: context.qio.surface,
      child: Text('x', style: context.qioText.body),
    );
  }
}

Widget _app(ValueNotifier<ThemeMode> mode) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: mode,
    builder: (_, m, _) => MaterialApp(
      theme: QioTheme.light,
      darkTheme: QioTheme.dark,
      themeMode: m,
      home: const _Probe(),
    ),
  );
}

void main() {
  testWidgets('switching ThemeMode updates colors without manual rebuild', (
    tester,
  ) async {
    final mode = ValueNotifier(ThemeMode.light);
    addTearDown(mode.dispose);
    await tester.pumpWidget(_app(mode));

    Color surface() =>
        tester.widget<ColoredBox>(find.byKey(const Key('probe'))).color;
    Color textColor() => tester.widget<Text>(find.text('x')).style!.color!;

    expect(surface(), QioPalette.light.surface);
    expect(textColor(), QioPalette.light.textPrimary);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    expect(surface(), QioPalette.dark.surface);
    expect(textColor(), QioPalette.dark.textPrimary);
  });

  test('theme registers the matching palette', () {
    expect(QioTheme.light.extension<QioPalette>(), QioPalette.light);
    expect(QioTheme.dark.extension<QioPalette>(), QioPalette.dark);
  });

  test('copyWith and lerp', () {
    expect(QioPalette.light.copyWith(card: Colors.red).card, Colors.red);
    expect(
      QioPalette.light.lerp(QioPalette.dark, 1).surface,
      QioPalette.dark.surface,
    );
    expect(
      QioPalette.light.lerp(QioPalette.dark, 0).surface,
      QioPalette.light.surface,
    );
  });
}
