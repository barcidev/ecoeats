import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:flutter/widgets.dart';

/// A block in the shape of the content that is on its way. Screens compose
/// them to mirror their real layout, so nothing jumps when data arrives.
class Skeleton extends StatefulWidget {
  const new({this.width, this.height, this.radius = Radii.sm, super.key});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: Motion.signature,
    lowerBound: 0.55,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _pulse,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            color: context.palette.line,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(.circular(widget.radius)),
            ),
          ),
        ),
      ),
    );
  }
}
