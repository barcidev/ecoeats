---
kind: quick
---

# Stacked auth sheets stay painted beneath the new one

## Objetivo

Cuando un panel de auth se abre sobre otro (por ejemplo, recuperar sobre el login), el de abajo se queda visible detrás, encogido y un poco más arriba, como hojas apiladas, también después de que termina la transición. Hoy las rutas hijas de auth son opacas y el panel de abajo deja de pintarse al terminar. Las rutas hijas de la shell de auth pasan a no opacas; la barrera de cada ruta sigue bloqueando los toques a lo de abajo.

## Archivos

- modificar lib/router/app_router.dart — rutas hijas de auth no opacas

## Tareas

- [ ] T1: Las rutas hijas de la shell de auth no son opacas, con test en test/router/app_router_test.dart
  - files: lib/router/app_router.dart
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/router test/router && fvm flutter analyze && fvm flutter test
