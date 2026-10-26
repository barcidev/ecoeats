import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

/// A signed-in user. The API has no refresh token, so a session simply ends
/// at [expiresAt] (24 h after login) and the user signs in again.
@freezed
abstract class Session with _$Session {
  const factory({
    required String token,
    required String userId,
    required String email,
    required DateTime expiresAt,
    String? role,

    /// Known only on devices where this user registered.
    String? firstNames,
  }) = _Session;

  const new _();

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  Duration remainingAt(DateTime now) {
    final remaining = expiresAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
