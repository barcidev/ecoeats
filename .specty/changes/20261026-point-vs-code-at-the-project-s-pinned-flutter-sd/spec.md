---
kind: quick
---

# Point VS Code at the project's pinned Flutter SDK

## Objetivo

VS Code analiza el proyecto con el Flutter global (3.44.8, Dart 3.12), que no conoce la sintaxis de constructores de Dart 3.13, y por eso marca errores en casi todo `lib` aunque `fvm flutter analyze` no encuentre ninguno. El proyecto le dice al editor que use el SDK fijado por fvm (3.47.8), el enlace `.fvm/versions/3.47.8` que crea `fvm use`, y que no indexe esa carpeta.

## Archivos

- crear .vscode/settings.json — SDK de Flutter del proyecto para la extensión de Dart

## Tareas

- [x] T1: Configurar el SDK del proyecto para VS Code
  - files: .vscode/settings.json
  - verify: python3 -I -c "import json,sys; d=json.load(open('.vscode/settings.json')); sys.exit(0 if d['dart.flutterSdkPath'] == '.fvm/versions/3.47.8' else 1)"
  - type: chore
