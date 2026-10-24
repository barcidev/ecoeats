import 'dart:ui';

import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
