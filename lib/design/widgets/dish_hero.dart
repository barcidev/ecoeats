import 'dart:ui' show lerpDouble;

import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/widgets.dart';

/// The flight of a dish photo between screens. Tags come from the catalog
/// (`dish-<id>-<source>`), since one dish may show twice on a screen.
///
/// On the way, the corners bend from one screen's radius to the other's,
/// and the photo below melts into the photo above, so the flight starts and
/// lands exactly on what each screen shows.
class DishHero extends StatelessWidget {
  const new({
    required this.tag,
    required this.child,
    this.radius = 0,
    super.key,
  });

  final String tag;
  final Widget child;

  /// Corner radius of the photo where the flight starts.
  final double radius;

  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    flightShuttleBuilder: _photoFlight,
    child: _Bend(radius: radius, child: child),
  );
}

/// A dish's name that flies with its photo, growing from a card's type into
/// a headline (or back). Each end keeps its own font while its size, weight
/// and color travel toward the other's, and the two cross in the middle.
class DishNameHero extends StatelessWidget {
  const new({
    required this.tag,
    required this.name,
    required this.style,
    this.maxLines,
    super.key,
  });

  final String tag;
  final String name;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    flightShuttleBuilder: _nameFlight,
    child: _Name(name: name, style: style, maxLines: maxLines),
  );
}

/// The two ends of a flight, the screen below first. The animation is the
/// upper route's, so its value is how far the flight is toward the upper
/// screen, in both directions.
(T lower, T upper) _ends<T>(
  HeroFlightDirection direction,
  BuildContext from,
  BuildContext to,
) {
  final departing = (from.widget as Hero).child as T;
  final arriving = (to.widget as Hero).child as T;
  return direction == .push ? (departing, arriving) : (arriving, departing);
}

Widget _photoFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final (lower, upper) = _ends<_Bend>(
    direction,
    fromHeroContext,
    toHeroContext,
  );
  final reduced = Motion.reduced(flightContext);
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      final radius = reduced
          ? (t < 0.5 ? lower.radius : upper.radius)
          : lerpDouble(lower.radius, upper.radius, t)!;
      return ClipRSuperellipse(
        borderRadius: BorderRadius.all(.circular(radius)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            lower.child,
            Opacity(opacity: t, child: upper.child),
          ],
        ),
      );
    },
  );
}

Widget _nameFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final (lower, upper) = _ends<_Name>(
    direction,
    fromHeroContext,
    toHeroContext,
  );
  final reduced = Motion.reduced(flightContext);
  // The swap of fonts happens in the middle of the flight, where the sizes
  // are closest.
  const cross = Interval(0.2, 0.8, curve: Curves.easeInOut);
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      final shown = cross.transform(t);
      // In the overlay there is no Material: reset the app's error style.
      return DefaultTextStyle(
        style: const TextStyle(),
        child: Stack(
          children: [
            Opacity(
              opacity: 1 - shown,
              child: lower.styled(
                reduced ? lower.style : _toward(lower.style, upper.style, t),
              ),
            ),
            Opacity(
              opacity: shown,
              child: upper.styled(
                reduced
                    ? upper.style
                    : _toward(upper.style, lower.style, 1 - t),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// [own] moved [t] of the way toward [other]'s size, spacing, weight and
/// color, still set in its own font.
TextStyle _toward(TextStyle own, TextStyle other, double t) => TextStyle.lerp(
  own,
  other.copyWith(
    fontFamily: own.fontFamily,
    fontStyle: own.fontStyle,
    fontVariations: own.fontVariations,
    fontFeatures: own.fontFeatures,
  ),
  t,
)!;

class _Bend extends StatelessWidget {
  const new({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _Name extends StatelessWidget {
  const new({required this.name, required this.style, required this.maxLines});

  final String name;
  final TextStyle style;
  final int? maxLines;

  Widget styled(TextStyle style) => Text(
    name,
    style: style,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) => styled(style);
}
