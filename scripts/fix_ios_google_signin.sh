#!/usr/bin/env bash
# Regenerate ios/Runner/GoogleService-Info.plist with a valid iOS CLIENT_ID,
# then inject GIDClientID + the REVERSED_CLIENT_ID URL scheme into Info.plist.
#
# Problem this fixes: Sentry FITWIZ-FLUTTER-1W reported a fatal on
# `com.aifitnesscoach.aiFitnessCoach@1.2.55+112` (iPhone18,1):
#   NSInvalidArgumentException: No active configuration.
#   Make sure GIDClientID is set in Info.plist.
# Two-part root cause:
#   1. ios/Runner/Info.plist has no GIDClientID.
#   2. The committed ios/Runner/GoogleService-Info.plist is Android-shaped —
#      it has ANDROID_CLIENT_ID / API_KEY / GCM_SENDER_ID but no CLIENT_ID
#      or REVERSED_CLIENT_ID, so we can't know what to put in Info.plist
#      without regenerating the plist from Firebase.
#
# Requires (install BEFORE running):
#   firebase   `npm install -g firebase-tools` (or `brew install firebase-cli`)
#   gcloud     (only if the Firebase iOS app has no OAuth iOS client yet)
#   plutil     ships with macOS
#   jq         `brew install jq`
#
# Auth:
#   Reuses GOOGLE_APPLICATION_CREDENTIALS from backend/.env
#   (FIREBASE_CREDENTIALS_PATH). Falls back to `firebase login` if the
#   service account lacks Firebase permissions.
#
# Safe: read-only by default. Re-running is idempotent — it removes any
# existing GIDClientID / CFBundleURLTypes entry before re-inserting.

set -euo pipefail

APPLY=${APPLY:-0}
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,28p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$REPO_ROOT/mobile/flutter/ios/Runner/Info.plist"
GSPLIST="$REPO_ROOT/mobile/flutter/ios/Runner/GoogleService-Info.plist"
FIREBASE_PROJECT="aifitnesscoach-5e5d3"
FIREBASE_IOS_APP_ID="1:843677137160:ios:4035cf483000d04a8554bd"
IOS_BUNDLE_ID="com.aifitnesscoach.aiFitnessCoach"

for tool in plutil jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Missing required tool: $tool" >&2
    exit 2
  fi
done

if ! command -v firebase >/dev/null 2>&1; then
  echo "❌ firebase CLI not installed."
  echo "   Install with: npm install -g firebase-tools"
  echo "   Then: firebase login"
  exit 2
fi

