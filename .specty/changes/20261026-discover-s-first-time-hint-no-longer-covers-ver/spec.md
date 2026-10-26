---
kind: quick
follows:
  - 20261026-discover-vertical-pager-over-the-visible-list-wi
---

# Discover's first-time hint no longer covers «Ver plato»

## Goal

The first time Discover opens, its swipe-up hint sat at the bottom, right on top of «Ver plato ↑». The first tap on that button only dismissed the hint instead of opening the dish. The hint now floats a little below the middle of the photo, as a coach mark. It never covers the dish's words or its button, and touches around it still reach the pager.

## Files

- modify lib/features/discover/presentation/discover_page.dart — the hint floats below the middle of the photo, away from the words and the button
- modify test/features/discover/discover_page_test.dart — the hint and the button never overlap, and the first tap opens the dish

## Tasks

- [ ] T1: Float the first-time hint off the button, with tests
  - files: lib/features/discover/presentation/discover_page.dart, test/features/discover/discover_page_test.dart
  - verify: fvm flutter test test/features/discover
