import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/operator.dart';
import '../models/queue.dart';

enum SectionStatus { loading, data, error }

class Section<T> {
  const Section(this.status, [this.value]);

  final SectionStatus status;
  final T? value;

  bool get isLoading => status == SectionStatus.loading;
  bool get hasError => status == SectionStatus.error;
}

class HomeController extends ChangeNotifier {
  HomeController({
    required this.ownedSource,
    required this.operatingSource,
    required this.requestsSource,
  }) {
    _subscribe();
  }

  final Stream<List<Queue>> Function() ownedSource;
  final Stream<List<QueueOperator>> Function() operatingSource;
  final Stream<List<OperatorRequest>> Function() requestsSource;

  final List<StreamSubscription<Object?>> _subs = [];
  bool _disposed = false;

  Section<List<Queue>> owned = const Section(SectionStatus.loading);
  Section<List<QueueOperator>> operating = const Section(SectionStatus.loading);
  Section<List<OperatorRequest>> requests = const Section(
    SectionStatus.loading,
  );

  bool get isLoading => owned.isLoading;
  bool get hasError =>
      owned.hasError || operating.hasError || requests.hasError;

  List<Queue> get ownedQueues => owned.value ?? const [];
  List<QueueOperator> get operatingQueues => operating.value ?? const [];
  List<OperatorRequest> get pendingRequests => requests.value ?? const [];

  void _subscribe() {
    _subs
      ..add(
        ownedSource().listen(
          (v) => _set(() => owned = Section(SectionStatus.data, v)),
          onError: (Object _) =>
              _set(() => owned = const Section(SectionStatus.error)),
        ),
      )
      ..add(
        operatingSource().listen(
          (v) => _set(() => operating = Section(SectionStatus.data, v)),
          onError: (Object _) =>
              _set(() => operating = const Section(SectionStatus.error)),
        ),
      )
      ..add(
        requestsSource().listen(
          (v) => _set(() => requests = Section(SectionStatus.data, v)),
          onError: (Object _) =>
              _set(() => requests = const Section(SectionStatus.error)),
        ),
      );
  }

  void _set(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  void retry() {
    _cancel();
    owned = const Section(SectionStatus.loading);
    operating = const Section(SectionStatus.loading);
    requests = const Section(SectionStatus.loading);
    notifyListeners();
    _subscribe();
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    super.dispose();
  }
}
