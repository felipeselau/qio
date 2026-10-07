import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_export.dart';

final now = DateTime(2026, 10, 7, 12);

Queue queue(String id, {String? name, String ownerId = 'own'}) => Queue(
  id: id,
  ownerId: ownerId,
  name: name ?? 'Fila $id',
  createdAt: DateTime(2026, 1, 1),
);

HistoryEntry served(
  String id, {
  DateTime? joinedAt,
  int serviceMin = 10,
  String? calledBy,
  String result = 'served',
}) {
  final joined = joinedAt ?? DateTime(2026, 10, 7, 9);
  final called = joined.add(const Duration(minutes: 5));
  return HistoryEntry(
    id: id,
    ticket: 1,
    name: 'n$id',
    result: result,
    joinedAt: joined,
    calledAt: called,
    finishedAt: called.add(Duration(minutes: serviceMin)),
    calledBy: calledBy,
  );
}

QueueOperator op(String uid, String name) =>
    QueueOperator(uid: uid, queueId: 'a', queueName: 'A', displayName: name);

MetricsReport report(
  List<QueueHistoryInput> data, {
  HistoryPeriod period = HistoryPeriod.all,
  String? queueId,
  int limit = 500,
}) => buildMetricsReport(
  data: data,
  period: period,
  now: now,
  historyLimit: limit,
  unknownOperatorName: 'ex',
  operatorQueueId: queueId,
);

