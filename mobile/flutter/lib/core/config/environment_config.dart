/// Environment configuration for the Zealova app.
///
/// Switch environments at build time:
///   flutter run --dart-define=ENV=dev          (local backend)
///   flutter run --dart-define=ENV=prod         (Render backend, default)
///
/// For release builds:
///   flutter build appbundle --dart-define=ENV=prod
enum Environment { dev, prod }

class EnvironmentConfig {
  EnvironmentConfig._();

  /// Current environment, set via --dart-define=ENV=dev|prod
  /// Defaults to prod so existing scripts/workflows are unchanged.
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  static Environment get current {
    switch (_env) {
      case 'dev':
      case 'development':
        return Environment.dev;
      default:
        return Environment.prod;
    }
  }

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;

  // -- Backend API -----------------------------------------------------------

  static String get backendBaseUrl {
    switch (current) {
      case Environment.dev:
        // 10.0.2.2 is Android emulator's alias for host machine localhost
        return const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://10.0.2.2:8000',
        );
      case Environment.prod:
        return const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'https://aifitnesscoach-zqi3.onrender.com',
        );
    }
  }

  // -- Supabase --------------------------------------------------------------
  // Same project for both envs for now. When you create a dev Supabase project,
  // add a dev case here with the new URL and anon key.

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hpbzfahijszqmgsybuor.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNjEzOTYsImV4cCI6MjA3OTgzNzM5Nn0.udv4b7UPhLLEfiWo7qd5ezqNTZ7KBXqzW_CwroNowAM',
  );

  // -- Google OAuth ----------------------------------------------------------

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '843677137160-h1jh9t4d0s6mui2eqsek2h0rnq27n19o.apps.googleusercontent.com',
  );

  // -- RevenueCat ------------------------------------------------------------

  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'test_key_placeholder',
  );

  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'test_key_placeholder',
  );

  // -- Sentry ---------------------------------------------------------------
  // Sentry DSNs are public by design (rate-limited per-project keys), so it's
  // safe to commit. Override at build time with
  //   flutter build appbundle --dart-define=SENTRY_DSN=https://...
  // if you ever rotate the key or point to a dev project.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://1f1f4e3167761431f27ded3e84831295@o4511241636872192.ingest.us.sentry.io/4511241668460544',
  );
}
