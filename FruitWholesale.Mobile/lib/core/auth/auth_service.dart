import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/current_user.dart';
import 'token_storage.dart';

/// Holds the logged-in user as observable state (via [ChangeNotifier]/Provider)
/// and drives login/logout against the backend's JWT auth endpoint.
class AuthService extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  CurrentUser? _user;
  bool _restoring = true;

  AuthService(this._api, this._storage) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  CurrentUser? get user => _user;
  bool get isAuthenticated => _user != null && !_user!.isExpired;

  /// True while the stored session is still being read on app startup.
  bool get isRestoring => _restoring;

  /// Restores a previously saved session, if any and not expired.
  Future<void> restoreSession() async {
    final stored = await _storage.read();
    if (stored != null && !stored.isExpired) {
      _user = stored;
    } else if (stored != null) {
      await _storage.clear();
    }
    _restoring = false;
    notifyListeners();
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> login(String username, String password) async {
    try {
      final json = await _api.post('/auth/login', body: {
        'username': username,
        'password': password,
      });
      final user = CurrentUser.fromJson(json as Map<String, dynamic>);
      _user = user;
      await _storage.save(user);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.clear();
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_user == null) return;
    _user = null;
    _storage.clear();
    notifyListeners();
  }
}
