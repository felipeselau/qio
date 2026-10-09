import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/history_privacy.dart';

void main() {
  test('uses the known value without reading', () async {
    var reads = 0;
    Future<bool> read() async {
      reads++;
      return false;
    }

    expect(await resolveAnonymizePhone(known: true, read: read), isTrue);
    expect(await resolveAnonymizePhone(known: false, read: read), isFalse);
    expect(reads, 0);
  });

  test('reads when the value is unknown', () async {
    expect(await resolveAnonymizePhone(read: () async => true), isTrue);
    expect(await resolveAnonymizePhone(read: () async => false), isFalse);
  });

  test('fails closed when the read throws', () async {
    expect(
      await resolveAnonymizePhone(read: () async => throw Exception('offline')),
      isTrue,
    );
  });
}
