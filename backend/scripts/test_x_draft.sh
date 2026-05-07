#!/bin/bash
# End-to-end test for the X publisher pipeline.
#
# Sends a small test draft to the /api/v1/x/draft endpoint. The webhook
# then forwards it to your Telegram chat with 🚀 / ❌ buttons. Tap one
# to verify the round-trip works.
#
# Usage:
#   ./scripts/test_x_draft.sh              # uses Render URL
#   ./scripts/test_x_draft.sh local        # uses http://localhost:8000

set -euo pipefail

cd "$(dirname "$0")/.."
set -a
source .env
set +a

if [[ "${1:-}" == "local" ]]; then
  BASE_URL="http://localhost:8000"
else
  BASE_URL="https://aifitnesscoach-zql3.onrender.com"
fi

echo "POSTing test draft to ${BASE_URL}/api/v1/x/draft ..."
echo

# Two short tweets so we exercise the thread reply-chain code path.
# These are deliberately bland — if you tap 🚀, they'll go live on
# @chetwitt123. Tap ❌ to dry-run-test the pipeline without posting.
RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST "${BASE_URL}/api/v1/x/draft" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Token: ${X_DRAFT_INTERNAL_TOKEN}" \
  -d '{
    "angle": "TEST — pipeline verification",
    "tweets": [
      "Test tweet 1 of 2 — verifying my X publisher pipeline. If you see this on @chetwitt123 it means the bot, the webhook, the OAuth refresh flow, and the threading all work end-to-end. 🛠️",
      "Test tweet 2 of 2 — and this confirms reply-chaining via in_reply_to_tweet_id works. Now back to your regularly scheduled build-in-public posts."
    ]
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP ${HTTP_CODE}"
echo "${BODY}"
echo

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "✅ Draft accepted. Check your Telegram bot — you should see the draft"
  echo "   with 🚀 Post to X / ❌ Skip buttons."
  echo
  echo "   Tap 🚀 to verify the X publishing path works."
  echo "   Tap ❌ to dry-run only (no tweets posted)."
else
  echo "❌ Draft submission failed."
  echo
  echo "   Common causes:"
  echo "   - Render hasn't finished deploying yet (wait ~2 min, retry)"
  echo "   - X_DRAFT_INTERNAL_TOKEN mismatch between local .env and Render env"
  echo "   - TELEGRAM_BOT_TOKEN missing or invalid in Render env"
  exit 1
fi
