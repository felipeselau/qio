import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/brand_palette.dart';
import '../services/poster.dart';
import '../services/qr_style.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_input.dart';

class QrPosterScreen extends StatefulWidget {
  const QrPosterScreen({
    super.key,
    required this.queueName,
    required this.joinUrl,
    this.queueId,
    this.logoUrl,
    this.brandColor,
    this.posterTitle,
    this.canEdit = false,
    this.queues,
  });

  final String queueName;
  final String joinUrl;
  final String? queueId;
  final String? logoUrl;
  final String? brandColor;
  final String? posterTitle;
  final bool canEdit;
  final QueueService? queues;

  @override
  State<QrPosterScreen> createState() => _QrPosterScreenState();
}

class _QrPosterScreenState extends State<QrPosterScreen> {
  final _boundaryKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.posterTitle ?? '',
  );
  QrColorPreset _preset = QrColorPreset.azul;
  PosterSize _size = PosterSize.a4;
  bool _busy = false;
  Future<pw.ImageProvider?>? _logo;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String get _displayUrl => widget.joinUrl.replaceFirst('https://', '');

  String get _baseName {
    final slug = widget.queueName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'qio-${slug.isEmpty ? 'fila' : slug}';
  }

  Color get _accent => isValidBrandHex(widget.brandColor)
      ? BrandColor(widget.brandColor!.toUpperCase(), '').color
      : _preset.color;

  String? get _headline {
    final text = normalizePosterTitle(_title.text);
    return text.isEmpty ? null : text;
  }

  bool get _canEditTitle => widget.canEdit && widget.queueId != null;

  String? _validateTitle(String? value, AppLocalizations l10n) =>
      isValidPosterTitle(value ?? '') ? null : l10n.posterHeadlineInvalid;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: QioColors.error),
    );
  }

  Future<void> _run(Future<void> Function() action, String errorMessage) async {
    if (_busy) return;
    if (_formKey.currentState?.validate() == false) return;
    setState(() => _busy = true);
    try {
      await _persistTitle();
      await action();
    } on Exception {
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistTitle() async {
    final id = widget.queueId;
    if (!_canEditTitle || id == null) return;
    final next = _headline;
    final previous = widget.posterTitle;
    if (next == (previous == null || previous.isEmpty ? null : previous)) {
      return;
    }
    try {
      await (widget.queues ?? QueueService.instance).updatePosterTitle(
        id,
        next,
      );
    } on Exception {
      return;
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

  Future<Uint8List> _buildPdf() async {
    final logo = await (_logo ??= fetchPosterLogo(widget.logoUrl));
    if (!mounted) throw Exception('disposed');
    return buildPosterPdf(
      size: _size,
      queueName: widget.queueName,
      url: widget.joinUrl,
      accent: toPdfColor(_accent),
      qrColor: toPdfColor(_preset.color),
      instructions: posterInstructions(Localizations.localeOf(context)),
      title: _headline,
      logo: logo,
      fallbackName: AppLocalizations.of(context).posterNameFallback,
    );
  }

  Future<void> _shareImage() => _run(() async {
    final bytes = await _capturePng();
    final fileName = '$_baseName.png';
    await SharePlus.instance.share(
      ShareParams(
        text: widget.joinUrl,
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  }, AppLocalizations.of(context).shareImageError);

  Future<void> _sharePdf() => _run(() async {
    final bytes = await _buildPdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$_baseName-${_size.name}.pdf',
    );
  }, AppLocalizations.of(context).sharePdfError);

  Future<void> _print() => _run(() async {
    await Printing.layoutPdf(
      name: _baseName,
      format: _size.format,
      onLayout: (_) => _buildPdf(),
    );
  }, AppLocalizations.of(context).printPosterError);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          l10n.posterTitle,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Semantics(
                image: true,
                label: l10n.posterPreviewSemantics(_size.label(l10n)),
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: AspectRatio(
                      aspectRatio: 1 / _size.aspect,
                      child: _PosterPreview(
                        queueName: pdfSafeText(widget.queueName).isEmpty
                            ? l10n.posterNameFallback
                            : widget.queueName,
                        url: widget.joinUrl,
                        displayUrl: _displayUrl,
                        title: _headline,
                        logoUrl: widget.logoUrl,
                        accent: _accent,
                        qrColor: _preset.color,
                        instructions: posterInstructions(
                          Localizations.localeOf(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (pdfTextLosesChars(widget.queueName) ||
              pdfTextLosesChars(_headline ?? '')) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.posterNameLossy,
                style: context.qioText.caption.copyWith(
                  color: context.qio.gray700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.posterSize,
            style: context.qioText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.qio.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in PosterSize.values)
                ChoiceChip(
                  label: Text(s.label(l10n)),
                  selected: _size == s,
                  onSelected: (_) => setState(() => _size = s),
                ),
            ],
          ),
          if (_canEditTitle) ...[
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: QioInput(
                label: l10n.posterHeadlineLabel,
                hint: l10n.posterHeadlineHint,
                controller: _title,
                validator: (v) => _validateTitle(v, l10n),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.qrColor,
            style: context.qioText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.qio.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in QrColorPreset.values)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: p.color, radius: 8),
                  label: Text(p.label(l10n)),
                  selected: _preset == p,
                  onSelected: (_) => setState(() => _preset = p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          QioButton(
            label: l10n.shareImage,
            icon: Icons.share_outlined,
            isFullWidth: true,
            isLoading: _busy,
            onPressed: _busy ? null : _shareImage,
          ),
          const SizedBox(height: 12),
          QioButton(
            label: l10n.sharePdf,
            variant: QioButtonVariant.secondary,
            icon: Icons.picture_as_pdf_outlined,
            isFullWidth: true,
            onPressed: _busy ? null : _sharePdf,
          ),
          const SizedBox(height: 12),
          QioButton(
            label: l10n.print,
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

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({
    required this.queueName,
    required this.url,
    required this.displayUrl,
    required this.title,
    required this.logoUrl,
    required this.accent,
    required this.qrColor,
    required this.instructions,
  });

  final String queueName;
  final String url;
  final String displayUrl;
  final String? title;
  final String? logoUrl;
  final Color accent;
  final Color qrColor;
  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final k = w / 595;
        final style = context.qioText.body;
        final logo = isPosterLogoUrl(logoUrl) ? logoUrl : null;
        return ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: accent,
                padding: EdgeInsets.symmetric(
                  horizontal: 32 * k,
                  vertical: 36 * k,
                ),
                child: Column(
                  children: [
                    if (logo != null) ...[
                      Container(
                        width: 96 * k,
                        height: 96 * k,
                        padding: EdgeInsets.all(6 * k),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * k),
                    ],
                    Text(
                      queueName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        fontSize: 38 * k,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32 * k),
                              child: Text(
                                title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: style.copyWith(
                                  fontSize: 24 * k,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(height: 18 * k),
                          ],
                          QrImageView(
                            data: url,
                            version: QrVersions.auto,
                            size: 330 * k,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: qrColor,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: qrColor,
                            ),
                          ),
                          SizedBox(height: 22 * k),
                          if (instructions.isNotEmpty)
                            Text(
                              instructions.first,
                              textAlign: TextAlign.center,
                              style: style.copyWith(
                                fontSize: 26 * k,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          if (instructions.length > 1) ...[
                            SizedBox(height: 6 * k),
                            Text(
                              instructions.skip(1).join('   |   '),
                              textAlign: TextAlign.center,
                              style: style.copyWith(
                                fontSize: 12 * k,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          SizedBox(height: 14 * k),
                          Text(
                            displayUrl,
                            style: style.copyWith(
                              fontSize: 18 * k,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
