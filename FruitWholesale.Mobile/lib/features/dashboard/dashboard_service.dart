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
}
