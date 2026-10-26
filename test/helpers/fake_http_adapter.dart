import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef _Reply = ResponseBody Function(RequestOptions options);

/// A Dio adapter that answers from a script, so tests never touch the
/// network.
class FakeHttpAdapter implements HttpClientAdapter {
  final _replies = <String, _Reply>{};
  final requests = <RequestOptions>[];

  void reply(
    String method,
    String path, {
    int status = 200,
    Object? body,
    Map<String, List<String>> headers = const {},
  }) {
    _replies['$method $path'] = (_) => ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [
          if (body is String) 'text/plain' else Headers.jsonContentType,
        ],
        ...headers,
      },
    );
  }

  /// Answers `{success: true, message: 'OK', data: data}`.
  void ok(String method, String path, Object? data) => reply(
    method,
    path,
    body: {'success': true, 'message': 'OK', 'data': data},
  );

  void fail(String method, String path, DioExceptionType type) {
    _replies['$method $path'] = (options) =>
        throw DioException(requestOptions: options, type: type);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = _replies['${options.method} ${options.path}'];
    if (reply == null) {
      throw StateError('No reply for ${options.method} ${options.path}');
    }
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}
