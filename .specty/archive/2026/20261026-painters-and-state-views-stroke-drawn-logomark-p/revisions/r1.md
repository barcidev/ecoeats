---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C3
---

# Painters and state views: stroke-drawn LogoMark, PlateIllustration with state details, and StateView with its drawings and 429 countdown

## Goal

The brand mark and the app's drawings become finished line art. The logo draws itself as one stroke: the plate's rim, then its well, then a veined leaf. Each unhappy state gets its own drawing on the same plate: crumbs for nothing found, smoke for a kitchen failure, a cut cord for no connection, and an hourglass that empties while a 429 counts down. State views arrive with a quiet rise instead of popping in.

## Out of scope

- The screens that show the states (catalog and auth), which keep their calls and copy.
- Exporting the mark to PNG, icons and splash (C7 to C9).

## Assumptions

- A1: `LogoMark`, `PlateIllustration` and `StateView` keep their public API. `PlateIllustration` gains two optional parameters: `detail` (the leaf by default, as today) and `progress` (only the hourglass reads it, as the sand left on top).
  - impact: high
- A2: The detail enum lives with the painter (`PlateDetail`), so painters never import widgets. `StateView` maps each `StateKind` to its detail: empty → crumbs, error → smoke, offline → cut cord, rateLimited → hourglass.
- A3: The mark's `progress` keeps its meaning from 0 to 1 (agent A animates it on the welcome): the rim takes 0–0.6, the well 0.35–0.75, and the leaf grows 0.66–1. At 0 nothing is drawn; at 1 the full mark is.
- A4: The leaf's vein is cut out of the leaf (not painted over it), so the mark works on any background: photo, paper or the transparent PNG of C7.
- A5: A state view rises 12 px and fades in over 480 ms, its texts 40 ms after the drawing. With reduced motion it appears at once. The 429 cooldown keeps its one-second tick, and the hourglass reads the fraction left.

## Acceptance criteria

- AC1: WHEN `LogoMark` has progress 0 THEN it draws nothing; WHEN progress grows THEN the rim draws from the top as one stroke, the well follows, and the leaf grows last; WHEN progress is 1 THEN rim, well and veined leaf are complete, and the vein shows what is behind the mark.
- AC2: WHEN `PlateIllustration` is given a detail THEN it draws the same plate, fork and knife with that detail in its accent color: a leaf, crumbs, smoke, a cut cord or an hourglass whose top sand follows `progress`.
- AC3: WHEN `StateView` shows THEN its drawing has the detail of its kind, and the view rises and fades in (at once with reduced motion); WHEN it has a 429 cooldown THEN the action shows the caller's countdown label every second, the hourglass empties as the time runs, and at zero the action is enabled.
- AC4: WHEN `fvm flutter test` runs THEN tests for the mark's stages, every detail and the state view's drawings and countdown pass, along with every existing test.

## Design

- `LogoMark`: rim and well are circle paths drawn through `PathMetric.extractPath` up to their share of `progress`. The leaf is a two-curve path scaled from its stem, painted inside a `saveLayer` where the vein is drawn with `BlendMode.clear`.
- `PlateIllustration`: the plate, fork and knife stay as they are. A `switch` on `PlateDetail` draws the extra strokes in the accent color. The hourglass is two triangles whose top sand is clipped to `progress` and whose bottom sand to its complement.
- `StateView`: a single entrance controller (`Motion.slow`) drives two intervals: the drawing, then the texts and action. While a cooldown runs, the hourglass gets `remaining / cooldown`.

## Files

- modify lib/design/painters/logo_mark.dart — stroke-drawn rim and well, veined leaf
- modify lib/design/painters/plate_illustration.dart — `PlateDetail` and the four state details
- modify lib/design/widgets/state_view.dart — detail per kind, entrance, hourglass during the cooldown
- create test/design/painters_test.dart — mark stages and every detail
- modify test/design/widgets/state_view_test.dart — drawing per kind, entrance and hourglass

## Tasks

- [ ] T1: Stroke-drawn LogoMark with its well and a veined leaf, with tests for its stages
  - files: lib/design/painters/logo_mark.dart, test/design/painters_test.dart
  - ac: AC1
  - verify: fvm flutter test test/design/painters_test.dart test/features/auth/presentation/auth_shell_test.dart
- [ ] T2: PlateIllustration details for each state, with tests
  - files: lib/design/painters/plate_illustration.dart, test/design/painters_test.dart
  - ac: AC2
  - verify: fvm flutter test test/design/painters_test.dart
- [ ] T3: StateView with its drawing per kind, its entrance and the emptying hourglass, with widget tests
  - files: lib/design/widgets/state_view.dart, test/design/widgets/state_view_test.dart
  - ac: AC3, AC4
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: The welcome test reads the mark's progress while it animates. Mitigation: `progress` keeps its 0–1 meaning, and T1 runs the auth shell tests.
- R2: `saveLayer` for the vein costs a little on every frame of the welcome animation. Mitigation: the layer is bounded to the leaf's rect, and only the leaf uses it.
