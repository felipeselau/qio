import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/action_errors.dart';

FirebaseException fe(String code) =>
    FirebaseException(plugin: 'test', code: code);

void main() {
  test('maps connectivity failures to offline', () {
    expect(describeActionError(fe('unavailable')), ActionError.offline);
    expect(
      describeActionError(fe('network-request-failed')),
      ActionError.offline,
    );
    expect(describeActionError(fe('network-error')), ActionError.offline);
    expect(describeActionError(fe('disconnected')), ActionError.offline);
    expect(describeActionError(fe('deadline-exceeded')), ActionError.offline);
  });

  test('maps unauthenticated to accessEnded', () {
    expect(describeActionError(fe('unauthenticated')), ActionError.accessEnded);
  });

  test('maps permission-denied to accessEnded', () {
    expect(
      describeActionError(fe('permission-denied')),
      ActionError.accessEnded,
    );
  });

  test('maps concurrency failures to conflict', () {
    expect(describeActionError(fe('aborted')), ActionError.conflict);
    expect(
      describeActionError(fe('failed-precondition')),
      ActionError.conflict,
    );
  });

  test('maps everything else to generic', () {
    expect(describeActionError(fe('internal')), ActionError.generic);
    expect(describeActionError(Exception('x')), ActionError.generic);
  });
}
