import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/presentation/home/discover_banner.dart';
import 'package:ecoeats/features/dishes/presentation/home/featured_carousel.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_header.dart';
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

  void _clearSearch() {
    _search.clear();
    ref.read(catalogFilterProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final searching = ref.watch(catalogFilterProvider).isSearching;
    final visible = ref.watch(visibleDishesProvider).value ?? const [];
    final featured = ref.watch(featuredDishesProvider).value ?? const [];
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.gutter,
              vertical: Space.md,
            ),
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, index) => Text(
                visible[index].name,
                style: EcoType.titleSmall.copyWith(color: palette.ink),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