void main() {
  group('buildMetricsReport', () {
    test('filters by period', () {
      final old = served('old', joinedAt: DateTime(2026, 9, 1, 9));
      final recent = served('new');
      final data = [
        QueueHistoryInput(queue('a'), [old, recent], const [], const []),
      ];
      expect(report(data).metrics.total, 2);
      final r = report(data, period: HistoryPeriod.last7Days);
      expect(r.metrics.total, 1);
      expect(r.isEmpty, isFalse);
      expect(r.peaks, [9]);
      expect(r.distribution[9], 1);
    });

    test('queue selector only affects operators', () {
      final data = [
        QueueHistoryInput(
          queue('a', ownerId: 'o1'),
          [served('1'), served('2', calledBy: 'u1')],
          const [],
          [op('u1', 'Bia')],
        ),
        QueueHistoryInput(
          queue('b', ownerId: 'o2'),
          [served('3'), served('4'), served('5')],
          const [],
          const [],
        ),
      ];
      final all = report(data);
      expect(all.metrics.total, 5);
      expect(all.operators.fold<int>(0, (s, o) => s + o.served), 5);
      expect(all.operatorQueueName, isNull);
      final onlyA = report(data, queueId: 'a');
      expect(onlyA.metrics.total, 5);
      expect(onlyA.ranking.length, 2);
      expect(onlyA.operators.fold<int>(0, (s, o) => s + o.served), 2);
      expect(onlyA.operatorQueueName, 'Fila a');
      expect(onlyA.operatorNames['u1'], 'Bia');
    });

    test('operator feedback follows selected queue', () {
      final data = [
        QueueHistoryInput(
          queue('a'),
          [served('1')],
          const [QueueFeedback(entryId: '1', rating: 4)],
          const [],
        ),
      ];
      final r = report(data);
      expect(r.operators.single.feedback.count, 1);
      expect(r.operators.single.feedback.average, 4);
    });

    test('flags truncation only when oldest entry is inside the period', () {
      final entries = [
        served('1'),
        served('2', joinedAt: DateTime(2026, 10, 6, 9)),
      ];
      final data = [QueueHistoryInput(queue('a'), entries, const [], const [])];
      expect(report(data, limit: 2).truncated, isTrue);
      expect(report(data, limit: 3).truncated, isFalse);
      final older = [
        served('1'),
        served('2', joinedAt: DateTime(2026, 8, 1, 9)),
      ];
      final data2 = [QueueHistoryInput(queue('a'), older, const [], const [])];
      expect(
        report(data2, period: HistoryPeriod.last7Days, limit: 2).truncated,
        isFalse,
      );
    });

    test('truncation respects the queue selector', () {
      final full = [served('1'), served('2')];
      final data = [
        QueueHistoryInput(queue('a'), full, const [], const []),
        QueueHistoryInput(queue('b'), [served('3')], const [], const []),
      ];
      expect(report(data, limit: 2).truncated, isTrue);
      expect(report(data, limit: 2, queueId: 'b').truncated, isFalse);
    });

    test('empty data', () {
      final r = report([
        QueueHistoryInput(queue('a'), const [], const [], const []),
      ]);
      expect(r.isEmpty, isTrue);
      expect(r.metrics.total, 0);
      expect(r.peaks, isEmpty);
      expect(r.operators, isEmpty);
      expect(r.truncated, isFalse);
      expect(r.ranking.single.name, 'Fila a');
      expect(report(const []).isEmpty, isTrue);
    });
  });

  group('buildMetricsCsv', () {
    final pt = lookupAppLocalizations(const Locale('pt'));
    final en = lookupAppLocalizations(const Locale('en'));
    final es = lookupAppLocalizations(const Locale('es'));
    final at = DateTime(2026, 10, 7, 12, 30, 5);

    List<String> lines(AppLocalizations l10n, MetricsReport r) {
      final csv = buildMetricsCsv(l10n, r, generatedAt: at);
      expect(csv.startsWith('\u{FEFF}'), isTrue);
      expect(csv.endsWith('\r\n'), isTrue);
      expect(csv.replaceAll('\r\n', '').contains('\n'), isFalse);
      return csv.substring(1).split('\r\n');
    }

    final data = [
      QueueHistoryInput(
        queue('a', ownerId: 'o1', name: 'Caixa'),
        [
          served('1'),
          served('2', calledBy: 'u1'),
          served('3', calledBy: 'u1'),
          served('4', calledBy: 'u1', serviceMin: 20),
          served('5', calledBy: 'gone', result: 'no_show'),
        ],
        const [QueueFeedback(entryId: '2', rating: 4)],
        [op('u1', 'Bia')],
      ),
    ];

    test('sections come in order separated by blank lines', () {
      final l = lines(pt, report(data));
      final titles = [
        for (var i = 0; i < l.length; i++)
          if (i == 0 || l[i - 1].isEmpty) l[i],
      ];
      expect(titles, [
        'Qio - Métricas das filas',
        'Atendimentos',
        'Picos de demanda',
        'Filas mais ativas',
        'Por atendente',
        'Espera e chamadas',
      ]);
    });

    test('header section and summary values', () {
      final l = lines(pt, report(data));
      expect(l[1], 'período,Tudo');
      expect(l[2], 'escopo por atendente,Todas as filas');
      expect(l[3], 'gerado em,2026-10-07 12:30:05');
      expect(l[4], '');
      expect(l[5], 'Atendimentos');
      expect(l[6], 'métrica,valor');
      expect(l[7], 'total,5');
      expect(l[8], 'atendidos,4');
      expect(l[9], 'não compareceram,1');
      expect(l[10], 'desistiram,0');
      expect(l[11], 'taxa de não comparecimento (%),20.0');
      expect(l[12], 'espera média (min),5.0');
      expect(l[13], 'atendimento médio (min),12.5');
    });

    test('peak hours has 24 rows', () {
      final l = lines(pt, report(data));
      final i = l.indexOf('Picos de demanda');
      expect(l[i + 1], 'hora,entradas');
      expect(l.sublist(i + 2, i + 26).length, 24);
      expect(l[i + 2], '0,0');
      expect(l[i + 11], '9,5');
      expect(l[i + 26], '');
    });

    test('ranking and rate', () {
      final l = lines(pt, report(data));
      final i = l.indexOf('Filas mais ativas');
      expect(
        l[i + 1],
        'posição,fila,total,não compareceram,taxa de não comparecimento (%)',
      );
      expect(l[i + 2], '1,Caixa,5,1,20.0');
    });

    test('operators: owner, operator, former operator and null cells', () {
      final l = lines(pt, report(data));
      final i = l.indexOf('Por atendente');
      expect(
        l[i + 1],
        'atendente,atendidos,não compareceram,atendimento médio (min),'
        'nota média,qtd notas',
      );
      expect(l[i + 2], 'Bia,3,0,13.3,4.0,1');
      expect(l[i + 3], 'Dono,1,0,,,0');
      expect(l[i + 4], 'ex-operador,0,1,,,0');
    });

    test('wait and calls section', () {
      final withEffort = [
        QueueHistoryInput(
          queue('a'),
          [
            for (var i = 0; i < 5; i++) served('$i'),
            HistoryEntry(
              id: 'r',
              ticket: 1,
              name: 'r',
              result: 'served',
              joinedAt: DateTime(2026, 10, 7, 9),
              calledAt: DateTime(2026, 10, 7, 9, 20),
              finishedAt: DateTime(2026, 10, 7, 9, 30),
              recalls: 2,
              skips: 1,
            ),
          ],
          const [],
          const [],
        ),
      ];
      final l = lines(pt, report(withEffort));
      final i = l.indexOf('Espera e chamadas');
      expect(l.sublist(i, i + 15), [
        'Espera e chamadas',
        'métrica,valor',
        'amostras de espera,6',
        'mediana (min),5.0',
        'P90 (min),20.0',
        'faixa de espera: Menos de 5 min,0',
        'faixa de espera: 5–15 min,5',
        'faixa de espera: 15–30 min,1',
        'faixa de espera: Mais de 30 min,0',
        'atendimentos chamados,6',
        're-chamadas,2',
        'atendimentos com re-chamada,1',
        'taxa de re-chamada (%),16.7',
        'movidos ao fim,1',
        'atendimentos com movido ao fim,1',
      ]);
      expect(lines(en, report(withEffort)).contains('Wait and calls'), isTrue);
    });

    test('wait and calls section is empty-safe', () {
      final r = report([
        QueueHistoryInput(queue('a'), const [], const [], const []),
      ]);
      final l = lines(pt, r);
      final i = l.indexOf('Espera e chamadas');
      expect(l[i + 2], 'amostras de espera,0');
      expect(l[i + 3], 'mediana (min),');
      expect(l[i + 4], 'P90 (min),');
      expect(l[i + 12], 'taxa de re-chamada (%),');
    });

    test('null averages stay empty', () {
      final r = report([
        QueueHistoryInput(queue('a'), const [], const [], const []),
      ]);
      final l = lines(pt, r);
      expect(l[12], 'espera média (min),');
      expect(l[13], 'atendimento médio (min),');
    });

    test('empty operators shows the empty message', () {
      final r = report([
        QueueHistoryInput(queue('a'), const [], const [], const []),
      ]);
      final l = lines(pt, r);
      expect(
        l[l.indexOf('Por atendente') + 1],
        'Nenhum atendimento por atendente no período',
      );
    });

    test('scope shows the selected queue and truncation note', () {
      final r = report(data, queueId: 'a', limit: 5);
      final l = lines(pt, r);
      expect(l[2], 'escopo por atendente,Caixa');
      expect(l[4], startsWith('Mostrando só os 5 registros'));
    });

    test('neutralizes formulas and escapes commas and quotes', () {
      for (final bad in ['=1+1', '+1', '-1', '@x']) {
        final d = [
          QueueHistoryInput(
            queue('a', name: bad),
            const [],
            const [],
            const [],
          ),
        ];
        final l = lines(pt, report(d));
        final i = l.indexOf('Filas mais ativas');
        expect(l[i + 2], "1,'$bad,0,0,0.0");
      }
      final d = [
        QueueHistoryInput(
          queue('a', name: 'A, "B"'),
          const [],
          const [],
          const [],
        ),
      ];
      final l = lines(pt, report(d));
      final i = l.indexOf('Filas mais ativas');
      expect(l[i + 2], '1,"A, ""B""",0,0,0.0');
    });

    test('operator names are protected too', () {
      final d = [
        QueueHistoryInput(
          queue('a'),
          [served('1', calledBy: 'u1')],
          const [],
          [op('u1', '=HYPERLINK("x")')],
        ),
      ];
      final l = lines(pt, report(d));
      final i = l.indexOf('Por atendente');
      expect(l[i + 2], startsWith('"\'=HYPERLINK(""x"")",1,0'));
    });

    test('headers follow the locale', () {
      final r = report(data);
      expect(lines(en, r)[1], 'period,All time');
      expect(lines(en, r)[7], 'total,5');
      expect(lines(en, r)[11], 'no-show rate (%),20.0');
      expect(lines(es, r)[0], 'Qio - Métricas de las filas');
      expect(lines(es, r)[1], 'período,Todo');
      expect(lines(es, r)[13], 'atención promedio (min),12.5');
    });
  });

  group('buildMetricsPdf', () {
    final pt = lookupAppLocalizations(const Locale('pt'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('builds a valid document with data', () async {
      final data = [
        QueueHistoryInput(
          queue('a', name: 'Caixa'),
          [
            served('1'),
            served('2', calledBy: 'u1'),
            served('3', calledBy: 'u1'),
            served('4', calledBy: 'u1', result: 'no_show'),
          ],
          const [QueueFeedback(entryId: '2', rating: 5)],
          [op('u1', 'Bia')],
        ),
      ];
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report(data, limit: 4),
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('builds with recalls and wait samples', () async {
      final bytes = await buildMetricsPdf(
        l10n: pt,
        report: report([
          QueueHistoryInput(
            queue('a'),
            [
              for (var i = 0; i < 5; i++) served('$i'),
              HistoryEntry(
                id: 'r',
                ticket: 1,
                name: 'r',
                result: 'served',
                joinedAt: DateTime(2026, 10, 7, 9),
                calledAt: DateTime(2026, 10, 7, 9, 20),
                recalls: 1,
                skips: 2,
              ),
            ],
            const [],
            const [],
          ),
        ]),
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('builds with empty data in another locale', () async {
      final bytes = await buildMetricsPdf(
        l10n: en,
        report: report([
          QueueHistoryInput(queue('a'), const [], const [], const []),
        ]),
        generatedAt: DateTime(2026, 10, 7),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
