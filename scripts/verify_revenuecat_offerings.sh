#!/usr/bin/env bash
# Verify — and optionally repair — the RevenueCat offering/package config
# for the FitWiz Android + iOS apps.
#
# Problem this fixes: Sentry FITWIZ-FLUTTER-1X reported fatal crashes on
# `com.aifitnesscoach.app@1.2.56+1121` with "Exception: Product not found:
# premium_yearly". The canonical RC-recommended client lookup is via the
# offering package's `lookup_key` (`$rc_annual`), not the raw store product
# identifier. This script confirms that (a) the `$rc_annual` package exists
# on the current offering for both platforms and (b) its attached product
# points at the Play/App Store product `premium_yearly`. If either check
# fails the script emits the exact RC API call to fix it.
#
# Requires:
#   REVCAT_API_KEY    v2 secret API key — available in Render env for this
#                     service; pull via `render env pull` or export manually.
#   jq                Homebrew / apt: brew install jq
#   curl              stdlib.
#
# Safe: READ-ONLY by default. Pass `--apply` to execute the create-package
# mutation. Without it, we print the curl commands so you can review first.

set -euo pipefail

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

: "${REVCAT_API_KEY:?Set REVCAT_API_KEY. Pull from Render with: render env pull --service-id srv-d4o6oker433s73d8pu0g > /tmp/render.env && source /tmp/render.env}"

for tool in jq curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Missing required tool: $tool" >&2
    exit 2
  fi
done

RC_BASE="https://api.revenuecat.com/v2"
AUTH="Authorization: Bearer $REVCAT_API_KEY"

rc_get() {
  curl --fail --silent --show-error -H "$AUTH" "$RC_BASE$1"
}

rc_post() {
  local path="$1" body="$2"
  curl --fail --silent --show-error -X POST \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d "$body" "$RC_BASE$path"
}

echo "== Resolving project id =="
PROJECTS_JSON=$(rc_get "/projects")
RC_PROJECT_ID=$(echo "$PROJECTS_JSON" | jq -r '.items[0].id // empty')
if [[ -z "$RC_PROJECT_ID" ]]; then
  echo "❌ No RevenueCat project accessible with this API key. Response:"
  echo "$PROJECTS_JSON" | jq
  exit 1
fi
echo "  RC_PROJECT_ID=$RC_PROJECT_ID"

echo "== Resolving apps =="
APPS_JSON=$(rc_get "/projects/$RC_PROJECT_ID/apps")
# RevenueCat uses type "play_store" / "app_store" for Google + Apple apps.
ANDROID_APP_ID=$(echo "$APPS_JSON" | jq -r '.items[] | select(.type=="play_store") | .id' | head -n1)
IOS_APP_ID=$(echo "$APPS_JSON" | jq -r '.items[] | select(.type=="app_store") | .id' | head -n1)
echo "  android app_id: ${ANDROID_APP_ID:-<missing>}"
echo "  ios     app_id: ${IOS_APP_ID:-<missing>}"
if [[ -z "$ANDROID_APP_ID" && -z "$IOS_APP_ID" ]]; then
  echo "❌ No Play Store or App Store app configured in RevenueCat." >&2
  echo "   Raw apps payload for debugging:" >&2
  echo "$APPS_JSON" | jq
  exit 1
fi

echo "== Resolving current offering =="
OFFERINGS_JSON=$(rc_get "/projects/$RC_PROJECT_ID/offerings")
CURRENT_OFFERING_ID=$(echo "$OFFERINGS_JSON" | jq -r '.items[] | select(.is_current==true) | .id' | head -n1)
if [[ -z "$CURRENT_OFFERING_ID" ]]; then
  CURRENT_OFFERING_ID=$(echo "$OFFERINGS_JSON" | jq -r '.items[0].id // empty')
  echo "  ⚠️ No offering marked is_current=true, falling back to first ($CURRENT_OFFERING_ID)."
fi
echo "  current offering: $CURRENT_OFFERING_ID"

