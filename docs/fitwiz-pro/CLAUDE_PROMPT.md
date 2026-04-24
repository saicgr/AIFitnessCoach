# FitWiz Pro — Phase 1 Implementation Brief

## Read these first
1. `docs/B2B_STRATEGY.md` — full strategic plan, pricing, ICPs, phased roadmap
2. `CLAUDE.md` — project conventions (no mock data, test before deploy, AI-first)
3. `backend/main.py` and `mobile/flutter/lib/main.dart` — entry points

## What you're building
**FitWiz Pro** — a B2B coaching platform layered on the existing FitWiz B2C codebase. Phase 1 ships:
- **Free** (**5 clients** — matches Everfit Starter + Trainerize Basic, **1 trainer seat**, NO Stripe Connect, **"Powered by Reppora"** footer non-removable in client app)
- **Pro $39/mo or $329/yr** (up to 100 clients, **1 trainer seat included**, AI + nutrition + Stripe Connect bundled, removable footer)
  - Add-on trainer seats in Pro: **+$10/mo each, max 3 seats total** (forces Studio upgrade at 4+)
- **Studio $99/mo or $799/yr** (unlimited clients, **up to 10 trainer seats**, custom domain + email)
- **Enterprise** (10+ seats OR 2,000+ clients): custom pricing
- **Local Gym DFY** ($499 setup + $199/mo Lite / $1,500 setup + $399/mo Pro)
- **Founder Lifetime $399** (capped 200 buyers, 30-day window)
- **Plus 1% on each Stripe Connect client payment, capped at $300/mo per coach** (NOT per-active-client — see Sprint 3)

**Critical pricing principle: NEVER tier by sub-100-client buckets like Trainerize does ($25/$50/$79/$135 etc by client count).** Two flat client caps only (Pro ≤100, Studio ≤2K). The 1% capped take-rate captures upside as coaches grow. A "trainer seat" = one login account for a coach (NOT a client). Solo coach = 1 seat; studio with 5 staff = 5 seats.

**Branding decision (Phase 1 — four mandatory surfaces, THREE Flutter flavors):**
1. **Coach web dashboard** at `pro.fitwiz.app` (Next.js + Vercel) — full builder, drag-and-drop, billing, branding editor
2. **Reppora client mobile app** (App Store: `Reppora`, subtitle `Train with Your Coach`, bundle `com.reppora.app`, Health & Fitness) — Flutter `client` flavor, **purpose-built for following coach-assigned programs**. NOT a re-theme of FitWiz consumer (FitWiz lacks coach-program / trainer↔client message / coach-assigned check-in primitives). Reuses ~90% of FitWiz infra (workout execution, food logging, recipes, wearables, offline DB), ~10% new screens
3. **Reppora coach mobile app** (App Store: `Reppora for Coach`, subtitle `Coach Portal`, bundle `com.reppora.coach`, Business/Productivity) — Flutter `coach` flavor, reply/monitor companion (NOT a duplicate builder)
4. **FitWiz consumer app** (existing `com.fitwiz.app`, untouched) — separate B2C product line; zero changes from Reppora work

Mirrors Everfit's two-app pattern (`Everfit - Train smart` + `Everfit for Coach`) but with Reppora as a fully distinct parent brand from FitWiz consumer for stronger anti-cannibalization. See Sprints 4a (client) + 4b (coach) for build specs.

See §5 of STRATEGY.md for full pricing rationale + unit economics.

## What we're selling on (the wedge)
**Two-layer wedge — read carefully, this drives every priority call:**

**(1) SALES wedge — what makes a coach sign up:** Fast manual program builder (RAG semantic exercise search, drag-and-drop, supersets, AMRAP, %1RM, fork/templates, bulk-assign), flat $39 Pro / $99 Studio pricing, modern reliable UX, white-label that updates live, Stripe Connect with 1% capped take, sell-programs marketplace, AI migration importer from Trainerize. **NOT AI as the product.** Coaches don't sign up for AI — they sign up because manual building is fast, pricing is flat and fair, and the app doesn't crash. Trainerize/Everfit/AppRabbit fail on these basics. We win by being not-broken.

