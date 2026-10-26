import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The six-digit recovery code, drawn as boxes over one hidden text field so
/// paste, the platform's one-time-code autofill, delete and screen readers
/// behave as in any other field.
class OtpField extends StatefulWidget {
  const new({
    required this.onCompleted,
    required this.semanticsLabel,
    this.error = false,
    this.enabled = true,
    this.autofocus = true,
    super.key,
  });

  static const length = 6;

  @visibleForTesting
  static Key boxKey(int index) => ValueKey('otp-box-$index');

  @visibleForTesting
  static const caretKey = Key('otp-caret');

  /// Called once each time the sixth digit arrives.
  final ValueChanged<String> onCompleted;
  final String semanticsLabel;

  /// Turning it on means the code was rejected: the field clears, plays a
  /// haptic and keeps the error look until the user types again.
  final bool error;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late bool _showError = widget.error;
  String? _reported;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_keepCaretAtEnd);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error && !oldWidget.error) {
      _controller.clear();
      _reported = null;
      _showError = true;
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  // A tap between boxes must not leave the caret in the middle of the code;
  // a non-collapsed selection is left alone so paste menus still work.
  void _keepCaretAtEnd() {
    final selection = _controller.selection;
    final end = _controller.text.length;
    if (selection.isCollapsed && selection.baseOffset != end) {
      _controller.selection = .collapsed(offset: end);
    }
  }

  void _onChanged(String value) {
    setState(() => _showError = false);
    if (value.length < OtpField.length) {
      _reported = null;
    } else if (value != _reported) {
      _reported = value;
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final focused = widget.enabled && _focusNode.hasFocus;
    final active = focused && text.length < OtpField.length
        ? text.length
        : null;

    final boxes = Row(
      children: [
        for (var i = 0; i < OtpField.length; i++) ...[
          // A wider gap in the middle reads the code as two groups of three.
          if (i > 0)
            SizedBox(width: i == OtpField.length ~/ 2 ? Space.md : Space.xs),
          Expanded(
            child: _Box(
              index: i,
              digit: i < text.length ? text[i] : null,
              active: i == active,
              error: _showError,
              enabled: widget.enabled,
            ),
          ),
        ],
      ],
    );

    return Stack(
      children: [
        ExcludeSemantics(child: boxes),
        Positioned.fill(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(OtpField.length),
            ],
            onChanged: _onChanged,
            showCursor: false,
            enableSuggestions: false,
            autocorrect: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: InputDecoration(
              labelText: widget.semanticsLabel,
              labelStyle: const TextStyle(color: Colors.transparent),
              floatingLabelBehavior: .never,
              border: InputBorder.none,
              filled: false,
              isCollapsed: true,
              contentPadding: .zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const new({
    required this.index,
    required this.digit,
    required this.active,
    required this.error,
    required this.enabled,
  });

  final int index;
  final String? digit;
  final bool active;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduced = Motion.reduced(context);
    final duration = reduced ? Duration.zero : Motion.quick;
    final border = switch ((error, active)) {
      (true, _) => palette.achiote,
      (_, true) => palette.ink,
      _ => palette.line,
    };

    return AspectRatio(
      aspectRatio: 0.8,
      child: AnimatedContainer(
        key: OtpField.boxKey(index),
        duration: duration,
        curve: Motion.emphasized,
        alignment: .center,
        decoration: ShapeDecoration(
          color: palette.raised,
          shape: RoundedSuperellipseBorder(
            borderRadius: const .all(.circular(Radii.sm)),
            side: BorderSide(
              color: border,
              width: error || active ? 1.5 : Space.hairline,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: reduced
                ? child
                : ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                    child: child,
                  ),
          ),
          child: switch (digit) {
            final digit? => Text(
              digit,
              key: ValueKey(digit),
              style: EcoType.title.copyWith(
                color: enabled ? palette.ink : palette.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            null when active => _Caret(color: palette.achiote),
            null => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

/// A still caret: a blinking one would never let the screen settle.
class _Caret extends StatelessWidget {
  const new({required this.color}) : super(key: OtpField.caretKey);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      child: const SizedBox(width: 2, height: 24),
    );
  }
}
