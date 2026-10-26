# ecoeats

<!-- specty:begin id=project -->
## Proyecto (detectado por Specty)
- Stack: Dart (flutter, flutter)
- Comandos:
  - Tests: `flutter test`
  - Lint: `flutter analyze`
<!-- specty:end id=project -->

<!-- specty:begin id=flow -->
## Flujo de trabajo (Specty)
Este repositorio usa Specty. Antes de crear, modificar o borrar código, ejecuta `specty next` y sigue su salida hasta la línea `SIGUIENTE:`. Habla con el usuario en español.
- Si el usuario pide un cambio y no hay uno activo, `specty next` te indica cómo crear la spec.
- Cada cambio vive en su propia carpeta (una worktree): tras `specty new`, trabaja en la carpeta que indica, no en la principal.
- Completa cada tarea con `specty task done <id>`; no ejecutes `git commit` tú mismo.
- Si necesitas un archivo fuera del alcance de la tarea, pídelo con `specty scope add`.
- Aprobar, aceptar y cerrar lo hace el usuario en su terminal; tú se lo pides y terminas tu turno. Solo si `SIGUIENTE:` te lo pide (modo delegado), los ejecutas tú.
- Si el comando `specty` no existe, usa `npx -y @baquia-dev/specty <comando>`. Nunca uses `npx specty`: es otro paquete.

## Reglas (Specty)
- Antes de reportar una tarea como terminada, ejecuta `specty check --changed --spec` y corrige todos los fallos. No reportes con fallos pendientes.
- Antes de crear un módulo, caso de uso, componente o pantalla, busca uno equivalente en el repo y replica su estructura.
- Localiza el código con búsquedas dirigidas por símbolo o texto y lee solo los fragmentos necesarios, no archivos completos.
- Edita con cambios puntuales; no reescribas archivos completos para cambios pequeños.
- Reporte final breve: qué cambió, qué se verificó y qué queda pendiente.
<!-- specty:end id=flow -->

## Map

<!-- Directories whose purpose is not obvious, and what must not be touched (generated code, applied migrations…). -->

## Conventions

<!-- Only what cannot be inferred from the code and no linter enforces. Every rule, verifiable. -->
