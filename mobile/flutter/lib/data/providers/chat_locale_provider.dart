import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ChatLocaleNotifier() : super(const ChatLocaleState()) {
    _load();
  }

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
  }

  /// Alias for setLocale(null) — clears the chat-language override.
  Future<void> clear() => setLocale(null);
}

final chatLocaleProvider =
    StateNotifierProvider<ChatLocaleNotifier, ChatLocaleState>(
  (ref) => ChatLocaleNotifier(),
);
