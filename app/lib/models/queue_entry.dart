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
    );
  }

  Map<String, dynamic> toMap() => {
    'ticket': ticket,
    'name': name,
    'phone': phone,
    'uid': uid,
    'fcmToken': fcmToken,
    'status': status.value,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
    if (calledAt != null) 'calledAt': calledAt!.millisecondsSinceEpoch,
  };
}
