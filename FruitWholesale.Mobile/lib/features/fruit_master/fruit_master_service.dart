import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'fruit_master_models.dart';

class FruitMasterService {
  final ApiClient _api;

  FruitMasterService(this._api);

  Future<PaginatedList<FruitMaster>> getPaged(int pageNumber) async {
    final json = await _api.get('/fruitmaster', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, FruitMaster.fromJson);
  }

  Future<FruitMaster> getById(int id) async {
    final json = await _api.get('/fruitmaster/$id');
    return FruitMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<FruitMaster> create(FruitMaster fruit) async {
    final json = await _api.post('/fruitmaster', body: fruit.toSaveJson());
    return FruitMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<FruitMaster> update(int id, FruitMaster fruit) async {
    final json = await _api.put('/fruitmaster/$id', body: fruit.toSaveJson());
    return FruitMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/fruitmaster/$id/${active ? 'activate' : 'deactivate'}');
  }
}
