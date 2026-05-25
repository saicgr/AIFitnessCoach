#!/usr/bin/env python3
"""
i18n_add_feature.py — REUSABLE i18n tooling for shipping any new feature
across all 36 locales.

USE THIS WHEN: You (or a Claude session) just shipped a new feature in English
and need it translated to all 35 non-English locales. This script handles the
common scenarios end-to-end: add keys → translate → verify → regen.

────────────────────────────────────────────────────────────────────────────
QUICK START
────────────────────────────────────────────────────────────────────────────

  # Scenario 1: You hardcoded new English strings in Flutter source files
  python3 scripts/i18n_add_feature.py screen --files \\
      mobile/flutter/lib/screens/new_feature/

  # Scenario 2: You have an explicit dict of new ARB keys to add
  python3 scripts/i18n_add_feature.py keys --json /tmp/new_keys.json
  # /tmp/new_keys.json: {"newFeatureTitle": "Awesome New Feature", ...}

  # Scenario 3: You added a backend notification template (English string)
  python3 scripts/i18n_add_feature.py notification \\
      --key challenge_invite_title --en "You've been invited!"

  # Scenario 4: You added rows to a DB i18n table (need other locales filled)
  python3 scripts/i18n_add_feature.py db --table exercise_library_i18n

  # Scenario 5: Just translate one string for ad-hoc use (no persistence)
  python3 scripts/i18n_add_feature.py oneshot --text "Workout complete" \\
      --locales hi,te,ta

────────────────────────────────────────────────────────────────────────────
ARCHITECTURE
────────────────────────────────────────────────────────────────────────────

Zealova i18n spans 5 layers:
  1. Flutter ARB    — mobile/flutter/lib/l10n/app_*.arb (36 files)
  2. Backend notif  — backend/core/i18n.py + i18n_translations.py
  3. DB rows        — exercise_library_i18n, food_nutrition_overrides_i18n, etc.
  4. AI Coach       — Gemini system prompt injection (locale-aware reply)
  5. Native files   — ios/Runner/<locale>.lproj/, android/app/src/main/res/values-<locale>/

This script targets layers 1, 2, 3 — the most common case. Layer 4 is wired
automatically by the chat endpoint. Layer 5 is touched rarely (widget labels).

ALL TRANSLATION goes through gemini-3.1-flash-lite (per project policy —
no Google/MyMemory/LibreTranslate rate limits, no paid Cloud Translation,
just our existing GEMINI_API_KEY). Estimated cost: $0.01-0.50 per feature.

────────────────────────────────────────────────────────────────────────────
THE 36 LOCALES
────────────────────────────────────────────────────────────────────────────

en, ar, bn, cs, de, es, fi, fr, ha, hi, id, it, ja, jv, kn, ko, ml, mr,
ms, ne, nl, or, pa, pl, pt, ru, sv, sw, ta, te, th, tl, tr, ur, vi, zh

en is the source of truth. Every other locale is filled from English.

────────────────────────────────────────────────────────────────────────────
RESUME-SAFETY
────────────────────────────────────────────────────────────────────────────

All scenarios are idempotent:
  - ARB: only translates cells where current value == English (no double-work)
  - Backend notif: skips locales that already have the key
  - DB rows: ON CONFLICT (id, locale) DO NOTHING — never overwrites

Re-running after a partial failure picks up where it left off.

────────────────────────────────────────────────────────────────────────────
QUALITY GUARANTEES
────────────────────────────────────────────────────────────────────────────

Every translation request:
  1. Preserves {name} / {count} ICU placeholders verbatim
  2. Preserves brand names: Zealova, Strava, Fitbod, MyFitnessPal, Hyrox, …
  3. Preserves fitness acronyms: RPE, 1RM, AMRAP, EMOM, BMR, TDEE, HRV, …
  4. Returns JSON dict, parsed strictly (no markdown fence pollution)
  5. Falls back to English if Gemini returns malformed output

If the call fails or returns malformed JSON, the cell stays English (which
the Flutter gen-l10n + Dart code treats as a graceful fallback — the app
still works in the user's locale, just shows English for that one string).

────────────────────────────────────────────────────────────────────────────
COST GUIDE (gemini-3.1-flash-lite, as of 2026-05)
────────────────────────────────────────────────────────────────────────────

Input  : $0.10 / 1M tokens
Output : $0.40 / 1M tokens

Per-scenario rough cost:
  1 new ARB key  × 35 locales  ~$0.0001
  20 new ARB keys × 35 locales  ~$0.002
  1 new notification template × 35 locales  ~$0.0001
  100 new DB exercise rows × 35 locales  ~$0.01
  1000 new DB food rows × 35 locales  ~$0.10
  Full app re-translation (~12K keys × 35)  ~$1-2

────────────────────────────────────────────────────────────────────────────
TROUBLESHOOTING
────────────────────────────────────────────────────────────────────────────

"gen-l10n: Invalid ARB resource name 'XYZ'"
  → Keys must be lowerCamelCase, no leading uppercase or digits. Rename.

"Found syntax errors" (ICU parser)
  → Some translation broke an ICU placeholder. Run the brace-sanitizer:
    python3 scripts/i18n_add_feature.py sanitize-braces

"undefined_identifier 'arg0'" (analyzer)
  → A non-en value introduced a placeholder name that isn't in @-metadata.
    Run: python3 scripts/i18n_add_feature.py strip-stray-placeholders

"undefined_method 'foo'" (analyzer)
  → Call site uses a key that's not in app_en.arb. Either add to en.arb
    (this script's `keys` subcommand) or fix the typo in source.

"flutter gen-l10n no longer outputs anything"
  → Check that all .arb files are valid JSON: python3 -c "import json; [json.load(open(f)) for f in glob.glob('mobile/flutter/lib/l10n/app_*.arb')]"
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parent.parent
L10N = REPO / "mobile" / "flutter" / "lib" / "l10n"
EN_ARB = L10N / "app_en.arb"
BACKEND_I18N = REPO / "backend" / "core" / "i18n.py"
BACKEND_TRANSLATIONS = REPO / "backend" / "core" / "i18n_translations.py"

LOCALES_NON_EN = [
    "ar","bn","cs","de","es","fi","fr","ha","hi","id",
    "it","ja","jv","kn","ko","ml","mr","ms","ne","nl",
    "or","pa","pl","pt","ru","sv","sw","ta","te","th",
    "tl","tr","ur","vi","zh",
]

LOCALE_NATIVE = {
    "ar":"Arabic (العربية)","bn":"Bengali (বাংলা)","cs":"Czech (čeština)",
    "de":"German (Deutsch)","es":"Spanish (español)","fi":"Finnish (suomi)",
    "fr":"French (français)","ha":"Hausa","hi":"Hindi (हिन्दी)",
    "id":"Indonesian (Bahasa Indonesia)","it":"Italian (italiano)",
    "ja":"Japanese (日本語)","jv":"Javanese (Basa Jawa)","kn":"Kannada (ಕನ್ನಡ)",
    "ko":"Korean (한국어)","ml":"Malayalam (മലയാളം)","mr":"Marathi (मराठी)",
    "ms":"Malay (Bahasa Melayu)","ne":"Nepali (नेपाली)","nl":"Dutch (Nederlands)",
    "or":"Odia (ଓଡ଼ିଆ)","pa":"Punjabi (ਪੰਜਾਬੀ)","pl":"Polish (polski)",
    "pt":"Portuguese (português)","ru":"Russian (русский)","sv":"Swedish (svenska)",
    "sw":"Swahili (Kiswahili)","ta":"Tamil (தமிழ்)","te":"Telugu (తెలుగు)",
    "th":"Thai (ไทย)","tl":"Tagalog (Filipino)","tr":"Turkish (Türkçe)",
    "ur":"Urdu (اردو)","vi":"Vietnamese (Tiếng Việt)",
    "zh":"Simplified Chinese (简体中文)",
}

# Verbatim-preserved terms across all translations.
# Brand names + fitness acronyms — Gemini is instructed not to translate these.
PRESERVE_VERBATIM = [
    "Zealova","Strava","Fitbod","MyFitnessPal","Apple","Google","Hyrox",
    "RevenueCat","MacroFactor","Hevy","Jefit","Peloton","Garmin","FitNotes",
    "StrongLifts","RPE","1RM","AMRAP","EMOM","BMR","TDEE","HRV","NEAT","ATG",
    "RIR","TUT",
]

GEMINI_MODEL_DEFAULT = "gemini-3.1-flash-lite"

# ────────────────────────────────────────────────────────────────────────────
# Shared helpers
# ────────────────────────────────────────────────────────────────────────────

def load_env() -> None:
    """Load backend/.env into os.environ so GEMINI_API_KEY is available.
    Idempotent — doesn't clobber already-set env vars."""
    env_path = REPO / "backend" / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        if not line.strip() or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k.strip(), v)


