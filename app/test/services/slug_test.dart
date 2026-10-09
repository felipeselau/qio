import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/join_url.dart';
import 'package:qio_app/services/slug.dart';

void main() {
  const valid = ['abc', 'cafe-do-ze', 'a1b', 'loja-2', '123', 'a--b'];
  const invalid = [
    '',
    'ab',
    '-abc',
    'abc-',
    'ab_c',
    'café',
    'a b c',
    'abc/def',
    'ABC',
    'abc.def',
    'abc\n',
  ];
  const reserved = [
    'admin',
    'api',
    'app',
    'q',
    'c',
    'w',
    'n',
    'privacidade',
    'termos',
    'assets',
    'fonts',
    'icons',
  ];

  group('isValidSlug', () {
    for (final s in [...valid, 'a' * 40]) {
      test('aceita "$s"', () => expect(isValidSlug(s), isTrue));
    }
    for (final s in [...invalid, 'a' * 41]) {
      test('rejeita "${s.replaceAll('\n', r'\n')}"', () {
        expect(isValidSlug(s), isFalse);
      });
    }
    for (final s in reserved) {
      test('rejeita reservado $s', () => expect(isValidSlug(s), isFalse));
    }
  });

  test('slugError distingue formato e reservado', () {
    expect(slugError('ab'), SlugError.format);
    expect(slugError('admin'), SlugError.reserved);
    expect(slugError('privacidade'), SlugError.reserved);
    expect(slugError('minha-loja'), isNull);
  });

  test('lista de reservados completa', () {
    expect([...slugReserved]..sort(), [...reserved]..sort());
  });

  test('normalizeSlug faz trim e minúsculas', () {
    expect(normalizeSlug('  Cafe-Do-Ze '), 'cafe-do-ze');
  });

  group('link curto', () {
    test('shortUrl usa /n/', () {
      expect(shortUrl('cafe'), 'https://qio.web.app/n/cafe');
    });

    test('queueLinkUrl cai para /q/ sem slug', () {
      expect(queueLinkUrl('q1', null), 'https://qio.web.app/q/q1');
      expect(queueLinkUrl('q1', ''), 'https://qio.web.app/q/q1');
      expect(queueLinkUrl('q1', 'cafe'), 'https://qio.web.app/n/cafe');
    });
  });

  group('slugAvailability', () {
    final now = DateTime(2026, 10, 9);
    SlugAvailability check({
      bool exists = true,
      bool released = false,
      String owner = 'outro',
      DateTime? releasedAt,
    }) => slugAvailability(
      exists: exists,
      uid: 'eu',
      now: now,
      released: released,
      ownerId: owner,
      releasedAt: releasedAt,
    );

    test('inexistente está livre', () {
      expect(check(exists: false), SlugAvailability.free);
    });

    test('ativo está em uso, mesmo sendo meu', () {
      expect(check(owner: 'eu'), SlugAvailability.taken);
      expect(check(), SlugAvailability.taken);
    });

    test('tombstone meu pode ser retomado', () {
      expect(
        check(released: true, owner: 'eu', releasedAt: now),
        SlugAvailability.mine,
      );
    });

    test('tombstone de outro só livra depois de 30 dias', () {
      expect(
        check(
          released: true,
          releasedAt: now.subtract(const Duration(days: 29)),
        ),
        SlugAvailability.taken,
      );
      expect(
        check(
          released: true,
          releasedAt: now.subtract(const Duration(days: 31)),
        ),
        SlugAvailability.free,
      );
      expect(check(released: true), SlugAvailability.taken);
    });
  });

  group('canReleaseSlug', () {
    bool can({
      bool exists = true,
      bool released = false,
      String owner = 'eu',
      String queue = 'q1',
    }) => canReleaseSlug(
      exists: exists,
      uid: 'eu',
      queueId: 'q1',
      released: released,
      ownerId: owner,
      docQueueId: queue,
    );

    test('só libera slug ativo meu da mesma fila', () {
      expect(can(), isTrue);
      expect(can(exists: false), isFalse);
      expect(can(released: true), isFalse);
      expect(can(owner: 'outro'), isFalse);
      expect(can(queue: 'q2'), isFalse);
    });
  });
}
