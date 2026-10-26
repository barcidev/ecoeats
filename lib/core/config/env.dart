abstract final class Env {
  /// Override with `--dart-define=API_BASE_URL=http://localhost:8080` to work
  /// against a local backend.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ecoeats-api-kotlin-production.up.railway.app',
  );
}