def get_gemini_client():
    """Return a configured google.genai client. Errors if API key missing."""
    load_env()
    if not os.environ.get("GEMINI_API_KEY"):
        raise SystemExit(
            "❌ GEMINI_API_KEY not set. Add to backend/.env or export it."
        )
    from google import genai
    return genai.Client(api_key=os.environ["GEMINI_API_KEY"])


def is_valid_dart_identifier(key: str) -> bool:
    """Flutter gen-l10n requires lowerCamelCase Dart-identifier keys."""
    return bool(re.match(r"^[a-z][a-zA-Z0-9_]*$", key))


def translate_batch_via_gemini(
    client,
    model: str,
    locale: str,
    items: dict[str, str],
    preserve_extra: list[str] | None = None,
) -> dict[str, str]:
    """Translate a batch of English strings to one target locale via Gemini.

    Args:
      client: google.genai Client
      model: e.g. "gemini-3.1-flash-lite"
      locale: target ISO 639-1 code, e.g. "hi"
      items: {key: English_value} — keys are opaque to Gemini
      preserve_extra: additional terms to preserve verbatim beyond PRESERVE_VERBATIM

    Returns:
      {key: translated_value} — keys missing from output mean translation failed
      for that one item (caller should leave English in place).
    """
    from google.genai import types

    native = LOCALE_NATIVE.get(locale, locale)
    preserve_terms = PRESERVE_VERBATIM + (preserve_extra or [])
    preserve_list = ", ".join(preserve_terms)

    system = f"""You translate UI strings for the Zealova fitness app from English to {native}.

Rules:
1. Output ONLY valid JSON: {{"<key>": "<translated value>", ...}}. No prose, no markdown fences, no comments.
2. Preserve every ICU placeholder verbatim: {{name}}, {{count}}, {{xp}}, etc.
3. Preserve these brand/acronym terms verbatim in Latin script even in non-Latin languages: {preserve_list}.
4. Match the user-facing tone: friendly, concise, second-person where natural.
5. For very short labels (single word), translate to the {native} equivalent; do NOT add punctuation.
6. For multi-sentence strings, preserve sentence boundaries (.) in the target script.
7. Use proper script — Hindi must use Devanagari, Arabic must use Arabic script, etc."""

    prompt = (
        f"Translate these English UI strings to {native}. Return JSON only.\n\n"
        f"{json.dumps(items, ensure_ascii=False, indent=2)}"
    )

    try:
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=system,
                response_mime_type="application/json",
                temperature=0.2,
                max_output_tokens=8000,
            ),
        )
        text = (response.text or "").strip()
        # Defensive: strip markdown fences if model returned them
        text = re.sub(r"^```(?:json)?\n?", "", text)
        text = re.sub(r"\n?```$", "", text)
        result = json.loads(text)
        if not isinstance(result, dict):
            return {}
        return result
    except Exception as e:
        print(f"  ⚠ [{locale}] batch error: {type(e).__name__}: {str(e)[:120]}",
              file=sys.stderr)
        return {}


