import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'purchase_models.dart';

class PurchaseService {
  final ApiClient _api;

  PurchaseService(this._api);

  Future<PaginatedList<PurchaseListItem>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    int? supplierId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/purchase', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      if (supplierId != null) 'supplierId': supplierId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, PurchaseListItem.fromJson);
  }

  Future<PurchaseDetail> getById(int id) async {
    final json = await _api.get('/purchase/$id');
    return PurchaseDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<String> getNextInvoiceNo() async {
    final json = await _api.get('/purchase/next-invoice-no');
    return json as String;
  }

  Future<PurchaseDetail> create(PurchaseDetail purchase) async {
    final json = await _api.post('/purchase', body: purchase.toSaveJson());
    return PurchaseDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<PurchaseDetail> update(int id, PurchaseDetail purchase) async {
    final json = await _api.put('/purchase/$id', body: purchase.toSaveJson());
    return PurchaseDetail.fromJson(json as Map<String, dynamic>);
  }
}
