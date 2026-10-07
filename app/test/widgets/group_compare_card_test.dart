import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/queue_analytics.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/widgets/group_compare_card.dart';
import 'package:qio_app/widgets/qio_card.dart';

Widget wrap(Widget child) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('empty list renders only the title', (tester) async {
    await tester.pumpWidget(wrap(const GroupCompareSection(rows: [])));
    expect(find.text('Comparativo entre filas do grupo'), findsOneWidget);
    expect(find.byType(QioCard), findsNothing);
  });

  testWidgets('renders one row per queue with its numbers', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GroupCompareSection(
          rows: [
            QueueComparison(
              queueId: 'a',
              name: 'Caixa',
              metrics: HistoryMetrics(
                total: 4,
                served: 3,
                noShow: 1,
                left: 0,
                noShowRate: 0.25,
                avgWaitMin: 7,
              ),
              feedback: FeedbackSummary(count: 2, average: 4.5),
            ),
            QueueComparison(
              queueId: 'b',
              name: 'Balcão',
              metrics: HistoryMetrics(
                total: 0,
                served: 0,
                noShow: 0,
                left: 0,
                noShowRate: 0,
              ),
              feedback: FeedbackSummary(count: 0),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Caixa'), findsOneWidget);
    expect(find.text('Balcão'), findsOneWidget);
    expect(find.textContaining('4 atendimentos'), findsOneWidget);
    expect(find.textContaining('25%'), findsOneWidget);
    expect(find.textContaining('4.5 ★'), findsOneWidget);
    expect(find.textContaining('nota —'), findsOneWidget);
  });
}