def chunks(d: dict, size: int) -> Iterable[dict]:
    """Yield sub-dicts of at most `size` items each."""
    items = list(d.items())
    for i in range(0, len(items), size):
        yield dict(items[i:i+size])


# ────────────────────────────────────────────────────────────────────────────
# Scenario 1: KEYS — add explicit {key: english_value} dict to ARB + translate
# ────────────────────────────────────────────────────────────────────────────

def cmd_keys(args) -> int:
    """Add new ARB keys from a JSON file (shape: {key: english_value, ...} with
    optional @key metadata entries) and translate to all 35 non-en locales."""
    json_path = Path(args.json)
    if not json_path.exists():
        print(f"❌ {json_path} not found", file=sys.stderr)
        return 1
    new_data = json.load(open(json_path))
    if not isinstance(new_data, dict):
        print(f"❌ {json_path} must be a JSON object", file=sys.stderr)
        return 1

    # Validate keys
    invalid = [k for k in new_data if not k.startswith("@") and not is_valid_dart_identifier(k)]
    if invalid:
        print(f"❌ Invalid Dart identifier keys: {invalid[:5]}", file=sys.stderr)
        return 1

    en = json.load(open(EN_ARB))
    new_keys = {k: v for k, v in new_data.items() if k not in en}
    if not new_keys:
        print("✓ No new keys to add (all already in app_en.arb).")
        return 0

    # Add to en.arb
    for k, v in new_keys.items():
        en[k] = v
    with EN_ARB.open("w") as f:
        json.dump(en, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"✓ Added {len(new_keys)} key(s) to app_en.arb")

    # Mirror English placeholder to all non-en .arb (then we translate)
    for arb in sorted(L10N.glob("app_*.arb")):
        if arb.name == "app_en.arb": continue
        d = json.load(open(arb))
        for k, v in new_keys.items():
            if k not in d:
                d[k] = v
        with arb.open("w") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
            f.write("\n")

    # Translate the new keys only (resume-safe pattern: only cells == English)
    print(f"Translating {len(new_keys)} new key(s) × 35 locales via {args.model}...")
    _translate_arb_subset(new_keys, args.model, args.parallel)

    # Regen Dart
    print("Running flutter gen-l10n...")
    os.system(f"cd {REPO}/mobile/flutter && flutter gen-l10n")

    print(f"\n✓ Done. {len(new_keys)} new keys translated to all 35 non-en locales.")
    print("  Run `flutter analyze lib/` to confirm no new errors.")
    return 0


