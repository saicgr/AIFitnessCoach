# i18n Documentation Index

**Zealova ships in 36 languages.** This folder contains everything needed to understand, maintain, and replicate that.

---

## The 36 supported languages

| # | Code | Language | Native Script | Region |
|---|---|---|---|---|
| 1 | `en` | English | English | Source of truth |
| 2 | `ar` | Arabic | العربية | MENA (RTL) |
| 3 | `bn` | Bengali | বাংলা | South Asia |
| 4 | `cs` | Czech | Čeština | Europe |
| 5 | `de` | German | Deutsch | Europe |
| 6 | `es` | Spanish | Español | Latam + Iberia |
| 7 | `fi` | Finnish | Suomi | Europe |
| 8 | `fr` | French | Français | Europe + Africa |
| 9 | `ha` | Hausa | Hausa | West Africa |
| 10 | `hi` | Hindi | हिन्दी | India |
| 11 | `id` | Indonesian | Bahasa Indonesia | SE Asia |
| 12 | `it` | Italian | Italiano | Europe |
| 13 | `ja` | Japanese | 日本語 | East Asia |
| 14 | `jv` | Javanese | Basa Jawa | SE Asia |
| 15 | `kn` | Kannada | ಕನ್ನಡ | India |
| 16 | `ko` | Korean | 한국어 | East Asia |
| 17 | `ml` | Malayalam | മലയാളം | India |
| 18 | `mr` | Marathi | मराठी | India |
| 19 | `ms` | Malay | Bahasa Melayu | SE Asia |
| 20 | `ne` | Nepali | नेपाली | South Asia |
| 21 | `nl` | Dutch | Nederlands | Europe |
| 22 | `or` | Odia | ଓଡ଼ିଆ | India |
| 23 | `pa` | Punjabi | ਪੰਜਾਬੀ | South Asia |
| 24 | `pl` | Polish | Polski | Europe |
| 25 | `pt` | Portuguese | Português | Brazil + Iberia |
| 26 | `ru` | Russian | Русский | Europe + Central Asia |
| 27 | `sv` | Swedish | Svenska | Europe |
| 28 | `sw` | Swahili | Kiswahili | East Africa |
| 29 | `ta` | Tamil | தமிழ் | India + SE Asia |
| 30 | `te` | Telugu | తెలుగు | India |
| 31 | `th` | Thai | ไทย | SE Asia |
| 32 | `tl` | Tagalog | Tagalog | SE Asia (Filipino) |
| 33 | `tr` | Turkish | Türkçe | Europe + MENA |
| 34 | `ur` | Urdu | اردو | South Asia (RTL) |
| 35 | `vi` | Vietnamese | Tiếng Việt | SE Asia |
| 36 | `zh` | Simplified Chinese | 简体中文 | East Asia |

**RTL locales:** `ar`, `ur` (require directional layout audit — see ARCHITECTURE.md)

**Combined addressable population:** ~6 billion people.

---

## Documents in this folder

| File | Audience | What it covers |
|---|---|---|
| **[README.md](README.md)** | Everyone (you are here) | Index + 36-language reference |
| **[BUILD_FROM_SCRATCH.md](BUILD_FROM_SCRATCH.md)** | Developers starting a new app | Step-by-step guide to add 36-language support to any new Flutter + FastAPI app, from `flutter create` to shipping globally |
| **[ZEALOVA_ARCHITECTURE.md](ZEALOVA_ARCHITECTURE.md)** | Future Zealova contributors / Claude sessions | This specific repo's i18n architecture — 5 layers, common workflows, troubleshooting, AI Coach locale flow, file reference |
| **[TOOL_USAGE.md](TOOL_USAGE.md)** | Anyone using `scripts/i18n_add_feature.py` | Reusable CLI tool reference — 8 subcommands, examples, cost calculator, install guide for other repos |

---

## Quick reference — most common commands

```bash
# Add new ARB keys + translate to 35 locales
python3 scripts/i18n_add_feature.py keys --json /tmp/new_keys.json

# Scan a Flutter screen, extract English literals, migrate + translate
python3 scripts/i18n_add_feature.py screen --files mobile/flutter/lib/screens/new_feature/

# Add a backend notification template + translate
python3 scripts/i18n_add_feature.py notification --key foo_title --en "Hello!"

# Translate DB i18n rows for a table
python3 scripts/i18n_add_feature.py db --table exercise_library_i18n

# Quick one-off translation (no persistence)
python3 scripts/i18n_add_feature.py oneshot --text "Workout done" --locales hi,te

# Check coverage
python3 scripts/i18n_add_feature.py coverage

# Fix common issues
python3 scripts/i18n_add_feature.py sanitize-braces
python3 scripts/i18n_add_feature.py strip-stray-placeholders
```

---

## What's where in the codebase

### Flutter
- `mobile/flutter/lib/l10n/app_en.arb` — English source (12,295 keys)
- `mobile/flutter/lib/l10n/app_<locale>.arb` — 35 other locales (auto-translated)
- `mobile/flutter/lib/l10n/generated/` — auto-generated Dart by `flutter gen-l10n`
- `mobile/flutter/lib/data/providers/locale_provider.dart` — app UI locale state
- `mobile/flutter/lib/data/providers/chat_locale_provider.dart` — AI Coach locale (separate)
- `mobile/flutter/lib/data/services/api_client.dart` — Accept-Language + X-Chat-Locale headers
- `mobile/flutter/lib/data/services/chat_action_summary_builder.dart` — client-side tool action localization
- `mobile/flutter/ios/Runner/<locale>.lproj/Localizable.strings` — native iOS strings (36 files)
- `mobile/flutter/android/app/src/main/res/values-<locale>/strings.xml` — native Android (35 + default)

