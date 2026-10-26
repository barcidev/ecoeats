---
kind: standard
---

# A rejected code keeps its deadline in sight, and one email normalization

## Objetivo

En el paso del código, cuando el código fue rechazado, la persona sigue viendo cuánto le queda al código («Vence en mm:ss») debajo del aviso de intentos, en vez de perder ese dato. Además, el email se normaliza en un solo lugar: se quita `Validators.normalizeEmail`, que repetía el `normalizeEmail` del repositorio.

## Fuera de alcance

- Los demás estados del código: bloqueado y vencido no muestran la cuenta, porque ese código ya no sirve.
- La lógica de la recuperación.

## Supuestos

- A1: Con un código rechazado, el aviso de intentos va primero en achiote y la cuenta «Vence en» debajo, en gris, como en el estado normal.
- A2: El test que comprobaba `Validators.normalizeEmail` pasa a comprobar el `normalizeEmail` del repositorio con la misma aserción, así no se pierde la comprobación.

## Criterios de aceptación

- AC1: CUANDO un código es rechazado y quedan intentos ENTONCES se ven el aviso «Ese código no coincide…» y, debajo, «Vence en mm:ss» siguiendo la cuenta.
- AC2: CUANDO el código está bloqueado o vencido ENTONCES solo se ve su aviso.
- AC3: CUANDO se busca cómo se normaliza un email ENTONCES hay una sola función, la del repositorio, y su test sigue pasando.
- AC4: CUANDO corre `fvm flutter test` ENTONCES pasan los tests de la recuperación y de los validators.

## Archivos

- modificar lib/features/auth/presentation/recover_page.dart — la cuenta junto al aviso de código rechazado
- modificar lib/features/auth/application/validators.dart — quitar `normalizeEmail`

## Tareas

- [x] T1: La cuenta sigue visible con un código rechazado, con test en test/features/auth/presentation/recover_page_test.dart
  - files: lib/features/auth/presentation/recover_page.dart
  - ac: AC1, AC2, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T2: Una sola normalización de email, con su test en test/features/auth/application/validators_test.dart
  - files: lib/features/auth/application/validators.dart
  - ac: AC3, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test
  - type: refactor
