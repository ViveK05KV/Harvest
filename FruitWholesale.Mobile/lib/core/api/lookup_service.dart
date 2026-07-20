import '../models/employee_option.dart';
import '../models/expense_category_option.dart';
import '../models/fruit_option.dart';
import '../models/route_option.dart';
import '../models/shop_option.dart';
import '../models/supplier_option.dart';
import 'api_client.dart';

/// Shared read-only lookups (active shops/fruits/routes/suppliers) used across
/// forms for their dropdowns.
class LookupService {
  final ApiClient _api;

  LookupService(this._api);

  Future<List<ShopOption>> getActiveShops() async {
    final json = await _api.get('/shopmaster/active') as List;
    return json.map((e) => ShopOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FruitOption>> getActiveFruits() async {
    final json = await _api.get('/fruitmaster/active') as List;
    return json.map((e) => FruitOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RouteOption>> getActiveRoutes() async {
    final json = await _api.get('/routemaster/active') as List;
    return json.map((e) => RouteOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SupplierOption>> getActiveSuppliers() async {
    final json = await _api.get('/suppliermaster/active') as List;
    return json.map((e) => SupplierOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EmployeeOption>> getActiveEmployees() async {
    final json = await _api.get('/employee/active') as List;
    return json.map((e) => EmployeeOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExpenseCategoryOption>> getActiveExpenseCategories() async {
    final json = await _api.get('/expensecategory/active') as List;
    return json.map((e) => ExpenseCategoryOption.fromJson(e as Map<String, dynamic>)).toList();
  }
}
