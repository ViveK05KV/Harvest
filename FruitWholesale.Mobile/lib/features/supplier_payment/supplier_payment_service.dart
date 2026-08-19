import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'supplier_payment_models.dart';

class SupplierPaymentService {
  final ApiClient _api;

  SupplierPaymentService(this._api);

  Future<PaginatedList<SupplierPayment>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    int? supplierId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/supplierpayment', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (supplierId != null) 'supplierId': supplierId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, SupplierPayment.fromJson);
  }

  Future<SupplierPayment> getById(int id) async {
    final json = await _api.get('/supplierpayment/$id');
    return SupplierPayment.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplierPayment> create(SupplierPayment payment) async {
    final json = await _api.post('/supplierpayment', body: payment.toSaveJson());
    return SupplierPayment.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplierPayment> update(int id, SupplierPayment payment) async {
    final json = await _api.put('/supplierpayment/$id', body: payment.toSaveJson());
    return SupplierPayment.fromJson(json as Map<String, dynamic>);
  }
}
