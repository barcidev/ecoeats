---
kind: standard
---

# One password visibility toggle for every auth form

## Objetivo

El ojo que muestra u oculta la contraseña es una sola pieza compartida en lugar de tres copias en login, registro y recuperación, así se ve y se anuncia igual en todas las pantallas.

## Fuera de alcance

- Cambiar cómo se ve o qué dice el ojo.
- Otros campos de los formularios.

## Supuestos

- A1: `PasswordToggle` vive en `widgets/auth_panel.dart` con las demás piezas compartidas de los paneles y recibe si la contraseña está oculta y qué hacer al tocarlo.

## Criterios de aceptación

- AC1: CUANDO la contraseña está oculta ENTONCES el ojo muestra el ícono de ojo y se anuncia «Mostrar contraseña»; CUANDO se ve ENTONCES muestra el ojo tachado y se anuncia «Ocultar contraseña»; tocarlo cambia el estado.
- AC2: CUANDO se abren el login, el registro o la contraseña nueva de la recuperación ENTONCES su campo de contraseña usa el mismo `PasswordToggle` y sigue mostrando y ocultando la contraseña.
- AC3: CUANDO corre `fvm flutter test` ENTONCES pasan el test del toggle y los de las tres pantallas.

## Archivos

- modificar lib/features/auth/presentation/widgets/auth_panel.dart — el toggle compartido
- modificar lib/features/auth/presentation/login_page.dart — usarlo
- modificar lib/features/auth/presentation/register_page.dart — usarlo
- modificar lib/features/auth/presentation/recover_page.dart — usarlo

## Tareas

- [x] T1: El toggle compartido, con su test en test/features/auth/presentation/widgets/auth_panel_test.dart
  - files: lib/features/auth/presentation/widgets/auth_panel.dart
  - ac: AC1, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T2: Login, registro y recuperación usan el toggle
  - files: lib/features/auth/presentation/login_page.dart, lib/features/auth/presentation/register_page.dart, lib/features/auth/presentation/recover_page.dart
  - ac: AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test
  - type: refactor
