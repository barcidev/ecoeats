---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C8
---

# Android icon and splash: adaptive and monochrome launcher icon and the light and dark splash, Android 12+ API included

## Goal

On Android, EcoEats looks like itself before its first frame. The launcher shows the plate mark as an adaptive icon on «Mantel» paper, and Android 13+ can tint it to match the wallpaper. Opening the app shows the mark on paper, light or dark with the phone's theme, through the classic launch background and through the Android 12+ splash API.

## Out of scope

- iOS (C9). The shared generator configs keep `ios: false` until then.
- The Dart side of the splash: `main.dart` already preserves it until the session is restored.
- Store listing icons and release signing.

## Assumptions

- A1: The generators read their own `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml` at the root, so `pubspec.yaml` stays untouched. Their output under `android/` is committed. Specty ignores the native folders, so they are not part of this change's size.
  - impact: high
- A2: The adaptive icon uses `icon_foreground.png` over a solid «Mantel» paper background (#F4EEE4), with `icon_monochrome.png` as its themed layer. Older launchers get `icon.png`, generated as the legacy `ic_launcher`.
- A3: The splash background is «Mantel» paper (#F4EEE4) in light mode and «Fogón» paper (#14110E) in dark mode, with the matching mark. Android 12+ gets its own icon source and the same background colors.
- A4: The generators' edits to `styles.xml` keep the phase 0 themes. The diff is reviewed after each run, and a debug APK is built and run on the Pixel 9 emulator to see the icon and the splash.

## Acceptance criteria

- AC1: WHEN the generators run THEN `android/` holds the launcher icon in every density, an adaptive icon (foreground, paper background, monochrome) for API 26+, and the launch backgrounds and styles for light, dark and API 31+.
- AC2: WHEN the debug APK is installed on the emulator THEN the launcher shows the plate mark on paper, and opening the app shows the mark on paper in light mode and on night paper in dark mode before the first frame.
- AC3: WHEN `fvm flutter build apk --debug`, `fvm flutter analyze` and `fvm flutter test` run THEN they all succeed.

## Files

- create flutter_launcher_icons.yaml — launcher icon generator config, Android on
- create flutter_native_splash.yaml — splash generator config, Android on, Android 12 included
- modify android/app/src/main/res/** — generated icons, launch backgrounds and styles

## Tasks

- [x] T1: Adaptive and monochrome launcher icon
  - files: flutter_launcher_icons.yaml, android/app/src/main/res/**
  - ac: AC1
  - verify: fvm dart run flutter_launcher_icons
- [ ] T2: Light and dark splash, Android 12+ included, built and seen on the emulator
  - files: flutter_native_splash.yaml, android/app/src/main/res/**
  - ac: AC1, AC2, AC3
  - verify: fvm dart run flutter_native_splash:create && fvm flutter build apk --debug && fvm flutter analyze && fvm flutter test

## Risks

- R1: The generators may not match the Flutter 3.47 Android template, or may overwrite phase 0's theme settings. Mitigation: review the diff of `styles.xml` and the manifest after each run and restore anything they drop; if a generator fails, write the resources by hand and note it.
