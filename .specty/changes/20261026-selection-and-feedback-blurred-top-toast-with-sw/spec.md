---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C4
---

# Selection and feedback: blurred top Toast with swipe to dismiss, SegmentedPills with a sliding indicator and fractional RatingStars, with a SegmentedPills widget test

## Goal

Choosing and being told things feels tactile. A filter or setting choice moves one ink pill that slides and stretches from the old option to the new one, and the row scrolls the choice into view. Notes drop from the top over frosted glass and can be flicked away. Ratings show exactly how much of the last star a dish earned.

## Out of scope

- The screens that use these widgets: the menu filters, the profile sheet's appearance and language, the session and refresh toasts. They keep their calls.
- The small single stars that the catalog's card and row draw from the icon set.

## Assumptions

- A1: The public API of `Toast`, `SegmentedPills` and `RatingStars` stays as it is. Tests reach the moving indicator through a `@visibleForTesting` key.
  - impact: high
- A2: `RatingStars` keeps one `Align` per star with the star's filled fraction as its `widthFactor`, as the existing test reads it. The stars become drawn shapes that span their whole box, so the box fraction is exactly the star fraction (an icon glyph has side bearings that skew it).
  - impact: high
- A3: The pill indicator is measured from the laid-out pills after each frame and moved with an implicit animation (`Motion.standard`, emphasized). Until the first measure, the selected pill paints its own fill, so no frame shows unreadable text.
- A4: A toast is dismissed by an upward flick (over 300 px/s) or a drag past 24 px; a shorter drag springs back. Dragging pauses its timer, and the full duration starts again on release.
- A5: The toast's blur is clipped to its own shape and its background stays translucent «raised» paper with a hairline. With reduced motion it appears and leaves with a fade.

## Acceptance criteria

- AC1: WHEN a value of `SegmentedPills` is picked THEN one ink indicator slides and resizes from the old pill to the new one, the labels change color, and the row scrolls the new pill into view; WHEN reduced motion is on THEN the indicator jumps; a tap still reports its value and the selected pill is still reported as selected.
- AC2: WHEN `RatingStars` shows 4.7 THEN four stars are full and the fifth is filled across 70 % of its drawn width; WHEN it shows 4.5 THEN the fifth is half filled; screen readers read the caller's label.
- AC3: WHEN a `Toast` shows THEN it drops from the top over a blurred, translucent backdrop and leaves by itself after its duration; WHEN it is flicked or dragged up far enough THEN it leaves at once; WHEN a short drag ends THEN it springs back and stays for its full duration; WHEN another toast comes THEN it replaces the current one.
- AC4: WHEN `fvm flutter test` runs THEN the SegmentedPills, RatingStars and Toast widget tests pass, along with every existing test.

## Design

- `SegmentedPills` becomes stateful. Each pill has a `GlobalKey`. A post-frame measure turns the selected pill's box into a rect within the row's `Stack`, and `setState` runs only when the rect changed. An `AnimatedPositioned` ink stadium sits behind a transparent `Row`. `Scrollable.ensureVisible` centers a newly picked pill.
- `RatingStars` draws each star with a `_StarPainter` that fits a rounded five-point star to the full width of its box: an empty star in the line color, and the filled one clipped by the existing `Align`.
- `Toast`'s banner gains a `ClipRSuperellipse` with a `BackdropFilter`, a vertical drag that translates it (with resistance downward), and a cancellable `Timer` instead of a delayed future.

## Files

- modify lib/design/widgets/segmented_pills.dart — sliding indicator and scroll into view
- modify lib/design/widgets/rating_stars.dart — drawn stars spanning their box
- modify lib/design/widgets/toast.dart — blur, swipe to dismiss, pausable timer
- modify test/design/widgets/selection_test.dart — indicator, scroll, exact fractions, toast gestures

## Tasks

- [x] T1: SegmentedPills with a sliding, resizing indicator that scrolls the choice into view, with widget tests
  - files: lib/design/widgets/segmented_pills.dart, test/design/widgets/selection_test.dart
  - ac: AC1
  - verify: fvm flutter test test/design/widgets/selection_test.dart test/features/dishes/presentation/home_menu_test.dart test/features/profile
- [x] T2: RatingStars drawn so the fill matches the star's width, with tests
  - files: lib/design/widgets/rating_stars.dart, test/design/widgets/selection_test.dart
  - ac: AC2
  - verify: fvm flutter test test/design/widgets/selection_test.dart
- [ ] T3: Toast over a blurred backdrop that can be flicked away, with widget tests
  - files: lib/design/widgets/toast.dart, test/design/widgets/selection_test.dart
  - ac: AC3, AC4
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: The menu filters mask the pill row with a `ShaderMask`, and the profile sheet lays pills inside a bottom sheet. Mitigation: the indicator lives inside the row's own scroll view, so it is masked and clipped with the pills; T1 runs the menu and profile tests.
- R2: Measuring after each frame could loop. Mitigation: `setState` runs only when the measured rect changed.
