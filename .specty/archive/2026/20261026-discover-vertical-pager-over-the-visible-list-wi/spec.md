---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C6
---

# Discover: vertical pager over the visible list with Ken Burns, text depth, rail, counter, haptic and precache, the first-time hint, «Ver plato ↑» with the discover hero and the softened reveal, with a reduced-motion widget test

## Goal

Discover becomes the app's immersive walk through the menu. It opens as a circle growing from the touched point, then shows one dish per screen, full-bleed. The photo slowly zooms, the words glide faster than the photo under the finger, a rail and a «04 / 12» counter keep the place, and a light tick marks each landing. The first time, a quiet hint says to swipe up. «Ver plato ↑» flies the photo and the name into the dish's detail.

## Out of scope

- The banner that opens Discover and the detail it leads to (agent B). The detail already takes `heroSource: .discover` and, since C5, flies the name.
- Filters inside Discover: it walks whatever Home's filter, search and order leave visible.

## Assumptions

- A1: Discover walks a snapshot of `visibleDishesProvider` taken when it first has data, so a background refresh never reorders the pages under the finger. If the list is still loading it shows the plate spinner; if it is empty it shows the empty state with its own copy.
  - impact: high
- A2: The phase 0 test file `test/features/discover/discover_route_test.dart` rendered the placeholder page without a `ProviderScope`. The real page reads the catalog, so those tests get a `ProviderScope` with a fake catalog around the same widgets; their assertions (reveal fraction, origin, rendering in light and dark) do not change. The epic's A3 foresaw this.
  - impact: high
- A3: The first-time hint is stored the way the profile stores its choices (`SharedPreferences`, key `discover.hintSeen`). It hides for good after the first page change or a tap on it. Tests use `SharedPreferences.setMockInitialValues`.
- A4: Precaching is the pager's own implicit scrolling: the next page is built offstage, so its photo starts loading before it shows.
- A5: The Ken Burns runs on the active page only: a slow zoom from 1 to 1.12 with a slight drift, reversing every 9 s. A page that stops being active freezes where it is. On drag, the photo moves at 0.65 of the page and the text at 1.25, so the words lead.
- A6: With reduced motion, Discover opens with a fade (the route already does this). There is no Ken Burns and no depth, and the hint's arrow stands still. Paging, the counter, the rail, the haptic and «Ver plato ↑» stay.
- A7: The reveal keeps its circular clip (the existing route test reads it). It is softened by a dark ring that hugs the growing edge and fades as the circle completes, and by the page settling from a 1.04 scale.

## Acceptance criteria

- AC1: WHEN Discover opens THEN it shows the first visible dish full screen, with its photo, name, price, rating, a short description and «Ver plato ↑», a counter «01 / N» where N is the number of visible dishes, a progress rail, and a close button; WHEN Home's filter leaves four dishes THEN the counter says «/ 04».
- AC2: WHEN the user swipes up THEN the next dish settles into place, the counter and the rail follow, and a light haptic plays once per settled page; WHEN a page is active THEN its photo zooms slowly; WHILE dragging THEN the text moves farther than the photo; the next page's photo is already built offstage.
- AC3: WHEN Discover opens for the first time THEN a swipe-up hint shows; WHEN the user changes page or taps the hint THEN it hides and never shows again, also after reopening.
- AC4: WHEN «Ver plato ↑» is tapped THEN the dish's detail opens with the photo and the name flying from Discover (hero source `discover`).
- AC5: WHEN the visible list is empty THEN Discover shows its empty state with a way back; WHEN it is loading THEN the plate spinner shows.
- AC6: WHEN reduced motion is on THEN the photo does not zoom, the text does not lead, and Discover still pages, counts, ticks and opens the detail.
- AC7: WHEN Discover opens from a touch THEN the circle grows from it with a soft dark edge and the page settles from a slight scale; WHEN `fvm flutter test` runs THEN the Discover tests (reduced motion included), the route tests and every existing test pass.

## Design

- `application/discover_hint.dart`: `DiscoverHint` (`AsyncNotifier<bool>`, true while the hint should show) with `dismiss()`.
- `presentation/discover_page.dart`: `DiscoverPage` (`ConsumerStatefulWidget`, same constructor) holds the snapshot and the `PageController`. It builds the loading, empty and pager states. A `NotificationListener<ScrollEndNotification>` fires the haptic and dismisses the hint when the settled page changes.
- `presentation/discover_slide.dart`: one dish. It holds its Ken Burns controller (running only while `active`), the depth from `controller.page - index`, the scrims, and the text block with `DishNameHero` and `DishHero` under the `discover` source.
- `presentation/discover_chrome.dart`: the counter (tabular figures, zero-padded, a live region), the rail, the close button and the hint with its bobbing arrow.
- `discover_route.dart`: the same `revealRoute` and clipper, plus an edge ring painted inside the clip and a 1.04 → 1 scale.
- Copy in the `discover` namespace, Spanish and English: featured overline, empty state, the page's semantic summary and the hint's dismiss label.

