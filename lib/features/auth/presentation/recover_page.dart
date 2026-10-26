import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/features/auth/application/recovery_controller.dart';
import 'package:ecoeats/features/auth/application/validators.dart';
import 'package:ecoeats/features/auth/presentation/widgets/auth_panel.dart';
import 'package:ecoeats/features/auth/presentation/widgets/otp_field.dart';
import 'package:ecoeats/features/auth/presentation/widgets/password_checklist.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// «jorge@gmail.com» becomes «j•••@gmail.com»: enough to recognize the
/// address, not to read it over someone's shoulder.
String maskEmail(String email) {
  final at = email.indexOf('@');
  return at <= 0 ? email : '${email[0]}•••${email.substring(at)}';
}

/// Password recovery in three steps (email, emailed code, new password) and
/// a drawn check at the end, which returns to login with the email.
@RoutePage()
class RecoverPage extends ConsumerStatefulWidget {
  const new({super.key});

  @visibleForTesting
  static const checkKey = Key('recover-check');

  @override
  ConsumerState<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends ConsumerState<RecoverPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  /// Messages of a step show only after its first try, then follow typing.
  var _triedEmail = false;
  var _triedPassword = false;
  var _hidden = true;

  /// Each rejected code shakes the field once more.
  var _rejections = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  RecoveryController get _controller =>
      ref.read(recoveryControllerProvider.notifier);

  bool _before(DateTime? deadline) =>
      deadline != null && ref.read(clockProvider)().isBefore(deadline);

  void _onRecovery(RecoveryState? previous, RecoveryState next) {
    switch ((previous, next)) {
      case (RecoveryCode(verifying: true), RecoveryCode(:final issue))
          when issue == .rejected || issue == .locked:
        setState(() => _rejections++);
      case (RecoveryCode(resending: true), RecoveryCode(failure: null)):
        Toast.show(context, context.t.auth.recover.code.resent);
      default:
    }
  }

  Future<void> _sendCode() async {
    setState(() => _triedEmail = true);
    if (Validators.email(_email.text) == null) {
      await _controller.sendCode(_email.text);
    }
  }

  Future<void> _save() async {
    setState(() => _triedPassword = true);
    final valid =
        Validators.newPassword(_password.text) == null &&
        Validators.confirmation(_password.text, _confirmation.text) == null;
    if (valid) await _controller.resetPassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recoveryControllerProvider, _onRecovery);
    final state = ref.watch(recoveryControllerProvider);
    final t = context.t;
    final copy = t.auth.recover;
    final (title, subtitle, content) = switch (state) {
      RecoveryEmail() => (copy.title, copy.email.message, _emailStep(t, state)),
      RecoveryCode(:final email) => (
        copy.code.title,
        copy.code.message(email: maskEmail(email)),
        _codeStep(t, state),
      ),
      RecoveryPassword() => (
        copy.password.title,
        null,
        _passwordStep(t, state),
      ),
      RecoveryDone() => (
        copy.done.title,
        copy.done.message,
        _doneStep(t, state),
      ),
    };
    final reduced = Motion.reduced(context);