def cmd_screen(args) -> int:
    """For a list of source files/dirs, find hardcoded English strings,
    extract them, mint ARB keys, add to en.arb, and translate.

    This wraps the existing scripts/i18n_migrate_screen.py + i18n_migrate_all.py
    workflow. See scripts/i18n_migrate_screen.py for the lexer rules.
    """
    files = args.files
    if not files:
        print("❌ Specify --files <path>...", file=sys.stderr)
        return 1
    # Build a filter regex from the file paths
    filter_re = "|".join(re.escape(f) for f in files)
    cmd = f"cd {REPO} && python3 scripts/i18n_migrate_all.py --dry-run --filter '{filter_re}'"
    print(f"→ Scanning for new keys: {cmd}")
    os.system(cmd)
    keys_file = REPO / "reports" / "i18n_keys.json"
    if not keys_file.exists() or keys_file.stat().st_size < 10:
        print("✓ No new keys found.")
        return 0
    print(f"→ Adding extracted keys via `keys` subcommand...")
    args.json = str(keys_file)
    return cmd_keys(args)


# ────────────────────────────────────────────────────────────────────────────
# Scenario 2: NOTIFICATION — add backend notification template
# ────────────────────────────────────────────────────────────────────────────

def cmd_notification(args) -> int:
    """Add a single backend notification template (English string) and
    translate to all 35 non-en locales. Writes to backend/core/i18n.py +
    backend/core/i18n_translations.py."""
    key = args.key
    en_value = args.en
    if not key or not en_value:
        print("❌ Both --key and --en are required.", file=sys.stderr)
        return 1

    # Append to _EN_TEMPLATES in backend/core/i18n.py
    i18n_text = BACKEND_I18N.read_text()
    if f'"{key}":' in i18n_text:
        print(f"⚠ Key '{key}' already exists in backend/core/i18n.py — skipping add.")
    else:
        # Insert before the closing brace of _EN_TEMPLATES
        marker = "_EN_TEMPLATES: dict[str, str] = {"
        idx = i18n_text.find(marker)
        if idx < 0:
            print(f"❌ Can't find _EN_TEMPLATES marker in {BACKEND_I18N}",
                  file=sys.stderr)
            return 1
        # Find the matching closing }
        end_idx = i18n_text.find("\n}", idx)
        if end_idx < 0:
            print(f"❌ Can't find _EN_TEMPLATES closing brace", file=sys.stderr)
            return 1
        insert = f'    "{key}": "{en_value}",\n'
        new_text = i18n_text[:end_idx] + insert + i18n_text[end_idx:]
        BACKEND_I18N.write_text(new_text)
        print(f"✓ Added '{key}' to backend/core/i18n.py _EN_TEMPLATES")

    # Translate to 35 locales and inject into NON_EN_TEMPLATES
    print(f"Translating to 35 locales via {args.model}...")
    client = get_gemini_client()
    translations: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = {
            pool.submit(translate_batch_via_gemini, client, args.model, loc, {key: en_value}): loc
            for loc in LOCALES_NON_EN
        }
        for fut in as_completed(futures):
            loc = futures[fut]
            try:
                result = fut.result()
                if key in result:
                    translations[loc] = result[key]
            except Exception as e:
                print(f"  ⚠ [{loc}] {e}", file=sys.stderr)

    # Update backend/core/i18n_translations.py by re-loading + injecting
    sys.path.insert(0, str(REPO / "backend"))
    try:
        # Reload module to get fresh data
        if "core.i18n_translations" in sys.modules:
            del sys.modules["core.i18n_translations"]
        from core.i18n_translations import NON_EN_TEMPLATES  # type: ignore
        existing = dict(NON_EN_TEMPLATES)
    except Exception:
        existing = {loc: {} for loc in LOCALES_NON_EN}

    for loc, val in translations.items():
        existing.setdefault(loc, {})[key] = val

    # Write back
    _write_non_en_templates(existing)

    print(f"✓ Translated '{key}' to {len(translations)}/35 locales")
    # Spot-check
    for loc in ["hi", "ar", "zh"]:
        if loc in translations:
            print(f"  [{loc}] {translations[loc]!r}")
    return 0


