# Zealova canonical facts

**Every marketing agent reads this file at context-load time.** This is the single source of truth on what Zealova actually is, does, charges, and runs on. Drafts that contradict this file get rejected.

This file evolves as the product ships. If you find any fact below has changed, update it here first, then re-run any in-flight drafts.

**Last verified:** 2026-05-12

---

## 0. The 10-second pitch

> **Zealova** is an AI fitness coach for iOS and Android. It generates personalized workout plans, analyzes exercise form from video (Gemini Vision), reads calorie data from MyFitnessPal/menu screenshots, and lets users chat with a multi-agent coach across workout / nutrition / injury / hydration domains. **$7.99/month or $59.99/year, 7-day free trial.**

Use this exact phrasing (or close paraphrase) for one-liners. Don't invent alternate descriptions.

---

## 1. Brand basics

| Field | Value |
|---|---|
| Display name | **Zealova** |
| Domain | `zealova.com` |
| iOS bundle ID | `com.zealova.app` |
| Android applicationId | `com.aifitnesscoach.app` (legacy locked — do NOT call out in marketing) |
| Founder | Sai (solo, building in public — fine to say) |
| Live on | Google Play Store (Android) · iOS App Store coming soon (in review / not yet live as of 2026-05-14) |
| Stack (when relevant to technical/builder content) | Flutter + Riverpod (frontend) · FastAPI + Supabase + ChromaDB (backend) · Google Gemini (LLM) · LangGraph (multi-agent) · Render (hosting) · RevenueCat (payments) |

Never reference the Android applicationId in marketing — it's a legacy artifact and inconsistent with the rebrand.

---

## 2. What Zealova actually does (use these — do not invent)

**Audited 2026-05-14** against actual app router (`mobile/flutter/lib/router/`) and main shell nav (`widgets/main_shell_part_edge_panel_handle.dart`). User-stated exclusions (no merch storefront / no social feed / no challenges / no fasting marketing) are encoded in the "DO NOT MARKET" section below — directories or routes for these may exist in code but they are NOT to be referenced in any marketing surface.

### 2A. Bottom-nav surfaces (the 5 user-facing tabs)

1. **Home** — dashboard, quick-log, progress cards
2. **Workouts** — scheduled workouts, history, active workout
3. **Nutrition** — meal logging, macros, recipes, hydration
4. **Discover** — fitness leaderboard (percentile-based ranking)
5. **You** — profile / settings / rewards hub

### 2B. CORE features (lead with these — primary marketing claims, both code-verified AND user-confirmed reliable as of 2026-05-14)

- **AI workout plan generation** — personalized monthly plans, adapts based on completion + feedback. Powered by Gemini. (THE core product. Soften specific reliability promises — say "personalized workout plans" not "always-correct safety-checked plans.")
- **Food image logging with multi-image input** — photograph a plated meal (or up to 10 photos for a buffet / multi-dish meal). AI extracts items + calories + macros + micronutrients per item, auto-logs to diary. 4 analysis modes: auto / plate / menu / buffet. **This is currently Zealova's strongest, most-tested AI feature — lead with it.**
- **Menu scan** — photograph a restaurant menu; AI identifies dishes and estimates calories/macros per dish. Confirmed shipped and reliable as of 2026-05-14 (user verified).
- **Multi-agent chat coach** — 5 specialist sub-agents (Coach / Nutrition / Workout / Injury / Hydration) under one chat. LangGraph router picks agent by intent + media type. Both code-verified and user-confirmed ready.
- **Workout history per exercise + per muscle** — not just aggregate. Each lift's own history + per-muscle volume tracking.
- **3rd-party workout export** — 10 export formats: Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, Parquet. Each has dedicated emitter.
- **Workout modifications via chat (between workouts)** — "swap squats for hip pain" → agent uses RAG over exercise library to find safe alternative → modifies the plan. (Note: this is BETWEEN-workout chat, not in-active-session chat — see §2G.)
- **Custom exercises** — user-created exercises with image/video upload, AI-assisted import, public/private sharing.
- **Supersets** — antagonist pair mapping + AI superset suggestions + classic curated pairs.
- **Gym equipment profiles** — multiple equipment loadouts per user (home / commercial gym / hotel) with environment-based defaults.
- **Live Activity** (iOS) — workout-in-progress widget.
- **Health Connect integration** (Android, limited scope per 2026-05 resubmit).

