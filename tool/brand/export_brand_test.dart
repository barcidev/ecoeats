// The brand's image sources, drawn by the same painter the app uses for its
// logo, so the icon, the splash and the welcome mark never drift apart. Run
// on purpose when the mark changes:
//
//   fvm flutter test tool/brand/export_brand_test.dart
//
// It writes the PNGs to assets/brand/ and then checks them. The regular test
// run does not touch them.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Source = ({
  String name,
  double canvas,
  double mark,
  Color? background,
  Color rim,
  Color leaf,
});

const EcoPalette _day = EcoPalette.mantel;
const EcoPalette _night = EcoPalette.fogon;

final List<_Source> _sources = [
  // The logo itself, edge to edge.
  (
    name: 'logo',
    canvas: 1024,
    mark: 1024,
    background: null,
    rim: _day.ink,
    leaf: _day.achiote,
  ),
  // iOS icons may not be transparent: the mark sits on the day's paper.
  (
    name: 'icon',
    canvas: 1024,
    mark: 655,
    background: _day.paper,
    rim: _day.ink,
    leaf: _day.achiote,
  ),
  // Android's adaptive layers keep the mark inside the 66 % safe zone.
  (
    name: 'icon_foreground',
    canvas: 1024,
    mark: 573,
    background: null,
    rim: _day.ink,
    leaf: _day.achiote,
  ),
  (
    name: 'icon_monochrome',
    canvas: 1024,
    mark: 573,
    background: null,
    rim: _day.ink,
    leaf: _day.ink,
  ),
  // The splash shows 192 dp at 4x, with the mark at two thirds.
  (
    name: 'splash',
    canvas: 768,
    mark: 512,
    background: null,
    rim: _day.ink,
    leaf: _day.achiote,
  ),
  (
    name: 'splash_dark',
    canvas: 768,
    mark: 512,
    background: null,
    rim: _night.ink,
    leaf: _night.achiote,
  ),
  // Android 12 crops its splash icon to a 768 px circle out of 1152 px.
  (
    name: 'splash_android12',
    canvas: 1152,
    mark: 640,
    background: null,
    rim: _day.ink,
    leaf: _day.achiote,
  ),
  (
    name: 'splash_android12_dark',
    canvas: 1152,
    mark: 640,
    background: null,
    rim: _night.ink,
    leaf: _night.achiote,
  ),
];

File _file(_Source source) => File('assets/brand/${source.name}.png');

void main() {
  testWidgets('renders the brand sources from LogoMark', (tester) async {
    addTearDown(tester.view.reset);
    for (final source in _sources) {
      tester.view.physicalSize = Size.square(source.canvas);
      tester.view.devicePixelRatio = 1;
      final canvas = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: canvas,
              child: SizedBox.square(
                dimension: source.canvas,
                child: ColoredBox(
                  color: source.background ?? const Color(0x00000000),
                  child: Center(
                    child: LogoMark(
                      size: source.mark,
                      color: source.rim,
                      accent: source.leaf,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          canvas.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        _file(source)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  });

  test('every source has its size, its background and its mark', () async {
    for (final source in _sources) {
      final codec = await ui.instantiateImageCodec(
        _file(source).readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.width, source.canvas, reason: source.name);
      expect(image.height, source.canvas, reason: source.name);

      final pixels = (await image.toByteData())!;
      int alphaAt(double x, double y) =>
          pixels.getUint8((y.round() * image.width + x.round()) * 4 + 3);

      // The corner is the background: clear, or the icon's opaque paper.
      expect(
        alphaAt(0, 0),
        source.background == null ? 0 : 255,
        reason: '${source.name} corner',
      );
      // The top of the rim, where the stroke is thickest, is fully inked.
      final stroke = source.mark / 14;
      final rimTop = (source.canvas - source.mark) / 2 + stroke;
      expect(
        alphaAt(source.canvas / 2, rimTop),
        255,
        reason: '${source.name} rim',
      );
      image.dispose();
    }
  });
}
