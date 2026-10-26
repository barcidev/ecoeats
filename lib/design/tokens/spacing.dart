import 'package:flutter/painting.dart';

abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Side margin of every screen.
  static const double gutter = 20;

  /// Lines replace shadows, so they stay at one physical-looking pixel.
  static const double hairline = 1;
}

abstract final class Radii {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;

  static const RoundedSuperellipseBorder squircleSm = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(.circular(sm)),
  );
  static const RoundedSuperellipseBorder squircleMd = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(.circular(md)),
  );
  static const RoundedSuperellipseBorder squircleLg = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(.circular(lg)),
  );
}
