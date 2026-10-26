import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_controller.freezed.dart';
part 'register_controller.g.dart';

enum RegisterStep { about, access }

/// The registration fields, each with the step that holds it and the key the
/// API uses for it in a 400.
enum RegisterField {
  firstNames('nombres', .about),
  lastNames('apellidos', .about),
  documentNumber('numero_documento', .about),
  email('correo', .access),
  password('password', .access);

  new(this.apiKey, this.step);

  final String apiKey;
  final RegisterStep step;
}

/// One registration attempt. `blockedUntil` is set by a 429 and outlives a
/// dismissed failure, so the button keeps counting down.
@freezed
abstract class RegisterState with _$RegisterState {
  const factory({
    @Default(RegisterStep.about) RegisterStep step,
    @Default(false) bool submitting,
    @Default(false) bool succeeded,
    AppFailure? failure,
    DateTime? blockedUntil,
  }) = _RegisterState;

  const new _();

  /// What the API refused: the fields a 400 names, or the value a 409 says
  /// was already taken.
  Set<RegisterField> get rejectedFields => switch (failure) {
    ValidationFailure(:final fieldErrors) => {
      for (final field in RegisterField.values)
        if (fieldErrors.containsKey(field.apiKey)) field,
    },
    ConflictFailure(field: .email) => {RegisterField.email},
    ConflictFailure(field: .document) => {RegisterField.documentNumber},
    _ => const {},
  };

  /// The API's own words about [field], which only exist in Spanish.
  String? serverMessage(RegisterField field) => switch (failure) {
    ValidationFailure(:final fieldErrors) => fieldErrors[field.apiKey],
    _ => null,
  };
}

/// Walks the two registration steps and signs up through the session, which
/// signs in right after and keeps the first names for the greeting.
@riverpod
class RegisterController extends _$RegisterController {
  @override
  RegisterState build() => const RegisterState();

  DateTime _now() => ref.read(clockProvider)();

  void next() => state = state.copyWith(step: .access);

  void back() => state = state.copyWith(step: .about);

  Future<void> submit({
    required String documentNumber,
    required String firstNames,
    required String lastNames,
    required String email,
    required String password,
  }) async {
    final current = state;
    final blockedUntil = current.blockedUntil;
    if (current.submitting ||
        current.succeeded ||
        (blockedUntil != null && _now().isBefore(blockedUntil))) {
      return;
    }
    state = current.copyWith(
      submitting: true,
      failure: null,
      blockedUntil: null,
    );
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .register(
            documentNumber: documentNumber,
            firstNames: firstNames,
            lastNames: lastNames,
            email: email,
            password: password,
          );
      if (!ref.mounted) return;
      state = state.copyWith(submitting: false, succeeded: true);
    } on Object catch (error) {
      if (!ref.mounted) return;
      final failure = toFailure(error);
      final refused = RegisterState(
        step: current.step,
        failure: failure,
        blockedUntil: switch (failure) {
          RateLimitedFailure(:final retryAfter) => _now().add(retryAfter),
          _ => null,
        },
      );
      // Back to the first step that holds a refused field.
      final steps = refused.rejectedFields.map((field) => field.step).toSet();
      state = refused.copyWith(
        step: steps.isEmpty
            ? current.step
            : RegisterStep.values.firstWhere(steps.contains),
      );
    }
  }

  void dismissFailure() => state = state.copyWith(failure: null);
}
