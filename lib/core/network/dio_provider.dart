import 'package:dio/dio.dart';
import 'package:ecoeats/core/config/env.dart';
import 'package:ecoeats/core/network/auth_interceptor.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      readToken: () => ref.read(tokenStoreProvider).readToken(),
      onUnauthorized: () =>
          ref.read(sessionControllerProvider.notifier).onUnauthorized(),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
