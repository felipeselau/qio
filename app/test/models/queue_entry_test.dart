import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';

void main() {
  group('EntryStatusX', () {
    test('value returns storage values', () {
      expect(EntryStatus.waiting.value, 'waiting');
      expect(EntryStatus.called.value, 'called');
      expect(EntryStatus.served.value, 'served');
      expect(EntryStatus.noShow.value, 'no_show');
      expect(EntryStatus.left.value, 'left');
    });

    test('fromValue maps known values', () {
      expect(EntryStatusX.fromValue('waiting'), EntryStatus.waiting);
      expect(EntryStatusX.fromValue('called'), EntryStatus.called);
      expect(EntryStatusX.fromValue('served'), EntryStatus.served);
      expect(EntryStatusX.fromValue('no_show'), EntryStatus.noShow);
      expect(EntryStatusX.fromValue('left'), EntryStatus.left);
    });

    test('fromValue defaults to waiting for unknown/null', () {
      expect(EntryStatusX.fromValue(null), EntryStatus.waiting);
      expect(EntryStatusX.fromValue('garbage'), EntryStatus.waiting);
    });
  });

  group('QueueEntry.fromSnapshot', () {
    test('parses full snapshot', () {
      final joined = DateTime(2026, 1, 15, 10).millisecondsSinceEpoch;
      final called = DateTime(2026, 1, 15, 10, 20).millisecondsSinceEpoch;
      final e = QueueEntry.fromSnapshot('e1', {
        'ticket': 7,
        'name': 'João Silva',
        'phone': '(11) 99999-0000',
        'uid': 'user1',
        'fcmToken': 'token-abc',
        'status': 'called',
        'joinedAt': joined,
        'calledAt': called,
      });

      expect(e.id, 'e1');
      expect(e.ticket, 7);
      expect(e.name, 'João Silva');
      expect(e.phone, '(11) 99999-0000');
      expect(e.uid, 'user1');
      expect(e.fcmToken, 'token-abc');
      expect(e.status, EntryStatus.called);
      expect(e.joinedAt.millisecondsSinceEpoch, joined);
      expect(e.calledAt!.millisecondsSinceEpoch, called);
    });

    test('applies defaults for missing fields', () {
      final e = QueueEntry.fromSnapshot('e2', {});

      expect(e.ticket, 0);
      expect(e.name, '');
      expect(e.phone, isNull);
      expect(e.uid, '');
      expect(e.fcmToken, isNull);
      expect(e.status, EntryStatus.waiting);
      expect(e.calledAt, isNull);
    });

    test('calledAt stays null when absent', () {
      final e = QueueEntry.fromSnapshot('e3', {
        'ticket': 1,
        'status': 'waiting',
        'calledAt': null,
      });
      expect(e.calledAt, isNull);
    });
  });

  group('QueueEntry.toMap', () {
    test('serializes and omits null calledAt', () {
      final joined = DateTime(2026, 1, 15, 10);
      final e = QueueEntry(
        id: 'e4',
        ticket: 3,
        name: 'Maria',
        uid: 'user2',
        status: EntryStatus.waiting,
        joinedAt: joined,
      );

      final map = e.toMap();
      expect(map['ticket'], 3);
      expect(map['status'], 'waiting');
      expect(map['joinedAt'], joined.millisecondsSinceEpoch);
      expect(map.containsKey('calledAt'), isFalse);
    });

    test('includes calledAt when set', () {
      final joined = DateTime(2026, 1, 15, 10);
      final called = DateTime(2026, 1, 15, 10, 30);
      final e = QueueEntry(
        id: 'e5',
        ticket: 4,
        name: 'Pedro',
        uid: 'user3',
        status: EntryStatus.called,
        joinedAt: joined,
        calledAt: called,
      );

      expect(e.toMap()['calledAt'], called.millisecondsSinceEpoch);
    });
  });
}
