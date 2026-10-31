# EcoEats

> Catálogo móvil premium de platos saludables para iOS y Android que consume el API REST de EcoEats.

EcoEats está diseñado como un producto móvil artesanal: navegación a pantalla completa, microinteracciones cuidadas, físicas de resorte en componentes interactivos y una identidad visual distintiva basada en tipografías editoriales y texturas sutiles.

---

## Características

- **Catálogo interactivo**:
  - Carrusel de platos destacados en la cabecera.
  - Menú completo con filtrado por categorías y ordenación.
  - Búsqueda en tiempo real insensible a tildes y diacríticos.
- **Detalle de plato inmersivo**:
  - Vista a pantalla completa con transiciones compartidas (*Hero*).
  - Desglose visual de macronutrientes (proteínas, carbohidratos, grasas, calorías) e ingredientes.
  - Cierre interactivo mediante gesto de arrastre vertical (*swipe to dismiss*).
- **Modo Descubrir**:
  - Recorrido inmersivo vertical de platos estilo reel/feed a pantalla completa.
- **Autenticación completa**:
  - Registro en dos pasos con validación dinámica de requisitos de contraseña.
  - Inicio de sesión con persistencia segura de token JWT (`flutter_secure_storage`).
  - Recuperación de contraseña mediante flujo de 3 pasos con código OTP por correo electrónico.
- **Perfil y personalización**:
  - Selector de tema visual (Claro / Oscuro / Sistema).
  - Selector de idioma en caliente (Español / Inglés con base en `slang`).
  - Cierre de sesión seguro y gestión de estado de usuario.
- **Resiliencia de red y estados UX**:
  - Manejo diseñado para estados sin conexión (*offline*), caducidad de sesión (401), límite de peticiones (429 *Too Many Requests*) y fallos en carga de imágenes.
  - Galería interna de diseño (`/gallery`) para validar tokens, componentes y microinteracciones.

---

## Stack Tecnológico

| Capa | Tecnología |
| :--- | :--- |
| **Framework & SDK** | Flutter 3.47.8 / Dart 3.13.7 (fijado con [FVM](https://fvm.app)) |
| **Gestión de Estado** | [Riverpod 3](https://riverpod.dev) (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`) |
| **Enrutamiento** | [AutoRoute 11](https://autoroute.vercel.app) con guards de autenticación y deep linking |
| **Modelos & Serialización** | `freezed` 4.0.1 y `json_serializable` 6.15.2 |
| **Cliente HTTP** | `dio` con interceptores de autenticación, reintentos y mapeo de errores |
| **Almacenamiento** | `flutter_secure_storage` (tokens JWT) y `shared_preferences` (preferencias de usuario) |
| **Internacionalización** | `slang` (soporte `es` como idioma base y `en`) |
| **Diseño & UI** | Tipografías locales *Fraunces* (display serif) e *Instrument Sans*, íconos de *Phosphor* y *custom painters* |
| **Linter & Análisis** | `very_good_analysis` y `riverpod_lint` |
| **Pruebas** | `flutter_test` y `mocktail` |
| **Backend** | API REST de EcoEats (Spring Boot / Kotlin en Railway) |

---

## Estructura del Proyecto

```text
lib/
├── app.dart              # Configuración raíz de la app y MaterialApp
├── main.dart             # Punto de entrada, inicialización de dependencias y splash
├── core/                 # Infraestructura compartida
│   ├── config/           # Variables de entorno y configuración general
│   ├── format/           # Formateadores de fecha, moneda y números
│   ├── network/          # Cliente Dio, interceptores, health check y retry policy
│   └── session/          # Manejo de JWT, almacenamiento seguro y sesión activa
├── design/               # Sistema de diseño
│   ├── gallery/          # Galería de componentes interactivos
│   ├── painters/         # Ilustraciones vectoriales y logomarca personalizados
│   ├── tokens/           # Paleta de colores, tipografía, espaciados y curvas de motion
│   └── widgets/          # Componentes reutilizables (botones, campos, spinners, etc.)
├── features/             # Módulos por dominio de negocio
│   ├── auth/             # Login, registro en dos pasos y recuperación con OTP
│   ├── discover/         # Navegación vertical de platos a pantalla completa
│   ├── dishes/           # Catálogo, carrusel, filtros, búsqueda y detalle
│   └── profile/          # Hoja modal de perfil, tema e idioma
├── i18n/                 # Archivos de traducción YAML (slang)
└── router/               # Definición de rutas, guards y transiciones
```

---

## Requisitos Previos

- [FVM (Flutter Version Management)](https://fvm.app/) instalado en tu entorno.
- Git.
- Xcode (para desarrollo o pruebas en iOS) y/o Android Studio (para Android).

---

## Instalación y Configuración

1. **Clonar el repositorio**:
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd ecoeats
   ```

2. **Instalar y usar la versión de Flutter configurada**:
   ```bash
   fvm install
   fvm use 3.47.8
   ```

3. **Obtener dependencias**:
   ```bash
   fvm flutter pub get
   ```

4. **Generar código (Riverpod, Freezed, AutoRoute y Slang)**:
   ```bash
   fvm dart run build_runner build -d
   fvm dart run slang
   ```

---

## Ejecución

### Entorno por Defecto (Producción en Railway)

Por defecto, la aplicación apunta al backend desplegado en Railway:

```bash
fvm flutter run
```

### Backend Local

Para apuntar a una instancia local de la API (por ejemplo, en `http://localhost:8080`):

```bash
fvm flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

---

## Calidad de Código y Pruebas

- **Ejecutar análisis estático (Linter)**:
  ```bash
  fvm flutter analyze
  ```

- **Ejecutar suite completa de tests**:
  ```bash
  fvm flutter test
  ```

- **Generar capturas para QA visual**:
  El proyecto incluye un arnés de prueba para generar capturas de pantalla de los componentes y pantallas principales en ambos temas (claro/oscuro) e idiomas (español/inglés) dentro de `build/qa/`:
  ```bash
  fvm flutter test tool/qa/screens_test.dart
  ```

