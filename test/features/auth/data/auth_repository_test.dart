import 'package:dio/dio.dart';
import 'package:ecoeats/features/auth/data/auth_api.dart';
import 'package:ecoeats/features/auth/data/auth_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http_adapter.dart';

const _user = {
  'id': '0199c394-3880-7000-8000-000000000001',
  'numero_documento': '1032456789',
  'nombres': 'Jorge',
  'apellidos': 'Palacio',
  'correo': 'jorge@example.com',
};

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
  });

  group('DTOs', () {
    test('login response keeps id, email and token', () {
      final login = LoginResponse.fromJson(const {
        'id': 'u1',
        'email': 'jorge@example.com',
        'token': 'jwt',
        'tokenFirebaseAuth': '',
      });
      expect(
        login,
        const LoginResponse(id: 'u1', email: 'jorge@example.com', token: 'jwt'),
      );
    });

    test('registered user reads the Spanish keys', () {
      final user = RegisteredUser.fromJson(_user);
      expect(user.documentNumber, '1032456789');
      expect(user.firstNames, 'Jorge');
      expect(user.lastNames, 'Palacio');
      expect(user.email, 'jorge@example.com');
    });

    test('register request writes the Spanish keys', () {
      const body = RegisterRequest(
        documentNumber: '1032456789',
        firstNames: 'Jorge',
        lastNames: 'Palacio',
        email: 'jorge@example.com',
        password: 'secreta1',
      );
      expect(body.toJson(), {
        'numero_documento': '1032456789',
        'nombres': 'Jorge',
        'apellidos': 'Palacio',
        'correo': 'jorge@example.com',
        'password': 'secreta1',
      });
    });
  });

  group('AuthApi', () {
    test('register posts the request and returns the user', () async {
      adapter.reply(
        'POST',
        '/api/securities/register',
        status: 201,
        body: {
          'success': true,
          'message': 'Usuario registrado correctamente',
          'data': {'user': _user},
        },
      );
      final user = await AuthApi(dio).register(
        const RegisterRequest(
          documentNumber: '1032456789',
          firstNames: 'Jorge',
          lastNames: 'Palacio',
          email: 'jorge@example.com',
          password: 'secreta1',
        ),
      );
      expect(user.id, _user['id']);
      expect(
        adapter.requests.single.data,
        containsPair('numero_documento', '1032456789'),
      );
    });

    test('verify OTP returns the valid flag', () async {
      adapter.ok('POST', '/api/securities/verify-otp', {'valid': false});
      final valid = await AuthApi(dio)
          .verifyOtp(email: 'jorge@example.com', otp: '123456');
      expect(valid, isFalse);
      expect(adapter.requests.single.data, {
        'email': 'jorge@example.com',
        'otp': '123456',
      });
    });

    test('forgot and reset password post to their endpoints', () async {
      adapter
        ..ok('POST', '/api/securities/forgot-password', null)
        ..ok('POST', '/api/securities/reset-password', null);
      final api = AuthApi(dio);
      await api.forgotPassword('jorge@example.com');
      await api.resetPassword(
        email: 'jorge@example.com',
        otp: '123456',
        newPassword: 'nueva123',
      );
      expect(adapter.requests.map((request) => request.path), [
        '/api/securities/forgot-password',
        '/api/securities/reset-password',
      ]);
      expect(adapter.requests.last.data, {
        'email': 'jorge@example.com',
        'otp': '123456',
        'newPassword': 'nueva123',
      });
    });
  });
}
