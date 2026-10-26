import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/widgets.dart';

/// Wide enough that the repeat never shows on a phone-sized surface.
const _tileSide = 256;

Future<ui.Image>? _tile;

/// The paper's noise: seeded, made once per process and shared by every
/// overlay, so the texture never crawls between frames or screens.
@visibleForTesting
Future<ui.Image> grainTile() => _tile ??= _makeTile();

Future<ui.Image> _makeTile() {
  final random = math.Random(7);
  final pixels = Uint8List(_tileSide * _tileSide * 4);
  for (var i = 3; i < pixels.length; i += 4) {
    // Only alpha: the overlay tints it. Skewed toward clear, so the grain
    // reads as fibres in the paper rather than static.
    pixels[i] = (math.pow(random.nextDouble(), 1.6) * 255).round();
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    _tileSide,
    _tileSide,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Paper grain over a surface, so flat color reads as printed matter.
class GrainOverlay extends StatefulWidget {
  const new({this.child, this.opacity = 0.06, super.key});

  final Widget? child;
  final double opacity;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    unawaited(
      grainTile().then((image) {
        if (mounted) setState(() => _image = image);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grain = IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(
            image: _image,
            color: context.palette.ink.withValues(alpha: widget.opacity),
            pixelRatio: MediaQuery.devicePixelRatioOf(context),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    final content = widget.child;
    if (content == null) return grain;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        content,
        Positioned.fill(child: grain),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const new({
    required this.image,
    required this.color,
    required this.pixelRatio,
  });

  /// Null until the tile is ready; nothing is drawn meanwhile.
  final ui.Image? image;
  final Color color;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = image;
    if (tile == null) return;
    // One noise pixel per physical pixel: sharp grain on every screen.
    final scale = 1 / pixelRatio;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.diagonal3Values(scale, scale, 1).storage,
          filterQuality: FilterQuality.none,
        )
        ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.color != color ||
      oldDelegate.pixelRatio != pixelRatio;
}
