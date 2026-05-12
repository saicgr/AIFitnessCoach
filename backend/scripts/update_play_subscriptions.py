"""Update Google Play subscription pricing + trial offers.

Replaces the legacy Play sandbox SKUs that surfaced as "$49.99/30-min" with the
real pre-launch pricing locked into MEMORY/project_pricing.md:

    premium_monthly  → $7.99/month  + 7-day free trial
    premium_yearly   → $59.99/year  + 7-day free trial
    (legacy)         → deactivate the $49.99/30-min sandbox offer

Why a script instead of "log into Play Console": the user's
feedback_no_dashboard_deferral memo rules out dashboard-only plans. This
script is idempotent — re-running with the same args is a no-op apart from
the deactivation step.

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/play-developer-sa.json
    backend/.venv/bin/python -m backend.scripts.update_play_subscriptions \\
        --package com.aifitnesscoach.app \\
        --monthly-sku premium_monthly --monthly-price 7.99 \\
        --yearly-sku premium_yearly --yearly-price 59.99 \\
        --trial-days 7

Auth:
    The service account needs the Google Play Android Developer API role
    `androidpublisher` (added via the Play Console > Setup > API access page
    when the SA was created). No app-specific permissions beyond that.

Propagation:
    Play caches base-plan pricing aggressively. Allow ~6 hours after the
    script returns before re-running `verify_revenuecat_offerings.dart` to
    confirm the price shown in app matches.
"""
from __future__ import annotations

import argparse
import sys
from typing import Dict, List

try:
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from google.auth import default as google_auth_default
except ImportError as exc:  # noqa: BLE001
    sys.exit(
        f"Missing google-api-python-client (or google-auth). Install with:\n"
        f"    backend/.venv/bin/pip install google-api-python-client google-auth\n"
        f"Original error: {exc}"
    )

ANDROIDPUBLISHER_SCOPE = ["https://www.googleapis.com/auth/androidpublisher"]

# Countries (ISO-3166-1 alpha-2) that get the explicit USD price. Other
# regions inherit Play's auto-conversion. Limited to US for v1 — broaden in a
# future pass once we have launch data.
PRIMARY_REGION = "US"


def _service():
    creds, _ = google_auth_default(scopes=ANDROIDPUBLISHER_SCOPE)
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def _list_offers(svc, package: str, sku: str) -> List[Dict]:
    """Return all subscription offers attached to a given base plan/SKU."""
    try:
        resp = (
            svc.monetization()
            .subscriptions()
            .basePlans()
            .offers()
            .list(packageName=package, productId=sku, basePlanId=sku)
            .execute()
        )
    except HttpError as e:
        if e.resp.status == 404:
            return []
        raise
    return resp.get("subscriptionOffers", [])


def _patch_base_plan_price(svc, package: str, sku: str, price_usd: float) -> None:
    """Update the base-plan USD price for the given SKU."""
    body = {
        "regionalConfigs": [
            {
                "regionCode": PRIMARY_REGION,
                "price": {
                    "currencyCode": "USD",
                    "units": str(int(price_usd)),
                    "nanos": int(round((price_usd - int(price_usd)) * 1_000_000_000)),
                },
            }
        ],
    }
    svc.monetization().subscriptions().basePlans().migratePrices(
        packageName=package, productId=sku, basePlanId=sku, body=body
    ).execute()
    print(f"  ✔ {sku}: USD price set to ${price_usd:.2f}")


def _ensure_trial_offer(svc, package: str, sku: str, trial_days: int) -> None:
    """Create a free-trial offer if one with `trial_days` doesn't exist yet."""
    existing = _list_offers(svc, package, sku)
    for offer in existing:
        phases = offer.get("phases", [])
        if any(p.get("freeTrial") and p.get("duration") == f"P{trial_days}D" for p in phases):
            print(f"  ✔ {sku}: {trial_days}-day trial offer already present "
                  f"({offer.get('offerId')})")
            return

    offer_id = f"trial-{trial_days}d"
    body = {
        "basePlanId": sku,
        "offerId": offer_id,
        "phases": [
            {
                "duration": f"P{trial_days}D",
                "recurrenceCount": 1,
                "freeTrial": {},
            }
        ],
        "state": "ACTIVE",
        "regionalConfigs": [{"regionCode": PRIMARY_REGION}],
    }
    svc.monetization().subscriptions().basePlans().offers().create(
        packageName=package,
        productId=sku,
        basePlanId=sku,
        offerId=offer_id,
        body=body,
    ).execute()
    print(f"  ✔ {sku}: created {trial_days}-day free-trial offer ({offer_id})")


def _deactivate_legacy_offer(svc, package: str, sku: str) -> None:
    """Deactivate the $49.99 / 30-minute sandbox test offer if it exists.

    Identified by a phase with `priceMicros` close to 49_990_000 or a
    short `duration` like `PT30M`. Conservative — only flips state to
    INACTIVE; never deletes (so QA can re-enable if needed).
    """
    for offer in _list_offers(svc, package, sku):
        phases = offer.get("phases", [])
        is_legacy = any(
            (p.get("regionalConfigs", [{}])[0]
              .get("price", {})
              .get("units") == "49")
            or p.get("duration", "").startswith("PT")  # any sub-day duration
            for p in phases
        )
        if not is_legacy:
            continue
        if offer.get("state") == "INACTIVE":
            print(f"  ✔ {sku}: legacy offer {offer['offerId']} already INACTIVE")
            continue
        svc.monetization().subscriptions().basePlans().offers().deactivate(
            packageName=package,
            productId=sku,
            basePlanId=sku,
            offerId=offer["offerId"],
        ).execute()
        print(f"  ✔ {sku}: deactivated legacy offer {offer['offerId']}")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--package", required=True, help="Android package ID, e.g. com.aifitnesscoach.app")
    p.add_argument("--monthly-sku", required=True)
    p.add_argument("--monthly-price", type=float, required=True)
    p.add_argument("--yearly-sku", required=True)
    p.add_argument("--yearly-price", type=float, required=True)
    p.add_argument("--trial-days", type=int, default=7)
    args = p.parse_args()

    svc = _service()

    print(f"→ Updating {args.package}")
    for sku, price in (
        (args.monthly_sku, args.monthly_price),
        (args.yearly_sku, args.yearly_price),
    ):
        print(f"\n[{sku}]")
        _patch_base_plan_price(svc, args.package, sku, price)
        _ensure_trial_offer(svc, args.package, sku, args.trial_days)
        _deactivate_legacy_offer(svc, args.package, sku)

    print("\n✓ Done. Allow ~6 hours for Play cache propagation, then run "
          "`verify_revenuecat_offerings.dart` from mobile/flutter/scripts/.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
