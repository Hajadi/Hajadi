import '../models/worker_profile.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

class FavoritesViewModel extends BaseViewModel {
  FavoritesViewModel(this._services);

  final Services _services;

  List<WorkerProfile> _workers = const <WorkerProfile>[];

  List<WorkerProfile> get workers => _workers;

  Future<void> load(List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) {
      _workers = const <WorkerProfile>[];
      safeNotify();
      return;
    }
    await guard(() async {
      _workers = await _services.data.fetchWorkersByIds(favoriteIds);
      return true;
    });
    safeNotify();
  }
}
