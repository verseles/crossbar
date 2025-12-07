/// HTTP response wrapper
class WebResponse {
  const WebResponse({
    required this.statusCode,
    this.body,
    this.headers = const {},
    this.error,
  });

  /// HTTP status code
  final int statusCode;

  /// Response body (can be String, Map, List depending on content-type)
  final dynamic body;

  /// Response headers
  final Map<String, String> headers;

  /// Error message if request failed
  final String? error;

  /// Whether request was successful (2xx status)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether request failed
  bool get isError => error != null || statusCode >= 400;

  /// Get body as Map (for JSON responses)
  Map<String, dynamic>? get json {
    if (body is Map<String, dynamic>) return body;
    return null;
  }

  /// Get body as String
  String get text => body?.toString() ?? '';

  @override
  String toString() => isError ? 'WebResponse(error: $error)' : 'WebResponse($statusCode)';
}
