# `i18n_add_feature.py` — Reusable Flutter/Backend i18n Tool

**A drop-in Python CLI for shipping new features across many locales using `gemini-3.1-flash-lite`.**

Works with any Flutter app using ARB-based localization, and any FastAPI/Python backend using a templated-string notification system. Designed to be lifted into other projects with minimal changes.

---

## What it does

Takes English source strings (in your ARB file, your backend templates, or your DB) and translates them to N target languages using Google's Gemini 3.1 Flash Lite. Resume-safe, batched, cheap (~$0.0001 per string × 35 locales), and quality-preserving (handles ICU placeholders, brand names, and acronyms correctly).

## Supported scenarios

1. **`keys`** — Add a JSON dict of `{key: english_value}` to your ARB and translate to N locales.
2. **`screen`** — Scan a Flutter source directory, extract hardcoded English strings, replace with `AppLocalizations` calls, add to ARB, translate.
3. **`notification`** — Add a single backend notification template + translate.
4. **`db`** — Fill non-en rows in DB-stored i18n tables (delegates to per-table scripts).
5. **`oneshot`** — Ad-hoc translation of one string, no persistence.
6. **`sanitize-braces`** — Fix ICU brace imbalance across all ARB files (rare, post-translation).
7. **`strip-stray-placeholders`** — Re-mirror EN for values where translator introduced rogue placeholder names.
8. **`coverage`** — Print translation coverage per locale (raw + REAL).

---

## Installation in a new app

### 1. Copy the script
```bash
cp scripts/i18n_add_feature.py /path/to/your/app/scripts/
```

### 2. Install deps
```bash
pip install google-genai
```

### 3. Provide a Gemini API key
The script reads `GEMINI_API_KEY` from `backend/.env` (relative to repo root) OR from the environment:
```bash
export GEMINI_API_KEY=AIza...
```
Get a key at https://aistudio.google.com/apikey (free tier available).

### 4. Adapt the constants at the top of the script

```python
# ─── EDIT THESE FOR YOUR PROJECT ───────────────────────────────────────

REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "mobile" / "flutter" / "lib" / "l10n"     # your ARB dir
EN_ARB = L10N / "app_en.arb"                            # your en ARB
BACKEND_I18N = REPO / "backend" / "core" / "i18n.py"    # backend templates (optional)
BACKEND_TRANSLATIONS = REPO / "backend" / "core" / "i18n_translations.py"

# The non-English locales you support (ISO 639-1).
LOCALES_NON_EN = [
    "ar","bn","cs","de","es","fi","fr","ha","hi","id",
    "it","ja","jv","kn","ko","ml","mr","ms","ne","nl",
    "or","pa","pl","pt","ru","sv","sw","ta","te","th",
    "tl","tr","ur","vi","zh",
]

# Map each ISO code → human-readable native name (used in Gemini prompts).
# Including native script in parentheses helps Gemini pick the right script.
LOCALE_NATIVE = {
    "ar":"Arabic (العربية)",
    "hi":"Hindi (हिन्दी)",
    # ... fill in all your locales ...
}

# Terms to preserve verbatim across all translations.
# Brand names + technical acronyms specific to your app.
PRESERVE_VERBATIM = [
    "MyAppName", "BrandPartner", "PRO", "API", "URL",
    # ... add your brand + acronyms ...
]
```

### 5. (Optional) Adapt the backend hooks

If your backend uses a different localization pattern, edit `cmd_notification` and `_write_non_en_templates` to match. Or just don't use the `notification` subcommand and skip backend integration.

If your DB has different i18n table names, edit `cmd_db` to point at your per-table translator scripts. Or remove the subcommand.

---

## Usage examples

### Add a JSON dict of new ARB keys
```bash
# /tmp/new.json: {"loginButton": "Sign in", "loginHint": "Email address"}
python3 scripts/i18n_add_feature.py keys --json /tmp/new.json
```

What happens:
1. Validates each key is a valid Dart identifier (lowerCamelCase).
2. Adds keys to `app_en.arb` (skips ones already present).
3. Mirrors English to all 35 non-en `.arb` files.
4. Translates non-en cells via Gemini Flash Lite (only translates cells where current value == English — resume-safe).
5. Runs `flutter gen-l10n`.

### Migrate Dart files containing hardcoded strings
```bash
python3 scripts/i18n_add_feature.py screen --files lib/screens/checkout/
```

