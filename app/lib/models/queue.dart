import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import 'alerts_config.dart';
import 'expiry_config.dart';
import 'queue_schedule.dart';
import 'queue_slot.dart';

enum QueueStatus { open, paused, closed }

extension QueueStatusX on QueueStatus {
  String label(AppLocalizations l10n) {
    switch (this) {
      case QueueStatus.open:
        return l10n.statusOpen;
      case QueueStatus.paused:
        return l10n.statusPaused;
      case QueueStatus.closed:
        return l10n.statusClosed;
    }
  }

  String get value {
    switch (this) {
      case QueueStatus.open:
        return 'open';
      case QueueStatus.paused:
        return 'paused';
      case QueueStatus.closed:
        return 'closed';
    }
  }

  static QueueStatus fromValue(String? v) {
    switch (v) {
      case 'paused':
        return QueueStatus.paused;
      case 'closed':
        return QueueStatus.closed;
      default:
        return QueueStatus.open;
    }
  }
}

class Queue {
  Queue({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.status = QueueStatus.open,
    this.avgServiceMin = 10,
    required this.createdAt,
    this.operatorInviteCode,
    this.operatorInviteExpiresAt,
    this.maxWaiting = 0,
    this.statusMessage,
    this.resumeAt,
    this.schedule,
    this.brandColor,
    this.logoUrl,
    this.slug,
    this.posterTitle,
    this.groupId,
    this.alerts,
    this.mode = QueueMode.queue,
    this.slots = const [],
    this.anonymizePhone = false,
    this.retentionDays,
    this.expiry,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final QueueStatus status;
  final int avgServiceMin;
  final DateTime createdAt;
  final String? operatorInviteCode;
  final DateTime? operatorInviteExpiresAt;
  final int maxWaiting;
  final String? statusMessage;
  final DateTime? resumeAt;
  final QueueSchedule? schedule;
  final String? brandColor;
  final String? logoUrl;
  final String? slug;
  final String? posterTitle;
  final String? groupId;
  final AlertsConfig? alerts;
  final QueueMode mode;
  final List<QueueSlot> slots;
  final bool anonymizePhone;
  final int? retentionDays;
  final ExpiryConfig? expiry;

  bool get hasLimit => maxWaiting > 0;

  bool get isScheduled => mode == QueueMode.schedule;

  factory Queue.fromDoc(String id, Map<String, dynamic> data) {
    return Queue(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      status: QueueStatusX.fromValue(data['status'] as String?),
      avgServiceMin: (data['avgServiceMin'] as num?)?.toInt() ?? 10,
      createdAt: _parseCreatedAt(data['createdAt']),
      operatorInviteCode: data['operatorInviteCode'] as String?,
      operatorInviteExpiresAt: data['operatorInviteExpiresAt'] is Timestamp
          ? (data['operatorInviteExpiresAt'] as Timestamp).toDate()
          : null,
      maxWaiting: (data['maxWaiting'] as num?)?.toInt() ?? 0,
      statusMessage: data['statusMessage'] as String?,
      resumeAt: data['resumeAt'] is Timestamp
          ? (data['resumeAt'] as Timestamp).toDate()
          : null,
      schedule: QueueSchedule.fromMap(data['schedule']),
      brandColor: data['brandColor'] as String?,
      logoUrl: data['logoUrl'] as String?,
      slug: data['slug'] as String?,
      posterTitle: data['posterTitle'] as String?,
      groupId: data['groupId'] as String?,
      alerts: AlertsConfig.fromMap(data['alerts']),
      mode: QueueModeX.fromValue(data['mode'] as String?),
      slots: QueueSlot.listFromRaw(data['slots']),
      anonymizePhone: data['anonymizePhone'] == true,
      retentionDays: (data['retentionDays'] as num?)?.toInt(),
      expiry: ExpiryConfig.fromMap(data['expiry']),
    );
  }

  static DateTime _parseCreatedAt(dynamic v) {
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'status': status.value,
    'avgServiceMin': avgServiceMin,
    'createdAt': createdAt.toIso8601String(),
  };
}
