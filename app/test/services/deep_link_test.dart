import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/deep_link.dart';

void main() {
  group('queueIdFromLink', () {
    test('extracts the id from the join url', () {
      expect(
        queueIdFromLink(Uri.parse('https://qio.web.app/q/abc123')),
        'abc123',
      );
      expect(queueIdFromLink(Uri.parse('https://qio.web.app/q/abc/')), 'abc');
      expect(
        queueIdFromLink(Uri.parse('https://qio.web.app/q/a_b-C?x=1#frag')),
        'a_b-C',
      );
    });

    test('rejects other hosts, schemes and paths', () {
      for (final url in [
        'http://qio.web.app/q/abc',
        'https://evil.example/q/abc',
        'https://qio.web.app/c/abc',
        'https://qio.web.app/q',
        'https://qio.web.app/q/abc/extra',
        'https://qio.web.app/',
        'https://qio.web.app/q/a b',
        'https://qio.web.app/q/..%2Fx',
      ]) {
        expect(queueIdFromLink(Uri.parse(url)), isNull, reason: url);
      }
    });
  });

  test('client url uses /c/ so the app does not claim it again', () {
    final url = clientUrlForQueue('abc');
    expect(url.toString(), 'https://qio.web.app/c/abc');
    expect(queueIdFromLink(url), isNull);
  });
}