What happens: delegates to `scripts/i18n_migrate_screen.py` + `i18n_migrate_all.py` (the lexer extracts `Text('foo')`, `hint: 'bar'`, etc., replaces with `AppLocalizations.of(context).keyName`, mints camelCase keys, then runs `keys` on the result).

### Add a backend notification template
```bash
python3 scripts/i18n_add_feature.py notification \
    --key welcome_email_subject \
    --en "Welcome to MyApp, {name}!"
```

What happens:
1. Appends to `_EN_TEMPLATES` dict in `backend/core/i18n.py`.
2. Translates to all 35 non-en locales.
3. Patches `backend/core/i18n_translations.py` with the new translations.
4. Your `get_template(locale, key, **vars)` call immediately picks up the localized version.

### Translate DB rows
```bash
python3 scripts/i18n_add_feature.py db --table exercise_library_i18n
```

Delegates to a per-table translator at `backend/scripts/translate_<table>.py`. You provide the per-table script (the script in this repo has examples).

### Ad-hoc translation (no persistence)
```bash
python3 scripts/i18n_add_feature.py oneshot --text "Hello world" --locales hi,te
# [hi] नमस्ते दुनिया
# [te] నమస్తే ప్రపంచం
```

### Check coverage
```bash
python3 scripts/i18n_add_feature.py coverage
```

Prints two metrics per locale:
- **Raw %**: cells whose value differs from English (low for placeholder-heavy keys).
- **REAL %**: % of TRANSLATABLE content translated (excludes pure-placeholder strings, brand names, acronyms).

Aim for REAL ≥ 95%.

### Repair broken ARB files
```bash
# ICU brace imbalance (rare; only if Gemini mangled an ICU placeholder)
python3 scripts/i18n_add_feature.py sanitize-braces

# Stray placeholder names (translator invented {n} that wasn't in EN)
python3 scripts/i18n_add_feature.py strip-stray-placeholders
```

---

## Quality guarantees

### What's preserved verbatim
- **ICU placeholders**: `{name}`, `{count}` stay exactly the same.
- **Brand names**: Listed in `PRESERVE_VERBATIM`. Stay in Latin script even in non-Latin-script locales (Arabic, Chinese, etc.).
- **Technical acronyms**: Listed in `PRESERVE_VERBATIM`.

### How it stays cheap
- **Batched**: 80 strings per Gemini call. Amortizes the system-prompt token overhead.
- **Resume-safe**: Only translates cells whose current value == English source.
- **Parallel**: 4-8 locales processed concurrently, 8 batches per locale concurrent.

### How it stays correct
- **JSON response mode**: Gemini returns valid JSON; we never parse free text.
- **Strict validation**: Bad JSON → cell stays English (graceful fallback). Never silently breaks the build.
- **Stripped markdown fences**: Defensive against model behaviors that wrap JSON in `​```​` fences.

---

## Cost calculator

`gemini-3.1-flash-lite` pricing (as of 2026-05):
- Input: $0.10 / 1M tokens
- Output: $0.40 / 1M tokens

| Action | Rough cost |
|---|---|
| 1 string × 35 locales | $0.0001 |
| 20 strings × 35 locales | $0.002 |
| 200 strings × 35 locales | $0.02 |
| 2,000 strings × 35 locales | $0.20 |
| 10,000 strings × 35 locales | $1-2 |

Translation of an entire mid-size app (10K-15K strings × 35 locales) typically costs **$1-3** and runs in **~5-10 minutes** with default parallelism.

---

## Architecture (under the hood)

```
                ┌───────────────────────────────┐
                │  i18n_add_feature.py (CLI)    │
                └─────────────┬─────────────────┘
                              │
       ┌──────────┬───────────┼───────────┬─────────────┐
       │          │           │           │             │
   keys/      notification    db       oneshot     coverage
   screen        │             │           │             │
       │         │             │           │             │
       ▼         ▼             ▼           ▼             ▼
  Add to ARB   Append to     Delegate    Print      Scan ARB
  Mirror EN    _EN_TEMPLATES  to per-    to stdout   files
  Translate    Translate      table                 + diff
  gen-l10n     (35 locales)   script                  vs EN
       │         │             │           │             │
       │         │             │           │             │
       └─────────┴──────┬──────┴───────────┘             │
                        ▼                                │
              ┌─────────────────────┐                    │
              │  Gemini Flash Lite  │                    │
              │  (batched, 8 par.)  │                    │
              │                     │                    │
              │  - Preserve ICU     │                    │
              │  - Preserve brands  │                    │
              │  - JSON mode        │                    │
              │  - Validate output  │                    │
              └─────────────────────┘                    │
                                                          │
                                                ┌────────────────┐
                                                │   Print:       │
                                                │   raw %        │
                                                │   REAL %       │
                                                └────────────────┘
