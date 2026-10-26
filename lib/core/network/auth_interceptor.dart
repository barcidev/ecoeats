import 'package:dio/dio.dart';

/// Adds the Bearer token to authenticated requests and ends the session when
/// the server rejects it.
///
/// It reads the token at request time instead of holding the session, so Dio
/// does not depend on the session controller that itself uses Dio.
class AuthInterceptor extends Interceptor {
  new({required this.readToken, required this.onUnauthorized});

  final Future<String?> Function() readToken;
  final void Function() onUnauthorized;

  static const _header = 'Authorization';

  // Login, register and recovery happen before there is a session, and a 401
  // there means a wrong password, not an expired token.
  static bool _isPublic(RequestOptions options) {
    final path = options.uri.path;
    return path.startsWith('/api/securities/') || path == '/health';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options)) {
      final token = await readToken();
      if (token != null) options.headers[_header] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sentToken = err.requestOptions.headers.containsKey(_header);
    if (err.response?.statusCode == 401 && sentToken) onUnauthorized();
    handler.next(err);
  }
}
