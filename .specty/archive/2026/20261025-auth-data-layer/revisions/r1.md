---
kind: standard
follows:
  - 20261025-network-core-and-formatters
---

# Auth data layer

## Goal

The app can call the five security endpoints of the API (register, login, forgot password, verify OTP and reset password) through an `AuthApi` that knows their paths and JSON shapes, behind an `AuthRepository` that normalizes emails and returns typed results. Errors surface as `AppFailure`, never as raw Dio errors.

## Out of scope

- Token storage, JWT decoding and the session controller (next change).
- Auth screens and their controllers (agent A).

## Assumptions

- A1: Register sends `numero_documento`, `nombres`, `apellidos`, `correo` and `password`, and login sends `email` and `password`, as the OpenAPI document of production says.
- A2: Emails are trimmed and lowercased before sending, as the API does on its side, so the stored session email matches what the server returns.
- A3: Register returns the user without a token; the auto-login after a 201 belongs to the session controller.

## Acceptance criteria

- AC1: WHEN login succeeds THEN the repository returns the user id, email and token of the response; WHEN the API answers 401 THEN it throws `AppFailure.unauthorized`.
- AC2: WHEN register is called THEN the request body uses the keys `numero_documento`, `nombres`, `apellidos`, `correo` and `password` with the email normalized, and a 201 returns the registered user.
- AC3: WHEN forgot password, verify OTP and reset password are called THEN they post to their endpoints, and verify OTP returns the `valid` flag of the response.

## Files

- create lib/features/auth/data/auth_dtos.dart — request and response DTOs (freezed and json)
- create lib/features/auth/data/auth_api.dart — HTTP calls of the security endpoints and its provider
- create lib/features/auth/data/auth_repository.dart — app-facing repository and its provider
- create test/features/auth/data/auth_repository_test.dart — repository and DTO tests

## Tasks

- [ ] T1: DTOs and AuthApi
  - files: lib/features/auth/data/auth_dtos.dart, lib/features/auth/data/auth_api.dart, test/features/auth/data/auth_repository_test.dart
  - ac: AC2, AC3
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T2: AuthRepository
  - files: lib/features/auth/data/auth_repository.dart, test/features/auth/data/auth_repository_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
