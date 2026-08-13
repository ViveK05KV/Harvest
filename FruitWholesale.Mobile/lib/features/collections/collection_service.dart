import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'collection_models.dart';

class CollectionService {
  final ApiClient _api;

  CollectionService(this._api);

  Future<PaginatedList<Collection>> getPaged({
    int pageNumber = 1,
    int pageSize = 20,
    int? shopId,
    String? fromDate,
    String? toDate,
  }) async {
    final json = await _api.get('/collection', query: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (shopId != null) 'shopId': shopId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
    return PaginatedList.fromJson(json as Map<String, dynamic>, Collection.fromJson);
  }

  Future<Collection> getById(int id) async {
    final json = await _api.get('/collection/$id');
    return Collection.fromJson(json as Map<String, dynamic>);
  }

  Future<Collection> create(Collection collection) async {
    final json = await _api.post('/collection', body: collection.toSaveJson());
    return Collection.fromJson(json as Map<String, dynamic>);
  }

  Future<Collection> update(int id, Collection collection) async {
    final json = await _api.put('/collection/$id', body: collection.toSaveJson());
    return Collection.fromJson(json as Map<String, dynamic>);
  }

  Future<CollectionSettlementPreview> getPendingSettlementPreview(int shopId) async {
    final json = await _api.get('/collection/pending-settle/preview', query: {'shopId': shopId});
    return CollectionSettlementPreview.fromJson(json as Map<String, dynamic>);
  }

  Future<CollectionSettlementResult> settle({required int shopId, required DateTime settlementDate}) async {
    final json = await _api.post('/collection/settle', body: {
      'shopID': shopId,
      'settlementDate': settlementDate.toIso8601String(),
    });
    return CollectionSettlementResult.fromJson(json as Map<String, dynamic>);
  }
}
