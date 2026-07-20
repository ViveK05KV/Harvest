/// Thrown by [ApiClient] for any non-2xx response, with the server's error
/// message(s) already extracted from either error shape the backend returns:
/// - FluentValidation/ModelState: `{ errors: { "Field": ["msg"] } }`
/// - Business-rule failures via `Result`: `{ errors: ["msg"] }`
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  static String extractMessage(int statusCode, dynamic body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List) {
        return errors.map((e) => e.toString()).join('\n');
      }
      if (errors is Map) {
        return errors.values
            .expand((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .join('\n');
      }
      if (body['detail'] is String) return body['detail'] as String;
      if (body['title'] is String) return body['title'] as String;
    }
    if (statusCode == 401) return 'Session expired. Please log in again.';
    if (statusCode == 403) return 'You do not have permission to do that.';
    return 'Something went wrong (HTTP $statusCode).';
  }

  @override
  String toString() => message;
}
