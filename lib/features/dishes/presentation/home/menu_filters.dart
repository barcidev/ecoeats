import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/features/dishes/domain/dish_filter.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:material_ui/material_ui.dart';

String categoryLabel(Translations t, DishCategory category) =>
    switch (category) {
      .all => t.dishes.filters.all,
      .featured => t.dishes.filters.featured,
      .highProtein => t.dishes.filters.highProtein,
      .light => t.dishes.filters.light,
    };

String sortLabel(Translations t, DishSort sort) => switch (sort) {
  .alphabetical => t.dishes.sort.alphabetical,
  .topRated => t.dishes.sort.topRated,
  .priceLow => t.dishes.sort.priceLow,
  .priceHigh => t.dishes.sort.priceHigh,
  .mostProtein => t.dishes.sort.mostProtein,
};

/// The category pills and the sort button, pinned under the header so the
/// menu can be narrowed from anywhere down the list.
class MenuFilters extends StatelessWidget {
  const new({
    required this.filter,
    required this.onCategory,
    required this.onSort,
    super.key,
  });

  final DishFilter filter;
  final ValueChanged<DishCategory> onCategory;
  final ValueChanged<DishSort> onSort;

  @override
  Widget build(BuildContext context) {
    final extent = MediaQuery.textScalerOf(context).scale(36) + Space.sm * 2;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FiltersDelegate(
        extent: extent,
        filter: filter,
        palette: context.palette,
        onCategory: onCategory,
        onSort: onSort,
      ),
    );
  }
}

class _FiltersDelegate extends SliverPersistentHeaderDelegate {
  const new({
    required this.extent,
    required this.filter,
    required this.palette,
    required this.onCategory,
    required this.onSort,
  });

  final double extent;
  final DishFilter filter;
  final EcoPalette palette;
  final ValueChanged<DishCategory> onCategory;
  final ValueChanged<DishSort> onSort;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(_FiltersDelegate oldDelegate) =>
      oldDelegate.filter != filter ||
      oldDelegate.extent != extent ||
      oldDelegate.palette != palette;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = context.t;
    final palette = context.palette;
    // A persistent header must fill its extent, or its geometry breaks.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.paper,
        border: Border(
          bottom: BorderSide(color: overlaps ? palette.line : palette.paper),
        ),
      ),
      child: SizedBox.expand(
        child: Row(
          children: [
            Expanded(
              // The pills that do not fit fade out before the sort button
              // instead of being cut against it.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [Color(0xFF000000), Color(0x00000000)],
                  stops: [1 - Space.lg / bounds.width, 1],
                ).createShader(bounds),
                child: SegmentedPills<DishCategory>(
                  values: DishCategory.values,
                  selected: filter.category,
                  labelOf: (category) => categoryLabel(t, category),
                  onChanged: onCategory,
                  padding: const EdgeInsets.only(
                    left: Space.gutter,
                    right: Space.lg,
                  ),
                ),
              ),
            ),
            Pressable(
              semanticLabel: t.dishes.sort.button(
                sort: sortLabel(t, filter.sort),
              ),
              onPressed: () => showSortSheet(
                context,
                current: filter.sort,
                onSelected: onSort,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xs,
                  Space.sm,
                  Space.gutter,
                  Space.sm,
                ),
                child: Icon(EcoIcons.arrowsDownUp, color: palette.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSortSheet(
  BuildContext context, {
  required DishSort current,
  required ValueChanged<DishSort> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final t = context.t;
      final palette = context.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, Space.lg),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.sm,
              ),
              child: Text(
                t.dishes.sort.title,
                style: EcoType.title.copyWith(color: palette.ink),
              ),
            ),
            for (final sort in DishSort.values)
              MergeSemantics(
                child: Semantics(
                  selected: sort == current,
                  child: Pressable(
                    onPressed: () {
                      onSelected(sort);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.gutter,
                        vertical: Space.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sortLabel(t, sort),
                              style: EcoType.body.copyWith(color: palette.ink),
                            ),
                          ),
                          if (sort == current)
                            Icon(EcoIcons.check, color: palette.achiote),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
