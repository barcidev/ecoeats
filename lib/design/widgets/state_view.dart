import 'dart:async';

import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:flutter/widgets.dart';

enum StateKind { empty, error, offline, rateLimited }

/// What a screen shows instead of its content: nothing found, no connection,
/// too many requests or a failure, always with a drawing, never a bare text.
class StateView extends StatefulWidget {
  const new({
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.cooldown,
    this.cooldownLabel,
    this.footnote,
    super.key,
  });

  final StateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// How long the action stays disabled, as a 429 asks.
  final Duration? cooldown;

  /// The action's text while the cooldown runs, such as «Intenta en 0:42».
  final String Function(Duration remaining)? cooldownLabel;

  /// Small print at the bottom, such as a request reference.
  final String? footnote;

  @override
  State<StateView> createState() => _StateViewState();
}

class _StateViewState extends State<StateView> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(StateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cooldown != widget.cooldown) _start();
  }

  void _start() {
    _ticker?.cancel();
    _remaining = widget.cooldown ?? Duration.zero;
    if (_remaining <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remaining -= const Duration(seconds: 1));
      if (_remaining <= Duration.zero) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = switch (widget.kind) {
      .empty => palette.panela,
      .error => palette.achiote,
      .offline => palette.muted,
      .rateLimited => palette.maiz,
    };
    final waiting = _remaining > Duration.zero;
    final label = waiting
        ? widget.cooldownLabel?.call(_remaining) ?? widget.actionLabel
        : widget.actionLabel;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          mainAxisSize: .min,
          children: [
            PlateIllustration(accent: accent),
            const SizedBox(height: Space.lg),
            Text(
              widget.title,
              textAlign: .center,
              style: EcoType.title.copyWith(color: palette.ink),
            ),
            if (widget.message case final message?) ...[
              const SizedBox(height: Space.xs),
              Text(
                message,
                textAlign: .center,
                style: EcoType.body.copyWith(color: palette.muted),
              ),
            ],
            if (label != null) ...[
              const SizedBox(height: Space.lg),
              EcoButton(
                label: label,
                variant: .secondary,
                expand: false,
                onPressed: waiting ? null : widget.onAction,
              ),
            ],
            if (widget.footnote case final footnote?) ...[
              const SizedBox(height: Space.lg),
              Text(
                footnote,
                style: EcoType.overline.copyWith(color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
