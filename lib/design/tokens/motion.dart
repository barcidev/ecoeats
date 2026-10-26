import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);

  /// Reserved for the signature moments: welcome, reveal, hero landing.
  static const signature = Duration(milliseconds: 900);

  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const spring = SpringDescription(mass: 1, stiffness: 380, damping: 30);

  /// Lists stagger only on their first load, and only the first items.
  static const stagger = Duration(milliseconds: 40);
  static const maxStaggered = 6;

  static Duration staggerDelay(int index) =>
      stagger * math.min(index, maxStaggered - 1);

  /// With reduced motion every animation becomes a plain crossfade.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
