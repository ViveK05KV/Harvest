import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'supply_models.dart';

class SupplyService {
  final ApiClient _api;

  SupplyService(this._api);

  Future<PaginatedList<SupplyListItem>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    int? shopId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/supply', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (shopId != null) 'shopId': shopId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, SupplyListItem.fromJson);
  }

  Future<SupplyDetail> getById(int id) async {
    final json = await _api.get('/supply/$id');
    return SupplyDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplyBillExtras> getBillExtras(int id) async {
    final json = await _api.get('/supply/$id/bill');
    return SupplyBillExtras.fromJson(json as Map<String, dynamic>);
  }

  Future<String> getNextInvoiceNo() async {
    final json = await _api.get('/supply/next-invoice-no');
    return json as String;
  }

  Future<SupplyDetail> create(SupplyDetail supply) async {
    final json = await _api.post('/supply', body: supply.toSaveJson());
    return SupplyDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplyDetail> update(int id, SupplyDetail supply) async {
    final json = await _api.put('/supply/$id', body: supply.toSaveJson());
    return SupplyDetail.fromJson(json as Map<String, dynamic>);
  }
}
