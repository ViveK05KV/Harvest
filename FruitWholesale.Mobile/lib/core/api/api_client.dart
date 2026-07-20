import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

/// Thin wrapper around [http] that attaches the stored JWT, decodes JSON,
/// and turns non-2xx responses into [ApiException].
class ApiClient {
  final TokenStorage _tokenStorage;
  final http.Client _http;

  /// Set by the auth layer; invoked whenever a request comes back 401 so the
  /// app can drop the stale session and return to the login screen.
  void Function()? onUnauthorized;

  ApiClient(this._tokenStorage, {http.Client? client}) : _http = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) params[key] = value.toString();
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final user = await _tokenStorage.read();
    return {
      if (json) 'Content-Type': 'application/json',
      if (user != null) 'Authorization': 'Bearer ${user.token}',
    };
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

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _http.get(_uri(path, query), headers: await _headers(json: false));
    return _handle(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _http.post(_uri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body));
    return _handle(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _http.put(_uri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body));
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _http.patch(_uri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body));
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _http.delete(_uri(path), headers: await _headers(json: false));
    return _handle(response);
  }

  /// Uploads a single file as `multipart/form-data` under the given field name.
  Future<dynamic> postMultipartFile(String path, {required String fieldName, required String filePath}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers(json: false));
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamedResponse = await _http.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response);
  }
}
