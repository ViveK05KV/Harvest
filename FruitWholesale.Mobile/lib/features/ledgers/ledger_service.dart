import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'ledger_models.dart';

class LedgerService {
  final ApiClient _api;

  LedgerService(this._api);

  Future<PaginatedList<LedgerEntry>> getShopLedger(int shopId, {int pageNumber = 1}) async {
    final json = await _api.get('/ledger/shop/$shopId', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, LedgerEntry.fromJson);
  }

  Future<PaginatedList<LedgerEntry>> getSupplierLedger(int supplierId, {int pageNumber = 1}) async {
    final json = await _api.get('/ledger/supplier/$supplierId', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, LedgerEntry.fromJson);
  }

  Future<PaginatedList<CashLedgerEntry>> getCashLedger({int pageNumber = 1}) async {
    final json = await _api.get('/ledger/cash', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, CashLedgerEntry.fromJson);
  }
}
