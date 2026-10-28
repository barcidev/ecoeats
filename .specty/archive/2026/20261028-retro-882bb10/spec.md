---
kind: retro
---

# Configuración de tareas de VS Code y opciones de DevTools

## Objetivo

Agregar la configuración de tareas para VS Code en `.vscode/tasks.json` permitiendo vigilar y generar automáticamente código con `build_runner` y `slang`, además de incorporar `devtools_options.yaml` para las extensiones de Flutter DevTools.

## Motivo

Facilitar el desarrollo en el editor mediante tareas automáticas en segundo plano para la generación de código y traducciones en tiempo real.

## Archivos

- crear .vscode/tasks.json — Tareas de VS Code para watch de build_runner y slang
- crear devtools_options.yaml — Opciones de Flutter DevTools

## Riesgos

- R1: Ninguno — Archivos de configuración de herramientas y entorno local de VS Code sin impacto en el runtime o dependencias de la aplicación.
