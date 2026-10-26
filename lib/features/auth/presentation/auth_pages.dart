import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/design/widgets/mask_reveal_text.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/features/auth/presentation/widgets/auth_panel.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// The login, register and recover pages are still phase 0 placeholders; each
// one moves to its own file when agent A builds it.

/// Hosts the auth pages over one living backdrop that never restarts between
/// them; while a panel is open, the photo steps back behind it.
@RoutePage()
class AuthShellPage extends StatelessWidget {
  const new({super.key});

  @visibleForTesting
  static const backdropKey = Key('auth-backdrop');

  @visibleForTesting
  static const photoKey = Key('auth-backdrop-photo');

  @visibleForTesting
  static const shadeKey = Key('auth-backdrop-shade');

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == .light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The top scrim keeps the photo dark under the status bar in both
      // themes; the bottom fades into paper, so that bar follows the theme.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: light ? .dark : .light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: GrainOverlay(
        child: AutoRouter(
          builder: (context, content) => Stack(
            fit: .expand,
            children: [
              _AuthBackdrop(
                key: backdropKey,
                receded: context.router.pageCount > 1,
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dishes from the API seed. Each one zooms and drifts slowly, then
/// crossfades into the next; [receded] shrinks and darkens the photo the way
/// a card steps back under a sheet.
class _AuthBackdrop extends StatefulWidget {
  const new({required this.receded, super.key});

  final bool receded;

  @override
  State<_AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<_AuthBackdrop>
    with SingleTickerProviderStateMixin {
  static const _photos = [
    'assets/photos/ajiaco.jpg',
    'assets/photos/sancocho.jpg',
    'assets/photos/arroz_atollado.jpg',
  ];

  // Where each photo drifts from and to, so consecutive ones move apart.
  static const _drift = [
    (Alignment(-0.4, -0.3), Alignment(0.3, 0.2)),
    (Alignment(0.4, 0.2), Alignment(-0.2, -0.3)),
    (Alignment(0, 0.4), Alignment(0, -0.3)),
  ];

  static const _cycleLength = Duration(seconds: 7);

  /// The last part of each cycle, when the next photo fades in over it.
  static const _handover = 0.18;

  // Two rounds through the photos, then the first one rests: an endless loop
  // would keep the GPU busy for someone who left the app on the welcome.
  static const _rounds = 2;

  // The photo holds still while the welcome plays its intro (1380 ms) and a
  // beat after it: one movement at a time.
  static const _stillAtFirst = Duration(milliseconds: 1700);

  static const _depthScale = 0.06;
  static const _depthShade = 0.45;

  // What shows around the photo when it shrinks: the stove, in both themes.
  static final Color _behind = EcoPalette.fogon.paper;

  late final _cycle = AnimationController(vsync: this, duration: _cycleLength)
    ..addStatusListener(_onCycleEnd);
  var _index = 0;
  var _cycles = 0;
  Timer? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final photo in _photos) {
      unawaited(precacheImage(_image(photo), context));
    }
    _start ??= Timer(_stillAtFirst, _cycle.forward);
  }

  @override
  void dispose() {
    _start?.cancel();
    _cycle.dispose();
    super.dispose();
  }

  void _onCycleEnd(AnimationStatus status) {
    if (status != .completed) return;
    _cycles++;
    setState(() => _index = (_index + 1) % _photos.length);
    if (_cycles < _photos.length * _rounds) {
      _cycle.forward(from: 0);
    } else {
      _cycle.value = 0;
    }
  }

  // Decoded at the screen's width plus the zoom's margin, never larger than
  // the file: three full photos at native size would waste memory.
  ImageProvider _image(String photo) {
    final pixels =
        MediaQuery.sizeOf(context).width *
        MediaQuery.devicePixelRatioOf(context);
    final width = (pixels * 1.15).round();
    return ResizeImage(AssetImage(photo), width: math.min(width, 1000));
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.receded ? 1 : 0),
      duration: Motion.slow,
      curve: Motion.emphasized,
      child: Stack(
        fit: .expand,
        children: [
          AnimatedBuilder(
            animation: _cycle,
            builder: (context, _) => _photosAt(_cycle.value, reduced: reduced),
          ),
          const _Scrim(),
        ],
      ),
      builder: (context, depth, photos) => ColoredBox(
        color: _behind,
        child: Transform.scale(
          key: AuthShellPage.photoKey,
          scale: reduced ? 1 : 1 - _depthScale * depth,
          child: ClipRSuperellipse(
            borderRadius: .circular(reduced ? 0 : Radii.lg * depth),
            clipBehavior: depth == 0 ? .none : .antiAlias,
            child: Stack(
              fit: .expand,
              children: [
                photos!,
                ColoredBox(
                  key: AuthShellPage.shadeKey,
                  color: Colors.black.withValues(alpha: _depthShade * depth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Both photos stay in the tree under keyed opacities, so the incoming one
  // keeps its decoded image when it becomes the current one.
  Widget _photosAt(double t, {required bool reduced}) {
    final next = (_index + 1) % _photos.length;
    final handover = ((t - (1 - _handover)) / _handover).clamp(0.0, 1.0);
    return Stack(
      fit: .expand,
      children: [
        for (final (index, opacity, progress) in [
          (_index, 1.0, reduced ? 0.0 : t),
          (next, Curves.easeInOut.transform(handover), 0.0),
        ])
          Opacity(
            key: ValueKey(_photos[index]),
            opacity: opacity,
            child: _photo(index, progress),
          ),
      ],
    );
  }

  Widget _photo(int index, double progress) {
    final (from, to) = _drift[index];
    return Transform.scale(
      scale: 1.04 + 0.08 * progress,
      alignment: .lerp(from, to, progress),
      child: Image(
        image: _image(_photos[index]),
        fit: .cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Darkens the top for the status bar and lets the photo settle into paper
/// at the bottom, where the welcome's words and actions sit.
class _Scrim extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final paper = context.palette.paper;
    return Stack(
      fit: .expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: .topCenter,
              end: Alignment(0, -0.5),
              colors: [Color(0x8C000000), Color(0x00000000)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: .topCenter,
              end: .bottomCenter,
              colors: [
                paper.withValues(alpha: 0),
                paper.withValues(alpha: 0),
                paper.withValues(alpha: 0.9),
                paper,
              ],
              stops: const [0, 0.3, 0.64, 0.82],
            ),
          ),
        ),
      ],
    );
  }
}

/// The first screen a guest sees: the mark draws its plate rim over the
/// photo, the headline rises line by line, and then the two ways in arrive.
@RoutePage()
class WelcomePage extends StatefulWidget {
  const new({super.key});

  @visibleForTesting
  static const actionsKey = Key('welcome-actions');

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  // One timeline for the whole intro, so the pieces keep their order.
  late final _intro = AnimationController(
    vsync: this,
    duration: Motion.signature + Motion.slow,
  );
  late final _rim = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.65, curve: Curves.easeInOutCubic),
  );
  late final CurvedAnimation _subline = _arrival(0.5, 0.85);
  late final CurvedAnimation _actions = _arrival(0.62, 1);

  // The headline starts while the rim is still closing.
  static const _headlineDelay = Duration(milliseconds: 300);

  // Over the darkened top of the photo the mark wears the night palette.
  static const EcoPalette _overPhoto = .fogon;

  CurvedAnimation _arrival(double begin, double end) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: Motion.emphasized),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.value > 0 || _intro.isAnimating) return;
    if (Motion.reduced(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Widget _rise(Animation<double> arrival, Widget child, {Key? key}) {
    return FadeTransition(
      key: key,
      opacity: arrival,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(arrival),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.welcome;
    final palette = context.palette;
    // «Comida colombiana, sin afán.» breaks after its comma in both languages.
    final lines = t.headline.split(RegExp(r'(?<=,)\s+'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.gutter,
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Semantics(
                header: true,
                label: context.t.common.appName,
                excludeSemantics: true,
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _rim,
                      builder: (context, _) => LogoMark(
                        size: 40,
                        progress: _rim.value,
                        color: _overPhoto.ink,
                        accent: _overPhoto.aguacate,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    FadeTransition(
                      opacity: _rim,
                      child: Text(
                        context.t.common.appName,
                        style: EcoType.title.copyWith(color: _overPhoto.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              MaskRevealText(
                lines: lines,
                delay: _headlineDelay,
                style: EcoType.displayWonk.copyWith(color: palette.ink),
              ),
              const SizedBox(height: Space.sm),
              _rise(
                _subline,
                Text(
                  t.subline,
                  style: EcoType.body.copyWith(color: palette.muted),
                ),
              ),
              const SizedBox(height: Space.xl),
              _rise(
                _actions,
                key: WelcomePage.actionsKey,
                Column(
                  children: [
                    EcoButton(
                      label: t.signIn,
                      onPressed: () => context.router.pushPath('login'),
                    ),
                    const SizedBox(height: Space.sm),
                    EcoButton(
                      label: t.createAccount,
                      variant: .secondary,
                      onPressed: () => context.router.pushPath('register'),
                    ),
                  ],
                ),
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
    return AuthPanel(
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
      AuthPanel(title: context.t.auth.register.title, children: const []);
}

@RoutePage()
class RecoverPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      AuthPanel(title: context.t.auth.recover.title, children: const []);
}
