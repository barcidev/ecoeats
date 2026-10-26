import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_hero.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _small = Color(0xFFAA0000);
const _large = Color(0xFF0000AA);
final TextStyle _rowName = EcoType.titleSmall.copyWith(
  color: EcoPalette.mantel.ink,
);
final TextStyle _headline = EcoType.headline.copyWith(
  color: EcoPalette.mantel.achiote,
);

Widget _app({bool reduceMotion = false}) => MaterialApp(
  theme: ecoTheme(.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Column(
        crossAxisAlignment: .start,
        children: [
          const SizedBox.square(
            dimension: 100,
            child: DishHero(
              tag: 'photo',
              radius: 28,
              child: ColoredBox(color: _small),
            ),
          ),
          DishNameHero(tag: 'name', name: 'Ajiaco', style: _rowName),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 400),
                reverseTransitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, _, _) => Scaffold(
                  body: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const SizedBox(
                        width: 300,
                        height: 300,
                        child: DishHero(
                          tag: 'photo',
                          child: ColoredBox(color: _large),
                        ),
                      ),
                      DishNameHero(
                        tag: 'name',
                        name: 'Ajiaco',
                        style: _headline,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ],
      ),
    ),
  ),
);

Iterable<double> _radii(WidgetTester tester) => tester
    .widgetList<ClipRSuperellipse>(find.byType(ClipRSuperellipse))
    .map((clip) => (clip.borderRadius as BorderRadius).topLeft.x);

double _largeOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) => widget is ColoredBox && widget.color == _large,
            ),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

Iterable<double> _nameSizes(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(find.text('Ajiaco'))
    .map((paragraph) => paragraph.text.style!.fontSize!);

void main() {
  testWidgets('the photo bends its corners and melts into the large one', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(_radii(tester).any((radius) => radius > 0 && radius < 28), isTrue);
    expect(_largeOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_radii(tester).any((radius) => radius > 0 && radius < 28), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the name grows from the row into the headline', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final flying = _nameSizes(tester).toList();
    expect(flying, hasLength(2));
    for (final size in flying) {
      expect(size, inExclusiveRange(18, 32));
    }
    // Overlay text never takes the app's error style.
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      find.text('Ajiaco'),
    )) {
      expect(
        paragraph.text.style!.decoration ?? TextDecoration.none,
        TextDecoration.none,
      );
    }

    await tester.pumpAndSettle();
    final landed = tester.widget<Text>(find.text('Ajiaco'));
    expect(landed.style, _headline);
  });

  testWidgets('with reduced motion the name only crossfades', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_nameSizes(tester).toSet(), {18.0, 32.0});
  });
}