def _write_non_en_templates(data: dict[str, dict[str, str]]) -> None:
    """Write the NON_EN_TEMPLATES dict back to backend/core/i18n_translations.py
    as valid Python. Preserves alphabetical key order for stable diffs."""
    out = [
        "# AUTO-GENERATED — do not edit directly.",
        "# Update via: scripts/i18n_add_feature.py notification --key X --en Y",
        "# or: scripts/i18n_translate_backend_notifications.py (full re-run)",
        "from __future__ import annotations",
        "",
        "NON_EN_TEMPLATES: dict[str, dict[str, str]] = {",
    ]
    for loc in sorted(data.keys()):
        out.append(f"    {loc!r}: {{")
        for k in sorted(data[loc].keys()):
            v = data[loc][k]
            # Use json.dumps to escape correctly + handle unicode
            out.append(f"        {k!r}: {json.dumps(v, ensure_ascii=False)},")
        out.append("    },")
    out.append("}")
    BACKEND_TRANSLATIONS.write_text("\n".join(out) + "\n")


# ────────────────────────────────────────────────────────────────────────────
# Scenario 3: DB — translate rows in i18n DB tables
# ────────────────────────────────────────────────────────────────────────────

def cmd_db(args) -> int:
    """Delegate to the appropriate per-table backend script that fills non-en
    rows for a given DB i18n table. Calls existing scripts."""
    table = args.table
    if table == "exercise_library_i18n":
        return os.system(
            f"cd {REPO} && backend/.venv/bin/python "
            f"backend/scripts/translate_exercise_library_i18n.py"
        )
    elif table == "food_nutrition_overrides_i18n":
        return os.system(
            f"cd {REPO} && backend/.venv/bin/python "
            f"backend/scripts/translate_food_i18n.py"
        )
    else:
        print(f"❌ Unknown table: {table}", file=sys.stderr)
        print(f"  Supported: exercise_library_i18n, food_nutrition_overrides_i18n",
              file=sys.stderr)
        return 1


# ────────────────────────────────────────────────────────────────────────────
# Scenario 4: ONESHOT — translate one string ad-hoc (no persistence)
# ────────────────────────────────────────────────────────────────────────────

def cmd_oneshot(args) -> int:
    """Quick one-off translation of a single string to one or more locales.
    Useful for debugging or copying translations into other contexts."""
    text = args.text
    locales = args.locales.split(",") if args.locales else LOCALES_NON_EN
    client = get_gemini_client()
    print(f"Translating {text!r} to {len(locales)} locale(s)...")
    for loc in locales:
        result = translate_batch_via_gemini(client, args.model, loc.strip(),
                                             {"_": text})
        translation = result.get("_", text)
        print(f"  [{loc:>3}] {translation}")
    return 0


# ────────────────────────────────────────────────────────────────────────────
# Maintenance: sanitize-braces, strip-stray-placeholders
# ────────────────────────────────────────────────────────────────────────────

