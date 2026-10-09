import 'dart:async';

import 'package:qio_app/models/alerts_config.dart';
import 'package:qio_app/models/expiry_config.dart';
import 'package:qio_app/models/history_entry.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/models/queue_schedule.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/services/group_service.dart';
import 'package:qio_app/services/manual_entry_service.dart';
import 'package:qio_app/services/operator_service.dart';
import 'package:qio_app/services/queue_service.dart';

Queue fakeQueue(
  String id, {
  String? name,
  QueueStatus status = QueueStatus.open,
  int maxWaiting = 0,
  String? statusMessage,
}) => Queue(
  id: id,
  ownerId: 'uid-1',
  name: name ?? 'Fila $id',
  status: status,
  createdAt: DateTime(2025, 5, 20),
  maxWaiting: maxWaiting,
  statusMessage: statusMessage,
);

QueueEntry fakeEntry(
  String id,
  int ticket, {
  String? name,
  EntryStatus status = EntryStatus.waiting,
  String? operatorId,
  bool manual = false,
  String? phone,
}) => QueueEntry(
  id: id,
  ticket: ticket,
  name: name ?? 'Cliente $ticket',
  uid: 'c-$id',
  status: status,
  joinedAt: DateTime(2025, 5, 20, 10, ticket),
  calledAt: status == EntryStatus.called ? DateTime(2025, 5, 20, 11) : null,
  operatorId: operatorId,
  manual: manual,
  phone: phone,
);

class FakeManualEntryService implements ManualEntryService {
  FakeManualEntryService({this.error, this.ticket = 7});

  Object? error;
  int ticket;
  Future<void>? gate;
  final List<Map<String, String?>> calls = [];

  @override
  Future<int> add({
    required String queueId,
    required String name,
    String? phone,
    String? slotId,
  }) async {
    calls.add({
      'queueId': queueId,
      'name': name,
      'phone': phone,
      'slotId': slotId,
    });
    await gate;
    if (error != null) throw error!;
    return ticket;
  }
}

class FakeQueueService implements QueueService {
  FakeQueueService({
    this.ownerQueues = const [],
    Map<String, Queue>? queues,
    Map<String, int>? waitingCounts,
    Map<String, List<QueueEntry>>? entries,
    this.history = const [],
    this.feedback = const [],
    this.uid = 'uid-1',
    this.callNextResult,
  }) : queues = queues ?? {},
       waitingCounts = waitingCounts ?? {},
       entries = entries ?? {};

  List<Queue> ownerQueues;
  Map<String, Queue> queues;
  Map<String, int> waitingCounts;
  Map<String, List<QueueEntry>> entries;
  List<HistoryEntry> history;
  List<QueueFeedback> feedback;
  String uid;
  QueueEntry? callNextResult;
  Object? ownerQueuesError;
  Object? historyError;
  Object? callNextError;
  Object? finishError;
  Object? statusError;
  Object? slugError;
  Future<void>? finishGate;
  final List<String> calls = [];
  final Map<String, int> waitingListens = {};

  @override
  String get currentUid => uid;

  @override
  Stream<List<Queue>> watchOwnerQueues() async* {
    if (ownerQueuesError != null) throw ownerQueuesError!;
    yield ownerQueues;
    yield* _ownerCtl.stream;
  }

  final _ownerCtl = StreamController<List<Queue>>.broadcast();

  void emitOwnerQueues(List<Queue> queues) {
    ownerQueues = queues;
    _ownerCtl.add(queues);
  }

  @override
  Stream<Queue> watchQueue(String queueId) {
    final q = queues[queueId];
    return q == null ? const Stream.empty() : Stream.value(q);
  }

  Stream<bool>? existsOverride;

  @override
  Stream<bool> watchQueueExists(String queueId) =>
      existsOverride ?? Stream.value(queues.containsKey(queueId));

