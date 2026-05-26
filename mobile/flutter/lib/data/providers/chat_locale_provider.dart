import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// AI Coach chat language state.
///
/// Separate from [localeProvider] (app UI language). Null = follow the app UI
/// language (the backend treats an absent X-Chat-Locale header as "use
/// preferred_locale"). Non-null = the user wants the AI to reply in a
/// different language.
///
/// Persists to SharedPreferences key [ChatLocaleNotifier.prefKey] across
/// restarts. The provider is watched by [chatLocaleSyncProvider] which keeps
/// the [ApiClient] X-Chat-Locale header in sync.
class ChatLocaleState {
  const ChatLocaleState({this.locale});

  /// Null = "Same as app language" (no X-Chat-Locale header sent).
  final Locale? locale;
}

class ChatLocaleNotifier extends StateNotifier<ChatLocaleState> {
  ChatLocaleNotifier(this._ref) : super(const ChatLocaleState()) {
    _load();
  }

  final Ref _ref;

  /// SharedPreferences key — separate namespace from the UI locale key.
  static const prefKey = 'chat_locale_code';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(prefKey);
    if (code != null && code.isNotEmpty) {
      state = ChatLocaleState(locale: Locale(code));
    }
    // Null (no stored key) → state stays ChatLocaleState(locale: null).
  }

  /// Set a specific locale for AI Coach replies.
  /// Pass null to reset to "Same as app language".
  Future<void> setLocale(Locale? locale) async {
    state = ChatLocaleState(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(prefKey);
    } else {
      await prefs.setString(prefKey, locale.languageCode);
    }
    // Persist to the backend immediately so the coach picks up the new
    // override on the NEXT message instead of waiting for the chat
    // endpoint to lazily back-propagate the X-Chat-Locale header.
    try {
      final api = _ref.read(apiClientProvider);
      await api.dio.patch(
        '/api/v1/users/me',
        // null clears the override server-side; explicit null is honoured.
        data: {'chat_locale': locale?.languageCode},
      );
      debugPrint(
          '🌐 [ChatLocale] Persisted chat_locale=${locale?.languageCode} to backend');
    } catch (e) {
      debugPrint(
          '⚠️ [ChatLocale] backend persist failed (will retry via header): $e');
    }
  }

  /// Alias for setLocale(null) — clears the chat-language override.
  Future<void> clear() => setLocale(null);
}

final chatLocaleProvider =
    StateNotifierProvider<ChatLocaleNotifier, ChatLocaleState>(
  (ref) => ChatLocaleNotifier(ref),
);