## Files

- create lib/features/discover/application/discover_hint.dart — persisted first-time hint
- modify lib/features/discover/presentation/discover_page.dart — snapshot, states and pager
- create lib/features/discover/presentation/discover_slide.dart — one dish: Ken Burns, depth, text, heroes
- create lib/features/discover/presentation/discover_chrome.dart — counter, rail, close and hint
- modify lib/features/discover/presentation/discover_route.dart — softened reveal
- modify lib/i18n/es/discover.i18n.yaml — Spanish copy
- modify lib/i18n/en/discover.i18n.yaml — English copy
- create test/features/discover/discover_hint_test.dart — hint persistence
- create test/features/discover/discover_page_test.dart — paging, counter, filter, hint, detail, empty, reduced motion
- modify test/features/discover/discover_route_test.dart — a ProviderScope around the same widgets; soft edge

## Tasks

- [x] T1: Discover copy in Spanish and English, and the persisted first-time hint, with tests
  - files: lib/i18n/es/discover.i18n.yaml, lib/i18n/en/discover.i18n.yaml, lib/features/discover/application/discover_hint.dart, test/features/discover/discover_hint_test.dart
  - ac: AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter test test/features/discover/discover_hint_test.dart test/i18n
- [x] T2: The dish slide: full-bleed photo with Ken Burns, leading text, scrims and the discover heroes
  - files: lib/features/discover/presentation/discover_slide.dart
  - ac: AC2, AC4, AC6
  - verify: fvm flutter analyze lib/features/discover
- [x] T3: The pager with its counter, rail, haptic, precache, hint, close, empty and loading states, with widget tests (reduced motion included)
  - files: lib/features/discover/presentation/discover_page.dart, lib/features/discover/presentation/discover_chrome.dart, test/features/discover/discover_page_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: fvm flutter test test/features/discover/discover_page_test.dart
- [x] T4: The softened reveal, and the route tests around a ProviderScope
  - files: lib/features/discover/presentation/discover_route.dart, test/features/discover/discover_route_test.dart
  - ac: AC7
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: Full-screen photos and a zoom on every frame can drop frames on older phones. Mitigation: the Ken Burns runs only on the active page through a `Transform`, the photo decodes at screen width, and Discover is profiled on device with the gallery QA (C10).
- R2: Heroes in an offstage page could collide with the visible one. Mitigation: each page's tags carry its dish id, and Flutter skips heroes in offstage subtrees.
- R3: Pushing the detail over Discover, whose route is not a page route, could show Discover through the detail's transparent route. Mitigation: that is the intended swipe-down-to-close effect; the detail paints its own paper.

## Closing

### Summary

Discover is the app's immersive walk. It opens as a circle growing from the touch, with a shaded edge and a page that settles from 1.04. Then it pages vertically through a snapshot of Home's visible dishes, one full-bleed dish at a time, with a slow push-in on the active photo, words that lead the drag, a counter «01 / 12», a progress rail and a light tick per settled page. The next photo is already built offstage. A first-time hint nods upward until the first swipe or tap, and stays gone. «Ver plato» flies the photo and the name into the detail, and loading, error and empty states sit in the same dark room. The full suite passes with 401 tests.

### Deviations

- The Ken Burns is one 9 s push-in that then holds, instead of reversing forever, and the hint's arrow nods three times. An existing catalog test (`the banner opens Discover`) settles after opening Discover, and an endless animation never does. A screen that comes to rest also saves battery. The scope request added the slide and the chrome files to T4.
- The text leads at 1.3 and the photo trails at 0.92 of the page, not 1.25 and 0.65. Keeping the photo's lag inside the slack of a 1.1 resting zoom means the `DishHero` keeps the page's exact rect and no edge ever shows.
- The phase 0 route tests now run inside a `ProviderScope` and a `TranslationProvider` with an empty catalog, so the page rests on its empty state and the route can settle. Their assertions did not change. A new test covers the shaded edge.

### Decisions

- Discover is always dark (`ecoTheme(.dark)`, light status bar), whatever the app's theme, because its words sit on photos.
- The counter rounds the live page, so it changes halfway through a swipe. The haptic and the hint dismissal wait for the scroll to end.
- «Ver plato ↑» is read as «Ver plato»: the arrow is drawn as an icon, so screen readers do not say «flecha».

### Follow-ups

- Visual QA of Discover with real fonts, and on device, comes with the design gallery slice (C10).
