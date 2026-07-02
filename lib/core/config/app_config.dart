// Demo/prototype credentials — replace with environment-based config before production.
// In a real build, supply these via `--dart-define=ADMIN_EMAIL=...` at compile time.
class AppConfig {
  static const adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'admin@wedpilot.app',
  );
  static const adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'W3dP!l0t#Adm1n',
  );
}
