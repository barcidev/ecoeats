---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C1
---

# Input validators: email, names, document, password (6 characters to 72 bytes, with checklist rules) and 6-digit code, with unit tests

## Goal

The auth screens can check every field before sending it, with the same rules the API enforces, so a request the server would reject with 400 is never sent. The password rules also feed the live checklist of registration and recovery.

## Out of scope

- Turning the reasons into text (C2 has the copy; each screen maps them).
- Any screen, controller or request.
- Server-side errors (400, 409); those come back through `AppFailure` in the controllers.

## Assumptions

- A1: The rules mirror the API's request DTOs: document, first names and last names are required (not blank) with at most 30, 100 and 100 characters; the email is required, well formed and at most 150 characters; a new password has at least 6 characters (UTF-16 units, as Java's `@Size` and Dart's `length` count them) and at most 72 bytes in UTF-8; the code is exactly six ASCII digits.
- A2: The login password is only checked for being present: accounts created before a rule changed must still be able to sign in.
- A3: Values are checked trimmed, except passwords, which are checked exactly as typed because spaces are valid characters in them. The email is also normalized to lowercase for sending, as the server does.
- A4: A client email check that is a bit stricter than Hibernate's (it asks for a dot in the domain) is acceptable: real customer addresses always have one.
- A5: Validators return a typed reason (`FieldIssue`) or null, never text, so they stay pure Dart and the screens translate them.

## Acceptance criteria

- AC1: WHEN an email is empty, has spaces inside, lacks `@` or a dot in the domain, or exceeds 150 characters THEN the email validator returns the matching reason; WHEN it is well formed with surrounding spaces THEN it is valid and normalizes to the trimmed lowercase address.
- AC2: WHEN first names, last names or the document are blank or exceed 100, 100 and 30 characters THEN their validator returns `required` or `tooLong`; otherwise it returns null.
- AC3: WHEN a new password has fewer than 6 characters THEN it is rejected as too short; WHEN it exceeds 72 bytes in UTF-8, for example 30 emoji or 40 «ñ», even with fewer than 72 characters, THEN it is rejected as too many bytes; WHEN it has 6 or more characters and fits in 72 bytes THEN it is valid.
- AC4: WHEN the checklist of a password is built THEN it reports separately whether the length rule and the byte rule pass, and the bytes used.
- AC5: WHEN a code is not exactly six ASCII digits THEN the code validator rejects it; WHEN a confirmation differs from its password THEN the confirmation validator returns `mismatch`.
- AC6: WHEN `fvm flutter test test/features/auth/application/validators_test.dart` runs THEN every case above passes.

## Files

- create lib/features/auth/application/validators.dart — field rules, `FieldIssue` reasons and the password checklist
- create test/features/auth/application/validators_test.dart — unit tests for every rule and edge case

## Tasks

- [x] T1: Field validators, the password checklist and their unit tests
  - files: lib/features/auth/application/validators.dart, test/features/auth/application/validators_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze lib/features/auth test/features/auth && fvm flutter test test/features/auth/application/validators_test.dart

## Closing

### Summary

`lib/features/auth/application/validators.dart` has the field rules the API enforces, as pure Dart: `Validators` returns a typed `FieldIssue` (or null) for email, names, document, login password, new password, confirmation and the 6-digit code, and `PasswordChecklist` reports the length and byte rules separately, with the bytes used. 22 unit tests cover every rule, including the 72-byte limit with «ñ» and emoji, and ASCII-only digits in the code. The whole suite (45 tests) and `flutter analyze` pass.

### Deviations

- None.

### Decisions

- A password made only of spaces counts as missing, like the API's `@NotBlank`; any other space is part of the password and counts toward its length and bytes.
- `FieldIssue` has one generic `invalid` for a malformed email or code; the screen knows which field it is and picks the message.
- The limits are public constants (`Validators.maxNameLength`…), so the copy and the screens can show them without repeating numbers.

### Follow-ups

- C2 adds the message for each `FieldIssue` in Spanish and English.
- `.specty/config.yaml` has no `verify.full`; with `fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test`, accepting would verify the whole repository.
