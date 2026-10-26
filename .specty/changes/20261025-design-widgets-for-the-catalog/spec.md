---
kind: standard
follows:
  - 20261025-dishes-data-layer
---

# Design widgets for the catalog

## Goal

The design widgets the catalog builds on exist with their final public API and a simple but working implementation, drawn only from the design tokens: a pressable surface with a spring scale and haptic, a button that turns into a spinner while loading, skeleton blocks, a state view with an illustration and an optional cooldown, segmented pills, fractional rating stars, a top toast, a plate-shaped spinner and the plate illustration. Premium motion can arrive later without changing any signature.

## Out of scope

- `DishImage`, `DishHero`, `EcoTextField`, `GrainOverlay`, `Shake`, `MaskRevealText`, `LogoMark` and the design gallery (next change).
- Premium polish of agent C (shimmer, sliding pill indicator, blur toast).

## Assumptions

- A1: No widget uses Material ripples or elevation: presses scale, edges are 1 px hairlines and shapes are squircles.
- A2: Texts reach the widgets already translated; no widget holds copy of its own.
- A3: The state view's cooldown (the 429 «try again in 0:42») ticks every second and enables its action at zero; the label of the countdown comes from the caller.
- A4: With reduced motion, the spinner and the skeleton stop animating and the pressable does not scale.

## Acceptance criteria

- AC1: WHEN a `Pressable` with a callback is tapped THEN the callback runs once; WHEN it has no callback THEN it ignores taps and reports itself as a disabled button to accessibility.
- AC2: WHEN an `EcoButton` is loading THEN it shows a `PlateSpinner` instead of its label and ignores taps; WHEN it is not THEN a tap runs its callback.
- AC3: WHEN a `StateView` has a cooldown THEN its action is disabled and shows the caller's countdown label every second, and WHEN the cooldown ends THEN the action is enabled.
- AC4: WHEN a pill of `SegmentedPills` is tapped THEN `onChanged` receives its value, and the selected pill is marked selected for accessibility.
- AC5: WHEN `RatingStars` shows 4.5 THEN four stars are full and the fifth is half filled; `Skeleton`, `Toast`, `PlateSpinner` and `PlateIllustration` render in light and dark without errors.

## Files

- create lib/design/widgets/pressable.dart — press feedback without ripples
- create lib/design/widgets/eco_button.dart — primary, secondary and quiet buttons with loading
- create lib/design/widgets/plate_spinner.dart — plate rim spinner with optional progress
- create lib/design/painters/plate_illustration.dart — line plate illustration
- create lib/design/widgets/skeleton.dart — layout-shaped placeholder blocks
- create lib/design/widgets/state_view.dart — empty, error, offline and cooldown states
- create lib/design/widgets/segmented_pills.dart — single-choice pills
- create lib/design/widgets/rating_stars.dart — fractional stars
- create lib/design/widgets/toast.dart — top toast
- create test/design/widgets/pressable_test.dart — Pressable and EcoButton tests
- create test/design/widgets/state_view_test.dart — StateView tests
- create test/design/widgets/selection_test.dart — SegmentedPills, RatingStars and render tests

## Tasks

- [x] T1: Pressable, PlateSpinner and EcoButton
  - files: lib/design/widgets/pressable.dart, lib/design/widgets/plate_spinner.dart, lib/design/widgets/eco_button.dart, test/design/widgets/pressable_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter analyze && fvm flutter test test/design
- [ ] T2: PlateIllustration, Skeleton and StateView
  - files: lib/design/painters/plate_illustration.dart, lib/design/widgets/skeleton.dart, lib/design/widgets/state_view.dart, test/design/widgets/state_view_test.dart
  - ac: AC3, AC5
  - verify: fvm flutter analyze && fvm flutter test test/design
- [ ] T3: SegmentedPills, RatingStars and Toast
  - files: lib/design/widgets/segmented_pills.dart, lib/design/widgets/rating_stars.dart, lib/design/widgets/toast.dart, test/design/widgets/selection_test.dart
  - ac: AC4, AC5
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
