import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EcoPalette', () {
    test('Mantel is the light palette', () {
      const mantel = EcoPalette.mantel;
      expect(mantel.paper, const Color(0xFFF4EEE4));
      expect(mantel.raised, const Color(0xFFFBF7F0));
      expect(mantel.ink, const Color(0xFF1E1B16));
      expect(mantel.muted, const Color(0xFF6B6257));
      expect(mantel.line, const Color(0xFFE2D8C9));
      expect(mantel.achiote, const Color(0xFFC2410C));
      expect(mantel.aguacate, const Color(0xFF4D6B2F));
      expect(mantel.maiz, const Color(0xFFE3A72F));
      expect(mantel.panela, const Color(0xFF8A5A2B));
    });

    test('Fogón is the dark palette', () {
      const fogon = EcoPalette.fogon;
      expect(fogon.paper, const Color(0xFF14110E));
      expect(fogon.raised, const Color(0xFF1E1A16));
      expect(fogon.ink, const Color(0xFFF3ECE1));
      expect(fogon.muted, const Color(0xFFA69C8F));
      expect(fogon.line, const Color(0xFF2E2822));
      expect(fogon.achiote, const Color(0xFFF06A2E));
      expect(fogon.aguacate, const Color(0xFF8FB15A));
      expect(fogon.maiz, const Color(0xFFF2C14E));
      expect(fogon.panela, const Color(0xFFB07A45));
    });

    test('lerp blends every color halfway', () {
      final mid = EcoPalette.mantel.lerp(EcoPalette.fogon, 0.5);
      expect(
        mid.paper,
        Color.lerp(EcoPalette.mantel.paper, EcoPalette.fogon.paper, 0.5),
      );
      expect(
        mid.achiote,
        Color.lerp(EcoPalette.mantel.achiote, EcoPalette.fogon.achiote, 0.5),
      );
    });

    test('copyWith replaces only what it is given', () {
      final copy = EcoPalette.mantel.copyWith(ink: const Color(0xFF000000));
      expect(copy.ink, const Color(0xFF000000));
      expect(copy.paper, EcoPalette.mantel.paper);
    });
  });

  group('Space', () {
    test('steps grow on a 4 px grid', () {
      const steps = [Space.xxs, Space.xs, Space.sm, Space.md, Space.lg];
      for (final step in steps) {
        expect(step % 4, 0);
      }
      expect(Space.hairline, 1);
    });
  });

  group('Motion', () {
    test('exposes the plan durations, curve and spring', () {
      expect(Motion.quick, const Duration(milliseconds: 160));
      expect(Motion.standard, const Duration(milliseconds: 280));
      expect(Motion.slow, const Duration(milliseconds: 480));
      expect(Motion.signature, const Duration(milliseconds: 900));
      expect(Motion.emphasized, const Cubic(0.2, 0, 0, 1));
      expect(Motion.spring.stiffness, 380);
      expect(Motion.spring.damping, 30);
      expect(Motion.stagger, const Duration(milliseconds: 40));
      expect(Motion.maxStaggered, 6);
    });

    testWidgets('reduced follows disableAnimations', (tester) async {
      late bool reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = Motion.reduced(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    test('staggerDelay caps at the sixth item', () {
      expect(Motion.staggerDelay(0), Duration.zero);
      expect(Motion.staggerDelay(2), const Duration(milliseconds: 80));
      expect(Motion.staggerDelay(10), const Duration(milliseconds: 200));
    });
  });

  group('EcoType', () {
    test('headings use Fraunces with the display axes', () {
      expect(EcoType.display.fontFamily, EcoFonts.display);
      expect(EcoType.display.fontSize, 48);
      expect(
        EcoType.display.fontVariations,
        containsAll(const [
          FontVariation('opsz', 144),
          FontVariation('SOFT', 100),
          FontVariation('wght', 500),
        ]),
      );
      expect(EcoType.headline.fontFamily, EcoFonts.display);
    });

    test('only the welcome style is wonky', () {
      expect(
        EcoType.displayWonk.fontVariations,
        contains(const FontVariation('WONK', 1)),
      );
      expect(
        EcoType.display.fontVariations!.map((axis) => axis.axis),
        isNot(contains('WONK')),
      );
    });

    test('body is Instrument Sans 16/24', () {
      expect(EcoType.body.fontFamily, EcoFonts.text);
      expect(EcoType.body.fontSize, 16);
      expect(EcoType.body.height, 24 / 16);
    });

    test('overlines are tracked at 1.4', () {
      expect(EcoType.overline.letterSpacing, 1.4);
      expect(EcoType.overline.fontFamily, EcoFonts.text);
    });

    test('numeric styles use tabular figures', () {
      expect(
        EcoType.numeric.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