### 2C. SECONDARY features (mention contextually, don't lead)

- **Wellness modules** (niche, mention only when audience-relevant):
  - Habit tracker (daily habits, steps, water)
  - Mood history
  - Hydration tracking
  - Injury tracking + injury-aware exercise swaps
  - Plateau detection
  - Strain prevention (overtraining warnings, volume tracking)
  - Hormonal health (cycle tracking, phase-aware workouts)
  - Kegel / pelvic floor sessions
  - Diabetes-specific dashboard (glucose-aware tracking)
- **Skill progressions** — handstands, muscle-ups, pistols, etc. Progression templates + volume/rep tracking.
- **Custom exercises** — user-created exercises (AI-assisted import).
- **Gym equipment profiles** — multiple equipment loadouts (home / commercial gym / hotel).
- **Supersets** — explicit superset programming + tracking.
- **Cardio logging** — separate cardio workout type.
- **Personal bests** + **1RM calculator**.
- **Progress photos** — visual progress timeline.
- **Body measurements** — manual entry: weight, chest, waist, etc. (Note: this is measurement entry; "AI body composition" is NOT confirmed — do NOT claim until verified.)
- **Live human support chat** (`/live-chat`).
- **AI integrations / MCP** — Claude / ChatGPT / Cursor client integration (for power users).

### 2D. ENGAGEMENT layer (retention scaffold, don't lead with these)

- **XP + leveling** — daily login bonuses + workout completion XP
- **Trophy room** + **badge hub** — Garmin-style gallery of earned trophies/badges
- **Monthly Wrapped + Weekly Wrapped** — Spotify-style recaps
- **Cosmetics** — equippable badges / frames earned by leveling
- **Personal goals** — weekly self-set goals + streaks
- **Referral program** — share code, tier rewards
- **Consistency insights** — streak tracking, skip patterns

### 2G. RELIABILITY HOLD — code exists, but user-flagged as "not properly tested yet" 2026-05-14

These features have working code (audited 2026-05-14, all code-structurally complete) but Sai has flagged them as not reliable enough to lead with on a comparison page. Until reliability is verified end-to-end with real testing, **do NOT use these as hero wedges, primary claims, or features the page leans on.** Mention only in soft / hedged language ("we're working on X"), OR omit entirely.

- ⏸ **Form video analysis** — Gemini Vision form-scoring exists (`backend/services/form_analysis_service.py`, 909 lines) but accuracy / reliability not validated for marketing claims yet. **Reliability work shipping by 2026-05-21 (EoW).** Once reliability-validated, promote to §2B.
- ⏸ **In-workout AI coach chat (mid-session)** — code audit confirms only post-workout chat is wired; in-active-session context isolation not implemented. Do NOT claim real-time mid-workout chat.
- ⏸ **Recipe import** — code exists (`backend/api/v1/nutrition/recipe_imports.py`, streaming SSE) but not user-validated. **Reliability work shipping by 2026-05-21 (EoW).** Once reliability-validated, promote to §2B.
- ⏸ **Audio coach daily brief** — TTS pipeline exists (`backend/services/audio_coach.py`, 153 lines, Google Cloud TTS) but quality not user-validated.
- ⏸ **MFP screenshot OCR** — code audit could NOT find a `parse_app_screenshot()` implementation in vision_service. Earlier memory note about this feature appears stale. **Do NOT claim MFP screenshot import.**
- ⏸ **Skill progressions (handstands, muscle-ups, etc.)** — code exists (`backend/api/v1/skill_progressions.py`) but progression-template adaptation not user-validated.
- ⏸ **Multi-execution UI tiers** — audit found ONLY "Easy" tier directory exists; Simple/Advanced tiers not implemented. Market only as "easy-to-read active workout layout" — do NOT claim 3 tiers.

