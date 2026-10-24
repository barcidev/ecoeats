import 'package:flutter/painting.dart';

abstract final class EcoFonts {
  static const display = 'Fraunces';
  static const text = 'InstrumentSans';
}

/// The type scale. Styles carry no color: the theme and the widgets add it.
///
/// Both families are variable fonts, and not every platform derives the
/// `wght` axis from [FontWeight], so each style sets its axes explicitly.
abstract final class EcoType {
  static const _displayAxes = [
    FontVariation('opsz', 144),
    FontVariation('SOFT', 100),
    FontVariation('wght', 500),
  ];

  static const display = TextStyle(
    fontFamily: EcoFonts.display,
    fontSize: 48,
    height: 1.04,
    letterSpacing: -0.96,
    fontWeight: FontWeight.w500,
    fontVariations: _displayAxes,
  );

  /// Only the welcome headline wobbles; everywhere else Fraunces stays calm.
  static const displayWonk = TextStyle(
    fontFamily: EcoFonts.display,
    fontSize: 48,
    height: 1.04,
    letterSpacing: -0.96,
    fontWeight: FontWeight.w500,
    fontVariations: [..._displayAxes, FontVariation('WONK', 1)],
  );

  static const headline = TextStyle(
    fontFamily: EcoFonts.display,
    fontSize: 32,
    height: 1.1,
    letterSpacing: -0.48,
    fontWeight: FontWeight.w500,
    fontVariations: [
      FontVariation('opsz', 72),
      FontVariation('SOFT', 100),
      FontVariation('wght', 500),
    ],
  );

  static const title = TextStyle(
    fontFamily: EcoFonts.display,
    fontSize: 24,
    height: 1.15,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w500,
    fontVariations: [
      FontVariation('opsz', 36),
      FontVariation('SOFT', 50),
      FontVariation('wght', 500),
    ],
  );

  static const titleSmall = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const body = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const bodySmall = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const label = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  /// Written in capitals by the widget that uses it; styles cannot transform
  /// case.
  static const overline = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const numeric = TextStyle(
    fontFamily: EcoFonts.text,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
