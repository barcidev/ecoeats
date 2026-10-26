---
kind: standard
---

# Login and registration celebrate on the button and sweep from its check

## Objetivo

Al entrar o crear la cuenta, el botón celebra antes de soltar la pantalla: se abre y dibuja su check (`success` de `EcoButton`), y desde ese check nace la barrida achiote, que cubre la app mientras Home aparece debajo. La pantalla retiene la ida a Home con el hold del cambio anterior y lo suelta cuando la barrida ya cubrió todo.

## Fuera de alcance

- El `EcoButton` y su animación de éxito (agente C), que se usan tal cual.
- La recuperación, que no inicia sesión.

## Supuestos

- A1: Login y registro llaman a `hold()` antes de enviar, lo sueltan si el intento falla o si la pantalla se va, y en el éxito lo sueltan desde la barrida, cuando el disco ya cubre la app.
  - impacto: alto
- A2: La barrida nace en el centro del botón, donde está el check, con el radio de la mitad del botón; así parece que el botón mismo se expande.
- A3: Con movimiento reducido el botón muestra el check sin animar, no hay barrida y el hold se suelta enseguida.
- A4: El registro recibe el mismo cambio que el login, para que las dos formas de entrar celebren igual.
- A5: Los tests de éxito de login y registro cambian su expectativa (la barrida llega después del check), porque el comportamiento cambia a pedido del usuario.

## Criterios de aceptación

- AC1: CUANDO el login o el registro tienen éxito ENTONCES el botón muestra su check dibujado y, al terminar el check, nace de él la barrida achiote.
- AC2: CUANDO la barrida cubre la app ENTONCES se suelta el hold y la app pasa a Home bajo la barrida, que luego se desvanece.
- AC3: CUANDO el intento falla o la pantalla se cierra ENTONCES el hold se suelta y nada queda esperando.
- AC4: CUANDO el movimiento reducido está activo ENTONCES no hay barrida y la ida a Home no espera.
- AC5: CUANDO corre `fvm flutter test` ENTONCES pasan los tests de la barrida, del login y del registro.

## Archivos

- modificar lib/features/auth/presentation/widgets/achiote_sweep.dart — avisar cuando la barrida cubre la app
- modificar lib/features/auth/presentation/login_page.dart — hold, botón con éxito y barrida desde onSuccess
- modificar lib/features/auth/presentation/register_page.dart — lo mismo para el registro

## Tareas

- [x] T1: La barrida avisa cuando cubre la app, con tests en test/features/auth/presentation/widgets/achiote_sweep_test.dart
  - files: lib/features/auth/presentation/widgets/achiote_sweep.dart
  - ac: AC2, AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [x] T2: Login y registro celebran en el botón y barren desde su check, con tests en test/features/auth/presentation/
  - files: lib/features/auth/presentation/login_page.dart, lib/features/auth/presentation/register_page.dart
  - ac: AC1, AC2, AC3, AC4, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Cierre

### Resumen

Login y registro celebran en su botón: al tener éxito pasan `success: state.succeeded` al `EcoButton`, que se abre y dibuja su check, y desde `onSuccess` nace la barrida achiote en el centro del botón, donde está el check. Antes de enviar, cada pantalla toma el hold de `signInHoldProvider`; la barrida lo suelta cuando el disco cubre la app (`AchioteSweep.play` ahora avisa con `onCovered`), y entonces la app pasa a Home bajo la barrida, que luego se desvanece. Un intento fallido o una pantalla que se cierra sueltan el hold, y con movimiento reducido no hay barrida y se suelta al instante. 3 tests nuevos (2 de la barrida, 1 del login) y los de éxito de login y registro reescritos para el nuevo orden; la suite completa (418 tests) y `flutter analyze` pasan.

### Desviaciones

- El registro recibe el mismo cambio que el login, como dice A4, aunque el pedido nombraba solo el login.
- La verificación completa de `.specty/config.yaml` (`flutter analyze && flutter test`) usa el Flutter global (3.44.8), que no resuelve las dependencias; la aceptación se corrió con el Flutter fijado por fvm (3.47.8) primero en el PATH.

### Decisiones

- El fin del crecimiento de la barrida se lee del valor de la animación, porque el estado de un `Interval` sigue al de toda la animación y solo llega a «completado» al final.
- La barrida nace del centro del botón con el radio de su mitad: el check está centrado, así que el disco sale de él y parece que el botón mismo se expande.

### Pendientes

- Conviene que `verify` en `.specty/config.yaml` use `fvm flutter`, para que la verificación completa corra con el SDK del proyecto (archivo protegido: lo cambia la persona).
- Ver la celebración completa en un simulador (check, barrida y Home debajo).
