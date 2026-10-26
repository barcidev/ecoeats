import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The profile, as a sheet over the current screen. Home's avatar opens it;
/// this phase 0 version shows the session and signs out, and agent A adds
/// appearance, language and the sign-out confirmation.
abstract final class ProfileSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _ProfileSheetBody(),
    );
  }
}

class _ProfileSheetBody extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.profile;
    final palette = context.palette;
    final session = ref.watch(sessionControllerProvider).value;
    final now = ref.watch(clockProvider)();

    return Padding(
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
            if (session.firstNames case final name?)
              Text(
                name,
                style: EcoType.titleSmall.copyWith(color: palette.ink),
              ),
            Text(
              session.email,
              style: EcoType.body.copyWith(color: palette.muted),
            ),
            const SizedBox(height: Space.xs),
            Text(
              t.sessionEndsIn(hours: session.remainingAt(now).inHours),
              style: EcoType.bodySmall.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: Space.xl),
          EcoButton(
            label: t.signOut.action,
            variant: .secondary,
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(sessionControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