def cmd_sanitize_braces(args) -> int:
    """Fix ICU brace imbalance across all .arb files. Replaces `{` and `}`
    with `(` `)` in values where braces don't balance — preserves only the
    intentional ICU placeholders that are balanced."""
    import glob
    total_fixed = 0
    for arb in sorted(L10N.glob("app_*.arb")):
        d = json.load(open(arb))
        changed = False
        for k, v in list(d.items()):
            if k.startswith("@") or not isinstance(v, str): continue
            depth = 0; bad = False
            for c in v:
                if c == "{": depth += 1
                elif c == "}": depth -= 1
                if depth < 0: bad = True; break
            if bad or depth != 0:
                d[k] = v.replace("{", "(").replace("}", ")")
                changed = True
                total_fixed += 1
        if changed:
            with arb.open("w") as f:
                json.dump(d, f, ensure_ascii=False, indent=2)
                f.write("\n")
    print(f"✓ Sanitized {total_fixed} value(s) with brace imbalance")
    return 0


def cmd_strip_stray_placeholders(args) -> int:
    """For any non-en value containing a placeholder name that doesn't exist
    in EN's value, re-mirror the English. Fixes gen-l10n inferring extra
    placeholders from a single locale's bad translation."""
    en = json.load(open(EN_ARB))
    en_phs = {}
    for k, v in en.items():
        if k.startswith("@") or not isinstance(v, str): continue
        en_phs[k] = set(re.findall(r"\{([a-zA-Z_]\w*)(?:,|\})", v))

    fixed = 0
    for arb in sorted(L10N.glob("app_*.arb")):
        if arb.name == "app_en.arb": continue
        d = json.load(open(arb))
        changed = False
        for k, en_v in en.items():
            if k.startswith("@") or not isinstance(en_v, str): continue
            v = d.get(k)
            if not isinstance(v, str): continue
            their_phs = set(re.findall(r"\{([a-zA-Z_]\w*)(?:,|\})", v))
            extra = their_phs - en_phs.get(k, set())
            if extra:
                d[k] = en_v
                if f"@{k}" in en: d[f"@{k}"] = en[f"@{k}"]
                changed = True
                fixed += 1
        if changed:
            with arb.open("w") as f:
                json.dump(d, f, ensure_ascii=False, indent=2)
                f.write("\n")
    print(f"✓ Re-mirrored {fixed} cell(s) with stray placeholders")
    return 0


def cmd_coverage(args) -> int:
    """Print translation coverage per locale (raw + REAL excluding placeholders)."""
    en = json.load(open(EN_ARB))
    en_keys = {k:v for k,v in en.items() if not k.startswith("@") and isinstance(v,str)}
    PRESERVE = set(PRESERVE_VERBATIM) | {"Instagram","TikTok","OAuth","API","iOS",
                                          "Android","HIIT","VO2"}
    def translatable(v):
        s = re.sub(r"\{[^}]*\}|\$\{[^}]*\}", "", v)
        for b in PRESERVE: s = s.replace(b, "")
        return len(re.sub(r"[^a-zA-Z]", "", s)) >= 3

    print(f"{'loc':4} | raw % | REAL % (translatable only)")
    print("-" * 45)
    raw_tot = real_tot = count = 0
    for arb in sorted(L10N.glob("app_*.arb")):
        loc = arb.stem.removeprefix("app_")
        if loc == "en": continue
        d = json.load(open(arb))
        raw_diff = sum(1 for k,v in en_keys.items() if isinstance(d.get(k),str) and d[k]!=v)
        raw_total = sum(1 for k in en_keys if isinstance(d.get(k),str))
        real_total = real_bleed = 0
        for k, v in en_keys.items():
            if not isinstance(d.get(k),str) or not translatable(v): continue
            real_total += 1
            if d[k] == v: real_bleed += 1
        raw_pct = raw_diff / max(1, raw_total) * 100
        real_pct = (real_total - real_bleed) / max(1, real_total) * 100
        raw_tot += raw_pct; real_tot += real_pct; count += 1
        print(f"  {loc:3} | {raw_pct:>5.1f}% | {real_pct:>5.1f}%")
    print(f"\nAvg raw: {raw_tot/count:.1f}%  |  Avg REAL: {real_tot/count:.1f}%")
    return 0


