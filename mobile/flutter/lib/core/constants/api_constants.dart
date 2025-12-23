/// API configuration constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for the backend API
  // Development: Use localhost:8000 for local testing
  // Production: Use https://aifitnesscoach-zqi3.onrender.com
  static const String baseUrl = 'https://aifitnesscoach-zqi3.onrender.com'; // Production

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Supabase configuration
  static const String supabaseUrl = 'https://hpbzfahijszqmgsybuor.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNjEzOTYsImV4cCI6MjA3OTgzNzM5Nn0.udv4b7UPhLLEfiWo7qd5ezqNTZ7KBXqzW_CwroNowAM';

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
      '843677137160-h1jh9t4d0s6mui2eqsek2h0rnq27n19o.apps.googleusercontent.com';

  /// RevenueCat API Keys
  static const String revenueCatAppleApiKey = 'sk_SGkNgrhTGybZ1hAfyvXJTHhLLAmNY';
  static const String revenueCatGoogleApiKey = 'sk_SGkNgrhTGybZ1hAfyvXJTHhLLAmNY'; // Same key works for both

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
}
