import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'expense_category_models.dart';

class ExpenseCategoryService {
  final ApiClient _api;

  ExpenseCategoryService(this._api);

  Future<PaginatedList<ExpenseCategory>> getPaged(int pageNumber) async {
    final json = await _api.get('/expensecategory', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, ExpenseCategory.fromJson);
  }

  Future<ExpenseCategory> getById(int id) async {
    final json = await _api.get('/expensecategory/$id');
    return ExpenseCategory.fromJson(json as Map<String, dynamic>);
  }

  Future<ExpenseCategory> create(ExpenseCategory category) async {
    final json = await _api.post('/expensecategory', body: category.toSaveJson());
    return ExpenseCategory.fromJson(json as Map<String, dynamic>);
  }

  Future<ExpenseCategory> update(int id, ExpenseCategory category) async {
    final json = await _api.put('/expensecategory/$id', body: category.toSaveJson());
    return ExpenseCategory.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/expensecategory/$id/${active ? 'activate' : 'deactivate'}');
  }
}