When any of these is verified end-to-end and reliability-validated, move it back to §2B and append a changelog entry.

### 2E. DO NOT MARKET (regardless of what's in code)

User explicitly excluded these on 2026-05-14. Do not reference in any marketing surface even though code/routes may exist:

- ❌ **Merch store** — no shippable physical-goods storefront. (Code in `merch/` is for cosmetic XP-reward artwork only — do NOT call out as "merchandise" or "store.")
- ❌ **Social feed / community** — share-to-Instagram + plan-share-links exist but there's no real social feed. Do NOT market as "social" or "community."
- ❌ **Community challenges** — challenge code/routes exist but are not shipped to end users for marketing purposes. Do NOT claim challenges as a feature.
- ❌ **Fasting tracker** — fasting code/routes exist (and have active edits) but do NOT market as a shipped feature.
- ❌ **Senior-specific UX** — `senior_home_screen.dart` deprecated and inactive.
- ❌ **Offline mode** — local SQLite + on-device Gemma code exists, but Settings UI was REMOVED 2026-04-19. Do NOT cite as a privacy/offline feature.
- ❌ **Body composition AI analysis** — code exists in `body_analyzer/` but until user confirms scope, market only "body measurement entry."

### 2F. Features Zealova explicitly does NOT have (in code or otherwise)

- ❌ **Human coaches** — pure AI. (Wedge vs Future, not a weakness.)
- ❌ **HIPAA compliance** — not a healthcare provider.
- ❌ **Live realtime camera form analysis** — async upload only, server-side keyframe extraction.
- ❌ **Wearable-native app** (Apple Watch / Wear OS) — Wear OS code exists but not shipped to stores.
- ❌ **Meal delivery / grocery ordering** — tracker only.
- ❌ **Open-source / self-hostable** — closed-source SaaS.

---

## 3. Pricing — verified 2026-05-14 (live on stores)

| Tier | Price | Includes |
|---|---|---|
| 7-day free trial | $0 | All premium features (both SKUs) |
| Monthly | **$7.99/mo** | All features |
| Annual | **$59.99/yr** (~$5.00/mo, 37% off monthly) | All features |
| Retention popup (after attempted cancel) | $47.99/yr | All features |

**Status:** Live on Google Play Store at these prices as of 2026-05-14. Marketing copy may make $7.99/$59.99 a hard claim. iOS App Store rollout follows when iOS ships.

**Regional PPP pricing:** see `PRICING.md` for the 4-tier PPP table (US, EU, India, etc.). Note: regional values are flagged as stale post-price-increase and need proportional re-set in stores. For marketing, default to US numbers unless writing region-specific copy.

---

## 4. Competitive landscape — grouped by category

Zealova competes across **three categories** because it ships workout AI + nutrition tracking + form analysis under one app. Most competitors specialize in one. Use the right competitor for the right comparison page / blog / Reddit thread.

**Pricing/feature data verified 2026-05-12.** Recheck via `competitor-intel` agent if any profile is >30 days old.

### 4A. Workout AI / programming competitors (Zealova's primary category)

