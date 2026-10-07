import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/widgets/wait_effort_card.dart';

Widget host(WaitStats wait, CallEffortStats effort) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: WaitEffortCard(waitStats: wait, callEffort: effort),
  ),
);

void main() {
  testWidgets('empty shows dashes and no bars', (tester) async {
    await tester.pumpWidget(
      host(
        const WaitStats(samples: 0, bucketCounts: [0, 0, 0, 0]),
        const CallEffortStats(
          called: 0,
          recallsTotal: 0,
          recalledEntries: 0,
          skipsTotal: 0,
          skippedEntries: 0,
        ),
      ),
    );
    expect(find.text('Espera e chamadas'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('amostras insuficientes'), findsNothing);
  });

  testWidgets('filled shows stats, bars with semantics and hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const WaitStats(samples: 4, medianMin: 8, bucketCounts: [1, 2, 1, 0]),
        const CallEffortStats(
          called: 4,
          recallsTotal: 3,
          recalledEntries: 2,
          skipsTotal: 1,
          skippedEntries: 1,
          recallRate: 0.5,
        ),
      ),
    );
    expect(find.text('8 min'), findsOneWidget);
    expect(find.text('amostras insuficientes'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    final label = tester.getSemantics(find.byType(WaitEffortCard)).label;
    expect(label, contains('5–15 min: 2 (50%)'));
    expect(label, contains('Mais de 30 min: 0 (0%)'));
    expect(label, isNot(contains('5–15 min\n2')));
    expect(find.text('2 entradas de 4 (50%) · 3 re-chamadas'), findsOneWidget);
    expect(find.text('1 entradas de 4 · 1 movidos ao fim'), findsOneWidget);
    handle.dispose();
  });
}
