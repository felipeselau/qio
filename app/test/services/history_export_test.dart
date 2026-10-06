import 'package:flutter_test/flutter_test.dart';
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
  test('csv has BOM, header and row', () {
    final csv = buildHistoryCsv([entry()]);
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).trim().split('\r\n');
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

  test('csv escapes commas, quotes and formula prefixes', () {
    expect(csvCell('a,b'), '"a,b"');
    expect(csvCell('say "hi"'), '"say ""hi"""');
    expect(csvCell('=SUM(A1)'), "'=SUM(A1)");
  });

  test('csv leaves missing dates and phone empty', () {
    final e = HistoryEntry(
      id: 'x',
      ticket: 1,
      name: 'Bia',
      result: 'left',
      joinedAt: DateTime(2026, 10, 1),
    );
    final row = buildHistoryCsv([e]).substring(1).trim().split('\r\n')[1];
    expect(row, '1,Bia,,Desistiu,2026-10-01 00:00:00,,');
  });

  test('pdf builds a valid document', () async {
    final bytes = await buildHistoryPdf(
      queueName: 'Fila',
      entries: [
        entry(),
        entry(result: 'no_show'),
      ],
      generatedAt: DateTime(2026, 10, 6),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
