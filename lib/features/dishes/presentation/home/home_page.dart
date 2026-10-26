import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_header.dart';
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
    final visible = ref.watch(visibleDishesProvider).value ?? const [];
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
