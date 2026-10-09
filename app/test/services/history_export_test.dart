import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/services/history_export.dart';

HistoryEntry entry({
  String name = 'Ana',
  String? phone = '(11) 91234-5678',
  String result = 'served',
}) => HistoryEntry(
  id: 'e1',
  ticket: 7,
  name: name,
  phone: phone,
  result: result,
  joinedAt: DateTime(2026, 10, 1, 9, 0, 0),
  calledAt: DateTime(2026, 10, 1, 9, 10, 0),
  finishedAt: DateTime(2026, 10, 1, 9, 20, 0),
);

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('csv has BOM, header and row', () {
    final csv = buildHistoryCsv(pt, [entry()]);
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).trim().split('\r\n');
    expect(lines[0], 'ticket,nome,resultado,entrada,chamado,finalizado');
    expect(
      lines[1],
      '7,Ana,Atendido,2026-10-01 09:00:00,'
      '2026-10-01 09:10:00,2026-10-01 09:20:00',
    );
  });

  test('csv omits the phone by default', () {
    final csv = buildHistoryCsv(pt, [entry()]);
    expect(csv.contains('91234'), isFalse);
    expect(csv.contains('telefone'), isFalse);
  });

  test('csv includes the phone only when requested', () {
    final lines = buildHistoryCsv(pt, [
      entry(),
    ], includePhone: true).substring(1).trim().split('\r\n');
    expect(
      lines[0],
      'ticket,nome,telefone,resultado,entrada,chamado,finalizado',
    );
    expect(
      lines[1],
      '7,Ana,(11) 91234-5678,Atendido,2026-10-01 09:00:00,'
      '2026-10-01 09:10:00,2026-10-01 09:20:00',
    );
  });

  test('csv header and result follow the locale', () {
    final lines = buildHistoryCsv(en, [
      entry(),
    ]).substring(1).trim().split('\r\n');
    expect(lines[0], 'ticket,name,result,joined,called,finished');
    expect(lines[1].split(',')[2], 'Served');
  });

  test('csv escapes commas, quotes and formula prefixes', () {
    expect(csvCell('a,b'), '"a,b"');
    expect(csvCell('say "hi"'), '"say ""hi"""');
    expect(csvCell('=SUM(A1)'), "'=SUM(A1)");
    expect(csvCell('\u0001=SUM(A1)'), "'\u0001=SUM(A1)");
  });

  test('csv leaves missing dates and phone empty', () {
    final e = HistoryEntry(
      id: 'x',
      ticket: 1,
      name: 'Bia',
      result: 'left',
      joinedAt: DateTime(2026, 10, 1),
    );
    final row = buildHistoryCsv(pt, [
      e,
    ], includePhone: true).substring(1).trim().split('\r\n')[1];
    expect(row, '1,Bia,,Desistiu,2026-10-01 00:00:00,,');
  });

  test('pdf builds a valid document', () async {
    final bytes = await buildHistoryPdf(
      l10n: pt,
      queueName: 'Fila',
      entries: [
        entry(),
        entry(result: 'no_show'),
      ],
      generatedAt: DateTime(2026, 10, 6),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('pdf with phone is larger than the default one', () async {
    Future<int> size({required bool includePhone}) async =>
        (await buildHistoryPdf(
          l10n: pt,
          queueName: 'Fila',
          entries: [entry()],
          generatedAt: DateTime(2026, 10, 6),
          includePhone: includePhone,
        )).length;
    final without = await size(includePhone: false);
    final withPhone = await size(includePhone: true);
    expect(withPhone, greaterThan(without));
  });

  test('pdf builds for another locale', () async {
    final bytes = await buildHistoryPdf(
      l10n: en,
      queueName: 'Queue',
      entries: const [],
      generatedAt: DateTime(2026, 10, 6),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
