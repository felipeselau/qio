import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';

import '../helpers/bi_data.dart';

MetricsReport report(
  List<QueueHistoryInput> data, {
  HistoryPeriod period = HistoryPeriod.all,
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

  group('relatorio', () {
    test('atendentes e desistencia calculados do historico filtrado', () {
      final r = report(biData(attendantEntries()));
      final ana = r.attendants.firstWhere((a) => a.attendantId == 'op1');
      expect(ana.deviationPct, closeTo(-50, 1e-9));
      expect(ana.perHour, closeTo(4.8, 1e-9));
      expect(ana.idlePct, closeTo(0.6, 1e-9));
      expect(report(biData(abandonEntries())).abandonment!.capacityHours, [11]);
    });

    test('periodo muda os numeros', () {
      final data = biData([...attendantEntries(), oldAttendantEntry()]);
      final all = report(data);
      final week = report(data, period: HistoryPeriod.last7Days);
      int served(MetricsReport r) =>
          r.attendants.firstWhere((a) => a.attendantId == 'op1').stats.served;
      expect(served(all), 5);
      expect(served(week), 4);
    });

    test('sem historico nao ha abandono', () {
      expect(report(biData(const [])).abandonment, isNull);
    });
  });

  group('csv', () {
    test('tabela de atendentes', () {
      final l = lines(pt, report(biData(attendantEntries())));
      final i = l.indexOf('Por atendente');
      expect(i, greaterThan(0));
      expect(
        l[i + 1],
        'atendente,atendidos,atendimento médio (min),desvio vs média (%),'
        'atendimentos por hora (janela de atuação),ociosidade (%),'
        'não compareceram,nota média,qtd notas',
      );
      final rows = l.sublist(i + 2, i + 4);
      expect(rows, contains('Ana,4,5.0,-50.0,4.8,60.0,0,,0'));
      expect(rows, contains('Bia,4,15.0,+50.0,3.2,20.0,1,,0'));
    });

    test('desistencia por faixa, estimativa e hora, sem telefone', () {
      final csv = buildMetricsCsv(
        pt,
        report(biData(abandonEntries())),
        generatedAt: DateTime(2025, 6, 15),
      );
      final l = csv.substring(1).split('\r\n');
      final w = l.indexOf('Taxa por faixa de espera');
      expect(
        l[w + 1],
        'faixa de espera (min),chegaram à faixa,desistiram,desistência (%),'
        'desistência por 10 min (%)',
      );
      expect(l[w + 5], '20–40 min,9,4,44.4,22.2');
      expect(l[w + 6], '40+ min,0,0,,');
      expect(l[w + 7], 'ponto de inflexão,20–40 min');
      final e = l.indexOf('Taxa por estimativa mostrada');
      expect(l[e + 2], '0–5 min,5,0,0.0');
      expect(l[e + 4], '10–20 min,9,4,44.4');
      expect(l[e + 7], 'erro médio da estimativa (min),+3.5');
      expect(l[e + 8], 'erro absoluto médio da estimativa (min),4.5');
      final h = l.indexOf('Desistência por hora de chegada');
      expect(l[h + 2], '9,5,0,0.0,2.0');
      expect(l[h + 3], '11,9,4,44.4,22.2');
      expect(l[h + 4], 'horas com sinal de capacidade,11');
      expect(csv.toLowerCase().contains('phone'), isFalse);
    });

    test('sem estimativa a secao de estimativa some', () {
      final l = lines(pt, report(biData(abandonEntries(estimates: false))));
      expect(l, isNot(contains('Taxa por estimativa mostrada')));
    });

    test('respeita o idioma', () {
      final l = lines(en, report(biData(abandonEntries())));
      expect(l, contains('Rate by wait band'));
      expect(l, contains('Abandonment by arrival hour'));
    });
  });

  group('injecao em nomes', () {
    test('nomes de atendente começando com = + - @ são protegidos', () {
      for (final bad in ['=SOMA(1)', '+1', '-1', '@x']) {
        final l = lines(
          pt,
          report(biData(attendantEntries(), operators: [biOp('op1', bad)])),
        );
        final i = l.indexOf('Por atendente');
        final row = l.sublist(i + 2).firstWhere((x) => x.contains(bad));
        expect(row, startsWith("'$bad"), reason: bad);
      }
    });
  });

  group('pdf', () {
    test('contém títulos e valores das novas tabelas', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(biData([...attendantEntries(), ...abandonEntries()])),
        generatedAt: DateTime(2025, 6, 15),
        compress: false,
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      final text = pdfWords(bytes);
      for (final needle in [
        'Por atendente',
        'Ana',
        'Bia',
        'Taxa por faixa de espera',
        '20-40 min',
        'Desistência por hora de chegada',
        'Taxa por estimativa mostrada',
        '44.4',
      ]) {
        expect(text, contains(needle), reason: needle);
      }
    });

    test('sem estimativa o PDF não traz a seção', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(biData(abandonEntries(estimates: false))),
        generatedAt: DateTime(2025, 6, 15),
        compress: false,
      );
      expect(pdfWords(bytes), isNot(contains('Taxa por estimativa mostrada')));
    });
  });
}
