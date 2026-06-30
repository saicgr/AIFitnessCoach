# Zealova Screenshot Deck — 2026-06 Update

**Status:** DRAFT — awaiting founder review and approval before paste into Play Console / App Store Connect.
**Scope:** Complete rebuild. Prior deck (PLAY_STORE_SCREENSHOTS.md, last updated 2026-05-18) is one full reskin + 442 net-new-feature commits out of date. Do NOT overwrite the canonical PLAY_STORE_SCREENSHOTS.md until this draft is approved.
**Date:** 2026-06-29
**Authored by:** ASO Optimizer (live research run 2026-06-29)

---

## Section 1 — Current trends (live research, 2026-06-29)

**ASO screenshot trends (sourced live this run)**

- [AppScreenshotStudio, Medium 2026](https://medium.com/@AppScreenshotStudio/app-store-screenshots-that-convert-the-2026-design-guide-4438994689d6) — "Screenshot Story Flows" are the dominant 2026 framework. The winning arc is Value-Flow-Trust (Problem in frame 1-2, Solution in frame 3-5, Trust in frame 6-8). Single-feature enumeration screenshots are losing to cohesive mini-narratives.
- [AppScreenshotStudio, Medium 2026](https://medium.com/@AppScreenshotStudio/in-2026-the-battle-for-user-attention-on-the-app-store-and-google-play-is-no-longer-won-by-6fe9f70c707c) — Caption ceiling has dropped: five words max (down from the 2-6 range in prior guides). Captions that can't survive a squint test at thumbnail size disappear in search results.
- [AppFollow 2026](https://appfollow.io/blog/aso-screenshots-best-practices) — First three frames carry 70% of conversion weight (up from the 60% figure in Zealova's May notes). One idea per frame is non-negotiable — frames explaining 3 ideas at once break the narrative and hurt conversion.
- [TheAppLaunchpad 2026](https://theapplaunchpad.com/blog/google-play-store-screenshot-requirements/) — Google Play technical update: design for 1080x2400 (20:9, Pixel 9 / Galaxy S25 era) not 1080x1920. Still accepts 1080x1920 but modern device fit is better at 2400. Cap confirmed at 8 screenshots per phone device type.
- [ScreenshotWhale 2026](https://screenshotwhale.com/blog/aso-ab-testing) — A/B tests need 7+ days and 25K impressions per variant to reach 90% confidence. Test ONE element per experiment — screenshot copy, frame order, or background color — never bundle changes.
- [MobileAction 2026](https://www.mobileaction.co/guide/app-screenshot-sizes-and-guidelines-for-the-google-play-store/) — Feature graphic (Play-only, 1024x500) now meaningfully influences CTR in category browse and featured placements. Avoid dead center (Play button overlay covers it). Single benefit, one powerful image.
- [ASO statistics 2026, DigitalApplied](https://www.digitalapplied.com/blog/app-store-optimization-aso-statistics-2026-data) — Tap-through-to-install: 33.4% iOS / 27.7% Play average. Health & Fitness is at the lower end of organic install influence (27-41% of installs from ASO surfaces). Screenshots are the highest-leverage lever in this category.
- [ASO Trends, Appalize 2026](https://www.appalize.com/cs/blog/mobile-trends/aso-trends-and-benchmarks-2026-what-the-data-shows) — Apps that A/B test screenshots quarterly see 20-30% higher conversion rates than apps that update screenshots annually.

**Fitness category competitor moves (last 30 days)**

- Gravl (verified 2026-06-25, v1.45-1.46): Major release — workout share editor, progress photos, Strength Score upgrades, streak rewards, Apple Health background sync. NO new conversational AI, no nutrition, no form analysis improvement. Their screenshot deck likely still leads with Strength Score + adaptive programming (moat unchanged, gap intact).
- Google Health / Fitbit (launched 2026-05-19): Rebranded from Fitbit to "Google Health" on App Store. Subtitle: "Your personalized health coach." Description leads: "The Fitbit app is now Google Health, bringing out your best with effortless tracking and personalized coaching that's built with Gemini." 4.5 stars, 676K ratings. Requires Fitbit hardware for full functionality — hardware dependency is their exposed wedge.
- Sculptor (as of 2026-06-29): "Train Smarter with Your Camera." 5.0 stars but only 4 ratings — still very early. Single feature: auto rep count + form analysis. No workout generation, no nutrition.
- Gymscore (as of 2026-06-29): "AI workout & lifting tracker." 4.0 stars, 21 ratings. 5-dimension form scoring, on-device privacy. Single feature.
- MacroFactor (as of 2026-06-29): "Calorie Counter & Food Log." 4.8 stars, 18K ratings iOS. Nutrition-only, no photo AI per 2026 research — confirmed no food photo logging as of search run.
- MyFitnessPal acquisition of Cal AI (closed March 2026): Cal AI now operates within the MFP ecosystem. MFP Premium still at $19.99/mo vs Zealova $7.99/mo.
- Hevy (updated June 24 2026): "Weight Lifting Routine Planner." 4.9 stars, 77K ratings. Manual logging, no AI generation — gap vs Zealova unchanged.

---

## Section 2 — Why these matter for THIS output

- Story Flows replace enumeration → the old Zealova deck (frames 1-8 as independent feature callouts) needs a cohesive narrative arc, not just "here's a feature per frame."
- Five-word caption ceiling → all captions below are 5 words or fewer for the main line. Sub-captions stay at 8-12 words (unchanged from prior spec).
- 70% weight in first 3 frames → frames 1-3 must each stand alone as a complete install reason. The two hard-constraint features (menu scan, program customizability) must both land within the first 6 frames, with customizability at frame 3 (within the decision window) and menu scan at frame 5 (still well within normal scroll depth).
- Gravl's screenshot deck leads with Strength Score / adaptive programming — Zealova can counter-position with Program Library + customizability (Gravl has neither), which is a visible structural differentiator in side-by-side category browse.
- Google Health uses "personalized health coach" framing on subtitle — Zealova's frame 1 should anchor the "coach" claim differently. Zealova's wedge is specific AI capabilities (form video, menu scan, program library, multi-agent chat) that Google Health lacks or requires hardware for.
- Sculptor/Gymscore are single-feature form-analysis apps with very few reviews — Zealova's form check frame can position as "form check inside a full coach, not a standalone camera app."
- MacroFactor has no food photo logging — Zealova's menu scan frame is a clean win against the nutrition category's #2 app.
- Play technical spec: design at 1080x2400, not 1080x1920, to fit modern Android screens.
- Feature graphic matters now → add a Play-specific feature graphic spec to this deck.

---

## Section 3 — What I'm generating

Because of the above, this run produces:

- A complete Play Store core-8 frame deck (1080x2400 design target), replacing the outdated May deck in PLAY_STORE_SCREENSHOTS.md (which has an Exercise Detail frame at slot 2, a chat-swap frame at slot 4, and no Program Library or form check at all).
- An App Store extension to 10 frames (slots 9-10 added).
- Per-frame: main caption (5 words max, accent word marked), sub-caption (8-12 words, concrete number or timeframe), background color, exact in-app capture state, staging pre-conditions, and shippability flags for any frame whose feature needs staging setup.
- A Play feature graphic (1024x500) spec.
- Frame-1 badge guidance for the capability-pill-to-social-proof progression.
- A 30-second app preview video beat sheet.
- A competitor positioning note per frame where Zealova directly out-positions a named competitor.

---

## Competitor Screenshot Teardown (live, 2026-06-29)

### Fitbod — "AI Personal Trainer & Workouts" (App Store subtitle)
- **Frame 1 hook:** "Build muscle, gain strength and lose weight" — outcome-first, three goals in one line.
- **Caption style:** Benefit headline at top, dark background in phone.
- **Visual pattern:** Dark mode UI dominant. Progressive overload bars visible. Data-rich workout screens.
- **Screenshot arc (inferred):** Personalized plan → exercise detail → muscle recovery → progress → history.
- **Social proof:** 275K iOS ratings (4.8 stars). 4.6 Play (20K+). Very credible — no cap at thumbnail.
- **Program framing:** Shows pre-built programs but NOT a cinematic carousel or variant selector. Static list.
- **Customization framing:** Equipment selector visible but no "swap days / per-gym" visible in screenshots.
- **Nutrition/scan:** None.
- **Form analysis:** None.
- **Zealova out-position:** Program Library with HYROX cinematic hero + variant selectors, menu scan, AI form check, multi-agent chat, $7.99 vs $15.99/mo.

### Hevy — "Weight Lifting Routine Planner" (App Store subtitle)
- **Frame 1 hook:** Social + fast logging. "10M+ athletes" social proof prominent.
- **Caption style:** Benefit-first. Clean, minimal overlays.
- **Visual pattern:** Light and dark mode mix. Community feed screenshots visible. Fast-log UI.
- **Social proof:** 77K iOS ratings (4.9 stars) — extremely strong. Free tier.
- **Program/customization framing:** Routines visible but all manual — no AI generation, no program library.
- **Nutrition/scan:** None.
- **Zealova out-position:** AI generates the plan (Hevy just logs what you already decided). Program Library, form check, nutrition coach.

### MacroFactor — "Calorie Counter & Food Log"
- **Frame 1 hook:** "Reach your diet goals with the smartest macro tracker" — algorithm-first positioning.
- **Caption style:** Short, confident captions. Clean white/light backgrounds with dark in-phone.
- **Visual pattern:** Charts, trend lines, macro rings. Clinical precision aesthetic.
- **Social proof:** 18K iOS ratings (4.8 stars). Niche but loyal.
- **Nutrition/scan:** No food photo AI as of 2026 — confirmed by research. Barcode + manual only.
- **Zealova out-position:** Food photo logging + menu scan (MacroFactor has neither). Workout generation. Form check. Zealova is a coach; MacroFactor is a calculator.

### Sculptor — "Train Smarter with Your Camera"
- **Frame 1 hook:** Camera-first. "Auto-count reps + form feedback."
- **Caption style:** Action-verb subtitle ("Train Smarter with Your Camera") — clean and specific.
- **Visual pattern:** Camera viewfinder + rep counter + form overlay. Very focused on one screen.
- **Social proof:** 4 ratings — essentially zero social proof. New app.
- **Zealova out-position:** Form check inside a full coach (workout plans + nutrition + form + chat). Not a standalone camera app. Zealova is the full stack.

### Gymscore — "AI workout & lifting tracker"
- **Frame 1 hook:** 5-dimension form scoring. "Record your workout and get it reviewed."
- **Caption style:** Technical/specific. Privacy angle (on-device analysis).
- **Social proof:** 21 ratings. Also nearly zero.
- **Zealova out-position:** Same as Sculptor — full stack vs single feature.

### Google Health (formerly Fitbit) — "Your personalized health coach"
- **Frame 1 hook:** "Built with Gemini. Personalized AI fitness plans, sleep insights, and health data."
- **Caption style:** Broad lifestyle framing. "You set the vision. Google Health brings together your fitness, sleep, and wellness."
- **Visual pattern:** Likely lifestyle + dashboard hybrid. Health hub across all metrics.
- **Social proof:** 676K ratings (4.5 stars) — massive brand trust.
- **Key gap:** Requires Fitbit or Pixel hardware for full functionality. No restaurant menu scan. No program library with HYROX. No form video critique. No multi-agent chat with workout/nutrition/injury specialists.
- **Zealova out-position:** Hardware-independent. Menu scan. Program Library. AI Form Check. $7.99 vs $9.99/mo.

### Freeletics — 4.64 stars
- **Key metric they lead with:** "60 million athletes. 700+ exercises. 1 trillion workout combinations."
- **Visual pattern:** High-energy, dark backgrounds. Lifestyle/fitness model photography.
- **Gap:** Bodyweight HIIT focus. No nutrition scan. No form video. No program library.
- **Zealova out-position:** Strength programming + nutrition + form analysis. Freestyle exercise intelligence vs fixed HIIT combinations.

### Noom — 4.7 stars
- **Visual style:** Black/white/red. Sans-serif. Minimalist. "Informative, Friendly, Supportive" — notably different from muscle-centric fitness app aesthetics.
- **Screenshot arc:** Behavior change + coaching-first. Not gym-centric.
- **Gap:** Human coaches at $70/mo. No workout AI. No form analysis. Weight-loss behavior focus.
- **Zealova out-position:** Pure AI ($7.99 vs $70/mo). Workout generation. Form analysis. All-in-one vs nutrition-only behavior coaching.

### Caliber
- **Positioning:** "Science-based strength training." AI + human coach hybrid.
- **Gap:** $29-200/mo tiers. No restaurant menu scan. No Program Library.
- **Zealova out-position:** Price ($7.99 vs minimum $29). Pure AI with equivalent programming depth.

### Pattern that wins in fitness category (2026):
Dark-mode in-phone + cream/neutral frame background + 1-2 line benefit headline at top + single focal point per frame. The Mob-inspired style (which Zealova's house template already uses) IS the category-winning pattern. The main 2026 update is the narrative arc: frames must tell a mini-story, not just list features. Gravl leads with Strength Score; Google Health leads with "Gemini AI + all your health data." Both are broad hooks. Zealova's competitive move is specificity — "Program Library with HYROX" and "Snap a restaurant menu" are images that convert because they're visual and concrete.

---

## 2026 ASO Best-Practice Refresh (vs. May 2026 baseline in PLAY_STORE_SCREENSHOTS.md)

The May 2026 baseline spec already had most of the fundamentals right. Here are the updates that apply to this rebuild:

| Rule | May 2026 baseline | 2026-06-29 update |
|---|---|---|
| Main caption length | 2-6 words | 5 words MAX. Shorter wins. |
| Design resolution (Play) | 1080x1920 | 1080x2400 preferred (20:9 for Pixel 9 / Galaxy S25) |
| Narrative structure | Frames as independent feature callouts | Story Flow arc required: Problem → Solution → Trust |
| Frame 1 weight | "~90% don't scroll past frame 3" | 70% of install weight now attributed to frames 1-3 |
| Social proof placement | Frame 1 pill, frames 2/3/6 testimonials | Trust signals belong in frames 6-8 (Act 3). Frame 1 = value, not proof. |
| Feature graphic | Not specced | Now meaningfully affects CTR. Add spec. |
| A/B testing window | Not specced | 7 days minimum, 25K impressions per variant |
| Caption text area | Not specced | Must be under 20% of image area (Play compliance) |

---

## Final Ranked Deck

### Story Arc

```
Frame 1: WHAT IT IS (coach category positioning, home redesign)
Frame 2: THE LIBRARY (real curated programs, HYROX — browse and start)
Frame 3: MAKE IT YOURS (customizability — required)
Frame 4: FILM A SET (AI Form Check — category differentiator)
Frame 5: SNAP THE MENU (menu scan — required, highest visual wow)
Frame 6: YOU ARE READY (Easy mode active workout — calm, guided)
Frame 7: JUST SAY IT (multi-input chat logging — effortless)
Frame 8: THE PAYOFF (Overload Dashboard — strength climbs)
```

Frames 1-3 = full install-decision window. Every one must stand alone.
Frames 4-5 = category differentiators (form check + menu scan — no competitor has both).
Frames 6-7 = depth proof (in-gym experience + daily use).
Frame 8 = the outcome/payoff that drives trial activation.

---

### PLAY CORE-8 + APP STORE 10

---

#### Frame 1 — Category Positioning (Hero)

**Main caption** (accent word marked with ALL CAPS):
```
Your fitness coach, IN CHAT.
```
5 words. "IN CHAT" oversized, brand green. Accent the differentiator, not the noun.

**Sub-caption:**
*Plans, form checks, meal scores — one app, any question.*

**Background color:** Cream / off-white `#FAF8F4` (Mob-style house template, unchanged)

**In-phone screen:** Signature-v2 Home screen. Show:
- Metric deck visible at top (today's calorie progress, workout ring, steps, sleep)
- Timeline entry for today's workout (card visible)
- Coach nudge card ("Your bench is up 12 lbs this week")
- Clean, dark mode

**Staging pre-conditions:**
- Home screen in dark mode
- At least 1 workout logged today or yesterday for timeline to show
- Calorie intake partially filled (partial ring)
- Coach card showing a real positive progress insight

**Composition (Mob-style):**
- Phone tilted 10-12 degrees clockwise, centered slightly low
- Bottom-left: half a meal bowl (oats + berries) bleeding off
- Bottom-right: dumbbell head bleeding off
- Top-left: capability pill (see Frame-1 Badge section below)
- Top-right: optional herbs or water glass

**Competitor out-position:** Google Health uses "built with Gemini" broad framing. Zealova's "in chat" is more specific and more actionable — it tells the user exactly HOW the AI coaches them.

**Shippability:** CLEAN. Home screen is stable; metric deck and timeline shipped in this cycle (redesigned). Stage with care to show meaningful data.

---

#### Frame 2 — Program Library (Browse)

**Main caption:**
```
Real programs. PICK YOURS.
```
4 words. "PICK YOURS" oversized, brand green.

**Sub-caption:**
*HYROX, hypertrophy, strength — built by experts, tailored by AI.*

**Background color:** Deep charcoal `#1A1A2E` (dark, cinematic — matches the in-app hero carousel aesthetic)

**In-phone screen:** Program Library browse screen. Show:
- Cinematic hero carousel at top — HYROX card prominent (hero image + program name + level badge)
- At least 2-3 program cards partially visible below (e.g. Push/Pull/Legs hypertrophy, 5-day strength)
- Variant selector visible (duration dropdown showing "8 weeks / 12 weeks / 16 weeks")
- Browse filter pills at top (All / Strength / HYROX / Hypertrophy / Beginner)

**Staging pre-conditions:**
- Program Library screen loaded with HYROX in hero position
- At least 4 programs visible in the carousel
- Variant selector open on a program that has multiple duration options

**Composition:**
- Single phone, centered, slight tilt
- Dark background (no prop objects — let the dark frame background feel cinematic, matching the in-phone dark)
- Caption at top in white/cream text
- "PICK YOURS" in brand green

**Competitor out-position:** Fitbod has a programs list but not a cinematic carousel with HYROX or variant selectors. Hevy has community routines. Neither has a hero program browse experience. Gravl has no program library at all.

**Shippability:** CLEAN if program library is populated. Pre-condition: HYROX program must be live with variants in the library.

---

#### Frame 3 — Program Customizability (Make It Yours) — REQUIRED

**Main caption:**
```
Built for YOUR gym.
```
4 words. "YOUR" oversized, brand green.

**Sub-caption:**
*Swap days, pick your gym, let AI tailor every week.*

**Background color:** Warm indigo `#3D3A6B`

**In-phone screen:** "Edit Program" sheet / unified 6-step editor. Show the customize view with:
- Day reorder visible (drag handles on workout days — "Leg Day" being dragged to Tuesday)
- Gym assignment picker (dropdown showing "Home Gym" / "Iron Athletics" / "Hotel Gym")
- AI-tailor toggle active ("Tailor to my equipment: ON")
- "Save" button visible at bottom
- Program name at top ("My HYROX 12-Week Plan")

Alternative: If the tabbed customize view is more visually clean, show the tab headers (Days / Gym / Exercises / Goals) with the "Gym" tab open showing the per-day gym assignment grid.

**Staging pre-conditions:**
- An assigned program (HYROX or any 5+ day split)
- At least 2 gym profiles created (so the picker shows a real choice)
- AI-tailor toggle visible and set to ON
- Day reorder in mid-drag state (requires a screenshot with drag animation — may need a screen record frame or manually set state)

**Competitor out-position:** No competitor combines day-swap + per-gym assignment + AI-tailor in one screen. Fitbod adjusts exercises but can't rearrange program days. Gravl has no program customization at all. This frame is the strongest structural differentiator in the deck.

**Shippability:** MODERATE EFFORT. The drag-in-progress state is hard to screenshot naturally. Recommend either: (a) use a static state showing the day list reordered but not mid-drag, or (b) record a short clip of dragging and extract a clean frame. The "Gym" tab open showing per-day gym assignment is likely cleaner and stageable.

---

#### Frame 4 — AI Form Check (Category Differentiator)

**Main caption:**
```
Film a set. GET COACHED.
```
5 words. "GET COACHED" oversized, brand green.

**Sub-caption:**
*Your squat, your deadlift — real AI notes in 30 seconds.*

**Background color:** Muted amber `#4A3728` (warm, grounded — feels like a gym)

**In-phone screen:** Form check result screen. Show:
- Video frame at top (user performing a squat or deadlift — can be a generic fitness stock frame composited into the phone, or a real staged video frame)
- AI critique card below: overall form score (e.g. "7.4 / 10")
- 3-4 critique items visible: "Depth: Good — reached parallel" / "Knee cave: Slight inward collapse at bottom — cue knees out" / "Bar path: Slight forward drift — engage lats"
- "Reps counted: 3" at top right
- Clean, readable, clinical format

**Staging pre-conditions:**
- Film a real set (squat or deadlift) with adequate lighting, full body visible
- Submit via AI Form Check in the app
- Wait for Gemini Vision critique to return
- Screenshot the critique card in clean state (no loading spinner, no debug overlay)
- Real session data, real critique text

**Competitor out-position:** Sculptor and Gymscore are single-feature form apps with 4 and 21 ratings respectively. Zealova has full workout generation + nutrition + multi-agent chat + form check. Frame caption should implicitly communicate "inside a complete coach, not a standalone camera app" — the critique card alongside the navigation tabs (bottom nav still visible) signals this is one tab of a larger app.

**Shippability flag:** REQUIRES STAGING. Need to film a real set and get a clean AI critique back. Form video analysis shipped this cycle per user confirmation. Reliability note: `_ZEALOVA_FACTS.md` §2G flagged this as reliability-hold as of 2026-05-14. Confirm with Sai that the full pipeline (upload → keyframe extraction → Gemini Vision → critique display) is reliable before committing to this as a frame. If not yet reliable, substitute with Frame 4-ALT below.

**Frame 4-ALT (if form check not yet screenshot-ready):** Show the Cycle Tracker / Health Hub redesign, titled "Every health signal, ONE HUB." This is a visual differentiator vs competitors who are workout-only. Sub-caption: *Sleep, cycle, mood, steps — all wired to your coach.*

---

#### Frame 5 — Menu Scan (Nutrition Intelligence) — REQUIRED

**Main caption:**
```
Snap the menu. BEST PICK.
```
4 words main, accent phrase. "BEST PICK" oversized, brand green.

**Sub-caption:**
*Scored, ranked, calorie-matched — eat out without guessing.*

**Background color:** Warm peach `#FBE2C8` (unchanged from May spec — warm = food context, proven)

**In-phone screen:** Menu scan result. Show:
- Restaurant menu photo thumbnail at top (small — shows input)
- Parsed dish list below:
  - "Grilled Salmon Salad — 420 cal · 38g protein — Score: 91" + "TOP PICK" badge in brand green
  - "Chicken Caesar Wrap — 680 cal · 32g protein — Score: 74"
  - "BBQ Burger — 890 cal · 45g protein — Score: 52"
- "Best macro fit for your goal: Grilled Salmon Salad" callout under the top pick
- "Log TOP PICK" button visible at bottom

**Staging pre-conditions:**
- Open a real restaurant menu in the app (physical menu or printed menu works)
- Run menu scan (Nutrition tab → camera → menu mode)
- Get a clean result with at least 3 dishes parsed, including a TOP PICK badge
- Screenshot the result screen — no spinner, no loading state

**Competitor out-position:** MacroFactor has no food photo AI (confirmed 2026). MFP has meal scan in Premium ($19.99/mo) but no menu-specific mode with TOP PICK scored ranking. Cal AI is food-photo only, acquired by MFP. No workout AI competitor (Fitbod, Hevy, Gravl) has any nutrition scanning. This frame is a clean win in both category directions.

**Shippability:** CLEAN if menu scan pipeline is reliable. Pre-condition: need a real restaurant menu (physical or PDF) to scan. Output must show 3+ items with scores and TOP PICK.

---

#### Frame 6 — Easy Mode Active Workout (In-Gym Confidence)

**Main caption:**
```
Set by set. YOU'RE READY.
```
5 words. "YOU'RE READY" oversized, brand green.

**Sub-caption:**
*Warm up, lift, rest, repeat — one clean screen guides every set.*

**Background color:** Soft sky `#D6E9F5` (cool, calm — matches Easy mode's intentional palette)

**In-phone screen:** Easy mode active workout screen. Show:
- Current exercise focal: "Barbell Bench Press — Set 3 of 4"
- Weight + reps displayed large and clean (e.g. "80 kg × 8 reps")
- Warmup runner completed (green checkmarks on warmup sets above)
- Rest timer in progress (e.g. "Rest: 1:43")
- Next set preview below ("Set 4: 80 kg × 8 reps")
- Progress indicator (e.g. "Exercise 2 of 6")

**Staging pre-conditions:**
- Start a real workout in Easy mode
- Complete warmup sets so they show as checked
- Be in mid-rest between effective sets (rest timer visible)
- Barbell Bench Press (or any major compound) as current exercise
- Screenshot during rest timer — clean state

**Competitor out-position:** Hevy and Strong have fast logging UIs but they're pure input forms — no warmup runner, no AI-suggested weight, no progressive overload intelligence behind the target weight shown. "80 kg × 8 reps" on Zealova's screen is AI-generated based on your history; on Hevy it's what you type. The caption "YOU'RE READY" communicates that the app has done the thinking — you just have to lift.

**Shippability:** CLEAN. Easy mode was fully shipped this cycle. Need to stage a real workout session in Easy mode. The warmup runner state requires completing warmup sets first.

---

#### Frame 7 — Multi-Input Chat Logging (Effortless)

**Main caption:**
```
Just say what YOU ATE.
```
5 words. "YOU ATE" oversized, brand green.

**Sub-caption:**
*Or what you trained — runs, yoga, anything. Coach hears it.*

**Background color:** Soft green `#D4ECD7` (unchanged from May spec — food/health context)

**In-phone screen:** Coach chat screen. Show 3 stacked exchanges:
1. User: "two chicken tacos and a Corona at dinner" → Nutrition agent reply: macro card (580 cal, 32g protein, 48g carbs, 18g fat) + "Logged to dinner"
2. User: "30 min yoga this morning, pretty easy" → reply: "Logged 30 min yoga (easy intensity, ~120 cal). Nice active recovery day."
3. User: "evening run, 4 miles, easy pace" → reply: "Logged 4-mile run (~400 cal). Today's activity is solid — coach note added."

**Staging pre-conditions:**
- Send each message in a clean chat thread in sequence
- Allow each agent reply to complete before screenshotting
- Screenshot when all 3 exchanges are visible on screen (scroll to fit)
- Do NOT include an exercise-swap message in this thread (hard constraint: exclude coach-swap-as-coach-intelligence framing)

**Competitor out-position:** Strong, Hevy, JEFIT — none support meal logging. Fitbod doesn't do nutrition. Gravl explicitly excludes nutrition. "Two chicken tacos and a Corona" being logged by a voice-style message is a fundamentally different interaction model from every workout competitor.

**Shippability:** CLEAN. Multi-input chat logging is stable (shipped and tested). Staging is straightforward.

---

#### Frame 8 — Overload Dashboard (The Payoff)

**Main caption:**
```
Watch your strength CLIMB.
```
4 words. "CLIMB" oversized, brand green.

**Sub-caption:**
*Every PR tracked automatically. 16 muscle groups. All your lifts.*

**Background color:** Steel blue `#2563EB` (unchanged from May spec — conviction, performance)

**In-phone screen:** Progress / Stats screen — Overload Dashboard (Stats tab, index 1 per project notes). Show:
- Overload Dashboard primary view:
  - Line chart for Bench Press 1RM trending upward (+15 lbs over 8 weeks)
  - Muscle heatmap (front/back body, 16 muscle groups color-coded by volume)
  - "Composite Strength Score: 184" or equivalent metric
  - Recent PR callout badge: "+15 lbs Bench Press — NEW PR"
  - Week-over-week volume comparison bars

**Staging pre-conditions:**
- 20+ workouts logged across at least 6 weeks (for meaningful chart)
- At least one PR detected in last 4 weeks
- Heatmap showing varied muscle coverage (not just one muscle group)
- Stats tab navigated to Overload Dashboard (tab index 1)

**Competitor out-position:** Hevy shows workout history; Fitbod shows volume by muscle; neither shows a composite strength score + PR auto-detection + heatmap all on one screen. Gravl has Strength Score but it's a single number, not a full progressive overload dashboard. The phrase "16 muscle groups" in the sub-caption is a concrete number that convetes at thumbnail.

**Shippability:** MODERATE EFFORT. Requires sufficient workout history (20+ sessions). The QA reviewer account (reviewer@zealova.com, permanently premium) may have this data from testing if it's been used for workouts.

---

### APP STORE EXTENDED SLOTS (9-10)

---

#### Frame 9 — Fridge Scan + Recipes (Secondary Nutrition)

**Main caption:**
```
Open fridge. GET RECIPES.
```
4 words. "GET RECIPES" oversized, brand green.

**Sub-caption:**
*Detect ingredients, generate 3 recipes — high-protein options first.*

**Background color:** Sage green `#D1E8D5`

**In-phone screen:** Fridge scan result. Show:
- Fridge photo thumbnail at top
- Detected ingredient chips: "chicken breast · broccoli · eggs · olive oil · rice"
- 3 recipe cards:
  - "Chicken & Broccoli Stir-Fry — 34g protein · 420 cal · 18 min"
  - "Egg Fried Rice — 22g protein · 380 cal · 12 min"
  - "Chicken Egg Bowl — 41g protein · 390 cal · 10 min"
- "Save recipe" button visible

**Shippability flag:** REQUIRES VERIFICATION. Recipe import / fridge scan was in §2G reliability hold as of 2026-05-14. Per user confirmation, it shipped in this cycle. Confirm with Sai that fridge scan → recipe generation is reliable end-to-end before committing to this frame. If not clean, substitute with "Health Hub" (cycle + sleep + mindfulness) as Frame 9.

---

#### Frame 10 — Imports / Bring Your History

**Main caption:**
```
Bring your history. KEEP GOING.
```
5 words. "KEEP GOING" oversized, brand green.

**Sub-caption:**
*Import from MyFitnessPal, MacroFactor, Cronometer, or Apple Health.*

**Background color:** Muted lavender `#E8E0F0`

**In-phone screen:** Imports / switcher screen. Show:
- Import source list with logos/icons: MyFitnessPal, MacroFactor, Cronometer, Apple Health
- A progress bar showing import in progress: "Importing 847 food logs from MyFitnessPal..."
- OR post-import success: "Imported 847 food entries. Your nutrition history is ready."

**Staging pre-conditions:**
- Navigate to Imports / Data Switcher screen
- Initiate an MFP or Apple Health import on a test account
- Screenshot mid-import or post-success

**Competitor out-position:** Switching costs are the #1 reason people don't leave MFP. A dedicated "bring your history" frame directly addresses MFP users considering switching. No other workout AI competitor has a visible import switcher.

**Shippability:** CLEAN if import/switcher screen is wired and ships in this update.

---

### ORDER COMPARISON — USER'S PROPOSED DECK vs THIS DECK

| Slot | User's proposed | This deck | Change + reason |
|---|---|---|---|
| 1 | Coach in chat (home hero) | Same, home redesign | Caption updated; new home screen screenshot |
| 2 | Browse real programs (HYROX carousel) | Same | Kept — strong 2nd frame |
| 3 | Make it yours (customizability) | Same, more specific caption | Required; kept position 3 for decision-window coverage |
| 4 | Film a set. Get coached. | Same, amber background added | Form check with reliability flag |
| 5 | Always know what to lift next | CHANGED to Snap the menu | Menu scan moved from frame 6 to frame 5. Rationale: it's the highest-visual-wow moment in the deck, and 2026 research shows frames 4-5 are still in the "active scrolling" zone. Getting menu scan into frame 5 means it lands before ~70% of users stop. Also it's a required frame. |
| 6 | Snap a menu | CHANGED to Easy mode active workout | Active workout moved from slot 5 to slot 6. "Always know what to lift next" caption updated to "Set by set. YOU'RE READY." to reflect the Easy mode redesign. |
| 7 | Just say what you ate | Same | Kept; multi-input is a strong daily-use proof point |
| 8 | Watch your strength climb | Same, Overload Dashboard | Updated to show the new Overload Dashboard (not old progress dashboard) |
| 9-10 | Fridge recipes / Cycle tracker / Imports | Fridge recipes + Imports | Imports/switcher is stronger conversion hook (reduces switching friction) than cycle tracker for App Store extended slots |

---

## Frame-1 Badge Guidance

The capability pill on frame 1 substitutes for social proof before reviews accumulate. Progression ladder below — each threshold is a trigger to update frame 1 only (no other frames need to change):

| Stage | What to show (top-left pill) | Trigger |
|---|---|---|
| NOW (pre-review accumulation) | `1,700+ exercises · Plans + form check + menu scan` | Ship state — do NOT use star ratings if below 4.5 or below 50 reviews |
| 50+ reviews, 4.5+ stars | `★ 4.7 · Early adopters love it` | Update as soon as first reviews land |
| 250+ reviews, 4.5+ stars | `★ 4.7 · 250+ five-star reviews` | Cross 250 milestone |
| 1K+ reviews | `★ 4.7 · 1,000+ users` or `Trusted by 1,000+ athletes` | Cross 1K |
| Press hit / Product Hunt | `As seen on Product Hunt #1` or press logo | After PH launch or press coverage |
| 5K+ reviews | `★ 4.8 · 10,000+ workouts logged this month` | Use activity number if more credible than review count |

**Research note:** The 2026 guides clarify that social proof badges work best when placed in frames 6-8 (the Trust act of the story arc), not frame 1. However, for fitness apps specifically, a small capability pill in frame 1 that signals completeness (form check + menu scan + programs) is a credibility proxy before review counts are large enough to be convincing. Once you clear 250 reviews at 4.5+ stars, swap to the star rating badge — that's the real trust signal.

**Hard rule:** Never use a fabricated rating or a rating below 4.5 in the badge. If current rating is below 4.5, use the capability pill only.

---

## App Preview Video Beat Sheet (30 seconds)

Fitness apps see disproportionate lift from a preview video. The below beat sheet mirrors the screenshot arc in compressed form.

| Second | Scene | What to show | Caption burned in |
|---|---|---|---|
| 0-3 | HOOK | Real person opening their phone, home screen loads — today's workout card visible. No logo intro. | "Your coach is ready." |
| 4-7 | PROGRAM BROWSE | Scroll through Program Library carousel — HYROX card comes into hero position, user taps it, variant selector slides up | "Pick your program." |
| 8-11 | PROGRAM CUSTOMIZE | Edit Program sheet opens — drag a day, gym picker changes to "Home Gym", AI-tailor toggle flips on | "Make it yours." |
| 12-16 | ACTIVE WORKOUT | Easy mode active screen — bar slides from warmup to effective set, weight displayed large, rest timer counts down | "Set by set." |
| 17-21 | MENU SCAN | Camera opens on restaurant menu, TOP PICK badge appears on Grilled Salmon Salad | "Snap the menu. Pick the best." |
| 22-25 | FORM CHECK | Short clip: user sets up phone, does 3 squat reps, critique card slides up showing 7.4 score + 2 improvement notes | "Film a set. Get coached." |
| 26-28 | PAYOFF | Overload Dashboard — 1RM line chart trending up, PR badge pops: "+15 lbs Bench" | "Your strength climbs." |
| 29-30 | END CARD | App icon + "Zealova — AI fitness coach" + "Start free — 7 days, no charge" | |

**Production rules:**
- All captions burned in (no voiceover — most users watch muted)
- No animated logo intro before second 0
- Real app UI throughout — no mockup overlays or illustration-only frames
- End card: app icon + tagline + trial CTA
- 30 seconds total (Play Store preview video limit)
- Film in 1080x1920 vertical minimum; 1080x2400 preferred for modern Android

---

## Play Store Feature Graphic (1024x500)

This is Play-specific — App Store has no equivalent.

**What it is:** A banner shown in category browse, search results cards, and featured placements. Acts as a visual hook BEFORE the user opens the listing page.

**Spec:** 1024x500 px, JPEG or PNG, up to 15 MB. Keep key content 15% from all edges. CENTER IS DEAD ZONE (Play button overlay covers it).

**Recommended design:**

| Zone | Content |
|---|---|
| Left third | App icon (large), below-icon: "Zealova" wordmark |
| Right two-thirds | Single headline: "Plans. Form check. Menu scan." in large sans-serif |
| Background | Dark gradient (brand dark blue → black) |
| Bottom strip | "7-day free trial · $7.99/mo" in smaller text |
| Dead center | EMPTY — no logo, no text |

**Alternative:** If you want a visual instead of text, show the menu scan result (TOP PICK badge visible) as the dominant image, with app icon + "Zealova" text left-anchored.

---

## Shippability Summary — Flag Review Before Staging

| Frame | Feature | Shippability | Action needed |
|---|---|---|---|
| 1 | Home (signature-v2) | CLEAN | Stage with 1 logged workout + partial calorie fill |
| 2 | Program Library carousel | CLEAN | Confirm HYROX is in library with variant selectors |
| 3 | Edit Program (customizability) | MODERATE | Stage with 2 gym profiles + assigned program; use Gym tab view if drag state is hard to screenshot |
| 4 | AI Form Check | REQUIRES STAGING | Film real set, confirm critique pipeline returns clean result. Check reliability with Sai before committing. |
| 5 | Menu Scan | CLEAN | Stage with a printed/displayed restaurant menu; confirm TOP PICK badge renders |
| 6 | Easy mode active workout | CLEAN | Stage mid-workout in Easy mode, capture during rest timer |
| 7 | Multi-input chat logging | CLEAN | Send 3 test messages in sequence; screenshot all 3 exchanges visible |
| 8 | Overload Dashboard | MODERATE | Needs 20+ workouts logged; use QA reviewer account if available |
| 9 | Fridge scan + recipes | REQUIRES VERIFICATION | Confirm reliability with Sai (was in §2G hold May 2026) |
| 10 | Imports / switcher | CLEAN if shipped | Confirm import/switcher screen is live in this update |

---

## Pre-Capture Checklist (Updated)

- [ ] Dark mode enabled on device (all in-phone screens)
- [ ] Signature-v2 home redesign live on test device
- [ ] Program Library populated: HYROX + 3 other programs + variants visible
- [ ] Two gym profiles created (for customizability frame picker)
- [ ] An assigned program with days and gym set
- [ ] Easy mode workout session staged with warmup sets completed
- [ ] At least one restaurant menu (physical or displayed) for menu scan
- [ ] Chat thread cleared, ready for fresh 3-message nutrition/cardio log sequence
- [ ] 20+ workouts logged in test account for Overload Dashboard
- [ ] At least one PR detected in test account
- [ ] Clean status bar (full signal, 100% battery or close, time showing 10:09 or similar clean time)
- [ ] No debug banners, no error toasts, no loading spinners in any screenshot
- [ ] No sensitive personal data visible (blur any real email addresses or phone numbers)
- [ ] Form check video filmed (if including Frame 4)
- [ ] Fridge scan test confirmed (if including Frame 9)
- [ ] All screenshots at 1080x2400 (Play) or 1320x2868 (App Store 6.9" iPhone 16 Pro Max)

---

## Changelog Entry to Add

Once this deck is approved and shots staged, log the shipment in `docs/planning/marketing/aso/changelog.md` with:

```
## 2026-06-XX — Full screenshot deck rebuild (post-signature-v2 reskin + Program Library + Form Check + Menu Scan)

- Store(s): Play + App Store
- Asset(s) changed: All 8 Play screenshots + 10 App Store screenshots (complete rebuild)
- Before: May 2026 deck — 8 frames (coach/exercise detail/menu-fridge/chat-swap/voice-log/strength/body/shareables). Missing Program Library, customizability, AI Form Check, Easy mode.
- After: 8 frames per above spec. Added Program Library (F2), customizability (F3, required), AI Form Check (F4), menu scan (F5, required). Removed chat-swap frame (F4 old). Updated home (F1) to signature-v2. Updated progress (F8) to Overload Dashboard.
- Hypothesis: +15-25% listing-page-to-install conversion from (a) narrative story arc replacing feature enumeration, (b) two required high-visual-wow frames (form check + menu scan) that no competitor shows, (c) Program Library differentiator visible in frame 2 (in top-3 decision window).
- Measurement: Install conversion rate (listing page views → installs), 4 weeks post-live. Also track Play Store Listing Experiments if running a variant.
- Audit reference: Screenshot deck rebuild run 2026-06-29
- Status: DRAFT — awaiting staging and founder approval
```
