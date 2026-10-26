import 'package:ecoeats/core/network/app_failure.dart';

const _maxRetries = 2;
const _baseDelay = Duration(milliseconds: 400);

/// Retry policy for `ProviderScope(retry:)`: a 4xx never fixes itself, so only
/// lost connections and timeouts are tried again.
Duration? retryPolicy(int retryCount, Object error) {
  if (retryCount >= _maxRetries) return null;
  if (error is! AppFailure || !error.isTransient) return null;
  return _baseDelay * (1 << retryCount);
}
