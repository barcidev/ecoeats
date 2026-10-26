import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/core/network/retry.dart';
import 'package:flutter_test/flutter_test.dart';

final _request = RequestOptions(path: '/api/dish');

DioException _status(
  int status, {
  Object? body,
  Map<String, List<String>> headers = const {},
}) {
  return DioException.badResponse(
    statusCode: status,
    requestOptions: _request,
    response: Response<Object?>(
      requestOptions: _request,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object?> _error(String message, [List<Object?>? errors]) => {
  'success': false,
  'message': message,
  'data': null,
  'timestamp': '2026-10-09T12:00:00Z',
  'errors': ?errors,
};

void main() {
  group('mapDioError', () {
    test('a connection error is offline', () {
      final error = DioException.connectionError(
        requestOptions: _request,
        reason: 'Failed host lookup',
      );
      expect(mapDioError(error), const AppFailure.offline());
    });

    test('every timeout is a timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final error = DioException(requestOptions: _request, type: type);
        expect(mapDioError(error), const AppFailure.timeout());
      }
    });

    test('400 with errors is a validation failure per field', () {
      final failure = mapDioError(
        _status(
          400,
          body: _error('Datos de entrada inválidos', [
            {'field': 'correo', 'message': 'El correo debe ser válido'},
          ]),
        ),
      );
      expect(
        failure,
        const AppFailure.validation(
          fieldErrors: {'correo': 'El correo debe ser válido'},
          message: 'Datos de entrada inválidos',
        ),
      );
    });

    test('400 without errors is a validation failure without fields', () {
      final failure = mapDioError(
        _status(400, body: _error('OTP inválido o expirado')),
      );
      expect(
        failure,
        const AppFailure.validation(
          fieldErrors: {},
          message: 'OTP inválido o expirado',
        ),
      );
    });

    test('401 is unauthorized and 404 is not found', () {
      expect(
        mapDioError(_status(401, body: _error('Credenciales inválidas'))),
        const AppFailure.unauthorized(message: 'Credenciales inválidas'),
      );
      expect(
        mapDioError(_status(404, body: _error('Plato no encontrado'))),
        const AppFailure.notFound(message: 'Plato no encontrado'),
      );
    });

    test('the known 409s carry their field', () {
      expect(
        mapDioError(_status(409, body: _error('El email ya está registrado'))),
        const AppFailure.conflict(
          field: .email,
          message: 'El email ya está registrado',
        ),
      );
      expect(
        mapDioError(
          _status(
            409,
            body: _error('El número de documento ya está registrado'),
          ),
        ),
        const AppFailure.conflict(
          field: .document,
          message: 'El número de documento ya está registrado',
        ),
      );
      expect(
        mapDioError(_status(409, body: _error('Otro conflicto'))),
        const AppFailure.conflict(message: 'Otro conflicto'),
      );
    });

    test('429 waits what Retry-After says, or a minute', () {
      expect(
        mapDioError(
          _status(
            429,
            headers: {
              'retry-after': ['42'],
            },
          ),
        ),
        const AppFailure.rateLimited(retryAfter: Duration(seconds: 42)),
      );
      expect(
        mapDioError(_status(429)),
        const AppFailure.rateLimited(retryAfter: Duration(seconds: 60)),
      );
    });

    test('5xx is a server failure with its request id', () {
      final failure = mapDioError(
        _status(
          503,
          body: _error('No fue posible enviar el correo, intenta de nuevo'),
          headers: {
            'x-request-id': ['ab12cd'],
          },
        ),
      );
      expect(
        failure,
        const AppFailure.server(
          status: 503,
          requestId: 'ab12cd',
          message: 'No fue posible enviar el correo, intenta de nuevo',
        ),
      );
    });

    test('a body that is not JSON keeps no server message', () {
      expect(
        mapDioError(_status(500, body: '<html>Bad gateway</html>')),
        const AppFailure.server(status: 500),
      );
    });
  });

  group('toFailure', () {
    test('passes failures through and wraps anything else', () {
      const failure = AppFailure.notFound();
      expect(toFailure(failure), same(failure));
      expect(toFailure(const FormatException('bad')), isA<UnknownFailure>());
    });
  });

  group('retryPolicy', () {
    test('retries transient failures twice with a growing delay', () {
      final first = retryPolicy(0, const AppFailure.offline());
      final second = retryPolicy(1, const AppFailure.timeout());
      expect(first, isNotNull);
      expect(second, greaterThan(first!));
      expect(retryPolicy(2, const AppFailure.offline()), isNull);
    });

    test('never retries anything else', () {
      expect(retryPolicy(0, const AppFailure.notFound()), isNull);
      expect(
        retryPolicy(0, const AppFailure.rateLimited(retryAfter: .zero)),
        isNull,
      );
      expect(retryPolicy(0, StateError('bug')), isNull);
    });
  });
}
