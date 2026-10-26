import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/widgets.dart';

/// Every bar shares this scale, so two dishes compare at a glance.
const _scaleGrams = 100;

/// Carbohydrates and protein as bars that fill while their figures count up.
/// The API gives no calories, and the app does not make them up.
class MacroBars extends StatelessWidget {
  const new({required this.carbohydrates, required this.proteins, super.key});

  final int carbohydrates;
  final int proteins;

  @override
  Widget build(BuildContext context) {
    final t = context.t.dishes.detail;
    final palette = context.palette;
    return Column(
      children: [
        _MacroBar(
          label: t.carbohydrates,
          grams: carbohydrates,
          color: palette.maiz,
          start: 0,
        ),
        const SizedBox(height: Space.lg),
        _MacroBar(
          label: t.proteins,
          grams: proteins,
          color: palette.aguacate,
          start: 0.12,
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const new({
    required this.label,
    required this.grams,
    required this.color,
    required this.start,
  });

  final String label;
  final int grams;
  final Color color;

  /// Where in the shared animation this bar begins, so they fill one after
  /// the other.
  final double start;

  @override
  Widget build(BuildContext context) {
    final t = context.t.dishes.detail;
    final palette = context.palette;
    final still = Motion.reduced(context);
    return Semantics(
      label: t.macro(name: label, grams: grams),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: still ? Duration.zero : Motion.signature,
        curve: Interval(start, 1, curve: Motion.emphasized),
        builder: (context, progress, _) => Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: EcoType.label.copyWith(color: palette.ink),
                  ),
                ),
                Text(
                  t.grams(grams: (grams * progress).round()),
                  style: EcoType.numeric.copyWith(color: palette.ink),
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Container(
              height: 8,
              decoration: ShapeDecoration(
                color: palette.line,
                shape: const StadiumBorder(),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (grams / _scaleGrams).clamp(0.0, 1.0) * progress,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: color,
                    shape: const StadiumBorder(),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
