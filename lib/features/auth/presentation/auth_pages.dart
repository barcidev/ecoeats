import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Phase 0 placeholders. They keep the routes alive until agent A replaces
// them; only the login works, so the catalog can be reached.

/// Hosts the auth pages over one background that stays put between them.
@RoutePage()
class AuthShellPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.paper,
      child: const GrainOverlay(child: AutoRouter()),
    );
  }
}

@RoutePage()
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.welcome;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Spacer(),
              const LogoMark(size: 72),
              const SizedBox(height: Space.lg),
              Text(
                t.headline,
                style: EcoType.displayWonk.copyWith(color: palette.ink),
              ),
              const Spacer(),
              EcoButton(
                label: t.signIn,
                onPressed: () => context.router.pushPath('/auth/login'),
              ),
              const SizedBox(height: Space.sm),
              EcoButton(
                label: t.createAccount,
                variant: .secondary,
                onPressed: () => context.router.pushPath('/auth/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Success needs no navigation: the guards follow the session to Home.
  Future<void> _submit() async {
    final t = context.t;
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      final message = failure is UnauthorizedFailure
          ? t.auth.login.wrongCredentials
          : failureMessage(failure, t);
      Toast.show(context, message, tone: .alert);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.login;
    return _AuthPanel(
      title: t.title,
      children: [
        EcoTextField(
          label: t.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: Space.lg),
        EcoTextField(
          label: t.password,
          controller: _password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Space.xl),
        EcoButton(label: t.submit, loading: _loading, onPressed: _submit),
      ],
    );
  }
}

@RoutePage()
class RegisterPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      _AuthPanel(title: context.t.auth.register.title, children: const []);
}

@RoutePage()
class RecoverPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      _AuthPanel(title: context.t.auth.recover.title, children: const []);
}

class _AuthPanel extends StatelessWidget {
  const new({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  semanticLabel: context.t.common.actions.back,
                  onPressed: () => context.router.maybePop(),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.xs),
                    child: Icon(EcoIcons.arrowLeft, color: palette.ink),
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(title, style: EcoType.headline.copyWith(color: palette.ink)),
              const SizedBox(height: Space.xl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
