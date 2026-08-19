import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'employee_work_log_models.dart';

class EmployeeWorkLogService {
  final ApiClient _api;

  EmployeeWorkLogService(this._api);

  Future<PaginatedList<EmployeeWorkLog>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    int? employeeId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/employeeworklog', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (employeeId != null) 'employeeId': employeeId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, EmployeeWorkLog.fromJson);
  }

  Future<EmployeeWorkLog> getById(int id) async {
    final json = await _api.get('/employeeworklog/$id');
    return EmployeeWorkLog.fromJson(json as Map<String, dynamic>);
  }

  Future<EmployeeWorkLog> create(EmployeeWorkLog log) async {
    final json = await _api.post('/employeeworklog', body: log.toSaveJson());
    return EmployeeWorkLog.fromJson(json as Map<String, dynamic>);
  }

  Future<EmployeeWorkLog> update(int id, EmployeeWorkLog log) async {
    final json = await _api.put('/employeeworklog/$id', body: log.toSaveJson());
    return EmployeeWorkLog.fromJson(json as Map<String, dynamic>);
  }
}
