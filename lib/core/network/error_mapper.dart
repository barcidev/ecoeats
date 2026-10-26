import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/app_failure.dart';

const _defaultRetryAfter = Duration(seconds: 60);

AppFailure toFailure(Object error) => switch (error) {
  AppFailure() => error,
  DioException() => mapDioError(error),
  _ => AppFailure.unknown(cause: error),
};

AppFailure mapDioError(DioException error) {
  switch (error.type) {
    case .connectionError:
      return const AppFailure.offline();
    case .connectionTimeout ||
        .sendTimeout ||
        .receiveTimeout ||
        .transformTimeout:
      return const AppFailure.timeout();
    case .badResponse:
      return _fromResponse(error.response);
    case .cancel || .badCertificate || .unknown:
      return AppFailure.unknown(cause: error);
  }
}

AppFailure _fromResponse(Response<Object?>? response) {
  final status = response?.statusCode;
  final body = response?.data;
  final message = body is Map ? body['message'] as String? : null;

  return switch (status) {
    400 || 422 => AppFailure.validation(
      fieldErrors: _fieldErrors(body),
      message: message,
    ),
    401 || 403 => AppFailure.unauthorized(message: message),
    404 => AppFailure.notFound(message: message),
    409 => AppFailure.conflict(
      field: _conflictField(message),
      message: message,
    ),
    429 => AppFailure.rateLimited(
      retryAfter: _retryAfter(response?.headers.value('retry-after')),
    ),
    final int code when code >= 500 => AppFailure.server(
      status: code,
      requestId: response?.headers.value('x-request-id'),
      message: message,
    ),
    _ => AppFailure.unknown(cause: 'HTTP $status'),
  };
}

Map<String, String> _fieldErrors(Object? body) {
  if (body is! Map || body['errors'] is! List) return const {};
  return {
    for (final error
        in (body['errors'] as List).whereType<Map<Object?, Object?>>())
      if (error case {
        'field': final String field,
        'message': final String text,
      })
        field: text,
  };
}

// The API only says which value collided in its Spanish message.
ConflictField? _conflictField(String? message) {
  final text = message?.toLowerCase() ?? '';
  if (text.contains('documento')) return .document;
  if (text.contains('email') || text.contains('correo')) return .email;
  return null;
}

Duration _retryAfter(String? header) {
  final seconds = int.tryParse(header?.trim() ?? '');
  return seconds == null || seconds < 0
      ? _defaultRetryAfter
      : Duration(seconds: seconds);
}
