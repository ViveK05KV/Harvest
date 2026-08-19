import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/current_user.dart';
import 'token_storage.dart';

/// Holds the logged-in user as observable state (via [ChangeNotifier]/Provider)
/// and drives login/logout against the backend's JWT auth endpoint.
///
/// Sessions persist like a typical mobile app (Instagram etc): the JWT access
/// token is short-lived, but a long-lived refresh token (backend default: 60
/// days) is exchanged for a new one silently, both proactively on cold start
/// and reactively whenever a request 401s mid-session. The user only ever
/// sees the login screen again once the refresh token itself has expired or
/// been revoked.
class AuthService extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  CurrentUser? _user;
  bool _restoring = true;

  // Concurrent requests can all 401 at once when the access token expires;
  // without this they'd each kick off their own refresh call, racing to
  // rotate the same refresh token and invalidating each other's attempt.
  Future<bool>? _refreshing;

  AuthService(this._api, this._storage) {
    _api.onUnauthorized = _handleUnauthorized;
    _api.onRefreshNeeded = _tryRefresh;
  }

  CurrentUser? get user => _user;
  bool get isAuthenticated => _user != null && !_user!.isExpired;

  /// True while the stored session is still being read on app startup.
  bool get isRestoring => _restoring;

  void _setUser(CurrentUser? user) {
    _user = user;
    _api.updateToken(user?.token);
  }

  /// Restores a previously saved session, if any. An expired access token is
  /// not treated as a dead session - it's refreshed silently using the saved
  /// refresh token before giving up, so reopening the app days later still
  /// lands on the home screen instead of the login screen.
  Future<void> restoreSession() async {
    final stored = await _storage.read();
    if (stored != null) {
      _setUser(stored);
      if (stored.isExpired && !await _tryRefresh()) {
        _setUser(null);
        await _storage.clear();
      }
    }
    _restoring = false;
    notifyListeners();
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> login(String username, String password) async {
    try {
      final json = await _api.post(
        '/auth/login',
        body: {'username': username, 'password': password},
        attemptRefresh: false,
      );
      final user = CurrentUser.fromJson(json as Map<String, dynamic>);
      _setUser(user);
      await _storage.save(user);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Returns null on success, or an error message on failure. On success the
  /// stored session's username is updated in place so the drawer/app bar
  /// reflect it immediately, without forcing a re-login.
  Future<String?> changeUsername(String newUsername, String currentPassword) async {
    try {
      final json = await _api.post('/auth/change-username', body: {
        'newUsername': newUsername,
        'currentPassword': currentPassword,
      });
      final current = _user!;
      final updated = CurrentUser(
        token: current.token,
        expiresAt: current.expiresAt,
        refreshToken: current.refreshToken,
        userId: current.userId,
        fullName: current.fullName,
        username: json as String,
        role: current.role,
      );
      _setUser(updated);
      await _storage.save(updated);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    final refreshToken = _user?.refreshToken;
    _setUser(null);
    await _storage.clear();
    notifyListeners();
    if (refreshToken != null) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': refreshToken}, attemptRefresh: false);
      } on ApiException {
        // Best-effort server-side revoke; local session is already cleared either way.
      }
    }
  }

  Future<bool> _tryRefresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refreshToken = _user?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final json = await _api.post('/auth/refresh', body: {'refreshToken': refreshToken}, attemptRefresh: false);
      final refreshed = CurrentUser.fromJson(json as Map<String, dynamic>);
      _setUser(refreshed);
      await _storage.save(refreshed);
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  void _handleUnauthorized() {
    if (_user == null) return;
    _setUser(null);
    _storage.clear();
    notifyListeners();
  }
}
