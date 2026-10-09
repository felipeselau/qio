import 'package:cloud_functions/cloud_functions.dart';

import 'delete_service.dart';

const _timeout = Duration(minutes: 5);

String? normalizeCustomerPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.length == 10 || digits.length == 11 ? digits : null;
}

String maskCustomerPhone(String digits) {
  final split = digits.length == 11 ? 5 : 4;
  return '(${digits.substring(0, 2)}) '
      '${digits.substring(2, 2 + split)}-${digits.substring(2 + split)}';
}

List<String> customerPhoneForms(String digits) => [
  maskCustomerPhone(digits),
  digits,
];

enum CustomerEraseMode { delete, anonymize }

class CustomerQueueData {
  const CustomerQueueData({
    required this.queueId,
    required this.queueName,
    required this.history,
    required this.feedback,
    required this.entries,
    this.firstAt,
    this.lastAt,
  });

  final String queueId;
  final String queueName;
  final int history;
  final int feedback;
  final int entries;
  final DateTime? firstAt;
  final DateTime? lastAt;

  int get total => history + feedback + entries;

  factory CustomerQueueData.fromMap(Map<dynamic, dynamic> map) {
    return CustomerQueueData(
      queueId: map['queueId'] as String? ?? '',
      queueName: map['queueName'] as String? ?? '',
      history: _int(map['history']),
      feedback: _int(map['feedback']),
      entries: _int(map['entries']),
      firstAt: _date(map['firstAt']),
      lastAt: _date(map['lastAt']),
    );
  }
}

class CustomerSummary {
  const CustomerSummary({required this.queues, this.complete = true});

  final List<CustomerQueueData> queues;
  final bool complete;

  int get history => queues.fold(0, (a, q) => a + q.history);
  int get feedback => queues.fold(0, (a, q) => a + q.feedback);
  int get entries => queues.fold(0, (a, q) => a + q.entries);
  int get total => history + feedback + entries;
  bool get isEmpty => total == 0;

  factory CustomerSummary.fromMap(Map<String, dynamic> map) {
    final raw = map['queues'];
    return CustomerSummary(
      queues: raw is List
          ? [
              for (final q in raw)
                if (q is Map) CustomerQueueData.fromMap(q),
            ]
          : const [],
      complete: map['complete'] != false,
    );
  }
}

class CustomerExport {
  const CustomerExport({required this.csv, required this.truncated});

  final String csv;
  final bool truncated;
}

int _int(Object? v) => v is num ? v.toInt() : 0;

DateTime? _date(Object? v) =>
    v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

class DataSubjectService {
  DataSubjectService({this._invoker});

  static final DataSubjectService instance = DataSubjectService();

  final CallableInvoker? _invoker;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _invoker;
    try {
      if (custom != null) return await custom(name, data);
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(name, options: HttpsCallableOptions(timeout: _timeout));
      final result = await callable.call<Object?>(data);
      final raw = result.data;
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw mapCallableError(e);
    }
  }

  Future<CustomerSummary> find(String phoneDigits) async {
    final res = await _call('findCustomerData', {'phone': phoneDigits});
    return CustomerSummary.fromMap(res);
  }

  Future<CustomerExport> export(String phoneDigits) async {
    final res = await _call('exportCustomerData', {'phone': phoneDigits});
    return CustomerExport(
      csv: res['csv'] as String? ?? '',
      truncated: res['truncated'] == true,
    );
  }

  Future<CustomerSummary> erase(
    String phoneDigits,
    CustomerEraseMode mode,
  ) async {
    final res = await _call('eraseCustomerData', {
      'phone': phoneDigits,
      'mode': mode.name,
    });
    return CustomerSummary.fromMap(res);
  }
}
