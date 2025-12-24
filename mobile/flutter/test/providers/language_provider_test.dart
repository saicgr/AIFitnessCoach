import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_fitness_coach/core/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language', () {
    test('should create Language with required fields', () {
      const language = Language(
        code: 'en',
        name: 'English',
        nativeName: 'English',
      );

      expect(language.code, 'en');
      expect(language.name, 'English');
      expect(language.nativeName, 'English');
      expect(language.isComingSoon, false);
    });

    test('should support isComingSoon flag', () {
      const language = Language(
        code: 'fr',
        name: 'French',
        nativeName: 'Francais',
        isComingSoon: true,
      );

      expect(language.isComingSoon, true);
    });

    test('should be equal when codes match', () {
      const lang1 = Language(code: 'en', name: 'English', nativeName: 'English');
      const lang2 = Language(code: 'en', name: 'English', nativeName: 'English');
      const lang3 = Language(code: 'fr', name: 'French', nativeName: 'Francais');

      expect(lang1, equals(lang2));
      expect(lang1, isNot(equals(lang3)));
    });

    test('should have correct hashCode based on code', () {
      const lang1 = Language(code: 'en', name: 'English', nativeName: 'English');
      const lang2 = Language(code: 'en', name: 'English', nativeName: 'English');

      expect(lang1.hashCode, equals(lang2.hashCode));
    });
  });

  group('SupportedLanguages', () {
    test('should have English language', () {
      expect(SupportedLanguages.english.code, 'en');
      expect(SupportedLanguages.english.name, 'English');
      expect(SupportedLanguages.english.nativeName, 'English');
      expect(SupportedLanguages.english.isComingSoon, false);
    });

    test('should have Telugu language as coming soon', () {
      expect(SupportedLanguages.telugu.code, 'te');
      expect(SupportedLanguages.telugu.name, 'Telugu');
      expect(SupportedLanguages.telugu.isComingSoon, true);
    });

    test('should have all languages list', () {
      expect(SupportedLanguages.all.length, 2);
      expect(SupportedLanguages.all, contains(SupportedLanguages.english));
      expect(SupportedLanguages.all, contains(SupportedLanguages.telugu));
    });

    group('fromCode', () {
      test('should return English for "en"', () {
        final language = SupportedLanguages.fromCode('en');
        expect(language, SupportedLanguages.english);
      });

      test('should return Telugu for "te"', () {
        final language = SupportedLanguages.fromCode('te');
        expect(language, SupportedLanguages.telugu);
      });

      test('should return English for unknown code', () {
        final language = SupportedLanguages.fromCode('unknown');
        expect(language, SupportedLanguages.english);
      });

      test('should return English for empty code', () {
        final language = SupportedLanguages.fromCode('');
        expect(language, SupportedLanguages.english);
      });
    });
  });

  group('LanguageState', () {
    test('should have default values', () {
      const state = LanguageState();

      expect(state.selectedLanguage, isNull);
      expect(state.hasSelectedLanguage, false);
      expect(state.isLoading, true);
    });

    test('should create with custom values', () {
      const state = LanguageState(
        selectedLanguage: SupportedLanguages.english,
        hasSelectedLanguage: true,
        isLoading: false,
      );

      expect(state.selectedLanguage, SupportedLanguages.english);
      expect(state.hasSelectedLanguage, true);
      expect(state.isLoading, false);
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = LanguageState();
        final copied = original.copyWith(
          selectedLanguage: SupportedLanguages.english,
          hasSelectedLanguage: true,
          isLoading: false,
        );

        expect(copied.selectedLanguage, SupportedLanguages.english);
        expect(copied.hasSelectedLanguage, true);
        expect(copied.isLoading, false);
      });

      test('should preserve values when not specified', () {
        const original = LanguageState(
          selectedLanguage: SupportedLanguages.english,
          hasSelectedLanguage: true,
          isLoading: false,
        );
        final copied = original.copyWith();

        expect(copied.selectedLanguage, SupportedLanguages.english);
        expect(copied.hasSelectedLanguage, true);
        expect(copied.isLoading, false);
      });

      test('should update only specified values', () {
        const original = LanguageState(
          selectedLanguage: SupportedLanguages.english,
          hasSelectedLanguage: true,
          isLoading: false,
        );
        final copied = original.copyWith(isLoading: true);

        expect(copied.selectedLanguage, SupportedLanguages.english);
        expect(copied.hasSelectedLanguage, true);
        expect(copied.isLoading, true);
      });
    });
  });

  group('LanguageNotifier', () {
    late LanguageNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notifier = LanguageNotifier();
    });

    test('should initialize with loading state', () {
      expect(notifier.state.isLoading, true);
    });

    group('setLanguage', () {
      test('should set selected language', () async {
        await notifier.setLanguage(SupportedLanguages.english);

        expect(notifier.state.selectedLanguage, SupportedLanguages.english);
        expect(notifier.state.hasSelectedLanguage, true);
      });

      test('should persist language to SharedPreferences', () async {
        await notifier.setLanguage(SupportedLanguages.english);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_language'), 'en');
        expect(prefs.getBool('has_selected_language'), true);
      });
    });

    group('hasSelectedLanguage', () {
      test('should return false initially', () {
        expect(notifier.hasSelectedLanguage, false);
      });

      test('should return true after setting language', () async {
        await notifier.setLanguage(SupportedLanguages.english);
        expect(notifier.hasSelectedLanguage, true);
      });
    });

    group('currentLanguageCode', () {
      test('should return "en" by default', () {
        expect(notifier.currentLanguageCode, 'en');
      });

      test('should return selected language code', () async {
        await notifier.setLanguage(SupportedLanguages.telugu);
        expect(notifier.currentLanguageCode, 'te');
      });
    });

    group('persistence', () {
      test('should load saved language from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'selected_language': 'en',
          'has_selected_language': true,
        });

        final loadedNotifier = LanguageNotifier();

        // Wait for async _loadLanguage to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state.selectedLanguage, SupportedLanguages.english);
        expect(loadedNotifier.state.hasSelectedLanguage, true);
        expect(loadedNotifier.state.isLoading, false);
      });

      test('should handle no saved preference', () async {
        SharedPreferences.setMockInitialValues({});

        final loadedNotifier = LanguageNotifier();

        // Wait for async _loadLanguage to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state.selectedLanguage, isNull);
        expect(loadedNotifier.state.hasSelectedLanguage, false);
        expect(loadedNotifier.state.isLoading, false);
      });

      test('should handle partial saved preference', () async {
        // Only language code saved, but not has_selected flag
        SharedPreferences.setMockInitialValues({
          'selected_language': 'en',
        });

        final loadedNotifier = LanguageNotifier();

        // Wait for async _loadLanguage to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state.selectedLanguage, isNull);
        expect(loadedNotifier.state.hasSelectedLanguage, false);
      });
    });
  });

  group('languageProvider', () {
    test('should provide LanguageState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(languageProvider);
      expect(state, isA<LanguageState>());
    });

    test('should allow setting language via notifier', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(languageProvider.notifier);
      await notifier.setLanguage(SupportedLanguages.english);

      expect(container.read(languageProvider).selectedLanguage, SupportedLanguages.english);
      expect(container.read(languageProvider).hasSelectedLanguage, true);
    });
  });
}
