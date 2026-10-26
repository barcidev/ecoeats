import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/format/formatters.dart';
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
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:material_ui/material_ui.dart';

const _viewport = 0.78;

/// The featured dishes as 4:5 cards: the one in the middle full size, its
/// neighbours a little smaller, and each photo drifting against the swipe.
class FeaturedCarousel extends StatefulWidget {
  const new({required this.dishes, super.key});

  final List<Dish> dishes;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final _pages = PageController(viewportFraction: _viewport);
  var _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * _viewport;
    final dishes = widget.dishes;
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          height: width * 5 / 4,
          child: PageView.builder(
            controller: _pages,
            itemCount: dishes.length,
            onPageChanged: (page) => setState(() => _current = page),
            itemBuilder: (context, index) => _CarouselPage(
              controller: _pages,
              index: index,
              total: dishes.length,
              dish: dishes[index],
              width: width,
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Center(
          child: _PageIndicator(count: dishes.length, current: _current),
        ),
      ],
    );
  }
}

class _CarouselPage extends StatelessWidget {
  const new({
    required this.controller,
    required this.index,
    required this.total,
    required this.dish,
    required this.width,
  });

  final PageController controller;
  final int index;
  final int total;
  final Dish dish;
  final double width;

  @override
  Widget build(BuildContext context) {
    final still = Motion.reduced(context);
    return AnimatedBuilder(
      animation: controller,
      child: _Card(dish: dish, index: index, total: total, width: width),
      builder: (context, card) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? controller.initialPage.toDouble()
            : controller.initialPage.toDouble();
        final offset = still ? 0.0 : (page - index).clamp(-1.0, 1.0);
        return Transform.scale(
          scale: 1 - 0.07 * offset.abs(),
          child: _Parallax(offset: offset, child: card!),
        );
      },
    );
  }
}

/// Hands the page offset down to the photo, which moves against the swipe.
class _Parallax extends InheritedWidget {
  const new({required this.offset, required super.child});

  final double offset;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Parallax>()?.offset ?? 0;

  @override
  bool updateShouldNotify(_Parallax oldWidget) => oldWidget.offset != offset;
}

class _Card extends StatelessWidget {
  const new({
    required this.dish,
    required this.index,
    required this.total,
    required this.width,
  });

  final Dish dish;
  final int index;
  final int total;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final format = Formatters(t.$meta.locale.languageCode);
    final price = format.price(dish.price);
    final rating = format.rating(dish.rating);
    // Over the dark scrim the text keeps Fogón's ink in both themes.
    const onPhoto = Color(0xFFF3ECE1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Pressable(
        semanticLabel: t.dishes.featured.card(
          current: index + 1,
          total: total,
          name: dish.name,
          price: price,
          rating: rating,
        ),
        onPressed: () => context.router.push(
          DishDetailRoute(id: dish.id, initial: dish, heroSource: .carousel),
        ),
        child: ClipRSuperellipse(
          borderRadius: const BorderRadius.all(.circular(Radii.lg)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DishHero(
                tag: dishHeroTag(dish.id, .carousel),
                radius: Radii.lg,
                child: _DriftingPhoto(dish: dish, width: width),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB8140F0B)],
                  ),
                ),
              ),
              Positioned(
                left: Space.lg,
                right: Space.lg,
                bottom: Space.lg,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      dish.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EcoType.title.copyWith(color: onPhoto),
                    ),
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          price,
                          style: EcoType.numeric.copyWith(color: onPhoto),
                        ),
                        Text(
                          '·',
                          style: EcoType.numeric.copyWith(color: onPhoto),
                        ),
                        Icon(
                          EcoIcons.starFill,
                          size: 14,
                          color: context.palette.maiz,
                        ),
                        Text(
                          rating,
                          style: EcoType.numeric.copyWith(color: onPhoto),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriftingPhoto extends StatelessWidget {
  const new({required this.dish, required this.width});

  final Dish dish;
  final double width;

  @override
  Widget build(BuildContext context) {
    final offset = _Parallax.of(context);
    return Transform.translate(
      offset: Offset(-offset * width * 0.12, 0),
      child: Transform.scale(
        scale: 1.16,
        child: DishImage(
          url: sizedImageUrl(
            dish.image,
            logicalWidth: width * 1.16,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          ),
          name: dish.name,
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const new({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The cards already say «Destacado N de M»; the dots are for the eye.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: .min,
        spacing: Space.xs,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              key: ValueKey('featured-dot-$index'),
              duration: Motion.standard,
              curve: Motion.emphasized,
              width: index == current ? 20 : 6,
              height: 6,
              decoration: ShapeDecoration(
                color: index == current ? palette.achiote : palette.line,
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
