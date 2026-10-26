import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  Widget child, {
  Brightness brightness = .light,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: ecoTheme(brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  group('Skeleton', () {
    test('the highlight crosses the whole screen and starts over', () {
      const width = 390.0;
      final start = shimmerBandX(Duration.zero, width);
      expect(start, lessThan(0));
      final crossing = [
        for (var ms = 0; ms < 1600; ms += 100)
          shimmerBandX(Duration(milliseconds: ms), width),
      ];
      expect(crossing.any((x) => x > 0 && x < width), isTrue);
      expect(crossing.reduce((a, b) => a > b ? a : b), greaterThan(width));
      expect(
        shimmerBandX(const Duration(milliseconds: 5300), width),
        shimmerBandX(const Duration(milliseconds: 5300 - 1600), width),
      );
    });

    testWidgets('blocks keep shining while they show', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [Skeleton(width: 120, height: 16), Skeleton(height: 200)],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(tester.getSize(find.byType(Skeleton).first), const Size(120, 16));
      expect(tester.getSize(find.byType(Skeleton).last).height, 200);
    });

    testWidgets('with reduced motion they are flat and still', (tester) async {
      await tester.pumpWidget(
        _app(const Skeleton(width: 120, height: 16), reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    for (final brightness in Brightness.values) {
      testWidgets('they paint in ${brightness.name}', (tester) async {
        await tester.pumpWidget(
          _app(const Skeleton(height: 120), brightness: brightness),
        );
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('GrainOverlay', () {
    testWidgets('its noise tile is made once and shared', (tester) async {
      final (first, second) = (await tester.runAsync(
        () async => (await grainTile(), await grainTile()),
      ))!;
      expect(identical(first, second), isTrue);
      expect(first.width, first.height);

      final pixels = (await tester.runAsync(first.toByteData))!;
      final alphas = {
        for (var i = 3; i < pixels.lengthInBytes; i += 4) pixels.getUint8(i),
      };
      expect(alphas.length, greaterThan(100));
    });

    testWidgets('it lays the tile over its child and stays still', (
      tester,
    ) async {
      await tester.runAsync(grainTile);
      await tester.pumpWidget(
        _app(const GrainOverlay(child: Center(child: Text('papel')))),
      );
      await tester.pump();
      expect(find.text('papel'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
