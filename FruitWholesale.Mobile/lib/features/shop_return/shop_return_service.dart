import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'shop_return_models.dart';

class ShopReturnService {
  final ApiClient _api;

  ShopReturnService(this._api);

  Future<PaginatedList<ShopReturnListItem>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    int? shopId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/shopreturn', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      if (shopId != null) 'shopId': shopId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, ShopReturnListItem.fromJson);
  }

  Future<ShopReturnDetail> getById(int id) async {
    final json = await _api.get('/shopreturn/$id');
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<String> getNextReferenceNo() => _api.getText('/shopreturn/next-reference-no');

  Future<ShopReturnDetail> create(ShopReturnDetail shopReturn) async {
    final json = await _api.post('/shopreturn', body: shopReturn.toSaveJson());
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<ShopReturnDetail> update(int id, ShopReturnDetail shopReturn) async {
    final json = await _api.put('/shopreturn/$id', body: shopReturn.toSaveJson());
    return ShopReturnDetail.fromJson(json as Map<String, dynamic>);
  }
}