### Backend
- `backend/core/locale.py` — Accept-Language parser, persist_user_locale, overlay_*_i18n helpers
- `backend/core/i18n.py` — get_template + EN notification baseline
- `backend/core/i18n_translations.py` — non-en notification translations (auto-generated)
- `backend/services/gemini/chat.py` — `_build_locale_prefix` for Gemini system prompt injection
- `backend/services/langgraph_agents/*/nodes.py` — locale-aware system prompts
- `backend/api/v1/chat.py` — extracts both X-Chat-Locale + Accept-Language
- `backend/api/v1/push_nudge_cron.py` — uses get_template() with user's preferred_locale

### Database (Supabase Postgres)
- `users.preferred_locale` — app UI language (migration 2103)
- `users.chat_locale` — AI Coach language, separate (migration 2106)
- `exercise_library_i18n` (migration 2104) — 2,439 × 36 rows
- `equipment_types_i18n` (migration 2104) — 51 × 36 rows
- `muscle_group_i18n` (migration 2104) — 204 × 36 rows
- `movement_pattern_i18n` (migration 2104) — 9 × 36 rows
- `set_type_i18n` (migration 2104) — 5 × 36 rows
- `food_nutrition_overrides_i18n` (migration 2105) — 1,000 × 36 rows
- `recipes_i18n` (migration 2105) — 13 × 36 rows

### Scripts
- `scripts/i18n_add_feature.py` — **main reusable CLI** (use this for everything)
- `scripts/i18n_translate_gemini.py` — lower-level batched translator (used internally)
- `scripts/i18n_translate_backend_notifications.py` — backend notification template translator
- `scripts/i18n_coverage_check.py` — strict pass/fail coverage gate (CI use)
- `scripts/i18n_migrate_screen.py` — Dart lexer for extracting English literals
- `scripts/i18n_migrate_all.py` — orchestrator across all screens
- `scripts/i18n_rtl_audit.py` — RTL layout audit (Alignment.left → AlignmentDirectional.start)
- `scripts/i18n_fix_const_wraps.py` — strip `const` from constructors using AppLocalizations
- `backend/scripts/seed_exercise_library_i18n_en.py` — one-time English baseline seed
- `backend/scripts/seed_food_i18n_en.py` — one-time English food baseline seed
- `backend/scripts/translate_exercise_library_i18n.py` — DB exercise i18n filler
- `backend/scripts/translate_food_i18n.py` — DB food + recipes i18n filler

---

## How to add a 37th language

The pipeline doesn't bake in 36 as a constant — it's just a list. To add (e.g. Hebrew `he`):

1. Edit `LOCALES_NON_EN` in `scripts/i18n_add_feature.py` to append `"he"`.
2. Edit `LOCALE_NATIVE` in same file: `"he": "Hebrew (עברית)"`.
3. Create empty `lib/l10n/app_he.arb`: `{"@@locale": "he"}`.
4. Run `python3 scripts/i18n_add_feature.py keys --json <a json of any existing key>` — script will backfill the new locale across all keys.
5. (Backend) Add `"he"` to `SUPPORTED_LOCALES` in `backend/core/locale.py`.
6. (iOS) `mkdir ios/Runner/he.lproj && cp ios/Runner/en.lproj/Localizable.strings ios/Runner/he.lproj/`
7. (Android) `mkdir android/app/src/main/res/values-he && cp android/app/src/main/res/values/strings.xml android/app/src/main/res/values-he/`
8. (Hebrew is RTL) Run `scripts/i18n_rtl_audit.py` and apply directional fixes.

Cost to add 1 language: ~$0.05 (12K strings × 1 locale via Gemini Flash Lite).

---

## Production stats

- **36 languages** supported (English + 35)
- **12,295 ARB keys** translated
- **97.0% average REAL coverage** (translatable strings, excluding placeholders/brands/acronyms)
- **44 backend notification templates** × 36 locales
- **3,721 DB i18n rows** seeded with English baseline (translation in progress for non-en)
- **5 layers**: Flutter ARB / Backend templates / DB rows / AI Coach Gemini / Native platform strings
- **AI Coach** responds in user's language via Gemini system prompt injection
- **Independent AI Coach language picker** (separate from app UI)
- **Cost**: ~$2 one-time for full app translation, ~$0.001 per new feature
- **Build time**: 3 minutes for the full 35-locale translation pass

---

## Need help?

If you're a developer (or AI coding assistant) approaching this for the first time:

- **Starting a new app?** → Read `BUILD_FROM_SCRATCH.md` end-to-end.
- **Working in this Zealova repo?** → Read `ZEALOVA_ARCHITECTURE.md`.
- **Just want to use the script?** → Read `TOOL_USAGE.md`.
- **Got a translation bug?** → Read the Troubleshooting section in `ZEALOVA_ARCHITECTURE.md`.
- **Got an analyzer error after running translation?** → Run `python3 scripts/i18n_add_feature.py sanitize-braces` and `python3 scripts/i18n_add_feature.py strip-stray-placeholders`, then `flutter gen-l10n`.
