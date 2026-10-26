---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C5
---

# Dish photos in flight: DishImage editorial placeholder with the 280 ms fade, DishHero shuttle bending the radius and DishNameHero blending the text style, wired into the catalog names, with a DishImage fallback test

## Goal

Opening a dish feels like one continuous object moving, not two screens swapping. The photo flies from its card or row to the top of the detail. On the way its rounded corners straighten, and it melts from the small picture into the large one. The dish's name flies with it, growing from the card's type into the detail's headline. A photo that is missing or still loading shows a designed plate card that is always the same for the same dish, and the real photo fades in over it.

## Out of scope

- How the catalog lays out its cards, rows and detail. Only the name wrappers and the hero source passed to the detail body change (scope of the epic's A3).
- Discover's own hero, which uses these widgets in C6.

## Assumptions

- A1: `DishImage` and `DishHero` keep their public API. `DishNameHero` is new, in the same file as `DishHero`.
  - impact: high
- A2: The flight treats the hero on the upper route (the detail) as `t = 1` and the one below as `t = 0`, whether the route is pushed or popped. The shuttle stacks the lower child under the upper one and fades the upper one in, so the flight starts and ends exactly on what each screen shows. The corner radius is the lerp of the two heroes' radii.
  - impact: high
- A3: The name shuttle draws both names. Each keeps its own font family and has its size, weight, spacing, height and color lerped toward the other's. The two crossfade in the middle 60 % of the flight, so the switch from Instrument Sans to Fraunces never pops.
- A4: The name hero's tag is the photo's tag plus `-name` (`dishNameHeroTag` in the catalog's `dish_transitions.dart`). `DishDetailBody` gets the hero source it already knows in the page, so the detail's name lands on the right card.
- A5: The placeholder keeps its colors fixed by a stable hash of the name. It adds a soft light in the upper left over the two-color gradient, and keeps the plate drawing and the initials in Fraunces italic. With reduced motion, the shuttles skip the bend and the blend and just crossfade.

## Acceptance criteria

- AC1: WHEN a `DishImage` has no URL, is loading or fails THEN the editorial placeholder shows: the same gradient colors for the same dish name every time, a light in the upper left, the plate drawing and the initials in Fraunces italic; WHEN the photo arrives THEN it fades in over 280 ms.
- AC2: WHEN a route with a matching `DishHero` is pushed or popped THEN the photo flies between them, and mid-flight its corner radius lies between the two heroes' radii while the upper photo fades in over the lower; WHEN a matching `DishNameHero` flies THEN both names show mid-flight with a size between their two sizes, and the flight lands on the destination's exact style.
- AC3: WHEN a dish is opened from the featured carousel or from the menu row THEN its name flies with its photo into the detail's headline, and back when the detail closes.
- AC4: WHEN `fvm flutter test` runs THEN the DishImage fallback tests, the hero flight tests and every existing test (catalog included) pass.

## Design

- `dish_hero.dart`: `DishHero` wraps its child in a private `_Bend(radius)` marker inside the `Hero`. Its `flightShuttleBuilder` reads both markers, picks lower and upper by flight direction, and builds an `AnimatedBuilder` with a `ClipRSuperellipse` of the lerped radius around `Stack([lower, Opacity(t, upper)])`. `DishNameHero(tag, name, style, maxLines)` does the same with a private `_Name` marker. Its shuttle uses a `DefaultTextStyle` reset, so overlay text never takes the app's error style.
- `dish_image.dart`: `DishPlaceholder` layers a `RadialGradient` light over the existing `LinearGradient`. The rest of the widget is unchanged: the cache key, the decode width, and the 280 ms `fadeInDuration`.
- Catalog: the carousel card and the menu row wrap their name `Text` in `DishNameHero`, with the same style and lines. The detail body wraps its headline, and the page passes its `heroSource` down.

## Files

- modify lib/design/widgets/dish_image.dart — placeholder light, unchanged API
- modify lib/design/widgets/dish_hero.dart — radius-bending, crossfading photo shuttle; new DishNameHero
- modify test/design/widgets/dish_image_test.dart — stable colors, fade duration, fallback
- create test/design/widgets/dish_hero_test.dart — photo and name flights, push and pop
- modify lib/features/dishes/presentation/dish_transitions.dart — `dishNameHeroTag`
- modify lib/features/dishes/presentation/home/featured_carousel.dart — card name in a DishNameHero
- modify lib/features/dishes/presentation/home/carta.dart — row name in a DishNameHero
- modify lib/features/dishes/presentation/detail/dish_detail_body.dart — headline in a DishNameHero, hero source parameter
- modify lib/features/dishes/presentation/detail/dish_detail_page.dart — passes the hero source to the body

## Tasks

- [ ] T1: DishImage editorial placeholder with its light, stable colors and the 280 ms fade, with fallback tests
  - files: lib/design/widgets/dish_image.dart, test/design/widgets/dish_image_test.dart
  - ac: AC1
  - verify: fvm flutter test test/design/widgets/dish_image_test.dart
- [ ] T2: DishHero shuttle that bends the radius and crossfades, and DishNameHero that blends the text style, with flight tests
  - files: lib/design/widgets/dish_hero.dart, test/design/widgets/dish_hero_test.dart
  - ac: AC2
  - verify: fvm flutter test test/design/widgets/dish_hero_test.dart test/design/widgets/dish_image_test.dart
- [ ] T3: Catalog names fly into the detail headline
  - files: lib/features/dishes/presentation/dish_transitions.dart, lib/features/dishes/presentation/home/featured_carousel.dart, lib/features/dishes/presentation/home/carta.dart, lib/features/dishes/presentation/detail/dish_detail_body.dart, lib/features/dishes/presentation/detail/dish_detail_page.dart
  - ac: AC3, AC4
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: The detail's photo may still be loading when the flight lands, so the placeholder shows briefly before the photo fades in. Mitigation: the detail starts loading at push time, and the crossfade starts from the already loaded small photo; on a slow network the placeholder is the designed one, never grey.
- R2: Names that wrap differently on the card and in the detail can shift at landing. Mitigation: the shuttle lays both names out in the flying box, and the crossfade hides the change of line breaks; checked on the longest seed name.
- R3: The catalog tests find dish names by text. Mitigation: the names stay `Text` widgets with the same content, and T3 runs the whole suite.
