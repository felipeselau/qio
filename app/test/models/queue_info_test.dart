import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_info.dart';

void main() {
  group('QueueInfo validation', () {
    test('accepts boundaries', () {
      expect(
        QueueInfo(
          name: 'x' * 60,
          description: 'd' * 300,
          avgServiceMin: 240,
        ).error,
        isNull,
      );
      expect(const QueueInfo(name: 'a', avgServiceMin: 1).error, isNull);
    });

    test('rejects blank and long names', () {
      expect(const QueueInfo(name: '   ').error, QueueInfoError.nameRequired);
      expect(QueueInfo(name: 'x' * 61).error, QueueInfoError.nameTooLong);
    });

    test('rejects long description', () {
      expect(
        QueueInfo(name: 'a', description: 'd' * 301).error,
        QueueInfoError.descriptionTooLong,
      );
    });

    test('rejects average time outside 1-240', () {
      for (final v in [0, -1, 241]) {
        expect(
          QueueInfo(name: 'a', avgServiceMin: v).error,
          QueueInfoError.avgServiceInvalid,
        );
      }
      expect(
        QueueInfo.validateAvgServiceMin(null),
        QueueInfoError.avgServiceInvalid,
      );
    });
  });

  group('QueueInfo mapping', () {
    test('normalizes whitespace and blank description to null', () {
      final info = const QueueInfo(
        name: '  Padaria ',
        description: '   ',
        avgServiceMin: 12,
      ).normalized();
      expect(info.toFields(), {
        'name': 'Padaria',
        'description': null,
        'avgServiceMin': 12,
      });
    });

    test('keeps a trimmed description', () {
      final info = const QueueInfo(name: 'a', description: ' oi ').normalized();
      expect(info.description, 'oi');
      expect(info.avgServiceMin, defaultAvgServiceMin);
    });

    test('parseAvgServiceMin returns null for blanks and junk', () {
      expect(QueueInfo.parseAvgServiceMin(' 15 '), 15);
      expect(QueueInfo.parseAvgServiceMin(''), isNull);
      expect(QueueInfo.parseAvgServiceMin('x'), isNull);
    });
  });

  group('QueueInfo.forMirror', () {
    test('truncates, falls back and resets out-of-range values', () {
      final info = QueueInfo.forMirror(
        name: 'x' * 80,
        description: 'd' * 400,
        avgServiceMin: 999,
      );
      expect(info.name.length, queueNameMaxLength);
      expect(info.description!.length, queueDescriptionMaxLength);
      expect(info.avgServiceMin, defaultAvgServiceMin);
      expect(info.error, isNull);
    });

    test('empty name becomes the fallback and blank description null', () {
      final info = QueueInfo.forMirror(
        name: '   ',
        description: '  ',
        avgServiceMin: 0,
      );
      expect(info.name, fallbackQueueName);
      expect(info.description, isNull);
      expect(info.avgServiceMin, defaultAvgServiceMin);
    });

    test('keeps valid values', () {
      final info = QueueInfo.forMirror(
        name: 'Padaria',
        description: 'oi',
        avgServiceMin: 7,
      );
      expect(info.toFields(), {
        'name': 'Padaria',
        'description': 'oi',
        'avgServiceMin': 7,
      });
    });
  });

  group('changes', () {
    const current = QueueInfo(
      name: 'Padaria',
      description: 'oi',
      avgServiceMin: 5,
    );

    test('only changed fields are reported', () {
      final next = const QueueInfo(
        name: ' Padaria ',
        description: 'oi',
        avgServiceMin: 8,
      );
      expect(next.changesFrom(current), {'avgServiceMin': 8});
      expect(current.changesFrom(current), isEmpty);
    });

    test('legacy long name does not block editing other fields', () {
      final legacy = QueueInfo(name: 'x' * 80, avgServiceMin: 5);
      final next = QueueInfo(name: 'x' * 80, avgServiceMin: 9);
      final changes = next.changesFrom(legacy);
      expect(changes, {'avgServiceMin': 9});
      expect(next.errorForChanges(changes), isNull);
      final renamed = QueueInfo(name: 'y' * 80, avgServiceMin: 5);
      expect(
        renamed.errorForChanges(renamed.changesFrom(legacy)),
        QueueInfoError.nameTooLong,
      );
    });
  });

  group('mirrorInfoPatch', () {
    const doc = QueueInfo(name: 'Padaria', description: 'oi', avgServiceMin: 5);

    test('null when meta matches or is missing', () {
      expect(
        mirrorInfoPatch({
          'name': 'Padaria',
          'description': 'oi',
          'avgServiceMin': 5,
        }, doc),
        isNull,
      );
      expect(
        mirrorInfoPatch({
          'name': 'Padaria',
          'description': 'oi',
          'avgServiceMin': 5.0,
        }, doc),
        isNull,
      );
      expect(mirrorInfoPatch(null, doc), isNull);
    });

    test('reports divergent fields only', () {
      expect(
        mirrorInfoPatch({
          'name': 'Velho',
          'description': 'oi',
          'avgServiceMin': 9,
        }, doc),
        {'name': 'Padaria', 'avgServiceMin': 5},
      );
    });

    test('missing description in meta equals null in doc', () {
      expect(
        mirrorInfoPatch({
          'name': 'A',
          'avgServiceMin': 5,
        }, const QueueInfo(name: 'A', avgServiceMin: 5)),
        isNull,
      );
      expect(
        mirrorInfoPatch({
          'name': 'A',
          'description': 'x',
          'avgServiceMin': 5,
        }, const QueueInfo(name: 'A', avgServiceMin: 5)),
        {'description': null},
      );
    });

    test('legacy invalid doc is compared against its normalized form', () {
      final legacy = QueueInfo(name: 'x' * 80, avgServiceMin: 999);
      final patch = mirrorInfoPatch({
        'name': 'x' * 80,
        'avgServiceMin': 999,
      }, legacy);
      expect((patch!['name'] as String).length, queueNameMaxLength);
      expect(patch['avgServiceMin'], defaultAvgServiceMin);
    });
  });

  group('duplicateQueueName', () {
    test('appends the copy marker', () {
      expect(duplicateQueueName('Padaria', 'cópia'), 'Padaria (cópia)');
    });

    test('numbers instead of stacking', () {
      expect(
        duplicateQueueName('Padaria (cópia)', 'cópia'),
        'Padaria (cópia 2)',
      );
      expect(
        duplicateQueueName('Padaria (cópia 2)', 'cópia'),
        'Padaria (cópia 3)',
      );
    });

    test('truncates the base to stay within 60 chars', () {
      final name = duplicateQueueName('x' * 60, 'cópia');
      expect(name.length, lessThanOrEqualTo(queueNameMaxLength));
      expect(name.endsWith(' (cópia)'), isTrue);
    });
  });
}
