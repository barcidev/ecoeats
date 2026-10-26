import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/presentation/home/carta.dart';
import 'package:ecoeats/features/dishes/presentation/home/discover_banner.dart';
import 'package:ecoeats/features/dishes/presentation/home/featured_carousel.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_header.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_states.dart';
import 'package:ecoeats/features/dishes/presentation/home/menu_filters.dart';
import 'package:ecoeats/i18n/failure_text.dart';
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

  Future<void> _refresh() => ref.read(dishesProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(dishesProvider);
    ref.listen(dishesProvider, (previous, next) {
      // A failed refresh keeps the menu on screen; only a toast says why.
      if (previous?.isLoading != true || !next.hasValue || next.isLoading) {
        return;
      }
      if (next.error case final Object error) {
        Toast.show(
          context,
          failureMessage(toFailure(error), context.t),
          tone: .alert,
        );
      }
    });

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          HomeHeader(
            search: _search,
            onSearchChanged: ref.read(catalogFilterProvider.notifier).search,
            onSearchCleared: _clearSearch,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: _refresh,
            builder: _plateRefresh,
          ),
          ...switch (menu) {
            AsyncValue(hasValue: false, :final error?) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: HomeFailure(
                  failure: toFailure(error),
                  onRetry: _refresh,
                ),
              ),
            ],
            AsyncValue(hasValue: false) => [
              const SliverToBoxAdapter(child: HomeSkeleton()),
            ],
            _ => _menu(context),
          },
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }

  List<Widget> _menu(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(catalogFilterProvider);
    final filters = ref.read(catalogFilterProvider.notifier);
    final searching = filter.isSearching;
    final visible = ref.watch(visibleDishesProvider).value ?? const [];
    final featured = ref.watch(featuredDishesProvider).value ?? const [];
    if (visible.isNotEmpty && !_entered) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _entered = true);
    }

    return [
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
          sliver: SliverToBoxAdapter(child: DiscoverBanner(dishes: visible)),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
      MenuFilters(
        filter: filter,
        onCategory: filters.select,
        onSort: filters.sortBy,
      ),
      if (visible.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyMenu(
            query: filter.query,
            onClearSearch: _clearSearch,
            onShowAll: () => filters.select(.all),
          ),
        )
      else ...[
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
        SliverToBoxAdapter(child: CartaColophon(count: visible.length)),
      ],
    ];
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
