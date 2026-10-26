import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder: shows the dish name until the catalog's detail lands.
@RoutePage()
class DishDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(initial?.name ?? id)),
    );
  }
}
