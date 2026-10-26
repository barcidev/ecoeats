import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/sign_in_hold.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
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

  /// Keeps Home waiting while the button celebrates a sign-in.
  SignInHold? _hold;

  @override
  void dispose() {
    _hold?.release();
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
    _hold = ref.read(signInHoldProvider);
    _hold?.hold();
    await ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  /// Runs once the button has drawn its check: the sweep is born there and
  /// lets Home come when it covers the app.
  void _celebrate() {
    TextInput.finishAutofillContext();
    final box = _button.currentContext?.findRenderObject() as RenderBox?;
    AchioteSweep.play(
      context,
      origin: box == null
          ? MediaQuery.sizeOf(context).center(Offset.zero)
          : box.localToGlobal(box.size.center(Offset.zero)),
      onCovered: _hold?.release,
    );
  }

  /// Recovery ends by handing back the email it reset; the password field
  /// waits for the new one.
  Future<void> _recover() async {
    final email = await context.router.pushPath<String>('recover');
    if (!mounted || email == null) return;
    setState(() {
      _email.text = email;
      _password.clear();
      _tried = false;
    });
    _passwordFocus.requestFocus();
  }

  void _onLogin(LoginState? previous, LoginState next) {
    final answered = (previous?.submitting ?? false) && !next.submitting;
    if (!answered || next.failure == null) return;
    // Nothing to celebrate: Home must not wait for this attempt.
    _hold?.release();
    // Only what the API refused about the typing shakes; a lost connection
    // is nobody's mistake.
    if (next.failure is UnauthorizedFailure ||
        next.failure is ValidationFailure) {
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
      footer: PanelFooter(
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
                suffix: PasswordToggle(
                  hidden: _hidden,
                  onToggle: () => setState(() => _hidden = !_hidden),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: .centerRight,
          child: TextLink(
            label: t.auth.login.forgot,
            onPressed: busy ? null : _recover,
          ),
        ),
        FormMessage(_formMessage(t, state)),
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
      success: state.succeeded,
      onSuccess: _celebrate,
      onPressed: _submit,
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
