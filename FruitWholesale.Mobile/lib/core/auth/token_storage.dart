import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/current_user.dart';

/// Persists the logged-in user (including JWT) in Android Keystore-backed
/// encrypted storage — never plain SharedPreferences.
class TokenStorage {
  static const _key = 'fw_current_user';

  final _storage = const FlutterSecureStorage();

  Future<void> save(CurrentUser user) async {
    await _storage.write(key: _key, value: jsonEncode(user.toJson()));
  }

  Future<CurrentUser?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return CurrentUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt/incompatible stored value from a previous app version.
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
