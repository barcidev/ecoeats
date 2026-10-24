# ecoeats

## What it is

El objetivo es una app Flutter que liste los platos del API EcoEats (Swagger en producción). Debe sentirse como un producto premium: pantalla completa, animaciones cuidadas y una UX/UI hecha a mano, sin señales de "plantilla generada por IA". La carpeta ecoeats/ está vacía, así que el proyecto parte de cero.

## Who it is for

Para personas que quieren ver platos de comida saludable

## MVP scope

App móvil Flutter (iOS y Android) para clientes de EcoEats que consume el API en producción. Incluye registro con inicio de sesión automático, login con JWT y recuperación de contraseña con un código OTP enviado por correo. Muestra el catálogo de platos con destacados en carrusel, búsqueda que ignora las tildes, filtros y orden. Cada plato tiene un detalle con foto a pantalla completa, macros e ingredientes. Trae un modo Descubrir para recorrer los platos a pantalla completa deslizando en vertical. El perfil permite elegir tema claro u oscuro e idioma español o inglés, y cerrar sesión. La app debe manejar con estados diseñados la sesión expirada, la falta de conexión, el límite de peticiones (429) y las imágenes rotas, y verse como un producto premium hecho a mano, con animaciones cuidadas. Queda fuera de alcance: CRUD de administrador, carrito, favoritos y pagos.

## Out of scope

Funciones de administrador (crear, editar y eliminar platos, subir o quitar imágenes), aunque el API ya las tiene. Carrito, pedidos y pagos. Favoritos y calificaciones hechas por los usuarios (la calificación solo se muestra). Edición de perfil y eliminación de cuenta, que el API no soporta. Login social o con Firebase. Mantener la sesión más de 24 h, porque el API no tiene refresh token. Notificaciones push. Catálogo sin conexión (solo se cachean las imágenes). Versión web y de escritorio, ya que solo se hace iOS y Android. Diseño para tablet y orientación horizontal. Traducir el contenido de los platos (solo se traduce la interfaz) e idiomas distintos de español e inglés. Analítica y reporte de errores.

## Stack

Dart 3.13 y Flutter 3.47.8, fijado al proyecto con fvm; solo iOS y Android. Estado con Riverpod 3 (flutter_riverpod 3.4 y riverpod_generator); modelos inmutables con freezed 4.0.1 y json_serializable; rutas con auto_route 11; traducciones con slang (español como base, más inglés); HTTP con dio; el JWT se guarda en flutter_secure_storage y las preferencias en shared_preferences; imágenes con cached_network_image; formatos de número y fecha con intl. La interfaz usa material_ui y cupertino_ui, porque Flutter 3.47 sacó Material del framework. Íconos de Phosphor y fuentes Fraunces e Instrument Sans empaquetadas en la app. Para desarrollo: build_runner 2.16.1 para generar código, very_good_analysis y riverpod_lint para lints, flutter_test y mocktail para tests, y flutter_native_splash y flutter_launcher_icons para el splash y los íconos. freezed queda en 4.0.1 y build_runner en 2.16.1 porque son las últimas versiones compatibles con auto_route_generator 10.6. El backend es el API REST de EcoEats (Spring Boot con Kotlin), documentado en OpenAPI.

## Deployment

App móvil para clientes de EcoEats en teléfonos iOS y Android, en orientación vertical y con conexión a internet (no hay modo sin conexión). Consume por HTTPS el API de EcoEats desplegado en Railway (https://ecoeats-api-kotlin-production.up.railway.app). La URL se configura con --dart-define=API_BASE_URL y por defecto apunta a producción, así que también puede apuntar a un backend local para desarrollo. El identificador de la app es co.ecoeats.ecoeats. Durante el desarrollo se ejecuta con fvm en simuladores de iPhone (17 Pro y SE) y en un emulador Android (Pixel 9). Para la v1 se generan builds de release (APK o AAB para Android y build de iOS desde Xcode) para instalar en dispositivos de prueba. La publicación en App Store y Google Play queda para después.

## Constraints

<!-- Any constraints? (deadlines, budget, rules, compatibility…) -->