echo "== Current offering packages =="
# The offering's /packages endpoint does NOT inline attached products; we
# have to fetch /packages/{id}/products separately for each one. Shape the
# result so downstream jq logic can treat it as if the attached products
# were inlined all along.
OFFERING_PACKAGES_JSON=$(rc_get "/projects/$RC_PROJECT_ID/offerings/$CURRENT_OFFERING_ID/packages")
PACKAGES_JSON=$(echo "$OFFERING_PACKAGES_JSON" | jq '{items: (.items // [])}')
# Enrich each package with its attached_products via a second API call.
ENRICHED_ITEMS="[]"
while read -r pkg_row; do
  [[ -z "$pkg_row" ]] && continue
  pkg_id=$(echo "$pkg_row" | jq -r '.id')
  attached_json=$(rc_get "/projects/$RC_PROJECT_ID/packages/$pkg_id/products" 2>/dev/null || echo '{"items":[]}')
  enriched=$(jq -n --argjson pkg "$pkg_row" --argjson attached "$attached_json" '
    $pkg + {attached_products: [($attached.items // [])[] | {
      store_identifier: (.product.store_identifier // .product.platform_product_identifier),
      app_id: .product.app_id,
      eligibility_criteria: .eligibility_criteria
    }]}
  ')
  ENRICHED_ITEMS=$(jq -n --argjson arr "$ENRICHED_ITEMS" --argjson item "$enriched" '$arr + [$item]')
done < <(echo "$PACKAGES_JSON" | jq -c '.items[]')
PACKAGES_JSON=$(jq -n --argjson arr "$ENRICHED_ITEMS" '{items: $arr}')
echo "$PACKAGES_JSON" | jq '.items[] | {id, lookup_key, display_name, attached_products}'

check_package() {
  local lookup_key="$1" expected_store_id="$2" app_id="$3" platform="$4"
  if [[ -z "$app_id" ]]; then
    echo "  ⏭️  $platform: no app_id — skipping."
    return 0
  fi
  local match
  # store_identifier on Play Store subscriptions comes back as
  # "<sku>:<base-plan>" (new Google Play Billing v5+ format). Accept either
  # an exact match OR a prefix match ending in a colon so existing
  # "<sku>:<base-plan>" attachments still validate against the expected
  # top-level SKU.
  match=$(echo "$PACKAGES_JSON" | jq --arg lk "$lookup_key" --arg sid "$expected_store_id" --arg aid "$app_id" '
    (.items // [])[]
    | select(.lookup_key == $lk)
    | (.attached_products // [])[]
    | select(.app_id == $aid
             and (((.store_identifier // .platform_product_identifier) == $sid)
                  or ((.store_identifier // .platform_product_identifier) | startswith($sid + ":"))))
  ')
  if [[ -n "$match" && "$match" != "null" ]]; then
    echo "  ✅ $platform: $lookup_key → $expected_store_id is correctly attached."
    return 0
  fi
  echo "  ❌ $platform: $lookup_key → $expected_store_id is MISSING on offering $CURRENT_OFFERING_ID."
  if [[ "$APPLY" -eq 1 ]]; then
    echo "     Creating product + package…"
    # Create or ensure the product row first (idempotent via 409 on duplicate).
    set +e
    rc_post "/projects/$RC_PROJECT_ID/products" \
      "$(jq -n --arg sid "$expected_store_id" --arg aid "$app_id" \
         '{store_identifier:$sid, app_id:$aid, type:"subscription"}')" >/dev/null
    local prod_rc=$?
    set -e
    if [[ $prod_rc -ne 0 ]]; then
      echo "     (product exists already — continuing)"
    fi
    rc_post "/projects/$RC_PROJECT_ID/offerings/$CURRENT_OFFERING_ID/packages" \
      "$(jq -n --arg lk "$lookup_key" --arg aid "$app_id" --arg sid "$expected_store_id" \
         '{lookup_key:$lk, display_name:"Annual", position:1, products:[{app_id:$aid, product_id:$sid}]}')" \
      | jq
    echo "     ✅ $platform: create complete. Re-run without --apply to verify."
  else
    echo "     (dry run — re-run with --apply to execute)"
    echo "     curl -X POST -H 'Authorization: Bearer \$REVCAT_API_KEY' -H 'Content-Type: application/json' \\"
    echo "       '$RC_BASE/projects/$RC_PROJECT_ID/products' \\"
    echo "       -d '{\"store_identifier\":\"$expected_store_id\",\"app_id\":\"$app_id\",\"type\":\"subscription\"}'"
    echo "     curl -X POST -H 'Authorization: Bearer \$REVCAT_API_KEY' -H 'Content-Type: application/json' \\"
    echo "       '$RC_BASE/projects/$RC_PROJECT_ID/offerings/$CURRENT_OFFERING_ID/packages' \\"
    echo "       -d '{\"lookup_key\":\"$lookup_key\",\"display_name\":\"Annual\",\"position\":1,\"products\":[{\"app_id\":\"$app_id\",\"product_id\":\"$expected_store_id\"}]}'"
  fi
}

echo "== Verifying \$rc_annual = premium_yearly =="
check_package '$rc_annual' 'premium_yearly' "$ANDROID_APP_ID" 'android'
check_package '$rc_annual' 'premium_yearly' "$IOS_APP_ID"     'ios'

echo "== Verifying \$rc_monthly = premium_monthly =="
check_package '$rc_monthly' 'premium_monthly' "$ANDROID_APP_ID" 'android'
check_package '$rc_monthly' 'premium_monthly' "$IOS_APP_ID"     'ios'

echo
echo "Done. If anything was missing, re-run with --apply to create it, then"
echo "re-run once more without --apply to confirm everything shows ✅."
