import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'route_master_models.dart';

class RouteMasterService {
  final ApiClient _api;

  RouteMasterService(this._api);

  Future<PaginatedList<RouteMaster>> getPaged(int pageNumber) async {
    final json = await _api.get('/routemaster', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, RouteMaster.fromJson);
  }

  Future<RouteMaster> getById(int id) async {
    final json = await _api.get('/routemaster/$id');
    return RouteMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<RouteMaster> create(RouteMaster route) async {
    final json = await _api.post('/routemaster', body: route.toSaveJson());
    return RouteMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<RouteMaster> update(int id, RouteMaster route) async {
    final json = await _api.put('/routemaster/$id', body: route.toSaveJson());
    return RouteMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/routemaster/$id/${active ? 'activate' : 'deactivate'}');
  }
}
