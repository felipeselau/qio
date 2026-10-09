enum EntryStatus { waiting, called, served, noShow, left }

extension EntryStatusX on EntryStatus {
  String get value {
    switch (this) {
      case EntryStatus.waiting:
        return 'waiting';
      case EntryStatus.called:
        return 'called';
      case EntryStatus.served:
        return 'served';
      case EntryStatus.noShow:
        return 'no_show';
      case EntryStatus.left:
        return 'left';
    }
  }

  static EntryStatus fromValue(String? v) {
    switch (v) {
      case 'called':
        return EntryStatus.called;
      case 'served':
        return EntryStatus.served;
      case 'no_show':
        return EntryStatus.noShow;
      case 'left':
        return EntryStatus.left;
      default:
        return EntryStatus.waiting;
    }
  }
}

class QueueEntry {
  QueueEntry({
    required this.id,
    required this.ticket,
    required this.name,
    this.phone,
    required this.uid,
    this.fcmToken,
    required this.status,
    required this.joinedAt,
    this.calledAt,
    this.operatorId,
    this.order,
    this.recalls = 0,
    this.skips = 0,
    this.recalledAt,
    this.slotId,
    this.slotStart,
    this.manual = false,
  });

  final String id;
  final int ticket;
  final String name;
  final String? phone;
  final String uid;
  final String? fcmToken;
  final EntryStatus status;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final String? operatorId;
  final int? order;
  final int recalls;
  final int skips;
  final DateTime? recalledAt;
  final String? slotId;
  final DateTime? slotStart;
  final bool manual;

  int get sortOrder => order ?? joinedAt.millisecondsSinceEpoch;

  static int compareInQueue(QueueEntry a, QueueEntry b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.ticket.compareTo(b.ticket);
  }

  factory QueueEntry.fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return QueueEntry(
      id: id,
      ticket: (data['ticket'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      uid: data['uid'] as String? ?? '',
      fcmToken: data['fcmToken'] as String?,
      status: EntryStatusX.fromValue(data['status'] as String?),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['joinedAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      calledAt: data['calledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['calledAt'] as num).toInt(),
            )
          : null,
      operatorId: data['operatorId'] as String?,
      order: (data['order'] as num?)?.toInt(),
      recalls: (data['recalls'] as num?)?.toInt() ?? 0,
      skips: (data['skips'] as num?)?.toInt() ?? 0,
      recalledAt: data['recalledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['recalledAt'] as num).toInt(),
            )
          : null,
      slotId: data['slotId'] as String?,
      slotStart: data['slotStart'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['slotStart'] as num).toInt(),
            )
          : null,
      manual: data['manual'] == true,
    );
  }

  bool isHandledBy(String uid, {required bool isOwner}) =>
      operatorId == uid || (operatorId == null && isOwner);

  Map<String, dynamic> toMap() => {
    'ticket': ticket,
    'name': name,
    'phone': phone,
    if (!manual) 'uid': uid,
    if (manual) 'manual': true,
    'fcmToken': fcmToken,
    'status': status.value,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
    if (calledAt != null) 'calledAt': calledAt!.millisecondsSinceEpoch,
    if (operatorId != null) 'operatorId': operatorId,
  };
}