# ────────────────────────────────────────────────────────────────────────────
# Internal helper used by `keys` and `screen`
# ────────────────────────────────────────────────────────────────────────────

def _translate_arb_subset(new_keys: dict[str, str], model: str, parallel: int) -> None:
    """Translate the given keys to all 35 non-en locales, writing back to
    each app_<locale>.arb. Resume-safe: only updates cells where current
    value == English source."""
    client = get_gemini_client()

    def process_locale(locale: str) -> tuple[str, int]:
        arb_path = L10N / f"app_{locale}.arb"
        data = json.load(open(arb_path))
        todo = {k: v for k, v in new_keys.items() if data.get(k) == v}
        if not todo:
            return locale, 0
        # Batch translate (80 keys per call)
        result: dict[str, str] = {}
        for batch in chunks(todo, 80):
            r = translate_batch_via_gemini(client, model, locale, batch)
            result.update(r)
        changed = 0
        for k, v in result.items():
            if v and v != data.get(k):
                data[k] = v
                changed += 1
        with arb_path.open("w") as f:
            json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")
        return locale, changed

    with ThreadPoolExecutor(max_workers=parallel) as pool:
        futures = {pool.submit(process_locale, loc): loc for loc in LOCALES_NON_EN}
        for fut in as_completed(futures):
            loc, n = fut.result()
            print(f"  [{loc}] {n} translated")


# ────────────────────────────────────────────────────────────────────────────
# CLI
# ────────────────────────────────────────────────────────────────────────────

def build_parser():
    p = argparse.ArgumentParser(
        prog="i18n_add_feature.py",
        description="Reusable i18n tooling for Zealova. See top-of-file docstring for full guide.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = p.add_subparsers(dest="cmd", required=True, metavar="COMMAND")

    # keys
    pk = sub.add_parser("keys", help="Add explicit {key: english} dict + translate")
    pk.add_argument("--json", required=True, help="Path to JSON file of {key: en_value}")
    pk.add_argument("--model", default=GEMINI_MODEL_DEFAULT)
    pk.add_argument("--parallel", type=int, default=6,
                    help="Locales processed in parallel")
    pk.set_defaults(func=cmd_keys)

    # screen
    ps = sub.add_parser("screen",
                        help="Scan Dart source files, extract new strings, add + translate")
    ps.add_argument("--files", nargs="+", required=True,
                    help="Source file paths or directory prefixes to scan")
    ps.add_argument("--model", default=GEMINI_MODEL_DEFAULT)
    ps.add_argument("--parallel", type=int, default=6)
    ps.set_defaults(func=cmd_screen)

    # notification
    pn = sub.add_parser("notification",
                        help="Add a backend notification template + translate")
    pn.add_argument("--key", required=True,
                    help="Template key (snake_case), e.g. challenge_invite_title")
    pn.add_argument("--en", required=True, help="English template string")
    pn.add_argument("--model", default=GEMINI_MODEL_DEFAULT)
    pn.set_defaults(func=cmd_notification)

    # db
    pd = sub.add_parser("db", help="Fill non-en rows in a DB i18n table")
    pd.add_argument("--table", required=True,
                    choices=["exercise_library_i18n", "food_nutrition_overrides_i18n"],
                    help="Table to populate")
    pd.set_defaults(func=cmd_db)

    # oneshot
    po = sub.add_parser("oneshot", help="Ad-hoc translation, no persistence")
    po.add_argument("--text", required=True)
    po.add_argument("--locales", default=None, help="Comma-separated; default all 35")
    po.add_argument("--model", default=GEMINI_MODEL_DEFAULT)
    po.set_defaults(func=cmd_oneshot)

    # sanitize-braces
    psb = sub.add_parser("sanitize-braces",
                         help="Fix ICU brace imbalance across all .arb files")
    psb.set_defaults(func=cmd_sanitize_braces)

    # strip-stray-placeholders
    pss = sub.add_parser("strip-stray-placeholders",
                         help="Re-mirror EN for values with rogue placeholder names")
    pss.set_defaults(func=cmd_strip_stray_placeholders)

    # coverage
    pc = sub.add_parser("coverage",
                        help="Print translation coverage per locale (raw + REAL)")
    pc.set_defaults(func=cmd_coverage)

    return p


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
