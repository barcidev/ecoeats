import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_controller.freezed.dart';
part 'login_controller.g.dart';

/// The login fields, named as the API names them in a 400's field errors.
enum LoginField { email, password }

/// One login attempt. `blockedUntil` is set by a 429 and outlives a dismissed
/// failure, so the button keeps counting down to the next try.
@freezed
abstract class LoginState with _$LoginState {
  const factory({
    @Default(false) bool submitting,
    @Default(false) bool succeeded,
    AppFailure? failure,
    DateTime? blockedUntil,
  }) = _LoginState;

  const new _();

  Set<LoginField> get rejectedFields => switch (failure) {
    ValidationFailure(:final fieldErrors) => {
      for (final field in LoginField.values)
        if (fieldErrors.containsKey(field.name)) field,
    },
    _ => const {},
  };
}

/// Signs in through the session and tracks the attempt; the screen decides
/// what each outcome looks like.
@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  DateTime _now() => ref.read(clockProvider)();

  Future<void> submit({required String email, required String password}) async {
    final current = state;
    final blockedUntil = current.blockedUntil;
    if (current.submitting ||
        current.succeeded ||
        (blockedUntil != null && _now().isBefore(blockedUntil))) {
      return;
    }
    state = const LoginState(submitting: true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: email, password: password);
      if (!ref.mounted) return;
      state = const LoginState(succeeded: true);
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      state = LoginState(
        failure: failure,
        blockedUntil: switch (failure) {
          RateLimitedFailure(:final retryAfter) => _now().add(retryAfter),
          _ => null,
        },
      );
    }
  }

  void dismissFailure() => state = state.copyWith(failure: null);
}
