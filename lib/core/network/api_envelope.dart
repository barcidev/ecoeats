import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';

/// Sends a request and returns its parsed `data`; whatever fails on the way
/// surfaces as an [AppFailure].
Future<T> request<T>(
  Future<Response<Object?>> Function() send,
  T Function(Object? data) parse,
) async {
  final Response<Object?> response;
  try {
    response = await send();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
  final data = readEnvelope(response.data, parse);
  return data;
}

/// Reads the API's `{success, message, data}` envelope.
T readEnvelope<T>(Object? body, T Function(Object? data) parse) {
  if (body case {'success': true, 'data': final Object? data}) {
    try {
      return parse(data);
    } on Object catch (error) {
      throw AppFailure.unknown(cause: error);
    }
  }
  throw AppFailure.unknown(cause: 'Not an envelope: ${body.runtimeType}');
}
