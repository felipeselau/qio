import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/widgets/connection_banner.dart';
import 'package:qio_app/widgets/qio_empty_state.dart';
import 'package:qio_app/widgets/qio_input.dart';
import 'package:qio_app/widgets/qio_skeleton.dart';

Widget host(Widget child) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('empty state shows title, message and runs the action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        QioEmptyState(
          icon: Icons.history,
          title: 'Nada aqui',
          message: 'Volte depois',
          actionLabel: 'Criar',
          onAction: () => taps++,
        ),
      ),
    );
    expect(find.text('Nada aqui'), findsOneWidget);
    expect(find.text('Volte depois'), findsOneWidget);
    await tester.tap(find.text('Criar'));
    expect(taps, 1);
  });

  testWidgets('error state offers a retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(QioErrorState(onRetry: () => retries++)));
    expect(find.text('Algo deu errado'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
  });

  testWidgets('skeleton list renders cards without a spinner', (tester) async {
    await tester.pumpWidget(host(const QioSkeletonList(count: 2)));
    expect(find.byType(QioSkeletonCard), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('password input toggles visibility', (tester) async {
    await tester.pumpWidget(
      host(const QioPasswordInput(label: 'Senha', hint: 'x')),
    );
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byType(QioPasswordInput),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(field().obscureText, isFalse);
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
  });

  testWidgets(
    'connection banner appears after the delay and hides on reconnect',
    (tester) async {
      final controller = StreamController<bool>();
      await tester.pumpWidget(
        host(
          ConnectionBanner(
            connected: controller.stream,
            delay: const Duration(milliseconds: 200),
            child: const Text('conteudo'),
          ),
        ),
      );
      controller.add(false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Sem conexão'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem conexão'), findsOneWidget);
      controller.add(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem conexão'), findsNothing);
      expect(find.text('conteudo'), findsOneWidget);
      await controller.close();
    },
  );

  testWidgets('a quick blip does not show the banner', (tester) async {
    final controller = StreamController<bool>();
    await tester.pumpWidget(
      host(
        ConnectionBanner(
          connected: controller.stream,
          delay: const Duration(milliseconds: 300),
          child: const SizedBox(),
        ),
      ),
    );
    controller.add(false);
    await tester.pump(const Duration(milliseconds: 100));
    controller.add(true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Sem conexão'), findsNothing);
    await controller.close();
  });
}
