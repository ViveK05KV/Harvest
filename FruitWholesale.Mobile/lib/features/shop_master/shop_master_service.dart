import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'shop_master_models.dart';

class ShopMasterService {
  final ApiClient _api;

  ShopMasterService(this._api);

  Future<PaginatedList<ShopMaster>> getPaged(int pageNumber, {int? routeId, int pageSize = 20}) async {
    final json = await _api.get('/shopmaster', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (routeId != null) 'routeId': routeId,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, ShopMaster.fromJson);
  }

  Future<List<ShopMaster>> getAllActive() async {
    final json = await _api.get('/shopmaster/active') as List;
    return json.map((e) => ShopMaster.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopMaster> getById(int id) async {
    final json = await _api.get('/shopmaster/$id');
    return ShopMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<ShopMaster> create(ShopMaster shop) async {
    final json = await _api.post('/shopmaster', body: shop.toCreateJson());
    return ShopMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<ShopMaster> update(int id, ShopMaster shop) async {
    final json = await _api.put('/shopmaster/$id', body: shop.toUpdateJson());
    return ShopMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/shopmaster/$id/${active ? 'activate' : 'deactivate'}');
  }

  Future<void> applyBalanceAdjustment(int id, {required double amount, required bool isIncrease, required String narration}) async {
    await _api.post('/shopmaster/$id/balance-adjustment', body: {
      'amount': amount,
      'isIncrease': isIncrease,
      'narration': narration,
    });
  }
}