**(2) RETENTION wedge — what keeps the coach's CLIENTS engaged once on platform (opt-in per client by coach):**
- **Customized AI Coach (your voice, when you're offline):** Coach configures AI persona (tone, philosophy, programming style); when client messages outside coach's office hours, AI answers in coach's style; flags non-routine questions for coach to handle next morning. Lets coach take weekends off without losing client trust.
- Vision food logging, form-check video AI scoring, voice-narrated workout videos, automated progress photo comparisons.

**These AI features are sold inside the dashboard as "client retention add-ons", NOT on the landing page as the reason to buy.** Landing page is about manual builder + flat price + reliability. AI is bonus they discover after signing up.

## Hard rules (non-negotiable)
1. **Do NOT break the existing B2C app.** B2C is priority #1; B2B is additive only. Every change must be backwards-compatible. Existing FitWiz users continue working as-is.
2. **No mock data, no fallback data, no silent degradation.** Per CLAUDE.md feedback memory.
3. **Multi-tenant via Supabase RLS, not application-layer filtering.** Coach can never see another coach's clients. Test RLS with a malicious-coach unit test before merging.
4. **Web Stripe billing only — never in-app purchase for coach subscriptions.** Apple/Google IAP destroys margin (30% cut would turn $19 → $13.30).
5. **Reuse existing infrastructure.** RAG (`backend/services/exercise_search.py`), Gemini (`backend/services/gemini_service.py`), vision (`backend/services/vision_service.py`), LangGraph (`backend/services/langgraph_service.py`), notifications, S3, Supabase. Do NOT reimplement these.
6. **No new tech stacks beyond:** Next.js + Tailwind for the web dashboard (Vercel deploy), Stripe + Stripe Connect for billing. Backend stays FastAPI; mobile stays Flutter.
7. **Verify before claiming done.** Use the Supabase MCP to inspect schema. Use `py_compile` for backend. Use `flutter analyze` for mobile. No "watch prod logs after deploy" — verify locally.
8. **1,000-line limit PER FILE.** No file in this codebase may exceed 1,000 lines. If a file would cross 1,000 lines after your change, split it into focused modules first. Existing files >1,000 lines (e.g. `backend/services/gemini_service.py` at 5,400+ lines) are exempt from the rule when *editing* — but NEW files must respect the limit.
9. **Bill of materials per change: <500 LOC.** Per single PR. If a single change exceeds this, stop and split.
10. **Manual program builder is the core feature, NOT AI generation.** B2B coaches build programs themselves — fast, intuitive drag-and-drop. AI is a "suggest" button inside the manual builder, not the workflow. AI client-facing features (chat, vision, form-check) are **opt-in per client by the coach, OFF by default**. See §6.2.5 of the strategy doc.
11. **AI cost guardrails are non-negotiable.** Implement these quotas as middleware on every Gemini call from day 1:
    - **30 AI chat messages / client / month** (only counts when coach has enabled AI chat for that client)
    - **30 vision food classifications / client / month** (only when AI food logging enabled for that client)
    - **4 form-check video analyses / client / month** (only when enabled)
    - **50 "AI suggest" calls / coach / month** (inside manual program builder)
    - Above quota → return `429 Quota Exceeded` with `{degraded_mode: true, top_up_url}`. Frontend falls back to manual entry. Never silently bill the coach.
    - Track usage in `client_ai_usage_monthly (client_id, month, chat_count, vision_count, video_count)` and `coach_ai_usage_monthly (coach_id, month, suggest_count)`; rollover monthly via cron.
    - Studio plan ($99/mo) bypasses these quotas — implement quota lookup as `get_quotas_for_plan(plan_id)`.
    - **Per-client AI feature flags** stored on `coach_clients` table: `ai_chat_enabled`, `ai_vision_enabled`, `ai_form_check_enabled` — coach toggles these in the dashboard per client.
12. **Test infra cost in CI.** Add a GitHub Action that runs a synthetic 20-client coach load and asserts Gemini token spend < $4 (per the §6.3 manual-first cost model). Catches accidental cost regressions (e.g. a developer changing `model="gemini-3-pro"` instead of flash, or making an AI feature default-on).

## Phase 1 scope (in order)

### Sprint 1 — Multi-tenant foundation (2 weeks)
- Migration: `organizations` table (id, name, slug, owner_user_id, created_at)
- Migration: `coach_clients` join table (coach_user_id, client_user_id, org_id, status, invited_at, accepted_at)
- Migration: `org_id` FK added to `program_templates` (new), `workout_plans`, `meal_plans`, `custom_exercises`, `chat_messages` (where `coach_authored = true`)
- Update `backend/core/auth.py`: extend role enum to {`super_admin`, `org_owner`, `coach`, `client`}; add `current_org_id()` helper
- Apply Supabase RLS to all tables: `WHERE org_id = auth.jwt()->>'org_id'` pattern
- Audit ALL existing endpoints in `backend/api/v1/` for RLS-leak; add `OrgScopedRouter` wrapper
- **Verification:** Write `tests/test_rls_isolation.py` — create 2 coaches, confirm coach A cannot read coach B's data via any endpoint. CI gate.

### Sprint 2 — Coach web dashboard MVP (3 weeks)
- New repo dir: `web/` — Next.js 15 App Router, Tailwind, shadcn/ui, Supabase Auth client
- Routes: `/login`, `/signup`, `/dashboard`, `/clients`, `/clients/[id]`, `/templates`, `/messaging`, `/settings/branding`, `/settings/billing`
- Reuse existing FastAPI endpoints — do NOT duplicate business logic in Next.js
- Deploy: Vercel at `pro.fitwiz.app` subdomain (NOT a separate domain — keeps SEO + brand transfer; NOT an App Store app — avoids consumer FitWiz cannibalization)
- Marketing landing page lives at `fitwiz.app/pro` (existing apex), dashboard lives at `pro.fitwiz.app`
- **Verification:** Coach can sign up → invite a client → assign a workout template → see client adherence. End-to-end manual test recorded.

### Sprint 3 — Stripe + Stripe Connect billing + 1% take rate (2 weeks)
**The 1% fires on every client payment processed through Stripe Connect, capped at $300/mo per coach.** It is NOT a per-active-client fee (would penalize free/comp clients) and NOT a flat MRR cut (would hurt one-time program sales). It IS `application_fee_amount` on every PaymentIntent. Mechanic per STRATEGY.md §5.4.1:
- Set `application_fee_amount: charge_amount * 0.01` on every PaymentIntent created via coach's connected Stripe account
- Listen to `payment_intent.succeeded` webhook → upsert `coach_monthly_take_mtd (coach_id, month, gmv_cents, fee_cents)`
- When `fee_cents >= 30000` ($300): subsequent PaymentIntents in same month get `application_fee_amount: 0` (cap kicked in)
- Cron at 00:00 UTC on the 1st of each month: snapshot prior month to history, reset MTD counter
- Coach dashboard widget polls `/api/v1/coach/take-rate-mtd` every 60s, shows "MTD GMV: $X · FitWiz fee: $Y / $300 cap"
- Per-charge line item visible in coach dashboard with full breakdown (Stripe fee, FitWiz fee, net to coach)
- Monthly statement email auto-generated on the 1st via existing email infra
- Refund handling: `charge.refunded` webhook → `application_fee_refund` fires automatically (Stripe native), decrement MTD counter proportionally
- **NEVER show FitWiz line item on client-facing receipts** (white-label preservation — client only sees coach's brand)

**Coach subscription billing (separate from take rate):**
- Stripe Standard subscription products: Pro $39/mo + Pro $329/yr + Studio $99/mo + Studio $799/yr + Pro extra-seat $10/mo (max 3 in Pro tier — UI-enforced)
- Founder Lifetime checkout (Stripe one-time, $399, hard-capped at 200 via atomic DB counter; race-condition test required)
- Stripe Connect Standard onboarding flow for coaches (KYC + payout setup happens INSIDE coach dashboard, not in a separate sales flow)
- Webhooks: `customer.subscription.created/updated/deleted/payment_failed` → update `coach_users.subscription_status` + `plan_id` + `seat_count`
- Auto-upgrade trigger: when coach's active client count hits 100, push in-app prompt "You're at 100 clients — upgrade to Studio?" with one-click prorated upgrade button
- **Verification:** Buy Pro w/ Stripe test card → confirm RLS allows 100 clients. Buy Studio → confirm unlimited up to 2K fair-use. Buy Founder Lifetime → confirm counter decrements atomically. Run 5 simulated client charges through Stripe Connect → confirm 1% application_fee deducts correctly + dashboard MTD counter increments + at the $300 simulated cap subsequent charges get $0 application_fee + 1st-of-month cron resets counter.

### Sprint 4a — Reppora client mobile app (Flutter `client` build flavor) (4 weeks)
**MANDATORY for Phase 1. Purpose-built for following coach-assigned programs — NOT a re-theme of FitWiz consumer.** FitWiz consumer is built for AI-generated self-directed workouts and lacks the coach-program/trainer-message/coach-assigned-check-in primitives needed here.

**App Store / Play Store listing:**
- **Listing name:** `Reppora` (7 chars) · **Subtitle:** `Train with Your Coach` (21 chars) · **Category:** Health & Fitness
- **Bundle ID:** `com.reppora.app` · **URL scheme:** `reppora://`
- **Icon:** new "R" mark in accent color, light background (visually paired with the dark-bg coach app variant)
- **Promo first line:** "Follow your trainer's program — workouts, nutrition, check-ins, and direct messaging with your coach. Open by invite from your trainer."

**Flutter flavor setup:**
- Configure flavors: `consumer` (existing) + `client` + `coach`. Use `flavorizr` or manual scheme.
- `lib/main_consumer.dart` (renamed from existing `main.dart`) + `lib/main_client.dart` (new) + `lib/main_coach.dart` (new)
- Per-flavor `Info.plist` (iOS), `AndroidManifest.xml` (Android), bundle IDs, app names, app icons, URL schemes
- Android product flavors in `android/app/build.gradle`; iOS schemes via Xcode

**Reused 90% from existing FitWiz infrastructure (NO rebuilds):**
- `services/`, `data/`, `models/`, `core/networking/`, `core/auth/`, `core/theme/` — all shared
- Workout execution UI (rest timer, set/rep/weight logger) — only the data source changes (coach-assigned vs AI-generated)
- Food logging (manual + vision photo + barcode + screenshot OCR) — full reuse
- Recipe / grocery / batch-cook modeling — full reuse
- Body measurements + progress photos — full reuse
- Wearable sync (Apple Health, WHOOP, Garmin) — full reuse
- Offline-first Drift local DB + sync engine — full reuse
- Push notifications, FCM topic infra — full reuse

**New 10% client-only screens (`lib/screens/client/`):**
- `client_home_screen.dart` — "Today from Coach Sarah" dashboard: today's workout (from coach-assigned program), assigned habits/check-ins due today, unread coach messages, upcoming 1:1 appointment
- `client_program_screen.dart` — coach-assigned program week/day view with coach's exercise notes inline
- `client_meal_plan_screen.dart` — coach-assigned meal plan day-by-day, swap recipes if coach allowed it, auto-scaled macros
- `client_messages_screen.dart` — trainer↔client thread (separate from any opt-in AI chat); voice memo, photo, video reply support
- `client_forms_screen.dart` — assigned check-ins, intake forms, PAR-Q with auto-flag triggers
- `client_tasks_screen.dart` — coach-assigned habits w/ adherence streaks, water/steps/sleep/supplements
- `client_form_check_screen.dart` — record/upload form-check video TO coach (with optional AI pre-score before coach reviews)
- `client_coach_profile_screen.dart` — "About my coach" page (bio, certifications, philosophy)

**White-label runtime theming:**
- New `services/tenant_config_service.dart` — fetches `{logo_url, primary_color, accent_color, app_name, powered_by_visible}` on first login + cached for offline
- App displays coach's brand throughout (e.g. "Sarah's Strength App" in header, coach's logo, coach's accent color)
- App Store listing remains `Reppora` (single shared listing across all coaches' clients) but in-app branding is per-coach
- Replace hardcoded brand strings with `TenantTheme.of(context).appName`
- New onboarding branch: deeplink `reppora://invite/{token}` → "Welcome, you've been invited by Coach Sarah" → join flow

**"Powered by Reppora" footer** (NOT "Powered by FitWiz" — Reppora is the B2B brand; clients clicking footer should land on `reppora.com` to find their own coaches, not consumer FitWiz):
- Free tier: non-removable footer + on login screen
- Pro tier: removable via dashboard toggle (default off for clean white-label)

**Verification:**
1. Two invite links open the app w/ different logos/colors/coach names — no app rebuild required
2. Client receives a coach-assigned 4-week program → sees today's workout on home screen → completes it → coach sees adherence in coach app within 5s
3. Client receives a coach-assigned meal plan with macro target 2,000 kcal → swaps Tuesday's lunch recipe → coach sees the swap in dashboard
4. Client uploads a form-check video → optional AI pre-scores joint angles → coach gets push notification → coach reviews + sends written + voice feedback → client sees feedback in app within 5s
5. Client messages coach at 11pm → message arrives in coach inbox + push → coach replies via voice memo → client sees within 5s
6. Free-tier client sees non-removable "Powered by Reppora" footer → tap → opens `reppora.com` (not fitwiz.app)
7. CI: `flutter build apk --flavor client` and `flutter build ios --flavor client` both succeed; `consumer` and `coach` flavor builds remain unbroken

### Sprint 4b — Reppora coach mobile app `Reppora for Coach` (Flutter `coach` build flavor) (3 weeks)
**MANDATORY for Phase 1.** Mirrors Everfit's pattern (`Everfit for Coach`). Reply/monitor companion only — drag-and-drop building stays web-only.

**App Store / Play Store listing:**
- **Listing name:** `Reppora for Coach` (17 chars) · **Subtitle:** `Coach Portal` (12 chars) · **Category:** Business / Productivity (separates from FitWiz consumer Health & Fitness category)
- **Bundle ID:** `com.reppora.coach` · **URL scheme:** `reppora-coach://`
- **Icon:** same "R" mark as client app, but dark-bg variant (visually paired so coaches recognize the family)
- **Promo first line:** "For personal trainers managing online clients. Reply to clients, review form-check videos, monitor adherence on the go."

**Flutter flavor setup (extends Sprint 4a's three-flavor scheme):**
- Configured in Sprint 4a: `consumer` + `client` + `coach` flavors already exist
- `lib/main_coach.dart` entry point
- Per-flavor `Info.plist` / `AndroidManifest.xml` with distinct bundle IDs, app names, icons, URL schemes (`fitwiz://` vs `reppora://` vs `reppora-coach://`)
- Per-flavor App Store / Play Store assets (full three-flavor table):
  - **`coach` flavor (this sprint):** Listing `Reppora for Coach` · Subtitle `Coach Portal` · Category Business / Productivity · Bundle `com.reppora.coach` · Icon = "R" mark dark-bg variant (paired with client app)
  - **`client` flavor (Sprint 4a):** Listing `Reppora` · Subtitle `Train with Your Coach` · Category Health & Fitness · Bundle `com.reppora.app` · Icon = "R" mark light-bg variant
  - **`consumer` flavor (existing, untouched):** Listing `FitWiz` · Subtitle `AI Personal Trainer` · Category Health & Fitness · Bundle `com.fitwiz.app` · Icon = existing FitWiz logo
  - **Coach screenshots:** show coach UI only (dashboard, roster, message inbox, form-check review) — never client or consumer UI
  - **Coach promotional text first line:** "For personal trainers managing online clients. Reply to clients, review form-check videos, monitor adherence on the go."
- Shared 80%: `core/`, `data/`, `services/`, `models/`, `theme/`, networking, auth, message infra (most of which is also reused by the `client` flavor)
- Coach-only 20%: `screens/coach/` directory tree

**Coach-only screens (`lib/screens/coach/`):**
- `coach_dashboard_screen.dart` — today's overview: active clients, unread messages count, adherence at-a-glance, MRR widget, take-rate MTD widget
- `coach_clients_screen.dart` — searchable roster, tap-into client detail
- `coach_client_detail_screen.dart` — single-client view: assigned program, adherence, recent logs, message thread shortcut, quick-actions (reschedule today's workout, send template message, toggle AI features)
- `coach_messages_screen.dart` — unified inbox across all clients, unread badge, swipe-to-mark-read; tap into per-client chat
- `coach_chat_screen.dart` — reuses existing chat widgets w/ coach-side message composer (text + voice memo + photo + video reply)
- `coach_form_check_screen.dart` — pending form-check video review queue; play video, see AI-scored joint angles overlay, type written feedback or record voice annotation, send to client
- `coach_templates_screen.dart` — read-only template library; tap "Assign to clients" → bulk multi-select roster → confirm
- `coach_settings_screen.dart` — minimal: profile, sign out, deeplinks to web for builder/branding/billing/migration

**Deeplink-back-to-web for desktop-class actions:**
- "Build a new program" button → opens `pro.fitwiz.app/templates/new` in mobile browser (clear messaging: "Builder works best on desktop — opening web")
- Same for: meal plan builder, white-label theme editor, Stripe Connect KYC, migration importer

**Push notifications (coach-side):**
- New FCM topics per coach: `coach_{coach_id}_messages`, `coach_{coach_id}_form_checks`, `coach_{coach_id}_at_risk_clients`
- Coach receives push when: client sends message, client uploads form-check video, client misses 2+ workouts in a row (at-risk flag), monthly take-rate cap approached (80% of $300)

**Verification:**
1. Three App Store listings live + clearly differentiated: `FitWiz` (consumer, Health & Fitness) + `Reppora` (client, Health & Fitness) + `Reppora for Coach` (coach, Business/Productivity) — distinct icons, distinct categories, no cross-collision in App Store search
2. Coach signs up on `pro.fitwiz.app` → web shows "Download Reppora for Coach" CTA + QR code → coach installs `coach` flavor → logs in with same Supabase account → sees client roster on phone within 30s
3. Client sends message at 11pm → coach gets push notification on Reppora for Coach → opens app, replies via voice memo within 60s → client sees reply in Reppora client app within 5s
4. Coach taps "Build new program" on mobile → mobile browser opens `pro.fitwiz.app/templates/new` w/ session preserved
5. CI: `flutter build apk --flavor coach` + `flutter build ios --flavor coach` succeed; existing `consumer` flavor build is unbroken; `client` flavor build (from Sprint 4a) also still succeeds

### Sprint 5 — Manual program builder + Migration importer (THE core B2B features) (4 weeks)
**This is the marquee combination of FitWiz Pro. The manual builder is what coaches buy for. The migration importer is what makes them switch from Trainerize.**

**5a. Manual program builder + meal plan builder (4 weeks — both included in Pro $19, NOT add-ons):**

**Workout program builder:**
- Web dashboard: drag-and-drop program builder UI
  - Coach drags exercises from RAG-searched library into a week/day grid
  - Per-exercise: sets, reps, RPE, rest, notes, video reference
  - Supersets, circuits, AMRAP, EMOM, % 1RM auto-progression (match Everfit feature parity)
  - Save as **template** (reusable across clients) or **assigned program** (one client)
  - Duplicate, version, fork programs
  - Custom check-in form builder (Trainerize/Everfit baseline parity)
- API: `POST /api/v1/programs` — coach manually creates program template
- API: `POST /api/v1/programs/{id}/assign` — assign program to N clients (1-to-many bulk assignment)
- API: `POST /api/v1/programs/{id}/ai-suggest-block` — OPTIONAL: coach clicks "AI suggest"; returns 1 block of suggested exercises (coach edits). Quota: 50/coach/mo.

**Meal plan + recipe builder (CRITICAL — bundled in Pro, undercuts Trainerize $45/mo nutrition add-on):**
- Web dashboard: meal plan builder UI
  - Day-by-day, meal-by-meal grid (breakfast/lunch/dinner/snacks customizable)
  - Coach drags recipes into meal slots
  - Per-client calorie/macro auto-scaling (coach builds 1 plan at 2,000 kcal, system auto-scales for each client's target)
  - Save as **meal plan template** (reusable) or **assigned meal plan** (per-client)
- Recipe library: coach creates reusable recipes (ingredients, macros, instructions, photo)
- Per-client toggle: "client can swap recipes within plan" vs "fixed plan" (matches Everfit per-client setting)
- Custom macro goals per client OR enable "client sets own macros" toggle (matches Everfit feature)
- Reuse existing B2C nutrition infrastructure: `backend/services/nutrition/`, recipe + grocery + batch-cook modeling, vision food classifier
- API: `POST /api/v1/meal-plans`, `POST /api/v1/recipes`, `POST /api/v1/meal-plans/{id}/assign`
- Mobile client side: assigned meal plan view, daily macro tracker (manual + vision photo + barcode), grocery list auto-gen from week's plan, batch-cook tracking with food-safety expiry

**Adherence + assignment flow:**
- API: `GET /api/v1/coach/clients/{id}/adherence` — workout + nutrition adherence from logs
- Web dashboard: template library (workout + meal plan) + bulk assignment flow + adherence dashboard with at-risk client flags

**5b. AI-powered Migration Importer (1 week — THE moat-breaker, see strategy §6.8):**
- API: `POST /api/v1/migrate/program-pdf` — accepts PDF (Trainerize/Everfit/TrueCoach exports), runs Gemini Vision OCR + RAG-based exercise matching against our 1,900-exercise library, returns reconstructed program JSON ready for our manual builder. Target: 85% accuracy on Trainerize PDFs; coach reviews/edits last 15%.
- API: `POST /api/v1/migrate/program-screenshot` — same but for screenshots (for coaches without PDF export)
- API: `POST /api/v1/migrate/clients-csv` — standard CSV client import (any tool's export works; we auto-detect column headers)
- API: `POST /api/v1/migrate/sheets` — Google Sheets / Excel template importer (for the ~30% of coaches who built programs in spreadsheets)
- Web dashboard: "Migrate from your old tool" wizard — upload-and-review flow; coach sees side-by-side "your old PDF vs reconstructed program" before accepting
- **Verification:** Take a real Trainerize program PDF (sample one from G2 reviews or coach community), import it, confirm ≥85% of exercises matched correctly via RAG; coach can edit + assign within 5 minutes total.

**Combined Sprint 5 verification:**
1. Coach manually builds a 4-week strength program in <15 min OR imports an existing PDF program in <5 min, assigns to 3 clients, all 3 clients see it in their mobile app within 5s
2. Coach manually builds a 7-day 2,000-kcal meal plan in <20 min, assigns to 3 clients with different macro targets (1,800/2,000/2,400), each client sees auto-scaled macros + grocery list
3. Client snaps a meal photo → vision logs macros → coach sees in adherence dashboard within 30s
4. AI suggest button used 0 or 1 times max during the build

### Sprint 5b — Optional AI client retention features (2 weeks, only after 5 ships clean)
**Positioning: these are RETENTION features sold inside the dashboard, NOT the reason coaches sign up.**

- **Customized AI Coach (the marquee retention feature):**
  - New `coach_ai_persona` table: `coach_id`, `tone` (warm/strict/playful/no-nonsense), `programming_philosophy` (free-text), `office_hours_tz` + `office_hours_start/end`, `escalation_rules` (free-text), `fallback_message`
  - Coach configures persona in dashboard (~5-min setup wizard reuses existing persona patterns from B2C)
  - When client sends message outside office hours: AI coach answers in coach's voice using `langgraph_service` w/ persona-injected system prompt; flags non-routine questions (medical, complaint, scope) for coach review next morning
  - Coach sees "AI handled 12 messages overnight, 2 flagged for your review" digest each morning
- Per-client toggle UI on `coach_clients.ai_*_enabled`: coach enables/disables {AI coach, vision food, form-check, voice narration} per client
- Backend middleware enforces quotas + checks toggle flag on every AI call
- Default toggles: OFF on Free (all 5 clients) — Free tier is acquisition only, AI features visible but ungated only after upgrade. ON for first 10 clients on Pro (coach can enable for the rest manually; quota gates protect us)
- **Verification:** Coach configures AI persona w/ "warm but no-nonsense" tone; client messages at 11pm; AI replies in coach's voice within 5s; medical question gets flagged not auto-answered; coach sees digest at 8am.

### Sprint 5c — Table-stakes coach tools (4 weeks) — extracted from competitor pricing screenshots
**Why this sprint exists:** A feature parity audit of Trainerize, Everfit, TrueCoach, FitBudd, MyPTHub revealed 7 features that ALL major competitors ship and that coaches treat as basics. Missing any one of them is a "you're not serious" objection on demos. See STRATEGY.md §4.1 for the full parity matrix.

- **Forms & questionnaires** (table stakes — Trainerize, Everfit, TrueCoach, MyPTHub all ship this):
  - New `forms` table (`coach_id`, `name`, `schema_json`, `assignable_to_clients` bool)
  - New `form_responses` table (`form_id`, `client_id`, `submitted_at`, `responses_json`, `flagged_for_coach` bool)
  - Default form library bundled: PAR-Q (medical clearance), Intake form, Consent waiver, Weekly check-in, Photo release
  - Drag-and-drop form builder in web dashboard (text/number/multi-select/photo upload/signature widgets)
  - Client receives form via push notification, fills in mobile app, response shows in coach dashboard
  - Coach can flag any field-trigger as "auto-flag for review" (e.g. "any 'pain' answer flags this response")
  - **Verification:** Coach builds custom intake form in <5 min, assigns to new client, client fills on mobile, coach sees response with one flagged item highlighted within 5s.

- **Tasks & habit coaching** (table stakes — every competitor ships this):
  - New `habit_assignments` table (`coach_id`, `client_id`, `habit_name`, `frequency` daily/weekly/N-times-per-week, `target_value` optional numeric, `start_date`, `end_date`)
  - Default habit library: Drink 3L water, 10K steps, Sleep 8h, Daily mobility, Take supplements, Meditate 10min
  - Mobile: client sees habits as daily checklist in home screen, taps to mark complete, can log numeric value (e.g. 9,200 steps)
  - Coach dashboard: heat-map view of habit completion across all clients (red = struggling, green = consistent)
  - Streaks tracked + celebrated in client app (reuse existing B2C streak infra)
  - **Verification:** Coach assigns "Drink 3L water daily" + "10K steps daily" to 5 clients; clients log over 7 days; coach sees adherence heat-map showing 3 green / 1 yellow / 1 red.

- **Automated client check-ins** (table stakes — Everfit, TrueCoach, MyPTHub Premium ship this):
  - New `check_in_schedules` table (`coach_id`, `client_id`, `form_id`, `cadence` (weekly/biweekly/monthly), `day_of_week`, `time_local`, `last_sent_at`)
  - Cron runs hourly (per `feedback_intraday_notification_timing.md`), sends form via push + email at user's local time
  - Client gets gentle reminder push 24hr later if not submitted
  - Coach dashboard: "X check-ins overdue this week" tile
  - Auto-pause check-ins on vacation mode (per `feedback_user_notification_control.md`)
  - **Verification:** Coach sets up "weekly Sunday 6pm check-in" for 3 clients; cron fires Sunday 6pm in client local TZ; all 3 clients get push; 2 submit Monday, 1 gets gentle reminder Monday 6pm.

- **Saved response templates** (Everfit ships this; massive coach time-saver):
  - New `saved_responses` table (`coach_id`, `name`, `body`, `usage_count`, `category` enum motivation/scheduling/nutrition/billing/form-correction)
  - Web dashboard: saved-response panel in messaging UI, click-to-insert with `{client_first_name}` template tokens
  - Sortable by usage count + last used
  - Bulk-import 20 starter templates on coach signup
  - **Verification:** Coach creates 5 saved responses, sends 3 messages to different clients using saved templates with name token substitution working correctly.

- **1:1 appointment scheduling** (table stakes — Everfit, MyPTHub, FitBudd as add-on):
  - New `appointment_slots` table (`coach_id`, `start_local`, `duration_min`, `buffer_min`, `recurring_rule` iCal RRULE)
  - New `appointments` table (`slot_id`, `client_id`, `status` booked/cancelled/completed, `notes`, `created_at`)
  - Web dashboard: weekly calendar grid, set availability, block out PTO, set buffer time
  - Client mobile app: "Book a session" → see available slots → book → adds to client's iCal automatically
  - Two-way Google Calendar sync (read busy times from coach's GCal so we don't double-book)
  - 24hr + 1hr reminder push notifications (respecting quiet hours per memory)
  - Cancellation policy enforcement (configurable: 24hr free / 24-12hr 50% fee / <12hr 100% fee via Stripe)
  - **Verification:** Coach sets Mon-Fri 6-9am availability, client books 7am Tuesday, gets calendar invite, gets 24hr + 1hr reminders, can cancel up to 24hr free; coach's GCal busy time blocks our slots.

- **Async video + voice messages** (Everfit, MyPTHub ship this; massive value for form correction):
  - Reuse existing media upload pipeline + Gemini ASR for auto-transcription
  - Coach records video on web (laptop camera) or mobile, attaches to client message
  - Client records voice memo (any length, no 1-min cap like Everfit), auto-transcribed for coach skim
  - Gemini ASR transcript appears alongside audio (searchable in message history)
  - **Verification:** Coach records 2-min form-correction video on web, attaches to message, client receives push + can play in mobile app within 5s; client sends 90s voice memo back, coach sees transcript + can play original audio.

- **Wearable read-only integration — Apple Health + Google Fit + WHOOP** (table stakes — Trainerize, Everfit, TrueCoach Pro all ship this):
  - Use `flutter_health` package (per `feedback_flutter_packages_first.md`) for Apple Health + Google Fit
  - WHOOP via OAuth2 (read-only API, free tier)
  - Sync: steps, active calories, sleep duration, sleep stages, resting HR, HRV (where available)
  - Daily background sync via existing `workmanager` infra
  - Coach dashboard: client profile shows last-7-day wearable summary (sleep avg, step avg, HRV trend)
  - Client mobile: settings toggle to enable/disable each data source per privacy compliance
  - **Verification:** Coach enables wearable sync on test client account with Apple Watch; data syncs within 5 min; coach sees "Avg sleep: 6h 47m, Avg steps: 8,432" on client profile; client toggle off → data stops appearing.

### Sprint 6 — Trainer↔client messaging (1 week)
- New `chat_conversation_type` enum: `ai_coach` (existing) | `trainer_client` (new)
- Reuse media upload, push notification infra from existing chat
- Web dashboard: messaging UI w/ unread count, search
- Mobile: client sees trainer messages in their chat list, distinguishable from AI coach
- **Verification:** Coach sends message from web; client receives push within 5s; client replies; coach sees in dashboard.

### Sprint 7 — Local Gym DFY tier features (ships in Phase 1, displacing Mindbody) (4 weeks)
**Highest-ARPC tier in Phase 1 ($199–$399/mo). Same backend as Pro; feature-gated by `coach.plan_id`. First 20 customers onboarded by founder personally for direct learning + testimonials.**

> **What is Mindbody (context for the build):** US-dominant gym/studio booking SaaS, 60K+ locations, $129–$349+/mo per location, universally hated for clunky UX + dated app + transaction fees. Their member-facing app has notoriously bad reviews. We displace them with a modern AI-native fully-onboarded alternative.

- New `gym_locations` table (gym owner can have 1 location for now; multi-location is Gym Chain Phase 3)
- New `gym_members` table (member roster per location, with subscription status, attendance history, waiver status)
- New `gym_classes` table (class schedule per location, day/time/capacity/instructor)
- New `class_bookings` table (member books class slot)
- **Member roster management UI:** dashboard view of all members, add/remove/suspend, member profile pages
- **Class scheduling UI:** weekly grid, drag-and-drop class slots, capacity limits, instructor assignment
- **Member self-service mobile app flow:** member onboarding via QR code at gym entrance → email/phone → set goals → see assigned program from coach → book classes → pay drop-ins
- **Drop-in billing:** Stripe Checkout link per class, no-show fees, automated reminder texts
- **Member migration tools (reuse Sprint 5 migration infra):**
  - CSV import from Mindbody / Wodify / Glofox / Zen Planner / Pike13 (auto-detect column headers)
  - Bulk member email invitations w/ branded onboarding flow
  - Founder-led white-glove migration for first 20 gyms (allocate 100 hrs across Phase 1)
- **Multi-trainer support per gym:** up to 3 trainers (Lite) / 5 trainers (Pro), each with their own client roster within the gym
- **Custom check-in forms:** weekly progress check-ins, customizable per gym
- **Member retention dashboard:** at-risk flags (no class booked in 14 days, no workout logged in 21 days, payment failed), founder/owner sees churn-risk list
- New pricing page `fitwiz.app/gym-app` ($499 setup + $199 Lite / $1,500 setup + $399 Pro)
- Stripe products: Local Gym DFY Lite + Pro SKUs + setup fee one-time products
- **Verification:** Founder-led setup of 1 real Local Gym DFY customer end-to-end: import 50 members from Mindbody CSV in <30 min, gym branding live in their app within 24 hrs, owner schedules 10 classes for the week, 3 members book and 1 pays drop-in via Stripe, member retention dashboard correctly flags at-risk members.

### Sprint 8 — Launch prep (1 week)
- Landing pages: `fitwiz.app/pro` + `fitwiz.app/gym-app` (Next.js, Vercel)
- SEO content for `/gym-app`: "Mindbody alternatives 2026", "Wodify replacement", "F45 franchisee tech stack" — 5 long-form posts at launch
- **5-route hero on `fitwiz.app`** ("Solo coach / Local gym owner / Garage gym coach / Influencer coach / Multi-location chain"). Phase 1 active routes: `/pro` and `/gym-app`. Others "coming soon" w/ email capture for Phase 2+.
- Trustpilot integration; first-paying-coach review prompt automation
- Analytics: PostHog for product, Stripe for revenue, Supabase for usage
- Founder Lifetime page w/ live counter ("X / 200 claimed") + 30-day countdown timer
- **Verification:** Buy Pro end-to-end as a real coach (use a friend); buy Lifetime; receive welcome email; complete onboarding in <10 min.

## Out of scope for Phase 1 (do not build)
- **DFY Solo Coach tier** (manual ops, Phase 2): $499 setup + $99–$499/mo white-label for influencer coaches
- **Local Gym DFY tier** (Phase 2): $499 setup + $199/mo (Lite, ≤100 members) or $1,500 setup + $399/mo (Pro, ≤500 members) — single-location indie gyms (CrossFit boxes, F45 franchisees, boutique studios). Mindbody alternative.
- **Gym Chain tier** (Mindbody integration, Phase 3): multi-location franchisees + chains
- L3 dedicated App Store builds (per-trainer apps — Premium DFY only, Phase 2)
- Group/cohort messaging (Phase 2)
- Video conferencing (Phase 2 via Daily.co)
- Mindbody/Wodify sync (Phase 3)
- Custom exercise AI import per coach org (Phase 2)
- Supplement tracking, bloodwork upload (Phase 2)
- AI-generated social content for coach (Phase 2)
- Email/SMS automation campaigns / Autoflow drip sequences (Phase 2 — matches Everfit Autoflow)
- Community rooms / cohort groups / live class streaming (Phase 2 — matches MyPTHub Premium)
- On-demand video collection library (Phase 2 — matches Trainerize Studio + Everfit On-Demand add-on)
- Public coach profile / discovery directory (Phase 2 — matches Trainerize.me + TrueCoach Pro)
- Zapier integration (Phase 2 — matches MyPTHub, TrueCoach Pro, FitBudd Super Pro)
- Form library marketplace (Phase 3)
- Supplement / merch e-commerce store (Phase 3 — matches FitBudd default)
- AI Coach Marketplace (Phase 4)
- AR modes (Phase 4 / skip — Trainerize Studio Plus has but no usage data justifies build)

## Add-on philosophy (NEVER add recurring monthly add-ons)
**Anti-Trainerize. Anti-Everfit.** Coaches hate add-on creep. Every recurring competitor charge → bundled in Pro $19.

Permitted add-on shapes:
- **One-time only:** Dedicated App Store build $1,500 (Pro add-on); White-Glove Migration $299 (free for first 100)
- **Usage-based only:** AI overage credits $5/100 calls; SMS notifications $0.01/SMS (passthrough)
- **Premium support** $50/mo (Phase 2, only sold to coaches who ask)

**NEVER:** AI as a recurring add-on, nutrition as add-on, payments as add-on, branding as add-on, automation as add-on. All bundled in Pro forever.

## Stage gate to call Phase 1 done
- 50 paying Pro coaches sustained 30 days
- 200/200 Founder Lifetime sold OR 30-day window closed
- $1K MRR (Pro + Local Gym DFY recurring)
- NPS ≥40 from first 50 coaches
- All 8 sprint verifications pass
- **Migration importer hits ≥85% accuracy** on 50 real Trainerize PDFs sourced from coach community ($1,250 sourcing budget)
- **At least 10 paying Local Gym DFY customers** (validates the highest-ARPC tier — $199–$399/mo each)

## Out-of-scope for Phase 1 → moved to Phase 2

- **Home Gym tier** ($39/mo with garage gym features — scheduling/waivers/equipment-aware/drop-in billing) — Phase 2 (~2 weeks build because Local Gym DFY infrastructure already covers most of it)
- **DFY Solo Coach** ($499 setup + $99-$499/mo) — Phase 2
- Gym Chain tier (multi-location, Mindbody/Wodify integration) — Phase 3
- Enterprise (equipment OEM, corp wellness) — Phase 4 inbound only

## When to ask the user (founder) before acting
- Any change that touches B2C user data
- Any new third-party SaaS dependency (e.g., adding Resend, switching from Render)
- Any pricing change after launch
- Any decision that contradicts §6 of `docs/B2B_STRATEGY.md`

## Style
- Match existing CLAUDE.md conventions (logging prefixes 🔍✅❌, no mock data, test API before device, etc.)
- Match existing FitWiz code style (no comments unless WHY is non-obvious)
- Reuse, don't reinvent — every new feature should reference an existing service or pattern
- **Files: max 1,000 lines (new files); max 500 LOC per PR.** Split early; module by domain (auth, billing, templates, messaging) not by tech-layer (controllers, services).

## Verification cost-model — actual 2026 vendor pricing (DO NOT exceed)
Reference for every infra change. If a feature pushes any of these above target, redesign:

| Vendor | Unit cost | Pro coach budget (manual-first) |
|---|---|---|
| Gemini 3 Flash text | $0.50/1M input, $3/1M output | <$1/coach/mo (AI suggest + opt-in client chat) |
| Gemini 3 Flash vision | $0.30/1M input ($0.0004/image at 1024×1024) | <$0.60/coach/mo (opt-in client food/form features) |
| Supabase Pro | $25/mo base + $0.125/GB + $0.09/GB egress | <$0.60/coach amortized |
| Render Pro | $19/mo flat per service | <$0.20/coach amortized |
| Vercel Pro | $20/seat/mo + $20 credit + $0.15/GB overage | <$0.20/coach amortized |
| AWS S3 | $0.023/GB storage; first 100GB egress free | <$0.10/coach |
| Resend | Free 3K, then $20/50K, $0.40/1K beyond | <$0.10/coach |
| Stripe | 2.9% + $0.30 per txn | $0.85 on $19 sub |
| **Total target** | | **<$4/coach/mo** at 20-client typical → 83% margin on $19 Pro |

Begin with Sprint 1. Confirm the migration plan with the founder before applying RLS to existing tables.
