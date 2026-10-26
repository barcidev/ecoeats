import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/features/profile/application/locale_controller.dart';
import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The profile, as a sheet over the current screen: who is signed in and
/// until when, the appearance and the language, and a sign-out that asks
/// first. Home's avatar opens it.
abstract final class ProfileSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      // Its own height, not the default 9/16: small phones need to scroll it.
      isScrollControlled: true,
      builder: (_) => const _ProfileSheetBody(),
    );
  }
}

class _ProfileSheetBody extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ProfileSheetBody> createState() => _ProfileSheetBodyState();
}

class _ProfileSheetBodyState extends ConsumerState<_ProfileSheetBody> {
  var _confirming = false;

  Future<void> _signOut() async {
    Navigator.of(context).pop();
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.profile;
    final palette = context.palette;
    final session = ref.watch(sessionControllerProvider).value;
    final themeMode = ref.watch(themeModeControllerProvider).value ?? .system;
    final language = ref.watch(localeControllerProvider).value ?? .system;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.gutter,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(t.title, style: EcoType.title.copyWith(color: palette.ink)),
          if (session != null) ...[
            const SizedBox(height: Space.lg),
            _Who(session: session),
          ],
          const SizedBox(height: Space.xl),
          _Overline(t.appearance.title),
          SegmentedPills<ThemeMode>(
            padding: EdgeInsets.zero,
            values: const [.system, .light, .dark],
            selected: themeMode,
            labelOf: (mode) => switch (mode) {
              .system => t.appearance.system,
              .light => t.appearance.light,
              .dark => t.appearance.dark,
            },
            onChanged: ref.read(themeModeControllerProvider.notifier).choose,
          ),
          const SizedBox(height: Space.lg),
          _Overline(t.language.title),
          SegmentedPills<LocaleChoice>(
            padding: EdgeInsets.zero,
            values: LocaleChoice.values,
            selected: language,
            // Each language in its own name, whatever the current one is.
            labelOf: (choice) => switch (choice) {
              .system => t.language.system,
              .spanish => t.language.spanish,
              .english => t.language.english,
            },
            onChanged: ref.read(localeControllerProvider.notifier).choose,
          ),
          const SizedBox(height: Space.xl),
          Divider(height: Space.hairline, color: palette.line),
          const SizedBox(height: Space.lg),
          AnimatedSwitcher(
            duration: Motion.standard,
            switchInCurve: Motion.emphasized,
            child: _confirming
                ? _Confirmation(
                    key: const ValueKey('confirm'),
                    onCancel: () => setState(() => _confirming = false),
                    onConfirm: _signOut,
                  )
                : EcoButton(
                    key: const ValueKey('sign-out'),
                    label: t.signOut.action,
                    variant: .secondary,
                    icon: const Icon(EcoIcons.signOut, size: 20),
                    onPressed: () => setState(() => _confirming = true),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The initial, the name when this device knows it, the email and how long
/// the session lasts.
class _Who extends ConsumerWidget {
  const new({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.profile;
    final palette = context.palette;
    final name = session.firstNames;
    final left = session.remainingAt(ref.watch(clockProvider)());
    final initial = (name ?? session.email).characters.first.toUpperCase();

    return Row(
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.achiote,
              shape: const CircleBorder(),
            ),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Text(
                  initial,
                  style: EcoType.title.copyWith(color: palette.raised),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              if (name != null)
                Text(
                  name,
                  style: EcoType.titleSmall.copyWith(color: palette.ink),
                ),
              Text(
                session.email,
                style: (name == null ? EcoType.titleSmall : EcoType.body)
                    .copyWith(
                      color: name == null ? palette.ink : palette.muted,
                    ),
              ),
              const SizedBox(height: Space.xxs),
              Text(
                left.inHours < 1
                    ? t.sessionEndsSoon
                    : t.sessionEndsIn(hours: left.inHours),
                style: EcoType.bodySmall.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Overline extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Text(
        text.toUpperCase(),
        style: EcoType.overline.copyWith(color: context.palette.muted),
      ),
    );
  }
}

/// The sign-out question in place of its button, so no dialog stacks over
/// the sheet.
class _Confirmation extends StatelessWidget {
  const new({required this.onCancel, required this.onConfirm, super.key});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          t.profile.signOut.confirm,
          style: EcoType.titleSmall.copyWith(color: palette.ink),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          t.profile.signOut.message,
          style: EcoType.bodySmall.copyWith(color: palette.muted),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: EcoButton(
                label: t.common.actions.cancel,
                variant: .secondary,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: EcoButton(
                label: t.profile.signOut.action,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
