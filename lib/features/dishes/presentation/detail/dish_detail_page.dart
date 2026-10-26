import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/dish_hero.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:ecoeats/features/dishes/application/dish_detail_provider.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/image_url.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_body.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

@RoutePage()
class DishDetailPage extends ConsumerWidget {
  const new({
    @PathParam('id') required this.id,
    this.initial,
    this.heroSource = .list,
    super.key,
  });

  final String id;

  /// The dish as the list already knows it, shown while the detail loads.
  final Dish? initial;
  final HeroSource heroSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final detail = ref.watch(dishDetailProvider(id));
    final dish = detail.value ?? initial;
    final error = detail.error;

    final Widget content;
    if (error is NotFoundFailure) {
      content = StateView(
        kind: .empty,
        title: t.dishes.detail.gone,
        message: t.dishes.detail.goneHint,
        actionLabel: t.dishes.detail.backToMenu,
        onAction: () => context.router.maybePop(),
      );
    } else if (dish != null) {
      content = _DishScroll(dish: dish, heroSource: heroSource);
    } else if (error != null) {
      final copy = failureCopy(toFailure(error), t);
      content = StateView(
        kind: .error,
        title: copy.title,
        message: copy.message,
        footnote: copy.reference,
        actionLabel: t.common.actions.retry,
        onAction: () => ref.invalidate(dishDetailProvider(id)),
      );
    } else {
      content = const Center(child: PlateSpinner(size: 32));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: MediaQuery.paddingOf(context).top + Space.xs,
            left: Space.gutter,
            child: _CloseButton(label: t.dishes.detail.close),
          ),
        ],
      ),
    );
  }
}

class _DishScroll extends StatelessWidget {
  const new({required this.dish, required this.heroSource});

  final Dish dish;
  final HeroSource heroSource;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = MediaQuery.sizeOf(context);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // The photo takes the top 58 %, scrolls away at half speed and
        // stretches when the page is pulled down.
        SliverAppBar(
          expandedHeight: size.height * 0.58,
          stretch: true,
          automaticallyImplyLeading: false,
          backgroundColor: palette.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 0,
          collapsedHeight: 0,
          // Parallax collapse and zoom stretch are the bar's defaults.
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                DishHero(
                  tag: dishHeroTag(dish.id, heroSource),
                  child: DishImage(
                    url: sizedImageUrl(
                      dish.image,
                      logicalWidth: size.width,
                      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    ),
                    name: dish.name,
                  ),
                ),
                // The sheet's rounded shoulders, drawn here because the bar
                // paints above the slivers that follow it.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  height: Radii.lg + 1,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.paper,
                      shape: const RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.vertical(
                          top: .circular(Radii.lg),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _RisingSheet(child: DishDetailBody(dish: dish)),
        ),
      ],
    );
  }
}

/// The content rises a beat after the photo lands.
class _RisingSheet extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheet = ColoredBox(color: context.palette.paper, child: child);
    final route = ModalRoute.of(context)?.animation;
    if (route == null || Motion.reduced(context)) return sheet;
    // A 300 ms route: the sheet starts 120 ms in.
    final rise = CurvedAnimation(
      parent: route,
      curve: const Interval(0.4, 1, curve: Motion.emphasized),
    );
    return FadeTransition(
      opacity: rise,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(rise),
        child: sheet,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      semanticLabel: label,
      onPressed: () => context.router.maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          color: palette.raised.withValues(alpha: 0.92),
          shape: CircleBorder(side: BorderSide(color: palette.line)),
        ),
        child: Icon(EcoIcons.x, size: 18, color: palette.ink),
      ),
    );
  }
}
