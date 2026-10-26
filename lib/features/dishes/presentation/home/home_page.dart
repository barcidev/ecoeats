import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder: lists the dish names until the catalog's Home lands.
@RoutePage()
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishes = ref.watch(dishesProvider);
    return Scaffold(
      body: SafeArea(
        child: switch (dishes) {
          AsyncData(:final value) => ListView(
            children: [
              for (final dish in value) ListTile(title: Text(dish.name)),
            ],
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
