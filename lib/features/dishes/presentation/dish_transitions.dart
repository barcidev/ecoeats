import 'package:ecoeats/design/tokens/motion.dart';
import 'package:flutter/widgets.dart';

/// Where a dish photo flies from. A featured dish shows both in the carousel
/// and in the list, so the source is part of its hero tag.
enum HeroSource { carousel, list, discover }

String dishHeroTag(String dishId, HeroSource source) =>
    'dish-$dishId-${source.name}';

/// The dish's name flies along with its photo, under a tag of its own.
String dishNameHeroTag(String dishId, HeroSource source) =>
    '${dishHeroTag(dishId, source)}-name';

Widget dishFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Motion.emphasized),
    child: child,
  );
}
