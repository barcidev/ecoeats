import 'dart:ui' show lerpDouble;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A form field drawn as a label over an underline, the way a paper form
/// reads. The label rests on the line until the field is used, the line
/// inks itself while typing, and the error, already translated, slides in
/// under it.
class EcoTextField extends StatefulWidget {
  const new({
    required this.label,
    this.controller,
    this.focusNode,
    this.error,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? error;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final bool enabled;
  final bool autofocus;

  @override
  State<EcoTextField> createState() => _EcoTextFieldState();
}

// The label's line, and the room it keeps above the input in every state.
const _labelHeight = 16.0;

// Resting on the input line, the overline grows to read like a placeholder.
const _restingScale = 1.25;

class _EcoTextFieldState extends State<EcoTextField>
    with TickerProviderStateMixin {
  FocusNode? _ownFocus;
  TextEditingController? _ownText;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());

  late final _float = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );
  late final _ink = AnimationController(vsync: this, duration: Motion.standard);

  // Read in build: focus can change while the tree is torn down, when the
  // context can no longer be asked.
  var _reduced = false;

  bool get _up => _focus.hasFocus || _text.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _listen(_focus, _text);
    _float.value = _up ? 1 : 0;
    _ink.value = _focus.hasFocus ? 1 : 0;
  }

  @override
  void didUpdateWidget(EcoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFocus = oldWidget.focusNode ?? _ownFocus;
    final oldText = oldWidget.controller ?? _ownText;
    if (oldFocus != _focus || oldText != _text) {
      oldFocus?.removeListener(_sync);
      oldText?.removeListener(_sync);
      _listen(_focus, _text);
      _sync();
    }
  }

  void _listen(FocusNode focus, TextEditingController text) {
    focus.addListener(_sync);
    text.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    _move(_float, _up ? 1 : 0);
    _move(_ink, _focus.hasFocus ? 1 : 0);
    // The hint and the colors follow the focus too.
    setState(() {});
  }

  void _move(AnimationController controller, double target) {
    if (controller.value == target && !controller.isAnimating) return;
    if (_reduced) {
      controller.value = target;
    } else {
      controller.animateTo(target, curve: Motion.emphasized);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_sync);
    _text.removeListener(_sync);
    _ownFocus?.dispose();
    _ownText?.dispose();
    _float.dispose();
    _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduced = Motion.reduced(context);
    final palette = context.palette;
    final message = widget.error;
    final focused = _focus.hasFocus;
    final labelColor = switch ((message, focused)) {
      (_?, _) => palette.achiote,
      (null, true) when widget.enabled => palette.ink,
      _ => palette.muted,
    };
    final base = message == null ? palette.line : palette.achiote;
    final active = message == null ? palette.ink : palette.achiote;
    final change = _reduced ? Duration.zero : Motion.quick;
    final showHint = focused && _text.text.isEmpty;

    final field = TextField(
      controller: _text,
      focusNode: _focus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: EcoType.body.copyWith(color: palette.ink),
      cursorColor: palette.achiote,
      decoration: InputDecoration(
        isDense: true,
        hintText: showHint ? widget.hint : null,
        hintStyle: EcoType.body.copyWith(color: palette.muted),
        suffixIcon: widget.suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: Space.sm),
        // The underline is drawn below, so it can ink itself.
        border: InputBorder.none,
      ),
    );

    // Centered on the input line: the room above it, the content padding and
    // half of what the body line has left around the grown label.
    final restingTop =
        _labelHeight +
        Space.sm +
        ((EcoType.body.fontSize! * EcoType.body.height!) -
                _labelHeight * _restingScale) /
            2;

    final label = IgnorePointer(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final t = _float.value;
          final scale = lerpDouble(_restingScale, 1, t)!;
          return Transform(
            transform: Matrix4.translationValues(
              0,
              lerpDouble(restingTop, 0, t)!,
              0,
            )..scaleByDouble(scale, scale, 1, 1),
            child: child,
          );
        },
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: labelColor),
          duration: change,
          builder: (context, color, _) => Text(
            widget.label.toUpperCase(),
            style: EcoType.overline.copyWith(color: color),
          ),
        ),
      ),
    );

    final underline = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: base),
      duration: change,
      builder: (context, baseColor, _) => AnimatedBuilder(
        animation: _ink,
        builder: (context, _) => CustomPaint(
          painter: EcoUnderlinePainter(
            progress: _ink.value,
            base: baseColor ?? base,
            active: active,
          ),
          child: const SizedBox(height: 1.5, width: double.infinity),
        ),
      ),
    );

    // A new error slides in; a fixed one leaves at once, while the room it
    // took closes smoothly, so the form never shows a stale message.
    final errorText = message == null
        ? const SizedBox(width: double.infinity)
        : TweenAnimationBuilder<double>(
            key: ValueKey(message),
            tween: Tween(begin: 0, end: 1),
            duration: change,
            curve: Motion.emphasized,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -Space.xs),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                message,
                style: EcoType.bodySmall.copyWith(color: palette.achiote),
              ),
            ),
          );
    // A zero-length AnimatedSize re-dirties itself during layout.
    final errorLine = _reduced
        ? errorText
        : AnimatedSize(
            duration: Motion.quick,
            curve: Motion.emphasized,
            alignment: Alignment.topLeft,
            child: errorText,
          );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _labelHeight),
                child: field,
              ),
              Positioned(left: 0, top: 0, right: 0, child: label),
              Positioned(left: 0, right: 0, bottom: 0, child: underline),
            ],
          ),
          errorLine,
        ],
      ),
    );
  }
}

/// The field's line: a hairline in [base], inked from the left in [active]
/// as far as [progress] reaches.
@visibleForTesting
class EcoUnderlinePainter extends CustomPainter {
  const new({required this.progress, required this.base, required this.active});

  final double progress;
  final Color base;
  final Color active;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - Space.hairline,
        size.width,
        Space.hairline,
      ),
      Paint()..color = base,
    );
    if (progress <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      Paint()..color = active,
    );
  }

  @override
  bool shouldRepaint(EcoUnderlinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.base != base ||
      oldDelegate.active != active;
}
