# How to Build a 36-Language Flutter App from Scratch

**A complete, from-zero implementation guide for adding 36-language support to any new Flutter + FastAPI app.**

By the end you'll have:
- Flutter app that switches between 36 languages instantly
- ARB-based localization with `flutter gen-l10n`
- Settings UI with a language picker
- (Optional) Backend FastAPI that responds in the user's locale
- (Optional) AI chatbot (Gemini) that replies in the user's language
- (Optional) DB-stored content (products, articles, etc.) per locale
- (Optional) Separate "AI Coach language" different from app UI language
- Native iOS + Android string files for widgets / system UI
- Automated translation pipeline (no manual copy/paste, ~$1-2 per full app)

Lifted from a production fitness app shipping 12,000+ translated strings.

---

## Table of contents

1. [The 36 supported languages](#1-the-36-supported-languages)
2. [Cost & timeline reality check](#2-cost--timeline-reality-check)
3. [Required: Phase 1 — Flutter scaffold](#3-required-phase-1--flutter-scaffold)
4. [Required: Phase 2 — Language picker UI](#4-required-phase-2--language-picker-ui)
5. [Required: Phase 3 — Translation pipeline](#5-required-phase-3--translation-pipeline)
6. [Optional: Phase 4 — Backend locale awareness (FastAPI)](#6-optional-phase-4--backend-locale-awareness-fastapi)
7. [Optional: Phase 5 — AI chatbot in user's language (Gemini)](#7-optional-phase-5--ai-chatbot-in-users-language-gemini)
8. [Optional: Phase 6 — DB-stored content i18n](#8-optional-phase-6--db-stored-content-i18n)
9. [Optional: Phase 7 — Separate AI Coach language](#9-optional-phase-7--separate-ai-coach-language)
10. [Optional: Phase 8 — Native iOS/Android strings](#10-optional-phase-8--native-iosandroid-strings)
11. [Files to copy from this repo](#11-files-to-copy-from-this-repo)
12. [Common pitfalls](#12-common-pitfalls)
13. [Maintenance: adding a new feature](#13-maintenance-adding-a-new-feature)

---

## 1. The 36 supported languages

| ISO | Language | Script | Speakers (M) | Notes |
|---|---|---|---|---|
| en | English | Latin | 1500+ | Source of truth |
| ar | Arabic | Arabic (RTL) | 420 | RTL — needs layout audit |
| bn | Bengali | Bengali | 270 | |
| cs | Czech | Latin | 11 | |
| de | German | Latin | 130 | 30% longer than EN; audit button widths |
| es | Spanish | Latin | 560 | |
| fi | Finnish | Latin | 5 | Long compound words |
| fr | French | Latin | 280 | |
| ha | Hausa | Latin | 80 | West Africa |
| hi | Hindi | Devanagari | 600 | |
| id | Indonesian | Latin | 200 | |
| it | Italian | Latin | 65 | |
| ja | Japanese | Hiragana/Katakana/Kanji | 125 | |
| jv | Javanese | Latin | 80 | Indonesia |
| kn | Kannada | Kannada | 45 | India |
| ko | Korean | Hangul | 80 | |
| ml | Malayalam | Malayalam | 35 | India |
| mr | Marathi | Devanagari | 95 | India |
| ms | Malay | Latin | 33 | |
| ne | Nepali | Devanagari | 25 | |
| nl | Dutch | Latin | 25 | High loanword usage |
| or | Odia | Odia | 38 | India |
| pa | Punjabi | Gurmukhi | 125 | |
| pl | Polish | Latin | 45 | |
| pt | Portuguese | Latin | 260 | |
| ru | Russian | Cyrillic | 260 | |
| sv | Swedish | Latin | 10 | |
| sw | Swahili | Latin | 200 | East Africa |
| ta | Tamil | Tamil | 85 | India / SE Asia |
| te | Telugu | Telugu | 95 | India |
| th | Thai | Thai | 70 | No spaces between words |
| tl | Tagalog | Latin | 80 | Filipino |
| tr | Turkish | Latin | 90 | |
| ur | Urdu | Arabic (RTL) | 230 | RTL |
| vi | Vietnamese | Latin (w/ diacritics) | 95 | |
| zh | Simplified Chinese | Hanzi | 1100 | |

**Total addressable population:** ~6 billion people across these 36 languages.

You can shrink this list to whatever subset you want. The pipeline scales linearly with locale count.

---

## 2. Cost & timeline reality check

### Per-feature cost (gemini-3.1-flash-lite, 2026 pricing)
| Action | Cost |
|---|---|
| Single new string × 35 locales | $0.0001 |
| 20 new strings × 35 locales | $0.002 |
| 200 new strings × 35 locales | $0.02 |
| **Full app (10K strings × 35 locales)** | **$1-2** |

### Timeline
| Phase | Time (one developer + Claude) |
|---|---|
| Phase 1 (Flutter scaffold) | 30 min |
| Phase 2 (Language picker UI) | 30-60 min |
| Phase 3 (Translation pipeline + first run) | 1-2 hours (mostly automated) |
| Phase 4 (Backend locale) | 2-4 hours |
| Phase 5 (AI in user's language) | 1-2 hours |
| Phase 6 (DB i18n) | 4-8 hours (more if many tables) |
| Phase 7 (Separate AI Coach language) | 2-3 hours |
| Phase 8 (Native strings) | 1-2 hours |
| **Total minimum (Phases 1-3 only)** | **~3 hours** |
| **Total full stack (Phases 1-8)** | **~12-20 hours** |

If you have an LLM coding assistant (Claude, Cursor, etc.), most of this becomes "describe what you want + paste the snippets below." Manual work is mostly the per-app config (which screens, which DB tables, etc.).

---

## 3. Required: Phase 1 — Flutter scaffold

### 3.1 Add dependencies

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  shared_preferences: ^2.x   # for persisting user's choice
  flutter_riverpod: ^2.x      # or your preferred state mgmt

flutter:
  generate: true
```

### 3.2 Create `l10n.yaml` at repo root (sibling of pubspec.yaml)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/generated
synthetic-package: false
nullable-getter: false
```

### 3.3 Create `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appTitle": "MyApp",
  "navHome": "Home",
  "navSettings": "Settings",
  "commonOk": "OK",
  "commonCancel": "Cancel",
  "settingsLanguage": "Language",
  "@settingsGreetingName": {
    "placeholders": {
      "name": { "type": "Object" }
    }
  },
  "settingsGreetingName": "Hello, {name}!"
}
```

### 3.4 Create empty stub `app_<locale>.arb` for each of the 35 non-en locales

```bash
cd lib/l10n
for loc in ar bn cs de es fi fr ha hi id it ja jv kn ko ml mr ms ne nl or pa pl pt ru sv sw ta te th tl tr ur vi zh; do
  echo "{\"@@locale\": \"$loc\"}" > app_$loc.arb
done
```

### 3.5 Generate Dart code

```bash
flutter gen-l10n
```

This creates `lib/l10n/generated/app_localizations.dart` and one file per locale. Re-run after every ARB edit.

### 3.6 Wire into MaterialApp

In `lib/app.dart` (or wherever your root MaterialApp lives):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);  // see step 4
    return MaterialApp(
      title: 'MyApp',
      locale: localeState.locale,                     // null = system default
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(),
    );
  }
}
```

### 3.7 Use translated strings

```dart
import 'l10n/generated/app_localizations.dart';

// In any widget with BuildContext:
Text(AppLocalizations.of(context).navHome)

// With placeholder:
Text(AppLocalizations.of(context).settingsGreetingName(userName))
```

---

## 4. Required: Phase 2 — Language picker UI

### 4.1 Locale provider

`lib/data/providers/locale_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState {
  final Locale? locale;
  const LocaleState({this.locale});
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(const LocaleState()) {
    _load();
  }

  static const _kKey = 'locale_code';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kKey);
    if (code != null && code.isNotEmpty) {
      state = LocaleState(locale: Locale(code));
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = LocaleState(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kKey);
    } else {
      await prefs.setString(_kKey, locale.languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (_) => LocaleNotifier(),
);
```

### 4.2 Settings screen language picker

`lib/screens/settings/language_picker.dart`:

```dart
const _kLocaleNames = <String, String>{
  'en': 'English',
  'ar': 'العربية',
  'bn': 'বাংলা',
  'cs': 'Čeština',
  'de': 'Deutsch',
  'es': 'Español',
  'fi': 'Suomi',
  'fr': 'Français',
  'ha': 'Hausa',
  'hi': 'हिन्दी',
  'id': 'Bahasa Indonesia',
  'it': 'Italiano',
  'ja': '日本語',
  'jv': 'Basa Jawa',
  'kn': 'ಕನ್ನಡ',
  'ko': '한국어',
  'ml': 'മലയാളം',
  'mr': 'मराठी',
  'ms': 'Bahasa Melayu',
  'ne': 'नेपाली',
  'nl': 'Nederlands',
  'or': 'ଓଡ଼ିଆ',
  'pa': 'ਪੰਜਾਬੀ',
  'pl': 'Polski',
  'pt': 'Português',
  'ru': 'Русский',
  'sv': 'Svenska',
  'sw': 'Kiswahili',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'th': 'ไทย',
  'tl': 'Tagalog',
  'tr': 'Türkçe',
  'ur': 'اردو',
  'vi': 'Tiếng Việt',
  'zh': '简体中文',
};

class LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).locale?.languageCode ?? 'en';
    return ListView(
      children: [
        for (final entry in _kLocaleNames.entries)
          RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: current,
            onChanged: (code) {
              ref.read(localeProvider.notifier).setLocale(
                code == null ? null : Locale(code),
              );
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
```

That's it. The app instantly switches language when the user picks one because `MaterialApp` watches `localeProvider`.

---

## 5. Required: Phase 3 — Translation pipeline

This is the magic that fills your 35 non-English `.arb` files automatically.

### 5.1 Get a Gemini API key

1. Visit https://aistudio.google.com/apikey
2. Sign in with Google
3. Click "Create API key"
4. Export it: `export GEMINI_API_KEY=AIza...` (or put in `.env`)

### 5.2 Install Python deps

```bash
pip install google-genai
```

### 5.3 Copy the translation script

Copy `scripts/i18n_add_feature.py` from this repo into your new project.

Edit these constants at the top of the script:

```python
REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "lib" / "l10n"     # your ARB dir
EN_ARB = L10N / "app_en.arb"
LOCALES_NON_EN = [...]            # the 35 non-en codes
LOCALE_NATIVE = {...}             # native names in their script
PRESERVE_VERBATIM = [             # YOUR brand names + acronyms
    "MyAppName",
    "API", "URL",
    # ...
]
```

(Backend constants `BACKEND_I18N` / `BACKEND_TRANSLATIONS` can be removed if you don't have a Python backend.)

### 5.4 Translate everything

```bash
# Add new keys to en.arb (manually or via a JSON file)
cat > /tmp/initial_keys.json << 'EOF'
{
  "appTitle": "MyApp",
  "navHome": "Home",
  "navSettings": "Settings",
  "commonOk": "OK",
  "commonCancel": "Cancel",
  "settingsLanguage": "Language",
  "settingsGreetingName": "Hello, {name}!",
  "@settingsGreetingName": {"placeholders": {"name": {"type": "Object"}}}
}
EOF

# One command: adds to en.arb, mirrors to all 35, translates via Gemini
python3 scripts/i18n_add_feature.py keys --json /tmp/initial_keys.json
```

After ~10 seconds you'll have all 36 `app_*.arb` files filled. Run `flutter gen-l10n`, then use `AppLocalizations.of(context).appTitle` in your widgets.

### 5.5 Per-feature workflow

When you add new English strings:
```bash
# Option A: Migrate hardcoded strings in source automatically
python3 scripts/i18n_add_feature.py screen --files lib/screens/new_screen/

# Option B: Add an explicit JSON dict
python3 scripts/i18n_add_feature.py keys --json /tmp/new_keys.json

# Option C: Quick one-off translation (no persistence)
python3 scripts/i18n_add_feature.py oneshot --text "Hello" --locales hi,te
```

Done. App now supports 36 languages.

---

## 6. Optional: Phase 4 — Backend locale awareness (FastAPI)

Skip if you have no backend or your backend doesn't generate user-facing text.

### 6.1 Add `preferred_locale` column to your users table

```sql
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS preferred_locale TEXT NOT NULL DEFAULT 'en';

CREATE INDEX IF NOT EXISTS idx_users_preferred_locale_non_en
    ON users (preferred_locale)
    WHERE preferred_locale <> 'en';
```

### 6.2 Create `backend/core/locale.py`

Copy from `backend/core/locale.py` in this repo. The relevant functions:
- `SUPPORTED_LOCALES` — set of 36 codes
- `LOCALE_NATIVE_NAMES` — dict for prompts
- `parse_accept_language(header) -> str` — Accept-Language q-value parser
- `get_user_locale_from_request(request) -> str` — FastAPI helper
- `persist_user_locale(user_id, locale, db_client)` — write to DB

### 6.3 Wire into your endpoints

```python
from fastapi import Request, BackgroundTasks
from core.locale import get_user_locale_from_request, persist_user_locale

@router.post("/some-endpoint")
async def handler(request: Request, background_tasks: BackgroundTasks, ...):
    user_locale = get_user_locale_from_request(request)
    # Use user_locale to localize the response
    response = generate_localized_response(..., locale=user_locale)
    # Persist asynchronously
    if user_locale != "en":
        background_tasks.add_task(persist_user_locale, user_id, user_locale, db)
    return response
```

### 6.4 Client sends Accept-Language

In your Dio interceptor:

```dart
final localeCode = ref.read(localeProvider).locale?.toLanguageTag();
if (localeCode != null) {
  options.headers['Accept-Language'] = localeCode;
}
```

### 6.5 Backend notification templates

If you send cron-fired notifications (emails, push) with template strings:

```python
# backend/core/i18n.py
_EN_TEMPLATES = {
    "welcome_email_subject": "Welcome to MyApp, {name}!",
    "weekly_digest_title": "Your week in review, {name}",
    # ...
}

def get_template(locale: str, key: str, **fmt) -> str:
    try:
        from core.i18n_translations import NON_EN_TEMPLATES
        if locale != "en" and locale in NON_EN_TEMPLATES:
            tmpl = NON_EN_TEMPLATES[locale].get(key)
            if tmpl: return tmpl.format(**fmt)
    except ImportError:
        pass
    return _EN_TEMPLATES.get(key, key).format(**fmt)
```

Translate via:
```bash
python3 scripts/i18n_add_feature.py notification \
    --key welcome_email_subject \
    --en "Welcome to MyApp, {name}!"
```

This auto-translates to all 35 locales + patches `backend/core/i18n_translations.py`.

---

## 7. Optional: Phase 5 — AI chatbot in user's language (Gemini)

Skip if you don't have an LLM chatbot.

### 7.1 Inject locale prefix into Gemini system prompt

```python
def _build_locale_prefix(locale: str) -> str:
    """Inject this at the TOP of every system prompt so Gemini replies in
    the user's language regardless of what they wrote."""
    if locale == "en":
        return ""
    native = LOCALE_NATIVE_NAMES.get(locale, locale)
    return f"""The user's preferred language is {native} ({locale}).
ALWAYS respond in {native}, regardless of which language the user writes in.
Match their tone but use {native}. Exceptions: keep technical acronyms
(API, URL, etc.) and brand names (MyApp, ...) in Latin script even when
responding in non-Latin-script languages.

"""

# Use it:
def chat(self, user_message: str, system_prompt: str, locale: str = "en"):
    effective_prompt = _build_locale_prefix(locale) + system_prompt
    # ... call Gemini with effective_prompt ...
```

### 7.2 Pass locale through your service layer

Every chat/LLM call accepts a `locale` kwarg. Plumb it from the endpoint through to Gemini.

### 7.3 Gemini quality is excellent for all 36 locales

The model natively handles all 36. Even less common locales like Hausa, Tagalog, Odia work — coverage is 85-99% accuracy on UI-style strings.

---

## 8. Optional: Phase 6 — DB-stored content i18n

Skip if you don't have user-facing content stored in DB rows (product names, exercise descriptions, article titles, etc.).

### 8.1 Create i18n table per content type

```sql
CREATE TABLE IF NOT EXISTS products_i18n (
    product_id   UUID NOT NULL,
    locale       TEXT NOT NULL,
    name         TEXT NOT NULL,
    description  TEXT,
    PRIMARY KEY (product_id, locale)
);

CREATE INDEX IF NOT EXISTS idx_products_i18n_locale
    ON products_i18n (locale);
```

### 8.2 Seed the English baseline

Copy your existing English rows from `products` into `products_i18n` with `locale='en'`. One-time script:

```python
for row in db.table("products").select("id, name, description").execute().data:
    db.table("products_i18n").upsert({
        "product_id": row["id"],
        "locale": "en",
        "name": row["name"],
        "description": row["description"],
    }, on_conflict="product_id,locale").execute()
```

### 8.3 Write a translation script

Pattern at `backend/scripts/translate_exercise_library_i18n.py` (copy + adapt). It:
- Reads en rows from the i18n table
- Batches them (~50 rows per Gemini call)
- Calls Gemini Flash Lite to translate name + description
- INSERTs into the i18n table for each non-en locale
- Idempotent via ON CONFLICT (id, locale) DO NOTHING
- Resume-safe

Run it once per table:
```bash
python3 backend/scripts/translate_products_i18n.py
```

### 8.4 Use in queries via overlay helpers

```python
def overlay_product_i18n(product_dict: dict, locale: str, db_client) -> dict:
    if locale == "en":
        return product_dict  # en is already in the base row
    i18n_row = db_client.table("products_i18n")\
        .select("name, description")\
        .eq("product_id", product_dict["id"])\
        .in_("locale", [locale, "en"])\
        .execute().data
    # Prefer requested locale, fall back to en
    for row in sorted(i18n_row, key=lambda r: 0 if r.get("locale") == locale else 1):
        if row.get("name"): product_dict["name"] = row["name"]
        if row.get("description"): product_dict["description"] = row["description"]
        break
    return product_dict
```

Cost: ~$0.0001 per row × 35 locales. 1,000 rows ≈ $0.10.

---

## 9. Optional: Phase 7 — Separate AI Coach language

Skip if you don't have an AI feature or don't want a separate language preference for it.

### Why this exists

User might want app UI in English (because they read English fluently) but the AI Coach to reply in Telugu (because that's their natural conversational language). Without this, both are locked to the same language.

### 9.1 Add `chat_locale` column

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS chat_locale TEXT;
CREATE INDEX IF NOT EXISTS idx_users_chat_locale_non_null
    ON users (chat_locale) WHERE chat_locale IS NOT NULL;
```

Null = use `preferred_locale` (the app UI locale).

### 9.2 Backend: extract X-Chat-Locale header

```python
def get_chat_locale_from_request(request) -> str | None:
    header = request.headers.get("X-Chat-Locale")
    if header and header.lower() in SUPPORTED_LOCALES:
        return header.lower()
    return None

# In chat endpoint:
chat_locale = get_chat_locale_from_request(request) \
    or get_user_locale_from_request(request)  # fall through to app UI
response = await coach.chat(..., locale=chat_locale)
```

### 9.3 Client: separate provider for chat language

Copy `lib/data/providers/chat_locale_provider.dart` from this repo. Same shape as `localeProvider` but with key `'chat_locale_code'`.

### 9.4 Client: send X-Chat-Locale header

```dart
final chatCode = ref.read(chatLocaleProvider).locale?.toLanguageTag();
if (chatCode != null) {
  options.headers['X-Chat-Locale'] = chatCode;
}
```

### 9.5 Settings UI: second language picker

Two rows in Settings:
- "App Language" → `localeProvider`
- "AI Coach Language" → `chatLocaleProvider` (with "Same as app" as the null option)

### 9.6 In-chat system message when language changes (UX delight)

When user changes AI Coach language in Settings, insert a centered grey-pill message into the chat conversation:

```dart
// In your chat screen build():
ref.listen<ChatLocaleState>(chatLocaleProvider, (prev, next) {
  if (prev?.locale != next.locale) {
    final native = next.locale != null
      ? _kLocaleNames[next.locale!.languageCode] ?? next.locale!.languageCode
      : 'app language';
    ref.read(chatMessagesProvider.notifier).addSystemNotification(
      next.locale == null
        ? AppLocalizations.of(context).chatLanguageResetSystem
        : AppLocalizations.of(context).chatLanguageChangedSystem(native),
    );
  }
});
```

Render system messages as:
```dart
Center(child: Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(systemText, style: TextStyle(fontSize: 12)),
))
```

Looks like WhatsApp's "Messages are end-to-end encrypted" pill.

---

## 10. Optional: Phase 8 — Native iOS/Android strings

Skip if you have no widgets, live activities, or system-level UI.

### 10.1 iOS — create per-locale `Localizable.strings`

```bash
cd ios/Runner
for loc in en ar bn cs de es fi fr ha hi id it ja jv kn ko ml mr ms ne nl or pa pl pt ru sv sw ta te th tl tr ur vi zh; do
  mkdir -p $loc.lproj
  cat > $loc.lproj/Localizable.strings << 'EOF'
"CFBundleDisplayName" = "MyApp";
"WIDGET_TITLE" = "MyApp";
"NOTIF_REMINDER_TITLE" = "Time to log!";
EOF
done
```

Then in `ios/Runner/Info.plist`:
```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
```

### 10.2 Android — create per-locale `strings.xml`

```bash
cd android/app/src/main/res
for loc in ar bn cs de es fi fr ha hi id it ja jv kn ko ml mr ms ne nl or pa pl pt ru sv sw ta te th tl tr ur vi zh; do
  mkdir -p values-$loc
  cat > values-$loc/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MyApp</string>
    <string name="widget_title">MyApp</string>
    <string name="notif_reminder_title">Time to log!</string>
</resources>
EOF
done
```

Then translate them — for native files, use `oneshot` mode per string OR write a small Python script that reads each .strings/.xml and runs Gemini. For typical widget labels (5-10 strings), `oneshot` is fastest.

---

## 11. Files to copy from this repo

The minimum set for a new Flutter + FastAPI app:

| Source path | Destination | Why |
|---|---|---|
| `scripts/i18n_add_feature.py` | `scripts/i18n_add_feature.py` | The translation CLI |
| `scripts/I18N_ADD_FEATURE.md` | `scripts/I18N_ADD_FEATURE.md` | Tool docs |
| `mobile/flutter/lib/data/providers/locale_provider.dart` | `lib/data/providers/locale_provider.dart` | App UI locale state |
| `mobile/flutter/lib/data/providers/chat_locale_provider.dart` | `lib/data/providers/chat_locale_provider.dart` | (Phase 7) Chat locale state |
| `backend/core/locale.py` | `backend/core/locale.py` | (Phase 4) Accept-Language + DB persistence |
| `backend/core/i18n.py` | `backend/core/i18n.py` | (Phase 4) Notification templates |
| `backend/migrations/2103_users_preferred_locale.sql` | adapt to your migration system | (Phase 4) DB column |
| `backend/migrations/2106_users_chat_locale.sql` | adapt | (Phase 7) DB column |
| `backend/scripts/translate_exercise_library_i18n.py` | adapt for your tables | (Phase 6) DB translator template |
| `l10n.yaml` | `l10n.yaml` | Flutter gen-l10n config |

After copying, run the script's "Adapt these for your project" constants at the top of `i18n_add_feature.py`.

---

## 12. Common pitfalls

### 12.1 Layout overflow in long languages
German is ~30% longer than English. Finnish has long compound words. Audit your fixed-width buttons and labels — use `Flexible` / `Expanded` and `TextOverflow.ellipsis` where appropriate. Test on Hindi (Devanagari is tall) and Arabic (RTL with different glyph metrics).

### 12.2 RTL layouts for Arabic + Urdu
Replace direction-specific layout APIs:
- `Alignment.centerLeft` → `AlignmentDirectional.centerStart`
- `EdgeInsets.only(left: x)` → `EdgeInsetsDirectional.only(start: x)`
- `Positioned(left: x)` → `PositionedDirectional(start: x)`
- `TextAlign.left` → `TextAlign.start`

A script for this audit: copy `scripts/i18n_rtl_audit.py` from this repo. Run it after your initial translation pass.

### 12.3 ICU placeholders break
If a translation introduces stray `{n}` or unbalanced `{`, gen-l10n fails. Use:
```bash
python3 scripts/i18n_add_feature.py sanitize-braces
python3 scripts/i18n_add_feature.py strip-stray-placeholders
```

### 12.4 Currency, dates, numbers
Always use `intl` package's `NumberFormat`, `DateFormat`, `NumberFormat.currency` instead of hardcoded `'$5.99'`, `'5/12/2024'`, etc. These format per-locale automatically.

### 12.5 Asian name order
Don't compose "Hi, $firstName" — in Japanese/Korean/Chinese, family name comes first. Use a single `$name` field and let the user format their own display name.

### 12.6 Bundled fonts for non-Latin scripts
Older Android devices may not have Tamil, Hausa, Odia, etc. fonts installed. Bundle Noto Sans CJK + Noto Sans Indic + Noto Sans Arabic in `pubspec.yaml`:

```yaml
fonts:
  - family: NotoSans
    fonts:
      - asset: assets/fonts/NotoSans-Regular.ttf
      - asset: assets/fonts/NotoSansDevanagari-Regular.ttf
      # ... etc.
```

### 12.7 Thai text-breaking
Thai has no spaces between words. Flutter's default `Text` widget handles this correctly — don't manually `\n`-split Thai strings.

### 12.8 Plural forms vary
Russian has 3 plural forms. Arabic has 6. Use ICU plural syntax in your ARB:

```json
"@workoutCount": {
  "placeholders": { "count": { "type": "num" } }
},
"workoutCount": "{count, plural, =0{No workouts} =1{1 workout} other{{count} workouts}}"
```

The translation pipeline preserves ICU syntax verbatim — translators (Gemini in this case) fill in the language-specific plural cases naturally.

### 12.9 Acronyms + brand names accidentally translated
Solution: list them in `PRESERVE_VERBATIM` at the top of `i18n_add_feature.py`. The script tells Gemini to keep them in Latin script even in non-Latin languages.

### 12.10 Don't forget to commit the ARB files
The 36 `app_*.arb` files + generated `.dart` files should be committed to git. Translations are source code, not build artifacts.

---

## 13. Maintenance: adding a new feature

The most common workflow once your app is live:

### Scenario: You shipped a new screen with English strings

```bash
# 1. Replace hardcoded strings with AppLocalizations calls (manual or automated)
python3 scripts/i18n_add_feature.py screen --files lib/screens/new_feature/

# 2. (The above auto-runs translate + gen-l10n.)

# 3. Verify
flutter analyze lib/  # should show no new errors
python3 scripts/i18n_add_feature.py coverage  # confirm coverage didn't drop

# 4. Commit
git add lib/screens/new_feature/ lib/l10n/
git commit -m "feat: new feature with 36-language support"
```

Total time: ~5 minutes per feature. Cost: $0.001-0.01.

### Scenario: You're starting a brand new app

1. Phase 1 (Flutter scaffold) — 30 min
2. Phase 2 (Language picker) — 30 min
3. Phase 3 (Translation pipeline + first run) — 30 min
4. Build features in English
5. Run `python3 scripts/i18n_add_feature.py screen ...` after each new screen
6. Ship globally

Total bootstrap: ~2 hours from `flutter create` to "app ships in 36 languages."

---

## 14. Why this stack (vs alternatives)

| Alternative | Why we picked Gemini Flash Lite instead |
|---|---|
| Manual translation (humans) | $0.10-0.20 per word × millions of words = $100K+ |
| Google Cloud Translation API | $20/M chars, no ICU awareness |
| DeepL | $25/M chars, no Indic/SE Asian coverage |
| Free Google Translate web (deep_translator) | IP rate-limited, ICU placeholder mangling |
| MyMemory free tier | 1K words/day per IP |
| LibreTranslate self-hosted | Setup + maintenance overhead, mediocre quality |
| **Gemini 3.1 Flash Lite** | Cheapest LLM (~$1-2 for full app), ICU-aware via prompt, JSON mode, no rate limit issues |

---

## 15. Where to go next

After Phase 3 (you have a translated app):
- Add Phase 4 if you have a backend that emits user-facing text
- Add Phase 5 if you have an LLM chatbot
- Add Phase 6 if you have DB-stored content
- Add Phase 7 if your AI is a major feature deserving its own language preference
- Add Phase 8 if you ship widgets/live activities

Each Phase is independent — you can ship Phase 1+2+3 and have a fully multilingual app, then layer in the others as your product grows.

---

## 16. Real-world stats from this repo

A production fitness app shipping the full stack:
- **36 languages** supported
- **12,295 ARB keys** translated (97% REAL coverage)
- **44 backend notification templates** × 35 locales
- **2,439 exercise descriptions** × 35 locales (DB)
- **1,000 food entries** × 35 locales (DB)
- **AI Coach** responds in user's language via Gemini system prompt injection
- **Separate AI Coach language** picker (independent of app UI)
- **3 minutes** to translate the entire app via Gemini Flash Lite
- **~$2 one-time cost** for full app translation
- **~$0.001 per new feature** for ongoing translation

Tested in production with users in 30+ countries. Zero translation-quality complaints to date (you'll get a few — the trick is the script makes it trivial to fix one cell + commit).

---

## 17. Asking Claude (or another LLM) for help

If you point a future Claude session at this guide and ask "set up 36-language i18n for this Flutter app," they should:

1. Read this doc end-to-end.
2. Confirm which Phases apply to the user's app.
3. Walk Phases 1-3 first (the minimum viable stack).
4. Use the `i18n_add_feature.py` script for actual translation.
5. Layer in Phases 4-8 as the app grows.

The script + this doc + the GEMINI_API_KEY are everything Claude needs to ship a 36-language app from scratch.

Good luck! 🌐
