---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C9
---

# iOS icon and launch screen in light and dark

## Goal

On iOS, EcoEats shows its mark before the first frame, as on Android. The home screen has the plate mark on «Mantel» paper as its app icon, and the launch screen shows the mark on day paper or night paper, following the phone's appearance.

## Out of scope

- Android, already done in C8.
- App Store icons and marketing assets beyond the app's own icon set, and signing.

## Assumptions

- A1: The same generator configs from C8 turn iOS on (`ios: true`), and their output under `ios/` is committed. Specty ignores the native folders.
  - impact: high
- A2: The icon set comes from the opaque `icon.png`, with alpha removed, as the App Store requires. The launch screen uses `splash.png` and `splash_dark.png` over «Mantel» (#F4EEE4) and «Fogón» (#14110E) backgrounds.
- A3: The generators' edits to `Info.plist` and `LaunchScreen.storyboard` keep phase 0's settings: `CFBundleLocalizations` (es, en), the portrait lock and the app name. The diff is reviewed after each run, and anything dropped is restored.
- A4: A simulator debug build runs on the iPhone 15 Pro simulator, with screenshots of the launch screen in light and dark and of the home screen icon.

## Acceptance criteria

- AC1: WHEN the generators run THEN `ios/Runner/Assets.xcassets` holds the app icon at every size, built from the brand icon without alpha, and the launch images and background for light and dark, wired into the launch screen.
- AC2: WHEN the app is installed on the iPhone 15 Pro simulator THEN its icon on the home screen is the plate mark on paper, and the launch screen shows the mark on day paper in light appearance and on night paper in dark appearance.
- AC3: WHEN `fvm flutter build ios --simulator --debug`, `fvm flutter analyze` and `fvm flutter test` run THEN they all succeed, and `Info.plist` keeps its languages and its portrait lock.

## Files

- modify flutter_launcher_icons.yaml — iOS on, alpha removed
- modify flutter_native_splash.yaml — iOS on
- modify ios/Runner/Assets.xcassets — generated icon set, launch images and background
- modify ios/Runner/Base.lproj/LaunchScreen.storyboard — generated launch screen
- modify ios/Runner/Info.plist — only what the generator needs, phase 0 keys kept

## Tasks

- [x] T1: iOS app icon from the brand icon
  - files: flutter_launcher_icons.yaml, ios/Runner/Assets.xcassets
  - ac: AC1
  - verify: fvm dart run flutter_launcher_icons
- [x] T2: Light and dark launch screen, built and seen on the iPhone 15 Pro simulator
  - files: flutter_native_splash.yaml, ios/Runner/Assets.xcassets, ios/Runner/Base.lproj/LaunchScreen.storyboard, ios/Runner/Info.plist
  - ac: AC1, AC2, AC3
  - verify: fvm dart run flutter_native_splash:create && fvm flutter build ios --simulator --debug && fvm flutter analyze && fvm flutter test

## Risks

- R1: As on Android, the splash generator may rewrite `Info.plist` and drop phase 0 keys. Mitigation: review the diff and keep the plist as phase 0 left it, unless a key is needed for the launch screen.

## Closing

### Summary

On iOS, EcoEats shows its mark before the first frame, as on Android. The app icon set is drawn from the opaque brand icon, and the launch screen shows the mark on «Mantel» paper or «Fogón» paper, following the phone's appearance. A simulator build ran on the iPhone 15 Pro: the launch screen in light and dark, and the icon on the home screen, look as designed. `Info.plist` keeps its languages, name and portrait lock.

### Deviations

- `flutter_launcher_icons` 0.14 rewrites every `ASSETCATALOG_*` build setting in `project.pbxproj` with the icon's name, which breaks `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`. No option avoids it. The icon keeps the default name `AppIcon`, so the project needs no change: it was restored to its previous version, T1's verification broke it again, and T2 restored it for good. The config file now says to undo it after each run.
- `flutter_native_splash` reformats `Info.plist` and adds `UIStatusBarHidden = false`. The content is otherwise the same, and the generator's format is kept because every run rewrites it.

### Decisions

- `remove_alpha_ios: true` keeps the icon set opaque, as the App Store requires, even though the source already is.

### Follow-ups

- Reporting the `ASSETCATALOG_*` rewrite upstream to flutter_launcher_icons would remove the manual undo.
