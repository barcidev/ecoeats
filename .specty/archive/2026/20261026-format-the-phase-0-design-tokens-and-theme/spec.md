---
kind: quick
---

# Format the phase 0 design tokens and theme

## Objetivo

Tres archivos de la fase 0 no pasan `dart format` y hacen fallar la revisión de formato de Specty en cada cambio, aunque el cambio no los toque. Se formatean, sin cambiar nada más que espacios y saltos de línea, para que esa revisión vuelva a señalar solo problemas reales.

## Archivos

- modificar lib/design/theme.dart — solo formato
- modificar lib/design/tokens/motion.dart — solo formato
- modificar lib/design/tokens/spacing.dart — solo formato

## Tareas

- [x] T1: Formatear el tema y los tokens de diseño
  - files: lib/design/theme.dart, lib/design/tokens/motion.dart, lib/design/tokens/spacing.dart
  - verify: fvm dart format --output=none --set-exit-if-changed . && fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
  - type: style

## Cierre

### Resumen

Formatted lib/design/theme.dart and the motion and spacing tokens with dart format; only line breaks changed.
