import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recovery_controller.freezed.dart';
part 'recovery_controller.g.dart';

/// The limits the API puts on a recovery code.
abstract final class RecoveryRules {
  static const validity = Duration(minutes: 15);
  static const resendWait = Duration(seconds: 60);

  /// After this many wrong codes the API burns the code for good.
  static const maxAttempts = 5;
}

/// Why the current code cannot be used as it is.
enum CodeIssue {
  /// The API said no; there are attempts left.
  rejected,

  /// Every attempt is spent: only a new code helps.
  locked,

  /// Its 15 minutes are over, or the reset no longer takes it.
  expired,
}

/// One state per step of the recovery flow. `blockedUntil` is set when the
/// API answers 429, so the screen can count down to the next try.
@freezed
sealed class RecoveryState with _$RecoveryState {
  const factory email({
    @Default('') String email,
    @Default(false) bool sending,
    AppFailure? failure,
    DateTime? blockedUntil,
  }) = RecoveryEmail;

  const factory code({
    required String email,
    required DateTime expiresAt,
    required DateTime resendAt,
    @Default(RecoveryRules.maxAttempts) int attemptsLeft,
    @Default(false) bool verifying,
    @Default(false) bool resending,
    CodeIssue? issue,
    AppFailure? failure,
    DateTime? blockedUntil,
  }) = RecoveryCode;

  const factory password({
    required String email,
    required String code,
    required DateTime expiresAt,
    required DateTime resendAt,
    @Default(false) bool saving,
    AppFailure? failure,
    DateTime? blockedUntil,
  }) = RecoveryPassword;

  const factory done({required String email}) = RecoveryDone;
}

/// Walks the three recovery steps. Each action is ignored when the current
/// step cannot take it, so a double tap never sends twice.
@riverpod
class RecoveryController extends _$RecoveryController {
  @override
  RecoveryState build() => const RecoveryState.email();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  DateTime _now() => ref.read(clockProvider)();

  bool _isBlocked(DateTime? until) => until != null && _now().isBefore(until);

  DateTime? _blockedUntil(AppFailure failure) => switch (failure) {
    RateLimitedFailure(:final retryAfter) => _now().add(retryAfter),
    _ => null,
  };

  Future<void> sendCode(String email) async {
    final current = state;
    if (current is! RecoveryEmail ||
        current.sending ||
        _isBlocked(current.blockedUntil)) {
      return;
    }
    state = RecoveryState.email(email: email, sending: true);
    try {
      await _repository.forgotPassword(email);
      if (!ref.mounted) return;
      state = _freshCode(normalizeEmail(email));
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      state = RecoveryState.email(
        email: email,
        failure: failure,
        blockedUntil: _blockedUntil(failure),
      );
    }
  }

  Future<void> resend() async {
    final current = state;
    if (current is! RecoveryCode ||
        current.resending ||
        current.verifying ||
        _now().isBefore(current.resendAt) ||
        _isBlocked(current.blockedUntil)) {
      return;
    }
    state = current.copyWith(resending: true, failure: null);
    try {
      await _repository.forgotPassword(current.email);
      if (!ref.mounted) return;
      state = _freshCode(current.email);
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      state = current.copyWith(
        failure: failure,
        blockedUntil: _blockedUntil(failure),
      );
    }
  }

  Future<void> verify(String code) async {
    final current = state;
    if (current is! RecoveryCode ||
        current.verifying ||
        current.resending ||
        current.issue == .locked ||
        _isBlocked(current.blockedUntil)) {
      return;
    }
    if (!_now().isBefore(current.expiresAt)) {
      state = current.copyWith(issue: .expired, failure: null);
      return;
    }
    state = current.copyWith(verifying: true, issue: null, failure: null);
    try {
      final valid = await _repository.verifyOtp(
        email: current.email,
        otp: code,
      );
      if (!ref.mounted) return;
      if (valid) {
        state = RecoveryState.password(
          email: current.email,
          code: code,
          expiresAt: current.expiresAt,
          resendAt: current.resendAt,
        );
        return;
      }
      final attemptsLeft = current.attemptsLeft - 1;
      state = current.copyWith(
        attemptsLeft: attemptsLeft,
        // The API answers the same `false` for a wrong code and an expired one.
        issue: !_now().isBefore(current.expiresAt)
            ? .expired
            : attemptsLeft > 0
            ? .rejected
            : .locked,
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      state = current.copyWith(
        failure: failure,
        blockedUntil: _blockedUntil(failure),
      );
    }
  }

  Future<void> resetPassword(String newPassword) async {
    final current = state;
    if (current is! RecoveryPassword ||
        current.saving ||
        _isBlocked(current.blockedUntil)) {
      return;
    }
    if (!_now().isBefore(current.expiresAt)) {
      state = _expiredCode(current);
      return;
    }
    state = current.copyWith(saving: true, failure: null);
    try {
      await _repository.resetPassword(
        email: current.email,
        otp: current.code,
        newPassword: newPassword,
      );
      if (!ref.mounted) return;
      state = RecoveryState.done(email: current.email);
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      state = switch (failure) {
        // Without field errors, the 400 is the API's «OTP inválido o
        // expirado»: the code was verified before, so it ran out or was used.
        ValidationFailure(:final fieldErrors) when fieldErrors.isEmpty =>
          _expiredCode(current),
        _ => current.copyWith(
          failure: failure,
          blockedUntil: _blockedUntil(failure),
        ),
      };
    }
  }

  /// One step back: from the code to the email, from the new password to the
  /// code.
  void back() {
    state = switch (state) {
      RecoveryCode(:final email) => RecoveryState.email(email: email),
      RecoveryPassword(:final email, :final expiresAt, :final resendAt) =>
        RecoveryState.code(
          email: email,
          expiresAt: expiresAt,
          resendAt: resendAt,
        ),
      final other => other,
    };
  }

  RecoveryState _freshCode(String email) {
    final now = _now();
    return RecoveryState.code(
      email: email,
      expiresAt: now.add(RecoveryRules.validity),
      resendAt: now.add(RecoveryRules.resendWait),
    );
  }

  RecoveryState _expiredCode(RecoveryPassword password) => RecoveryState.code(
    email: password.email,
    expiresAt: password.expiresAt,
    resendAt: password.resendAt,
    issue: .expired,
  );
}
