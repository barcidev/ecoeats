import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/features/auth/application/validators.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:material_ui/material_ui.dart';

/// The rules of a new password, checked live under its field. The length
/// rule waits to be met; the byte rule holds until the password breaks it.
class PasswordRules extends StatelessWidget {
  const new({required this.password, super.key});

  final String password;

  /// Past this many bytes the hint explains why accents and emoji weigh more,
  /// before the limit is reached.
  static const _hintFrom = 60;

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.password;
    final palette = context.palette;
    final rules = PasswordChecklist.of(password);
    return Column(
      crossAxisAlignment: .start,
      children: [
        _Rule(
          label: t.minLength(min: Validators.minPasswordLength),
          state: rules.hasMinLength ? .met : .pending,
        ),
        const SizedBox(height: Space.xs),
        _Rule(label: t.maxBytes, state: rules.fitsInBytes ? .met : .broken),
        AnimatedSize(
          duration: Motion.quick,
          curve: Motion.emphasized,
          alignment: .topLeft,
          child: rules.bytes < _hintFrom
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(left: 26, top: Space.xxs),
                  child: Text(
                    t.maxBytesHint,
                    style: EcoType.bodySmall.copyWith(
                      color: rules.fitsInBytes
                          ? palette.muted
                          : palette.achiote,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

enum _RuleState { met, pending, broken }

class _Rule extends StatelessWidget {
  const new({required this.label, required this.state});

  final String label;
  final _RuleState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth.password;
    final palette = context.palette;
    final color = switch (state) {
      .met => palette.aguacate,
      .pending => palette.muted,
      .broken => palette.achiote,
    };
    // Its own node, so a form around it does not merge the rules together.
    return Semantics(
      container: true,
      label: '$label, ${state == .met ? t.met : t.missing}',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: AnimatedSwitcher(
              duration: Motion.reduced(context) ? Duration.zero : Motion.quick,
              child: switch (state) {
                .met => Icon(
                  EcoIcons.check,
                  key: const ValueKey(_RuleState.met),
                  size: 18,
                  color: color,
                ),
                .broken => Icon(
                  EcoIcons.x,
                  key: const ValueKey(_RuleState.broken),
                  size: 18,
                  color: color,
                ),
                .pending => Center(
                  key: const ValueKey(_RuleState.pending),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: CircleBorder(side: BorderSide(color: color)),
                    ),
                    child: const SizedBox.square(dimension: 10),
                  ),
                ),
              },
            ),
          ),
          const SizedBox(width: Space.xs),
          Text(
            label,
            style: EcoType.bodySmall.copyWith(
              color: state == .pending ? palette.muted : palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
