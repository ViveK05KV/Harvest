import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'stock_models.dart';

class StockService {
  final ApiClient _api;

  StockService(this._api);

  Future<List<CurrentStock>> getCurrentStock() async {
    final json = await _api.get('/stock/current') as List;
    return json.map((e) => CurrentStock.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaginatedList<StockLedgerEntry>> getStockLedger(int fruitId, {int pageNumber = 1}) async {
    final json = await _api.get('/stock/ledger/$fruitId', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, StockLedgerEntry.fromJson);
  }

  Future<void> applyAdjustment({required int fruitId, required double quantity, required bool isIncrease, required String narration}) async {
    await _api.post('/stock/adjustment', body: {
      'fruitID': fruitId,
      'quantity': quantity,
      'isIncrease': isIncrease,
      'narration': narration,
    });
  }
}
