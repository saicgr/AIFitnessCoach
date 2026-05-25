#!/usr/bin/env python3
"""
i18n_add_keys.py — bulk add new keys to every .arb file under mobile/flutter/lib/l10n/.

For each key the caller adds the English string in `KEYS` below. The script:
  - Adds the key + English value to app_en.arb (idempotent; skip if present).
  - Adds the same key to each non-English locale, copying the English value
    AND prepending an "[en] " prefix so QA + locale translators can spot
    untranslated keys at a glance during the in-app preview.

This is the pragmatic "ship infrastructure now, refine translations per PR"
pattern documented in docs/WORKOUTS_OVERHAUL_IMPLEMENTATION.md. Native-speaker
translators replace the "[en] foo" placeholder with their language's value
later; Flutter's gen-l10n bakes whatever value is present at build time.

Run from repo root:
    python3 scripts/i18n_add_keys.py

Then regenerate the dart code:
    cd mobile/flutter && flutter gen-l10n
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# ─── NEW KEYS ─────────────────────────────────────────────────────────────
# Add new keys here; rerun the script. Idempotent — re-running won't dupe.
KEYS: dict[str, str] = {
    # Bottom nav (most-visible always-on-screen labels)
    "navWorkout": "Workout",          # singular — matches main_shell label
    "navDiscover": "Discover",
    "navYou": "You",
    # Common UI primitives
    "commonOk": "OK",
    "commonClose": "Close",
    "commonEdit": "Edit",
    "commonShare": "Share",
    "commonNext": "Next",
    "commonBack": "Back",
    "commonDone": "Done",
    "commonYes": "Yes",
    "commonNo": "No",
    "commonError": "Error",
    "commonLoading": "Loading…",
    # Auth entry
    "authWelcomeTitle": "Welcome to Zealova",
    "authWelcomeSubtitle": "Your AI fitness coach",
    "authSignIn": "Sign in",
    "authSignUp": "Sign up",
    "authEmailHint": "Email",
    "authPasswordHint": "Password",
    "authContinueWithEmail": "Continue with email",
    "authContinueWithApple": "Continue with Apple",
    "authContinueWithGoogle": "Continue with Google",
    # Settings index
    "settingsAccountSection": "Account",
    "settingsAppSection": "App",
    "settingsTrainingSection": "Training",
    "settingsNutritionSection": "Nutrition",
    "settingsPrivacySection": "Privacy",
    "settingsAboutSection": "About",
    "settingsHelpSection": "Help",
    "settingsLogout": "Sign out",
    "settingsThemeMode": "Theme",
    "settingsThemeSystem": "System",
    "settingsThemeLight": "Light",
    "settingsThemeDark": "Dark",
    # Onboarding entry
    "onboardingGetStarted": "Get started",
    "onboardingAlreadyHaveAccount": "I already have an account",
    "onboardingContinueButton": "Continue",
    "onboardingSkip": "Skip",
    # Home headers / tab headers (also reused on many other screens)
    "homeTodaysWorkout": "Today's workout",
    "homeTodaysNutrition": "Today's nutrition",
    "homeQuickActions": "Quick actions",
    "homeStartWorkout": "Start workout",
    "homeLogMeal": "Log a meal",
    "homeScanFood": "Scan food",
    "homeMore": "More",
    # Workout shell
    "workoutListTitle": "Workouts",
    "workoutGenerate": "Generate workout",
    "workoutHistory": "History",
    "workoutFavourites": "Favourites",
    # Nutrition shell
    "nutritionDailyTab": "Daily",
    "nutritionRecipesTab": "Recipes",
    "nutritionPatternsTab": "Patterns",
    "nutritionLogFood": "Log food",
    # Progress / You shell
    "youTrophies": "Trophies",
    "youAchievements": "Achievements",
    "youSkills": "Skills",
    "youWrapped": "Wrapped",
    # Discover
    "discoverFeed": "Feed",
    "discoverFriends": "Friends",
    "discoverChallenges": "Challenges",
    # Notifications + permissions onboarding
    "notifsPrimerTitle": "Stay on track",
    "notifsPrimerBody": "Get reminders for your workouts and check-ins.",
    "notifsAllowButton": "Allow notifications",
    "notifsLaterButton": "Maybe later",
    # Coming soon
    "comingSoonTitle": "Coming soon",
    "comingSoonBody": "We're working on this feature. Stay tuned.",
    # Auth intro
    "authBuildMyPlan": "Build My Plan",
    "authIntroExercises": "Exercises",
    "authIntroFoods": "Foods",
    "authIntroAiCoach": "AI Coach",
}


L10N_DIR = Path(__file__).resolve().parent.parent / "mobile" / "flutter" / "lib" / "l10n"
EN_FILE = L10N_DIR / "app_en.arb"
# 2026-05-24: removed `[en] ` prefix per user feedback (visible UI leak).
# Non-en locales get the clean English value as a placeholder; `i18n_fill_translations.py`
# fills in the real translation. `i18n_coverage_check.py` is the gate that
# refuses to ship if any cell is still the English placeholder.
PLACEHOLDER_PREFIX = ""


def _load_keys_from_arg() -> dict[str, str]:
    """Load keys-to-add from --keys-file JSON arg, else fall back to inline KEYS dict.

    The --keys-file path is a JSON of {key: english_value} (e.g. output of
    i18n_migrate_all.py --dry-run → reports/i18n_keys.json).
    """
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--keys-file", type=Path, default=None)
    args, _ = ap.parse_known_args()
    if args.keys_file:
        if not args.keys_file.exists():
            print(f"❌ {args.keys_file} not found", file=sys.stderr)
            sys.exit(1)
        with args.keys_file.open() as f:
            data = json.load(f)
        if not isinstance(data, dict):
            print(f"❌ {args.keys_file} must be a JSON object {{key: english_value}}",
                  file=sys.stderr)
            sys.exit(1)
        return data
    return KEYS


def main() -> int:
    if not L10N_DIR.exists():
        print(f"❌ {L10N_DIR} does not exist", file=sys.stderr)
        return 1

    arb_files = sorted(L10N_DIR.glob("app_*.arb"))
    if not arb_files:
        print(f"❌ no .arb files in {L10N_DIR}", file=sys.stderr)
        return 1

    keys_to_add = _load_keys_from_arg()
    print(f"Found {len(arb_files)} locale files. Adding {len(keys_to_add)} key(s)…")

    added_per_locale: dict[str, int] = {}
    for arb in arb_files:
        with arb.open("r", encoding="utf-8") as f:
            data = json.load(f)
        is_en = arb.name == "app_en.arb"
        added = 0
        for key, value in keys_to_add.items():
            if key in data:
                continue
            if is_en:
                data[key] = value
            else:
                data[key] = f"{PLACEHOLDER_PREFIX}{value}"
            added += 1
        if added > 0:
            # Preserve the @@-prefixed metadata keys + write back stably.
            with arb.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        added_per_locale[arb.name] = added

    for fname, n in added_per_locale.items():
        marker = "  " if n == 0 else "✓ "
        print(f"  {marker}{fname:30s} +{n} key(s)")
    print("\nNext: cd mobile/flutter && flutter gen-l10n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
