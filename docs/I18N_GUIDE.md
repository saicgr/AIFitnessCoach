# Zealova i18n Guide

**For developers (and Claude sessions) shipping new features that need to work in 36 languages.**

Last updated: 2026-05-25

---

## TL;DR — Cheat sheet

| Scenario | Command |
|---|---|
| Added new strings in Flutter source | `python3 scripts/i18n_add_feature.py screen --files mobile/flutter/lib/screens/new_screen/` |
| Have explicit `{key: en_value}` dict | `python3 scripts/i18n_add_feature.py keys --json /tmp/new_keys.json` |
| Added backend notification template | `python3 scripts/i18n_add_feature.py notification --key invite_title --en "You're invited"` |
| Added new DB rows (exercise/food) | `python3 scripts/i18n_add_feature.py db --table exercise_library_i18n` |
| Just need a quick translation | `python3 scripts/i18n_add_feature.py oneshot --text "Workout done" --locales hi,te` |
| Check coverage | `python3 scripts/i18n_add_feature.py coverage` |
| Something broke gen-l10n | `python3 scripts/i18n_add_feature.py sanitize-braces && python3 scripts/i18n_add_feature.py strip-stray-placeholders` |

**ALL translation uses `gemini-3.1-flash-lite`. ~$0.01-0.50 per feature. Resume-safe.**

---

## 1. System Architecture

Zealova's i18n spans **5 layers**. Each layer has its own storage + translation pipeline.

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Flutter ARB (UI chrome — buttons, labels, errors)      │
│ Storage: mobile/flutter/lib/l10n/app_<locale>.arb  (36 files)   │
│ Translated: 36 locales, ~12,300 keys                            │
│ Codegen: flutter gen-l10n → lib/l10n/generated/                 │
│ Used by: AppLocalizations.of(context).keyName                   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│ Layer 2: Backend notification templates                          │
│ Storage: backend/core/i18n.py (en) + i18n_translations.py (35)  │
│ Used by: get_template(locale, key, **vars)                       │
│ Translated: 44 templates × 36 locales                            │
│ Used in: push_nudge_cron.py (HRV/streak/Wrapped/etc.)            │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│ Layer 3: DB-stored content i18n                                  │
│ Storage: Supabase tables                                         │
│   - exercise_library_i18n     (2,439 × 36)                       │
│   - equipment_types_i18n      (51 × 36)                          │
│   - muscle_group_i18n         (204 × 36)                         │
│   - movement_pattern_i18n     (9 × 36)                           │
│   - set_type_i18n             (5 × 36)                           │
│   - food_nutrition_overrides_i18n  (1000 × 36)                   │
│   - recipes_i18n              (13 × 36)                          │
│ Used by: backend/core/locale.py → overlay_*_i18n helpers         │
│ Endpoints JOIN with current locale, COALESCE to 'en'             │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│ Layer 4: AI Coach (Gemini-generated reply text)                  │
│ Wired in: backend/services/gemini/chat.py (ChatMixin)            │
│ Mechanism: locale prefix injected into system prompt:            │
│   "ALWAYS respond in हिन्दी, regardless of which language..."     │
│ Locale sources:                                                  │
│   - X-Chat-Locale header (separate AI Coach language preference) │
│   - falls through to Accept-Language (app UI locale)             │
│   - falls through to users.chat_locale → preferred_locale → en   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│ Layer 5: Native platform strings                                 │
│ iOS:     ios/Runner/<locale>.lproj/Localizable.strings (36)      │
│ Android: android/app/src/main/res/values-<locale>/strings.xml    │
│ Used by: widgets, live activities, app display name              │
│ Translation: rare — mostly widget labels (~10 keys per platform) │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. The 36 supported locales

| Code | Language | Code | Language | Code | Language |
|---|---|---|---|---|---|
| en | English | hi | Hindi | pt | Portuguese |
| ar | Arabic | id | Indonesian | ru | Russian |
| bn | Bengali | it | Italian | sv | Swedish |
| cs | Czech | ja | Japanese | sw | Swahili |
| de | German | jv | Javanese | ta | Tamil |
| es | Spanish | kn | Kannada | te | Telugu |
| fi | Finnish | ko | Korean | th | Thai |
| fr | French | ml | Malayalam | tl | Tagalog |
| ha | Hausa | mr | Marathi | tr | Turkish |
| - | - | ms | Malay | ur | Urdu |
| - | - | ne | Nepali | vi | Vietnamese |
| - | - | nl | Dutch | zh | Simplified Chinese |
| - | - | or | Odia | - | - |
| - | - | pa | Punjabi | - | - |
| - | - | pl | Polish | - | - |

