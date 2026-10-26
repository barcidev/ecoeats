import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/features/auth/application/register_controller.dart';
import 'package:ecoeats/features/auth/application/validators.dart';
import 'package:ecoeats/features/auth/presentation/widgets/achiote_sweep.dart';
import 'package:ecoeats/features/auth/presentation/widgets/auth_panel.dart';
import 'package:ecoeats/features/auth/presentation/widgets/password_checklist.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Creates an account in two steps: who the customer is, then how they will
/// sign in. What the API refuses lands on its step and field, and a created
/// account signs in on its own.
@RoutePage()
class RegisterPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _firstNames = TextEditingController();
  final _lastNames = TextEditingController();
  final _document = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final GlobalKey _button = GlobalKey();

  /// Messages of a step show only after its first try, then follow typing.
  var _triedAbout = false;
  var _triedAccess = false;
  var _hidden = true;
  var _refusals = 0;

  @override
  void dispose() {
    for (final controller in [
      _firstNames,
      _lastNames,
      _document,
      _email,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  RegisterController get _controller =>
      ref.read(registerControllerProvider.notifier);

  void _edited(String _) {
    setState(() {});
    if (ref.read(registerControllerProvider).failure != null) {
      _controller.dismissFailure();
    }
  }

  void _continue() {
    setState(() => _triedAbout = true);
    final valid =
        Validators.names(_firstNames.text) == null &&
        Validators.names(_lastNames.text) == null &&
        Validators.document(_document.text) == null;
    if (valid) {
      _controller.next();
    } else {
      setState(() => _refusals++);
    }
  }

  Future<void> _submit() async {
    setState(() => _triedAccess = true);
    final valid =
        Validators.email(_email.text) == null &&
        Validators.newPassword(_password.text) == null;
    if (!valid) {
      setState(() => _refusals++);
      return;
    }
    await _controller.submit(
      documentNumber: _document.text,
      firstNames: _firstNames.text,
      lastNames: _lastNames.text,
      email: _email.text,
      password: _password.text,
    );
  }

  void _onRegister(RegisterState? previous, RegisterState next) {
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
    final answered = (previous?.submitting ?? false) && !next.submitting;
    if (answered && next.rejectedFields.isNotEmpty) {
      setState(() => _refusals++);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, _onRegister);
    final state = ref.watch(registerControllerProvider);
    final t = context.t;
    final about = state.step == .about;

    return AuthPanel(
      overline: t.auth.register.step(current: state.step.index + 1, total: 2),
      title: t.auth.register.title,
      subtitle: about
          ? t.auth.register.about.title
          : t.auth.register.access.title,
      onBack: about ? null : _controller.back,
      footer: PanelFooter(
        question: t.auth.register.haveAccount,
        action: t.auth.register.signIn,
        onPressed: () => context.router.replacePath('login'),
      ),
      children: [
        Shake(
          trigger: _refusals == 0 ? null : _refusals,
          child: _StepSwitcher(
            forward: !about,
            child: about
                ? _aboutFields(
                    t,
                    state,
                    key: const ValueKey(RegisterStep.about),
                  )
                : _accessFields(
                    t,
                    state,
                    key: const ValueKey(RegisterStep.access),
                  ),
          ),
        ),
        FormMessage(_formMessage(t, state)),
        const SizedBox(height: Space.lg),
        if (about)
          EcoButton(label: t.common.actions.next, onPressed: _continue)
        else
          _submitButton(t, state),
      ],
    );
  }

  Widget _aboutFields(Translations t, RegisterState state, {Key? key}) {
    final copy = t.auth.register.about;
    final errors = t.auth.fieldErrors;
    String? check(RegisterField field, String value, String required) {
      if (state.rejectedFields.contains(field)) {
        return _refusal(t, state, field);
      }
      if (!_triedAbout) return null;
      final max = field == .documentNumber
          ? Validators.maxDocumentLength
          : Validators.maxNameLength;
      return switch (field == .documentNumber
          ? Validators.document(value)
          : Validators.names(value)) {
        null => null,
        .required => required,
        _ => errors.tooLong(max: max),
      };
    }

    return Column(
      key: key,
      crossAxisAlignment: .stretch,
      children: [
        EcoTextField(
          label: copy.firstNames,
          controller: _firstNames,
          error: check(
            .firstNames,
            _firstNames.text,
            errors.firstNamesRequired,
          ),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
          onChanged: _edited,
        ),
        const SizedBox(height: Space.lg),
        EcoTextField(
          label: copy.lastNames,
          controller: _lastNames,
          error: check(.lastNames, _lastNames.text, errors.lastNamesRequired),
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.familyName],
          onChanged: _edited,
        ),
        const SizedBox(height: Space.lg),
        EcoTextField(
          label: copy.document,
          controller: _document,
          hint: copy.documentHint,
          error: check(
            .documentNumber,
            _document.text,
            errors.documentRequired,
          ),
          textInputAction: TextInputAction.done,
          onChanged: _edited,
          onSubmitted: (_) => _continue(),
        ),
      ],
    );
  }

  Widget _accessFields(Translations t, RegisterState state, {Key? key}) {
    final copy = t.auth.register.access;
    final errors = t.auth.fieldErrors;
    final busy = state.submitting || state.succeeded;

    String? emailMessage() {
      if (state.rejectedFields.contains(RegisterField.email)) {
        return _refusal(t, state, .email);
      }
      if (!_triedAccess) return null;
      return switch (Validators.email(_email.text)) {
        null => null,
        .required => errors.emailRequired,
        .tooLong => errors.emailTooLong(max: Validators.maxEmailLength),
        _ => errors.emailInvalid,
      };
    }

    String? passwordMessage() {
      if (state.rejectedFields.contains(RegisterField.password)) {
        return _refusal(t, state, .password);
      }
      if (!_triedAccess) return null;
      return switch (Validators.newPassword(_password.text)) {
        null => null,
        .required => errors.passwordRequired,
        .tooShort => errors.passwordTooShort(min: Validators.minPasswordLength),
        _ => errors.passwordTooLong,
      };
    }

    return Column(
      key: key,
      crossAxisAlignment: .stretch,
      children: [
        EcoTextField(
          label: copy.email,
          controller: _email,
          error: emailMessage(),
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.newUsername],
          onChanged: _edited,
        ),
        const SizedBox(height: Space.lg),
        EcoTextField(
          label: copy.password,
          controller: _password,
          error: passwordMessage(),
          enabled: !busy,
          obscureText: _hidden,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
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
        const SizedBox(height: Space.sm),
        PasswordRules(password: _password.text),
      ],
    );
  }

  Widget _submitButton(Translations t, RegisterState state) {
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
      label: t.auth.register.submit,
      loading: state.submitting,
      // After a success the sweep covers the screen; the button just rests.
      onPressed: state.succeeded ? null : _submit,
    );
  }

  /// What the API said about [field]: a taken email or document in the app's
  /// words, otherwise its own Spanish message, which only Spanish shows.
  String _refusal(Translations t, RegisterState state, RegisterField field) {
    final spanish = t.$meta.locale == AppLocale.es;
    return switch (state.failure) {
      ConflictFailure(field: .email) => t.errors.conflict.email,
      ConflictFailure(field: .document) => t.errors.conflict.document,
      _ when spanish => state.serverMessage(field) ?? t.errors.validation,
      _ => t.errors.validation,
    };
  }

  String? _formMessage(Translations t, RegisterState state) {
    final failure = state.failure;
    if (failure == null || state.rejectedFields.isNotEmpty) return null;
    return failureMessage(failure, t);
  }
}

/// Slides the fields of the next step in from the side they come from.
class _StepSwitcher extends StatelessWidget {
  const new({required this.forward, required this.child});

  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return AnimatedSwitcher(
      duration: Motion.standard,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Motion.emphasized.flipped,
      layoutBuilder: (current, previous) =>
          Stack(alignment: .topCenter, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final entering = child.key == this.child.key;
        final from = (entering == forward ? 1.0 : -1.0) * 0.12;
        return FadeTransition(
          opacity: animation,
          child: reduced
              ? child
              : SlideTransition(
                  position: Tween(
                    begin: Offset(from, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
        );
      },
      child: child,
    );
  }
}
