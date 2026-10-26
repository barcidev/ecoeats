import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter/widgets.dart';

/// A single choice among a few values, as a row of pills that scrolls
/// sideways when it does not fit. One ink pill slides under the chosen value
/// and stretches to its size.
class SegmentedPills<T> extends StatefulWidget {
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

  @visibleForTesting
  static const ValueKey<String> indicatorKey = ValueKey(
    'segmented-pills-indicator',
  );

  @override
  State<SegmentedPills<T>> createState() => _SegmentedPillsState<T>();
}

class _SegmentedPillsState<T> extends State<SegmentedPills<T>> {
  final GlobalKey _row = GlobalKey();
  List<GlobalKey> _pills = [];

  /// Where the indicator rests, within the row; null until first measured.
  Rect? _indicator;

  @override
  void didUpdateWidget(SegmentedPills<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  /// Brings the chosen pill to the middle of the row when it scrolls.
  void _reveal() {
    final index = widget.values.indexOf(widget.selected);
    final pill = index < 0 ? null : _pills[index].currentContext;
    if (!mounted || pill == null) return;
    Scrollable.ensureVisible(
      pill,
      alignment: 0.5,
      duration: Motion.reduced(context) ? Duration.zero : Motion.standard,
      curve: Motion.emphasized,
    );
  }

  // The pills are laid out by their labels, so the indicator can only learn
  // its rect after a frame. It changes only when that rect does, so this
  // settles after one extra frame.
  void _measure() {
    if (!mounted) return;
    final index = widget.values.indexOf(widget.selected);
    final row = _row.currentContext?.findRenderObject() as RenderBox?;
    final pill = index < 0
        ? null
        : _pills[index].currentContext?.findRenderObject() as RenderBox?;
    final Rect? rect;
    if (row == null || pill == null || !pill.hasSize) {
      rect = null;
    } else {
      rect = pill.localToGlobal(Offset.zero, ancestor: row) & pill.size;
    }
    if (rect != _indicator) setState(() => _indicator = rect);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_pills.length != widget.values.length) {
      _pills = [for (final _ in widget.values) GlobalKey()];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final indicator = _indicator;
    final move = Motion.reduced(context) ? Duration.zero : Motion.standard;

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: widget.padding,
      child: Stack(
        key: _row,
        children: [
          if (indicator != null)
            AnimatedPositioned(
              key: SegmentedPills.indicatorKey,
              duration: move,
              curve: Motion.emphasized,
              left: indicator.left,
              top: indicator.top,
              width: indicator.width,
              height: indicator.height,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.ink,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          Row(
            spacing: Space.xs,
            children: [
              for (final (index, value) in widget.values.indexed)
                _Pill(
                  key: _pills[index],
                  label: widget.labelOf(value),
                  selected: value == widget.selected,
                  // Until the indicator knows where to go, the chosen pill
                  // paints its own ink, so its light label stays readable.
                  inked: value == widget.selected && indicator == null,
                  onTap: () => widget.onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.inked,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool inked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final change = Motion.reduced(context) ? Duration.zero : Motion.standard;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: Pressable(
          onPressed: onTap,
          child: AnimatedContainer(
            duration: change,
            curve: Motion.emphasized,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            decoration: ShapeDecoration(
              color: inked ? palette.ink : palette.ink.withValues(alpha: 0),
              shape: StadiumBorder(
                // The chosen pill's edge is the indicator's.
                side: BorderSide(
                  color: selected
                      ? palette.line.withValues(alpha: 0)
                      : palette.line,
                ),
              ),
            ),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: selected ? palette.paper : palette.ink),
              duration: change,
              curve: Motion.emphasized,
              builder: (context, color, _) =>
                  Text(label, style: EcoType.label.copyWith(color: color)),
            ),
          ),
        ),
      ),
    );
  }
}