**English is the source of truth.** Every other locale is filled from English. When you add a new key/string/row, only the English value is required; the rest is filled by Gemini Flash Lite.

---

## 3. Common workflows

### 3a. "I added some hardcoded English strings to a Flutter screen"

```bash
# 1. The migration tool scans for `Text('foo')`, `hint: 'bar'`, etc.
python3 scripts/i18n_add_feature.py screen --files mobile/flutter/lib/screens/new_feature/

# That single command:
#  - Scans your files for English literals
#  - Mints camelCase keys (e.g. newFeatureTitle, newFeatureSubtitle)
#  - Replaces literals with AppLocalizations.of(context).xxx
#  - Adds keys to app_en.arb
#  - Mirrors English to all 35 non-en .arb files
#  - Translates non-en cells via Gemini Flash Lite
#  - Runs flutter gen-l10n
```

After running:
```bash
cd mobile/flutter && flutter analyze lib/  # should still show 3 pre-existing errors
```

### 3b. "I have a `{key: english}` dict I want to add"

Write the JSON:
```bash
cat > /tmp/new_keys.json << 'EOF'
{
  "newFeatureTitle": "New Awesome Feature",
  "newFeatureSubtitle": "Track your progress, level up.",
  "newFeatureCtaLogIn": "Sign in to continue",
  "@newFeatureXpGained": {"placeholders": {"xp": {"type": "Object"}}},
  "newFeatureXpGained": "You gained {xp} XP!"
}
EOF
python3 scripts/i18n_add_feature.py keys --json /tmp/new_keys.json
```

The script:
- Validates each key is a valid Dart identifier (lowerCamelCase, no leading digit/underscore)
- Adds keys to `app_en.arb` (only ones not already present)
- Mirrors English to all 35 non-en `.arb` files
- Translates non-en cells via Gemini Flash Lite (resume-safe — only translates cells where value == English)
- Runs `flutter gen-l10n`

### 3c. "I added a backend cron-fired notification"

```bash
python3 scripts/i18n_add_feature.py notification \
    --key challenge_invite_title \
    --en "Your friend invited you to a challenge!"

python3 scripts/i18n_add_feature.py notification \
    --key challenge_invite_body \
    --en "{friend_name} challenges you to {challenge_name}. Accept?"
```

The script:
- Appends to `_EN_TEMPLATES` in `backend/core/i18n.py`
- Translates to all 35 non-en locales via Gemini
- Patches `backend/core/i18n_translations.py` with the new translations
- The cron jobs immediately pick up the localized version via `get_template(locale, key, **vars)`

Then **use it** in your cron handler:
```python
from core.i18n import get_template
title = get_template(user_locale, "challenge_invite_title")
body = get_template(user_locale, "challenge_invite_body",
                    friend_name="Alex", challenge_name="100-day plank")
```

### 3d. "I bulk-inserted new exercises (or foods) and need them translated"

```bash
# Fill non-en rows in exercise_library_i18n for the newly-added en rows
python3 scripts/i18n_add_feature.py db --table exercise_library_i18n

# Or for foods:
python3 scripts/i18n_add_feature.py db --table food_nutrition_overrides_i18n
```

This delegates to `backend/scripts/translate_exercise_library_i18n.py` or
`backend/scripts/translate_food_i18n.py` (already exists). Both are resume-safe
via `ON CONFLICT (id, locale) DO NOTHING`.

### 3e. "I just need a quick translation, no persistence"

```bash
python3 scripts/i18n_add_feature.py oneshot --text "Workout complete" \
    --locales hi,te,ta,ar,zh

# Output:
#   [hi] व्यायाम पूर्ण
#   [te] వ్యాయామం పూర్తయింది
#   [ta] உடற்பயிற்சி முடிந்தது
#   [ar] اكتمل التمرين
#   [zh] 锻炼完成
```

