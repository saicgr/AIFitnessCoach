#!/usr/bin/env bash
# Canonical release build for the Zealova consumer flavor.
#
# Why this exists:
#   - RevenueCat keys MUST be passed via --dart-define at build time.
#     Without them, environment_config.dart falls back to
#     "test_key_placeholder" and the paywall shows
#     "Purchase service not configured" — instant Play Store rejection.
#   - The release signingConfig in android/app/build.gradle.kts now fails
#     loudly if signing env vars are missing. This script wires those up.
#
# Required env vars (all four):
#   KEYSTORE_PATH       absolute or relative path to the upload keystore
#                       (default: ../keystores/release.keystore from android/)
#   KEYSTORE_PASSWORD   keystore password
#   KEY_ALIAS           default: fitwiz
#   KEY_PASSWORD        key password (often same as keystore password)
#
# Optional env vars:
#   REVENUECAT_APPLE_KEY  iOS only — fine to leave unset for Android-only builds
#   BACKEND_URL           override the default Render backend URL
#   SUPABASE_URL          override the default Supabase project URL
#   SUPABASE_ANON_KEY     override the default Supabase anon key
#
# Where to find the RevenueCat keys:
#   RevenueCat Dashboard → Project Settings → API Keys
#   - "Public app-specific" key for Android (starts with goog_)
#   - "Public app-specific" key for iOS (starts with appl_)
#   The Google production key is currently goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq.
#
# Tip for shell-special password chars: wrap in single quotes when exporting
#   export KEYSTORE_PASSWORD='p@$$w0rd!'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$FLUTTER_ROOT"

# --- Validate required signing env ----------------------------------------
: "${KEYSTORE_PATH:?KEYSTORE_PATH required (absolute or relative to android/app/). See script header.}"
: "${KEYSTORE_PASSWORD:?KEYSTORE_PASSWORD required.}"
: "${KEY_PASSWORD:?KEY_PASSWORD required.}"
: "${KEY_ALIAS:=fitwiz}"

# Strip any accidental whitespace/newlines from env vars (common copy-paste bug).
KEYSTORE_PASSWORD="$(printf '%s' "$KEYSTORE_PASSWORD" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
KEY_PASSWORD="$(printf '%s' "$KEY_PASSWORD" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
KEY_ALIAS="$(printf '%s' "$KEY_ALIAS" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Pre-flight: keystore file exists?
RESOLVED_KEYSTORE="$KEYSTORE_PATH"
if [[ ! -f "$RESOLVED_KEYSTORE" && -f "android/app/$KEYSTORE_PATH" ]]; then
  RESOLVED_KEYSTORE="android/app/$KEYSTORE_PATH"
fi
if [[ ! -f "$RESOLVED_KEYSTORE" ]]; then
  echo "❌ Keystore not found at: $RESOLVED_KEYSTORE" >&2
  echo "   Set KEYSTORE_PATH to an absolute path or relative-to-android/app/ path." >&2
  exit 1
fi

# Pre-flight: alias actually exists in keystore? (catches the silent
# "wrong alias" gradle failure that surfaces only mid-build).
if command -v keytool >/dev/null 2>&1; then
  if ! keytool -list -keystore "$RESOLVED_KEYSTORE" -storepass "$KEYSTORE_PASSWORD" 2>/dev/null \
       | grep -q "^$KEY_ALIAS,"; then
    echo "⚠️  Alias '$KEY_ALIAS' not found in keystore $RESOLVED_KEYSTORE" >&2
    echo "    Available aliases:" >&2
    keytool -list -keystore "$RESOLVED_KEYSTORE" -storepass "$KEYSTORE_PASSWORD" 2>/dev/null \
      | awk -F',' '/^[^ ]+,/{print "      - " $1}' >&2
    exit 1
  fi
fi

# --- Validate RevenueCat key ----------------------------------------------
# The Google production key is the one currently documented in
# PLAY_STORE_CHECKLIST.md. CI/local can override via env if it ever rotates.
RC_GOOGLE_KEY="${REVENUECAT_GOOGLE_KEY:-goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq}"
RC_GOOGLE_KEY="$(printf '%s' "$RC_GOOGLE_KEY" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
if [[ "$RC_GOOGLE_KEY" == "test_key_placeholder" || -z "$RC_GOOGLE_KEY" ]]; then
  echo "❌ REVENUECAT_GOOGLE_KEY missing or placeholder — refusing to build." >&2
  echo "   Releasing without a real key produces a non-functional paywall." >&2
  exit 1
fi
if [[ ! "$RC_GOOGLE_KEY" =~ ^goog_ ]]; then
  echo "⚠️  REVENUECAT_GOOGLE_KEY does not start with 'goog_' — verify you copied the Android key, not iOS." >&2
fi

# Build the dart-define list. Apple key is optional (not needed for Android).
DART_DEFINES=(
  "--dart-define=ENV=prod"
  "--dart-define=REVENUECAT_GOOGLE_KEY=$RC_GOOGLE_KEY"
)
if [[ -n "${REVENUECAT_APPLE_KEY:-}" ]]; then
  RC_APPLE_KEY="$(printf '%s' "$REVENUECAT_APPLE_KEY" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  DART_DEFINES+=("--dart-define=REVENUECAT_APPLE_KEY=$RC_APPLE_KEY")
fi
[[ -n "${BACKEND_URL:-}" ]] && DART_DEFINES+=("--dart-define=BACKEND_URL=$BACKEND_URL")
[[ -n "${SUPABASE_URL:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
[[ -n "${SUPABASE_ANON_KEY:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")

# Export signing vars for the gradle build (already set, but be explicit so
# we know they survived the env-strip above).
export KEYSTORE_PATH="$RESOLVED_KEYSTORE"
export KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD

echo "== Zealova release build =="
echo "  flutter root : $FLUTTER_ROOT"
echo "  keystore     : $KEYSTORE_PATH"
echo "  alias        : $KEY_ALIAS"
echo "  RC google key: ${RC_GOOGLE_KEY:0:8}…"  # truncated for log safety
echo "  defines      : ${#DART_DEFINES[@]} entries"

flutter build appbundle --release "${DART_DEFINES[@]}"

echo
echo "✅ AAB built at: build/app/outputs/bundle/release/app-release.aab"
echo "   Verify signing:"
echo "     \"\$ANDROID_HOME\"/build-tools/*/apksigner verify --verbose build/app/outputs/bundle/release/app-release.aab"
