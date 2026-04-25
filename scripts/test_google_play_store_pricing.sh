#!/usr/bin/env bash
#
# test_google_play_store_pricing.sh — exercise FitWiz subscription state
# end-to-end without uploading a build to the Play Store.
#
# Companion to scripts/verify_revenuecat_offerings.sh:
#   - verify_revenuecat_offerings.sh  → audits the OFFERING/PACKAGE config
#                                        ($rc_annual ↔ premium_yearly etc.)
#   - test_google_play_store_pricing.sh → simulates RUNTIME state
#                                        (grant entitlement, fire webhook,
#                                         inspect a subscriber, revoke).
#
# Modes:
#   fetch    GET subscriber + entitlement state from RevenueCat
#   grant    grant a promotional entitlement (simulates real purchase →
#            triggers RC webhook → backend writes to Supabase)
#   revoke   revoke promotionals (simulates expiration → webhook fires)
#   webhook  POST a synthetic RC event directly at the backend webhook
#            (bypasses RC; tests the handler in isolation)
#
# Usage:
#   ./test_google_play_store_pricing.sh fetch   <user_id>
#   ./test_google_play_store_pricing.sh grant   <user_id> [entitlement] [duration]
#   ./test_google_play_store_pricing.sh revoke  <user_id> [entitlement]
#   ./test_google_play_store_pricing.sh webhook <user_id> <event_type> [product_id]
#
# Defaults:
#   entitlement = premium
#   duration    = monthly  (RC promotional durations: weekly, monthly, two_month,
#                           three_month, six_month, yearly, lifetime)
#   product_id  = premium_yearly
#   event_type  = INITIAL_PURCHASE
#
# Required env:
#   RC_SECRET_KEY      RevenueCat v1 SECRET API key (starts with sk_).
#                      Project Settings → API Keys → Secret API Keys.
#                      DO NOT commit this — script reads from env only.
#
# Optional env:
#   WEBHOOK_SECRET     Bearer token configured as `revenuecat_webhook_secret`
#                      on the backend. Required for `webhook` mode against
#                      a real backend.
#   BACKEND_URL        Default https://aifitnesscoach-zqi3.onrender.com .
#                      Override to http://localhost:8000 for a local backend.
#   CONFIRM_PROD=1     Required to allow USER_IDs that don't start with
#                      `test_`. Guard against accidentally granting
#                      entitlements to a real prod user.
#
# Exit: non-zero on any failure. Output is the raw JSON body for the
# called endpoint, plus a one-line summary at the end.

set -euo pipefail

usage() {
  sed -n '2,40p' "$0" | sed 's/^# \?//'
  exit 2
}

[[ $# -lt 1 ]] && usage

MODE="$1"; shift

case "$MODE" in
  -h|--help) usage ;;
esac

[[ $# -lt 1 ]] && { echo "❌ user_id required" >&2; usage; }
USER_ID="$1"; shift

# --- prod-user guard ------------------------------------------------------
if [[ "${CONFIRM_PROD:-0}" != "1" ]]; then
  if [[ ! "$USER_ID" =~ ^test_ ]]; then
    echo "❌ USER_ID '$USER_ID' does not start with 'test_'." >&2
    echo "   Re-run with CONFIRM_PROD=1 if you really mean to target a prod user." >&2
    exit 1
  fi
fi

# URL-encode user_id (covers the rare case of unusual UUID variants).
URL_USER_ID="$(python3 -c 'import sys, urllib.parse as u; print(u.quote(sys.argv[1], safe=""))' "$USER_ID")"

RC_BASE="https://api.revenuecat.com/v1"
BACKEND_URL="${BACKEND_URL:-https://aifitnesscoach-zqi3.onrender.com}"

require_rc() {
  : "${RC_SECRET_KEY:?RC_SECRET_KEY required (RevenueCat → Project Settings → API Keys → Secret).}"
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq required. brew install jq" >&2
    exit 2
  fi
}

case "$MODE" in
  fetch)
    require_rc
    require_jq
    echo "== Fetching subscriber $USER_ID from RevenueCat =="
    curl --fail --silent --show-error \
      -H "Authorization: Bearer $RC_SECRET_KEY" \
      "$RC_BASE/subscribers/$URL_USER_ID" | jq '.'
    echo
    echo "Tip: scan the 'subscriptions' object for product_identifier values."
    echo "     Match against your Play Console SKUs (premium_monthly, premium_yearly, …)."
    ;;

  grant)
    require_rc
    ENTITLEMENT="${1:-premium}"
    DURATION="${2:-monthly}"
    echo "== Granting promotional entitlement '$ENTITLEMENT' ($DURATION) to $USER_ID =="
    curl --fail --silent --show-error \
      -X POST \
      -H "Authorization: Bearer $RC_SECRET_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"duration\": \"$DURATION\"}" \
      "$RC_BASE/subscribers/$URL_USER_ID/entitlements/$ENTITLEMENT/promotional"
    echo
    echo
    echo "✅ Granted. Webhook should have fired → backend should have written to Supabase."
    echo "   Re-run with 'fetch' to confirm. Allow ~1s for propagation."
    ;;

  revoke)
    require_rc
    ENTITLEMENT="${1:-premium}"
    echo "== Revoking promotionals for entitlement '$ENTITLEMENT' on $USER_ID =="
    curl --fail --silent --show-error \
      -X POST \
      -H "Authorization: Bearer $RC_SECRET_KEY" \
      "$RC_BASE/subscribers/$URL_USER_ID/entitlements/$ENTITLEMENT/revoke_promotionals"
    echo
    echo
    echo "✅ Revoked. Backend should have downgraded tier on next webhook."
    ;;

  webhook)
    [[ $# -lt 1 ]] && { echo "❌ event_type required (INITIAL_PURCHASE | RENEWAL | CANCELLATION | EXPIRATION | PRODUCT_CHANGE | BILLING_ISSUE)" >&2; exit 2; }
    EVENT_TYPE="$1"
    PRODUCT_ID="${2:-premium_yearly}"

    : "${WEBHOOK_SECRET:?WEBHOOK_SECRET required (matches backend revenuecat_webhook_secret).}"

    NOW_MS=$(($(date +%s) * 1000))
    EXPIRES_MS=$((NOW_MS + 7 * 24 * 60 * 60 * 1000))  # +7 days

    BODY=$(cat <<EOF
{
  "event": {
    "type": "$EVENT_TYPE",
    "id": "test-$NOW_MS",
    "app_user_id": "$USER_ID",
    "product_id": "$PRODUCT_ID",
    "period_type": "TRIAL",
    "purchased_at_ms": $NOW_MS,
    "expiration_at_ms": $EXPIRES_MS,
    "environment": "SANDBOX",
    "store": "PLAY_STORE",
    "currency": "USD",
    "price": 0.0
  }
}
EOF
)
    echo "== Posting synthetic $EVENT_TYPE event for $USER_ID to backend =="
    curl --silent --show-error -i \
      -X POST \
      -H "Authorization: Bearer $WEBHOOK_SECRET" \
      -H "Content-Type: application/json" \
      -d "$BODY" \
      "$BACKEND_URL/api/v1/subscriptions/webhook/revenuecat"
    echo
    ;;

  *)
    echo "❌ Unknown mode: $MODE" >&2
    usage
    ;;
esac
