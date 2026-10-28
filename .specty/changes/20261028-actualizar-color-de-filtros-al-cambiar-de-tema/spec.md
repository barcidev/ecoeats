---
kind: quick
---

# Actualizar color de filtros al cambiar de tema

## Objetivo

Al cambiar entre modo claro y oscuro, la barra fija de filtros (`MenuFilters`) conservaba el fondo y el color de iconos del tema anterior porque `_FiltersDelegate.shouldRebuild` no tenía en cuenta la paleta. Pasamos la paleta de colores a `_FiltersDelegate`, comparamos la igualdad en `shouldRebuild` e implementamos igualdad por valor en `EcoPalette` para que la barra se actualice de inmediato al cambiar el tema.

## Archivos

- modificar lib/design/tokens/palette.dart — Implementar igualdad por valor y hashCode en EcoPalette
- modificar lib/features/dishes/presentation/home/menu_filters.dart — Pasar la paleta al delegado y reconstruir ante cambios de tema
- modificar test/features/dishes/presentation/home_menu_test.dart — Probar que el fondo de los filtros cambia con el tema

## Tareas

- [x] T1: Reconstruir los filtros del menú al cambiar de tema
  - files: lib/design/tokens/palette.dart, lib/features/dishes/presentation/home/menu_filters.dart, test/features/dishes/presentation/home_menu_test.dart
  - verify: fvm flutter test test/features/dishes/presentation/home_menu_test.dart
  - type: fix
