import 'dart:async';

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/widgets.dart';

enum ToastTone { neutral, success, alert }

/// A short note that drops from the top and leaves by itself. Only one shows
/// at a time: a new one replaces the current.
abstract final class Toast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = .neutral,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastBanner(
        message: message,
        tone: tone,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _ToastBanner extends StatefulWidget {
  const new({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final ToastTone tone;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner>
    with SingleTickerProviderStateMixin {
  late final _drop = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    await _drop.forward();
    await Future<void>.delayed(widget.duration);
    if (!mounted) return;
    await _drop.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dot = switch (widget.tone) {
      .neutral => palette.ink,
      .success => palette.aguacate,
      .alert => palette.achiote,
    };
    final curve = CurvedAnimation(parent: _drop, curve: Motion.emphasized);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter,
            vertical: Space.xs,
          ),
          child: FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -0.4),
                end: Offset.zero,
              ).animate(curve),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.sm,
                  ),
                  decoration: ShapeDecoration(
                    color: palette.raised,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: const BorderRadius.all(.circular(Radii.md)),
                      side: BorderSide(color: palette.line),
                    ),
                  ),
                  child: Row(
                    spacing: Space.sm,
                    children: [
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          color: dot,
                          shape: const CircleBorder(),
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: EcoType.bodySmall.copyWith(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
