# Manual steps: activate the $47.99 exit-intent offer (14d)

The downsell screen is live in code with a safety guard: if the SKU below
doesn't exist in the current RevenueCat offering, "Keep my plan" silently
falls back to standard `premium_yearly` (no crash). To activate the real
$47.99 founding price, do these once:

## 1. Google Play Console (~5 min)
1. Play Console → **Zealova (com.aifitnesscoach.app)** → Monetize → Products → **Subscriptions**.
2. Open the existing **premium** subscription (the one holding `premium_monthly` / `premium_yearly` base plans) → **Add base plan** (or add an offer on the yearly base plan — RevenueCat treats either as a product; base plan is simpler).
3. Base plan ID: `premium-yearly-25off` → auto-renewing, billing period **1 year**, price **$47.99 USD** (let Play auto-convert other currencies).
4. Add an **offer** on it: 7-day free trial, eligibility "new customer acquisition".
5. Activate.

## 2. RevenueCat dashboard (~3 min)
1. RevenueCat → Project → **Products** → + New → attach the Play product `premium:premium-yearly-25off` with identifier **`premium_yearly_25off`** (must match the code string exactly).
2. **Entitlements** → `premium` → attach `premium_yearly_25off`.
3. **Offerings** → current offering → add a package (custom identifier fine) containing `premium_yearly_25off`.

## 3. PostHog (~1 min)
1. Feature flags → create/enable **`paywall_soft_exit_offer`** → roll out to 100% (or start at 50% as an A/B vs plain skip).

## 4. Verify
- Sandbox account → reach paywall → tap "Maybe later" → downsell shows → "Keep my plan" opens the Play sheet at **$47.99/yr with 7-day trial**.
- Until step 1–2 are done, the same tap purchases standard $59.99 yearly (guard fallback) — check logcat for `premium_yearly_25off missing from offerings`.

## iOS note
When the iOS pricing goes live, mirror this in App Store Connect (subscription
group → new yearly sub at $47.99 w/ 7-day intro offer) and attach to the same
RevenueCat product identifier.
