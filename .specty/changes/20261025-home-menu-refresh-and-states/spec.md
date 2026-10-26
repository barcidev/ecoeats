---
kind: standard
follows:
  - 20261025-home-header-featured-carousel-and-discover-banne
---

# Home menu, refresh and states

## Goal

«La carta» becomes the editorial menu of the plan: pinned category pills with a sort sheet, rows with photo, name, a taste of the ingredients, price and rating, a plate-shaped pull-to-refresh with bouncing physics, and a colophon that counts the dishes in the right plural. Every unhappy moment is designed: a skeleton shaped like the real layout while the list first loads, an empty search that offers to clear itself, and full-screen states for offline, too many requests (with its countdown), a server failure (with its reference) and anything else, each with a retry. A failed refresh keeps the menu on screen and says so in a toast.

## Out of scope

- The dish detail screen (next change).
- Discover (agent C).

## Assumptions

- A1: The pills are Todos, Destacados, Altos en proteína and Ligeros; the sort sheet offers A–Z, best rated, price up, price down and most protein, and marks the current one.
- A2: Rows enter staggered by 40 ms, at most six, only on the first load of the list; with reduced motion they appear at once.
- A3: Pull-to-refresh is a `CupertinoSliverRefreshControl` whose indicator is the `PlateSpinner`, filling with the pull and turning while it refreshes.
- A4: A failure without data takes the whole space under the header; a failure with data (a refresh) is a toast and the list stays.
- A5: A row's photo is its thumbnail sized for 72 logical px; a broken photo shows the dish placeholder with its initials.

## Acceptance criteria

- AC1: WHEN a pill is tapped THEN «La carta» shows only that category; WHEN a sort is chosen in the sheet THEN the rows follow that order and the sheet closes; the pills stay pinned under the header while scrolling.
- AC2: WHEN the list is loaded THEN each row shows the dish's name, its first ingredients, price and rating, is read as one sentence, and opens the dish's detail; the colophon reads «12 platos» («12 dishes» in English), and «1 plato» for one.
- AC3: WHEN the list is pulled down THEN it is fetched again and the new dishes replace the old ones.
- AC4: WHEN the list is still loading for the first time THEN a skeleton with the carousel, banner, pills and rows shapes shows, and it gives way to the menu; WHEN a dish's photo fails THEN its row shows the placeholder with the dish's initials.
- AC5: WHEN a search finds nothing THEN an empty state names the query and its action clears the search.
- AC6: WHEN the first load fails offline THEN the offline state shows with a retry that loads again; WHEN it fails with 429 THEN the action reads «Intenta en 0:42» and counts down; WHEN it fails on the server THEN the state shows «Ref. <id>»; WHEN a refresh fails THEN the menu stays and a toast tells why.

## Files

- modify lib/features/dishes/presentation/home/home_page.dart — menu slivers, refresh and states
- create lib/features/dishes/presentation/home/menu_filters.dart — pinned pills and sort sheet
- create lib/features/dishes/presentation/home/carta.dart — rows, staggered entrance and colophon
- create lib/features/dishes/presentation/home/home_states.dart — skeleton, empty and failure states, countdown
- modify lib/i18n/es/dishes.i18n.yaml — Spanish copy of filters, rows and states
- modify lib/i18n/en/dishes.i18n.yaml — English copy of filters, rows and states
- create test/features/dishes/presentation/home_menu_test.dart — filters, sort, rows, colophon and refresh tests
- create test/features/dishes/presentation/home_states_test.dart — skeleton, fallback, empty and failure tests

## Tasks

- [x] T1: Pinned filters, sort sheet, rows and colophon
  - files: lib/features/dishes/presentation/home/menu_filters.dart, lib/features/dishes/presentation/home/carta.dart, lib/features/dishes/presentation/home/home_page.dart, lib/i18n/es/dishes.i18n.yaml, lib/i18n/en/dishes.i18n.yaml, test/features/dishes/presentation/home_menu_test.dart
  - ac: AC1, AC2
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes test/i18n
- [ ] T2: Pull-to-refresh with the plate spinner
  - files: lib/features/dishes/presentation/home/home_page.dart, test/features/dishes/presentation/home_menu_test.dart
  - ac: AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes
- [ ] T3: Skeleton, empty and failure states
  - files: lib/features/dishes/presentation/home/home_states.dart, lib/features/dishes/presentation/home/home_page.dart, lib/i18n/es/dishes.i18n.yaml, lib/i18n/en/dishes.i18n.yaml, test/features/dishes/presentation/home_states_test.dart
  - ac: AC4, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
