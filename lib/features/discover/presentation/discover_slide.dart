import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_hero.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/image_url.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/widgets.dart';

/// Discover is always on a photo, whatever the theme: its words take the
/// night palette's light ink and corn yellow.
const EcoPalette _onPhoto = EcoPalette.fogon;

/// How far the words lead and the photo trails while the finger drags, as a
/// share of the screen's height. The photo's lag stays inside the slack its
/// resting zoom leaves, so no edge ever shows.
const _textLead = 0.3;
const _photoLag = 0.08;
const _restingZoom = 1.1;

/// One dish of Discover, full-bleed. While its page is the active one, the
/// photo pushes in slowly (Ken Burns); while the finger drags, the words lead
/// and the photo trails, so the page reads in depth.
class DiscoverSlide extends StatefulWidget {
  const new({
    required this.dish,
    required this.index,
    required this.pager,
    required this.active,
    required this.onOpen,
    super.key,
  });

  final Dish dish;
  final int index;
  final PageController pager;

  /// Only the page at rest on screen zooms; the others hold still.
  final bool active;

  /// Opens the dish's detail.
  final VoidCallback onOpen;

  @override
  State<DiscoverSlide> createState() => _DiscoverSlideState();
}

class _DiscoverSlideState extends State<DiscoverSlide>
    with SingleTickerProviderStateMixin {
  // A slow push-in that turns around every nine seconds.
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DiscoverSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      if (!_drift.isAnimating) _drift.repeat(reverse: true);
    } else {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// How far this page is from rest: 0 on screen, 1 one page above, -1 one
  /// page below.
  double get _offset {
    final pager = widget.pager;
    if (!pager.hasClients || !pager.position.haveDimensions) return 0;
    return (pager.page ?? widget.index.toDouble()) - widget.index;
  }

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;
    final t = context.t;
    final format = Formatters(t.$meta.locale.languageCode);
    final price = format.price(dish.price);
    final rating = format.rating(dish.rating);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final reduced = Motion.reduced(context);

    final photo = DishHero(
      tag: dishHeroTag(dish.id, .discover),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([_drift, widget.pager]),
          child: DishImage(
            url: sizedImageUrl(
              dish.image,
              logicalWidth: size.width * _restingZoom,
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
            ),
            name: dish.name,
          ),
          builder: (context, child) {
            if (reduced) return child!;
            final push = Curves.easeInOut.transform(_drift.value);
            return Transform.translate(
              offset: Offset(
                -push * size.width * 0.02,
                _offset * size.height * _photoLag - push * size.height * 0.015,
              ),
              child: Transform.scale(
                scale: _restingZoom + push * 0.12,
                child: child,
              ),
            );
          },
        ),
      ),
    );

    final words = Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        if (dish.featured) ...[
          Text(
            t.discover.featured.toUpperCase(),
            style: EcoType.overline.copyWith(color: _onPhoto.maiz),
          ),
          const SizedBox(height: Space.xs),
        ],
        DishNameHero(
          tag: dishNameHeroTag(dish.id, .discover),
          name: dish.name,
          maxLines: 3,
          style: EcoType.display.copyWith(fontSize: 40, color: _onPhoto.ink),
        ),
        const SizedBox(height: Space.sm),
        Row(
          spacing: Space.xs,
          children: [
            Text(price, style: EcoType.numeric.copyWith(color: _onPhoto.ink)),
            Text('·', style: EcoType.numeric.copyWith(color: _onPhoto.muted)),
            RatingStars(rating: dish.rating, color: _onPhoto.maiz),
            Text(
              rating,
              style: EcoType.bodySmall.copyWith(color: _onPhoto.muted),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(
          dish.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: EcoType.body.copyWith(
            color: _onPhoto.ink.withValues(alpha: 0.82),
          ),
        ),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // The page reads as one sentence; the visuals say the same again.
        Semantics(
          container: true,
          label: t.discover.page(name: dish.name, price: price, rating: rating),
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo,
                const _Scrims(),
                Positioned(
                  left: Space.gutter,
                  right: Space.gutter * 2,
                  bottom:
                      padding.bottom + Space.xxl + EcoType.label.fontSize! * 3,
                  child: AnimatedBuilder(
                    animation: widget.pager,
                    child: words,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        reduced ? 0 : -_offset * size.height * _textLead,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: Space.gutter,
          bottom: padding.bottom + Space.xl,
          child: _SeeDish(label: t.discover.seeDish, onPressed: widget.onOpen),
        ),
      ],
    );
  }
}

/// Dark at the top for the counter and the close button, and deep at the
/// bottom where the words sit, so light ink reads on any photo.
class _Scrims extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.22, 0.45, 1],
            colors: [
              Color(0x73140F0B),
              Color(0x00140F0B),
              Color(0x00140F0B),
              Color(0xD9140F0B),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeDish extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // The arrow is drawn as an icon, so readers hear only the words.
    final words = label.replaceAll('↑', '').trim();
    return Pressable(
      semanticLabel: words,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: _onPhoto.ink.withValues(alpha: 0.12),
          shape: StadiumBorder(
            side: BorderSide(color: _onPhoto.ink.withValues(alpha: 0.5)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: Space.xs,
            children: [
              Text(words, style: EcoType.label.copyWith(color: _onPhoto.ink)),
              Icon(EcoIcons.arrowUp, size: 18, color: _onPhoto.ink),
            ],
          ),
        ),
      ),
    );
  }
}
