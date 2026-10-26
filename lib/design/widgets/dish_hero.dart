import 'package:flutter/widgets.dart';

/// The flight of a dish photo between screens. Tags come from the catalog
/// (`dish-<id>-<source>`), since one dish may show twice on a screen.
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
  Widget build(BuildContext context) => Hero(tag: tag, child: child);
}