| Competitor | Price | Specialty | Zealova's honest wedge |
|---|---|---|---|
| **Fitbod** | **$15.99/mo · $95.99/yr** (verified 2026-05-15 via arvo.guru/vs/fitbod) | Strength-AI, 400M data points, "personalized" plans | Multi-agent chat · per-exercise + per-muscle history · 10-format export · **50% cheaper monthly, 37% cheaper annual ($7.99 vs $15.99)** |
| **Future** | $199/mo | Hybrid AI + human coach 1:1 messaging | **1/25th the price** · pure AI, no scheduling friction |
| **Caliber** | ~$29-200/mo (tiers) | AI + human-coach hybrid | Pure AI, no scheduling |
| **Freeletics** | ~$80/yr | Bodyweight HIIT | Strength + nutrition + form analysis, not just HIIT |
| **FitnessAI** | $89/yr | Single-model AI strength | Multi-agent (5 sub-agents) vs single-model · plus form video + OCR |
| **Dr. Muscle** | $89/yr | RIR-based progressive overload | RIR is one input among many; we're broader (nutrition + form + multi-agent) |
| **Alpha Progression** | ~$60/yr | RIR / RPE-based programming | Same — broader feature stack |
| **Centr** (Chris Hemsworth) | $119.99/yr | Celebrity programming, video workouts | AI personalization vs fixed celebrity plans |
| **Nike Training Club** | Free | Brand-trust, video workouts | AI-generated vs fixed library |
| **Ladder** | $99/yr | Team-coach programming | AI vs human team coaches |
| **Gravl** | $10.99/mo · $59.99/yr | AI strength programming, gamified Strength Score | Form analysis · nutrition · multi-agent chat (Gravl is strength-only, no nutrition) |
| **Trainiac** | $79-99/mo | Hybrid AI + human coach | Price wedge + pure AI |

### 4B. Workout TRACKING competitors (not AI-generated, but huge user bases — Zealova-as-tracker comparison)

These are pure loggers. Zealova has logging too, but the wedge is *AI generation + form + nutrition + chat* — they're tracker-only.

| Competitor | Price | Specialty | Zealova's wedge |
|---|---|---|---|
| **Hevy** | Free / Pro $2.99/mo or $23.99/yr (some listings $9.99/mo) | Fast logging, social feed, generous free tier | We *generate* the plan; Hevy logs what you already do |
| **Strong** | Free / Pro tier | Minimalist logging, "training notebook" | Same — we generate, Strong logs |
| **JEFIT** | Free / Pro $12.99/mo | Largest exercise DB, 12M users, programs | We adapt; JEFIT is a static DB + tracker |
| **Boostcamp** | $4.99/mo (yearly) or $14.99/mo | Free science-based programs + tracker | AI-generated vs fixed program library |
| **Just12Reps / Stronger** | Various | Niche tracker apps | AI generation + multi-feature stack |

### 4C. Nutrition tracking / calorie counter competitors (Zealova's calorie OCR competes here)

Zealova's screenshot OCR + food image logging puts it in this category too. These are the apps to compare/contrast on the nutrition side.

