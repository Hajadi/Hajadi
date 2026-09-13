import 'dart:async';

import '../models/review.dart';
import '../models/worker_profile.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// A single worker profile with its live review feed.
class WorkerDetailViewModel extends BaseViewModel {
  WorkerDetailViewModel(this._services, this.workerId) {
    _workerSubscription =
        _services.data.watchWorker(workerId).listen((WorkerProfile? profile) {
      _worker = profile;
      _loading = false;
      safeNotify();
    }, onError: (Object error) {
      setError('errorGeneric');
      _loading = false;
    });
    _reviewSubscription = _services.data
        .watchReviewsForWorker(workerId)
        .listen((List<Review> reviews) {
      _reviews = reviews;
      safeNotify();
    });
  }

  final Services _services;
  final String workerId;

  StreamSubscription<WorkerProfile?>? _workerSubscription;
  StreamSubscription<List<Review>>? _reviewSubscription;

  WorkerProfile? _worker;
  List<Review> _reviews = const <Review>[];
  bool _loading = true;

  WorkerProfile? get worker => _worker;
  List<Review> get reviews => _reviews;
  bool get loading => _loading;

  @override
  void dispose() {
    _workerSubscription?.cancel();
    _reviewSubscription?.cancel();
    super.dispose();
  }
}
