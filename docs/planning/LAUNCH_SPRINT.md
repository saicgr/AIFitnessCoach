# Zealova iOS Launch Sprint — Accelerated (May 12 - May 25)

**One job:** Ship Zealova to iOS App Store. Everything else serves that.

**Status going in (May 12):**
- ✅ Waitlist landing page live
- ✅ Privacy policy live (zealova.com/privacy)
- ✅ App icon exists (verify 1024×1024 spec)
- ✅ Screenshots — Play Store versions exist (need iOS optimization + iPad sizes)
- ✅ App description v2 (adapt for Apple)
- ✅ Pricing structure defined ($7.99/mo + $59.99/yr + 7-day trial)
- ❓ iOS build / TestFlight status — **THE critical unknown**

**Accelerated timeline:**
- Days 1-4 (May 12-15): iOS Apple-specific work
- Day 5 (Fri May 16): SUBMIT to Apple
- Days 6-9 (May 17-20): Apple review
- Days 10-14 (May 21-25): LAUNCH if approved (target: ~May 22-25)

If iOS build isn't TestFlight-ready, fall back to original timeline (submit May 23, launch ~Jun 1).

---

## DAY 0 (today, Tue May 12) — Critical build status check

**Before anything else, answer this:** Does `flutter build ios` produce a clean release build that runs on a real iPhone without crashes?

| Check | Status |
|---|---|
| Clean `flutter build ios --release` | ⬜ |
| Bundle ID set to `com.zealova.app` | ⬜ |
| iOS deployment target ≥ 15.0 | ⬜ |
| Live Activity sub-bundle configured (`com.zealova.app.LiveActivity`) | ⬜ |
| AASA file deployed at `zealova.com/.well-known/apple-app-site-association` (App ID `G9RL26P89Q.com.zealova.app`) | ⬜ |
| Runner buildPhases order correct (Embed Foundation Extensions BEFORE Thin Binary, per memory notes) | ⬜ |
| flutter_gemma strip script in place | ⬜ |
| Push notifications working on iOS | ⬜ |
| RevenueCat IAP working with iOS sandbox | ⬜ |

**If ANY answer is no → that's Day 1's actual focus.** Apple won't review a broken build.

---

## DAY 1 (Tue May 12) — Foundation

| # | Task | Done |
|---|---|---|
| 1 | App Store Connect → create Zealova app record (~5 min) | ⬜ |
| 2 | Confirm bundle ID `com.zealova.app` matches in App Store Connect + Xcode | ⬜ |
| 3 | Upload first TestFlight build via Xcode | ⬜ |
| 4 | Add yourself as Internal Tester in TestFlight | ⬜ |
| 5 | Verify build runs from TestFlight on your iPhone | ⬜ |
| 6 | Fix any crashes / iOS-specific bugs from TestFlight | ⬜ |

---

## DAY 2 (Wed May 13) — IAP + reviewer access

| # | Task | Done |
|---|---|---|
| 7 | App Store Connect → In-App Purchases → create subscription group | ⬜ |
| 8 | Add `$7.99/mo` SKU + `$59.99/yr` SKU with 7-day trial | ⬜ |
| 9 | Configure subscription metadata (display name, description, screenshot per sub) | ⬜ |
| 10 | Verify RevenueCat picks up new iOS SKUs | ⬜ |
| 11 | Test IAP flow on TestFlight build (sandbox purchase) | ⬜ |
| 12 | Create demo account for Apple reviewers (reviewer@zealova.com + dummy password) | ⬜ |
| 13 | Verify demo account can sign in + see full app | ⬜ |
| 14 | Recruit 2-3 friends as TestFlight beta testers (catch bugs you missed) | ⬜ |

---

## DAY 3 (Thu May 14) — Assets optimization

| # | Task | Done |
|---|---|---|
| 15 | Verify app icon meets Apple spec: 1024×1024, no transparency, no rounded corners (Apple rounds them) | ⬜ |
| 16 | Optimize Play Store screenshots for iPhone 6.9" Apple spec (1320×2868) | ⬜ |
| 17 | Resize for iPhone 6.5" (1242×2688) | ⬜ |
| 18 | **NEW: iPad 13" screenshots (2064×2752)** — Apple requires, Play didn't | ⬜ |
| 19 | **NEW: iPad 12.9" screenshots (2048×2732)** | ⬜ |
| 20 | Adapt Play Store description copy for Apple character limits (4000 char body, 30 char name, 30 char subtitle) | ⬜ |
| 21 | Write promotional text (170 char, editable post-launch) | ⬜ |

---

## DAY 4 (Fri May 15) — Keywords + privacy + final review

