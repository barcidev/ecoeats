import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter/widgets.dart';

enum EcoButtonVariant { primary, secondary, quiet }

class EcoButton extends StatelessWidget {
  const new({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = .primary,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;

  /// Null disables it.
  final VoidCallback? onPressed;

  /// Shows the spinner in place of the label and ignores taps.
  final bool loading;
  final EcoButtonVariant variant;
  final Widget? icon;

  /// Fills the available width, as the main action of a screen does.
  final bool expand;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onAchiote = Color.lerp(palette.paper, palette.raised, 0.5)!;
    final (background, foreground, border) = switch (variant) {
      .primary => (palette.achiote, onAchiote, null),
      .secondary => (null, palette.ink, palette.line),
      .quiet => (null, palette.ink, null),
    };
    final disabled = onPressed == null && !loading;

    final content = AnimatedSwitcher(
      duration: Motion.quick,
      child: loading
          ? PlateSpinner(
              key: const ValueKey('spinner'),
              size: 22,
              color: foreground,
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: .min,
              spacing: Space.xs,
              children: [
                ?icon,
                Text(label, style: EcoType.label.copyWith(color: foreground)),
              ],
            ),
    );

    return Pressable(
      onPressed: loading ? null : onPressed,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1,
        duration: Motion.quick,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: background,
            shape: RoundedSuperellipseBorder(
              borderRadius: const BorderRadius.all(.circular(Radii.md)),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
