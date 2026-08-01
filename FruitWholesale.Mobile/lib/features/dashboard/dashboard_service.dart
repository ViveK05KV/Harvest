import '../../core/api/api_client.dart';
import 'dashboard_models.dart';

class DashboardService {
  final ApiClient _api;

  DashboardService(this._api);

  Future<DashboardSummary> getSummary() async {
    final json = await _api.get('/dashboard/summary');
    return DashboardSummary.fromJson(json as Map<String, dynamic>);
  }

  Future<DashboardCharts> getCharts() async {
    final json = await _api.get('/dashboard/charts');
    return DashboardCharts.fromJson(json as Map<String, dynamic>);
  }

  Future<List<TrendPoint>> getSalesTrend(DashboardPeriod period) async {
    final json = await _api.get('/dashboard/sales-trend', query: {'period': period.toApi}) as List;
    return json.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SalesVsPurchases> getSalesVsPurchases(DashboardPeriod period) async {
    final json = await _api.get('/dashboard/sales-vs-purchases', query: {'period': period.toApi});
    return SalesVsPurchases.fromJson(json as Map<String, dynamic>);
  }

  Future<List<TrendPoint>> getCashTrend() async {
    final json = await _api.get('/dashboard/cash-trend') as List;
    return json.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TrendPoint>> getProfitTrend() async {
    final json = await _api.get('/dashboard/profit-trend') as List;
    return json.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
