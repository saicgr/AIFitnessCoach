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
import 'data/services/haptic_service.dart';
import 'data/services/image_url_cache.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling for simulators/missing config)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue without Firebase on simulator or if config is missing
  }

  // Initialize notification service
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ Notification service initialization failed: $e');
  }

  // Initialize SharedPreferences for notification prefs
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  // Initialize persistent image URL cache
  await ImageUrlCache.initialize();

  // Initialize haptic service with saved preference
  await HapticService.initialize();

  // Initialize RevenueCat for in-app purchases
  try {
    await SubscriptionNotifier.configureRevenueCat();
  } catch (e) {
    debugPrint('⚠️ RevenueCat initialization failed: $e');
  }

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ProviderScope(
      overrides: [
        // Provide SharedPreferences instance for accessibility and notification providers
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        notificationServiceProvider.overrideWithValue(notificationService),
        notificationPreferencesProvider.overrideWith(
          (ref) => NotificationPreferencesNotifier(sharedPreferences, notificationService),
        ),
      ],
      child: const AiFitnessCoachApp(),
    ),
  );
}
