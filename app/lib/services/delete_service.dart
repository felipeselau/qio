import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

typedef CallableInvoker =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    );

const _deleteTimeout = Duration(minutes: 9);

bool deleteConfirmationMatches(String input, {String? email}) {
  final value = input.trim().toLowerCase();
  if (value.isEmpty) return false;
  if (value == 'excluir' || value == 'delete' || value == 'eliminar') {
    return true;
  }
  final mail = email?.trim().toLowerCase() ?? '';
  return mail.isNotEmpty && value == mail;
}

FirebaseException mapCallableError(FirebaseFunctionsException e) {
  final details = e.details;
  final reason = details is Map ? details['reason'] : null;
  final code = switch ((e.code, reason)) {
    ('aborted', 'partial') => 'delete-incomplete',
    ('failed-precondition', 'recent-login') => 'recent-login',
    _ => e.code,
  };
  return FirebaseException(
    plugin: 'cloud_functions',
    code: code,
    message: e.message,
  );
}

class DeleteService {
  DeleteService({this._invoker});

  static final DeleteService instance = DeleteService();

  final CallableInvoker? _invoker;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _invoker;
    try {
      if (custom != null) return await custom(name, data);
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: _deleteTimeout),
          );
      final result = await callable.call<Object?>(data);
      final raw = result.data;
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw mapCallableError(e);
    }
  }

  Future<void> deleteQueue(String queueId) async {
    await _call('deleteQueue', {'queueId': queueId});
  }

  Future<void> deleteAccount() async {
    await _call('deleteAccount', const {});
  }
}
