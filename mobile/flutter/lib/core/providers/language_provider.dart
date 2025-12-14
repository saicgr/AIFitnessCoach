import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported language model
class Language {
  final String code;
  final String name;
  final String nativeName;
  final bool isComingSoon;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isComingSoon = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Available languages
class SupportedLanguages {
  static const english = Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
  );

  static const telugu = Language(
    code: 'te',
    name: 'Telugu',
    nativeName: 'తెలుగు',
    isComingSoon: true,
  );

  static const List<Language> all = [english, telugu];

  static Language fromCode(String code) {
    return all.firstWhere(
      (lang) => lang.code == code,
      orElse: () => english,
    );
  }
}

/// Language state
class LanguageState {
  final Language? selectedLanguage;
  final bool hasSelectedLanguage;
  final bool isLoading;

  const LanguageState({
    this.selectedLanguage,
    this.hasSelectedLanguage = false,
    this.isLoading = true,
  });

  LanguageState copyWith({
    Language? selectedLanguage,
    bool? hasSelectedLanguage,
    bool? isLoading,
  }) {
    return LanguageState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

/// Language notifier
class LanguageNotifier extends StateNotifier<LanguageState> {
  static const _languageKey = 'selected_language';
  static const _hasSelectedKey = 'has_selected_language';

  LanguageNotifier() : super(const LanguageState()) {
    _loadLanguage();
  }

  /// Load saved language preference
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSelected = prefs.getBool(_hasSelectedKey) ?? false;
      final languageCode = prefs.getString(_languageKey);

      if (hasSelected && languageCode != null) {
        state = LanguageState(
          selectedLanguage: SupportedLanguages.fromCode(languageCode),
          hasSelectedLanguage: true,
          isLoading: false,
        );
      } else {
        state = const LanguageState(
          selectedLanguage: null,
          hasSelectedLanguage: false,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
      state = const LanguageState(
        selectedLanguage: null,
        hasSelectedLanguage: false,
        isLoading: false,
      );
    }
  }

  /// Set language and save to preferences
  Future<void> setLanguage(Language language) async {
    state = state.copyWith(
      selectedLanguage: language,
      hasSelectedLanguage: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
      await prefs.setBool(_hasSelectedKey, true);
      debugPrint('✅ [Language] Saved language: ${language.code}');
    } catch (e) {
      debugPrint('❌ [Language] Error saving language: $e');
    }
  }

  /// Check if language has been selected (for router redirect)
  bool get hasSelectedLanguage => state.hasSelectedLanguage;

  /// Get current language code
  String get currentLanguageCode => state.selectedLanguage?.code ?? 'en';
}
