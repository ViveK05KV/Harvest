import '../models/employee_option.dart';
import '../models/expense_category_option.dart';
import '../models/fruit_option.dart';
import '../models/route_option.dart';
import '../models/shop_option.dart';
import '../models/supplier_option.dart';
import 'api_client.dart';

/// Shared read-only lookups (active shops/fruits/routes/suppliers) used across
/// forms for their dropdowns. Results are cached at the class level (not per
/// instance, since callers construct a fresh LookupService per screen) so
/// opening Supply/Purchase/Collections/etc. repeatedly during a session
/// doesn't re-fetch these rarely-changing lists from the network every time.
/// Call [invalidateAll] after editing a master list so the next form open
/// picks up the change.
class LookupService {
  final ApiClient _api;

  LookupService(this._api);

  static Future<List<ShopOption>>? _shopsCache;
  static Future<List<FruitOption>>? _fruitsCache;
  static Future<List<RouteOption>>? _routesCache;
  static Future<List<SupplierOption>>? _suppliersCache;
  static Future<List<EmployeeOption>>? _employeesCache;
  static Future<List<ExpenseCategoryOption>>? _expenseCategoriesCache;

  Future<List<ShopOption>> getActiveShops() => _shopsCache ??= _fetchShops();
  Future<List<FruitOption>> getActiveFruits() => _fruitsCache ??= _fetchFruits();
  Future<List<RouteOption>> getActiveRoutes() => _routesCache ??= _fetchRoutes();
  Future<List<SupplierOption>> getActiveSuppliers() => _suppliersCache ??= _fetchSuppliers();
  Future<List<EmployeeOption>> getActiveEmployees() => _employeesCache ??= _fetchEmployees();
  Future<List<ExpenseCategoryOption>> getActiveExpenseCategories() =>
      _expenseCategoriesCache ??= _fetchExpenseCategories();

  static void invalidateAll() {
    _shopsCache = null;
    _fruitsCache = null;
    _routesCache = null;
    _suppliersCache = null;
    _employeesCache = null;
    _expenseCategoriesCache = null;
  }

  Future<List<ShopOption>> _fetchShops() async {
    final json = await _api.get('/shopmaster/active') as List;
    return json.map((e) => ShopOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FruitOption>> _fetchFruits() async {
    final json = await _api.get('/fruitmaster/active') as List;
    return json.map((e) => FruitOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RouteOption>> _fetchRoutes() async {
    final json = await _api.get('/routemaster/active') as List;
    return json.map((e) => RouteOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SupplierOption>> _fetchSuppliers() async {
    final json = await _api.get('/suppliermaster/active') as List;
    return json.map((e) => SupplierOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EmployeeOption>> _fetchEmployees() async {
    final json = await _api.get('/employee/active') as List;
    return json.map((e) => EmployeeOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExpenseCategoryOption>> _fetchExpenseCategories() async {
    final json = await _api.get('/expensecategory/active') as List;
    return json.map((e) => ExpenseCategoryOption.fromJson(e as Map<String, dynamic>)).toList();
  }
}
