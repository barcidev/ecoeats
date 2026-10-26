---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C1
---

# Press, button and spinner motion: spring Pressable with haptic, EcoButton that morphs into the loader and expands on success, PlateSpinner and spring Shake, with widget tests for Pressable and every EcoButton state

## Goal

The app's tap targets, main button, loader and refusal shake move like physical objects instead of tweens. A press sinks and springs back. The button folds into a spinning plate while it waits and opens again with a drawn check when it succeeds. The spinner's rim chases itself, and a refused form shakes with damped swings. Every screen gets this without changing a call.

## Out of scope

- The full-screen achiote sweep after login. Agent A already owns it (`AchioteSweep` in `features/auth`), so the button's success stays inside its own bounds and the sweep is not duplicated.
- Calls in auth, catalog and profile: they keep working unchanged and can opt in to `success` later.
- The other design widgets (slices C2 to C5).

## Assumptions

- A1: The public API of `Pressable`, `EcoButton`, `PlateSpinner` and `Shake` stays as it is. `EcoButton` only gains two optional parameters: `success` (false by default) and `onSuccess`.
  - impact: high
- A2: «Expands on success» means the circle opens back to the button's full width with a check that draws itself, and `onSuccess` runs when the check is complete. Agent A's sweep can start from that callback or keep starting from its own state, as it does now.
  - impact: high
- A3: The press and release springs use `Motion.spring` (380/30), which overshoots a little on release. The shake uses a softer, less damped spring of its own, so it swings about three times before it rests, and it always ends exactly at rest.
- A4: A loading or successful button ignores taps, keeps its label as its semantic label, and keeps its full slot in the layout: only the painted shape narrows, centered in it, so nothing around it moves.
- A5: With reduced motion, Pressable does not scale, the button swaps label, spinner and check with a crossfade and no width change, the shake plays only its haptic, and `onSuccess` still runs.
- A6: Haptics: a selection click when a Pressable fires, a light impact when the button succeeds, and a medium impact for each shake.

## Acceptance criteria

- AC1: WHEN a `Pressable` is held THEN its child scales below 1; WHEN it is released THEN it springs back to exactly 1, its callback runs once and a selection-click haptic plays; WHEN it has no callback THEN taps do nothing and it reports itself as a disabled button; WHEN reduced motion is on THEN it never scales.
- AC2: WHEN an `EcoButton` starts loading THEN its painted shape narrows to a circle as tall as the button, the plate spinner replaces the label, and taps are ignored; WHEN loading ends without success THEN it widens back to its label and accepts taps again.
- AC3: WHEN an `EcoButton` gets `success` THEN the circle widens back to the full button, a check draws itself, a light haptic plays, taps are ignored, and `onSuccess` runs once at the end, with reduced motion too; WHEN an `EcoButton` has no callback and is not loading THEN it is drawn at 40 % opacity and reported as disabled.
- AC4: WHEN `PlateSpinner` spins THEN its arc grows and shrinks as it turns, with no jump when a turn starts again; WHEN it has `progress` THEN it draws that still fraction of the rim.
- AC5: WHEN the `Shake` trigger changes to a new value THEN the child swings sideways several times with decreasing strength, a medium haptic plays, and the child ends exactly at rest.
- AC6: WHEN `fvm flutter test` runs THEN the Pressable and EcoButton widget tests (idle, disabled, loading, back from loading, success and reduced motion) and the spinner and shake tests pass, along with every existing test.

## Design

- `Pressable`: an unbounded `AnimationController` holds the scale. `animateWith(SpringSimulation(Motion.spring, …))` drives it toward the pressed scale on tap down and back to 1 on release, keeping the current velocity, so a quick tap still dips.
- `EcoButton`: a private state class. The slot keeps the button's laid-out width. Inside it, a centered `AnimatedSize` and a radius tween morph the painted shape between the full pill and the circle. An `AnimatedSwitcher` swaps label, spinner and check. The check is a small `CustomPainter` with a progress value.
- `PlateSpinner`: `plateSpinnerArc(t)` returns the start and sweep of the arc for one cycle. The head and the tail run on eased halves, and the base rotation of 1.25 turns per cycle makes the end of a cycle meet the start of the next. It is exposed `@visibleForTesting` so continuity can be tested.
- `Shake`: an unbounded controller runs a `SpringSimulation` from 0 to 0 with an initial velocity, and is set to exactly 0 when the simulation ends.