  @override
  Stream<int> watchWaitingCount(String queueId) {
    late final StreamController<int> controller;
    controller = StreamController<int>(
      onListen: () {
        waitingListens[queueId] = (waitingListens[queueId] ?? 0) + 1;
        controller.add(waitingCounts[queueId] ?? 0);
      },
      onCancel: () {
        waitingListens[queueId] = (waitingListens[queueId] ?? 1) - 1;
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<QueueEntry>> watchEntries(String queueId) =>
      Stream.value(entries[queueId] ?? const []);

  @override
  Stream<List<HistoryEntry>> watchHistory(String queueId, {int limit = 200}) =>
      historyError != null
      ? Stream.error(historyError!)
      : Stream.value(history);

  @override
  Future<List<HistoryEntry>> fetchHistory(
    String queueId, {
    int limit = QueueService.historyFetchLimit,
  }) async => history;

  @override
  Stream<List<QueueFeedback>> watchFeedback(String queueId) =>
      Stream.value(feedback);

  @override
  Future<List<QueueFeedback>> fetchFeedback(String queueId) async => feedback;

  @override
  Future<void> setSlug(
    String queueId, {
    String? currentSlug,
    String? newSlug,
  }) async {
    calls.add('setSlug:$queueId:${currentSlug ?? '-'}:${newSlug ?? '-'}');
    if (slugError != null) throw slugError!;
  }

  @override
  Future<void> updatePosterTitle(String queueId, String? title) async {
    calls.add('posterTitle:$queueId:${title ?? '-'}');
  }

  @override
  String queueJoinUrl(String queueId) => 'https://qio.web.app/q/$queueId';

  @override
  Future<void> ensureMirror(String queueId) async {
    calls.add('ensureMirror:$queueId');
  }

  @override
  Future<QueueEntry?> callNext(String queueId) async {
    calls.add('callNext:$queueId');
    if (callNextError != null) throw callNextError!;
    return callNextResult;
  }

  @override
  Future<void> markServed(
    String queueId,
    QueueEntry entry, {
    bool? anonymizePhone,
  }) async {
    if (finishGate != null) await finishGate;
    if (finishError != null) throw finishError!;
    calls.add('served:${entry.id}');
  }

  @override
  Future<void> markNoShow(
    String queueId,
    QueueEntry entry, {
    bool? anonymizePhone,
  }) async {
    if (finishGate != null) await finishGate;
    if (finishError != null) throw finishError!;
    calls.add('noShow:${entry.id}');
  }

  @override
  Future<void> updateQueueStatus(
    String queueId,
    QueueStatus status, {
    String? message,
    DateTime? resumeAt,
  }) async {
    calls.add('status:$queueId:${status.value}');
    if (statusError != null) throw statusError!;
    lastStatusMessage = message;
  }

  String? lastStatusMessage;
  QueueMode? savedMode;
  List<QueueSlot>? savedSlots;
  Object? createError;
  QueueMode? createdMode;
  List<QueueSlot>? createdSlots;

  @override
  Future<void> updateModeAndSlots(
    String queueId,
    QueueMode mode,
    List<QueueSlot> slots,
  ) async {
    calls.add('modeSlots:$queueId:${mode.value}:${slots.length}');
    savedMode = mode;
    savedSlots = slots;
  }

  @override
  Future<Queue> createQueue({
    required String name,
    String? description,
    int? avgServiceMin,
    int maxWaiting = 0,
    String? groupId,
    QueueMode mode = QueueMode.queue,
    List<QueueSlot> slots = const [],
    QueueSchedule? schedule,
    String? brandColor,
    AlertsConfig? alerts,
  }) async {
    final error = createError;
    if (error != null) throw error;
    calls.add('create:$name:${mode.value}:${slots.length}');
    createdMode = mode;
    createdSlots = slots;
    createdArgs = (
      name: name,
      description: description,
      avgServiceMin: avgServiceMin,
      maxWaiting: maxWaiting,
      groupId: groupId,
    );
    if (createResult != null) return createResult!;
    throw Exception('stop before navigation');
  }

  Queue? createResult;
  ({
    String name,
    String? description,
    int? avgServiceMin,
    int maxWaiting,
    String? groupId,
  })?
  createdArgs;
  Object? updateInfoError;
  Object? duplicateError;
  Queue? duplicateResult;
  String? duplicatedName;

  @override
  Future<void> updateQueueInfo(
    String queueId, {
    required String name,
    String? description,
    required int avgServiceMin,
  }) async {
    calls.add('info:$queueId:$name:${description ?? ''}:$avgServiceMin');
    if (updateInfoError != null) throw updateInfoError!;
  }

  @override
  Future<void> updateAnonymizePhone(String queueId, bool value) async {
    calls.add('anonymize:$queueId:$value');
  }

  @override
  Future<void> updateExpiry(String queueId, ExpiryConfig config) async {
    calls.add(
      'expiry:$queueId:${config.enabled}:${config.hours}:${config.clearOnClose}:${config.resetTicketDaily}',
    );
  }

  @override
  Future<Queue> duplicateQueue(String queueId, {required String name}) async {
    calls.add('duplicate:$queueId:$name');
    duplicatedName = name;
    if (duplicateError != null) throw duplicateError!;
    final copy = duplicateResult ?? fakeQueue('copy', name: name);
    queues[copy.id] = copy;
    return copy;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGroupService implements GroupService {
  FakeGroupService({this.groups = const []});

  List<QueueGroup> groups;
  final List<String> calls = [];

  @override
  Stream<List<QueueGroup>> watchGroups() => Stream.value(groups);

  @override
  Future<List<QueueGroup>> fetchGroups() async => groups;

  @override
  Future<void> setQueueGroup(String queueId, String? groupId) async {
    calls.add('setQueueGroup:$queueId:$groupId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOperatorService implements OperatorService {
  FakeOperatorService({this.operating = const [], this.requests = const []});

  List<QueueOperator> operating;
  List<OperatorRequest> requests;
  final List<String> calls = [];

  @override
  Stream<List<QueueOperator>> watchMyOperatorQueues() =>
      Stream.value(operating);

  @override
  Stream<List<OperatorRequest>> watchMyRequests() => Stream.value(requests);

  final StreamController<bool> access = StreamController<bool>.broadcast();

  @override
  Stream<bool> watchIsOperator(String queueId) => access.stream;

  @override
  Future<void> cancelMyRequest(String queueId) async {
    calls.add('cancel:$queueId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HistoryEntry fakeHistory(
  String id,
  int ticket, {
  String? name,
  String result = 'served',
  required DateTime finishedAt,
  int waitMin = 5,
  int serviceMin = 3,
}) {
  final calledAt = finishedAt.subtract(Duration(minutes: serviceMin));
  return HistoryEntry(
    id: id,
    ticket: ticket,
    name: name ?? 'Cliente $ticket',
    result: result,
    joinedAt: calledAt.subtract(Duration(minutes: waitMin)),
    calledAt: calledAt,
    finishedAt: finishedAt,
  );
}
