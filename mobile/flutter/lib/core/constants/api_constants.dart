/// API configuration constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for the backend API
  // Development: Use localhost:8000 for local testing
  // Production: Use https://fitwiz-zqi3.onrender.com
  static const String baseUrl = 'https://aifitnesscoach-zqi3.onrender.com'; // Production

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Supabase configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hpbzfahijszqmgsybuor.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNjEzOTYsImV4cCI6MjA3OTgzNzM5Nn0.udv4b7UPhLLEfiWo7qd5ezqNTZ7KBXqzW_CwroNowAM',
  );

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Connection timeout
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Read timeout
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Write timeout
  static const Duration sendTimeout = Duration(seconds: 15);

  /// AI-specific receive timeout (longer for AI responses)
  static const Duration aiReceiveTimeout = Duration(minutes: 2);

  /// Google OAuth Web Client ID
  static const String googleWebClientId =
      '843677137160-h1jh9t4d0s6mui2eqsek2h0rnq27n19o.apps.googleusercontent.com';

  /// RevenueCat API Keys - supplied via --dart-define at build time
  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'test_key_placeholder',
  );
  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'test_key_placeholder',
  );

  /// Google Maps API Key (for gym location picker)
  /// To set up:
  /// 1. Go to Google Cloud Console: https://console.cloud.google.com/
  /// 2. Create or select a project
  /// 3. Enable: Maps SDK for Android, Maps SDK for iOS, Places API, Geocoding API
  /// 4. Create API Key and add restrictions for your app
  // static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE'; // Removed for v1

  // Endpoint paths
  static const String auth = '/users/auth/google';
  static const String users = '/users';
  static const String workouts = '/workouts';
  static const String chat = '/chat';
  static const String exercises = '/exercises';
  static const String library = '/library';
  static const String insights = '/insights';
  static const String achievements = '/achievements';
  static const String onboarding = '/onboarding';
  static const String metrics = '/metrics';
  static const String feedback = '/feedback';
  static const String hydration = '/hydration';
  static const String nutrition = '/nutrition';
  static const String summaries = '/summaries';
  static const String aiSettings = '/ai-settings';
  static const String scheduling = '/scheduling';
  static const String dailySchedule = '/daily-schedule';
  static const String supersets = '/supersets';
}