# Try to use FIREBASE_CREDENTIALS_PATH from backend/.env if set.
if [[ -f "$REPO_ROOT/backend/.env" ]]; then
  FIREBASE_CREDS_PATH=$(grep -E '^FIREBASE_CREDENTIALS_PATH=' "$REPO_ROOT/backend/.env" | head -n1 | cut -d= -f2- | tr -d '"')
  if [[ -n "$FIREBASE_CREDS_PATH" && -f "$FIREBASE_CREDS_PATH" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$FIREBASE_CREDS_PATH"
    echo "  Using service account: $FIREBASE_CREDS_PATH"
  fi
fi

echo "== Regenerating GoogleService-Info.plist from Firebase =="
TMP_PLIST=$(mktemp -t fitwiz-gsi-plist.XXXXXX.plist)
trap 'rm -f "$TMP_PLIST"' EXIT
firebase apps:sdkconfig ios "$FIREBASE_IOS_APP_ID" --project "$FIREBASE_PROJECT" > "$TMP_PLIST"

# Some firebase CLI versions wrap the plist in a JSON envelope; detect and
# strip if needed.
if head -c1 "$TMP_PLIST" | grep -q '{'; then
  echo "  (firebase CLI returned JSON envelope — extracting .fileContents)"
  jq -r '.fileContents // .sdkConfig // empty' "$TMP_PLIST" > "${TMP_PLIST}.extracted"
  mv "${TMP_PLIST}.extracted" "$TMP_PLIST"
fi

if ! plutil -p "$TMP_PLIST" >/dev/null 2>&1; then
  echo "❌ firebase returned non-plist output:"
  cat "$TMP_PLIST"
  exit 1
fi

CLIENT_ID=$(plutil -extract CLIENT_ID raw "$TMP_PLIST" 2>/dev/null || echo "")
REVERSED=$(plutil -extract REVERSED_CLIENT_ID raw "$TMP_PLIST" 2>/dev/null || echo "")

if [[ -z "$CLIENT_ID" || -z "$REVERSED" ]]; then
  echo "❌ Regenerated plist STILL missing CLIENT_ID/REVERSED_CLIENT_ID."
  echo "   This means no OAuth iOS client is attached to the Firebase iOS app."
  echo
  echo "   To create one programmatically (requires gcloud + Project-Owner IAM):"
  echo
  echo "     gcloud alpha iap oauth-brands list --project=$FIREBASE_PROJECT"
  echo "     # Copy the brand name (projects/<num>/brands/<id>), then:"
  echo "     gcloud alpha iap oauth-clients create <BRAND_NAME> \\"
  echo "       --display_name='FitWiz iOS' \\"
  echo "       --application-type=IOS \\"
  echo "       --ios-bundle-id=$IOS_BUNDLE_ID"
  echo
  echo "   Then re-run this script. The OAuth client will auto-attach to"
  echo "   the Firebase app and appear in apps:sdkconfig output."
  exit 1
fi

echo "  ✅ Got CLIENT_ID=$CLIENT_ID"
echo "  ✅ Got REVERSED_CLIENT_ID=$REVERSED"

if [[ "$APPLY" -eq 0 ]]; then
  echo
  echo "Dry-run mode. Would run:"
  echo "  mv '$TMP_PLIST' '$GSPLIST'"
  echo "  plutil -remove GIDClientID '$PLIST' (if present)"
  echo "  plutil -insert GIDClientID -string '$CLIENT_ID' '$PLIST'"
  echo "  plutil -insert CFBundleURLTypes.1 -json ... '$PLIST'  (appending Google URL scheme)"
  echo
  echo "Re-run with --apply to commit the changes."
  exit 0
fi

echo "== Applying changes =="
mv "$TMP_PLIST" "$GSPLIST"
trap - EXIT
echo "  ✅ Replaced ios/Runner/GoogleService-Info.plist"

# Idempotent plist mutation: remove first, insert second. -remove is a
# no-op when the key doesn't exist (we swallow the error).
plutil -remove GIDClientID "$PLIST" 2>/dev/null || true
plutil -insert GIDClientID -string "$CLIENT_ID" "$PLIST"
echo "  ✅ Info.plist GIDClientID = $CLIENT_ID"

# The existing CFBundleURLTypes[0] is `fitwiz://`. Google's redirect needs
# the REVERSED_CLIENT_ID scheme as an additional CFBundleURLTypes entry.
# We remove any stale Google entry (index 1) first so repeat runs don't
# accumulate duplicates.
#
# plutil index manipulation is fiddly — easiest approach is to use
# PlistBuddy which handles arrays cleanly.
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes:1" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleTypeRole string Editor" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLName string com.google.signin" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes:0 string $REVERSED" "$PLIST"
echo "  ✅ Info.plist CFBundleURLTypes[1] = Google $REVERSED scheme"

echo
echo "Done. Next steps:"
echo "  1. Verify visually: plutil -p '$PLIST' | grep -A8 -E 'GIDClientID|CFBundleURLTypes'"
echo "  2. Clean build: (cd '$REPO_ROOT/mobile/flutter' && flutter clean && flutter build ios --no-codesign --flavor consumer)"
echo "  3. Run on device/simulator and tap 'Continue with Google' — should show Google sheet, not crash."
echo "  4. Bump ios CFBundleVersion, rebuild release, re-ship."