```

---

## Why Gemini Flash Lite over alternatives

| Alternative | Issue |
|---|---|
| **Google Translate web** (free) | IP rate-limited; doesn't understand ICU placeholders; often mangles them. |
| **DeepL** | High quality for European langs, but $$$, and no/limited Indic/SE Asian coverage. |
| **MyMemory free tier** | 1K words/day per IP — useless at scale. |
| **LibreTranslate self-hosted** | Quality is mediocre; setup overhead; no ICU awareness. |
| **GPT-4o-mini** | Comparable cost + quality, but requires a different SDK + key. |
| **Claude Haiku** | More expensive (~5×) for marginal quality gain on UI strings. |
| **Gemini 3 Flash** | 5-10× more expensive than Flash Lite for negligible quality gain on short UI strings. |
| **✅ Gemini 3.1 Flash Lite** | Cheapest LLM that handles ICU + brand preservation correctly. |

---

## Common pitfalls

### "My ARB key was rejected as invalid"
Flutter `gen-l10n` requires **lowerCamelCase Dart identifiers**. No:
- Leading uppercase: `FooBar` → use `fooBar`
- Leading digits: `1stPlace` → use `firstPlace`
- Hyphens or dots: `my-key`, `my.key` → use `myKey`

### "gen-l10n says 'Found syntax errors'"
A non-en value has unbalanced `{` or `}`. Run:
```bash
python3 scripts/i18n_add_feature.py sanitize-braces
```

### "Analyzer says 'Undefined name arg0' in generated locale .dart"
A translation introduced a placeholder name that doesn't exist in EN. Run:
```bash
python3 scripts/i18n_add_feature.py strip-stray-placeholders
```

### "Translation introduced a wrong placeholder"
Example: `'Set {arg0} of 3'` came back from Japanese as `'セット {arg0} のうち {n}'` (stray `{n}`).

The `strip-stray-placeholders` command catches this and re-mirrors English. Re-run the translation on those cells if you want a proper translation (rare; usually safe to leave as English).

### "Some locales are <85% coverage"
Common locales with this profile: **Tagalog** (Filipino genuinely uses English loanwords for tech/fitness terms), **Dutch** (similar). This is not a bug — it's how those languages are actually spoken. Re-running with more aggressive prompts (see `i18n_translate_gemini_v3.py` example in this repo) can lift them by 5-10pp.

---

## API reference

### `keys` subcommand
```
python3 scripts/i18n_add_feature.py keys --json <path> [--parallel N] [--model MODEL]
```

### `screen` subcommand
```
python3 scripts/i18n_add_feature.py screen --files <path>... [--parallel N] [--model MODEL]
```

### `notification` subcommand
```
python3 scripts/i18n_add_feature.py notification --key KEY --en "ENGLISH" [--model MODEL]
```

### `db` subcommand
```
python3 scripts/i18n_add_feature.py db --table TABLE
```

### `oneshot` subcommand
```
python3 scripts/i18n_add_feature.py oneshot --text "TEXT" [--locales hi,te] [--model MODEL]
```

### `coverage` / `sanitize-braces` / `strip-stray-placeholders`
No arguments. Scan all `app_*.arb` files in the configured `L10N` dir.

---

## Extending the script

The script is single-file by design — easy to copy and adapt.

### Add a new locale
1. Add code to `LOCALES_NON_EN` list.
2. Add `LOCALE_NATIVE[code]` entry with native script in parens.
3. Re-run `keys` or `screen` on existing ARB — it'll backfill the new locale.

### Use a different LLM
The `translate_batch_via_gemini` function takes a `client` arg. Replace it with an OpenAI/Anthropic equivalent. Keep the JSON-mode + system prompt structure; just swap the SDK call.

### Add a new subcommand
Add a `cmd_<name>(args)` function and register it in `build_parser()`. Patterns to copy from existing subcommands:
- Resume-safe writes: load existing data, only modify cells you have new content for.
- Batched Gemini calls: `chunks(d, 80)` + `ThreadPoolExecutor`.
- Quality preservation: pass `preserve_extra` to `translate_batch_via_gemini` for app-specific terms.

---

## License + attribution

Lifted from the Zealova fitness app i18n implementation. Built using `google-genai` SDK.

Free to copy, modify, and use in any project.
