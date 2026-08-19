import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'supplier_return_models.dart';

class SupplierReturnService {
  final ApiClient _api;

  SupplierReturnService(this._api);

  Future<PaginatedList<SupplierReturnListItem>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    int? supplierId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/supplierreturn', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      if (supplierId != null) 'supplierId': supplierId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, SupplierReturnListItem.fromJson);
  }

  Future<SupplierReturnDetail> getById(int id) async {
    final json = await _api.get('/supplierreturn/$id');
    return SupplierReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<String> getNextReferenceNo() async {
    final json = await _api.get('/supplierreturn/next-reference-no');
    return json as String;
  }

  Future<SupplierReturnDetail> create(SupplierReturnDetail supplierReturn) async {
    final json = await _api.post('/supplierreturn', body: supplierReturn.toSaveJson());
    return SupplierReturnDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplierReturnDetail> update(int id, SupplierReturnDetail supplierReturn) async {
    final json = await _api.put('/supplierreturn/$id', body: supplierReturn.toSaveJson());
    return SupplierReturnDetail.fromJson(json as Map<String, dynamic>);
  }
}