Useful for: debugging, designing copy, prototyping. Doesn't touch any file.

---

## 4. Quality + cost guarantees

### What's preserved verbatim in every translation
- **ICU placeholders**: `{name}`, `{count}`, `{xp}` — stay exactly the same
- **Brand names**: `Zealova`, `Strava`, `Fitbod`, `MyFitnessPal`, `Hyrox`, `RevenueCat`, `MacroFactor`, `Hevy`, `Jefit`, `Peloton`, `Garmin`, `FitNotes`, `StrongLifts`
- **Fitness acronyms**: `RPE`, `1RM`, `AMRAP`, `EMOM`, `BMR`, `TDEE`, `HRV`, `NEAT`, `ATG`, `RIR`, `TUT`

### Pricing (Gemini 3.1 Flash Lite, as of 2026-05)
| Input | Output |
|---|---|
| $0.10 / 1M tokens | $0.40 / 1M tokens |

### Cost per typical action
| Action | Cost |
|---|---|
| Single ARB key × 35 locales | ~$0.0001 |
| 20 ARB keys × 35 locales | ~$0.002 |
| Backend notification × 35 locales | ~$0.0001 |
| 100 DB exercise rows × 35 locales | ~$0.01 |
| 1000 DB food rows × 35 locales | ~$0.10 |
| **Full app re-translation** (12K keys × 35) | ~$1-2 |

---

## 5. Verifying coverage

```bash
python3 scripts/i18n_add_feature.py coverage
```

Output:
```
loc  | raw % | REAL %
-------------------------
  ar | 96.1% | 99.0%
  ...
Avg raw: 93.1%  |  Avg REAL: 97.0%
```

- **Raw %** = cells whose value differs from English (low for placeholder-heavy strings)
- **REAL %** = % of TRANSLATABLE content that's translated (excludes pure-placeholder strings like `{x} lbs`, brand names, acronyms)

Aim for REAL % above 95% per locale. Tagalog (`tl`) and Dutch (`nl`) commonly use English loanwords so they're naturally lower (~86-93%).

---

## 6. Troubleshooting

### `flutter gen-l10n`: "Invalid ARB resource name 'Foo'"
Keys must be **lowerCamelCase** valid Dart identifiers — no leading uppercase, no leading digits, no hyphens, no dots.

```bash
# Fix manually in app_en.arb, then mirror:
# Bad:  "FooBar", "1stPlace", "my-key"
# Good: "fooBar", "firstPlace", "myKey"
```

### `flutter gen-l10n`: "ICU Syntax Error" or "Found syntax errors"
A translated value has unbalanced `{` or `}` (translator mangled an ICU placeholder).
```bash
python3 scripts/i18n_add_feature.py sanitize-braces
cd mobile/flutter && flutter gen-l10n
```

### Analyzer: "Undefined name 'arg0'" in generated locale .dart file
A non-en value introduced a placeholder name that's NOT in EN's value. gen-l10n picks the UNION of all placeholders, creating a method that references undefined args.
```bash
python3 scripts/i18n_add_feature.py strip-stray-placeholders
cd mobile/flutter && flutter gen-l10n
```

### Analyzer: "The method/getter 'foo' isn't defined for the type 'AppLocalizations'"
Call site references `AppLocalizations.of(context).foo` but `foo` isn't in `app_en.arb`. Either:
- Typo in source (fix the call)
- Forgot to add the key (use `python3 scripts/i18n_add_feature.py keys --json /tmp/missing.json`)

### Analyzer: "argument_type_not_assignable: 'int' to 'String'"
`@-metadata` declares a placeholder as `String` but call site passes an `int`. Solution: change all placeholder types to `Object` (accepts both):
```bash
# Quick fix: bulk-normalize all non-plural placeholder types to Object
backend/.venv/bin/python << 'PY'
import json, glob
for arb in sorted(glob.glob('mobile/flutter/lib/l10n/app_*.arb')):
    d = json.load(open(arb))
    changed = False
    for k, v in d.items():
        if not k.startswith('@') or not isinstance(v, dict): continue
        for ph in (v.get('placeholders') or {}).values():
            if isinstance(ph, dict) and ph.get('type') in ('String','int','num','double'):
                ph['type'] = 'Object'; changed = True
    if changed:
        with open(arb, 'w') as f:
            json.dump(d, f, ensure_ascii=False, indent=2); f.write('\n')
PY
cd mobile/flutter && flutter gen-l10n
```

