import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/widgets.dart';

/// A headline that rises line by line from behind its own baseline, as if
/// each line were slid out of a slot. The slots reach past the line box, so
/// accents and descenders are never cut.
class MaskRevealText extends StatefulWidget {
  const new({
    required this.lines,
    this.style,
    this.textAlign = TextAlign.start,
    this.delay = Duration.zero,
    super.key,
  });

  final List<String> lines;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration delay;

  @override
  State<MaskRevealText> createState() => _MaskRevealTextState();
}

class _MaskRevealTextState extends State<MaskRevealText>
    with SingleTickerProviderStateMixin {
  static const _lineGap = Duration(milliseconds: 120);

  late final _reveal = AnimationController(
    vsync: this,
    duration: Motion.slow + _lineGap * (widget.lines.length - 1),
  );
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reveal.value > 0 || _wait != null) return;
    if (Motion.reduced(context)) {
      _reveal.value = 1;
    } else {
      _wait = Timer(widget.delay, _reveal.forward);
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final fontSize = style.fontSize ?? 14;
    // Fraunces reaches about a quarter of its size past a tight line box,
    // above (Á, Ñ) and below (g, y).
    final overhang = fontSize * 0.3;
    final lineHeight = fontSize * (style.height ?? 1.2);
    // A line starts low enough that its accents clear the bottom of the slot.
    final hidden = 1 + overhang * 2 / lineHeight;
    final total = _reveal.duration!.inMilliseconds;
    final span = Motion.slow.inMilliseconds / total;
    final align = switch (widget.textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    return Semantics(
      label: widget.lines.join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: .min,
        children: [
          for (final (index, line) in widget.lines.indexed)
            ClipRect(
              clipper: _Slot(overhang),
              child: SlideTransition(
                position: Tween(begin: Offset(0, hidden), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: _reveal,
                        curve: Interval(
                          index * _lineGap.inMilliseconds / total,
                          (index * _lineGap.inMilliseconds / total + span)
                              .clamp(0, 1),
                          curve: Motion.emphasized,
                        ),
                      ),
                    ),
                child: Text(
                  line,
                  style: widget.style,
                  textAlign: widget.textAlign,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Slot extends CustomClipper<Rect> {
  const new(this.overhang);

  final double overhang;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -overhang,
    -overhang,
    size.width + overhang,
    size.height + overhang,
  );

  @override
  bool shouldReclip(_Slot oldClipper) => oldClipper.overhang != overhang;
}
