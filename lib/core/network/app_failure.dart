import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

enum ConflictField { email, document }

/// Everything that can go wrong talking to the API, in the app's own terms.
///
/// The server writes its messages only in Spanish, so the UI shows a
/// translated text per variant; `message` is just a fallback for Spanish.
@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  const factory offline() = OfflineFailure;

  const factory timeout() = TimeoutFailure;

  const factory unauthorized({String? message}) = UnauthorizedFailure;

  const factory validation({
    required Map<String, String> fieldErrors,
    String? message,
  }) = ValidationFailure;

  const factory conflict({ConflictField? field, String? message}) =
      ConflictFailure;

  const factory notFound({String? message}) = NotFoundFailure;

  const factory rateLimited({required Duration retryAfter}) =
      RateLimitedFailure;

  const factory server({int? status, String? requestId, String? message}) =
      ServerFailure;

  const factory unknown({Object? cause}) = UnknownFailure;

  const new _();

  /// Failures that may go away by trying again a moment later.
  bool get isTransient => switch (this) {
    OfflineFailure() || TimeoutFailure() => true,
    _ => false,
  };
}
