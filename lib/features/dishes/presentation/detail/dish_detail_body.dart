import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/ingredients.dart';
import 'package:ecoeats/features/dishes/presentation/detail/macro_bars.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:material_ui/material_ui.dart';

/// Everything under the photo: what the dish is, what it costs, what it
/// brings and what goes into it.
class DishDetailBody extends StatelessWidget {
  const new({required this.dish, super.key});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final palette = context.palette;
    final format = Formatters(t.$meta.locale.languageCode);
    final rating = format.rating(dish.rating);
    final ingredients = parseIngredients(dish.ingredients);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.xs,
        Space.gutter,
        Space.xxl,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            (dish.featured
                    ? t.dishes.detail.featured
                    : t.dishes.detail.fromMenu)
                .toUpperCase(),
            style: EcoType.overline.copyWith(color: palette.achiote),
          ),
          const SizedBox(height: Space.xs),
          Text(dish.name, style: EcoType.headline.copyWith(color: palette.ink)),
          const SizedBox(height: Space.md),
          Row(
            children: [
              RatingStars(
                rating: dish.rating,
                size: 16,
                semanticLabel: t.dishes.detail.rating(rating: rating),
              ),
              const SizedBox(width: Space.xs),
              ExcludeSemantics(
                child: Text(
                  rating,
                  style: EcoType.bodySmall.copyWith(color: palette.muted),
                ),
              ),
              const Spacer(),
              Text(
                format.price(dish.price),
                style: EcoType.title.copyWith(
                  color: palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(
            dish.description,
            style: EcoType.body.copyWith(color: palette.ink),
          ),
          const SizedBox(height: Space.xl),
          _SectionTitle(
            title: t.dishes.detail.nutrition,
            note: t.dishes.detail.perServing,
          ),
          const SizedBox(height: Space.md),
          MacroBars(carbohydrates: dish.carbohydrates, proteins: dish.proteins),
          const SizedBox(height: Space.xl),
          _SectionTitle(title: t.dishes.detail.ingredients),
          const SizedBox(height: Space.xs),
          for (final (index, ingredient) in ingredients.indexed)
            _Ingredient(
              number: (index + 1).toString().padLeft(2, '0'),
              name: ingredient,
              last: index == ingredients.length - 1,
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: .baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(title, style: EcoType.title.copyWith(color: palette.ink)),
        ),
        if (note case final note?)
          Text(note, style: EcoType.bodySmall.copyWith(color: palette.muted)),
      ],
    );
  }
}

/// «01  Frijoles rojos»: numbered like the steps of a recipe card.
class _Ingredient extends StatelessWidget {
  const new({required this.number, required this.name, required this.last});

  final String number;
  final String name;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: Space.xl,
            child: Text(
              number,
              style: EcoType.numeric.copyWith(color: palette.achiote),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(name, style: EcoType.body.copyWith(color: palette.ink)),
          ),
        ],
      ),
    );
  }
}
