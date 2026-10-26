import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/features/auth/application/login_controller.dart';
import 'package:ecoeats/features/auth/application/validators.dart';
import 'package:ecoeats/features/auth/presentation/widgets/achiote_sweep.dart';
import 'package:ecoeats/features/auth/presentation/widgets/auth_panel.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Signs a returning customer in. Fields are checked before sending; what the
/// API refuses is said in the app's words, and a success sweeps into Home.
@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  final GlobalKey _button = GlobalKey();

  /// Messages show only after the first try, then follow the typing.
  var _tried = false;
  var _hidden = true;

  /// Each refusal shakes the form once more.
  var _refusals = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _valid =>
      Validators.email(_email.text) == null &&
      Validators.loginPassword(_password.text) == null;

  void _edited(String _) {
    setState(() {});
    if (ref.read(loginControllerProvider).failure != null) {
      ref.read(loginControllerProvider.notifier).dismissFailure();
    }
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (!_valid) {
      setState(() => _refusals++);
      return;
    }
    await ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  void _onLogin(LoginState? previous, LoginState next) {
    if (next.succeeded && !(previous?.succeeded ?? false)) {
      TextInput.finishAutofillContext();
      final box = _button.currentContext?.findRenderObject() as RenderBox?;
      AchioteSweep.play(
        context,
        origin: box == null
            ? MediaQuery.sizeOf(context).center(Offset.zero)
            : box.localToGlobal(box.size.center(Offset.zero)),
      );
      return;
    }
    // Only what the API refused about the typing shakes; a lost connection
    // is nobody's mistake.
    final answered = (previous?.submitting ?? false) && !next.submitting;
    if (answered &&
        (next.failure is UnauthorizedFailure ||
            next.failure is ValidationFailure)) {
      setState(() => _refusals++);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, _onLogin);
    final state = ref.watch(loginControllerProvider);
    final t = context.t;
    final busy = state.submitting || state.succeeded;

    return AuthPanel(
      title: t.auth.login.title,
      subtitle: t.auth.login.subtitle,
      footer: _Footer(
        question: t.auth.login.noAccount,
        action: t.auth.login.createOne,
        onPressed: () => context.router.replacePath('register'),
      ),
      children: [
        Shake(
          trigger: _refusals == 0 ? null : _refusals,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              EcoTextField(
                label: t.auth.login.email,
                controller: _email,
                error: _emailMessage(t, state),
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                onChanged: _edited,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: Space.lg),
              EcoTextField(
                label: t.auth.login.password,
                controller: _password,
                focusNode: _passwordFocus,
                error: _passwordMessage(t, state),
                enabled: !busy,
                obscureText: _hidden,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: _edited,
                onSubmitted: (_) => _submit(),
                suffix: Pressable(
                  semanticLabel: _hidden
                      ? t.auth.password.show
                      : t.auth.password.hide,
                  onPressed: () => setState(() => _hidden = !_hidden),
                  child: Icon(
                    _hidden ? EcoIcons.eye : EcoIcons.eyeSlash,
                    size: 20,
                    color: context.palette.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: .centerRight,
          child: _TextLink(
            label: t.auth.login.forgot,
            onPressed: busy ? null : () => context.router.pushPath('recover'),
          ),
        ),
        _FormMessage(_formMessage(t, state)),
        const SizedBox(height: Space.lg),
        _submitButton(t, state, busy),
      ],
    );
  }

  Widget _submitButton(Translations t, LoginState state, bool busy) {
    final blockedUntil = state.blockedUntil;
    if (blockedUntil != null &&
        ref.read(clockProvider)().isBefore(blockedUntil)) {
      return Countdown(
        until: blockedUntil,
        onDone: () => setState(() {}),
        builder: (context, left) => EcoButton(
          label: t.common.retryIn(time: Countdown.format(left)),
          icon: const Icon(EcoIcons.clockCountdown, size: 20),
        ),
      );
    }
    return EcoButton(
      key: _button,
      label: t.auth.login.submit,
      loading: state.submitting,
      // After a success the sweep covers the screen; the button just rests.
      onPressed: state.succeeded ? null : _submit,
    );
  }

  String? _emailMessage(Translations t, LoginState state) {
    final errors = t.auth.fieldErrors;
    if (state.rejectedFields.contains(LoginField.email)) {
      return errors.emailInvalid;
    }
    if (!_tried) return null;
    return switch (Validators.email(_email.text)) {
      null => null,
      .required => errors.emailRequired,
      .tooLong => errors.emailTooLong(max: Validators.maxEmailLength),
      _ => errors.emailInvalid,
    };
  }

  String? _passwordMessage(Translations t, LoginState state) {
    final rejected = state.rejectedFields.contains(LoginField.password);
    if (!rejected &&
        (!_tried || Validators.loginPassword(_password.text) == null)) {
      return null;
    }
    return t.auth.fieldErrors.passwordRequired;
  }

  String? _formMessage(Translations t, LoginState state) {
    return switch (state.failure) {
      null => null,
      UnauthorizedFailure() => t.auth.login.wrongCredentials,
      // Field errors are already under their fields.
      ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty => null,
      final failure => failureMessage(failure, t),
    };
  }
}

/// One line under the form for what the API answered, announced to screen
/// readers when it appears.
class _FormMessage extends StatelessWidget {
  const new(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: .topLeft,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: .start,
                  children: [
                    Icon(
                      EcoIcons.warningCircle,
                      size: 18,
                      color: palette.achiote,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        text,
                        style: EcoType.bodySmall.copyWith(
                          color: palette.achiote,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Text(
          label,
          style: EcoType.label.copyWith(
            color: palette.ink,
            decoration: TextDecoration.underline,
            decorationColor: palette.line,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        Text(
          question,
          style: EcoType.bodySmall.copyWith(color: context.palette.muted),
        ),
        const SizedBox(width: Space.xs),
        _TextLink(label: action, onPressed: onPressed),
      ],
    );
  }
}
