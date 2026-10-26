---
kind: quick
follows:
  - 20261025-dish-detail
---

# Native platforms

## Goal

The app runs on Android and iOS. `flutter create` (3.47.8, `co.ecoeats.ecoeats`) provides both host projects with the plan's settings: INTERNET permission, the «EcoEats» name, portrait only, predictive back on Android and the es/en localizations on iOS. The analyzer skips both folders, as Flutter's own template does. The Android folder is the one built and run in the cancelled change `20261025-android-platform`.

## Files

- modify analysis_options.yaml — exclude android/** and ios/** from analysis
- create android/** — Android host project (ignored path), from the cancelled change
- create ios/** — iOS host project (ignored path), with display name, localizations and portrait

## Tasks

- [x] T1: Add both host projects and exclude them from analysis
  - files: analysis_options.yaml, android/**, ios/**
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test && fvm flutter build apk --debug && fvm flutter build ios --simulator --debug
  - type: chore
