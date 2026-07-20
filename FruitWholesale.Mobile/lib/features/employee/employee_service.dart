import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'employee_models.dart';

class EmployeeService {
  final ApiClient _api;

  EmployeeService(this._api);

  Future<PaginatedList<Employee>> getPaged(int pageNumber) async {
    final json = await _api.get('/employee', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, Employee.fromJson);
  }

  Future<Employee> getById(int id) async {
    final json = await _api.get('/employee/$id');
    return Employee.fromJson(json as Map<String, dynamic>);
  }

  Future<Employee> create(Employee employee) async {
    final json = await _api.post('/employee', body: employee.toSaveJson());
    return Employee.fromJson(json as Map<String, dynamic>);
  }

  Future<Employee> update(int id, Employee employee) async {
    final json = await _api.put('/employee/$id', body: employee.toSaveJson());
    return Employee.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/employee/$id/${active ? 'activate' : 'deactivate'}');
  }
}
