---
kind: standard
follows:
  - 20261025-catalog-domain-and-providers
---

# Home header, featured carousel and discover banner

## Goal

The top of Home looks and behaves like the plan's editorial front page: a large header with the date in the active language, a greeting and a headline that follow the time of day, and an avatar that opens the profile; while scrolling it collapses into a blurred bar that keeps the accent-free search at hand. Under it, the featured dishes ride a 4:5 carousel with inner parallax, scaled side cards, a page indicator and spoken labels, and a «Modo descubrir» banner fans out three thumbnails and opens Discover from the point it was tapped. Searching hides both and leaves the results.

## Out of scope

- Filter pills, sort sheet, «La carta» rows, pull-to-refresh, colophon and the empty, error, offline and 429 states (next change); until then Home lists the visible dishes plainly.
- The dish detail screen (later change) and the real Discover (agent C).

## Assumptions

- A1: Day parts follow Colombian use: «Buenos días» from 5:00 to 11:59, «Buenas tardes» from 12:00 to 18:59 and «Buenas noches» from 19:00; the headline asks about breakfast, lunch (12:00 to 17:59) or tonight.
- A2: The greeting names only the first of the stored first names («Jorge Andrés» → «Jorge»); without a known name it is just «Buenas tardes.».
- A3: The header is a pinned `SliverAppBar` whose expanded height grows with the text scale, so 130 % text does not overflow; the blur and the hairline appear only once content passes under it.
- A4: Carousel photos and thumbnails are requested through `sizedImageUrl` for their laid-out width; with reduced motion the carousel neither scales nor parallaxes.
- A5: Home's widget tests run the whole app through its router with fake session and dishes, as the app test does.

## Acceptance criteria

- AC1: WHEN Home opens at 9:00 for «Jorge» in Spanish THEN the header reads the date as «SÁBADO 24 DE OCTUBRE», «Buenos días, Jorge.» and the breakfast headline; at 20:00 it greets the night; in English the same parts read in English.
- AC2: WHEN the avatar is tapped THEN the profile sheet opens.
- AC3: WHEN the user types «camaron» in the search THEN the carousel and the banner leave and only the matching dishes are listed; clearing the search brings them back.
- AC4: WHEN Home shows the featured dishes THEN the carousel has one card per featured dish, each read as «Destacado N de M» with its name, price and rating, and the indicator marks the current page; WHEN a card is tapped THEN that dish's detail opens.
- AC5: WHEN the discover banner is tapped THEN Discover opens, revealed from the tapped point.

## Files

- modify lib/features/dishes/presentation/home/home_page.dart — scroll view with header, carousel, banner and results
- create lib/features/dishes/presentation/home/home_greeting.dart — day parts and greeting
- create lib/features/dishes/presentation/home/home_header.dart — collapsing header, avatar and search
- create lib/features/dishes/presentation/home/featured_carousel.dart — featured carousel and indicator
- create lib/features/dishes/presentation/home/discover_banner.dart — discover banner with fanned thumbnails
- modify lib/i18n/es/dishes.i18n.yaml — Spanish copy of the header, carousel and banner
- modify lib/i18n/en/dishes.i18n.yaml — English copy of the header, carousel and banner
- create test/helpers/app_harness.dart — boots the app with fake session and dishes
- create test/features/dishes/presentation/home_header_test.dart — greeting, date, avatar and search tests
- create test/features/dishes/presentation/home_carousel_test.dart — carousel and banner tests

## Tasks

- [ ] T1: Greeting and collapsing header with search
  - files: lib/features/dishes/presentation/home/home_greeting.dart, lib/features/dishes/presentation/home/home_header.dart, lib/features/dishes/presentation/home/home_page.dart, lib/i18n/es/dishes.i18n.yaml, lib/i18n/en/dishes.i18n.yaml
  - ac: AC1, AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes test/i18n
- [ ] T2: Header tests over the running app
  - files: test/helpers/app_harness.dart, test/features/dishes/presentation/home_header_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/dishes
  - type: test
- [ ] T3: Featured carousel and discover banner
  - files: lib/features/dishes/presentation/home/featured_carousel.dart, lib/features/dishes/presentation/home/discover_banner.dart, lib/features/dishes/presentation/home/home_page.dart, test/features/dishes/presentation/home_carousel_test.dart
  - ac: AC4, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
