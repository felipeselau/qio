import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/services/operator_service.dart';

void main() {
  group('OperatorRequestStatusX', () {
    test('round-trips storage values', () {
      for (final s in OperatorRequestStatus.values) {
        expect(OperatorRequestStatusX.fromValue(s.value), s);
      }
    });

    test('defaults to pending for unknown/null', () {
      expect(
        OperatorRequestStatusX.fromValue(null),
        OperatorRequestStatus.pending,
      );
      expect(
        OperatorRequestStatusX.fromValue('garbage'),
        OperatorRequestStatus.pending,
      );
    });
  });

  group('OperatorRequest.fromDoc', () {
    test('parses fields and timestamps', () {
      final requested = DateTime(2026, 9, 24, 10);
      final r = OperatorRequest.fromDoc('u1', {
        'queueId': 'q1',
        'queueName': 'Balcão',
        'status': 'rejected',
        'displayName': 'Ana',
        'email': 'ana@example.com',
        'requestedAt': Timestamp.fromDate(requested),
      });

      expect(r.uid, 'u1');
      expect(r.queueId, 'q1');
      expect(r.queueName, 'Balcão');
      expect(r.status, OperatorRequestStatus.rejected);
      expect(r.requestedAt, requested);
      expect(r.respondedAt, isNull);
      expect(r.label, 'Ana');
    });

    test('label falls back to email then uid', () {
      expect(OperatorRequest.fromDoc('u2', {'email': 'x@y.z'}).label, 'x@y.z');
      expect(OperatorRequest.fromDoc('u3', {}).label, 'u3');
    });
  });

  group('QueueOperator.fromDoc', () {
    test('parses fields', () {
      final op = QueueOperator.fromDoc('u1', {
        'queueId': 'q1',
        'queueName': 'Balcão',
        'addedBy': 'owner1',
        'addedAt': Timestamp.fromDate(DateTime(2026, 9, 24)),
      });

      expect(op.uid, 'u1');
      expect(op.queueId, 'q1');
      expect(op.addedBy, 'owner1');
      expect(op.addedAt, DateTime(2026, 9, 24));
      expect(op.label, 'u1');
    });
  });

  group('OperatorService.normalizeCode', () {
    test('uppercases and strips separators', () {
      expect(OperatorService.normalizeCode(' k7m-2qx '), 'K7M2QX');
    });

    test('drops accents and symbols', () {
      expect(OperatorService.normalizeCode('ab.c d/é1'), 'ABCD1');
    });
  });

  group('removed status', () {
    test('parses removed', () {
      expect(
        OperatorRequestStatusX.fromValue('removed'),
        OperatorRequestStatus.removed,
      );
      expect(OperatorRequestStatus.removed.value, 'removed');
    });
  });

  group('isInviteExpired', () {
    final now = DateTime(2026, 9, 27, 12);

    test('no expiration never expires', () {
      expect(isInviteExpired(null, now), isFalse);
    });

    test('future expiration is valid', () {
      expect(
        isInviteExpired(now.add(const Duration(minutes: 1)), now),
        isFalse,
      );
    });

    test('past expiration is expired', () {
      expect(
        isInviteExpired(now.subtract(const Duration(seconds: 1)), now),
        isTrue,
      );
    });

    test('expires exactly at expiresAt', () {
      expect(isInviteExpired(now, now), isTrue);
    });

    test('default validity is 24 hours', () {
      expect(OperatorService.defaultInviteValidity, const Duration(hours: 24));
    });
  });
}