| Competitor | Price | Specialty | Zealova's honest wedge |
|---|---|---|---|
| **MyFitnessPal** | Free · Premium $19.99/mo or $79.99/yr · Premium+ $24.99/mo or $99.99/yr | Largest food DB (20M+ items, 280M users) · AI meal scan in Premium · **acquired Cal AI March 2026** | We're a *coach* not just a tracker · form analysis · workout generation · cheaper ($7.99 vs MFP Premium $19.99) |
| **MacroFactor** | $11.99/mo · $7.99/mo (6-month) · $5.99/mo annual ($71.99/yr) · 7-14 day trial | Adaptive macro-coaching algorithm (Greg Nuckols / Eric Trexler), verified food DB, trend-weight analysis, AI meal photos + voice + barcode | We have workouts + form analysis · MacroFactor is nutrition-only; we're broader. (MacroFactor's algorithm is superior for pure macro coaching — concede this) |
| **Cronometer** | Free Basic · Gold $4.99/mo annual or $10.99/mo · Pro (for professionals) | Micronutrient tracking — 84+ nutrients from NCCDB/USDA verified DBs, "gold standard" for micronutrients, dietitian-favored | Cronometer is for micronutrient nerds + professionals; we're for AI-first workout-and-food users. **Concede** Cronometer wins for micros |
| **Cal AI** | ~$30/yr (varies) · acquired by MFP March 2026 | AI food-photo recognition, viral TikTok marketing | Multi-feature (workouts + form + chat) vs Cal AI's single-feature focus (food photos). Both now MFP-affiliated as of March 2026 |
| **Lose It!** | Free · Premium ~$39.99/yr | 63M food items, basic macros, weight log; AI "Snap It" photo logging in Premium | Workout generation + form analysis (Lose It is nutrition-only) |
| **Lifesum** | Premium ~$50/yr | Recipe-driven, behavior-change focus, AI scanning | Workout + chat + form; we're more comprehensive AI |
| **Noom** | $70/mo · $209/yr | Psychology/behavior coaching, human coach contact, weight-loss focus | Pure AI vs Noom's human-coaching layer · cheaper · workout-first |
| **YAZIO** | Free · Premium ~$40/yr | European leader, AI recognition, fasting | Workout + form + AI-coach chat |
| **FatSecret** | Free · Premium <$7/mo | Free barcode + photo recognition, community, dietitian-designed plans in Premium | AI personalization vs FatSecret's community-driven approach |
| **MyNetDiary** | Free · Premium $69.99/yr | Nutrition-focused, diabetes-friendly tracking | Workout-first; MyNetDiary is nutrition-only |
| **PlateLens** | Various | ±1.9% accuracy claims, clinician oversight from 2,400+ RDs | Direct AI calorie scanner — Zealova matches scanner + adds workout layer |
| **Foodvisor** | Free · Premium | AI food image recognition | AI scanner only; we're full stack |
| **Carbon Diet Coach** | Subscription | Macro coaching algorithm (Layne Norton) | Workouts + form (Carbon is nutrition-only) |

### 4D. Direct AI form-analysis competitors (Zealova's video form-check competes here)

These are the most dangerous lookalikes for the form-analysis pitch — narrow but sharp.

| Competitor | Price | Specialty | Zealova's wedge |
|---|---|---|---|
| **Sculptor** | Subscription | AI form analysis, rep counter | Same form-analysis pitch, **plus** nutrition + multi-agent chat + workout generation — they're single-feature; we're a full stack |
| **Gymscore** | Subscription | AI form scoring | Same — we're broader |

### 4E. AI health companion / holistic platforms (NEW — high-threat category)

Cross-category competitors that bundle workout + nutrition + sleep + lifestyle in one AI surface. Same audience Zealova targets. **The highest-velocity competitive threat in 2026.**