| # | Task | Done |
|---|---|---|
| 22 | Keyword research — App Store SEO tools (AppFollow free tier, Sensor Tower if budget) | ⬜ |
| 23 | Pick 100 char of keywords (no spaces, comma-separated). Examples: `fitness,AI,coach,workout,nutrition,macro,gym,trainer,personal,plan` | ⬜ |
| 24 | Privacy Nutrition Label — fill out in App Store Connect (similar info to Play Data Safety but Apple's UI) | ⬜ |
| 25 | Age rating quiz (likely 4+ or 12+ for fitness) | ⬜ |
| 26 | Category: Health & Fitness (primary), Lifestyle (secondary) | ⬜ |
| 27 | Categories selected, pricing tier set, available territories set | ⬜ |
| 28 | Final TestFlight build with all bug fixes | ⬜ |
| 29 | Final review on actual device — every flow works | ⬜ |

---

## DAY 5 (Sat May 16) — SUBMIT + screenshots polish

| Time | Task |
|---|---|
| Morning (post-gym) | Final review of every App Store Connect field |
| 10:30-12:00 | Cleaning day (don't skip — keystone) |
| 12:30 | Lunch with wife |
| **1:00-2:30 PM** | **SUBMIT to Apple** — hit "Submit for Review" |
| 2:30-4:30 PM | Polish App Store screenshots IF you have any rejection-risk (e.g., text in screenshots that looks like ads) |
| 4:30+ | Wife time |

**Submission strategy:**
- Submit Saturday afternoon — Apple reviews queue starts cranking Sunday/Monday
- Reviewer typically picks up within 24-48 hours of submission
- If you submit by Saturday 2pm CT, verdict likely by Monday-Tuesday May 18-19

---

## DAYS 6-9 (Sun May 17 - Wed May 20) — Apple review

### Sunday May 17 — preserve launch energy

Don't break the Sunday batch routine even though no Apple verdict yet.

| Time | What |
|---|---|
| 6:30-8:30 | Wake + GYM |
| 9:00 | Shower + breakfast |
| **9:30-12:00** | **Sunday batch — but PRE-LAUNCH content** (~15 posts): "submitted Zealova to Apple Friday, hoping for verdict this week" build-in-public + waitlist drivers |
| 12:00-12:30 | Background agent task specs |
| 12:30-1:00 | Lunch with wife |
| **1:00-4:00** | **Record launch-day Reels (3-5 Reels)** — Cal AI app demo style, ready to fire when approved |
| 4:00-5:30 | Weekend job apps (~50) |
| 5:30+ | Meal prep + wife |

### Mon-Wed May 18-20 — wait + prep launch

| Day | Active focus |
|---|---|
| Mon | Check App Store Connect status hourly. Edit Reels recorded Sunday in CapCut. Cross-post-ready exports (9:16, captioned). |
| Tue | Draft launch day playbook content: X thread, LinkedIn long-form, email blast, SMS, Reddit posts, Product Hunt prep |
| Wed | Verify Resend + Twilio working. Test email blast to yourself. Pre-write Product Hunt page (draft, don't submit). |

**If Apple rejects** (Mon-Wed): fix issue same day, resubmit. 24-48 hr re-review window. Slips launch by 2-4 days.

**If Apple approves** (Mon-Wed): trigger Launch Day Playbook below.

---

## LAUNCH DAY playbook (the day iOS goes live)

Everything pre-drafted by end of Day 7 (Mon May 18). All you do launch day is hit "send" and reply to comments.

| Hour | Action |
|---|---|
| Hour 0 | **App Store live**. Verify Zealova link works. Click your own link, verify install completes. |
| Hour 1 | **X launch thread** from personal handle (5-7 tweets + screenshots + App Store link) |
| Hour 1 | **LinkedIn founder post** — long-form (1000+ words) |
| Hour 1 | **Email blast to waitlist** via Resend |
| Hour 2 | **SMS blast** to phone-numbered waitlist (90% open rate) |
| Hour 3 | **IG Reel #1** uploads via Meta Business Suite |
| Hour 3 | **Same Reel to TikTok @zealova** (manual upload — create account if not done) |
| Hour 3 | **Same Reel to YouTube Shorts @zealova** (manual upload) |
| Hour 4 | **Reddit launch posts**: r/loseit + r/getmotivated + r/sideproject + r/indiehackers |
| Hour 6 | **Product Hunt launch** (best Tuesday — if approval lands non-Tuesday, schedule PH for next Tuesday) |
| Hour 8 | **Show HN** post on Hacker News |
| Hour 12 | Second IG Reel auto-fires |
| Hour 18 | Reply to ALL comments across all platforms |
| Hour 24 | Day-1 metrics review (installs, signups, sub trials, viral velocity) |

---

## POST-LAUNCH (Week 2+ after iOS live)

- Reels 3-7 fire across the rest of the week
- Daily X + LI follow-up posts (engagement + thank-yous + day-by-day metrics)
- Reply to App Store reviews within 24 hr
- Resume full schedule from `WEEKLY_SCHEDULE.md` (33 posts + 3 Reels/wk)
- Hireable / Mobi / UV active sessions resume (vibe-coding rotation)

---

## DAILY RHYTHM DURING SPRINT (deltas from WEEKLY_SCHEDULE.md)

| Block | Normal | Sprint mode |
|---|---|---|
| Mon-Fri morning build (40 min) | Vibe-pick from 4 apps | **Zealova iOS prep ONLY** |
| Mon-Wed-Fri evening build (60 min) | Vibe-pick from 4 apps | **Zealova iOS prep ONLY** |
| Tue/Thu morning build (40 min) | Mobi / Hireable | **Zealova iOS prep ONLY** |
| Saturday 2:30-4:30 video block | Recording Reels | **Day 5 (May 16): SUBMIT** · Day 12+ (post-launch): real Reels |
| Sun 10:00-12:30 social batch | 33 posts | **~15 pre-launch teases only** |
| Sun 1:00-4:00 build big block | Hireable + Mobi | **Sun May 17: record launch Reels** · Sun May 24: post-launch normal |

### Unchanged blocks

- Sleep (5:45am wake / 10:30pm bed)
- Day job (8-12, 1-5)
- Gym (Tue/Thu/Sat/Sun, 2 hr with commute)
- Job apps (~825/wk across 4 windows)
- Wife time (evenings + Sat afternoon)
- Saturday cleaning (10:30-12)

---

## OTHER APPS (Hireable / Mobi / UV) DURING SPRINT

| Activity | Status |
|---|---|
| Active build sessions | PAUSED for 2 weeks |
| Background Claude agents | CONTINUE (no effort cost) |
| Marketing posts for Hireable/Mobi/UV | STOPPED for 2 weeks |
| PR review of agent work | Saturday during meal prep (optional) |

Resume Week 3+ (post-launch).

---

## MARKETING DURING SPRINT — pre-launch tease mode

Drop from 33 posts/wk → **~15 posts/wk**. Save ammo for launch blitz.

### Allowed post types

- ✅ Build-in-public ("Submitting Zealova to Apple Saturday — pray for me")
- ✅ Waitlist drivers ("iOS launching ~May 22. First 100 waitlist gets 50% off year 1.")
- ✅ UI tease (single screenshots, NOT full Reel demos)
- ✅ Founder narrative ("Why I'm building Zealova as someone 50 lbs overweight")
- ✅ Reddit value comments in r/loseit / r/fitness (warm up subs, NO Zealova posts yet)
- ✅ Apple review status updates ("Submitted! Now waiting. Apple's review takes 1-3 days.")

### Banned post types (save for launch)

- ❌ App demo Reels
- ❌ Cal AI-style "scan this!" demos
- ❌ Anything with "Download Now" CTA
- ❌ TikTok / YouTube Shorts (save accounts for launch reveal)
- ❌ Reddit launch posts in major fitness subs

---

## TRACKING

### Day 1 review (Tue May 12, end of day)

- iOS build status: ⬜ working / ⬜ blocked
- App Store Connect record: ⬜ created
- TestFlight upload: ⬜ done

### End of Week 1 review (Sun May 18)

- Submitted to Apple: ⬜ Y / ⬜ N
- Day target was Saturday May 16
- Waitlist signups: __ / 500 target
- Pre-launch posts shipped: __ / 15
- Launch Reels recorded: __ / 5

### End of sprint review (Sun May 25)

- Apple verdict: ⬜ approved / ⬜ rejected
- Launch executed: ⬜ Y / ⬜ N
- Day-1 installs: __
- Day-1 sub trials: __
- Day-1 waitlist conversion: __

---

## CRITICAL RULES

### DO

- ✅ Active builds 100% Zealova for 2 weeks
- ✅ Submit by Saturday May 16 even if 80% perfect — Apple feedback > paralysis
- ✅ Pre-write all launch day content by Mon May 18
- ✅ Capture waitlist emails + phones aggressively
- ✅ Verify TestFlight build EVERY day before changing anything else
- ✅ Sleep 10:30pm even during sprint — burnout kills launches

### DON'T

- ❌ Record Cal AI-style demo Reels before App Store live
- ❌ Drive social posts to "download" CTA (App Store link will 404)
- ❌ Build new features on Zealova that aren't critical for v1 — feature freeze
- ❌ Active sessions on Hireable / Mobi / UV
- ❌ Skip gym to make iOS deadline (8 hr gym/wk is the keystone)
- ❌ Stay up past 10:30pm to "finish" Zealova prep
- ❌ Submit a known-buggy build to Apple — rejection costs 4 days
