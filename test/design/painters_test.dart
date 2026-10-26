import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _ink = Color(0xFF1E1B16);
const _leaf = Color(0xFFC2410C);

Widget _app(Widget child) => MaterialApp(
  theme: ecoTheme(.light),
  home: Scaffold(body: Center(child: child)),
);

Finder _canvasOf(Type widget) => find.descendant(
  of: find.byType(widget),
  matching: find.byType(CustomPaint),
);

Future<void> _mark(WidgetTester tester, double progress) => tester.pumpWidget(
  _app(LogoMark(size: 120, progress: progress, color: _ink, accent: _leaf)),
);

void main() {
  group('LogoMark', () {
    testWidgets('at zero it draws nothing', (tester) async {
      await _mark(tester, 0);
      expect(tester.renderObject(_canvasOf(LogoMark)), paintsNothing);
    });

    testWidgets('early on only the rim is drawn, as one stroke', (
      tester,
    ) async {
      await _mark(tester, 0.3);
      final canvas = tester.renderObject(_canvasOf(LogoMark));
      expect(canvas, paints..path(color: _ink, style: PaintingStyle.stroke));
      expect(canvas, paintsExactlyCountTimes(#drawPath, 1));
    });

    testWidgets('the well follows before the leaf grows', (tester) async {
      await _mark(tester, 0.6);
      final canvas = tester.renderObject(_canvasOf(LogoMark));
      expect(canvas, paintsExactlyCountTimes(#drawPath, 2));
      expect(canvas, paintsExactlyCountTimes(#saveLayer, 0));
    });

    testWidgets('complete, it has rim, well and a leaf with its vein cut out', (
      tester,
    ) async {
      await _mark(tester, 1);
      expect(
        tester.renderObject(_canvasOf(LogoMark)),
        paints
          ..path(color: _ink, style: PaintingStyle.stroke)
          ..path(color: _ink, style: PaintingStyle.stroke)
          ..something((method, _) => method == #saveLayer)
          ..path(color: _leaf, style: PaintingStyle.fill)
          // The vein clears the leaf, so the background shows through it.
          ..something(
            (method, arguments) =>
                method == #drawPath &&
                (arguments[1] as Paint).blendMode == BlendMode.clear,
          )
          ..restore(),
      );
    });
  });
}
