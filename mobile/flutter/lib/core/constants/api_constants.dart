/// API configuration constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for the backend API
  static const String baseUrl = 'https://ai-fitness-coach-api.onrender.com';

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Connection timeout (longer for Render cold start)
  static const Duration connectTimeout = Duration(seconds: 90);

  /// Read timeout (longer for AI responses)
  static const Duration receiveTimeout = Duration(seconds: 120);

  /// Write timeout
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Google OAuth Web Client ID
  static const String googleWebClientId =
      '763543360320-hjregsh5hn0lvp610sjr36m34f9fh2bj.apps.googleusercontent.com';

  // Endpoint paths
  static const String auth = '/users/auth/google';
  static const String users = '/users';
  static const String workouts = '/workouts-db';
  static const String chat = '/chat';
  static const String exercises = '/exercises';
  static const String library = '/library';
  static const String insights = '/insights';
  static const String achievements = '/achievements';
  static const String onboarding = '/onboarding';
  static const String metrics = '/metrics';
  static const String feedback = '/feedback';
}
