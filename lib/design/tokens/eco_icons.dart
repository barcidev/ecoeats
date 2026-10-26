import 'package:flutter/widgets.dart';

/// The app's single icon set: Phosphor, light weight (fill only for the
/// filled half of a star).
///
/// phosphor_flutter 2.1 subclasses `IconData`, which Flutter 3.47 made final,
/// so its Dart code no longer compiles. The package stays as a dependency only
/// for the fonts it bundles, read here through plain const `IconData`.
abstract final class EcoIcons {
  static const _light = 'PhosphorLight';
  static const _fill = 'PhosphorFill';
  static const _package = 'phosphor_flutter';

  static const arrowClockwise = IconData(
    0xe036,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const arrowLeft = IconData(
    0xe058,
    fontFamily: _light,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const arrowUp = IconData(
    0xe08e,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const arrowsDownUp = IconData(
    0xe098,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const caretDown = IconData(
    0xe136,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const caretLeft = IconData(
    0xe138,
    fontFamily: _light,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const cards = IconData(
    0xee50,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const check = IconData(
    0xe182,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const clockCountdown = IconData(
    0xed2c,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const eye = IconData(
    0xe220,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const eyeSlash = IconData(
    0xe224,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const forkKnife = IconData(
    0xe262,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const globe = IconData(
    0xe288,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const leaf = IconData(
    0xe2da,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const magnifyingGlass = IconData(
    0xe30c,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const moon = IconData(
    0xe330,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const signOut = IconData(
    0xe42a,
    fontFamily: _light,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const slidersHorizontal = IconData(
    0xe434,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const star = IconData(
    0xe46a,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const starFill = IconData(
    0xe46a,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const sun = IconData(
    0xe472,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const user = IconData(
    0xe4c2,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const warningCircle = IconData(
    0xe4e2,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const wifiSlash = IconData(
    0xe4f2,
    fontFamily: _light,
    fontPackage: _package,
  );
  static const x = IconData(0xe4f6, fontFamily: _light, fontPackage: _package);
}
