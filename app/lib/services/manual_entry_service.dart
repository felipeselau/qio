import 'package:cloud_functions/cloud_functions.dart';

import '../l10n/app_localizations.dart';

enum ManualEntryError {
  queueFull,
  slotFull,
  slotRequired,
  slotInvalid,
  slotPassed,
  notOpen,
  invalidInput,
  accessEnded,
  offline,
  generic,
}

class ManualEntryException implements Exception {
  const ManualEntryException(this.error);

  final ManualEntryError error;
}

ManualEntryError manualEntryErrorFrom(String code, Object? reason) {
  switch (reason) {
    case 'queue-full':
      return ManualEntryError.queueFull;
    case 'slot-full':
      return ManualEntryError.slotFull;
    case 'slot-required':
      return ManualEntryError.slotRequired;
    case 'slot-invalid':
      return ManualEntryError.slotInvalid;
    case 'slot-passed':
      return ManualEntryError.slotPassed;
  }
  switch (code) {
    case 'failed-precondition':
      return ManualEntryError.notOpen;
    case 'invalid-argument':
      return ManualEntryError.invalidInput;
    case 'permission-denied':
    case 'unauthenticated':
      return ManualEntryError.accessEnded;
    case 'unavailable':
    case 'deadline-exceeded':
      return ManualEntryError.offline;
  }
  return ManualEntryError.generic;
}

extension ManualEntryErrorMessage on ManualEntryError {
  String message(AppLocalizations l10n) => switch (this) {
    ManualEntryError.queueFull => l10n.manualAddQueueFull,
    ManualEntryError.slotFull => l10n.manualAddSlotFull,
    ManualEntryError.slotRequired ||
    ManualEntryError.slotInvalid => l10n.manualAddSlotRequired,
    ManualEntryError.slotPassed => l10n.manualAddSlotPassed,
    ManualEntryError.notOpen => l10n.manualAddNotOpen,
    ManualEntryError.invalidInput => l10n.manualAddInvalid,
    ManualEntryError.accessEnded => l10n.actionErrorAccessEnded,
    ManualEntryError.offline => l10n.actionErrorOffline,
    ManualEntryError.generic => l10n.genericActionError,
  };
}

class ManualEntryService {
  ManualEntryService._();
  static final ManualEntryService instance = ManualEntryService._();

  ManualEntryService.forTesting();

  Future<int> add({
    required String queueId,
    required String name,
    String? phone,
    String? slotId,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('addManualEntry');
      final result = await callable.call<Map<Object?, Object?>>({
        'queueId': queueId,
        'name': name,
        'phone': phone ?? '',
        'slotId': ?slotId,
      });
      return (result.data['ticket'] as num?)?.toInt() ?? 0;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] : null;
      throw ManualEntryException(manualEntryErrorFrom(e.code, reason));
    }
  }
}
