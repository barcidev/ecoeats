---
kind: standard
follows:
  - 20261025-media-brand-and-form-widgets
allowedDependencies:
  - yaml
---

# Translations setup

## Goal

The app speaks Spanish (base) and English through slang, one namespace per owner: `common` and `errors` are complete in both languages, and `auth`, `dishes`, `discover` and `profile` start with their base keys for their owners to extend. Every `AppFailure` has its own translated words, so the server's Spanish messages never reach the screen as they are; they only fill in, in Spanish, what the app has no words for.

## Out of scope

- Wiring `TranslationProvider`, the locale and the Material localizations into the app (routes change).
- The full copy of auth and profile (agent A) and of the catalog screens (agent B changes).
- The language selector (agent A).

## Assumptions

- A1: Translations live in `lib/i18n/<locale>/<namespace>.i18n.yaml`, generated with `dart run slang` into `lib/i18n/gen/strings.g.dart`, which git ignores.
- A2: English is written in its own voice, not word for word: «Comida colombiana, sin afán.» becomes «Colombian food, unhurried.».
- A3: The server message is shown only when the language is Spanish and the failure has no more specific words (a 409 or a 400 the app does not recognize).
- A4: `yaml` joins the dev dependencies so a test can check that both languages define the same keys.

## Acceptance criteria

- AC1: WHEN the Spanish and English files are compared THEN every namespace defines the same keys in both languages.
- AC2: WHEN 12 dishes are counted THEN Spanish reads «12 platos» and English «12 dishes», and one dish reads «1 plato» and «1 dish».
- AC3: WHEN a failure is turned into words THEN offline, timeout, rate limit, server (with «Ref.» and the request id), not found, unauthorized, validation and each known conflict have their own text in the active language.
- AC4: WHEN an unknown conflict or a field-less validation carries a server message THEN Spanish shows that message and English shows its generic text.

## Files

- modify pubspec.yaml — yaml as a dev dependency
- create lib/i18n/es/common.i18n.yaml — shared Spanish copy
- create lib/i18n/en/common.i18n.yaml — shared English copy
- create lib/i18n/es/errors.i18n.yaml — Spanish failure copy
- create lib/i18n/en/errors.i18n.yaml — English failure copy
- create lib/i18n/es/auth.i18n.yaml — Spanish auth base keys
- create lib/i18n/en/auth.i18n.yaml — English auth base keys
- create lib/i18n/es/dishes.i18n.yaml — Spanish catalog base keys
- create lib/i18n/en/dishes.i18n.yaml — English catalog base keys
- create lib/i18n/es/discover.i18n.yaml — Spanish Discover base keys
- create lib/i18n/en/discover.i18n.yaml — English Discover base keys
- create lib/i18n/es/profile.i18n.yaml — Spanish profile base keys
- create lib/i18n/en/profile.i18n.yaml — English profile base keys
- create lib/i18n/failure_text.dart — AppFailure to translated words
- create test/i18n/translations_test.dart — parity, plural and failure text tests

## Tasks

- [x] T1: Shared copy and key parity
  - files: pubspec.yaml, lib/i18n/es/common.i18n.yaml, lib/i18n/en/common.i18n.yaml, test/i18n/translations_test.dart
  - ac: AC1
  - verify: fvm dart run slang && fvm flutter analyze && fvm flutter test test/i18n
  - type: chore
- [x] T2: Feature namespaces with their base keys
  - files: lib/i18n/es/auth.i18n.yaml, lib/i18n/en/auth.i18n.yaml, lib/i18n/es/dishes.i18n.yaml, lib/i18n/en/dishes.i18n.yaml, lib/i18n/es/discover.i18n.yaml, lib/i18n/en/discover.i18n.yaml, lib/i18n/es/profile.i18n.yaml, lib/i18n/en/profile.i18n.yaml, test/i18n/translations_test.dart
  - ac: AC1, AC2
  - verify: fvm dart run slang && fvm flutter analyze && fvm flutter test test/i18n
- [ ] T3: Failure copy and its mapping
  - files: lib/i18n/es/errors.i18n.yaml, lib/i18n/en/errors.i18n.yaml, lib/i18n/failure_text.dart, test/i18n/translations_test.dart
  - ac: AC1, AC3, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
