import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/push_service.dart';

void main() {
  test('pushLanguageCode keeps pt/en/es and falls back to pt', () {
    expect(pushLanguageCode('en'), 'en');
    expect(pushLanguageCode('ES'), 'es');
    expect(pushLanguageCode('pt'), 'pt');
    expect(pushLanguageCode('fr'), 'pt');
    expect(pushLanguageCode(''), 'pt');
  });
}
