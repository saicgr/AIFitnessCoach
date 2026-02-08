import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/accessibility/accessibility_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'data/services/data_cache_service.dart';
import 'data/services/haptic_service.dart';
import 'data/services/image_url_cache.dart';
import 'data/services/notification_service.dart';
import 'data/services/widget_action_headless_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Critical blocking initializations (must complete before runApp) ---
  // Run all three in parallel since they're independent of each other.
  // This saves ~500-1000ms vs sequential awaits on slow devices/emulators.

  late final SharedPreferences sharedPreferences;
  await Future.wait([
    Firebase.initializeApp().catchError((e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
    }),
    SharedPreferences.getInstance().then((prefs) => sharedPreferences = prefs),
    Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    ),
  ]);

  // NotificationService instance (constructor is synchronous; initialize() is deferred below)
  final notificationService = NotificationService();

  // Set system UI overlay style for dark theme (synchronous, non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge (synchronous, non-blocking)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Create ProviderContainer for widget actions
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      notificationServiceProvider.overrideWithValue(notificationService),
      notificationPreferencesProvider.overrideWith(
        (ref) => NotificationPreferencesNotifier(sharedPreferences, notificationService),
      ),
    ],
  );

  // --- Launch the app immediately to start rendering UI ---
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitWizApp(),
    ),
  );

  // --- Non-critical initializations run in parallel AFTER runApp ---
  // Performance fix H1: these no longer block first frame rendering.
  // Each has .catchError() so one failure doesn't affect the others.
  await Future.wait([
    notificationService.initialize().catchError((e) {
      debugPrint('⚠️ Notification service initialization failed: $e');
    }),
    ImageUrlCache.initialize().catchError((e) {
      debugPrint('⚠️ ImageUrlCache initialization failed: $e');
    }),
    DataCacheService.initialize().catchError((e) {
      debugPrint('⚠️ DataCacheService initialization failed: $e');
    }),
    HapticService.initialize().catchError((e) {
      debugPrint('⚠️ HapticService initialization failed: $e');
    }),
    SubscriptionNotifier.configureRevenueCat().catchError((e) {
      debugPrint('⚠️ RevenueCat initialization failed: $e');
    }),
  ]);

  // Pre-warm headless widget service for native widget actions
  try {
    final headlessService = container.read(widgetActionHeadlessServiceProvider);
    headlessService.initialize();
    debugPrint('✅ Widget action headless service initialized');
  } catch (e) {
    debugPrint('⚠️ Widget action headless service initialization failed: $e');
  }
}
