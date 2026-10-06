import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/theme/qio_theme.dart';
import 'package:qio_app/widgets/qio_button.dart';
import 'package:qio_app/widgets/qio_empty_state.dart';
import 'package:qio_app/widgets/qio_input.dart';
import 'package:qio_app/widgets/qio_responsive_body.dart';

Widget host(Widget child, {double textScale = 1}) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: QioTheme.light,
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget gallery() => Column(
  children: [
    QioButton(label: 'Entrar', onPressed: () {}),
    QioButton(
      label: 'Excluir',
      variant: QioButtonVariant.danger,
      onPressed: () {},
    ),
    QioButton(
      label: 'Voltar',
      variant: QioButtonVariant.secondary,
      onPressed: () {},
    ),
    const QioPasswordInput(label: 'Senha'),
    QioErrorState(onRetry: () {}),
    QioEmptyState(
      icon: Icons.history,
      title: 'Nada ainda',
      message: 'Os atendimentos aparecem aqui.',
      actionLabel: 'Criar',
      onAction: () {},
    ),
  ],
);

void main() {
  testWidgets('tap targets meet the Android and labeled guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(gallery()));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('text contrast guideline passes in the light theme', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(gallery()));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('no overflow at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(gallery(), textScale: scale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('responsive body limits the content width on tablets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QioResponsiveBody(child: Container(key: const Key('c'))),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('c'))).width, 640);
    expect(tester.getTopLeft(find.byKey(const Key('c'))).dx, (1024 - 640) / 2);
  });
}
