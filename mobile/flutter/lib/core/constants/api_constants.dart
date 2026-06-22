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

  /// Hard cap on any single Supabase `refreshSession()` attempt. Without it a
  /// hung refresh (dead/stale session, wedged gotrue client) blocks forever:
  /// the 401 interceptor coalesces every authenticated request onto one shared
  /// refresh future, so one stuck refresh leaves every screen spinning
  /// "Pending" indefinitely. With this cap a hang becomes a clean failure that
  /// trips the existing force-sign-out → re-auth path instead.
  static const Duration tokenRefreshTimeout = Duration(seconds: 10);

  /// Hard cap on any single secure-storage (Keychain) read/write.
  /// FlutterSecureStorage serializes every operation through ONE platform
  /// channel; under contention an op can STALL (hang, not throw), and there is
  /// no native timeout. The token + user-id writes that EVERY auth path runs
  /// (`setUserId`/`setAuthToken` — Google/Apple/email/restore) sit on the
  /// critical path before the auth state can flip to authenticated, so one
  /// stalled write wedges sign-in forever with an infinite spinner and NO
  /// exception (invisible to Sentry/backend). This cap turns a stall into a
  /// SharedPreferences fallback so the auth flow always proceeds. A storage op
  /// is normally <100ms; 4s is a generous ceiling.
  static const Duration secureStorageOpTimeout = Duration(seconds: 4);

  /// Hard cap on a full repository sign-in/sign-up call inside the auth
  /// notifier (defense-in-depth). Even with [secureStorageOpTimeout], no auth
  /// notifier should ever sit in `loading` indefinitely — on timeout we flip to
  /// a visible, retryable error instead of a dead screen. 20s comfortably
  /// exceeds Supabase signUp + `/auth/sync` + capped storage writes.
  static const Duration authOpTimeout = Duration(seconds: 20);

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
  static const String revenueCatAppleApiKey =
      EnvironmentConfig.revenueCatAppleApiKey;
  static const String revenueCatGoogleApiKey =
      EnvironmentConfig.revenueCatGoogleApiKey;

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
  // Saved-workout library + Customization Studio presets (Google-Health-parity).
  // Studio sub-paths build off `workouts` (e.g. '$workouts/customize').
  static const String savedWorkouts = '/saved-workouts';
  static const String workoutPresets = '/workout-presets';
  // Generalized event log + Timeline aggregator (added 2026-05-10).
  static const String events = '/events';
  static const String timeline = '/timeline';
  static const String wellnessMood = '/wellness/mood';

  // Stats tab — training/fueling trend surfaces (2026-05-28).
  // Volume trend: GET /scores/volume-trend?user_id=&weeks=12 — Σ(weight×reps)
  // per ISO week, zero-filled. Fueling split: GET
  // /nutrition/training-vs-rest/{user_id}?days=30&tz= — avg protein/calories on
  // training vs rest days. Training insight reuses /coach/daily-insight with
  // source=workout_stats (see coachDailyInsight below).
  static const String scoresVolumeTrend = '/scores/volume-trend';
  static const String nutritionTrainingVsRest = '/nutrition/training-vs-rest';
  static const String coachDailyInsight = '/coach/daily-insight';
  // Per-muscle estimated-1RM trend (next-PR ETA): GET
  // /scores/strength/e1rm-trend?user_id=&weeks=12 — best e1RM per ISO week per
  // muscle, null-filled, only muscles with >=1 non-null week.
  static const String scoresE1rmTrend = '/scores/strength/e1rm-trend';
  // Coach long-term memory ("What Coach Remembers" settings surface).
  // Base router prefix mounted by `backend/api/v1/coach_memory.py`.
  static const String coachMemory = '/coach/memory';

  /// `GET`/`PUT /coach/memory/settings` — `{ "enabled": bool }` master toggle.
  static const String coachMemorySettings = '$coachMemory/settings';

  /// `PATCH`/`DELETE /coach/memory/{id}` — edit content / tombstone a memory.
  static String coachMemoryItem(String id) => '$coachMemory/$id';

  /// `POST /coach/memory/{id}/resolve` — close an open follow-up loop.
  static String coachMemoryResolve(String id) => '$coachMemory/$id/resolve';

  // Chat sessions ("Ask Coach" conversation list, like ChatGPT/Gemini).
  // Backend router mounted at `/coach/sessions`. Each session groups a
  // distinct conversation thread; messages are scoped per session via a
  // `session_id` on `chat_history` rows.
  /// `GET /coach/sessions?q=&include_archived=&limit=&offset=` (list) and
  /// `POST /coach/sessions` (create).
  static const String coachSessions = '/coach/sessions';

  /// `GET /coach/sessions/{id}` (fetch) · `PATCH` (rename/archive) ·
  /// `DELETE` (delete + cascade messages).
  static String coachSessionItem(String id) => '$coachSessions/$id';

  /// `GET /coach/sessions/{id}/messages?limit=&offset=` — oldest-first
  /// `chat_history` rows for a single session.
  static String coachSessionMessages(String id) =>
      '$coachSessions/$id/messages';

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
