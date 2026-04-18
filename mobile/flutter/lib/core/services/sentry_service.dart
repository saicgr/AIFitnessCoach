import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/environment_config.dart';

/// Sentry error tracking — modular wrapper for the Flutter app.
///
/// Runs alongside Firebase Crashlytics + PostHog (both untouched). Silent
/// no-op when `SENTRY_DSN` is unset. Never blocks app launch on failure.
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
          // Keep payloads small; Firebase Crashlytics is the heavy-duty store.
          options.tracesSampleRate = 0.1;
          options.attachScreenshot = false;
          options.attachViewHierarchy = false;
          options.sendDefaultPii = false;
          options.enableAutoSessionTracking = true;
          // Dedupe noisy framework warnings already caught by Crashlytics.
          options.beforeSend = (event, hint) {
            final msg = event.message?.formatted ?? '';
            if (msg.contains('RenderFlex overflowed') ||
                msg.contains('Failed to interpolate TextStyles')) {
              return null;
            }
            return event;
          };
        },
        appRunner: appRunner,
      );
      _enabled = true;
      debugPrint('✅ [Sentry] initialized.');
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
      scope.setUser(
        SentryUser(id: id, email: email),
      );
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
  }) async {
    if (!_enabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stack,
      hint: hint != null ? Hint.withMap({'context': hint}) : null,
      withScope: extra == null
          ? null
          : (scope) {
              scope.setContexts('extra', extra);
            },
    );
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
}
