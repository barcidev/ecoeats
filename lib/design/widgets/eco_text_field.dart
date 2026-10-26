import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A form field drawn as a label over an underline, the way a paper form
/// reads. The error, already translated, shows under the line.
class EcoTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final message = error;
    final lineColor = message == null ? palette.line : palette.achiote;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            label.toUpperCase(),
            style: EcoType.overline.copyWith(color: palette.muted),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            enabled: enabled,
            autofocus: autofocus,
            style: EcoType.body.copyWith(color: palette.ink),
            cursorColor: palette.achiote,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: EcoType.body.copyWith(color: palette.muted),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(vertical: Space.sm),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: lineColor),
              ),
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: palette.line),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: message == null ? palette.ink : palette.achiote,
                  width: 1.5,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.quick,
            curve: Motion.emphasized,
            alignment: Alignment.topLeft,
            child: message == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      message,
                      style: EcoType.bodySmall.copyWith(color: palette.achiote),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
