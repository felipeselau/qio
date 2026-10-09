import 'dart:typed_data';
import 'dart:ui' show Color, Locale;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';

const posterTitleMaxLength = 60;
const posterLogoPrefix = 'https://firebasestorage.googleapis.com/';
const posterLogoTimeout = Duration(seconds: 6);

enum PosterSize { a4, a5, table }

extension PosterSizeX on PosterSize {
  PdfPageFormat get format => switch (this) {
    PosterSize.a4 => PdfPageFormat.a4,
    PosterSize.a5 => PdfPageFormat.a5,
    PosterSize.table => const PdfPageFormat(
      100 * PdfPageFormat.mm,
      150 * PdfPageFormat.mm,
    ),
  };

  double get aspect => format.height / format.width;

  double get scale => format.width / PdfPageFormat.a4.width;

  String label(AppLocalizations l10n) => switch (this) {
    PosterSize.a4 => l10n.posterSizeA4,
    PosterSize.a5 => l10n.posterSizeA5,
    PosterSize.table => l10n.posterSizeTable,
  };
}

const _replacements = <String, String>{
  '★': '*',
  '☆': '*',
  '—': '-',
  '–': '-',
  '−': '-',
  '‘': "'",
  '’': "'",
  '‚': ',',
  '“': '"',
  '”': '"',
  '„': '"',
  '…': '...',
  '•': '-',
  '→': '->',
  '←': '<-',
  '€': 'EUR',
  '™': '(TM)',
  '✓': '',
  '✔': '',
};

String pdfSafeText(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final replacement = _replacements[ch];
    if (replacement != null) {
      out.write(replacement);
    } else if (rune < 0x20 || (rune >= 0x7F && rune <= 0x9F)) {
      out.write(' ');
    } else if (rune <= 0xFF) {
      out.write(ch);
    }
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String normalizePosterTitle(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

bool isValidPosterTitle(String value) =>
    normalizePosterTitle(value).length <= posterTitleMaxLength;

bool isPosterLogoUrl(String? url) =>
    url != null && url.startsWith(posterLogoPrefix);

Future<pw.ImageProvider?> fetchPosterLogo(
  String? url, {
  Duration timeout = posterLogoTimeout,
  Future<pw.ImageProvider> Function(String url)? loader,
}) async {
  if (!isPosterLogoUrl(url)) return null;
  try {
    return await (loader ?? (u) => networkImage(u))(url!).timeout(timeout);
  } catch (_) {
    return null;
  }
}

List<String> posterInstructions(Locale current) {
  final order = ['pt', 'en', 'es'];
  final first = order.contains(current.languageCode)
      ? current.languageCode
      : 'pt';
  final rest = order.where((c) => c != first);
  return [
    for (final code in [first, ...rest])
      pdfSafeText(lookupAppLocalizations(Locale(code)).scanToJoin),
  ];
}

PdfColor toPdfColor(Color color) => PdfColor(color.r, color.g, color.b);

Future<Uint8List> buildPosterPdf({
  required PosterSize size,
  required String queueName,
  required String url,
  required PdfColor accent,
  required PdfColor qrColor,
  required List<String> instructions,
  String? title,
  pw.ImageProvider? logo,
}) async {
  try {
    return await _renderPoster(
      size: size,
      queueName: queueName,
      url: url,
      accent: accent,
      qrColor: qrColor,
      instructions: instructions,
      title: title,
      logo: logo,
    );
  } catch (_) {
    if (logo == null) rethrow;
    return _renderPoster(
      size: size,
      queueName: queueName,
      url: url,
      accent: accent,
      qrColor: qrColor,
      instructions: instructions,
      title: title,
    );
  }
}

Future<Uint8List> _renderPoster({
  required PosterSize size,
  required String queueName,
  required String url,
  required PdfColor accent,
  required PdfColor qrColor,
  required List<String> instructions,
  String? title,
  pw.ImageProvider? logo,
}) {
  final s = size.scale;
  final name = pdfSafeText(queueName);
  final headline = title == null ? '' : pdfSafeText(title);
  final display = pdfSafeText(url.replaceFirst('https://', ''));
  final primary = instructions.isEmpty ? '' : instructions.first;
  final others = instructions.skip(1).join('   |   ');
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: size.format,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: accent,
            padding: pw.EdgeInsets.symmetric(
              horizontal: 32 * s,
              vertical: 36 * s,
            ),
            child: pw.Column(
              children: [
                if (logo != null) ...[
                  pw.Container(
                    width: 96 * s,
                    height: 96 * s,
                    padding: pw.EdgeInsets.all(6 * s),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 16 * s),
                ],
                if (name.isNotEmpty)
                  pw.Text(
                    name,
                    maxLines: 3,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 38 * s,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (headline.isNotEmpty) ...[
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: 32 * s),
                      child: pw.Text(
                        headline,
                        maxLines: 2,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 24 * s,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 18 * s),
                  ],
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: url,
                    width: 330 * s,
                    height: 330 * s,
                    color: qrColor,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 22 * s),
                  if (primary.isNotEmpty)
                    pw.Text(
                      primary,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 26 * s,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (others.isNotEmpty) ...[
                    pw.SizedBox(height: 6 * s),
                    pw.Text(
                      others,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12 * s,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 14 * s),
                  pw.Text(
                    display,
                    style: pw.TextStyle(fontSize: 18 * s, color: accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
