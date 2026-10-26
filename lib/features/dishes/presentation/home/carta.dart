import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_hero.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/image_url.dart';
import 'package:ecoeats/features/dishes/domain/ingredients.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:material_ui/material_ui.dart';

const _photo = 72.0;

/// «Bandeja Paisa: frijoles rojos, arroz blanco, chicharrón…»: enough of the
/// list to taste the dish without reading the recipe.
String ingredientPreview(String ingredients, {int count = 3}) {
  final items = parseIngredients(ingredients);
  final shown = items.take(count).join(', ');
  return items.length > count ? '$shown…' : shown;
}

/// One line of the menu: photo, name, a taste of the ingredients, price and
/// rating, set like a printed menu rather than a list of cards.
class CartaRow extends StatelessWidget {
  const new({
    required this.dish,
    required this.index,
    this.entrance = false,
    super.key,
  });

  final Dish dish;
  final int index;

  /// Rise into place after the earlier rows, on the menu's first load.
  final bool entrance;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final palette = context.palette;
    final format = Formatters(t.$meta.locale.languageCode);
    final price = format.price(dish.price);
    final rating = format.rating(dish.rating);

    final row = Pressable(
      semanticLabel: t.dishes.row.semantics(
        name: dish.name,
        price: price,
        rating: rating,
        protein: dish.proteins,
      ),
      onPressed: () =>
          context.router.push(DishDetailRoute(id: dish.id, initial: dish)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _photo,
              child: DishHero(
                tag: dishHeroTag(dish.id, .list),
                radius: Radii.sm,
                child: DishImage(
                  url: sizedImageUrl(
                    dish.thumbnail,
                    logicalWidth: _photo,
                    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  ),
                  name: dish.name,
                  borderRadius: const BorderRadius.all(.circular(Radii.sm)),
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  DishNameHero(
                    tag: dishNameHeroTag(dish.id, .list),
                    name: dish.name,
                    maxLines: 2,
                    style: EcoType.titleSmall.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    ingredientPreview(dish.ingredients),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EcoType.bodySmall.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Column(
              crossAxisAlignment: .end,
              children: [
                Text(
                  price,
                  style: EcoType.numeric.copyWith(color: palette.ink),
                ),
                const SizedBox(height: Space.xxs),
                Row(
                  mainAxisSize: .min,
                  spacing: Space.xxs,
                  children: [
                    Icon(EcoIcons.starFill, size: 12, color: palette.maiz),
                    Text(
                      rating,
                      style: EcoType.bodySmall.copyWith(
                        color: palette.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!entrance) return row;
    return _Entrance(delay: Motion.staggerDelay(index), child: row);
  }
}

class _Entrance extends StatefulWidget {
  const new({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final _rise = AnimationController(vsync: this, duration: Motion.slow);
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wait != null || _rise.value > 0) return;
    if (Motion.reduced(context)) {
      _rise.value = 1;
    } else {
      _wait = Timer(widget.delay, _rise.forward);
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _rise, curve: Motion.emphasized);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// The printer's mark at the end of the menu, with its dish count.
class CartaColophon extends StatelessWidget {
  const new({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl),
      child: Column(
        children: [
          LogoMark(size: 28, color: palette.muted, accent: palette.muted),
          const SizedBox(height: Space.sm),
          Text(
            context.t.dishes.home.count(n: count),
            style: EcoType.overline.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
