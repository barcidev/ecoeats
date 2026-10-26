import 'dart:math' as math;

import 'package:ecoeats/design/gallery/design_gallery_page.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/features/discover/presentation/discover_page.dart';
import 'package:ecoeats/features/discover/presentation/discover_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CircleRevealClipper _clipper(WidgetTester tester) =>
    tester.widget<ClipPath>(find.byType(ClipPath)).clipper!
        as CircleRevealClipper;

void main() {
  test('the circle covers the screen from any origin', () {
    const size = Size(400, 800);
    final full = const CircleRevealClipper(
      origin: Offset.zero,
      fraction: 1,
    ).getClip(size).getBounds();
    final radius = math.sqrt(400 * 400 + 800 * 800);
    expect(full.width, closeTo(radius * 2, 0.5));
    final centered = const CircleRevealClipper(
      origin: null,
      fraction: 1,
    ).getClip(size).getBounds().center;
    expect((centered - size.center(Offset.zero)).distance, lessThan(0.01));
    expect(
      const CircleRevealClipper(
        origin: Offset(10, 10),
        fraction: 0,
      ).getClip(size).getBounds().isEmpty,
      isTrue,
    );
  });

  testWidgets('the page grows from the tap until it covers everything', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ecoTheme(.light),
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                revealRoute<void>(
                  settings: const RouteSettings(name: 'discover'),
                  origin: const Offset(40, 700),
                  child: const DiscoverPage(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final opening = _clipper(tester);
    expect(opening.origin, const Offset(40, 700));
    expect(opening.fraction, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(_clipper(tester).fraction, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets('brand, gallery and Discover render in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      addTearDown(tester.view.reset);
      for (final screen in <Widget>[
        const Scaffold(
          body: GrainOverlay(
            child: Center(child: LogoMark(size: 96, progress: 0.5)),
          ),
        ),
        const DesignGalleryPage(),
        const DiscoverPage(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(theme: ecoTheme(brightness), home: screen),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
