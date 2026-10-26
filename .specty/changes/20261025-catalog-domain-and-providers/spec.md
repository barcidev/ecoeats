---
kind: standard
follows:
  - 20261025-router-guards-and-app-shell
---

# Catalog domain and providers

## Goal

The catalog's logic exists and is tested before any of its screens: ingredients parsed without breaking what sits inside parentheses, a search that ignores accents and «ñ» over names and ingredients, dish photo URLs sized to the screen for Unsplash, and a freezed filter with the plan's categories and sort orders. Providers expose the filter, the visible dishes (the list after filter, search and sort), the featured dishes, and a dish detail that shows at once what the list already knows and then refreshes it from `GET /api/dish/{id}`.

## Out of scope

- Home, the carousel, filters UI, the detail screen and their copy (next catalog changes).
- Discover (agent C), which will read `visibleDishes`.

## Assumptions

- A1: Search matches every word of the query, in any order, against the dish name and its ingredients; «camaron» finds «Arroz con camarones».
- A2: Categories are Todos, Destacados (`flagHeader`), Altos en proteína (≥ 35 g) and Ligeros (≤ 35 g of carbohydrates); sorts are A–Z (default), best rated, price up, price down and most protein, with the name breaking ties.
- A3: Unsplash photos get `w` from buckets of 400, 800, 1200 and 1600 px (the smallest that covers the laid-out width times the pixel ratio), plus `q=75` and `auto=format`; presigned or other URLs stay as they are.
- A4: `dishDetail(id)` is a stream: it emits the list's copy first when there is one, then the server's; a 404 ends it in `notFound` even after the list's copy, because the dish is gone.

## Acceptance criteria

- AC1: WHEN «Frijoles rojos, arroz blanco, hogao (tomate, cebolla), aguacate» is parsed THEN it gives four ingredients, the third «hogao (tomate, cebolla)», with no empty or padded items.
- AC2: WHEN the query is «camaron» or «JALAPEÑO» THEN dishes whose name or ingredients say «camarones» or «jalapeño» match, and every word of a longer query must match.
- AC3: WHEN an Unsplash URL is sized for 180 logical px at 3x THEN its `w` is 800 with `q=75` and `auto=format`, keeping its other parameters; WHEN the URL is presigned or from another host THEN it comes back unchanged.
- AC4: WHEN a category, a query and a sort are applied THEN only the matching dishes remain, in the chosen order, ties broken by name.
- AC5: WHEN the filter changes THEN `visibleDishes` follows it without leaving its data state; `featuredDishes` holds only featured dishes whatever the filter.
- AC6: WHEN the detail of a listed dish opens THEN the list's copy is shown at once and the server's replaces it; WHEN the server answers 404 THEN the detail ends in `notFound`.

## Files

- create lib/features/dishes/domain/ingredients.dart — ingredient parser
- create lib/features/dishes/domain/text_search.dart — accent-free search
- create lib/features/dishes/domain/image_url.dart — sized Unsplash URLs
- create lib/features/dishes/domain/dish_filter.dart — category, query and sort (freezed)
- create lib/features/dishes/application/catalog_filter.dart — filter notifier
- create lib/features/dishes/application/catalog_views.dart — visible and featured dishes
- create lib/features/dishes/application/dish_detail_provider.dart — dish detail stream
- create test/helpers/dish_fixtures.dart — sample Colombian dishes
- create test/features/dishes/domain/ingredients_test.dart — parser tests
- create test/features/dishes/domain/text_search_test.dart — search tests
- create test/features/dishes/domain/image_url_test.dart — image URL tests
- create test/features/dishes/domain/dish_filter_test.dart — filter and sort tests
- create test/features/dishes/application/catalog_providers_test.dart — provider tests

## Tasks

- [x] T1: Ingredients, search and image URLs
  - files: lib/features/dishes/domain/ingredients.dart, lib/features/dishes/domain/text_search.dart, lib/features/dishes/domain/image_url.dart, test/features/dishes/domain/ingredients_test.dart, test/features/dishes/domain/text_search_test.dart, test/features/dishes/domain/image_url_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test test/features/dishes/domain
- [x] T2: Dish filter
  - files: lib/features/dishes/domain/dish_filter.dart, test/helpers/dish_fixtures.dart, test/features/dishes/domain/dish_filter_test.dart
  - ac: AC4
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes
- [ ] T3: Catalog providers and dish detail
  - files: lib/features/dishes/application/catalog_filter.dart, lib/features/dishes/application/catalog_views.dart, lib/features/dishes/application/dish_detail_provider.dart, test/features/dishes/application/catalog_providers_test.dart
  - ac: AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