Note: placeholders used inside `{count, plural, ...}` MUST be `num` — re-run with that exception if needed.

### Gemini returns English instead of translation
Common causes:
- Rate limit (rare with paid API key — usually only an issue with free tiers like MyMemory)
- Locale unsupported (Gemini supports all 36 we have)
- String is too short or all-acronym — Gemini intentionally leaves it

The script's `oneshot` command is good for debugging — run it on the same string and locale to confirm.

### Translation introduces wrong placeholders (rare)
Example: Japanese translation of `'Set {arg0} of 3'` came back as `'セット {arg0} のうち {n}'` — adding stray `{n}`.

```bash
# Detect + fix:
python3 scripts/i18n_add_feature.py strip-stray-placeholders
```

---

## 7. How the AI Coach uses locale

```
┌─────────────┐                                           ┌──────────────┐
│   Client    │                                           │   Backend    │
│             │  POST /api/chat/send                      │              │
│  Accept-    │  ────────────────────────────────────►    │ chat.py:     │
│  Language:  │                                           │  • _ui_locale│
│  en         │  X-Chat-Locale: te                        │    = "en"    │
│             │                                           │  • _chat_    │
│  X-Chat-    │                                           │    locale    │
│  Locale: te │                                           │    = "te"    │
└─────────────┘                                           └──────┬───────┘
                                                                 │
                          coach.process_message(locale="te")     │
                                  ▼                              │
                          ┌───────────────────┐                  │
                          │  Gemini system    │                  │
                          │  prompt prefix:   │                  │
                          │                   │                  │
                          │  "ALWAYS respond  │                  │
                          │   in తెలుగు..."   │                  │
                          └─────────┬─────────┘                  │
                                    ▼                            │
                          Telugu reply streams back              │
                                                                 │
                          BackgroundTask:                        │
                          • persist preferred_locale="en"   ◄────┤ (Accept-Language)
                          • persist chat_locale="te"        ◄────┤ (X-Chat-Locale)
                                                                 │
                          Next cron fires:                       │
                          • Notification body uses preferred_locale ("en")
                          • Coach proactive nudge uses chat_locale ("te")
```

**Key insight**: app UI locale and AI Coach locale are independent. User can run app in English but receive Telugu AI Coach replies. Set in Settings → "AI Coach Language".

When the user changes AI Coach language, the chat screen inserts a centered grey-pill system message: "🌐 AI Coach now responds in తెలుగు".

---

## 8. Future-Claude-session checklist

When a future Claude session opens this repo and needs to ship i18n for a new feature, ask them to:

1. **Read this doc first**.
2. **Identify which layer**: ARB? Backend notification? DB row?
3. **Use `scripts/i18n_add_feature.py`** — don't write a new translation script.
4. **Verify with `coverage`**: `python3 scripts/i18n_add_feature.py coverage`.
5. **Run `flutter analyze lib/`** — should stay at exactly 3 pre-existing errors.
6. **NEVER use Gemini Pro / GPT-4 / Claude for translation** — Flash Lite is ~10× cheaper and quality is excellent for UI strings.

If you (a future Claude session) hit a scenario this guide doesn't cover, add it to this doc before solving it. Future sessions will thank you.

---

## 9. File reference

