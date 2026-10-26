import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/domain/dish_filter.dart';
import 'package:ecoeats/features/dishes/presentation/home/carta.dart';
import 'package:ecoeats/features/dishes/presentation/home/discover_banner.dart';
import 'package:ecoeats/features/dishes/presentation/home/featured_carousel.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_header.dart';
import 'package:ecoeats/features/dishes/presentation/home/menu_filters.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final _search = TextEditingController(
    text: ref.read(catalogFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Rows rise into place only the first time the menu appears.
  var _entered = false;

  void _clearSearch() {
    _search.clear();
    ref.read(catalogFilterProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(catalogFilterProvider);
    final searching = filter.isSearching;
    final filters = ref.read(catalogFilterProvider.notifier);
    final visible = ref.watch(visibleDishesProvider).value ?? const [];
    final featured = ref.watch(featuredDishesProvider).value ?? const [];
    if (visible.isNotEmpty && !_entered) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _entered = true);
    }
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          HomeHeader(
            search: _search,
            onSearchChanged: filters.search,
            onSearchCleared: _clearSearch,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: ref.read(dishesProvider.notifier).refresh,
            builder: _plateRefresh,
          ),
          // A search is a question: only its answers stay on screen.
          if (!searching && featured.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.lg,
                  Space.gutter,
                  Space.sm,
                ),
                child: Text(
                  context.t.dishes.featured.title.toUpperCase(),
                  style: EcoType.overline.copyWith(color: palette.muted),
                ),
              ),
            ),
            SliverToBoxAdapter(child: FeaturedCarousel(dishes: featured)),
          ],
          if (!searching && visible.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: Space.xl),
              sliver: SliverToBoxAdapter(
                child: DiscoverBanner(dishes: visible),
              ),
            ),
          if (visible.isNotEmpty || filter != const DishFilter()) ...[
            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
            MenuFilters(
              filter: filter,
              onCategory: filters.select,
              onSort: filters.sortBy,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.lg,
                  Space.gutter,
                  Space.xs,
                ),
                child: Text(
                  context.t.dishes.home.carta,
                  style: EcoType.headline.copyWith(color: palette.ink),
                ),
              ),
            ),
            SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => Divider(
                indent: Space.gutter,
                endIndent: Space.gutter,
                color: palette.line,
              ),
              itemBuilder: (context, index) => CartaRow(
                key: ValueKey(visible[index].id),
                dish: visible[index],
                index: index,
                entrance: !_entered && index < Motion.maxStaggered,
              ),
            ),
            if (visible.isNotEmpty)
              SliverToBoxAdapter(child: CartaColophon(count: visible.length)),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}

/// The pull-to-refresh indicator: a plate whose rim fills with the pull and
/// turns once the menu is being fetched again.
Widget _plateRefresh(
  BuildContext context,
  RefreshIndicatorMode mode,
  double pulledExtent,
  double triggerDistance,
  double indicatorExtent,
) {
  final pulled = (pulledExtent / triggerDistance).clamp(0.0, 1.0);
  final turning = mode == .armed || mode == .refresh;
  return Center(
    child: Opacity(
      opacity: mode == .done ? 0 : pulled,
      child: PlateSpinner(size: 28, progress: turning ? null : pulled),
    ),
  );
}
