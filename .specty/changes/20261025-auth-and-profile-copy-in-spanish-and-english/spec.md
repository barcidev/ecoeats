---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C2
---

# Auth and profile copy in Spanish and English

## Goal

Every text the auth screens and the profile sheet will show exists in Spanish and English before the screens are built: the welcome, login, the two registration steps, the three recovery steps, the password checklist, the message for each field rule, and the profile with its appearance, language and sign-out. English is written in its own voice, not word for word.

## Out of scope

- The screens that use the texts (C3, C5, C6, C8, C9).
- `common` and `errors` (phase 0): server failures, retry countdown and conflicts already have their words there and are reused.
- Dish content, which is never translated.

## Assumptions

- A1: The keys phase 0 created in `auth` and `profile` stay with their names, so nothing that reads them breaks; this slice adds keys and may polish values.
- A2: Each field rule (`FieldIssue` from C1) gets its own message per field, with the limits as parameters (`{max}`, `{min}`) so the numbers live only in `Validators`.
- A3: Language names are written in their own language in both files (Español, English), as the plan asks.
- A4: Countdowns arrive as already formatted text (`{time}`, such as `14:59`), so the copy does not format durations.

## Acceptance criteria

- AC1: WHEN the app runs in Spanish or English THEN the auth namespace has the texts of the welcome, login, two-step registration, three-step recovery (masked email message, code expiry and resend countdowns, rejected, locked and expired code, done), password checklist and every field rule.
- AC2: WHEN the profile sheet runs in either language THEN it has the session expiry (hours and less than an hour), appearance, language and sign-out confirmation texts, with Español and English named in their own language.
- AC3: WHEN a rejected code leaves 1 or several attempts THEN the message uses the singular or the plural of each language.
- AC4: WHEN the translations test runs THEN Spanish and English define the same keys and the new plural and language-name checks pass.

## Files

- modify lib/i18n/es/auth.i18n.yaml — Spanish auth copy
- modify lib/i18n/en/auth.i18n.yaml — English auth copy
- modify lib/i18n/es/profile.i18n.yaml — Spanish profile copy
- modify lib/i18n/en/profile.i18n.yaml — English profile copy
- modify test/i18n/translations_test.dart — plural and language-name checks

## Tasks

- [x] T1: Auth and profile copy in both languages, with their translation checks
  - files: lib/i18n/es/auth.i18n.yaml, lib/i18n/en/auth.i18n.yaml, lib/i18n/es/profile.i18n.yaml, lib/i18n/en/profile.i18n.yaml, test/i18n/translations_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/i18n
