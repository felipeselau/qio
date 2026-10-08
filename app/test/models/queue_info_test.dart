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

  group('duplicateQueueName', () {
    test('appends the suffix', () {
      expect(duplicateQueueName('Padaria', ' (cópia)'), 'Padaria (cópia)');
    });

    test('truncates the base to stay within 60 chars', () {
      final name = duplicateQueueName('x' * 60, ' (cópia)');
      expect(name.length, lessThanOrEqualTo(queueNameMaxLength));
      expect(name.endsWith(' (cópia)'), isTrue);
    });
  });
}
