---
kind: standard
---

# Names start with a capital in the registration form

## Objetivo

Al escribir nombres y apellidos en el registro, el teclado empieza cada palabra en mayúscula, como se escriben los nombres. Para eso `EcoTextField` recibe un `textCapitalization` opcional.

## Fuera de alcance

- Corregir o transformar lo que la persona escribe: solo cambia cómo arranca el teclado.
- Los demás campos, que se quedan sin mayúscula automática (correo, documento, contraseñas).

## Supuestos

- A1: `textCapitalization` es un parámetro opcional de `EcoTextField` que por defecto es `none`, así ningún campo existente cambia.

## Criterios de aceptación

- AC1: CUANDO un `EcoTextField` recibe `textCapitalization` ENTONCES su campo de texto lo usa; CUANDO no lo recibe ENTONCES no capitaliza.
- AC2: CUANDO se abre el paso 1 del registro ENTONCES los campos de nombres y apellidos capitalizan cada palabra y el de documento no.
- AC3: CUANDO corre `fvm flutter test` ENTONCES pasan los tests de `EcoTextField` y del registro.

## Archivos

- modificar lib/design/widgets/eco_text_field.dart — parámetro `textCapitalization`
- modificar lib/features/auth/presentation/register_page.dart — nombres y apellidos con mayúscula por palabra

## Tareas

- [x] T1: `EcoTextField` acepta `textCapitalization`, con test en test/design/widgets/form_motion_test.dart
  - files: lib/design/widgets/eco_text_field.dart
  - ac: AC1, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/design/widgets test/design/widgets && fvm flutter analyze && fvm flutter test test/design
- [x] T2: Nombres y apellidos del registro con mayúscula por palabra, con test en test/features/auth/presentation/register_page_test.dart
  - files: lib/features/auth/presentation/register_page.dart
  - ac: AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Cierre

### Resumen

`EcoTextField` recibe un `textCapitalization` opcional (por defecto `none`, así ningún campo existente cambia) y lo pasa a su campo de texto. En el paso 1 del registro, nombres y apellidos empiezan cada palabra en mayúscula; el documento no. Un test de `EcoTextField` y uno del registro; la suite completa (421 tests) y `flutter analyze` pasan.

### Desviaciones

- El `build` de `EcoTextField` (134 líneas) se partió en `_field`, `_label`, `_underline` y `_errorLine`, y el mensaje de cada campo del paso 1 del registro pasó a `_aboutMessage`: la revisión `function-lines` de Specty limita a 50 líneas toda función que el cambio toca. Es una extracción sin cambios de comportamiento; los tests de `EcoTextField` siguen pasando.
- La verificación completa corrió con el Flutter fijado por fvm primero en el PATH.

### Decisiones

- Solo nombres y apellidos capitalizan; el documento puede llevar letras de un pasaporte y el correo nunca debe capitalizarse.

### Pendientes

- Ninguno.
