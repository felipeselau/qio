import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../models/history_entry.dart';
import 'history_metrics.dart';

List<String> _csvHeader(AppLocalizations l10n) => [
  l10n.csvTicket,
  l10n.csvName,
  l10n.csvPhone,
  l10n.csvResult,
  l10n.csvEntered,
  l10n.csvCalled,
  l10n.csvFinished,
];

String resultLabel(AppLocalizations l10n, String result) => switch (result) {
  'served' => l10n.served,
  'no_show' => l10n.noShow,
  'left' => l10n.resultLeft,
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

String buildHistoryCsv(AppLocalizations l10n, List<HistoryEntry> entries) {
  final rows = <List<String>>[
    _csvHeader(l10n),
    for (final e in entries)
      [
        '${e.ticket}',
        e.name,
        e.phone ?? '',
        resultLabel(l10n, e.result),
        formatExportDateTime(e.joinedAt),
        formatExportDateTime(e.calledAt),
        formatExportDateTime(e.finishedAt),
      ],
  ];
  return '﻿${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}\r\n';
}

String _minutes(AppLocalizations l10n, double? v) {
  if (v == null) return '-';
  if (v < 1) return l10n.durationLessThanMinute;
  return l10n.durationMinutes(v.round());
}

Future<Uint8List> buildHistoryPdf({
  required AppLocalizations l10n,
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
            l10n.pdfTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(queueName, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            l10n.pdfGeneratedAt(formatExportDateTime(generatedAt)),
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
            _metric(l10n.pdfTotal, '${metrics.total}'),
            _metric(l10n.servedPlural, '${metrics.served}'),
            _metric(l10n.noShowPlural, '${metrics.noShow} ($pct%)'),
            _metric(l10n.leftPlural, '${metrics.left}'),
            _metric(l10n.avgWait, _minutes(l10n, metrics.avgWaitMin)),
            _metric(l10n.avgService, _minutes(l10n, metrics.avgServiceMin)),
          ],
        ),
        pw.SizedBox(height: 16),
        if (entries.isEmpty)
          pw.Text(l10n.pdfNoRecords)
        else
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.colTicket,
              l10n.colName,
              l10n.colPhone,
              l10n.colResult,
              l10n.colEntered,
              l10n.colCalled,
              l10n.colFinished,
            ],
            data: [
              for (final e in entries)
                [
                  '${e.ticket}',
                  e.name,
                  e.phone ?? '',
                  resultLabel(l10n, e.result),
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