## Files

- modify lib/design/widgets/pressable.dart — spring press and release
- modify lib/design/widgets/eco_button.dart — morph into the loader, success expansion with a drawn check, optional `success` and `onSuccess`
- modify lib/design/widgets/plate_spinner.dart — chasing arc, continuous between turns
- modify lib/design/widgets/shake.dart — damped spring swings that end at rest
- modify test/design/widgets/pressable_test.dart — Pressable spring, haptic and reduced motion; every EcoButton state
- modify test/design/widgets/form_motion_test.dart — shake haptic and several swings
- create test/design/widgets/plate_spinner_test.dart — arc continuity and progress

## Tasks

- [x] T1: Spring Pressable with haptic, with its widget tests
  - files: lib/design/widgets/pressable.dart, test/design/widgets/pressable_test.dart
  - ac: AC1
  - verify: fvm flutter test test/design/widgets/pressable_test.dart
- [x] T2: Chasing PlateSpinner and spring Shake, with their tests
  - files: lib/design/widgets/plate_spinner.dart, lib/design/widgets/shake.dart, test/design/widgets/plate_spinner_test.dart, test/design/widgets/form_motion_test.dart
  - ac: AC4, AC5
  - verify: fvm flutter test test/design/widgets/plate_spinner_test.dart test/design/widgets/form_motion_test.dart
- [x] T3: EcoButton that morphs into the loader and expands on success, with a widget test for every state
  - files: lib/design/widgets/eco_button.dart, test/design/widgets/pressable_test.dart
  - ac: AC2, AC3, AC6
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: Auth tests may expect the button's old layout or opacity while loading. Mitigation: the slot keeps its width and the label stays as the semantic label; T3 runs the whole suite.
- R2: Spring simulations may take long to settle in `pumpAndSettle`. Mitigation: the springs use the default tolerance, and the shake snaps to 0 when it ends.

## Closing

### Summary

Pressable, EcoButton, PlateSpinner and Shake now move physically behind the same API. A press sinks and springs back. The button folds into a spinning plate while loading and opens again with a drawn check on success. The spinner's arc chases itself, and the shake swings on a damped spring. Every existing screen and test keeps working: the full suite passes with 317 tests.

### Deviations

- `EcoButton` no longer uses a `LayoutBuilder` to read its width. The catalog lays its state views out through `SliverFillRemaining`, which asks for intrinsic sizes, and a `LayoutBuilder` cannot answer them. The full width comes from a `double.infinity` box, as the phase 0 button did.
- The old shake already swung several times with a haptic, so the new shake tests guard behavior that existed before. The change is in how it moves: a spring instead of a sine.

### Decisions

- `EcoButton` exposes `shapeKey` and `checkKey` (`@visibleForTesting`), so tests can measure the painted shape and find the check without depending on private widgets.
- While the circle narrows, the fading label is clipped at its edge instead of wrapping (`UnconstrainedBox` with `Clip.hardEdge`).
- Pressable reads reduced motion during build. A tap cancel can arrive while the tree is torn down, when the context can no longer be asked.
- Every spring rests exactly on its target when its simulation ends, because the simulations stop within their tolerance.

### Follow-ups

- Agent A can pass `success: state.succeeded` to the login button and start `AchioteSweep` from `onSuccess`, so the sweep grows out of the drawn check. Today the button only rests at 40 % opacity during the sweep.
- `.specty/config.yaml` has no `verify.full`; adding `fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test` would make every acceptance run the whole suite.
