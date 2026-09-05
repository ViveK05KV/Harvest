import '../../core/api/api_client.dart';
import 'employee_loan_models.dart';

class EmployeeLoanService {
  final ApiClient _api;

  EmployeeLoanService(this._api);

  Future<List<EmployeeLoanSummaryRow>> getSummary() async {
    final json = await _api.get('/employeeloan/summary');
    return (json as List).map((e) => EmployeeLoanSummaryRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EmployeeLoanHistoryRow>> getHistory(int employeeId) async {
    final json = await _api.get('/employeeloan/$employeeId/history');
    return (json as List).map((e) => EmployeeLoanHistoryRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createRepayment(EmployeeLoanRepayment repayment) async {
    await _api.post('/employeeloan/repayments', body: repayment.toSaveJson());
  }

  Future<void> deleteRepayment(int id) async {
    await _api.delete('/employeeloan/repayments/$id');
  }

  Future<void> applyAdjustment(int employeeId, {required double amount, required bool isIncrease, required String narration}) async {
    await _api.post('/employeeloan/$employeeId/adjustments', body: {
      'amount': amount,
      'isIncrease': isIncrease,
      'narration': narration,
    });
  }

  Future<void> deleteAdjustment(int id) async {
    await _api.delete('/employeeloan/adjustments/$id');
  }
}
