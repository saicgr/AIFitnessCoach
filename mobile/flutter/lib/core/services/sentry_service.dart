import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/environment_config.dart';

/// Sentry error tracking — modular wrapper for the Flutter app.
///
/// Runs alongside Firebase Crashlytics + PostHog. Silent no-op when
/// `SENTRY_DSN` is unset. Never blocks app launch on failure.
class SentryService {
  SentryService._();

  static bool _enabled = false;
  static bool get isEnabled => _enabled;

  /// Initialize Sentry. Wrap [appRunner] so Sentry can attach zone-level error
  /// handling. If no DSN is configured, [appRunner] is invoked directly and
  /// the method returns without initializing anything.
  static Future<void> init({
    required Future<void> Function() appRunner,
    String? release,
  }) async {
    final dsn = EnvironmentConfig.sentryDsn;
    if (dsn.isEmpty) {
      debugPrint('ℹ️ [Sentry] DSN not set — error tracking disabled.');
      await appRunner();
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment =
              EnvironmentConfig.isDev ? 'development' : 'production';
          if (release != null && release.isNotEmpty) {
            options.release = 'fitwiz-flutter@$release';
          }

          // Performance: modest sample rate keeps cost in check while giving
          // enough spans to spot slow API calls / screen transitions.
          options.tracesSampleRate = EnvironmentConfig.isDev ? 1.0 : 0.2;
          options.profilesSampleRate = EnvironmentConfig.isDev ? 1.0 : 0.1;

          // UI diagnostics — without these, a RenderFlex overflow arrives in
          // Sentry as a terse exception with no screen context. Attaching
          // screenshot + view hierarchy is what makes frontend triage fast.
          options.attachScreenshot = true;
          options.attachViewHierarchy = true;

          // Attach a stack trace to EVERY event, including plain
          // `captureMessage` calls and FlutterError reports that arrive
          // without one. Without this, RenderFlex overflows show up in
          // Sentry as a one-line message with no widget frames, which is
          // useless for triage. Cost: a few hundred bytes per event.
          options.attachStacktrace = true;
          // Don't fold framework frames so the actual user widget that
          // owns the overflowing Column/Row is visible, not just
          // `RenderFlex.performLayout`.
          options.considerInAppFramesByDefault = true;

          // Privacy: redact text inputs and images so screenshots/hierarchies
          // don't leak PII (food names the user is typing, coach chat, etc.).
          // Sentry 8.x still exposes this under `experimental` until 9.x.
          options.experimental.privacy.maskAllText = true;
          options.experimental.privacy.maskAllImages = true;

          options.sendDefaultPii = false;
          options.enableAutoSessionTracking = true;

          // Rich breadcrumbs: touch events + native (iOS/Android) events so
          // we can reconstruct what the user did before the error.
          options.enableUserInteractionBreadcrumbs = true;
          options.enableUserInteractionTracing = true;
          options.enableAutoNativeBreadcrumbs = true;
          options.enableAppLifecycleBreadcrumbs = true;
          options.enableWindowMetricBreadcrumbs = true;
          options.enableBrightnessChangeBreadcrumbs = true;
          options.enableTextScaleChangeBreadcrumbs = true;
          options.maxBreadcrumbs = 150;

          // App-not-responding detection — iOS and Android both supported.
          options.enableAppHangTracking = true;

          // Dedupe: PostHog / Crashlytics already capture some noise. We keep
          // RenderFlex overflows (we explicitly WANT to see layout bugs) but
          // drop a few truly redundant framework messages.
          options.beforeSend = (event, hint) {
            final msg = event.message?.formatted ?? '';
            if (msg.contains('Failed to interpolate TextStyles')) {
              return null;
            }
            return event;
          };

        },
        appRunner: () async {
          // Platform/build tags are easier to set as scope tags than via
          // options.beforeSend, and they're available for every future event.
          await Sentry.configureScope((scope) {
            scope.setTag('platform', _platformTag());
            scope.setTag('env',
                EnvironmentConfig.isDev ? 'development' : 'production');
            if (release != null && release.isNotEmpty) {
              scope.setTag('app_version', release);
            }
            scope.setTag('debug_mode', kDebugMode ? 'true' : 'false');
          });
          await appRunner();
        },
      );
      _enabled = true;
      debugPrint('✅ [Sentry] initialized (env=${EnvironmentConfig.isDev ? "dev" : "prod"}, screenshot=on).');
    } catch (e) {
      // Never block app startup on Sentry init failure.
      debugPrint('⚠️ [Sentry] init failed (non-fatal): $e');
      await appRunner();
    }
  }

  /// Attach user context to subsequent events. Call on sign-in.
  static Future<void> setUser({required String id, String? email}) async {
    if (!_enabled) return;
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, email: email));
    });
  }

  /// Clear user context. Call on sign-out.
  static Future<void> clearUser() async {
    if (!_enabled) return;
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Manually capture an error with optional context.
  static Future<void> captureError(
    Object error,
    StackTrace? stack, {
    String? hint,
    Map<String, dynamic>? extra,
    Map<String, String>? tags,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_enabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stack,
      hint: hint != null ? Hint.withMap({'context': hint}) : null,
      withScope: (scope) {
        scope.level = level;
        if (extra != null) scope.setContexts('extra', extra);
        if (tags != null) {
          tags.forEach(scope.setTag);
        }
      },
    );
  }

  /// Capture a plain message (non-exception) with optional level + tags.
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
    Map<String, String>? tags,
  }) async {
    if (!_enabled) return;
    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) scope.setContexts('extra', extra);
        if (tags != null) {
          tags.forEach(scope.setTag);
        }
      },
    );
  }

  /// Drop a breadcrumb — typed ("ui", "nav", "api", "workout", etc.) so
  /// filtering in the Sentry UI is easier.
  static void addBreadcrumb({
    required String message,
    String category = 'app',
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Set a tag on the current scope. Useful for per-screen context (e.g.
  /// workout_tier=simple, onboarding_step=3).
  static Future<void> setTag(String key, String value) async {
    if (!_enabled) return;
    await Sentry.configureScope((scope) => scope.setTag(key, value));
  }

  /// Remove a previously-set tag.
  static Future<void> removeTag(String key) async {
    if (!_enabled) return;
    await Sentry.configureScope((scope) => scope.removeTag(key));
  }

  /// Attach to Dio so HTTP calls appear as breadcrumbs + performance spans.
  static void attachToDio(Dio dio) {
    if (!_enabled) return;
    dio.addSentry(
      captureFailedRequests: false, // 4xx/5xx already handled elsewhere
    );
  }

  /// A NavigatorObserver you can add to your router for nav breadcrumbs.
  static SentryNavigatorObserver navigatorObserver() =>
      SentryNavigatorObserver();

  static String _platformTag() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }
}
