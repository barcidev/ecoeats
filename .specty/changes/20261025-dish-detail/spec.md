---
kind: standard
follows:
  - 20261025-home-menu-refresh-and-states
---

# Dish detail

## Goal

A dish opens the way the plan describes: its photo flies from where it was tapped (carousel, list or Discover) into the top 58 % of the screen, which moves at half speed while scrolling and stretches when pulled; the content sheet rises a moment after with an overline, the name, fractional stars and the price, the description, carbohydrate and protein bars that fill with rolling figures (no invented calories), and the ingredients numbered 01, 02…. Pulling the page down from the top shrinks it toward 0.9 with Home showing behind and closes it past a threshold. A dish that is gone says it is no longer on the menu.

## Out of scope

- The flight shuttle that interpolates corner radius and text style (agent C's `DishHero`).
- Discover's own entry into the detail (agent C).

## Assumptions

- A1: The photo is a non-pinned stretching header: half-speed parallax while it scrolls away, zoom when pulled down at the top; a floating close button stays over it.
- A2: Pulling down from the top first stretches the photo and scales the page toward 0.9; releasing past 120 px of pull closes the detail, otherwise everything springs back.
- A3: The macro bars share a fixed 100 g scale, so dishes can be compared at a glance; carbohydrates use maíz and protein aguacate.
- A4: While the server copy loads, the list's copy (or the route's `initial` dish) is shown; a failure after that keeps it on screen, except a 404, which replaces it with the «gone» state.
- A5: The content rises 120 ms after the route starts; with reduced motion the bars and figures appear at their final values and nothing rises.

## Acceptance criteria

- AC1: WHEN a featured card is tapped THEN the detail shows the dish's photo under the same hero tag, its overline, name, rating read as «4,9 de 5», price and description.
- AC2: WHEN the detail settles THEN the carbohydrate and protein bars read «Carbohidratos, 85 g» and «Proteínas, 55 g», and the ingredients are listed in order numbered «01», «02»… with parentheses kept inside their ingredient.
- AC3: WHEN the server answers with a newer copy THEN the detail shows it in place of the list's.
- AC4: WHEN the server answers 404 THEN the detail reads «Este plato ya no está en la carta.» and its action goes back to Home.
- AC5: WHEN the page is pulled down past the threshold from the top THEN the detail closes and Home is on screen; WHEN the pull is short THEN it stays.

## Files

- modify lib/features/dishes/presentation/detail/dish_detail_page.dart — detail page with photo header, states and close button
- create lib/features/dishes/presentation/detail/dish_detail_body.dart — overline, name, rating, price, description and ingredients
- create lib/features/dishes/presentation/detail/macro_bars.dart — animated macro bars with rolling figures
- create lib/features/dishes/presentation/detail/swipe_to_dismiss.dart — pull-down-to-close behaviour
- modify lib/i18n/es/dishes.i18n.yaml — Spanish detail copy
- modify lib/i18n/en/dishes.i18n.yaml — English detail copy
- create test/features/dishes/presentation/dish_detail_test.dart — detail tests over the running app

## Tasks

- [x] T1: Detail content: header, macros and ingredients
  - files: lib/features/dishes/presentation/detail/dish_detail_page.dart, lib/features/dishes/presentation/detail/dish_detail_body.dart, lib/features/dishes/presentation/detail/macro_bars.dart, lib/i18n/es/dishes.i18n.yaml, lib/i18n/en/dishes.i18n.yaml, test/features/dishes/presentation/dish_detail_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes test/i18n
- [ ] T2: Pull down to close
  - files: lib/features/dishes/presentation/detail/swipe_to_dismiss.dart, lib/features/dishes/presentation/detail/dish_detail_page.dart, test/features/dishes/presentation/dish_detail_test.dart
  - ac: AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