    return AuthPanel(
      title: title,
      subtitle: subtitle,
      onBack: switch (state) {
        RecoveryEmail() => null,
        RecoveryDone(:final email) => () => context.router.maybePop(email),
        _ => _controller.back,
      },
      children: [
        AnimatedSwitcher(
          duration: Motion.standard,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: reduced
                ? child
                : SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
          ),
          child: KeyedSubtree(key: ValueKey(state.runtimeType), child: content),
        ),
      ],
    );
  }

  Widget _emailStep(Translations t, RecoveryEmail state) {
    final errors = t.auth.fieldErrors;
    final failure = state.failure;
    final message = switch (failure) {
      NotFoundFailure() => t.auth.recover.email.notFound,
      _ when !_triedEmail => null,
      _ => switch (Validators.email(_email.text)) {
        null => null,
        .required => errors.emailRequired,
        .tooLong => errors.emailTooLong(max: Validators.maxEmailLength),
        _ => errors.emailInvalid,
      },
    };
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        EcoTextField(
          label: t.auth.recover.email.field,
          controller: _email,
          error: message,
          enabled: !state.sending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _sendCode(),
        ),
        FormMessage(
          failure == null || failure is NotFoundFailure
              ? null
              : failureMessage(failure, t),
        ),
        const SizedBox(height: Space.lg),
        _action(
          t.auth.recover.email.submit,
          onPressed: _sendCode,
          loading: state.sending,
          blockedUntil: state.blockedUntil,
        ),
      ],
    );
  }

  Widget _codeStep(Translations t, RecoveryCode state) {
    final copy = t.auth.recover.code;
    final expired = state.issue == .expired || !_before(state.expiresAt);
    final usable = !expired && state.issue != .locked;
    final failure = state.failure;
    void refresh() => setState(() {});

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Shake(
          trigger: _rejections == 0 ? null : _rejections,
          // The field plays its own haptic when it is told it was wrong.
          haptic: false,
          child: OtpField(
            // A new code starts on a fresh, empty field.
            key: ValueKey(state.expiresAt),
            semanticsLabel: copy.field,
            error: state.issue == .rejected || state.issue == .locked,
            enabled: usable && !state.verifying && !_before(state.blockedUntil),
            onCompleted: _controller.verify,
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: switch (state.issue) {
                _ when expired => _status(copy.expired, alert: true),
                .locked => _status(copy.locked, alert: true),
                .rejected => _status(
                  copy.rejected(n: state.attemptsLeft),
                  alert: true,
                ),
                _ => Countdown(
                  until: state.expiresAt,
                  onDone: refresh,
                  builder: (context, left) =>
                      _status(copy.expiresIn(time: Countdown.format(left))),
                ),
              },
            ),
            if (state.verifying || state.resending)
              const PlateSpinner(size: 18),
          ],
        ),
        FormMessage(failure == null ? null : failureMessage(failure, t)),
        const SizedBox(height: Space.lg),
        if (_before(state.resendAt))
          Countdown(
            until: state.resendAt,
            onDone: refresh,
            builder: (context, left) =>
                _status(copy.resendIn(time: Countdown.format(left))),
          )
        else
          Align(
            alignment: .centerLeft,
            child: TextLink(
              label: copy.resend,
              onPressed: state.resending ? null : _controller.resend,
            ),
          ),
        Align(
          alignment: .centerLeft,
          child: TextLink(label: copy.changeEmail, onPressed: _controller.back),
        ),
      ],
    );
  }

  Widget _passwordStep(Translations t, RecoveryPassword state) {
    final copy = t.auth.recover.password;
    final errors = t.auth.fieldErrors;
    final spanish = t.$meta.locale == AppLocale.es;
    // A 400 here always names the password: one without fields sent the flow
    // back to the code step.
    final refusal = switch (state.failure) {
      ValidationFailure(:final fieldErrors) =>
        (spanish ? fieldErrors['newPassword'] : null) ?? t.errors.validation,
      _ => null,
    };
    final passwordMessage =
        refusal ??
        (!_triedPassword
            ? null
            : switch (Validators.newPassword(_password.text)) {
                null => null,
                .required => errors.passwordRequired,
                .tooShort => errors.passwordTooShort(
                  min: Validators.minPasswordLength,
                ),
                _ => errors.passwordTooLong,
              });
    final confirmationMessage = !_triedPassword
        ? null
        : switch (Validators.confirmation(_password.text, _confirmation.text)) {
            null => null,
            .required => errors.confirmationRequired,
            _ => errors.confirmationMismatch,
          };
    final failure = state.failure;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        EcoTextField(
          label: copy.field,
          controller: _password,
          error: passwordMessage,
          enabled: !state.saving,
          obscureText: _hidden,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
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
        const SizedBox(height: Space.lg),
        EcoTextField(
          label: copy.confirmation,
          controller: _confirmation,
          error: confirmationMessage,
          enabled: !state.saving,
          obscureText: _hidden,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        FormMessage(
          failure == null || failure is ValidationFailure
              ? null
              : failureMessage(failure, t),
        ),
        const SizedBox(height: Space.lg),
        _action(
          copy.submit,
          onPressed: _save,
          loading: state.saving,
          blockedUntil: state.blockedUntil,
        ),
      ],
    );
  }

  Widget _doneStep(Translations t, RecoveryDone state) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const Center(child: _DrawnCheck()),
        const SizedBox(height: Space.xl),
        EcoButton(
          label: t.auth.recover.done.action,
          onPressed: () => context.router.maybePop(state.email),
        ),
      ],
    );
  }

  /// The main action of a step, or its 429 countdown while it is blocked.
  Widget _action(
    String label, {
    required VoidCallback onPressed,
    required bool loading,
    required DateTime? blockedUntil,
  }) {
    if (blockedUntil != null && _before(blockedUntil)) {
      return Countdown(
        until: blockedUntil,
        onDone: () => setState(() {}),
        builder: (context, left) => EcoButton(
          label: context.t.common.retryIn(time: Countdown.format(left)),
          icon: const Icon(EcoIcons.clockCountdown, size: 20),
        ),
      );
    }
    return EcoButton(label: label, loading: loading, onPressed: onPressed);
  }

  Widget _status(String text, {bool alert = false}) {
    final palette = context.palette;
    return Semantics(
      liveRegion: alert,
      child: Text(
        text,
        style: EcoType.bodySmall.copyWith(
          color: alert ? palette.achiote : palette.muted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A circle closes and a check is drawn inside it, the way a pen would; with
/// reduced motion it is already drawn.
class _DrawnCheck extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final color = context.palette.aguacate;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: Motion.reduced(context) ? 1 : 0, end: 1),
      duration: Motion.signature,
      curve: Curves.easeInOutCubic,
      builder: (context, progress, _) => CustomPaint(
        key: RecoverPage.checkKey,
        size: const Size.square(88),
        painter: _CheckPainter(progress: progress, color: color),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const new({required this.progress, required this.color});

  /// The circle takes the first part of the stroke, the check the rest.
  static const _circleShare = 0.6;

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final circle = (progress / _circleShare).clamp(0.0, 1.0);
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      circle * math.pi * 2,
      false,
      pen,
    );

    final check = ((progress - _circleShare) / (1 - _circleShare)).clamp(
      0.0,
      1.0,
    );
    if (check == 0) return;
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.45, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.38);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * check), pen);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
