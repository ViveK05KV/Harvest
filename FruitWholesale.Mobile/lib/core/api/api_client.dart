import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Thin wrapper around [http] that attaches the current JWT, decodes JSON,
/// and turns non-2xx responses into [ApiException].
///
/// The token is held in memory (kept in sync by [AuthService] via
/// [updateToken]) rather than re-read from secure storage on every request —
/// that storage read is a real disk/IPC round-trip through the Android
/// Keystore, unnecessary when the value rarely changes.
class ApiClient {
  final http.Client _http;

  String? _token;

  /// Set by the auth layer; invoked whenever a request comes back 401 so the
  /// app can drop the stale session and return to the login screen. Only
  /// fires once a refresh attempt (below) has already failed or wasn't
  /// applicable, so it stays the "give up, go to login" signal.
  void Function()? onUnauthorized;

  /// Set by the auth layer. Called on a 401 to silently exchange the refresh
  /// token for a new access token; returns true if the caller should retry
  /// the request that just failed. Concurrency (many in-flight requests
  /// hitting 401 at once) is coalesced by the auth layer, not here.
  Future<bool> Function()? onRefreshNeeded;

  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  void updateToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) params[key] = value.toString();
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      // Sent as X-Authorization, not Authorization: the API is reached through
      // CloudFront, whose Origin Access Control signs every origin request and
      // overwrites Authorization with its own SigV4 signature. EdgeIdentityMiddleware
      // promotes this back onto Authorization before authenticating — mirrors
      // the Angular client's auth.interceptor.ts exactly.
      if (_token != null) 'X-Authorization': 'Bearer $_token',
    };
  }

  /// CloudFront's OAC does not hash the body itself — it trusts and signs
  /// whatever the viewer supplies in `x-amz-content-sha256`. Without it, any
  /// request carrying a body is rejected before it ever reaches the app with
  /// "The request signature we calculated does not match the signature you
  /// provided." Mirrors the Angular client's payload-hash.interceptor.ts.
  Map<String, String> _signedJsonHeaders(List<int>? bodyBytes) {
    final headers = _headers();
    if (bodyBytes != null) {
      headers['x-amz-content-sha256'] = sha256.convert(bodyBytes).toString();
    }
    return headers;
  }

  dynamic _handle(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    final decoded = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    throw ApiException(response.statusCode, ApiException.extractMessage(response.statusCode, decoded));
  }

  /// Sends via [sender], and on a 401 tries exactly one silent refresh-and-
  /// retry before falling through to [_handle]'s normal 401 handling. Pass
  /// `attemptRefresh: false` for calls that must not recurse into refresh
  /// themselves (the refresh call, the login call).
  Future<dynamic> _send(Future<http.Response> Function() sender, {bool attemptRefresh = true}) async {
    var response = await sender();
    if (response.statusCode == 401 && attemptRefresh && onRefreshNeeded != null) {
      final refreshed = await onRefreshNeeded!();
      if (refreshed) response = await sender();
    }
    return _handle(response);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool attemptRefresh = true}) {
    return _send(
      () => _http.get(_uri(path, query), headers: _headers(json: false)),
      attemptRefresh: attemptRefresh,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool attemptRefresh = true}) {
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _http.post(_uri(path), headers: _signedJsonHeaders(bytes), body: bytes),
      attemptRefresh: attemptRefresh,
    );
  }

  Future<dynamic> put(String path, {Object? body, bool attemptRefresh = true}) {
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _http.put(_uri(path), headers: _signedJsonHeaders(bytes), body: bytes),
      attemptRefresh: attemptRefresh,
    );
  }

  Future<dynamic> patch(String path, {Object? body, bool attemptRefresh = true}) {
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _http.patch(_uri(path), headers: _signedJsonHeaders(bytes), body: bytes),
      attemptRefresh: attemptRefresh,
    );
  }

  Future<dynamic> delete(String path, {bool attemptRefresh = true}) {
    return _send(
      () => _http.delete(_uri(path), headers: _headers(json: false)),
      attemptRefresh: attemptRefresh,
    );
  }

  /// Uploads a single file as `multipart/form-data` under the given field name.
  Future<dynamic> postMultipartFile(String path, {required String fieldName, required String filePath}) async {
    final multipart = http.MultipartRequest('POST', _uri(path));
    multipart.headers.addAll(_headers(json: false));
    multipart.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    // The exact bytes CloudFront's OAC signs must be the exact bytes on the
    // wire, so the multipart body is finalized to bytes up front (rather than
    // streamed) purely to hash it — the file sizes involved here (logo
    // uploads, capped server-side at 2 MB) make that trade fine.
    final bytes = await multipart.finalize().toBytes();
    final headers = Map<String, String>.from(multipart.headers)
      ..remove('content-length')
      ..['x-amz-content-sha256'] = sha256.convert(bytes).toString();

    final response = await _http.post(_uri(path), headers: headers, body: bytes);
    return _handle(response);
  }
}
