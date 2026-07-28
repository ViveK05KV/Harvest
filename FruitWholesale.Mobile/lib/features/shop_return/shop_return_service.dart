import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'shop_return_models.dart';

class ShopReturnService {
  final ApiClient _api;

  ShopReturnService(this._api);

  Future<PaginatedList<ShopReturnListItem>> getPaged({int pageNumber = 1, int pageSize = 20}) async {
    final json = await _api.get('/shopreturn', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, ShopReturnListItem.fromJson);
  }

  Future<ShopReturnDetail> getById(int id) async {
    final json = await _api.get('/shopreturn/$id');
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<String> getNextReferenceNo() async {
    final json = await _api.get('/shopreturn/next-reference-no');
    return json as String;
  }

  Future<ShopReturnDetail> create(ShopReturnDetail shopReturn) async {
    final json = await _api.post('/shopreturn', body: shopReturn.toSaveJson());
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<ShopReturnDetail> update(int id, ShopReturnDetail shopReturn) async {
    final json = await _api.put('/shopreturn/$id', body: shopReturn.toSaveJson());
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }
}