| File | What it does |
|---|---|
| `scripts/i18n_add_feature.py` | **Main entry — reusable CLI for all i18n scenarios** |
| `scripts/i18n_translate_gemini.py` | Lower-level: batched Gemini translator (used internally) |
| `scripts/i18n_translate_backend_notifications.py` | Backend notification template translator |
| `scripts/i18n_coverage_check.py` | Strict pass/fail coverage gate (CI use) |
| `scripts/i18n_migrate_screen.py` | Lexer for extracting English literals from Dart |
| `scripts/i18n_migrate_all.py` | Orchestrator across all screens |
| `scripts/i18n_rtl_audit.py` | RTL layout audit (Alignment.left → AlignmentDirectional.start) |
| `scripts/i18n_fix_const_wraps.py` | Strip `const` from constructors using AppLocalizations |
| `backend/scripts/translate_exercise_library_i18n.py` | DB exercise i18n filler |
| `backend/scripts/translate_food_i18n.py` | DB food + recipes i18n filler |
| `backend/scripts/seed_exercise_library_i18n_en.py` | One-time English baseline seed |
| `backend/scripts/seed_food_i18n_en.py` | One-time English food baseline seed |
| `backend/core/locale.py` | parse_accept_language, persist_user_locale, overlay_*_i18n |
| `backend/core/i18n.py` | get_template + EN baseline templates |
| `backend/core/i18n_translations.py` | NON_EN_TEMPLATES (auto-generated) |
| `mobile/flutter/lib/data/services/chat_action_summary_builder.dart` | Client-side localization of tool action summaries |
| `mobile/flutter/lib/data/providers/locale_provider.dart` | App UI locale notifier |
| `mobile/flutter/lib/data/providers/chat_locale_provider.dart` | AI Coach locale notifier (separate) |
| `mobile/flutter/lib/data/services/api_client.dart` | Sends Accept-Language + X-Chat-Locale headers |
| `mobile/flutter/lib/l10n/app_*.arb` | The 36 translation files (en + 35 locales) |
| `mobile/flutter/lib/l10n/generated/` | Auto-regenerated Dart by `flutter gen-l10n` |
| `backend/migrations/2103_users_preferred_locale.sql` | App UI locale column |
| `backend/migrations/2104_exercise_library_i18n.sql` | Exercise i18n tables |
| `backend/migrations/2105_food_overrides_i18n.sql` | Food + recipes i18n tables |
| `backend/migrations/2106_users_chat_locale.sql` | AI Coach locale column (separate) |
| `docs/I18N_GUIDE.md` | **This file** |

---

## 10. Frequently asked questions

**Q: Why Gemini 3.1 Flash Lite specifically and not Google Translate or DeepL?**
A: Gemini handles ICU placeholders correctly (it understands `{name}` is a variable, not text). Google Translate often translates the placeholder name. DeepL has the same issue and costs 10× more. Flash Lite is also our existing API key — no new vendor.

**Q: What if Gemini gets rate-limited?**
A: Flash Lite has very high quota (10M tokens/min on paid tier). Hasn't happened in practice. If it does, the script retries the failing locale automatically; cells that ultimately fail stay English (graceful fallback).

**Q: How do I add a new locale (e.g. Vietnamese variant)?**
A: This is a much bigger change — touches the `LOCALES_NON_EN` list in 4+ scripts, MaterialApp's `supportedLocales`, native iOS `.lproj`, native Android `values-`, and the backend `SUPPORTED_LOCALES` set. See `feedback_strategy_scenario_depth` for the full checklist. Not something the reusable script handles.

**Q: Can the AI Coach respond in a different language than what I chose in Settings?**
A: Yes — set "AI Coach Language" separately in Settings. This is the X-Chat-Locale path. App UI stays whatever you set as "App Language".

**Q: What does the user see when they change AI Coach language?**
A: A centered grey-pill system message appears in the chat conversation: "🌐 AI Coach now responds in తెలుగు". Like WhatsApp's encryption notice.

**Q: How is non-English content quality?**
A: REAL coverage is 97% on average. Top locales (Arabic, Russian, Chinese, Japanese) are at 98-99%. Bottom (Tagalog) at 86% because Filipino genuinely uses English loanwords for fitness/tech terms. For better quality, hire a native speaker reviewer per locale — the structural pipeline (this guide) is independent of human review.

---

## 11. What to do when you spot translation quality issues

1. Open `mobile/flutter/lib/l10n/app_<locale>.arb`
2. Find the key
3. Replace the value with a corrected translation
4. Run `cd mobile/flutter && flutter gen-l10n`
5. Don't run the translator — it will overwrite your manual fix (the `==English` resume-safe check skips already-translated cells)

For systematic corrections (e.g. "the word X is consistently wrong in Hindi"), grep + sed across `app_hi.arb`, then commit. Document the pattern so future generations don't reintroduce it.
