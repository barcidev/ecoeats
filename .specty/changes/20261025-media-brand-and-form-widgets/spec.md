---
kind: standard
follows:
  - 20261025-design-widgets-for-the-catalog
---

# Media, brand and form widgets

## Goal

The rest of the design contracts exist with a simple but working implementation: a dish photo that never shows grey (a palette gradient with the plate drawing and the dish's initials stands in while it loads or when it fails), a hero for dish photos, the text field of the auth forms, a paper-grain overlay, a shake with haptic, a line-by-line masked text reveal, the logo mark, and a debug-only design gallery. Discover exists as a placeholder page with its circular reveal route, so the router can register both.

## Out of scope

- Premium versions of these widgets (agent C): flight shuttle with radius and text interpolation, shader grain, the real Discover pager.
- The router (routes change).

## Assumptions

- A1: Image cache keys drop the `X-Amz-*` query parameters, because presigned URLs change on every listing while the photo does not; the decoded width follows the laid-out width times the device pixel ratio.
- A2: The placeholder gradient is picked from the palette by a stable hash of the dish name, so a dish keeps its colors across launches and screens.
- A3: The reveal route reads its origin from an argument; without one it opens from the center of the screen. With reduced motion it is a plain fade.
- A4: The design gallery is a `@RoutePage` the router registers only in debug builds.

## Acceptance criteria

- AC1: WHEN `DishImage` has no URL or its image fails THEN it shows the placeholder with the plate drawing and the dish initials («Bandeja Paisa» → «BP»), never an empty box; WHEN two URLs differ only in `X-Amz-*` parameters THEN they share one cache key.
- AC2: WHEN `DishHero` wraps a photo THEN a `Hero` with the given tag holds it.
- AC3: WHEN `EcoTextField` has an error THEN the error text shows under the field; WHEN it is obscured THEN the typed text is hidden.
- AC4: WHEN the `trigger` of `Shake` changes THEN its child moves sideways and comes back to rest; WHEN `MaskRevealText` builds THEN every line ends fully visible.
- AC5: WHEN the reveal route is pushed with an origin THEN the page appears clipped by a circle that grows from that point until it covers the screen; `GrainOverlay`, `LogoMark`, the gallery and the Discover placeholder render in light and dark without errors.

## Files

- create lib/design/widgets/dish_image.dart — dish photo with editorial placeholder and stable cache key
- create lib/design/widgets/dish_hero.dart — hero for dish photos
- create lib/design/widgets/eco_text_field.dart — underlined form field with label and error
- create lib/design/widgets/grain_overlay.dart — paper grain overlay
- create lib/design/widgets/shake.dart — sideways shake with haptic
- create lib/design/widgets/mask_reveal_text.dart — line-by-line masked reveal
- create lib/design/painters/logo_mark.dart — logo mark with drawing progress
- create lib/design/gallery/design_gallery_page.dart — debug design gallery page
- create lib/features/discover/presentation/discover_page.dart — Discover placeholder page
- create lib/features/discover/presentation/discover_route.dart — circular reveal route
- create test/design/widgets/dish_image_test.dart — DishImage and DishHero tests
- create test/design/widgets/form_motion_test.dart — EcoTextField, Shake and MaskRevealText tests
- create test/features/discover/discover_route_test.dart — reveal route and render tests

## Tasks

- [x] T1: DishImage and DishHero
  - files: lib/design/widgets/dish_image.dart, lib/design/widgets/dish_hero.dart, test/design/widgets/dish_image_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter analyze && fvm flutter test test/design
- [ ] T2: EcoTextField, Shake and MaskRevealText
  - files: lib/design/widgets/eco_text_field.dart, lib/design/widgets/shake.dart, lib/design/widgets/mask_reveal_text.dart, test/design/widgets/form_motion_test.dart
  - ac: AC3, AC4
  - verify: fvm flutter analyze && fvm flutter test test/design
- [ ] T3: GrainOverlay, LogoMark, gallery and Discover placeholder with its reveal route
  - files: lib/design/widgets/grain_overlay.dart, lib/design/painters/logo_mark.dart, lib/design/gallery/design_gallery_page.dart, lib/features/discover/presentation/discover_page.dart, lib/features/discover/presentation/discover_route.dart, test/features/discover/discover_route_test.dart
  - ac: AC5
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
