import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';

void main() {
  group('QueueStatusX', () {
    test('label returns pt-BR labels', () {
      expect(QueueStatus.open.label, 'Aberta');
      expect(QueueStatus.paused.label, 'Pausada');
      expect(QueueStatus.closed.label, 'Fechada');
    });

    test('value returns storage values', () {
      expect(QueueStatus.open.value, 'open');
      expect(QueueStatus.paused.value, 'paused');
      expect(QueueStatus.closed.value, 'closed');
    });

    test('fromValue maps known values', () {
      expect(QueueStatusX.fromValue('open'), QueueStatus.open);
      expect(QueueStatusX.fromValue('paused'), QueueStatus.paused);
      expect(QueueStatusX.fromValue('closed'), QueueStatus.closed);
    });

    test('fromValue defaults to open for unknown/null', () {
      expect(QueueStatusX.fromValue(null), QueueStatus.open);
      expect(QueueStatusX.fromValue('garbage'), QueueStatus.open);
    });
  });

  group('Queue.fromDoc', () {
    test('parses full doc with Firestore Timestamp', () {
      final date = DateTime(2026, 1, 15, 10, 30);
      final q = Queue.fromDoc('q1', {
        'ownerId': 'owner1',
        'name': 'Atendimento Geral',
        'description': 'Fila principal',
        'status': 'paused',
        'avgServiceMin': 15,
        'createdAt': Timestamp.fromDate(date),
      });

      expect(q.id, 'q1');
      expect(q.ownerId, 'owner1');
      expect(q.name, 'Atendimento Geral');
      expect(q.description, 'Fila principal');
      expect(q.status, QueueStatus.paused);
      expect(q.avgServiceMin, 15);
      expect(q.createdAt, date);
    });

    test('parses createdAt from ISO string', () {
      final q = Queue.fromDoc('q2', {
        'ownerId': 'owner1',
        'name': 'Fila',
        'createdAt': '2026-02-20T14:00:00.000',
      });

      expect(q.createdAt, DateTime(2026, 2, 20, 14));
    });

    test('applies defaults for missing fields', () {
      final q = Queue.fromDoc('q3', {});

      expect(q.ownerId, '');
      expect(q.name, '');
      expect(q.description, isNull);
      expect(q.status, QueueStatus.open);
      expect(q.avgServiceMin, 10);
    });

    test('parses avgServiceMin from double', () {
      final q = Queue.fromDoc('q4', {'avgServiceMin': 12.0});
      expect(q.avgServiceMin, 12);
    });
  });

  group('Queue.toMap', () {
    test('serializes to storage format', () {
      final date = DateTime(2026, 3, 1);
      final q = Queue(
        id: 'q5',
        ownerId: 'owner1',
        name: 'Fila',
        status: QueueStatus.closed,
        avgServiceMin: 20,
        createdAt: date,
      );

      final map = q.toMap();
      expect(map['ownerId'], 'owner1');
      expect(map['status'], 'closed');
      expect(map['avgServiceMin'], 20);
      expect(map['createdAt'], date.toIso8601String());
    });
  });
}
