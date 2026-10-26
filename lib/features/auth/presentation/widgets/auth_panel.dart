import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The sheet every auth panel sits in. It rises over the shell's backdrop and
/// leaves the photo visible above its top edge; [footer] rests at the bottom
/// when the content is short.
class AuthPanel extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    this.overline,
    this.subtitle,
    this.footer,
    this.onBack,
    super.key,
  });

  final String title;
  final List<Widget> children;

  /// Small capitals above the title, such as the step of a flow.
  final String? overline;
  final String? subtitle;
  final Widget? footer;

  /// Defaults to leaving the panel.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 40),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.raised,
          shape: const RoundedSuperellipseBorder(
            borderRadius: .vertical(top: .circular(Radii.lg)),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            top: false,
            child: AutofillGroup(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(Space.gutter),
                    sliver: SliverList.list(
                      children: [
                        _header(context, palette),
                        const SizedBox(height: Space.xl),
                        ...children,
                      ],
                    ),
                  ),
                  if (footer case final footer?)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          0,
                          Space.gutter,
                          Space.lg,
                        ),
                        child: Align(alignment: .bottomCenter, child: footer),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, EcoPalette palette) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Pressable(
          semanticLabel: context.t.common.actions.back,
          onPressed: onBack ?? () => context.router.maybePop(),
          child: Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: Icon(EcoIcons.arrowLeft, color: palette.ink),
          ),
        ),
        const SizedBox(height: Space.lg),
        if (overline case final overline?) ...[
          Text(
            overline.toUpperCase(),
            style: EcoType.overline.copyWith(color: palette.muted),
          ),
          const SizedBox(height: Space.xs),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: EcoType.headline.copyWith(color: palette.ink),
          ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: Space.xs),
          Text(subtitle, style: EcoType.body.copyWith(color: palette.muted)),
        ],
      ],
    );
  }
}

/// Rebuilds once a second with the time left until [until], and calls
/// [onDone] once when it runs out. Time comes from the app's clock, so tests
/// move it by hand.
class Countdown extends ConsumerStatefulWidget {
  const new({
    required this.until,
    required this.builder,
    this.onDone,
    super.key,
  });

  final DateTime until;
  final Widget Function(BuildContext context, Duration left) builder;
  final VoidCallback? onDone;

  /// «0:42», «14:59»: minutes without padding, rounded up to the second so
  /// the last second still reads «0:01».
  static String format(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil().clamp(0, 359999);
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  ConsumerState<Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<Countdown> {
  Timer? _tick;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didUpdateWidget(Countdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.until != oldWidget.until) _done = false;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(ref.read(clockProvider)());
    if (left <= Duration.zero && !_done) {
      _done = true;
      // Reported after this frame: the callback usually rebuilds the parent.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
    }
    return widget.builder(context, left.isNegative ? Duration.zero : left);
  }
}

/// One line under the form for what the API answered, announced to screen
/// readers when it appears.
class FormMessage extends StatelessWidget {
  const new(this.message, {super.key});

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

/// The eye at the end of a password field: it says what tapping it will do,
/// show or hide what was typed.
class PasswordToggle extends StatelessWidget {
  const new({required this.hidden, required this.onToggle, super.key});

  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.password;
    return Pressable(
      semanticLabel: hidden ? t.show : t.hide,
      onPressed: onToggle,
      child: Icon(
        hidden ? EcoIcons.eye : EcoIcons.eyeSlash,
        size: 20,
        color: context.palette.muted,
      ),
    );
  }
}

/// A quiet, underlined action inside a panel.
class TextLink extends StatelessWidget {
  const new({required this.label, required this.onPressed, super.key});

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

/// A question and its link at the foot of a panel, such as «¿No tienes cuenta?
/// Crear una».
class PanelFooter extends StatelessWidget {
  const new({
    required this.question,
    required this.action,
    required this.onPressed,
    super.key,
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
        TextLink(label: action, onPressed: onPressed),
      ],
    );
  }
}
