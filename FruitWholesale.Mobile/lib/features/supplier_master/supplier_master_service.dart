import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'supplier_master_models.dart';

class SupplierMasterService {
  final ApiClient _api;

  SupplierMasterService(this._api);

  Future<PaginatedList<SupplierMaster>> getPaged(int pageNumber) async {
    final json = await _api.get('/suppliermaster', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, SupplierMaster.fromJson);
  }

  Future<SupplierMaster> getById(int id) async {
    final json = await _api.get('/suppliermaster/$id');
    return SupplierMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplierMaster> create(SupplierMaster supplier) async {
    final json = await _api.post('/suppliermaster', body: supplier.toCreateJson());
    return SupplierMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplierMaster> update(int id, SupplierMaster supplier) async {
    final json = await _api.put('/suppliermaster/$id', body: supplier.toUpdateJson());
    return SupplierMaster.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/suppliermaster/$id/${active ? 'activate' : 'deactivate'}');
  }
}
