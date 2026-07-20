import '../../core/api/api_client.dart';
import '../../core/models/paginated_list.dart';
import 'user_models.dart';

class UserService {
  final ApiClient _api;

  UserService(this._api);

  Future<PaginatedList<AppUser>> getPaged(int pageNumber) async {
    final json = await _api.get('/users', query: {'pageNumber': pageNumber, 'pageSize': 20});
    return PaginatedList.fromJson(json as Map<String, dynamic>, AppUser.fromJson);
  }

  Future<AppUser> create({required String fullName, required String username, required String password, required String role}) async {
    final json = await _api.post('/users', body: {
      'fullName': fullName,
      'username': username,
      'password': password,
      'role': role,
    });
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  Future<AppUser> update(int id, {required String fullName, required String role}) async {
    final json = await _api.put('/users/$id', body: {'fullName': fullName, 'role': role});
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/users/$id/${active ? 'activate' : 'deactivate'}');
  }
}
