import 'dart:async';

import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/design/widgets/mask_reveal_text.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/widgets.dart';

/// Every design component, in sections, with the app's own copy. Section
/// names and demo controls are for designers and stay in English.
class GallerySections extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final palette = context.palette;
    final format = Formatters(t.$meta.locale.languageCode);
    final headline = t.auth.welcome.headline;

    return Column(
      crossAxisAlignment: .start,
      children: [
        _Section('Type', [
          Text(
            headline,
            style: EcoType.displayWonk.copyWith(color: palette.ink),
          ),
          Text(
            t.dishes.featured.title,
            style: EcoType.headline.copyWith(color: palette.ink),
          ),
          Text(
            t.discover.title,
            style: EcoType.title.copyWith(color: palette.ink),
          ),
          Text(
            t.auth.welcome.subline,
            style: EcoType.body.copyWith(color: palette.ink),
          ),
          Text(
            t.profile.signOut.message,
            style: EcoType.bodySmall.copyWith(color: palette.muted),
          ),
          Text(
            '${format.price(28000)} · ${format.rating(4.9)}',
            style: EcoType.numeric.copyWith(color: palette.ink),
          ),
          Text(
            t.discover.featured.toUpperCase(),
            style: EcoType.overline.copyWith(color: palette.achiote),
          ),
        ]),
        _Section('Buttons', [
          EcoButton(label: t.auth.welcome.signIn, onPressed: () {}),
          EcoButton(
            label: t.auth.welcome.createAccount,
            variant: .secondary,
            onPressed: () {},
          ),
          EcoButton(
            label: t.common.actions.back,
            variant: .quiet,
            onPressed: () {},
          ),
          EcoButton(label: t.auth.login.submit),
          const _ButtonCycle(),
        ]),
        _Section('Fields', [
          EcoTextField(label: t.auth.login.email, hint: 'ana@ecoeats.co'),
          EcoTextField(
            label: t.auth.login.password,
            obscureText: true,
            error: t.auth.fieldErrors.passwordTooShort(min: 6),
          ),
          EcoTextField(label: t.auth.register.about.document, enabled: false),
        ]),
        _Section('Selection', [
          const _PillsDemo(),
          for (final rating in [4.7, 4.5, 3.2])
            Row(
              spacing: Space.xs,
              children: [
                RatingStars(rating: rating, size: 18),
                Text(
                  format.rating(rating),
                  style: EcoType.bodySmall.copyWith(color: palette.muted),
                ),
              ],
            ),
        ]),
        _Section('Feedback', [
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final (tone, message) in [
                (ToastTone.neutral, t.errors.validation),
                (ToastTone.success, t.auth.recover.code.resent),
                (ToastTone.alert, t.errors.sessionExpired),
              ])
                EcoButton(
                  label: 'Toast · ${tone.name}',
                  variant: .secondary,
                  expand: false,
                  onPressed: () => Toast.show(context, message, tone: tone),
                ),
            ],
          ),
          const _ShakeDemo(),
        ]),
        _Section('Media', [
          Row(
            spacing: Space.sm,
            children: [
              for (final name in ['Bandeja Paisa', 'Ajiaco', 'Arroz con Coco'])
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: DishImage(
                      url: null,
                      name: name,
                      borderRadius: const BorderRadius.all(.circular(Radii.lg)),
                    ),
                  ),
                ),
            ],
          ),
        ]),
        const _Section('Loading', [
          Row(
            spacing: Space.lg,
            children: [
              PlateSpinner(size: 32),
              PlateSpinner(size: 32, progress: 0.6),
              _MarkDemo(),
            ],
          ),
          Skeleton(height: 120, radius: Radii.lg),
          Skeleton(width: 180, height: 16),
          Skeleton(width: 120, height: 12),
        ]),
        _Section('Drawings', [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final (detail, accent) in [
                (PlateDetail.leaf, palette.aguacate),
                (PlateDetail.crumbs, palette.panela),
                (PlateDetail.smoke, palette.achiote),
                (PlateDetail.cutCord, palette.ink),
                (PlateDetail.hourglass, palette.maiz),
              ])
                PlateIllustration(
                  size: 64,
                  detail: detail,
                  accent: accent,
                  progress: 0.6,
                ),
            ],
          ),
        ]),
        _Section('States', [
          for (final kind in StateKind.values)
            SizedBox(height: 400, child: _StateDemo(kind: kind)),
        ]),
        _Section('Motion', [_HeadlineDemo(headline: headline)]),
        _Section('Paper', [
          SizedBox(
            height: 120,
            child: GrainOverlay(
              opacity: 0.08,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.raised,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: const BorderRadius.all(.circular(Radii.lg)),
                    side: BorderSide(color: palette.line),
                  ),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: Space.xxl),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: Space.sm,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Space.xl),
          child: Text(
            title.toUpperCase(),
            style: EcoType.overline.copyWith(color: context.palette.muted),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A demo control: small, quiet, and in the designers' language.
class _Replay extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: EcoButton(
      label: label,
      variant: .quiet,
      expand: false,
      onPressed: onPressed,
    ),
  );
}

