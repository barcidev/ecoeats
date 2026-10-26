import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/image_url.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:material_ui/material_ui.dart';

const _thumbWidth = 60.0;
const _thumbHeight = 76.0;

/// The way into Discover: three dishes fanned out like cards in a hand. It
/// remembers where it was touched so Discover can open from that point.
class DiscoverBanner extends StatefulWidget {
  const new({required this.dishes, super.key});

  /// The dishes Discover will walk through; the first three fan out.
  final List<Dish> dishes;

  @override
  State<DiscoverBanner> createState() => _DiscoverBannerState();
}

class _DiscoverBannerState extends State<DiscoverBanner> {
  Offset? _touch;

  @override
  Widget build(BuildContext context) {
    final t = context.t.dishes.discover;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Listener(
        onPointerDown: (event) => _touch = event.position,
        child: Pressable(
          semanticLabel: t.open,
          onPressed: () =>
              context.router.push(DiscoverRoute(revealOrigin: _touch)),
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: ShapeDecoration(
              color: palette.raised,
              shape: RoundedSuperellipseBorder(
                borderRadius: const BorderRadius.all(.circular(Radii.lg)),
                side: BorderSide(color: palette.line),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        t.title,
                        style: EcoType.title.copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        t.subtitle,
                        style: EcoType.bodySmall.copyWith(color: palette.muted),
                      ),
                      const SizedBox(height: Space.sm),
                      Icon(EcoIcons.arrowUp, size: 18, color: palette.achiote),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                _Fan(dishes: widget.dishes.take(3).toList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fan extends StatelessWidget {
  const new({required this.dishes});

  final List<Dish> dishes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    const angles = [-0.18, 0.0, 0.18];
    return SizedBox(
      width: _thumbWidth * 2.1,
      height: _thumbHeight * 1.15,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final (index, dish) in dishes.indexed)
            Transform.translate(
              offset: Offset((index - 1) * _thumbWidth * 0.55, 0),
              child: Transform.rotate(
                angle: angles[index] * (dishes.length == 1 ? 0 : 1),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _thumbWidth,
                  height: _thumbHeight,
                  padding: const EdgeInsets.all(2),
                  decoration: ShapeDecoration(
                    color: palette.raised,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: const BorderRadius.all(.circular(Radii.sm)),
                      side: BorderSide(color: palette.line),
                    ),
                  ),
                  child: DishImage(
                    url: sizedImageUrl(
                      dish.thumbnail,
                      logicalWidth: _thumbWidth,
                      devicePixelRatio: ratio,
                    ),
                    name: dish.name,
                    borderRadius: const BorderRadius.all(
                      .circular(Radii.sm - 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
