import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/qr_style.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';

class QrPosterScreen extends StatefulWidget {
  const QrPosterScreen({
    super.key,
    required this.queueName,
    required this.joinUrl,
  });

  final String queueName;
  final String joinUrl;

  @override
  State<QrPosterScreen> createState() => _QrPosterScreenState();
}

class _QrPosterScreenState extends State<QrPosterScreen> {
  final _boundaryKey = GlobalKey();
  QrColorPreset _preset = QrColorPreset.azul;
  bool _busy = false;

  String get _displayUrl => widget.joinUrl.replaceFirst('https://', '');

  String get _baseName {
    final slug = widget.queueName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'qio-${slug.isEmpty ? 'fila' : slug}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: QioColors.error),
    );
  }

  Future<void> _run(Future<void> Function() action, String errorMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Exception {
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _capturePng() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('png');
    return data.buffer.asUint8List();
  }

  Future<void> _shareImage() => _run(() async {
    final bytes = await _capturePng();
    final fileName = '$_baseName.png';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  }, 'Não foi possível compartilhar a imagem.');

  Future<void> _print() => _run(() async {
    final color = _preset.color;
    final pdfColor = PdfColor(color.r, color.g, color.b);
    final name = widget.queueName;
    final url = widget.joinUrl;
    final display = _displayUrl;
    await Printing.layoutPdf(
      name: _baseName,
      onLayout: (format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(48),
            build: (_) => pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 32),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: url,
                    width: 360,
                    height: 360,
                    color: pdfColor,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text(
                    'Escaneie para entrar na fila',
                    style: const pw.TextStyle(fontSize: 22),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(display, style: const pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        );
        return doc.save();
      },
    );
  }, 'Não foi possível imprimir o cartaz.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Cartaz do QR',
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    widget.queueName,
                    textAlign: TextAlign.center,
                    style: QioTextStyles.heading1.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  QrImageView(
                    data: widget.joinUrl,
                    version: QrVersions.auto,
                    size: 260,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: _preset.color,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: _preset.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Escaneie para entrar na fila',
                    style: QioTextStyles.body.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayUrl,
                    style: QioTextStyles.caption.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'COR DO QR',
            style: QioTextStyles.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: QioColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in QrColorPreset.values)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: p.color, radius: 8),
                  label: Text(p.label),
                  selected: _preset == p,
                  onSelected: (_) => setState(() => _preset = p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          QioButton(
            label: 'Compartilhar imagem',
            icon: Icons.share_outlined,
            isFullWidth: true,
            isLoading: _busy,
            onPressed: _busy ? null : _shareImage,
          ),
          const SizedBox(height: 12),
          QioButton(
            label: 'Imprimir',
            variant: QioButtonVariant.secondary,
            icon: Icons.print,
            isFullWidth: true,
            onPressed: _busy ? null : _print,
          ),
        ],
      ),
    );
  }
}
