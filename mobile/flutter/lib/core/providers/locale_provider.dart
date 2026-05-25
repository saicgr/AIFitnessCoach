import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 5 — app locale state.
///
/// Persists the user's chosen locale to SharedPreferences so the choice
/// survives app restarts. Null = "follow system" (MaterialApp.locale = null
/// → uses `Localizations.localeOf` system fallback).
///
/// **Supported set (36 locales):** Gravl-parity 8 (en, es, de, fr, it, pt,
/// cs, pl) + 28 added 2026-05-24 covering Indian (hi, mr, ne, bn, ta, te,
/// kn, ml, pa, or), CJK (zh, ja, ko), RTL (ar, ur), Southeast Asian (vi,
/// id, jv, th, ms, tl), European (ru, sv, nl, fi, tr), African (sw, ha).
///
/// **RTL handling:** Arabic (`ar`) and Urdu (`ur`) are right-to-left. Flutter
/// switches `Directionality` automatically once a locale is listed here, but
/// the app contains hardcoded `Alignment.left`/`EdgeInsets.only(left:)` that
/// should be migrated to `start`/`end` equivalents in a follow-up RTL audit.
class LocaleState {
  const LocaleState({this.locale});
  final Locale? locale;
}

const supportedAppLocales = <Locale>[
  // Phase 5 — Gravl-parity set
  Locale('en'),
  Locale('es'),
  Locale('de'),
  Locale('fr'),
  Locale('it'),
  Locale('pt'),
  Locale('cs'),
  Locale('pl'),
  // 2026-05-24 — global expansion
  Locale('hi'),  // Hindi
  Locale('te'),  // Telugu
  Locale('ta'),  // Tamil
  Locale('ja'),  // Japanese
  Locale('ko'),  // Korean
  Locale('kn'),  // Kannada
  Locale('ar'),  // Arabic — RTL
  Locale('mr'),  // Marathi
  Locale('bn'),  // Bengali
  Locale('pa'),  // Punjabi (Gurmukhi)
  Locale('tr'),  // Turkish
  Locale('vi'),  // Vietnamese
  Locale('ur'),  // Urdu — RTL
  Locale('id'),  // Indonesian
  Locale('jv'),  // Javanese
  Locale('ml'),  // Malayalam
  Locale('or'),  // Odia
  Locale('th'),  // Thai
  Locale('ms'),  // Malay
  Locale('tl'),  // Tagalog / Filipino
  Locale('ne'),  // Nepali
  Locale('sv'),  // Swedish
  Locale('nl'),  // Dutch
  Locale('fi'),  // Finnish
  Locale('sw'),  // Swahili
  Locale('ha'),  // Hausa
  Locale('zh'),  // Chinese (Simplified default)
  Locale('ru'),  // Russian
];

/// RTL languages — surfaced as a helper for any widget that wants to gate
/// layout/animation against direction without re-checking `Directionality`.
const rtlAppLanguageCodes = <String>{'ar', 'ur'};

bool isRtlLanguageCode(String code) => rtlAppLanguageCodes.contains(code);

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(const LocaleState()) {
    _load();
  }

  static const _prefKey = 'app_locale_code';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && code.isNotEmpty) {
      state = LocaleState(locale: Locale(code));
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = LocaleState(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(),
);