enum _Phase { idle, loading, success }

/// The main button's whole life: waits, succeeds, and rests again.
class _ButtonCycle extends StatefulWidget {
  const new();

  @override
  State<_ButtonCycle> createState() => _ButtonCycleState();
}

class _ButtonCycleState extends State<_ButtonCycle> {
  _Phase _phase = .idle;
  Timer? _next;

  void _go(_Phase phase, Duration after) {
    _next?.cancel();
    _next = Timer(after, () {
      if (mounted) setState(() => _phase = phase);
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EcoButton(
      label: context.t.auth.login.submit,
      loading: _phase == .loading,
      success: _phase == .success,
      onSuccess: () => _go(.idle, const Duration(seconds: 1)),
      onPressed: _phase == .idle
          ? () {
              setState(() => _phase = .loading);
              _go(.success, const Duration(milliseconds: 1400));
            }
          : null,
    );
  }
}

class _PillsDemo extends StatefulWidget {
  const new();

  @override
  State<_PillsDemo> createState() => _PillsDemoState();
}

class _PillsDemoState extends State<_PillsDemo> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final filters = context.t.dishes.filters;
    final labels = [
      filters.all,
      filters.featured,
      filters.highProtein,
      filters.light,
    ];
    return SegmentedPills<int>(
      values: [for (var index = 0; index < labels.length; index++) index],
      selected: _selected,
      labelOf: (index) => labels[index],
      onChanged: (index) => setState(() => _selected = index),
      padding: EdgeInsets.zero,
    );
  }
}

class _ShakeDemo extends StatefulWidget {
  const new();

  @override
  State<_ShakeDemo> createState() => _ShakeDemoState();
}

class _ShakeDemoState extends State<_ShakeDemo> {
  var _refusals = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Shake(
          trigger: _refusals == 0 ? null : _refusals,
          child: EcoTextField(
            label: t.auth.login.email,
            error: t.auth.login.wrongCredentials,
          ),
        ),
        _Replay(label: 'Shake', onPressed: () => setState(() => _refusals++)),
      ],
    );
  }
}

/// The mark drawing itself; a tap draws it again.
class _MarkDemo extends StatefulWidget {
  const new();

  @override
  State<_MarkDemo> createState() => _MarkDemoState();
}

class _MarkDemoState extends State<_MarkDemo> {
  var _round = 0;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Draw the mark again',
      onPressed: () => setState(() => _round++),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_round),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (context, progress, _) =>
            LogoMark(size: 56, progress: progress),
      ),
    );
  }
}

class _StateDemo extends StatelessWidget {
  const new({required this.kind});

  final StateKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final errors = t.errors;
    String wait(Duration left) {
      final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
      return t.common.retryIn(time: '${left.inMinutes}:$seconds');
    }

    return switch (kind) {
      .empty => StateView(
        kind: kind,
        title: t.discover.empty.title,
        message: t.discover.empty.message,
        actionLabel: t.common.actions.back,
        onAction: () {},
      ),
      .error => StateView(
        kind: kind,
        title: errors.server.title,
        message: errors.server.message,
        footnote: errors.server.reference(id: 'a1b2'),
        actionLabel: t.common.actions.retry,
        onAction: () {},
      ),
      .offline => StateView(
        kind: kind,
        title: errors.offline.title,
        message: errors.offline.message,
        actionLabel: t.common.actions.retry,
        onAction: () {},
      ),
      .rateLimited => StateView(
        kind: kind,
        title: errors.rateLimited.title,
        message: errors.rateLimited.message,
        actionLabel: t.common.actions.retry,
        onAction: () {},
        cooldown: const Duration(seconds: 42),
        cooldownLabel: wait,
      ),
    };
  }
}

class _HeadlineDemo extends StatefulWidget {
  const new({required this.headline});

  final String headline;

  @override
  State<_HeadlineDemo> createState() => _HeadlineDemoState();
}

class _HeadlineDemoState extends State<_HeadlineDemo> {
  var _round = 0;

  @override
  Widget build(BuildContext context) {
    // One line per clause, as the welcome sets it.
    final lines = widget.headline.split(RegExp(r'(?<=,)\s+'));
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        MaskRevealText(
          key: ValueKey('$_round-${widget.headline}'),
          lines: lines,
          style: EcoType.displayWonk.copyWith(color: context.palette.ink),
        ),
        _Replay(label: 'Replay', onPressed: () => setState(() => _round++)),
      ],
    );
  }
}
