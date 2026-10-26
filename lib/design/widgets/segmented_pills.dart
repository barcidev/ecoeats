import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter/widgets.dart';

/// A single choice among a few values, as a row of pills that scrolls
/// sideways when it does not fit.
class SegmentedPills<T> extends StatelessWidget {
  const new({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.gutter),
    super.key,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value) labelOf;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: padding,
      child: Row(
        spacing: Space.xs,
        children: [
          for (final value in values)
            _Pill(
              label: labelOf(value),
              selected: value == selected,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: Pressable(
          onPressed: onTap,
          child: AnimatedContainer(
            duration: Motion.quick,
            curve: Motion.emphasized,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            decoration: ShapeDecoration(
              color: selected ? palette.ink : palette.paper,
              shape: StadiumBorder(
                side: BorderSide(color: selected ? palette.ink : palette.line),
              ),
            ),
            child: Text(
              label,
              style: EcoType.label.copyWith(
                color: selected ? palette.paper : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
