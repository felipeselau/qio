import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/history_entry.dart';
import 'history_metrics.dart';

const _csvHeader = [
  'ticket',
  'nome',
  'telefone',
  'resultado',
  'entrada',
  'chamado',
  'finalizado',
];

String resultLabel(String result) => switch (result) {
  'served' => 'Atendido',
  'no_show' => 'Não compareceu',
  'left' => 'Desistiu',
  _ => result,
};

String _two(int n) => n.toString().padLeft(2, '0');

String formatExportDateTime(DateTime? d) {
  if (d == null) return '';
  return '${d.year}-${_two(d.month)}-${_two(d.day)} '
      '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
}

String csvCell(String value) {
  var v = value;
  if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
  if (v.contains(RegExp(r'[",\n\r]'))) {
    v = '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String buildHistoryCsv(List<HistoryEntry> entries) {
  final rows = <List<String>>[
    _csvHeader,
    for (final e in entries)
      [
        '${e.ticket}',
        e.name,
        e.phone ?? '',
        resultLabel(e.result),
        formatExportDateTime(e.joinedAt),
        formatExportDateTime(e.calledAt),
        formatExportDateTime(e.finishedAt),
      ],
  ];
  return '﻿${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}\r\n';
}

String _minutes(double? v) {
  if (v == null) return '-';
  if (v < 1) return '<1 min';
  return '${v.round()} min';
}

Future<Uint8List> buildHistoryPdf({
  required String queueName,
  required List<HistoryEntry> entries,
  required DateTime generatedAt,
}) {
  final metrics = computeHistoryMetrics(entries);
  final pct = (metrics.noShowRate * 100).round();
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Qio - Histórico de atendimentos',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(queueName, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            'Gerado em ${formatExportDateTime(generatedAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
        ],
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        pw.Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _metric('Total', '${metrics.total}'),
            _metric('Atendidos', '${metrics.served}'),
            _metric('Não compareceram', '${metrics.noShow} ($pct%)'),
            _metric('Desistiram', '${metrics.left}'),
            _metric('Espera média', _minutes(metrics.avgWaitMin)),
            _metric('Atendimento médio', _minutes(metrics.avgServiceMin)),
          ],
        ),
        pw.SizedBox(height: 16),
        if (entries.isEmpty)
          pw.Text('Nenhum atendimento no período.')
        else
          pw.TableHelper.fromTextArray(
            headers: const [
              'Ticket',
              'Nome',
              'Telefone',
              'Resultado',
              'Entrada',
              'Chamado',
              'Finalizado',
            ],
            data: [
              for (final e in entries)
                [
                  '${e.ticket}',
                  e.name,
                  e.phone ?? '',
                  resultLabel(e.result),
                  _short(e.joinedAt),
                  _short(e.calledAt),
                  _short(e.finishedAt),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
          ),
      ],
    ),
  );
  return doc.save();
}

String _short(DateTime? d) {
  if (d == null) return '';
  return '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
}

pw.Widget _metric(String label, String value) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      label,
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
    ),
    pw.Text(
      value,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    ),
  ],
);
