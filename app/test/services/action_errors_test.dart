import 'package:cloud_firestore/cloud_firestore.dart';
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
