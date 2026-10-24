---
kind: standard
allowedDependencies:
  - flutter_riverpod
  - riverpod_annotation
  - freezed_annotation
  - json_annotation
  - auto_route
  - slang
  - slang_flutter
  - dio
  - flutter_secure_storage
  - shared_preferences
  - cached_network_image
  - intl
  - material_ui
  - cupertino_ui
  - phosphor_flutter
  - flutter_localizations
  - flutter_native_splash
  - auto_route_generator
  - freezed
  - json_serializable
  - riverpod_generator
  - build_runner
  - riverpod_lint
  - very_good_analysis
  - mocktail
  - flutter_launcher_icons
  - flutter_test
---

# Project skeleton

## Goal

The Flutter project exists with the toolchain the plan fixes: Flutter 3.47.8 pinned with fvm, every dependency of the plan resolved, very_good_analysis and riverpod_lint enabled, build_runner and slang configured, and generated files kept out of git. A minimal app renders and a smoke test passes. This is the first of the chained changes of phase 0; the native platforms come in the next one.

## Out of scope

- The `android/` and `ios/` folders and their native configuration (next change).
- Fonts, design tokens, theme and design widgets.
- Core (network, session, formatters), data, routes, translations and features.

## Assumptions

- A1: Phase 0 is split into chained standard changes of at most 2 modules each, because the repository keeps Specty's default split limits; this change covers the root configuration and `lib/`.
  - impact: high
- A2: Flutter 3.47.8 is pinned with `.fvmrc` (`updateVscodeSettings: false`, `updateGitIgnore: false`), and every command runs through `fvm`.
- A3: `flutter_native_splash` goes in `dependencies`, not `dev_dependencies`, because `main.dart` will call `FlutterNativeSplash.preserve()`.
- A4: Generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `lib/i18n/gen/`) are in `.gitignore`, so every verification regenerates them with `build_runner` (and later `slang`).
- A5: If the solver does not settle on the plan's versions by itself, `freezed` and `build_runner` are pinned to 4.0.1 and 2.16.1, the newest compatible with `auto_route_generator` 10.6.
- A6: The project is created with `fvm flutter create --org co.ecoeats --project-name ecoeats --platforms ios,android` in a scratch folder, and this change takes only its root files, `lib/` and `test/`.

## Acceptance criteria

- AC1: WHEN `fvm flutter pub get` runs THEN every dependency of the plan resolves and `pubspec.lock` is written.
- AC2: WHEN `fvm dart run build_runner build -d` and then `fvm flutter analyze` run THEN both finish without errors and analyze reports no issues.
- AC3: WHEN `fvm flutter test` runs THEN the smoke test passes, finding the «EcoEats» text the minimal app renders.

## Files

- create .fvmrc — Flutter 3.47.8 pin
- create .gitignore — Flutter defaults, fvm and generated code
- create .metadata — project metadata from flutter create
- create pubspec.yaml — the plan's dependencies
- create pubspec.lock — resolved versions
- create analysis_options.yaml — very_good_analysis and riverpod_lint, without public_member_api_docs
- create build.yaml — options of freezed, json_serializable, riverpod and auto_route
- create slang.yaml — base locale es, namespaces, braces interpolation
- create lib/main.dart — minimal app
- create test/smoke_test.dart — first test

## Tasks

- [x] T1: Pin Flutter and resolve the dependencies
  - files: .fvmrc, .gitignore, .metadata, pubspec.yaml, pubspec.lock
  - ac: AC1
  - verify: fvm flutter pub get
  - type: chore
- [ ] T2: Configure lints and code generation, and render the minimal app
  - files: analysis_options.yaml, build.yaml, slang.yaml, lib/main.dart, test/smoke_test.dart
  - ac: AC2, AC3
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test

## Risks

- R1: Some version from the plan does not exist or does not solve with Dart 3.13.7. Mitigation: pin the newest compatible version and note it in the task.
