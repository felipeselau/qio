import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';

import '../helpers/bi_data.dart';

MetricsReport report(
  List<QueueHistoryInput> data, {
  HistoryPeriod period = HistoryPeriod.last7Days,
}) => buildMetricsReport(
  data: data,
  period: period,
  now: biNow,
  historyLimit: 500,
  unknownOperatorName: 'ex',
);

List<String> lines(AppLocalizations l10n, MetricsReport r) => buildMetricsCsv(
  l10n,
  r,
  generatedAt: DateTime(2025, 6, 15),
).substring(1).split('\r\n');

String pdfWords(List<int> bytes) => RegExp(
  r'\[\((.*?)\)\]TJ',
).allMatches(String.fromCharCodes(bytes)).map((m) => m.group(1)!).join(' ');

void main() {
  setUpAll(initializeDateFormatting);
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('relatório', () {
    test('metas só contam filas com meta', () {
      final r = report(biData(goalEntries(), goals: biGoals));
      expect(r.goals.hasGoals, isTrue);
      expect(r.goals.wait.overall.ok, 3);
      expect(r.goals.service.overall.ok, 4);
      expect(report(biData(goalEntries())).goals.hasGoals, isFalse);
    });

    test(
      'planejamento usa o período e a sazonalidade usa todo o histórico',
      () {
        final r = report(biData(planningEntries()));
        expect(r.staffing!.grid.coverageDays, 2);
        expect(r.staffing!.grid.cells[0][12].required, 2);
        expect(r.staffing!.seasonality.observedWeeks, 4);
        expect(r.staffing!.seasonality.weeks.first.volume, 6);
      },
    );

    test('sem histórico não há planejamento', () {
      expect(report(biData(const [])).staffing, isNull);
    });
  });

  group('csv', () {
    test('metas, períodos não atingidos e violação', () {
      final l = lines(pt, report(biData(goalEntries(), goals: biGoals)));
      final i = l.indexOf('Metas');
      expect(i, greaterThan(0));
      expect(
        l[i + 1],
        'indicador,avaliados,dentro do limite,% dentro do limite,alvo %,'
        'meta atingida,maior violação (min),dia da maior violação',
      );
      expect(l[i + 2], 'Espera,5,3,60.0,80.0,não,10.0,2025-06-14');
      expect(l[i + 3], 'Atendimento,5,4,80.0,80.0,sim,4.0,2025-06-14');
      final j = l.indexOf('Períodos em que a meta não foi atingida');
      expect(j, greaterThan(i));
      expect(l[j + 2], 'Espera,2025-06-14,5,3,60.0,80.0');
      expect(l[j + 3], 'Espera,horas abaixo do alvo,12');
    });

    test('sem metas a seção não existe', () {
      final l = lines(pt, report(biData(goalEntries())));
      expect(l, isNot(contains('Metas')));
    });

    test('planejamento de equipe', () {
      final l = lines(pt, report(biData(planningEntries())));
      final i = l.indexOf('Planejamento de equipe');
      expect(i, greaterThan(0));
      expect(l, contains('seg.,12,4.00,2,2.00,0.0'));
      expect(l, contains('ter.,10,2.00,1,0.00,+1.0'));
      final top = l.indexOf('Maiores déficits');
      expect(top, greaterThan(i));
      expect(l[top + 2], 'ter.,10,1,0.00,+1.0');
      final season = l.indexOf('Volume semanal e sazonalidade');
      expect(season, greaterThan(top));
      expect(l[season + 1], 'início da semana,chegadas');
      expect(l.sublist(season + 2, season + 6), [
        '2025-05-12,6',
        '2025-05-19,6',
        '2025-05-26,6',
        '2025-06-02,6',
      ]);
      expect(l[season + 6], 'tendência (% da média por semana),0.0');
      final rec = l.indexOf('Padrão recorrente');
      expect(l[rec + 2], 'seg.,12,4,4');
    });

    test('sem semanas observadas a sazonalidade some do csv', () {
      final current = planningEntries()
          .where((e) => e.joinedAt.isAfter(DateTime.utc(2025, 6, 8)))
          .toList();
      final l = lines(pt, report(biData(current)));
      expect(l, isNot(contains('Volume semanal e sazonalidade')));
      expect(l, contains('Planejamento de equipe'));
    });

    test('respeita o idioma', () {
      final l = lines(en, report(biData([...goalEntries()], goals: biGoals)));
      expect(l, contains('Goals'));
      expect(l, contains('Periods when the goal was not met'));
    });

    test('nenhuma coluna traz telefone', () {
      final csv = buildMetricsCsv(
        pt,
        report(
          biData([...goalEntries(), ...planningEntries()], goals: biGoals),
        ),
        generatedAt: DateTime(2025, 6, 15),
      );
      expect(csv.toLowerCase(), isNot(contains('telefone')));
      expect(csv, isNot(contains('(11)')));
    });
  });

  group('pdf', () {
    test('contém metas e planejamento', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(biData(goalEntries(), goals: biGoals)),
        generatedAt: DateTime(2025, 6, 15),
        compress: false,
      );
      final text = pdfWords(bytes);
      for (final needle in [
        'Metas',
        'Períodos em que a meta não foi atingida',
        'Espera',
        '60.0',
        '2025-06-14',
      ]) {
        expect(text, contains(needle), reason: needle);
      }
    });

    test('planejamento de equipe e déficits', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(biData(planningEntries())),
        generatedAt: DateTime(2025, 6, 15),
        compress: false,
      );
      final text = pdfWords(bytes);
      for (final needle in [
        'Planejamento de equipe',
        'Maiores déficits',
        'Volume semanal e sazonalidade',
        'Padrão recorrente',
        '2025-05-12',
        '+1.0',
      ]) {
        expect(text, contains(needle), reason: needle);
      }
    });

    test('sem metas o PDF não traz a seção', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(biData(goalEntries())),
        generatedAt: DateTime(2025, 6, 15),
        compress: false,
      );
      expect(pdfWords(bytes), isNot(contains('Períodos em que a meta')));
    });
  });
}
