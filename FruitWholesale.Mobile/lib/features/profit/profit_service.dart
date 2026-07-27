import '../../core/api/api_client.dart';
import 'profit_models.dart';

/// Admin-only profit endpoints (see ProfitController). Non-admin callers get
/// a 403 from the API - the nav item that reaches this screen is already
/// gated to Admin in home_shell.dart.
class ProfitService {
  final ApiClient _api;

  ProfitService(this._api);

  Map<String, dynamic> _query({int? shopId, DateTime? from, DateTime? to}) => {
        if (shopId != null) 'shopId': shopId,
        if (from != null) 'fromDate': from.toIso8601String(),
        if (to != null) 'toDate': to.toIso8601String(),
      };

  Future<List<ShopDailyProfitRow>> shopDaily({int? shopId, DateTime? from, DateTime? to}) async {
    final json = await _api.get('/profit/shop-daily', query: _query(shopId: shopId, from: from, to: to)) as List;
    return json.map((e) => ShopDailyProfitRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopProfitSummaryRow>> shopSummary({DateTime? from, DateTime? to}) async {
    final json = await _api.get('/profit/shop-summary', query: _query(from: from, to: to)) as List;
    return json.map((e) => ShopProfitSummaryRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FruitProfitSummaryRow>> fruitSummary({DateTime? from, DateTime? to}) async {
    final json = await _api.get('/profit/fruit-summary', query: _query(from: from, to: to)) as List;
    return json.map((e) => FruitProfitSummaryRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopFruitProfitRow>> shopFruit({int? shopId, DateTime? from, DateTime? to}) async {
    final json = await _api.get('/profit/shop-fruit', query: _query(shopId: shopId, from: from, to: to)) as List;
    return json.map((e) => ShopFruitProfitRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BusinessProfitTotal> businessTotal() async {
    final json = await _api.get('/profit/business-total');
    return BusinessProfitTotal.fromJson(json as Map<String, dynamic>);
  }
}
