---
kind: standard
follows:
  - 20261024-design-tokens-and-theme
---

# Network core and formatters

## Goal

The app has one way to talk to the EcoEats API and one vocabulary for what goes wrong: a configured Dio, an envelope reader, a sealed `AppFailure` that every error maps to (so the UI never shows a raw Spanish server message), a retry policy for `ProviderScope` that only retries transient failures, a warm-up ping to `/health`, and price, rating and date formatters for the active language.

## Out of scope

- The auth interceptor, token store and session (next change, it needs the auth data layer).
- Repositories and DTOs of dishes and auth.
- Translated texts for each failure (the i18n change maps failures to keys).

## Assumptions

- A1: `API_BASE_URL` comes from `--dart-define` and defaults to `https://ecoeats-api-kotlin-production.up.railway.app`.
- A2: The two known 409s are told apart by their message: «El email ya está registrado» is `email` and «El número de documento ya está registrado» is `document`; any other 409 keeps no field.
- A3: A 429 without a readable `Retry-After` waits 60 s.
- A4: `AppFailure` keeps the server message only as a fallback that the UI may show when the language is Spanish.
- A5: Formatters take a language code (`es` or `en`) so `core` does not depend on the generated translations; they round prices to whole pesos.

## Acceptance criteria

- AC1: WHEN Dio fails with a connection error THEN the failure is `offline`; WHEN it times out THEN `timeout`; WHEN the server answers 400 with `errors` THEN `validation` with each field and message; 401 THEN `unauthorized`; 404 THEN `notFound`; a known 409 THEN `conflict` with its field; 429 with `Retry-After: 42` THEN `rateLimited` of 42 s; 5xx THEN `server` with the `X-Request-Id`.
- AC2: WHEN a provider fails with `offline` or `timeout` THEN the retry policy retries at most twice with a growing delay; WHEN it fails with any other error THEN it does not retry.
- AC3: WHEN a request answers `success: true` THEN the helper returns the parsed `data`; WHEN the body is not an envelope or the parser throws THEN it throws `AppFailure.unknown`.
- AC4: WHEN the Dio provider is read THEN its base URL is the configured one, the connect timeout is 10 s and the receive timeout is 15 s; WHEN `/health` answers 503 THEN the warm-up ping completes without throwing.
- AC5: WHEN 28000 is formatted THEN the price is «$ 28.000» in es and «COP 28,000» in en; 4.9 is «4,9» and «4.9»; 2026-10-24 is «SÁBADO 24 DE OCTUBRE» and «SATURDAY, OCTOBER 24».

## Files

- create lib/core/config/env.dart — API base URL from dart-define
- create lib/core/network/app_failure.dart — sealed AppFailure (freezed)
- create lib/core/network/error_mapper.dart — DioException and any error to AppFailure
- create lib/core/network/retry.dart — ProviderScope retry policy
- create lib/core/network/api_envelope.dart — envelope reader and request helper
- create lib/core/network/dio_provider.dart — configured Dio provider
- create lib/core/network/health.dart — warm-up ping
- create lib/core/format/formatters.dart — price, rating and date per language
- create test/helpers/fake_http_adapter.dart — scripted Dio adapter for tests
- create test/core/network/error_mapper_test.dart — failure mapping and retry tests
- create test/core/network/api_envelope_test.dart — envelope, Dio and ping tests
- create test/core/format/formatters_test.dart — formatter tests

## Tasks

- [x] T1: AppFailure, error mapping and retry policy
  - files: lib/core/network/app_failure.dart, lib/core/network/error_mapper.dart, lib/core/network/retry.dart, test/core/network/error_mapper_test.dart
  - ac: AC1, AC2
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/core
- [ ] T2: Envelope, Dio and warm-up ping
  - files: lib/core/config/env.dart, lib/core/network/api_envelope.dart, lib/core/network/dio_provider.dart, lib/core/network/health.dart, test/helpers/fake_http_adapter.dart, test/core/network/api_envelope_test.dart
  - ac: AC3, AC4
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/core
- [ ] T3: Formatters per language
  - files: lib/core/format/formatters.dart, test/core/format/formatters_test.dart
  - ac: AC5
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
