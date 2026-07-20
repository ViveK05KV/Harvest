import '../../core/api/api_client.dart';
import 'report_models.dart';

class ReportService {
  final ApiClient _api;

  ReportService(this._api);

  Map<String, dynamic> _range(DateTime from, DateTime to) => {
        'fromDate': from.toIso8601String(),
        'toDate': to.toIso8601String(),
      };

  Future<List<DailySalesRow>> dailySales(DateTime from, DateTime to) async {
    final json = await _api.get('/report/daily-sales', query: _range(from, to)) as List;
    return json.map((e) => DailySalesRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DailyCollectionRow>> dailyCollection(DateTime from, DateTime to) async {
    final json = await _api.get('/report/daily-collection', query: _range(from, to)) as List;
    return json.map((e) => DailyCollectionRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DailyExpenseRow>> dailyExpense(DateTime from, DateTime to) async {
    final json = await _api.get('/report/daily-expense', query: _range(from, to)) as List;
    return json.map((e) => DailyExpenseRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PurchaseReportRow>> purchase(DateTime from, DateTime to) async {
    final json = await _api.get('/report/purchase', query: _range(from, to)) as List;
    return json.map((e) => PurchaseReportRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FruitSalesRow>> fruitSales(DateTime from, DateTime to) async {
    final json = await _api.get('/report/fruit-sales', query: _range(from, to)) as List;
    return json.map((e) => FruitSalesRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OutstandingRow>> outstanding() async {
    final json = await _api.get('/report/outstanding') as List;
    return json.map((e) => OutstandingRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProfitSummaryRow>> profitSummary(DateTime from, DateTime to) async {
    final json = await _api.get('/report/profit-summary', query: _range(from, to)) as List;
    return json.map((e) => ProfitSummaryRow.fromJson(e as Map<String, dynamic>)).toList();
  }
}
