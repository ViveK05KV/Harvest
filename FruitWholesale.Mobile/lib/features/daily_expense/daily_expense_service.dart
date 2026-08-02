import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'daily_expense_models.dart';

class DailyExpenseService {
  final ApiClient _api;

  DailyExpenseService(this._api);

  Future<PaginatedList<DailyExpense>> getPaged({int pageNumber = 1, int pageSize = 20, String? fromDate, String? toDate}) async {
    final json = await _api.get('/dailyexpense', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, DailyExpense.fromJson);
  }

  Future<DailyExpense> getById(int id) async {
    final json = await _api.get('/dailyexpense/$id');
    return DailyExpense.fromJson(json as Map<String, dynamic>);
  }

  Future<DailyExpense> create(DailyExpense expense) async {
    final json = await _api.post('/dailyexpense', body: expense.toSaveJson());
    return DailyExpense.fromJson(json as Map<String, dynamic>);
  }

  Future<DailyExpense> update(int id, DailyExpense expense) async {
    final json = await _api.put('/dailyexpense/$id', body: expense.toSaveJson());
    return DailyExpense.fromJson(json as Map<String, dynamic>);
  }
}
