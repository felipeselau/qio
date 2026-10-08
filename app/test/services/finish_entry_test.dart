import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/services/finish_entry.dart';

void main() {
  Map<String, Object?> entry(String status) => {
    'ticket': 4,
    'name': 'Ana',
    'status': status,
  };

  test('null snapshot means the entry is gone', () {
    expect(checkFinishable(null, EntryStatus.served), FinishCheck.gone);
  });

  test('called entry can proceed', () {
    expect(
      checkFinishable(entry('called'), EntryStatus.served),
      FinishCheck.proceed,
    );
  });

  test('entry already in the target status is idempotent', () {
    expect(
      checkFinishable(entry('served'), EntryStatus.served),
      FinishCheck.proceed,
    );
  });

  test('other statuses are a conflict', () {
    expect(
      checkFinishable(entry('waiting'), EntryStatus.served),
      FinishCheck.changed,
    );
    expect(
      checkFinishable(entry('no_show'), EntryStatus.served),
      FinishCheck.changed,
    );
    expect(
      checkFinishable(entry('left'), EntryStatus.noShow),
      FinishCheck.changed,
    );
  });

  test('finishedEntryData sets status and operator, keeping the rest', () {
    final data = finishedEntryData(entry('called'), EntryStatus.noShow, 'u1')!;
    expect(data['status'], 'no_show');
    expect(data['operatorId'], 'u1');
    expect(data['name'], 'Ana');
  });

  test('finishedEntryData refuses missing or conflicting entries', () {
    expect(finishedEntryData(null, EntryStatus.served, 'u1'), isNull);
    expect(
      finishedEntryData(entry('waiting'), EntryStatus.served, 'u1'),
      isNull,
    );
  });
}
