import '../config/environment_config.dart';

/// API configuration constants
class ApiConstants {
  ApiConstants._();

  /// Base URL for the backend API — driven by EnvironmentConfig
  static String get baseUrl => EnvironmentConfig.backendBaseUrl;

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Supabase configuration — driven by EnvironmentConfig
  static String get supabaseUrl => EnvironmentConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvironmentConfig.supabaseAnonKey;

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Connection timeout. 25s absorbs cold-start iOS/Android TCP+TLS handshake
  /// latency on weak networks and carrier handoffs (DNS → TLS → connect) where
  /// the connection itself — not the backend response — is what's slow.
  static const Duration connectTimeout = Duration(seconds: 25);

  /// Read timeout
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Write timeout
  static const Duration sendTimeout = Duration(seconds: 15);

  /// AI-specific receive timeout (longer for AI responses)
  static const Duration aiReceiveTimeout = Duration(minutes: 2);

  /// Chat media upload (presign + S3 PUT). Default 30s `receiveTimeout` was
  /// being hit by phone-recorded videos on cellular and surfaced as
  /// "Failed to send media: Request timed out". 3 minutes covers a 60s
  /// video on throttled 3G with headroom.
  static const Duration mediaUploadTimeout = Duration(minutes: 3);

  /// Connect timeout for media uploads — separate from `connectTimeout`
  /// because cellular handoff during a long upload can exceed 25s.
  static const Duration mediaUploadConnectTimeout = Duration(seconds: 45);

  /// Google OAuth Web Client ID — driven by EnvironmentConfig
  static const String googleWebClientId = EnvironmentConfig.googleWebClientId;

  /// RevenueCat API Keys — driven by EnvironmentConfig
  static const String revenueCatAppleApiKey = EnvironmentConfig.revenueCatAppleApiKey;
  static const String revenueCatGoogleApiKey = EnvironmentConfig.revenueCatGoogleApiKey;

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
  static const String dashboard = '/dashboard';
  // Generalized event log + Timeline aggregator (added 2026-05-10).
  static const String events = '/events';
  static const String timeline = '/timeline';
  static const String wellnessMood = '/wellness/mood';

  // Hormonal / cycle tracking (Phase B — 2026-05-22).
  // Base router prefix mounted by `backend/api/v1/hormonal_health.py`.
  static const String hormonalHealth = '/hormonal-health';

  /// `GET /hormonal-health/prediction/{user_id}` — full CyclePrediction.
  static String cyclePrediction(String userId) =>
      '$hormonalHealth/prediction/$userId';

  /// `GET`/`POST /hormonal-health/periods/{user_id}` — period history CRUD.
  static String cyclePeriods(String userId) =>
      '$hormonalHealth/periods/$userId';

  /// `PATCH`/`DELETE /hormonal-health/periods/{user_id}/{period_id}`.
  static String cyclePeriod(String userId, String periodId) =>
      '$hormonalHealth/periods/$userId/$periodId';

  /// `GET /hormonal-health/ai-insight/{user_id}` — a server-generated
  /// proactive cycle insight for the current phase/data, cached per day
  /// (Phase F).
  static String cycleAiInsight(String userId) =>
      '$hormonalHealth/ai-insight/$userId';
}
