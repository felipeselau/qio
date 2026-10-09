import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qio_app/services/poster.dart';

const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Future<List<int>> _build(
  PosterSize size, {
  String name = 'Padaria',
  String? title,
  pw.ImageProvider? logo,
}) => buildPosterPdf(
  size: size,
  queueName: name,
  url: 'https://qio.web.app/n/padaria',
  accent: PdfColors.blue,
  qrColor: PdfColors.black,
  instructions: posterInstructions(const Locale('pt')),
  title: title,
  logo: logo,
);

void main() {
  group('pdfSafeText', () {
    test('substitui símbolos fora de Latin-1', () {
      expect(pdfSafeText('★ Nota 5 — ótimo…'), '* Nota 5 - ótimo...');
      expect(pdfSafeText('“aspas” e ‘simples’'), '"aspas" e \'simples\'');
    });

    test('mantém Latin-1', () {
      expect(
        pdfSafeText('Pão de açúcar ¡Ñandú! ¿Sí?'),
        'Pão de açúcar ¡Ñandú! ¿Sí?',
      );
    });

    test('remove emoji, CJK e controles', () {
      expect(pdfSafeText('Fila 😀 日本\nok\t'), 'Fila ok');
      expect(pdfSafeText('😀'), '');
    });

    test('resultado só tem code points até 0xFF', () {
      final out = pdfSafeText('a★b—c‘d’e“f”g…h•i€j™k😀l中');
      expect(out.runes.every((r) => r <= 0xFF), isTrue);
    });
  });

  group('título do cartaz', () {
    test('normaliza espaços', () {
      expect(normalizePosterTitle('  olá   mundo '), 'olá mundo');
    });

    test('limite de 60 caracteres', () {
      expect(isValidPosterTitle('a' * 60), isTrue);
      expect(isValidPosterTitle('a' * 61), isFalse);
      expect(isValidPosterTitle('  ${'a' * 60}  '), isTrue);
      expect(isValidPosterTitle(''), isTrue);
    });
  });

  group('tamanhos', () {
    test('A4, A5 e cartão de mesa', () {
      expect(PosterSize.a4.format, PdfPageFormat.a4);
      expect(PosterSize.a5.format, PdfPageFormat.a5);
      expect(
        PosterSize.table.format.width,
        closeTo(100 * PdfPageFormat.mm, 0.1),
      );
      expect(
        PosterSize.table.format.height,
        closeTo(150 * PdfPageFormat.mm, 0.1),
      );
    });

    test('escala relativa ao A4', () {
      expect(PosterSize.a4.scale, 1);
      expect(PosterSize.a5.scale, closeTo(0.706, 0.01));
      expect(PosterSize.table.scale, closeTo(0.476, 0.01));
    });
  });

  group('logo', () {
    test('só aceita https do Storage', () {
      expect(
        isPosterLogoUrl('https://firebasestorage.googleapis.com/v0/b/x/o/y'),
        isTrue,
      );
      expect(
        isPosterLogoUrl('http://firebasestorage.googleapis.com/x'),
        isFalse,
      );
      expect(isPosterLogoUrl('https://evil.example/logo.png'), isFalse);
      expect(isPosterLogoUrl(null), isFalse);
    });

    test('URL fora do Storage nem chama o loader', () async {
      var called = false;
      final logo = await fetchPosterLogo(
        'https://evil.example/logo.png',
        loader: (_) async {
          called = true;
          return pw.MemoryImage(base64Decode(_pngBase64));
        },
      );
      expect(logo, isNull);
      expect(called, isFalse);
    });

    test('falha do loader vira null', () async {
      final logo = await fetchPosterLogo(
        'https://firebasestorage.googleapis.com/v0/b/x/o/y',
        loader: (_) async => throw Exception('rede'),
      );
      expect(logo, isNull);
    });

    test('timeout vira null', () async {
      final logo = await fetchPosterLogo(
        'https://firebasestorage.googleapis.com/v0/b/x/o/y',
        timeout: const Duration(milliseconds: 20),
        loader: (_) => Completer<pw.ImageProvider>().future,
      );
      expect(logo, isNull);
    });
  });

  group('buildPosterPdf', () {
    for (final size in PosterSize.values) {
      test('gera PDF em ${size.name}', () async {
        final bytes = await _build(size, title: 'Peça seu lugar');
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
      });
    }

    test('nome só com emoji e símbolos não quebra', () async {
      final bytes = await _build(PosterSize.table, name: '😀 ★ —');
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('inclui o logo quando disponível', () async {
      final semLogo = await _build(PosterSize.a4);
      final comLogo = await _build(
        PosterSize.a4,
        logo: pw.MemoryImage(base64Decode(_pngBase64)),
      );
      expect(comLogo.length, greaterThan(semLogo.length));
    });
  });

  group('posterInstructions', () {
    test('idioma atual primeiro, depois os outros dois', () {
      expect(posterInstructions(const Locale('en')), [
        'Scan to join the queue',
        'Escaneie para entrar na fila',
        'Escanea para entrar a la fila',
      ]);
      expect(
        posterInstructions(const Locale('fr')).first,
        'Escaneie para entrar na fila',
      );
    });
  });
}
