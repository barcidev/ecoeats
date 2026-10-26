import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';

/// The words of a failure for a full-screen state.
typedef FailureCopy = ({String title, String? message, String? reference});

FailureCopy failureCopy(AppFailure failure, Translations t) {
  final errors = t.errors;
  return switch (failure) {
    OfflineFailure() => (
      title: errors.offline.title,
      message: errors.offline.message,
      reference: null,
    ),
    TimeoutFailure() => (
      title: errors.timeout.title,
      message: errors.timeout.message,
      reference: null,
    ),
    RateLimitedFailure() => (
      title: errors.rateLimited.title,
      message: errors.rateLimited.message,
      reference: null,
    ),
    ServerFailure(:final requestId) => (
      title: errors.server.title,
      message: errors.server.message,
      reference: requestId == null
          ? null
          : errors.server.reference(id: requestId),
    ),
    _ => (title: failureMessage(failure, t), message: null, reference: null),
  };
}

/// One line for a toast or under a field.
///
/// The server writes only in Spanish, so its message never shows as is: it
/// fills in, in Spanish, only where the app has no words of its own.
String failureMessage(AppFailure failure, Translations t) {
  final errors = t.errors;
  final spanish = t.$meta.locale == AppLocale.es;
  String fallback(String? server, String generic) =>
      spanish && server != null && server.isNotEmpty ? server : generic;

  return switch (failure) {
    OfflineFailure() => errors.offline.title,
    TimeoutFailure() => errors.timeout.title,
    RateLimitedFailure() => errors.rateLimited.title,
    ServerFailure() => errors.server.title,
    NotFoundFailure() => errors.notFound,
    UnauthorizedFailure() => errors.unauthorized,
    ValidationFailure(:final fieldErrors, :final message) =>
      fieldErrors.isEmpty
          ? fallback(message, errors.validation)
          : errors.validation,
    ConflictFailure(field: .email) => errors.conflict.email,
    ConflictFailure(field: .document) => errors.conflict.document,
    ConflictFailure(:final message) => fallback(message, errors.conflict.other),
    UnknownFailure() => errors.unknown,
  };
}
