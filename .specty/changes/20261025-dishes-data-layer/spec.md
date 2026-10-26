---
kind: standard
follows:
  - 20261025-session-and-auth-interceptor
---

# Dishes data layer

## Goal

The catalog has its data: a freezed `Dish` read from the production contract (with the intentional `thumbails` typo), a `DishApi` and `DishRepository` for `GET /api/dish` and `GET /api/dish/{id}`, and a `dishesProvider` that loads the list and refreshes it keeping the previous one on screen. Home and the dish detail exist as `@RoutePage` placeholders, with a fade transition and hero tags that carry their source, so the router can register them.

## Out of scope

- The domain helpers (ingredients parser, accent-free search, image URLs, filters) and every catalog screen beyond the placeholders (agent B changes).
- The router itself (routes change).

## Assumptions

- A1: `price` and `rating` arrive as JSON numbers that may be integers, so they are read as `num` and kept as `double`.
- A2: Image URLs are temporary: the model keeps them as they come and nothing persists them.
- A3: Hero tags are `dish-<id>-<source>` with source `carousel`, `list` or `discover`, because a featured dish shows twice on Home.
- A4: The detail route receives the dish id as a path parameter plus an optional `initial` dish and a `heroSource`.

## Acceptance criteria

- AC1: WHEN a dish JSON from the API is read THEN `thumbails` becomes `thumbnail`, `flagHeader` becomes `featured`, and an integer price or rating is read as a double.
- AC2: WHEN the repository lists dishes THEN it returns them parsed from the envelope; WHEN it asks for one that does not exist THEN it throws `AppFailure.notFound`.
- AC3: WHEN `dishesProvider` is read THEN it holds the repository's list; WHEN it is refreshed THEN it fetches again and its future completes with the new list.
- AC4: WHEN a hero tag is built THEN it reads `dish-<id>-<source>`, and the Home and detail placeholders are annotated with `@RoutePage`.

## Files

- create lib/features/dishes/domain/dish.dart — Dish model (freezed and json)
- create lib/features/dishes/data/dish_api.dart — dish endpoints and provider
- create lib/features/dishes/data/dish_repository.dart — dish repository and provider
- create lib/features/dishes/application/dishes_provider.dart — dish list with refresh
- create lib/features/dishes/presentation/dish_transitions.dart — fade transition, hero source and tag
- create lib/features/dishes/presentation/home/home_page.dart — Home placeholder page
- create lib/features/dishes/presentation/detail/dish_detail_page.dart — detail placeholder page
- create test/features/dishes/domain/dish_test.dart — JSON tests
- create test/features/dishes/data/dish_repository_test.dart — repository tests
- create test/features/dishes/application/dishes_provider_test.dart — provider tests

## Tasks

- [x] T1: Dish model
  - files: lib/features/dishes/domain/dish.dart, test/features/dishes/domain/dish_test.dart
  - ac: AC1
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes
- [ ] T2: DishApi, DishRepository and dishesProvider
  - files: lib/features/dishes/data/dish_api.dart, lib/features/dishes/data/dish_repository.dart, lib/features/dishes/application/dishes_provider.dart, test/features/dishes/data/dish_repository_test.dart, test/features/dishes/application/dishes_provider_test.dart
  - ac: AC2, AC3
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes
- [ ] T3: Placeholder pages and transitions
  - files: lib/features/dishes/presentation/dish_transitions.dart, lib/features/dishes/presentation/home/home_page.dart, lib/features/dishes/presentation/detail/dish_detail_page.dart, test/features/dishes/domain/dish_test.dart
  - ac: AC4
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