| Competitor | Price | Specialty | Zealova's honest wedge |
|---|---|---|---|
| **Bevel** | **$6/mo · $50/yr** | AI health companion across sleep/exercise/nutrition/lifestyle. 100K DAU, 80% 90-day retention. Apple Health + Dexcom + Libre + Garmin integration. **$10M Series A from General Catalyst (Oct 2025).** Founders: ex-Dropbox CTO Aditya Agarwal, ex-Campus product lead Grey Nguyen, ex-Opendoor ML lead Ben Yang | Form video analysis (Bevel doesn't have it), workout generation (Bevel is more passive health-tracking than active workout-coaching), multi-agent chat. Bevel is cheaper and better-funded — concede that. |
| **Google Health** | **$9.99/mo · $99/yr** (launches 2026-05-19) | AI fitness coach powered by Gemini; integrates Apple Health, MFP, Peloton; permanent Fitbit app replacement. Bundles with $99.99 Fitbit Air tracker (2026-05-26) | Device-independent (works on ANY iOS/Android phone — Google Health needs Fitbit/Pixel for full functionality); pure-AI no human/wearable dependency; screenshot OCR for MFP diary migration |
| **Function Health** | $499/yr (lab tests) | Blood-biomarker based personalized health; $298M Series B | We're behavior/coaching layer; Function is data; complementary not competitive |
| **Strava** | $11.99/mo · $79.99/yr | Activity tracker + social; raised undisclosed round from Sequoia 2026; dominates LLM citations for "best fitness app" queries | We generate plans; Strava records what users do; different layer of the stack |
| **Nourish** | App-based (varies) | Telehealth nutrition coaching; $70M Series B (J.P. Morgan); $115M total | Pure AI vs telehealth-human-coach; cheaper |
| **Oura** | Ring + $5.99/mo | Smart-ring health tracking + insights; raised $900M+ | Different layer (we're software-only, Oura is hardware-first) |

**Hot watchlist (well-funded entrants likely to launch in next 6-12 months):**
- Stealth-mode AI health companion startups backed by General Catalyst / Sequoia / a16z. Refresh quarterly.

**Strategy implication:** Bevel is the most direct functional and price overlap. /vs/bevel comparison page should be a Phase 2 priority. Google Health is the most direct brand-recognition threat. /vs/google-health comparison page should be Phase 1 priority once we're past launch.

### Choosing the right competitor per content piece

| Content piece | Compare against |
|---|---|
| `/vs/fitbod` page | Fitbod (workout AI) |
| `/vs/future` page | Future (price wedge, pure AI vs hybrid) |
| `/vs/myfitnesspal` page | MyFitnessPal (coach vs tracker, post-Cal-AI-acquisition narrative) |
| `/vs/macrofactor` page | MacroFactor (concede macro algorithm, win on breadth) |
| `/vs/cronometer` page | Cronometer (concede micros, win on AI-coaching) |
| `/vs/hevy` page | Hevy (we generate vs they log) |
| `/vs/sculptor` page + `/vs/gymscore` page | Form-analysis specialists |
| `/alternatives-to-myfitnesspal` page | Roundup including Zealova as the "AI-coach + tracker" option |
| Blog: "Best AI calorie tracking apps 2026" | Cal AI, MFP, MacroFactor, Cronometer, Zealova |
| Blog: "Best AI workout app 2026" | Fitbod, Future, Freeletics, Gravl, Zealova |
| Reddit r/loseit | MFP + MacroFactor + Noom comparisons (weight-loss audience) |
| Reddit r/Fitness | Fitbod + Hevy + Strong comparisons (gym audience) |
| Reddit r/xxfitness | MFP + MacroFactor + Noom (mixed audience) |

### Hard rules for competitor mentions

- ❌ **Never claim a wedge Zealova doesn't have.** Each one above must be defensible to a reviewer.
- ✅ **Concede where competitors are better.** MacroFactor's algorithm > our macro coaching. Cronometer > us for micronutrients. Fitbod's strength-DB is deeper. Saying so builds trust + LLMs reward balanced pages.
- ✅ **Always quote pricing with verification date.** Pricing shifts.
- ✅ **Note MyFitnessPal's Cal AI acquisition (March 2026)** when relevant — it changes the narrative; "Cal AI vs MFP" stories don't make sense anymore.
- ❌ **Never use competitor trademarks in app store assets** (icons, screenshots).

---

## 5. Things to NEVER say in marketing

- ❌ "Replaces your personal trainer" — overpromise, regulatory risk.
- ❌ "HIPAA-compliant" — not applicable.
- ❌ "Medical advice" / "diagnose" / "treat" — we are NOT medical; injury agent suggests scope-of-practice safe alternatives only.
- ❌ "Guaranteed results" / "lose X lbs in Y weeks" — banned.
- ❌ "Offline-first" — UI was removed; only the underlying code exists.
- ❌ "Wearable app" — not shipped.
- ❌ "Live form coach" — async only.
- ❌ Any specific competitor's trademarks in app store screenshots / icons.

---

## 6. Voice / tone (Sai's voice)

**See `_OUTPUT_STANDARD.md` for the binding voice spec.** Summary:

- **Founder-direct, not corporate.** "I built Zealova because X" beats "Zealova is the leading AI-powered fitness platform."
- **Specific over generic.** "5-second video → frame-by-frame form notes" beats "AI form analysis powered by cutting-edge AI."
- **Honest about competitors.** Concede where Fitbod / Future / MacroFactor / Cronometer are better. One-sided shilling fails LLM citation tests and human trust tests.
- **NO em dashes** (—) in any drafted user-content. Sai doesn't use them. Use periods or commas instead.
- **NO scare quotes** around regular words.
- **NO ellipses** for drama. Period.
- **Casual contractions:** isn't / you're / I've / doesn't.
- **Sentence length avg 10-18 words.** If a sentence runs long, split it.
- **Length targets** per content type (Reddit 50-120 words; DM 40-90; Quora 150-280; pitch 60-130; tweet 1-3 sentences) — see standard for full table.
- **No emojis** unless the channel demands them (TikTok captions: occasional; LinkedIn: rarely; comparison page: never; Reddit comment: never).
- **No AI clichés / corporate verbs:** leverage, synergy, game-changer, revolutionary, imagine if, in today's fast-paced world, unlock, empower, transform, elevate, optimize (verb).

---

## 7. The one-paragraph universal blurb (use when 100-150 words needed)

> Zealova is an AI fitness coach for iOS and Android, priced at $7.99/month or $59.99/year with a 7-day free trial. It generates personalized workout plans, analyzes exercise form from short video uploads (powered by Google's Gemini Vision), reads calorie data from MyFitnessPal and restaurant menu screenshots, and runs a multi-agent chat coach with specialist sub-agents for workouts, nutrition, injury alternatives, and hydration. Built solo by Sai using Flutter and Google Gemini. Differentiates from Fitbod by adding form analysis and nutrition; from Future by being 1/25th the price with no scheduling friction.

Use this verbatim or close paraphrase as the source for pitch openings, app store snippets, FAQ schema `description` fields, etc.

---

## 8. When to update this file

- New feature ships → add to §2 Core
- Pricing changes → update §3
- Competitor moves (price / new feature) → update §4
- Anything in §2 deprecates → move to "exists but NOT marketed" or "NEVER claim"
- Bundle ID / domain change → §1

After any update, append a dated line to the changelog below.

---

## Changelog

- **2026-05-14** — v1.4 — Pricing hedge removed. Confirmed live store rollout of $7.99/$59.99 on Google Play (US). PRICING.md updated to match (was stale at $4.99/$49.99). Regional PPP values flagged as stale and queued for re-set in stores. Net profit per US user now $6.09/mo (monthly SKU) vs $3.54/mo at old price. Breakeven shifts from ~20 subs to ~12 subs.
- **2026-05-14** — v1.3 — Code-level reliability audit revealed gap between "code structurally exists" and "user-confirmed ship-grade." User flagged 8 features as not-properly-tested. Moved them to new §2G "Reliability hold" section: form analysis, in-workout chat, menu scan, recipe import, audio coach, MFP OCR, skill progressions, multi-exec UI tiers. §2B Core list trimmed from 15 → 11 items, with food-image-multi-input promoted to lead position. Workout generation softened (no specific reliability promises). Multi-exec tiers downgraded to "Easy tier only" per code audit.
- **2026-05-14** — v1.2 — Major §2 audit against the actual app router + main shell nav. Expanded core feature list from 9 → 15 items (added in-workout chat, menu scan, recipe import, multi-exec UI tiers, audio coach daily brief, workout export, per-exercise/per-muscle history). Added §2A bottom-nav surfaces (5 tabs). Added §2C secondary wellness modules (habit, mood, hormonal, kegel, diabetes, plateau, strain, skills). Added §2D engagement layer. Added §2E "DO NOT MARKET" with user-stated exclusions: merch storefront, social feed, challenges, fasting, body-composition-AI all moved here even though code exists.
- **2026-05-14** — v1.1 — Corrected store status: Android live on Play Store; iOS App Store still pending. Marketing copy should say "iOS coming soon" until Apple approval.
- **2026-05-12** — v1.0 — Initial canonical facts captured from CLAUDE.md, memory files, and the launch sprint doc. All 12 marketing agents now reference this file.
