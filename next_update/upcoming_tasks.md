# Upcoming Tasks — Consolidated Competitor Roadmap

Consolidates the two competitor-roadmap reference files into one prioritization table for Zealova planning.

- **Sources:** `macrofactor_roadmap.md` (61 items, with public vote counts + user comments) · `gravl_roadmap.md` (57 items)
- **Generated:** 2026-05-17
- **Subtasks** for MacroFactor rows are synthesized from reading *every* user comment on each item — they are the specific refinements/scope-expansions real users asked for. For Gravl rows the Subtasks cell carries the roadmap's own Notes field.
- **Popularity** = MacroFactor public vote count. Gravl publishes no votes → `N/A`.

### Label legend

| Label | Meaning | MacroFactor | Gravl |
|---|---|---|---|
| `Under Consideration` | Idea acknowledged, not committed | UNDER CONSIDERATION section | — |
| `Planned` | Committed, not started | Planned MF 🍱 / Planned WO 🏋️ | Planned for Q1 '26 |
| `In Progress` | Actively being built | — | In Progress |
| `Backlog` | Accepted but unscheduled | — | Backlog |
| `Won't Do` | Explicitly rejected | Won't Do ⛔ | — |
| `Released` | Shipped | RELEASED section | Launched |

## Summary by label (118 items)

| Label | MacroFactor | Gravl | Total |
|---|---|---|---|
| Under Consideration | 34 | 0 | 34 |
| Planned | 10 | 1 | 11 |
| In Progress | 0 | 2 | 2 |
| Backlog | 0 | 8 | 8 |
| Won't Do | 7 | 0 | 7 |
| Released | 10 | 46 | 56 |
| **Total** | **61** | **57** | **118** |

**Cross-source overlaps** (same feature on both roadmaps — don't double-count as separate priorities): Apple Watch, Wear OS, Garmin Connect, Health Connect, workout programs, AI form analysis. Flagged inline in the Notes column.

## Zealova implementation status (118 tasks)

Each main task was verified against the Zealova codebase (`mobile/flutter/lib/`, `backend/`) by reading actual screen/service code. Verdict in the `In Zealova?` column; `Partial`/`No` rows carry a one-line reason.

| In Zealova? | MacroFactor | Gravl | Total |
|---|---|---|---|
| ✅ Yes | 25 | 44 | 69 |
| 🟡 Partial | 12 | 9 | 21 |
| ❌ No | 24 | 4 | 28 |
| **Total** | **61** | **57** | **118** |

Zealova already covers most of Gravl's roadmap (workout tracking is a core strength). The clearest gaps vs. these competitors: watchOS / Wear OS apps, web app, period/cycle Health import + chart overlay, net carbs, nutrient ratios, weigh-in reminders, a weight widget, landscape/tablet support, and a few nutrition utilities (alcohol calculator, negative calories, %DV entry).

## Top 15 by demand (MacroFactor votes)

| Votes | Task | Label |
|---|---|---|
| 13,047 | Import Sleep | Under Consideration |
| 6,474 | Sub-goals (milestones) for Weight | Under Consideration |
| 6,197 | Weigh-in Notification | Under Consideration |
| 6,137 | Meal Planning Support | Under Consideration |
| 5,475 | Water (general hydration) Tracker | Planned |
| 5,270 | Recurring Meals (Repeat Foods) | Under Consideration |
| 4,966 | Web App Alpha | Planned |
| 4,638 | Meal Suggestions | Under Consideration |
| 4,621 | Alcoholic Beverage Calculator | Planned |
| 4,121 | Poop Tracker | Under Consideration |
| 3,738 | Flag Low Quality Branded Product Entries | Under Consideration |
| 3,680 | Fasting Timer | Under Consideration |
| 3,597 | MacroFactor on Apple Watch | Released |
| 3,422 | Period Overlay on Weight Trend | Under Consideration |
| 3,140 | Sharing Meals/Food Log | Under Consideration |

## Consolidated table

One continuous table — one row per task **and** per subtask. Main tasks are numbered `N` (bold); subtask rows are numbered `N.M` and indented with `↳`. MacroFactor subtasks are synthesized from an exhaustive read of every user comment; the comment count per item is shown in the Notes column. Use the row-range map below to scroll/search to a label group.

| Section | Tasks | Row range |
|---|---|---|
| MacroFactor — Under Consideration | 34 | #1 – #34 |
| MacroFactor — Planned | 10 | #35 – #44 |
| MacroFactor — Won't Do | 7 | #45 – #51 |
| MacroFactor — Released | 10 | #52 – #61 |
| Gravl — Launched / Released | 46 | #62 – #107 |
| Gravl — In Progress | 2 | #108 – #109 |
| Gravl — Planned | 1 | #110 |
| Gravl — Backlog | 8 | #111 – #118 |

| # | Source | Task / Subtask | Label | Category | Popularity | Notes | In Zealova? |
|---|---|---|---|---|---|---|---|
| **1** | MacroFactor | **Period Overlay on Weight Trend** | Under Consideration | Features | 3422 | Brings period data into weight trend view for richer trending insights; created Oct 2022. _(41 comments)_ | No — period tracking exists; no overlay on weight/trend charts |
| 1.1 | MacroFactor | ↳ Overlay period/menstrual phase data onto the weight trend chart | subtask | · | · | · | · |
| 1.2 | MacroFactor | ↳ Make the expenditure algorithm account for cyclical/monthly weight fluctuations so it doesn't cut calories due to luteal-phase water retention | subtask | · | · | · | · |
| 1.3 | MacroFactor | ↳ Add a one-week delay before the algorithm adjusts calories around the period | subtask | · | · | · | · |
| 1.4 | MacroFactor | ↳ Recognize/flag period-bloating weight gains as water weight so they don't distort the algorithm | subtask | · | · | · | · |
| 1.5 | MacroFactor | ↳ Add a next-period prediction feature based on previous cycle data (like Samsung Health / Apple Health) | subtask | · | · | · | · |
| 1.6 | MacroFactor | ↳ Increase suggested calorie targets (~200 cal more) during/before the period to match higher hunger | subtask | · | · | · | · |
| 1.7 | MacroFactor | ↳ Display the period as "Cycle day X" instead of "X days since last period" | subtask | · | · | · | · |
| 1.8 | MacroFactor | ↳ Overlay menstrual phase onto the energy expenditure chart, not just weight trend | subtask | · | · | · | · |
| 1.9 | MacroFactor | ↳ Support hormone-cycle tracking for users who don't menstruate (IUD users, post-menopausal women) | subtask | · | · | · | · |
| 1.10 | MacroFactor | ↳ Add an opt-in consent-based data-sharing option to fuel women's nutritional health research | subtask | · | · | · | · |
| 1.11 | MacroFactor | ↳ Allow comparing current weight to the same point in a previous cycle | subtask | · | · | · | · |
| 1.12 | MacroFactor | ↳ Add ovulation tracking (predict period timing and food needs for irregular cycles) | subtask | · | · | · | · |
| 1.13 | MacroFactor | ↳ Support PCOS / irregular-cycle users whose hormonal issues affect weight | subtask | · | · | · | · |
| 1.14 | MacroFactor | ↳ Add menstrual symptom tracking | subtask | · | · | · | · |
| 1.15 | MacroFactor | ↳ Suggest phase-specific micronutrients to prioritize across cycle stages | subtask | · | · | · | · |
| 1.16 | MacroFactor | ↳ Suggest phase-specific macro and exercise adjustments across the cycle | subtask | · | · | · | · |
| 1.17 | MacroFactor | ↳ Pull period data from Apple Health instead of requiring manual logging in both apps | subtask | · | · | · | · |
| 1.18 | MacroFactor | ↳ Implement period days as a shaded colored column overlay across insights and metrics charts | subtask | · | · | · | · |
| 1.19 | MacroFactor | ↳ Keep actual weight and weight prediction stable through the pre-period and period window | subtask | · | · | · | · |
| **2** | MacroFactor | **Flag Low Quality Branded Product Entries** | Under Consideration | Nutrition | 3738 | Basic checks to flag erroneous branded entries; created Oct 2022. _(25 comments)_ | Partial — in-app food report dialog exists; no warning badge / verified marker |
| 2.1 | MacroFactor | ↳ Suggest-an-edit mechanism for food entries, like Google Maps | subtask | · | · | · | · |
| 2.2 | MacroFactor | ↳ Let users verify that a food entry is correct | subtask | · | · | · | · |
| 2.3 | MacroFactor | ↳ Cross-check macros against calories (9/4/4 cal per g) and flag entries where the math is off | subtask | · | · | · | · |
| 2.4 | MacroFactor | ↳ Flag a nutrient when it is 300% of target or above | subtask | · | · | · | · |
| 2.5 | MacroFactor | ↳ Integrate Yuka app product-quality data (possible collaboration) | subtask | · | · | · | · |
| 2.6 | MacroFactor | ↳ Account for the same product having different calories/macros in different countries | subtask | · | · | · | · |
| 2.7 | MacroFactor | ↳ Require a photo of the nutrition label before an item can be added to the public database | subtask | · | · | · | · |
| 2.8 | MacroFactor | ↳ Use Yuka-style data to advise whether a logged food is the healthiest way to get the macros you need | subtask | · | · | · | · |
| 2.9 | MacroFactor | ↳ Keep generic-item searches (chicken breast, carrots) free of branded results unless the item is processed | subtask | · | · | · | · |
| 2.10 | MacroFactor | ↳ Allow users to keep adding items, since databases are sparse outside the US | subtask | · | · | · | · |
| 2.11 | MacroFactor | ↳ Show a yellow warning when kcal/serving deviates >20% from macro-derived energy, red when >35% | subtask | · | · | · | · |
| 2.12 | MacroFactor | ↳ Team up with Nutritionix for a library of validated foods | subtask | · | · | · | · |
| 2.13 | MacroFactor | ↳ Add community upvoting so users can mark foods accurate to their label | subtask | · | · | · | · |
| 2.14 | MacroFactor | ↳ Analyze whether what you eat suits your goal and suggest diet improvements | subtask | · | · | · | · |
| 2.15 | MacroFactor | ↳ Track micronutrients against medically accepted thresholds and suggest replacements when deficient | subtask | · | · | · | · |
| 2.16 | MacroFactor | ↳ Add a user-facing flag/report option for mistakes (e.g. 240ml bottle logged as 240g) | subtask | · | · | · | · |
| 2.17 | MacroFactor | ↳ Mark food entries as verified from a database source and show which source verified them | subtask | · | · | · | · |
| 2.18 | MacroFactor | ↳ Keep brand-specific entries for generic foods, since nutrient content varies by brand/farming | subtask | · | · | · | · |
| 2.19 | MacroFactor | ↳ Tie into product-testing systems to flag products with known inaccurate labeling | subtask | · | · | · | · |
| **3** | MacroFactor | **Calendar Week Start Day** | Under Consideration | Improvements | 1539 | Configurable first day of week for calendar and macro dashboard; created Oct 2022. _(39 comments)_ | Yes |
| 3.1 | MacroFactor | ↳ Add an option to start the week on the user's check-in day | subtask | · | · | · | · |
| 3.2 | MacroFactor | ↳ Allow starting the week on Friday | subtask | · | · | · | · |
| 3.3 | MacroFactor | ↳ Hook into system settings / default to the OS first-day-of-week (ISO 8601) | subtask | · | · | · | · |
| 3.4 | MacroFactor | ↳ Allow the week to start on Sunday | subtask | · | · | · | · |
| 3.5 | MacroFactor | ↳ Allow the week to start on Monday | subtask | · | · | · | · |
| 3.6 | MacroFactor | ↳ Allow the week to start on Saturday (for weekend meal-prep alignment) | subtask | · | · | · | · |
| 3.7 | MacroFactor | ↳ Apply the configurable start day to the weekly nutrition panel / "remaining" tab | subtask | · | · | · | · |
| 3.8 | MacroFactor | ↳ Allow choosing Wednesday as the check-in day so weekend effects dissipate before measuring | subtask | · | · | · | · |
| 3.9 | MacroFactor | ↳ Apply the configurable start day to the dashboard reset | subtask | · | · | · | · |
| 3.10 | MacroFactor | ↳ Make the start day configurable specifically in the Workouts app, whose charts start on Monday | subtask | · | · | · | · |
| 3.11 | MacroFactor | ↳ Sync the week start with the user's separate habit-tracking app | subtask | · | · | · | · |
| 3.12 | MacroFactor | ↳ Allow customizing the day the macro program/plan starts | subtask | · | · | · | · |
| **4** | MacroFactor | **Meal Planning Support** | Under Consideration | Nutrition | 6137 | Explicit tools to help with meal planning; created Oct 2022. _(71 comments)_ | Yes |
| 4.1 | MacroFactor | ↳ Suggest how much of a food to eat to hit remaining macros | subtask | · | · | · | · |
| 4.2 | MacroFactor | ↳ Add "planned meal" entries for future meals with the ability to check them off / adjust to actual | subtask | · | · | · | · |
| 4.3 | MacroFactor | ↳ Integrate eatthismuch.com-style meal-planning tools | subtask | · | · | · | · |
| 4.4 | MacroFactor | ↳ Set recurring daily meals that can be modified for a single day when needed | subtask | · | · | · | · |
| 4.5 | MacroFactor | ↳ Real-time recipe suggestions when macros have been under target for several days, with diet filters | subtask | · | · | · | · |
| 4.6 | MacroFactor | ↳ Offer meal planning as a separate app or an activatable/deactivatable module to avoid bloat | subtask | · | · | · | · |
| 4.7 | MacroFactor | ↳ Pull training plans from TrainingPeaks/Humango and plan macros by workout zone for pre/post fueling | subtask | · | · | · | · |
| 4.8 | MacroFactor | ↳ Add a "copy a day" function to reuse a meal-prepped day | subtask | · | · | · | · |
| 4.9 | MacroFactor | ↳ Build an uploadable pantry that recommends meals from what you have and generates a shopping list | subtask | · | · | · | · |
| 4.10 | MacroFactor | ↳ Pre-log meals and check them off as consumed | subtask | · | · | · | · |
| 4.11 | MacroFactor | ↳ Provide a curated selection of goal-specific recipes for fresh meal ideas | subtask | · | · | · | · |
| 4.12 | MacroFactor | ↳ Add recipe categorization in the library (Breakfast, Lunch, Dinner, Snacks) | subtask | · | · | · | · |
| 4.13 | MacroFactor | ↳ Add a hypothetical/sandbox meal-planning page to play with ingredients without logging as eaten | subtask | · | · | · | · |
| 4.14 | MacroFactor | ↳ Plan meals for a whole week, reuse prior weeks to build a library, and clone weeks to tweak | subtask | · | · | · | · |
| 4.15 | MacroFactor | ↳ Suggest per-meal macro ranges so daily macros stay balanced (like RP Diet) | subtask | · | · | · | · |
| 4.16 | MacroFactor | ↳ Compare two foods side by side and show how each affects the daily goal | subtask | · | · | · | · |
| 4.17 | MacroFactor | ↳ Suggest a food/meal from past foods that fits exact remaining macros | subtask | · | · | · | · |
| 4.18 | MacroFactor | ↳ Generate/export a shopping list for selected days | subtask | · | · | · | · |
| 4.19 | MacroFactor | ↳ AI suggestions of food to complete the day's remaining calories and nutrition | subtask | · | · | · | · |
| 4.20 | MacroFactor | ↳ Mark food-log items as planned/draft so they aren't summed into consumed totals | subtask | · | · | · | · |
| 4.21 | MacroFactor | ↳ Provide user-accessible API endpoints for interoperability with other apps | subtask | · | · | · | · |
| 4.22 | MacroFactor | ↳ Scan a recipe from a website or book and have it parsed and logged as a meal/recipe | subtask | · | · | · | · |
| 4.23 | MacroFactor | ↳ Scan/track fridge ingredients with perishable dates and plan days around them | subtask | · | · | · | · |
| 4.24 | MacroFactor | ↳ Generate a full meal plan from logged foods, recipes, macro targets, diet preferences and budget | subtask | · | · | · | · |
| 4.25 | MacroFactor | ↳ Save "plates" / groups of foods eaten together (like MyFitnessPal Save Meal) | subtask | · | · | · | · |
| 4.26 | MacroFactor | ↳ Highlight when too much protein is in one meal and help adjust meal number/sizes | subtask | · | · | · | · |
| 4.27 | MacroFactor | ↳ AI meal builder using profile dietary restrictions and food preferences | subtask | · | · | · | · |
| 4.28 | MacroFactor | ↳ Group logged-in-advance foods for the week to generate a grocery list | subtask | · | · | · | · |
| 4.29 | MacroFactor | ↳ AI-generated meal plan from foods you already eat, curated to goals and workout timing | subtask | · | · | · | · |
| 4.30 | MacroFactor | ↳ Integration/sync with the "Plan to Eat" app | subtask | · | · | · | · |
| 4.31 | MacroFactor | ↳ Generate a shopping list from planned recipes by selecting which days to include | subtask | · | · | · | · |
| 4.32 | MacroFactor | ↳ Meal recommendations based on remaining macronutrients | subtask | · | · | · | · |
| 4.33 | MacroFactor | ↳ Meal-plan creation favoring ingredient overlap, repeatable base meals, and batch-cooking | subtask | · | · | · | · |
| 4.34 | MacroFactor | ↳ A calendar-based weekly meal planner | subtask | · | · | · | · |
| 4.35 | MacroFactor | ↳ A free user recipe-sharing page where users browse, filter, and edit others' recipes | subtask | · | · | · | · |
| 4.36 | MacroFactor | ↳ A shopping page to track what to buy for the rest of the week | subtask | · | · | · | · |
| 4.37 | MacroFactor | ↳ An AI chat that helps plan meals | subtask | · | · | · | · |
| 4.38 | MacroFactor | ↳ Keep meal planning separate from the food log so it doesn't feel like pre-logging meals as eaten | subtask | · | · | · | · |
| **5** | MacroFactor | **Custom Calorie Distribution for Coached Plans** | Under Consideration | Algorithm | 469 | Custom calorie distribution while still using coached macros; created Oct 2022. _(17 comments)_ | No — no custom macro-split / per-day calorie distribution |
| 5.1 | MacroFactor | ↳ Allow subtle customization of suggested coached macros to match an external nutritionist program | subtask | · | · | · | · |
| 5.2 | MacroFactor | ↳ Support custom macro percentage splits (e.g. 30/40/30) not achievable with default options | subtask | · | · | · | · |
| 5.3 | MacroFactor | ↳ Allow uneven daily calorie distribution within a fixed weekly total | subtask | · | · | · | · |
| 5.4 | MacroFactor | ↳ Allow swapping carbs for fats for a single day while keeping protein and total calories fixed | subtask | · | · | · | · |
| 5.5 | MacroFactor | ↳ Plan ahead for cheat/social-dinner days by reducing other days to keep the weekly average | subtask | · | · | · | · |
| 5.6 | MacroFactor | ↳ Support reduced-calorie fasting days with the missing calories redistributed to other days | subtask | · | · | · | · |
| 5.7 | MacroFactor | ↳ Edit macro distribution within the weekly coached calorie intake | subtask | · | · | · | · |
| 5.8 | MacroFactor | ↳ Support shifting workout days week-to-week (for variable shift-work schedules) | subtask | · | · | · | · |
| 5.9 | MacroFactor | ↳ Create selectable "day profiles" (rest, cardio-only, lifting+cardio) each with their own calories | subtask | · | · | · | · |
| 5.10 | MacroFactor | ↳ Dynamically move bonus workout-day calories to a different day when the workout day changes | subtask | · | · | · | · |
| 5.11 | MacroFactor | ↳ Support carb cycling with high/medium/low carb-and-calorie day types | subtask | · | · | · | · |
| 5.12 | MacroFactor | ↳ Provide per-day sliding bars to set each day's shifted-calorie amount | subtask | · | · | · | · |
| 5.13 | MacroFactor | ↳ Accommodate calories to the user's specific workout plan | subtask | · | · | · | · |
| 5.14 | MacroFactor | ↳ Auto-monitor and adjust calories/macros so daily variance balances out over the week | subtask | · | · | · | · |
| 5.15 | MacroFactor | ↳ Let users set a calorie floor and adjust the goal end date accordingly | subtask | · | · | · | · |
| 5.16 | MacroFactor | ↳ Show each food item segmented within the dashboard calorie-ring to visualize each meal's contribution | subtask | · | · | · | · |
| 5.17 | MacroFactor | ↳ Set a custom calorie floor instead of only 800/1200 options on the women's coached plan | subtask | · | · | · | · |
| **6** | MacroFactor | **Customize Navigation Bar Page Order** | Under Consideration | Improvements | 120 | Reorder pages on the bottom navigation bar; created Oct 2022. No actionable comment asks. _(0 comments)_ | Partial — home tiles reorderable; bottom nav bar is not |
| **7** | MacroFactor | **Poop Tracker** | Under Consideration | Features | 4121 | Cory's favorite request — a poop tracker; created Oct 2022. _(50 comments)_ | No — no stool/digestion tracker |
| 7.1 | MacroFactor | ↳ Add a Bristol Stool Scale rating for logging bowel movements | subtask | · | · | · | · |
| 7.2 | MacroFactor | ↳ Have the weight algorithm account for days of no/missed bowel movements so skipped weigh-ins aren't needed | subtask | · | · | · | · |
| 7.3 | MacroFactor | ↳ Allow logging fiber on the main dashboard (optional toggle) | subtask | · | · | · | · |
| 7.4 | MacroFactor | ↳ Track other digestive symptoms — bloating, abdominal pain, gas | subtask | · | · | · | · |
| 7.5 | MacroFactor | ↳ Add a general event-logging mechanism to add events to the timeline | subtask | · | · | · | · |
| 7.6 | MacroFactor | ↳ Make all digestive/symptom data cleanly exportable alongside food-log data | subtask | · | · | · | · |
| 7.7 | MacroFactor | ↳ Add an "AI poop scanner" that estimates calories consumed by analyzing photos of stool | subtask | · | · | · | · |
| 7.8 | MacroFactor | ↳ Integrate poop logging with AI photo support to estimate nutritional content | subtask | · | · | · | · |
| 7.9 | MacroFactor | ↳ Convert macros consumed plus days-since-last-BM into the scale-weight calculation | subtask | · | · | · | · |
| 7.10 | MacroFactor | ↳ Provide a way to hide/disable all poop-related content from the dashboard | subtask | · | · | · | · |
| 7.11 | MacroFactor | ↳ Add a pee/urination tracker | subtask | · | · | · | · |
| 7.12 | MacroFactor | ↳ Correlate food intake with bowel movements to surface food intolerances and IBS trigger foods | subtask | · | · | · | · |
| 7.13 | MacroFactor | ↳ AI-driven advice that detects "when you eat X you get symptom" and suggests elimination diets | subtask | · | · | · | · |
| 7.14 | MacroFactor | ↳ Account for symptom delays (14-18 hour lag) when correlating GI symptoms to foods | subtask | · | · | · | · |
| 7.15 | MacroFactor | ↳ Provide a reminder for when to weigh in (after morning BM) | subtask | · | · | · | · |
| 7.16 | MacroFactor | ↳ Track diarrhea days so heavy weight loss from it is flagged | subtask | · | · | · | · |
| 7.17 | MacroFactor | ↳ Pre/post weigh-yourself logging to quantify a bowel movement's weight | subtask | · | · | · | · |
| 7.18 | MacroFactor | ↳ Reference the existing Pcal app's poop-tracking model | subtask | · | · | · | · |
| **8** | MacroFactor | **Edit a Past Goal in History** | Under Consideration | Improvements | 320 | Allows editing past goals; created Oct 2022. _(9 comments)_ | No — goal history is view-only |
| 8.1 | MacroFactor | ↳ Allow editing/retroactively changing a past goal's start date | subtask | · | · | · | · |
| 8.2 | MacroFactor | ↳ Allow editing past goal parameters (rate, macro spread, calories) as circumstances change | subtask | · | · | · | · |
| 8.3 | MacroFactor | ↳ Allow tapping into a previous goal to view its stats | subtask | · | · | · | · |
| 8.4 | MacroFactor | ↳ Support importing a pre-existing goal from before MacroFactor was adopted | subtask | · | · | · | · |
| **9** | MacroFactor | **Sub-goals (milestones) for Weight** | Under Consideration | Features | 6474 | More opportunities to celebrate when setting longer goals; created Oct 2022. _(31 comments)_ | Partial — general milestones screen exists; not tied to weight-goal sub-goals |
| 9.1 | MacroFactor | ↳ Add incremental sub-goal/milestone steps within a single larger weight goal | subtask | · | · | · | · |
| 9.2 | MacroFactor | ↳ Award a badge for hitting each milestone | subtask | · | · | · | · |
| 9.3 | MacroFactor | ↳ Auto-divide the start-to-goal range evenly into ~10 milestones (Happy Scale model) | subtask | · | · | · | · |
| 9.4 | MacroFactor | ↳ Celebratory animation at 25%, 50%, 75% progress marks | subtask | · | · | · | · |
| 9.5 | MacroFactor | ↳ Per-milestone "realistic date to reach goal" estimate | subtask | · | · | · | · |
| 9.6 | MacroFactor | ↳ Support milestones that go both up and down within one goal | subtask | · | · | · | · |
| 9.7 | MacroFactor | ↳ Easier way to see exactly how much weight has been lost alongside current trend weight | subtask | · | · | · | · |
| **10** | MacroFactor | **Add Negative Calories/Macros** | Under Consideration | Nutrition | 833 | Add negative foods to subtract from daily totals; created Oct 2022. _(33 comments)_ | No — no negative entries / input-field arithmetic |
| 10.1 | MacroFactor | ↳ Add a ± button in the logging keyboard / quick-add to enter negative servings of a food | subtask | · | · | · | · |
| 10.2 | MacroFactor | ↳ Allow negative entries on database food items, not just quick add | subtask | · | · | · | · |
| 10.3 | MacroFactor | ↳ Allow basic arithmetic in the weight/quantity input field (chained additions and subtractions) | subtask | · | · | · | · |
| 10.4 | MacroFactor | ↳ Add a "tare/before" weight placeholder that holds a value until food is re-weighed | subtask | · | · | · | · |
| 10.5 | MacroFactor | ↳ Add paired "starting weight" and "final weight" entries so the app computes consumed amount | subtask | · | · | · | · |
| 10.6 | MacroFactor | ↳ Support entering a dish/container weight to subtract from total weight | subtask | · | · | · | · |
| 10.7 | MacroFactor | ↳ Treat blood donation as negative calories rather than added expenditure | subtask | · | · | · | · |
| 10.8 | MacroFactor | ↳ Photo-based subtraction — picture leftovers on the plate and subtract them | subtask | · | · | · | · |
| 10.9 | MacroFactor | ↳ Allow subtracting cardio/exercise calories burned (opt-in) | subtask | · | · | · | · |
| 10.10 | MacroFactor | ↳ Support negative entries for foods that burn more calories digesting than they contain | subtask | · | · | · | · |
| 10.11 | MacroFactor | ↳ Group multiple weigh-as-you-go entries into a single food log entry, subtracting bone weight at the end | subtask | · | · | · | · |
| **11** | MacroFactor | **Check-in Notification** | Under Consideration | Features | 2724 | Optional notifications when it's time to check in; created Oct 2022. _(12 comments)_ | Yes |
| 11.1 | MacroFactor | ↳ Make reminder notifications optional, preferably opt-in rather than opt-out | subtask | · | · | · | · |
| 11.2 | MacroFactor | ↳ Allow users to set custom reminder times that can be changed | subtask | · | · | · | · |
| 11.3 | MacroFactor | ↳ Rename/broaden the feature to general "Reminders" covering check-in and food-logging | subtask | · | · | · | · |
| 11.4 | MacroFactor | ↳ Provide separate reminders for food-intake logging around breakfast/lunch/dinner times | subtask | · | · | · | · |
| 11.5 | MacroFactor | ↳ Add a notification setting to the workout app to remind users of workouts | subtask | · | · | · | · |
| **12** | MacroFactor | **Meal Time Notification** | Under Consideration | Features | 1064 | Optional reminders to eat a meal at particular times; created Oct 2022. _(18 comments)_ | Yes |
| 12.1 | MacroFactor | ↳ Notify the user at a planned meal time based on what they pre-logged | subtask | · | · | · | · |
| 12.2 | MacroFactor | ↳ Make meal-time notifications optional | subtask | · | · | · | · |
| 12.3 | MacroFactor | ↳ Notify when a specific meal hasn't been logged, with the notification deep-linking into the app | subtask | · | · | · | · |
| 12.4 | MacroFactor | ↳ Add a separate supplement-reminder space, distinguishable (e.g. by color) from meal reminders | subtask | · | · | · | · |
| 12.5 | MacroFactor | ↳ Allow a notification action button to auto-add a supplement directly from the notification | subtask | · | · | · | · |
| 12.6 | MacroFactor | ↳ Auto-suggest meal times based on sleep, wake, and workout times (RP Diet style) | subtask | · | · | · | · |
| 12.7 | MacroFactor | ↳ Simple per-meal reminders like "Time to log your Lunch" | subtask | · | · | · | · |
| 12.8 | MacroFactor | ↳ Reminder triggered when target calories haven't been logged by a certain time of day | subtask | · | · | · | · |
| **13** | MacroFactor | **Weigh-in Notification** | Under Consideration | Features | 6197 | Optional reminders to weigh in at chosen times; created Oct 2022. _(33 comments)_ | No — no weigh-in reminder |
| 13.1 | MacroFactor | ↳ Allow notifications to be disabled/toggled off once a routine is established | subtask | · | · | · | · |
| 13.2 | MacroFactor | ↳ Add daily reminders to track nutrition at specific user-set times (e.g. 12, 3, 6, 9 PM) | subtask | · | · | · | · |
| 13.3 | MacroFactor | ↳ Add result/feedback notifications ("Your intake was too low yesterday" / "Great job") | subtask | · | · | · | · |
| 13.4 | MacroFactor | ↳ Provide a timestamp option / type-in field to set the reminder time | subtask | · | · | · | · |
| 13.5 | MacroFactor | ↳ Suppress the reminder when the weigh-in is already logged via smart scale or Health Connect | subtask | · | · | · | · |
| 13.6 | MacroFactor | ↳ Add other recurring check-in reminders — update strategy, progress pics, waist circumference | subtask | · | · | · | · |
| **14** | MacroFactor | **Import Sleep** | Under Consideration | Integrations | 13047 | Highest-voted item overall. Correlate average sleep time with expenditure and eating habits; created Oct 2022. _(65 comments)_ | Yes |
| 14.1 | MacroFactor | ↳ Sync sleep data from Samsung Health | subtask | · | · | · | · |
| 14.2 | MacroFactor | ↳ Pull sleep data from Garmin Connect | subtask | · | · | · | · |
| 14.3 | MacroFactor | ↳ Pull sleep data from Apple Health | subtask | · | · | · | · |
| 14.4 | MacroFactor | ↳ Integrate with Oura ring for sleep data | subtask | · | · | · | · |
| 14.5 | MacroFactor | ↳ Feed imported sleep data into the expenditure/metabolism algorithm | subtask | · | · | · | · |
| 14.6 | MacroFactor | ↳ Track only total sleep time per night (treat detailed sleep-stage data as unreliable) | subtask | · | · | · | · |
| 14.7 | MacroFactor | ↳ Place sleep alongside steps and period tracking in the same category | subtask | · | · | · | · |
| 14.8 | MacroFactor | ↳ Use only week-to-week average sleep time given actigraphy unreliability | subtask | · | · | · | · |
| 14.9 | MacroFactor | ↳ Integrate with SleepCycle app | subtask | · | · | · | · |
| 14.10 | MacroFactor | ↳ Add a manual sleep tracker with a free-text Notes field for context | subtask | · | · | · | · |
| 14.11 | MacroFactor | ↳ Integrate with Whoop | subtask | · | · | · | · |
| 14.12 | MacroFactor | ↳ Integrate with Apple Watch | subtask | · | · | · | · |
| 14.13 | MacroFactor | ↳ Integrate with smart rings generally (e.g. RingConn) | subtask | · | · | · | · |
| 14.14 | MacroFactor | ↳ Import CPAP data via the ResMed myAir app | subtask | · | · | · | · |
| 14.15 | MacroFactor | ↳ Surface whether there is a correlation between sleep and other metrics | subtask | · | · | · | · |
| 14.16 | MacroFactor | ↳ Integrate with Fitbit (training and sleep) | subtask | · | · | · | · |
| 14.17 | MacroFactor | ↳ Integrate with Samsung watch via Samsung Health | subtask | · | · | · | · |
| 14.18 | MacroFactor | ↳ Import from Hume | subtask | · | · | · | · |
| 14.19 | MacroFactor | ↳ Integrate with Sleep Number bed | subtask | · | · | · | · |
| 14.20 | MacroFactor | ↳ Support manual sleep entry with sleep goals and goal-tracking | subtask | · | · | · | · |
| 14.21 | MacroFactor | ↳ Analyze how food types/macros and eating times affect sleep | subtask | · | · | · | · |
| **15** | MacroFactor | **Deciliters Support** | Under Consideration | Nutrition | 130 | Add deciliters to automatic unit conversions; created Oct 2022. _(1 comments)_ | No — hydration units are ml/oz/gallon only |
| 15.1 | MacroFactor | ↳ When a custom unit (dl) is added, still show tbsp/tsp conversions | subtask | · | · | · | · |
| **16** | MacroFactor | **Fasting Timer** | Under Consideration | Features | 3680 | Optional timer for fasting / time-restricted eating windows; created Oct 2022. Overlaps #24. _(50 comments)_ | Yes |
| 16.1 | MacroFactor | ↳ Track time and explain the current fasting phase | subtask | · | · | · | · |
| 16.2 | MacroFactor | ↳ Sync the fasting tracker with weekly goals | subtask | · | · | · | · |
| 16.3 | MacroFactor | ↳ Support feasting/fasting macro cycles (more carbs allowed on feasting days) | subtask | · | · | · | · |
| 16.4 | MacroFactor | ↳ Add the ability to simply mark a day as a "fasting" day | subtask | · | · | · | · |
| 16.5 | MacroFactor | ↳ Integrate with or mirror the "Zero" fasting app | subtask | · | · | · | · |
| 16.6 | MacroFactor | ↳ Stop fasting days from counting as incomplete/partial food logs | subtask | · | · | · | · |
| 16.7 | MacroFactor | ↳ Allow hiding a fasting timespan in the middle of the day's timeline | subtask | · | · | · | · |
| 16.8 | MacroFactor | ↳ Allow planning nutrition ahead of a fast, offsetting calories | subtask | · | · | · | · |
| 16.9 | MacroFactor | ↳ Add a "start a fast" action | subtask | · | · | · | · |
| 16.10 | MacroFactor | ↳ Estimate/show average time between dinner and breakfast (unintentional fasting detection) | subtask | · | · | · | · |
| 16.11 | MacroFactor | ↳ Include a timer estimating how long the user has been in ketosis | subtask | · | · | · | · |
| 16.12 | MacroFactor | ↳ Auto-stop the timer / break the fast when a meal is logged | subtask | · | · | · | · |
| 16.13 | MacroFactor | ↳ Support multiple fast lengths (16/8, 3-day, etc.) | subtask | · | · | · | · |
| 16.14 | MacroFactor | ↳ Provide a visual countdown timer showing fast start through end into the next day | subtask | · | · | · | · |
| 16.15 | MacroFactor | ↳ Log eating windows and set fasting goals | subtask | · | · | · | · |
| 16.16 | MacroFactor | ↳ Add notifications to begin and end a scheduled fast | subtask | · | · | · | · |
| 16.17 | MacroFactor | ↳ Mirror functionality of the "Easy Fast" app | subtask | · | · | · | · |
| 16.18 | MacroFactor | ↳ Support other fasting protocols such as 5:2 | subtask | · | · | · | · |
| **17** | MacroFactor | **Add Micronutrient Support for Iodine** | Under Consideration | Nutrition | 365 | Add iodine micronutrient despite poor research-database coverage; created Oct 2022. _(8 comments)_ | Yes |
| 17.1 | MacroFactor | ↳ Add iodine tracking under minerals/"other" in the Nutrition section | subtask | · | · | · | · |
| 17.2 | MacroFactor | ↳ Add a tooltip noting iodine isn't required on US labels so values are approximate | subtask | · | · | · | · |
| 17.3 | MacroFactor | ↳ Auto-add an estimated iodine amount when a logged food matches a known iodine-rich food list | subtask | · | · | · | · |
| 17.4 | MacroFactor | ↳ Mark estimated values with an approximate-value indicator | subtask | · | · | · | · |
| 17.5 | MacroFactor | ↳ Tie iodine intake to pregnancy and breastfeeding settings | subtask | · | · | · | · |
| 17.6 | MacroFactor | ↳ Support tracking iodine from multivitamin/supplement intake when food-label data is absent | subtask | · | · | · | · |
| 17.7 | MacroFactor | ↳ Use authoritative regional reference values (e.g. Australian Government RDI/EAR) | subtask | · | · | · | · |
| 17.8 | MacroFactor | ↳ Also add micronutrient support for B7 (biotin) | subtask | · | · | · | · |
| 17.9 | MacroFactor | ↳ Add quick-add for these nutrients (iodine/sodium) | subtask | · | · | · | · |
| **18** | MacroFactor | **Stone and Lbs Weight Unit** | Under Consideration | Improvements | 199 | Add stone/lbs alongside existing lbs and kg units; created Oct 2022. _(12 comments)_ | No — kg/lbs only, no stone unit |
| 18.1 | MacroFactor | ↳ Add a stone-and-pounds weight unit so UK users don't have to convert | subtask | · | · | · | · |
| **19** | MacroFactor | **Nutrients Ratios** | Under Consideration | Nutrition | 926 | Monitor ratios between selected nutrients; created Oct 2022. _(27 comments)_ | No — individual nutrients shown; no computed ratios |
| 19.1 | MacroFactor | ↳ Omega 3:6 ratio tracking | subtask | · | · | · | · |
| 19.2 | MacroFactor | ↳ Saturated fat : unsaturated fat ratio | subtask | · | · | · | · |
| 19.3 | MacroFactor | ↳ Show fiber inline with the other macronutrients (not buried in the nutrient screen) | subtask | · | · | · | · |
| 19.4 | MacroFactor | ↳ Fiber : calorie ratio | subtask | · | · | · | · |
| 19.5 | MacroFactor | ↳ Potassium : sodium ratio | subtask | · | · | · | · |
| 19.6 | MacroFactor | ↳ Calcium : oxalate ratio | subtask | · | · | · | · |
| 19.7 | MacroFactor | ↳ Macros expressed as a percent of calories | subtask | · | · | · | · |
| 19.8 | MacroFactor | ↳ Polyunsaturated : monounsaturated fat ratio | subtask | · | · | · | · |
| 19.9 | MacroFactor | ↳ Breakdown of the individual carotenoids making up vitamin A | subtask | · | · | · | · |
| 19.10 | MacroFactor | ↳ Breakdown of the individual tocopherols making up vitamin E | subtask | · | · | · | · |
| 19.11 | MacroFactor | ↳ Fatty acid ratio LA : ALA : EPA+DHA+DPA | subtask | · | · | · | · |
| 19.12 | MacroFactor | ↳ % carb+sodium, % fat+sodium, % fat+sugar — to flag hyperpalatable foods | subtask | · | · | · | · |
| 19.13 | MacroFactor | ↳ 8 essential amino acid profile breakdown for protein powder products | subtask | · | · | · | · |
| 19.14 | MacroFactor | ↳ Calorie : protein ratio shown as a running daily value on the dashboard | subtask | · | · | · | · |
| 19.15 | MacroFactor | ↳ Calorie : protein ratio shown per hour on the timeline | subtask | · | · | · | · |
| 19.16 | MacroFactor | ↳ Calorie : protein ratio shown in the plate view | subtask | · | · | · | · |
| 19.17 | MacroFactor | ↳ Calorie : protein ratio shown in the individual food item view | subtask | · | · | · | · |
| 19.18 | MacroFactor | ↳ Creatine available as a gram-ratio metric (different supplement forms) | subtask | · | · | · | · |
| 19.19 | MacroFactor | ↳ Net carbs — fiber subtracted from carbs | subtask | · | · | · | · |
| 19.20 | MacroFactor | ↳ Macros-as-%-of-calories in the Primary Focus area | subtask | · | · | · | · |
| 19.21 | MacroFactor | ↳ Macros-as-%-of-calories in the nutrition area | subtask | · | · | · | · |
| 19.22 | MacroFactor | ↳ Macros-as-%-of-calories as the colored bars along the top of the food log page | subtask | · | · | · | · |
| 19.23 | MacroFactor | ↳ Macros-as-%-of-calories shown inline with time-stamped meals | subtask | · | · | · | · |
| 19.24 | MacroFactor | ↳ Clear C/P/F ratio readout (adding to 100%) on dashboard, banners and hourly timeline | subtask | · | · | · | · |
| 19.25 | MacroFactor | ↳ Calcium : magnesium ratio | subtask | · | · | · | · |
| 19.26 | MacroFactor | ↳ Zinc : copper ratio | subtask | · | · | · | · |
| 19.27 | MacroFactor | ↳ Calcium : phosphorus ratio | subtask | · | · | · | · |
| 19.28 | MacroFactor | ↳ Iron : copper ratio | subtask | · | · | · | · |
| 19.29 | MacroFactor | ↳ Notification when a ratio drifts out of range, with per-ratio alert windows | subtask | · | · | · | · |
| 19.30 | MacroFactor | ↳ Targets for micronutrients (not just macronutrients) | subtask | · | · | · | · |
| 19.31 | MacroFactor | ↳ Add reference micronutrient amounts to branded items that only list macros | subtask | · | · | · | · |
| 19.32 | MacroFactor | ↳ Cholesterol ratios | subtask | · | · | · | · |
| 19.33 | MacroFactor | ↳ Leucine tracking | subtask | · | · | · | · |
| **20** | MacroFactor | **Make Prepare/Edit Recipe Available From The Food Log Timeline** | Under Consideration | Improvements | 1441 | Make prepare/edit recipe accessible after logging, not just before; created Oct 2022. _(26 comments)_ | Yes |
| 20.1 | MacroFactor | ↳ Edit/modify an already-logged recipe directly from the food log | subtask | · | · | · | · |
| 20.2 | MacroFactor | ↳ Open recipe instructions directly from the timeline entry | subtask | · | · | · | · |
| 20.3 | MacroFactor | ↳ Simplify/streamline the overall recipe-creation flow | subtask | · | · | · | · |
| 20.4 | MacroFactor | ↳ Allow editing the AI food logger's auto-generated recipe after logging | subtask | · | · | · | · |
| 20.5 | MacroFactor | ↳ View which ingredients an AI-snapshot logged | subtask | · | · | · | · |
| 20.6 | MacroFactor | ↳ Make recipe editing accessible from the dashboard if it can't be done from the food log | subtask | · | · | · | · |
| 20.7 | MacroFactor | ↳ Make swipe-left-to-edit more discoverable | subtask | · | · | · | · |
| 20.8 | MacroFactor | ↳ Select "Prepare meal" from the food log timeline when planning meals at the start of the day | subtask | · | · | · | · |
| 20.9 | MacroFactor | ↳ Edit the weight/amount of an individual ingredient within a logged meal without exploding it | subtask | · | · | · | · |
| 20.10 | MacroFactor | ↳ "Edit forward" — editing a recipe propagates the change to all logged future instances | subtask | · | · | · | · |
| 20.11 | MacroFactor | ↳ Preserve/expose per-ingredient food allergy/intolerance info that the logged version drops | subtask | · | · | · | · |
| **21** | MacroFactor | **Barcode Scanning Using Front Camera (Swap Option)** | Under Consideration | Features | 267 | Button to swap front/back camera when scanning barcodes; created Oct 2022. _(6 comments)_ | No — barcode scanner is back-camera only, no swap |
| 21.1 | MacroFactor | ↳ Button to swap between front and back camera when scanning barcodes | subtask | · | · | · | · |
| 21.2 | MacroFactor | ↳ Support setting the phone down and using on-device voice controls to scan barcodes | subtask | · | · | · | · |
| 21.3 | MacroFactor | ↳ Allow switching between all available camera lenses | subtask | · | · | · | · |
| 21.4 | MacroFactor | ↳ Apply the same front-camera / lens-swap option to nutrition label scanning | subtask | · | · | · | · |
| **22** | MacroFactor | **Change Order of Food Logging Tabs** | Under Consideration | Improvements | 324 | Reorder and potentially remove food-logging interface tabs; created Feb 2023. _(7 comments)_ | No — nutrition tabs not reorderable |
| 22.1 | MacroFactor | ↳ Re-order the tab sections of the food logging interface | subtask | · | · | · | · |
| 22.2 | MacroFactor | ↳ Remove/hide unused tab sections | subtask | · | · | · | · |
| 22.3 | MacroFactor | ↳ Move the Library tab next to Search | subtask | · | · | · | · |
| 22.4 | MacroFactor | ↳ Drag-and-drop logged food items to reorder them within the log | subtask | · | · | · | · |
| 22.5 | MacroFactor | ↳ Persist search keywords when switching from Search to Library | subtask | · | · | · | · |
| 22.6 | MacroFactor | ↳ Implement reordering via press-and-hold then drag (like Apple Reminders) | subtask | · | · | · | · |
| 22.7 | MacroFactor | ↳ Surface Favorites so it isn't hidden inside the Library tab | subtask | · | · | · | · |
| **23** | MacroFactor | **Sharing Meals/Food Log** | Under Consideration | Features | 3140 | Share meals and food logs with partners, family and coaches; created Feb 2023. _(89 comments)_ | Yes |
| 23.1 | MacroFactor | ↳ Share the full meal log so a fitness/nutrition coach can review it together | subtask | · | · | · | · |
| 23.2 | MacroFactor | ↳ Enter a meal once and share it to a partner who can then edit portions | subtask | · | · | · | · |
| 23.3 | MacroFactor | ↳ Add daily food log to the existing data export with calories, macros and time per item | subtask | · | · | · | · |
| 23.4 | MacroFactor | ↳ Allow exporting food log to CSV | subtask | · | · | · | · |
| 23.5 | MacroFactor | ↳ Export the actual foods eaten for sending to a trainer for weekly check-ins | subtask | · | · | · | · |
| 23.6 | MacroFactor | ↳ Share individual food items / custom food entries (not just recipes) | subtask | · | · | · | · |
| 23.7 | MacroFactor | ↳ Auto-synchronizing shared food database for a household/family | subtask | · | · | · | · |
| 23.8 | MacroFactor | ↳ Coach can send a friend request to be granted view of the user's weekly diary | subtask | · | · | · | · |
| 23.9 | MacroFactor | ↳ QR-code based sharing of meals/recipes/food items | subtask | · | · | · | · |
| 23.10 | MacroFactor | ↳ Generate shareable QR codes for recipes | subtask | · | · | · | · |
| 23.11 | MacroFactor | ↳ AirDrop-based sharing of macro/meal info to people present | subtask | · | · | · | · |
| 23.12 | MacroFactor | ↳ Accountability-buddy / follow feature so friends can see your log + macro targets | subtask | · | · | · | · |
| 23.13 | MacroFactor | ↳ Linked / paired accounts so one user can log into another's food log | subtask | · | · | · | · |
| 23.14 | MacroFactor | ↳ Shared recipe library / family recipe book linked across accounts | subtask | · | · | · | · |
| 23.15 | MacroFactor | ↳ Share a "plate" / group of foods without creating a recipe | subtask | · | · | · | · |
| 23.16 | MacroFactor | ↳ Bulk-share recipes and custom foods at once | subtask | · | · | · | · |
| 23.17 | MacroFactor | ↳ Profiles invisible to all other users by default; add friends only via custom share codes | subtask | · | · | · | · |
| 23.18 | MacroFactor | ↳ Granular per-friend control over exactly what data is shared | subtask | · | · | · | · |
| 23.19 | MacroFactor | ↳ Share buttons hidden until the user adds a friend, on a separate screen | subtask | · | · | · | · |
| 23.20 | MacroFactor | ↳ Export/share food log as a PDF or screenshot so a coach doesn't need the app | subtask | · | · | · | · |
| 23.21 | MacroFactor | ↳ Share food log via a simple link (no download needed) for sharing with doctors | subtask | · | · | · | · |
| 23.22 | MacroFactor | ↳ Export option with a window smaller than 7 days for nutritionist check-ins | subtask | · | · | · | · |
| 23.23 | MacroFactor | ↳ Dedicated coaching version of the app | subtask | · | · | · | · |
| 23.24 | MacroFactor | ↳ Premium shared/partner subscription giving partners view and edit access | subtask | · | · | · | · |
| 23.25 | MacroFactor | ↳ Direct integration/link with the Trainerize app | subtask | · | · | · | · |
| 23.26 | MacroFactor | ↳ Extend sharing to workout programs | subtask | · | · | · | · |
| 23.27 | MacroFactor | ↳ In-app chat function to share meals | subtask | · | · | · | · |
| 23.28 | MacroFactor | ↳ Strava-style social function | subtask | · | · | · | · |
| **24** | MacroFactor | **Intermittent Fasting Window Indicator** | Under Consideration | Features | 2251 | Timer/indicator for intended fasting windows; created Feb 2023. Overlaps #16. _(43 comments)_ | Yes |
| 24.1 | MacroFactor | ↳ Add IF/OMAD eating-window tracking to consolidate away from apps like Zero | subtask | · | · | · | · |
| 24.2 | MacroFactor | ↳ Display the eating window to discourage night-time snacking | subtask | · | · | · | · |
| 24.3 | MacroFactor | ↳ Show elapsed fasting duration to motivate completing a planned fast | subtask | · | · | · | · |
| 24.4 | MacroFactor | ↳ Simple customizable-eating-window timer used on demand | subtask | · | · | · | · |
| 24.5 | MacroFactor | ↳ Support both daily (one-off) and recurring fasting schedules | subtask | · | · | · | · |
| 24.6 | MacroFactor | ↳ Clock to set the day's fasting hours with a countdown | subtask | · | · | · | · |
| 24.7 | MacroFactor | ↳ Let users program fasting alongside a caloric deficit (any custom timeframe) | subtask | · | · | · | · |
| 24.8 | MacroFactor | ↳ Show in nutritional analysis how intermittent fasting has impacted weight | subtask | · | · | · | · |
| 24.9 | MacroFactor | ↳ Automatic per-day calculation of fasting time since last logged intake | subtask | · | · | · | · |
| 24.10 | MacroFactor | ↳ Settings value for typical meal length to offset the fast-since-last-meal calculation | subtask | · | · | · | · |
| 24.11 | MacroFactor | ↳ Surface fast-since-last-meal as a dashboard item | subtask | · | · | · | · |
| 24.12 | MacroFactor | ↳ Surface fast-since-last-meal as a widget | subtask | · | · | · | · |
| 24.13 | MacroFactor | ↳ Let users designate fasting days so the coach shifts calories to other days | subtask | · | · | · | · |
| 24.14 | MacroFactor | ↳ Link/integrate with an external IF app to feed MF more data | subtask | · | · | · | · |
| 24.15 | MacroFactor | ↳ Auto-stop the fasting timer when first calorie-bearing meal is logged | subtask | · | · | · | · |
| 24.16 | MacroFactor | ↳ Make a fasting timer visible in the widget view | subtask | · | · | · | · |
| 24.17 | MacroFactor | ↳ Offer "time restricted diet" as a selectable eating strategy | subtask | · | · | · | · |
| 24.18 | MacroFactor | ↳ Two-line visualization: one for eating duration, one for non-eating duration | subtask | · | · | · | · |
| 24.19 | MacroFactor | ↳ Config to define what counts as a non-eating window | subtask | · | · | · | · |
| 24.20 | MacroFactor | ↳ Show body-phase info per fasting phase | subtask | · | · | · | · |
| 24.21 | MacroFactor | ↳ Button to manually start/finish a fast | subtask | · | · | · | · |
| 24.22 | MacroFactor | ↳ Allow setting custom start and end times for the fast | subtask | · | · | · | · |
| 24.23 | MacroFactor | ↳ Push notification when the fast is completed | subtask | · | · | · | · |
| 24.24 | MacroFactor | ↳ Support multiple ratios (16/8, 18/6, 20/4) | subtask | · | · | · | · |
| 24.25 | MacroFactor | ↳ Detect and flag healthy vs unsafe fasting patterns | subtask | · | · | · | · |
| 24.26 | MacroFactor | ↳ Add fasting days into the coach program | subtask | · | · | · | · |
| **25** | MacroFactor | **Menstrual Cycle (Period Data) Import/Export** | Under Consideration | Integrations | 1636 | Sync menstrual cycle data via Apple Health / Health Connect; created Feb 2023. Overlaps #1. _(36 comments)_ | Partial — in-app cycle tracking exists; no Health import |
| 25.1 | MacroFactor | ↳ Sync menstrual cycle data via Apple Health / Health Connect | subtask | · | · | · | · |
| 25.2 | MacroFactor | ↳ Import historical cycle data from Fitbit | subtask | · | · | · | · |
| 25.3 | MacroFactor | ↳ Integrate with the Flo app | subtask | · | · | · | · |
| 25.4 | MacroFactor | ↳ Integrate with Natural Cycles | subtask | · | · | · | · |
| 25.5 | MacroFactor | ↳ Integrate with Clue | subtask | · | · | · | · |
| 25.6 | MacroFactor | ↳ Integrate with Oura (period + body temperature / ovulation) | subtask | · | · | · | · |
| 25.7 | MacroFactor | ↳ Connect directly with Garmin for cycle data | subtask | · | · | · | · |
| 25.8 | MacroFactor | ↳ Have the app learn cycle fluctuations so users see de-noised weight change | subtask | · | · | · | · |
| 25.9 | MacroFactor | ↳ Filter cyclical water-weight fluctuations out of the expenditure algorithm | subtask | · | · | · | · |
| 25.10 | MacroFactor | ↳ Analyze months of past weight data to auto-identify cyclical patterns | subtask | · | · | · | · |
| 25.11 | MacroFactor | ↳ Provide a cycle toggle to enable/disable the fluctuation filtering | subtask | · | · | · | · |
| 25.12 | MacroFactor | ↳ Highlight period dates on the weigh-in charts (color those days) | subtask | · | · | · | · |
| 25.13 | MacroFactor | ↳ Optional overlay marking period days in a distinct color on weight/expenditure charts | subtask | · | · | · | · |
| 25.14 | MacroFactor | ↳ Auto-adjust nutrition plan / goals based on cycle phase | subtask | · | · | · | · |
| 25.15 | MacroFactor | ↳ Auto-target maintenance calories during the days before and during the period | subtask | · | · | · | · |
| 25.16 | MacroFactor | ↳ Adjust calories and macros during a cut based on cycle phase | subtask | · | · | · | · |
| 25.17 | MacroFactor | ↳ Adjust workout intensity/programming based on cycle phase | subtask | · | · | · | · |
| 25.18 | MacroFactor | ↳ Allow manual entry of cycle data instead of requiring an integration | subtask | · | · | · | · |
| 25.19 | MacroFactor | ↳ Track flow intensity (light/medium/heavy/spotting) | subtask | · | · | · | · |
| 25.20 | MacroFactor | ↳ Track mood, bloating and other symptoms | subtask | · | · | · | · |
| 25.21 | MacroFactor | ↳ Show trends in symptoms/intake/cravings across months | subtask | · | · | · | · |
| 25.22 | MacroFactor | ↳ Provide a simple notes area to log light/heavy/spotting days | subtask | · | · | · | · |
| 25.23 | MacroFactor | ↳ Let users flag a needed deload due to period symptoms without harming progress tracking | subtask | · | · | · | · |
| 25.24 | MacroFactor | ↳ Show correlation of weight trend / expenditure against period days | subtask | · | · | · | · |
| 25.25 | MacroFactor | ↳ Change the cycle visualization from blocks to a different visual format | subtask | · | · | · | · |
| 25.26 | MacroFactor | ↳ Account for endometriosis/PCOS/pregnancy/perimenopause/menopause use cases | subtask | · | · | · | · |
| **26** | MacroFactor | **Barcode Number Display on Scan Failure** | Under Consideration | Improvements | 750 | Show scanned barcode number to verify correct scan; created Feb 2023. _(5 comments)_ | No — raw barcode not shown on scan failure |
| 26.1 | MacroFactor | ↳ Provide an option to turn the barcode-number display off for fast scanning | subtask | · | · | · | · |
| 26.2 | MacroFactor | ↳ Allow editing/completing barcode-scanned items when the data is incorrect or missing | subtask | · | · | · | · |
| 26.3 | MacroFactor | ↳ Support adding an item then a negative entry for removed components | subtask | · | · | · | · |
| **27** | MacroFactor | **Searchable Custom Food Icons** | Under Consideration | Improvements | 1055 | Adds a search bar to the custom-food icon selector; created Apr 2023. _(10 comments)_ | Partial — custom-food icon picker exists; not searchable |
| 27.1 | MacroFactor | ↳ Add a search bar to the custom-food icon selector | subtask | · | · | · | · |
| 27.2 | MacroFactor | ↳ Auto-default to an icon when its name appears in the product name (Splitwise-style) | subtask | · | · | · | · |
| **28** | MacroFactor | **Meal Suggestions** | Under Consideration | Nutrition | 4638 | Example meals to fill remaining macros on an in-progress day; created Sep 2024. _(60 comments)_ | Yes |
| 28.1 | MacroFactor | ↳ Suggest example meals to fill remaining macros on an in-progress day | subtask | · | · | · | · |
| 28.2 | MacroFactor | ↳ Make suggestions accessible via an explicit on-demand button rather than always-on | subtask | · | · | · | · |
| 28.3 | MacroFactor | ↳ Base suggestions on the user's own food/logging history | subtask | · | · | · | · |
| 28.4 | MacroFactor | ↳ Prioritize commonly logged / favorited foods (likely on hand) | subtask | · | · | · | · |
| 28.5 | MacroFactor | ↳ Suggest which of the user's saved meals best fit the remaining gap | subtask | · | · | · | · |
| 28.6 | MacroFactor | ↳ Alert when low on a specific micronutrient/vitamin/fiber and recommend foods rich in it | subtask | · | · | · | · |
| 28.7 | MacroFactor | ↳ Incorporate daily/weekly/monthly micronutrient averages into the gap-filling algorithm | subtask | · | · | · | · |
| 28.8 | MacroFactor | ↳ Provide a way to switch the feature off to avoid screen clutter | subtask | · | · | · | · |
| 28.9 | MacroFactor | ↳ Respect dietary restrictions (gluten-free, vegetarian, low-histamine, AIP) | subtask | · | · | · | · |
| 28.10 | MacroFactor | ↳ Let users input dietary restrictions/preferences so suggestions are filtered | subtask | · | · | · | · |
| 28.11 | MacroFactor | ↳ Suggest non-meat / non-fake protein sources for boosting protein | subtask | · | · | · | · |
| 28.12 | MacroFactor | ↳ Add a "Food at home" feature where users list available foods and get suggestions | subtask | · | · | · | · |
| 28.13 | MacroFactor | ↳ Let users tell the app which ingredients they have on hand | subtask | · | · | · | · |
| 28.14 | MacroFactor | ↳ Suggest pre- and post-workout nutrition based on when the user trains | subtask | · | · | · | · |
| 28.15 | MacroFactor | ↳ Provide separate fast-food and homemade suggestion sections | subtask | · | · | · | · |
| 28.16 | MacroFactor | ↳ Recommend menu choices when eating out (feed it a restaurant menu + macros) | subtask | · | · | · | · |
| 28.17 | MacroFactor | ↳ Onboard preferences/metrics similar to the MacroFactor workouts app | subtask | · | · | · | · |
| 28.18 | MacroFactor | ↳ Generate a recommended shopping list | subtask | · | · | · | · |
| 28.19 | MacroFactor | ↳ Suggest a full sample day of eating from history/liked foods | subtask | · | · | · | · |
| 28.20 | MacroFactor | ↳ Suggest meals from the user's entered recipes | subtask | · | · | · | · |
| 28.21 | MacroFactor | ↳ Use sliders / number-of-meals controls to hit remaining targets (EatThisMuch-style) | subtask | · | · | · | · |
| 28.22 | MacroFactor | ↳ Pull suggestions from the AI features or an existing recipe library | subtask | · | · | · | · |
| 28.23 | MacroFactor | ↳ Plan suggestions across multiple days ahead (batch-cook-aware) | subtask | · | · | · | · |
| 28.24 | MacroFactor | ↳ Build into the nutrition manager's info icon, suggesting a similar previously-logged food | subtask | · | · | · | · |
| 28.25 | MacroFactor | ↳ Offer a meal-prep feature guiding users through bi-weekly cook prep | subtask | · | · | · | · |
| 28.26 | MacroFactor | ↳ Open partnership integrations (WholeFoods, Amazon, local grocers) | subtask | · | · | · | · |
| 28.27 | MacroFactor | ↳ Offer only common/basic food recommendations to simplify the feature | subtask | · | · | · | · |
| **29** | MacroFactor | **Quick Add from Nutrition Label Scanner** | Under Consideration | Nutrition | 1684 | Log a scanned nutrition label without creating a custom food; created Sep 2024. _(24 comments)_ | Yes |
| 29.1 | MacroFactor | ↳ Photograph a nutrition label and have it automatically logged without creating a custom food | subtask | · | · | · | · |
| 29.2 | MacroFactor | ↳ Support logging via a screenshot of nutritional values | subtask | · | · | · | · |
| 29.3 | MacroFactor | ↳ Auto-translate non-English nutrition labels using AI before logging | subtask | · | · | · | · |
| 29.4 | MacroFactor | ↳ Map translated label data directly into the app's expected schema | subtask | · | · | · | · |
| 29.5 | MacroFactor | ↳ Allow adding fiber from the scanned label | subtask | · | · | · | · |
| 29.6 | MacroFactor | ↳ Reuse the label-scan flow within custom food creation, pre-filling values to verify | subtask | · | · | · | · |
| **30** | MacroFactor | **Move to Now** | Under Consideration | Improvements | 1624 | Adds a "To Now" option alongside To Today/Tomorrow/Date & Time; created Sep 2024. _(17 comments)_ | Partial — workouts can move to today; no general move for logged food |
| 30.1 | MacroFactor | ↳ Add a "Move to Now" option alongside To Today / To Tomorrow / To Date & Time | subtask | · | · | · | · |
| 30.2 | MacroFactor | ↳ Add a single "Copy to Now" button to copy a past meal to the current timestamp | subtask | · | · | · | · |
| 30.3 | MacroFactor | ↳ After a copy/move, automatically switch the current page/date to Today/Now | subtask | · | · | · | · |
| 30.4 | MacroFactor | ↳ Add a "Move to Yesterday" option for late logging | subtask | · | · | · | · |
| **31** | MacroFactor | **Recurring Meals (Repeat Foods)** | Under Consideration | Nutrition | 5270 | Schedule meals to appear as confirm-to-log timeline suggestions; created Sep 2024. _(75 comments)_ | Partial — recurring recipe schedules exist; no full-day multi-meal template |
| 31.1 | MacroFactor | ↳ Repeat/schedule individual recurring items (milk, protein shake, coffee), not just full meals | subtask | · | · | · | · |
| 31.2 | MacroFactor | ↳ Auto-log daily supplements/vitamins so they show in micronutrient/deficiency views | subtask | · | · | · | · |
| 31.3 | MacroFactor | ↳ Show scheduled-but-unconfirmed meals as faded entries you tap to confirm | subtask | · | · | · | · |
| 31.4 | MacroFactor | ↳ "Log yesterday's breakfast?" one-tap prompt on app open (LoseIt-style) | subtask | · | · | · | · |
| 31.5 | MacroFactor | ↳ Save reusable named "meals" (multi-item groups) distinct from recipes, for one-click add | subtask | · | · | · | · |
| 31.6 | MacroFactor | ↳ After saving a meal, allow editing portions/weights of each component individually | subtask | · | · | · | · |
| 31.7 | MacroFactor | ↳ Add a dedicated favorites tab for frequently eaten items | subtask | · | · | · | · |
| 31.8 | MacroFactor | ↳ Recurring scheduling like calendar events with per-time slots | subtask | · | · | · | · |
| 31.9 | MacroFactor | ↳ Recurrence rules: repeat every day / repeat Mon-Fri with easy single-entry deletion | subtask | · | · | · | · |
| 31.10 | MacroFactor | ↳ Per-day-of-week customization | subtask | · | · | · | · |
| 31.11 | MacroFactor | ↳ Pre-populate the whole upcoming week from saved favorites | subtask | · | · | · | · |
| 31.12 | MacroFactor | ↳ Fully automatic logging with no manual intervention for supplements/water | subtask | · | · | · | · |
| 31.13 | MacroFactor | ↳ Per-item toggle: auto-log silently vs require confirmation | subtask | · | · | · | · |
| 31.14 | MacroFactor | ↳ Save a logged meal as a recipe after the fact for one-click reuse | subtask | · | · | · | · |
| 31.15 | MacroFactor | ↳ Log a meal across X chosen recurring days at creation time (meal-prep oriented) | subtask | · | · | · | · |
| 31.16 | MacroFactor | ↳ AI learns the user's daily routine and proactively asks to apply it | subtask | · | · | · | · |
| 31.17 | MacroFactor | ↳ Full-day templates, with support for multiple templates (training / deficit / maintenance days) | subtask | · | · | · | · |
| 31.18 | MacroFactor | ↳ Match MyFitnessPal's swipe-right-to-add gesture for fast logging | subtask | · | · | · | · |
| 31.19 | MacroFactor | ↳ Schedule by time of day so foods auto-appear hourly | subtask | · | · | · | · |
| 31.20 | MacroFactor | ↳ Use recurring foods as reminders to eat / take vitamins | subtask | · | · | · | · |
| 31.21 | MacroFactor | ↳ Day templates rather than time-scheduled meals | subtask | · | · | · | · |
| **32** | MacroFactor | **Micronutrient Targets for Pregnancy** | Under Consideration | Nutrition | 649 | Floor/target/ceiling micronutrient info for pregnant users; created Sep 2024. _(36 comments)_ | No — iodine tracked; no pregnancy micronutrient targets |
| 32.1 | MacroFactor | ↳ Add micronutrient floor/target/ceiling and adjusted calories for breastfeeding/lactation | subtask | · | · | · | · |
| 32.2 | MacroFactor | ↳ Account for the ~400-500 kcal/day burned by breastfeeding in recommendations | subtask | · | · | · | · |
| 32.3 | MacroFactor | ↳ Base targets on scientific data; otherwise gather data via MF's database + volunteers | subtask | · | · | · | · |
| 32.4 | MacroFactor | ↳ Add a selectable "pregnancy" status/mode so the app expects healthy weight gain | subtask | · | · | · | · |
| 32.5 | MacroFactor | ↳ Support gradual, guided postpartum weight loss without jeopardizing milk supply | subtask | · | · | · | · |
| 32.6 | MacroFactor | ↳ Add a "pregnancy" option to the workout function so strength loss isn't read as regression | subtask | · | · | · | · |
| 32.7 | MacroFactor | ↳ Track prenatal vitamins as part of this feature | subtask | · | · | · | · |
| 32.8 | MacroFactor | ↳ Provide macro targets (not just micro) for pregnancy | subtask | · | · | · | · |
| 32.9 | MacroFactor | ↳ Keep breastfeeding-period data separate so it doesn't skew the user's post-breastfeeding baseline | subtask | · | · | · | · |
| **33** | MacroFactor | **Weight Widget** | Under Consideration | Features | 2323 | Home-screen widget for weight trend data; created Sep 2024. _(39 comments)_ | No — no dedicated weight home-screen widget |
| 33.1 | MacroFactor | ↳ Offer it as a habit-tracker widget that prompts logging without displaying weight data | subtask | · | · | · | · |
| 33.2 | MacroFactor | ↳ Allow logging weight multiple times per day | subtask | · | · | · | · |
| 33.3 | MacroFactor | ↳ Display scale body fat % in the widget and on the dashboard | subtask | · | · | · | · |
| 33.4 | MacroFactor | ↳ Provide a progress-bar widget of trend weight vs target weight | subtask | · | · | · | · |
| 33.5 | MacroFactor | ↳ Show remaining calories in/alongside the widget | subtask | · | · | · | · |
| 33.6 | MacroFactor | ↳ Offer a goal % / partial-goal display instead of raw weight | subtask | · | · | · | · |
| 33.7 | MacroFactor | ↳ Show progress, goal, rate (per week), and % of goal complete in the widget | subtask | · | · | · | · |
| 33.8 | MacroFactor | ↳ Provide a larger widget and a multi-widget "training focus" screen | subtask | · | · | · | · |
| 33.9 | MacroFactor | ↳ Offer the Food Log weekly banner as a home-screen widget | subtask | · | · | · | · |
| 33.10 | MacroFactor | ↳ Show both weight trend and scale weight | subtask | · | · | · | · |
| 33.11 | MacroFactor | ↳ Caution: a weight widget could encourage harmful tracking mindsets | subtask | · | · | · | · |
| **34** | MacroFactor | **Wear OS Workout App (Android)** | Under Consideration | Workouts | 162 | Companion Android watch app to work out without the phone; created Mar 2026. Overlaps Gravl #111 (Wear OS app). _(17 comments)_ | Partial — phone-side Wear plumbing + install banner; no watch module built |
| 34.1 | MacroFactor | ↳ Build a Wear OS companion app so users can train/log without carrying a phone | subtask | · | · | · | · |
| 34.2 | MacroFactor | ↳ Sync heart rate and workout details to Health Connect | subtask | · | · | · | · |
| 34.3 | MacroFactor | ↳ Read heart rate via the watch for more accurate active-calorie counts | subtask | · | · | · | · |
| 34.4 | MacroFactor | ↳ Interim solution: richer notifications showing current and next set with actions | subtask | · | · | · | · |
| 34.5 | MacroFactor | ↳ Watch UI should show current set, next set, etc. (Galaxy Watch parity) | subtask | · | · | · | · |
| 34.6 | MacroFactor | ↳ Add home-screen widgets for the workout calendar | subtask | · | · | · | · |
| 34.7 | MacroFactor | ↳ Add ability to share completed workouts | subtask | · | · | · | · |
| 34.8 | MacroFactor | ↳ Make it comparable to Hevy's Android watch app | subtask | · | · | · | · |
| **35** | MacroFactor | **Alcoholic Beverage Calculator** | Planned | Nutrition | 4621 | Utility to calc calories for unlabeled alcoholic drinks via stated ABV; created Oct 2022. _(21 comments)_ | No — no ABV calorie calculator |
| 35.1 | MacroFactor | ↳ Calculate calories/macros from ABV (or proof) plus drink volume | subtask | · | · | · | · |
| 35.2 | MacroFactor | ↳ Track weekly alcohol consumption against a guideline (e.g. 14 drinks/week) | subtask | · | · | · | · |
| 35.3 | MacroFactor | ↳ Let users set drink goals and track against them | subtask | · | · | · | · |
| 35.4 | MacroFactor | ↳ Implement as a simple input field for alcohol % and unit, not a complex calculator | subtask | · | · | · | · |
| 35.5 | MacroFactor | ↳ Estimate beer carbs from beer style | subtask | · | · | · | · |
| 35.6 | MacroFactor | ↳ Account for post-drinking water bloat so it doesn't distort the expenditure algorithm | subtask | · | · | · | · |
| 35.7 | MacroFactor | ↳ Option to tabulate alcohol calories against the user's carb target | subtask | · | · | · | · |
| 35.8 | MacroFactor | ↳ Sync logged alcohol to Apple Health's Alcohol Consumption metric | subtask | · | · | · | · |
| 35.9 | MacroFactor | ↳ Track "standard drinks" per week and set a weekly standard-drinks ceiling | subtask | · | · | · | · |
| 35.10 | MacroFactor | ↳ Quick-select from specific drink types with ABV and volume as inputs | subtask | · | · | · | · |
| **36** | MacroFactor | **Change Unit For Water** | Planned | Improvements | 713 | Option to view water volumetrically instead of by weight; created Oct 2022. _(11 comments)_ | Yes |
| 36.1 | MacroFactor | ↳ Display/log water in fluid ounces instead of grams | subtask | · | · | · | · |
| 36.2 | MacroFactor | ↳ Apply volumetric units (ml) by default to all liquids (e.g. milk in ml) | subtask | · | · | · | · |
| 36.3 | MacroFactor | ↳ Fix the dashboard so total water shows in the user's chosen unit, not grams | subtask | · | · | · | · |
| 36.4 | MacroFactor | ↳ Keep grams as an option for users who prefer measuring liquids by weight | subtask | · | · | · | · |
| **37** | MacroFactor | **100g Unified Food Search Option** | Planned | Nutrition | 1520 | Search results shown per 100g whenever weight is available; created Oct 2022. _(8 comments)_ | Yes |
| 37.1 | MacroFactor | ↳ Display search results normalized per 100g whenever weight is available | subtask | · | · | · | · |
| 37.2 | MacroFactor | ↳ Use 1g as the normalization unit instead of 100g to eliminate decimals | subtask | · | · | · | · |
| 37.3 | MacroFactor | ↳ Add a "Compare" feature to view similar grocery items side by side at a set weight | subtask | · | · | · | · |
| 37.4 | MacroFactor | ↳ For EU foods, drop the arbitrary serving size and just use grams | subtask | · | · | · | · |
| 37.5 | MacroFactor | ↳ Show a default per-100g macro view in recipe lists too | subtask | · | · | · | · |
| **38** | MacroFactor | **Grams Default Serving** | Planned | Nutrition | 2313 | Default serving for never-logged foods to grams; created Oct 2022. _(14 comments)_ | Yes |
| 38.1 | MacroFactor | ↳ Default the serving of never-before-logged foods to grams | subtask | · | · | · | · |
| 38.2 | MacroFactor | ↳ Make grams the default unit available for ALL foods including liquids | subtask | · | · | · | · |
| 38.3 | MacroFactor | ↳ Add a user setting to choose the default unit of measure | subtask | · | · | · | · |
| **39** | MacroFactor | **Water (general hydration) Tracker** | Planned | Nutrition | 5475 | Quick liquids-logging menu plus prominent daily intake view; created Oct 2022. _(36 comments)_ | Yes |
| 39.1 | MacroFactor | ↳ Quick menu specifically for logging liquids with a prominent day's-intake view | subtask | · | · | · | · |
| 39.2 | MacroFactor | ↳ Access/import water data from WaterMinder via Apple Health | subtask | · | · | · | · |
| 39.3 | MacroFactor | ↳ Add water via an Apple Watch integration/complication | subtask | · | · | · | · |
| 39.4 | MacroFactor | ↳ Provide a home-screen widget for quick water logging | subtask | · | · | · | · |
| 39.5 | MacroFactor | ↳ Clarify whether sauna/sweat loss factors into hydration tracking | subtask | · | · | · | · |
| 39.6 | MacroFactor | ↳ Quick-add buttons with presets: +250ml, +500ml, +1L, +330ml | subtask | · | · | · | · |
| 39.7 | MacroFactor | ↳ Fix database foods that have no water content set | subtask | · | · | · | · |
| 39.8 | MacroFactor | ↳ Have the hydration goal adjust based on activity level | subtask | · | · | · | · |
| 39.9 | MacroFactor | ↳ Auto-log the water content of drinks like Gatorade and sparkling water | subtask | · | · | · | · |
| 39.10 | MacroFactor | ↳ Sync water/hydration from Apple Health and Google Health Connect | subtask | · | · | · | · |
| 39.11 | MacroFactor | ↳ Customizable preset amounts on the quick-track buttons plus a custom-amount option | subtask | · | · | · | · |
| 39.12 | MacroFactor | ↳ Show water logs inline in the Food Log timeline rather than on a separate page | subtask | · | · | · | · |
| 39.13 | MacroFactor | ↳ Allow water quick-track buttons to appear in Favorites or Shortcuts bars | subtask | · | · | · | · |
| 39.14 | MacroFactor | ↳ Add a fluid ounce unit option for water tracking | subtask | · | · | · | · |
| 39.15 | MacroFactor | ↳ Make water visible on the main dashboard with a quick-add option | subtask | · | · | · | · |
| 39.16 | MacroFactor | ↳ Provide multiple units: fl oz, liters, ml | subtask | · | · | · | · |
| 39.17 | MacroFactor | ↳ Integrate with Garmin watch / cycling computer for logging water during exercise | subtask | · | · | · | · |
| 39.18 | MacroFactor | ↳ Let hydration sync from Garmin while ignoring Garmin's recommendation | subtask | · | · | · | · |
| 39.19 | MacroFactor | ↳ Have the barcode scanner scan water bottles and auto-add the bottle's oz to the goal | subtask | · | · | · | · |
| 39.20 | MacroFactor | ↳ Include hydration under the Habits section | subtask | · | · | · | · |
| 39.21 | MacroFactor | ↳ Import water data from smart bottles (HidrateSpark, Larq) via Apple Health | subtask | · | · | · | · |
| 39.22 | MacroFactor | ↳ Import hydration data from Google Health Connect | subtask | · | · | · | · |
| **40** | MacroFactor | **App-wide Kilojoule Support** | Planned | Improvements | 285 | Settings option to apply kilojoules app-wide for viewing energy; created Oct 2022. _(27 comments)_ | Partial — kJ converted internally; no user-facing kJ display toggle |
| 40.1 | MacroFactor | ↳ Settings option to apply kilojoules as an app-wide unit | subtask | · | · | · | · |
| 40.2 | MacroFactor | ↳ Acceptable to ship a partial rollout — only a few places need kJ | subtask | · | · | · | · |
| 40.3 | MacroFactor | ↳ Display kJ at least on the dashboard as a minimum first step | subtask | · | · | · | · |
| 40.4 | MacroFactor | ↳ Ability to quickly switch between kcal and kJ by tapping the calories value | subtask | · | · | · | · |
| 40.5 | MacroFactor | ↳ kJ display needed to verify scanned entries against kJ-only packaging labels | subtask | · | · | · | · |
| **41** | MacroFactor | **Landscape Tablet Support** | Planned | Improvements | 978 | Scaling to different screen sizes alongside web expansion; created Oct 2022. (Source listed this item twice — duplicate dropped.) _(27 comments)_ | No — portrait-only; no landscape/tablet layout |
| 41.1 | MacroFactor | ↳ Scale to different screen sizes generally, paired with the web expansion | subtask | · | · | · | · |
| 41.2 | MacroFactor | ↳ At minimum allow the app to rotate/auto-rotate even if not fully optimized | subtask | · | · | · | · |
| 41.3 | MacroFactor | ↳ Support iPad use docked in a Magic Keyboard | subtask | · | · | · | · |
| 41.4 | MacroFactor | ↳ Support landscape for kitchen use (iPad propped to follow a recipe) | subtask | · | · | · | · |
| 41.5 | MacroFactor | ↳ Enable comfortable keyboard typing of entries on iPad in landscape | subtask | · | · | · | · |
| 41.6 | MacroFactor | ↳ Support foldable phones | subtask | · | · | · | · |
| 41.7 | MacroFactor | ↳ Bring landscape support to the web app | subtask | · | · | · | · |
| 41.8 | MacroFactor | ↳ Provide larger graphs / bigger fonts for users with poor eyesight | subtask | · | · | · | · |
| 41.9 | MacroFactor | ↳ Add multi-window support | subtask | · | · | · | · |
| 41.10 | MacroFactor | ↳ Add landscape support specifically to the workouts feature | subtask | · | · | · | · |
| 41.11 | MacroFactor | ↳ Support full-screen viewing of programs/reports | subtask | · | · | · | · |
| **42** | MacroFactor | **Net Carb Support** | Planned | Nutrition | 1271 | Display preference to show net carb in the food-log macro summary; created Oct 2022. _(49 comments)_ | No — no net-carb field/display |
| 42.1 | MacroFactor | ↳ Display net carb in the food log macronutrient summary element | subtask | · | · | · | · |
| 42.2 | MacroFactor | ↳ Add a dashboard toggle to switch between gross and net carbs | subtask | · | · | · | · |
| 42.3 | MacroFactor | ↳ Subtract sugar alcohols from carbs (with a toggle for whether they count) | subtask | · | · | · | · |
| 42.4 | MacroFactor | ↳ Provide an option to see net and total carbs at a glance simultaneously | subtask | · | · | · | · |
| 42.5 | MacroFactor | ↳ Add a settings toggle for net vs total carbs | subtask | · | · | · | · |
| 42.6 | MacroFactor | ↳ Make net carbs the basis for the carb macro target, not just a display option | subtask | · | · | · | · |
| 42.7 | MacroFactor | ↳ Report insoluble fibre separately | subtask | · | · | · | · |
| 42.8 | MacroFactor | ↳ Let users specify whether macro targets are based on total or net carbs | subtask | · | · | · | · |
| 42.9 | MacroFactor | ↳ Provide an option to display "available carbohydrates" app-wide (EU/AU/NZ label standard) | subtask | · | · | · | · |
| 42.10 | MacroFactor | ↳ When that option is selected, have the database separate fiber from carbs for all foods | subtask | · | · | · | · |
| 42.11 | MacroFactor | ↳ Fix database foods entered with incorrect carb values | subtask | · | · | · | · |
| 42.12 | MacroFactor | ↳ Default to net carbs when a non-US label is selected on food entry | subtask | · | · | · | · |
| 42.13 | MacroFactor | ↳ Show net carbs / remaining net carbs without extra math when pinned to the dashboard | subtask | · | · | · | · |
| 42.14 | MacroFactor | ↳ Apply net carbs to both the consumed and remaining values | subtask | · | · | · | · |
| 42.15 | MacroFactor | ↳ Show protein, fat and net carbs on the detailed per-food-item log | subtask | · | · | · | · |
| **43** | MacroFactor | **Web App Alpha** | Planned | Features | 4966 | Bringing MacroFactor to the web, developed alongside mobile features; created Oct 2022. _(121 comments)_ | No — no real web app (default Flutter web scaffold only) |
| 43.1 | MacroFactor | ↳ Build a local-first architecture for the app | subtask | · | · | · | · |
| 43.2 | MacroFactor | ↳ Support basic logging functionality in a browser even if the algorithm stays phone-only | subtask | · | · | · | · |
| 43.3 | MacroFactor | ↳ Web interface for detailed recipe entry/management | subtask | · | · | · | · |
| 43.4 | MacroFactor | ↳ Provide a way to join the web app alpha/beta testing program | subtask | · | · | · | · |
| 43.5 | MacroFactor | ↳ Support viewing/visualizing data and graphs on a large screen | subtask | · | · | · | · |
| 43.6 | MacroFactor | ↳ Whole-week meal planning view with meal-planning details | subtask | · | · | · | · |
| 43.7 | MacroFactor | ↳ Keyboard-first data entry using Tab/Return key bindings (MyNetDiary model) | subtask | · | · | · | · |
| 43.8 | MacroFactor | ↳ Easy copy-paste integration with other data sources / recipe sites | subtask | · | · | · | · |
| 43.9 | MacroFactor | ↳ Manage subscription via the web (outside Apple/Google billing) | subtask | · | · | · | · |
| 43.10 | MacroFactor | ↳ Native desktop app for Mac/Windows rather than only a web app | subtask | · | · | · | · |
| 43.11 | MacroFactor | ↳ Use Compose Multiplatform for a single native codebase across web/desktop | subtask | · | · | · | · |
| 43.12 | MacroFactor | ↳ Provide a personal API token / public API endpoints | subtask | · | · | · | · |
| 43.13 | MacroFactor | ↳ API integration for Home Assistant | subtask | · | · | · | · |
| 43.14 | MacroFactor | ↳ Build workout programs for MacroFactor Workouts on the web | subtask | · | · | · | · |
| 43.15 | MacroFactor | ↳ Meal-plan simulation feature as an alternative to full meal planning | subtask | · | · | · | · |
| 43.16 | MacroFactor | ↳ Ship a pared-down MVP/alpha first (search, add food, view your day) | subtask | · | · | · | · |
| 43.17 | MacroFactor | ↳ Support copying over meals/days from the past in the web planning view | subtask | · | · | · | · |
| 43.18 | MacroFactor | ↳ Enable screenshare with a dietician/trainer/doctor for virtual visits | subtask | · | · | · | · |
| 43.19 | MacroFactor | ↳ Fix bugs when running the iOS app on Mac | subtask | · | · | · | · |
| 43.20 | MacroFactor | ↳ Provide an official ETA / timeline / status update | subtask | · | · | · | · |
| **44** | MacroFactor | **Apple Watch App (Workouts)** | Planned | Workouts | 1712 | Companion watchOS app to log workouts without the phone; created Jan 2026. Overlaps #59 and Gravl #90 (Apple Watch). _(99 comments)_ | No — no watchOS target |
| 44.1 | MacroFactor | ↳ Integrate the Apple Watch Ultra action button to log sets and advance the workout | subtask | · | · | · | · |
| 44.2 | MacroFactor | ↳ Reduce logging to one click on the watch | subtask | · | · | · | · |
| 44.3 | MacroFactor | ↳ Add an "L" complication that opens voice dictation to log food/exercise in one tap | subtask | · | · | · | · |
| 44.4 | MacroFactor | ↳ Capture heart rate during workouts and sync it to Apple Health | subtask | · | · | · | · |
| 44.5 | MacroFactor | ↳ Capture/estimate calories burned and sync to Apple Health | subtask | · | · | · | · |
| 44.6 | MacroFactor | ↳ Sync workout expenditure back to MacroFactor to adjust calorie expenditure | subtask | · | · | · | · |
| 44.7 | MacroFactor | ↳ Auto-detect/predict reps and estimate weight lifted from rep timing and history | subtask | · | · | · | · |
| 44.8 | MacroFactor | ↳ Track rest time and log sets directly on the watch (Hevy/Strong model) | subtask | · | · | · | · |
| 44.9 | MacroFactor | ↳ Build an Android WearOS companion app, not just watchOS | subtask | · | · | · | · |
| 44.10 | MacroFactor | ↳ Build a Samsung/Galaxy watch version | subtask | · | · | · | · |
| 44.11 | MacroFactor | ↳ Build a Garmin watch version | subtask | · | · | · | · |
| 44.12 | MacroFactor | ↳ Continuous heart rate monitoring available from the watch app at launch | subtask | · | · | · | · |
| 44.13 | MacroFactor | ↳ Make the watch action button configurable to a chosen food-intake method | subtask | · | · | · | · |
| 44.14 | MacroFactor | ↳ Fix the slow AI food search on the watch | subtask | · | · | · | · |
| 44.15 | MacroFactor | ↳ Starting a workout in MFWO should auto-start a watchOS workout session | subtask | · | · | · | · |
| 44.16 | MacroFactor | ↳ Log Apple Fitness "effort" rating when finishing a workout | subtask | · | · | · | · |
| 44.17 | MacroFactor | ↳ Log weights, reps and RIR/RPE per exercise from the watch | subtask | · | · | · | · |
| 44.18 | MacroFactor | ↳ Allow swapping between watch and phone mid-workout to read exercise instructions | subtask | · | · | · | · |
| 44.19 | MacroFactor | ↳ Rest timer notification/nudges on the watch when rest ends | subtask | · | · | · | · |
| 44.20 | MacroFactor | ↳ Provide a quick-start workout watch widget/complication | subtask | · | · | · | · |
| 44.21 | MacroFactor | ↳ Provide a TestFlight beta sign-up for the watch app | subtask | · | · | · | · |
| 44.22 | MacroFactor | ↳ Show next set's weight and reps on the watch smart stack | subtask | · | · | · | · |
| 44.23 | MacroFactor | ↳ Auto-advance the rest timer countdown to the next set | subtask | · | · | · | · |
| 44.24 | MacroFactor | ↳ Show desired/target rep range for the next set on the watch | subtask | · | · | · | · |
| 44.25 | MacroFactor | ↳ Keep expenditure/calorie estimates conservative for Apple Watch rings | subtask | · | · | · | · |
| 44.26 | MacroFactor | ↳ Full live-sync between watch and phone (Hevy model) | subtask | · | · | · | · |
| 44.27 | MacroFactor | ↳ Provide an estimated timeline for release | subtask | · | · | · | · |
| 44.28 | MacroFactor | ↳ Send an email notification when the watch app ships | subtask | · | · | · | · |
| **45** | MacroFactor | **Add Micronutrients to Custom Foods using %DV** | Won't Do | Nutrition | 84 | Rejection reason: new nutrition label makes amount-based entry more accurate. #Out of Scope; created Sep 2024. _(12 comments)_ | No — custom foods exist; no %DV micronutrient entry |
| 45.1 | MacroFactor | ↳ Add %DV as a third unit option (alongside mcg/IU) for micronutrient fields in custom foods | subtask | · | · | · | · |
| 45.2 | MacroFactor | ↳ Auto-convert an entered %DV to the absolute amount using a US daily-value lookup table | subtask | · | · | · | · |
| **46** | MacroFactor | **Cost of Foods & Recipes** | Won't Do | Features | 91 | Rejection reason: out of scope — the existing notes field can be used. #Out of Scope; created Sep 2024. _(9 comments)_ | No — cost only in restaurant menu analysis, not the food log |
| 46.1 | MacroFactor | ↳ Show cost per gram of food | subtask | · | · | · | · |
| 46.2 | MacroFactor | ↳ Let each user manually set their own food prices and currency | subtask | · | · | · | · |
| 46.3 | MacroFactor | ↳ Track total spend per meal and overall food spending | subtask | · | · | · | · |
| 46.4 | MacroFactor | ↳ Add a feature to attach cost to logged foods, with an opt-in daily spend stat | subtask | · | · | · | · |
| 46.5 | MacroFactor | ↳ Add a module (e.g. at check-ins) to update prices on recently bought foods | subtask | · | · | · | · |
| 46.6 | MacroFactor | ↳ Allow adjusting costs in real time at user-chosen intervals | subtask | · | · | · | · |
| 46.7 | MacroFactor | ↳ Scan grocery receipts to associate a cost with each logged ingredient | subtask | · | · | · | · |
| **47** | MacroFactor | **Add Activity Calories to Calorie Target** | Won't Do | Algorithm | 146 | Rejection reason: the expenditure algorithm is already the best method. #Invalid; created Sep 2024. _(14 comments)_ | Partial — cardio calories tracked; not wired into the calorie target |
| 47.1 | MacroFactor | ↳ Allow linking a Fitbit or other tracker to calculate calories burned | subtask | · | · | · | · |
| 47.2 | MacroFactor | ↳ Make activity-calorie inclusion an optional config setting | subtask | · | · | · | · |
| 47.3 | MacroFactor | ↳ Add a "log activity" function that adds burned calories and raises that day's intake target | subtask | · | · | · | · |
| 47.4 | MacroFactor | ↳ Track calories burned for specific workouts | subtask | · | · | · | · |
| 47.5 | MacroFactor | ↳ Use logged calorie burn to validate the expenditure algorithm | subtask | · | · | · | · |
| 47.6 | MacroFactor | ↳ Track non-weightlifting cardio activity: frequency, time, distance, type and calories | subtask | · | · | · | · |
| 47.7 | MacroFactor | ↳ Adjust weekly calorie targets for large swings in activity | subtask | · | · | · | · |
| 47.8 | MacroFactor | ↳ Let users declare upcoming-week activity changes | subtask | · | · | · | · |
| 47.9 | MacroFactor | ↳ Allow logging an activity by simple description (e.g. "Pilates 45 min") | subtask | · | · | · | · |
| **48** | MacroFactor | **Vacation Mode for Expenditure** | Won't Do | Algorithm | 165 | Rejection reason: expenditure algorithm already handles logging lapses. #Invalid; created Sep 2024. _(3 comments)_ | Partial — notification vacation mode exists; not an expenditure-algorithm mode |
| 48.1 | MacroFactor | ↳ Add a vacation mode to suppress weigh-in nagging during post-travel check-ins | subtask | · | · | · | · |
| **49** | MacroFactor | **Reverse Diet Goal** | Won't Do | Algorithm | 89 | Rejection reason: use the lowest-rate weight-gain goal instead. #Invalid; created Sep 2024. _(11 comments)_ | No — no reverse-diet goal type |
| 49.1 | MacroFactor | ↳ Reconsider the "Won't Do" stance — reverse dieting has psychological benefits for restrictive-diet recovery | subtask | · | · | · | · |
| 49.2 | MacroFactor | ↳ Add a guided transition feature from cutting to bulking that minimizes fat gain | subtask | · | · | · | · |
| 49.3 | MacroFactor | ↳ Provide a guided/automatic way to slowly transition out of a restrictive cut toward maintenance | subtask | · | · | · | · |
| 49.4 | MacroFactor | ↳ Treat "reverse diet" per modern usage as equivalent to a lean bulk | subtask | · | · | · | · |
| 49.5 | MacroFactor | ↳ Add an intervention when a user logs regularly but isn't losing weight below an expected height-based TDEE | subtask | · | · | · | · |
| 49.6 | MacroFactor | ↳ Clarify whether manually increasing values genuinely mimics a structured calorie ramp-up | subtask | · | · | · | · |
| **50** | MacroFactor | **Family Plan** | Won't Do | Features | 314 | Rejection reason: flat-rate pricing avoids offsetting costs onto some users; created Sep 2024. _(16 comments)_ | No — no family/multi-profile plan |
| 50.1 | MacroFactor | ↳ Offer at least a partner/couple plan (2-person) | subtask | · | · | · | · |
| 50.2 | MacroFactor | ↳ Add an easy way to share recipes between users/accounts | subtask | · | · | · | · |
| 50.3 | MacroFactor | ↳ Add an easy way to share individual meals between users | subtask | · | · | · | · |
| 50.4 | MacroFactor | ↳ Add a copy-meal / share-meal-as-QR-code mechanism | subtask | · | · | · | · |
| 50.5 | MacroFactor | ↳ Charge a higher price for a family plan so more household members can join | subtask | · | · | · | · |
| 50.6 | MacroFactor | ↳ Add a profile system (multiple profiles under one account) | subtask | · | · | · | · |
| 50.7 | MacroFactor | ↳ Allow the main account owner to set up and update food logs for additional profiles | subtask | · | · | · | · |
| 50.8 | MacroFactor | ↳ Limit a plan to a fixed number of devices/profiles with extra cost per additional | subtask | · | · | · | · |
| 50.9 | MacroFactor | ↳ Reconsider family pricing now that non-app-store subscription management is coming | subtask | · | · | · | · |
| 50.10 | MacroFactor | ↳ Add a "gift/sponsor a subscription" option to pay for another existing account | subtask | · | · | · | · |
| 50.11 | MacroFactor | ↳ Notify a sponsored account and give a 30-day grace window if the sponsor cancels | subtask | · | · | · | · |
| 50.12 | MacroFactor | ↳ Require a minimum subscription commitment to mitigate revenue concerns | subtask | · | · | · | · |
| 50.13 | MacroFactor | ↳ Match competitors by offering household/family sharing at comparable pricing | subtask | · | · | · | · |
| **51** | MacroFactor | **Wearable Integrations (Fitbit, Garmin, Oura, Whoop, ...)** | Won't Do | Integrations | 695 | Rejection reason: routed via Apple Health / Health Connect; wearable activity data isn't used by the algorithms. #Out of Scope; created Sep 2024. Overlaps Gravl #116 (Garmin Connect). _(60 comments)_ | Partial — Fitbit/Garmin/Strava/Peloton supported; no Oura/Whoop |
| 51.1 | MacroFactor | ↳ Automatically pull daily weight and body fat % from Garmin Connect each morning | subtask | · | · | · | · |
| 51.2 | MacroFactor | ↳ Provide direct Garmin Connect integration rather than only via Apple Health / Health Connect | subtask | · | · | · | · |
| 51.3 | MacroFactor | ↳ Add Oura Ring integration (sleep, temperature, heart rate, readiness) | subtask | · | · | · | · |
| 51.4 | MacroFactor | ↳ Pull data directly from the Samsung Health app | subtask | · | · | · | · |
| 51.5 | MacroFactor | ↳ Surface/add Samsung Health in the integrations section on Android | subtask | · | · | · | · |
| 51.6 | MacroFactor | ↳ Sync sleep data into the app to track sleep improvement | subtask | · | · | · | · |
| 51.7 | MacroFactor | ↳ Add Dexcom integration | subtask | · | · | · | · |
| 51.8 | MacroFactor | ↳ Add Omnipod / Tandem insulin pump integration | subtask | · | · | · | · |
| 51.9 | MacroFactor | ↳ Add Strava integration | subtask | · | · | · | · |
| 51.10 | MacroFactor | ↳ Add Whoop integration | subtask | · | · | · | · |
| 51.11 | MacroFactor | ↳ Add Polar integration | subtask | · | · | · | · |
| 51.12 | MacroFactor | ↳ Use activity/workout data to inform BMR/expenditure calculations | subtask | · | · | · | · |
| 51.13 | MacroFactor | ↳ Sync full weight history (past and future) from Garmin into one chart | subtask | · | · | · | · |
| 51.14 | MacroFactor | ↳ Fix the Apple Health steps integration so steps don't need manual editing | subtask | · | · | · | · |
| 51.15 | MacroFactor | ↳ Fully support all Health Connect data types from smart scales | subtask | · | · | · | · |
| 51.16 | MacroFactor | ↳ Export workout routines to Garmin via their Training API | subtask | · | · | · | · |
| 51.17 | MacroFactor | ↳ Export workout routines to Apple Health and Google Fit for smartwatches | subtask | · | · | · | · |
| 51.18 | MacroFactor | ↳ Implement fuzzy exercise-name matching so names match what Garmin expects | subtask | · | · | · | · |
| 51.19 | MacroFactor | ↳ Sync strength workouts to Garmin watch including the rest timer | subtask | · | · | · | · |
| 51.20 | MacroFactor | ↳ Post completed workouts to Garmin so it can account for needed recovery | subtask | · | · | · | · |
| 51.21 | MacroFactor | ↳ Feed exercise data into Training Peaks for athletes | subtask | · | · | · | · |
| 51.22 | MacroFactor | ↳ Add Stelo integration for glucose monitoring | subtask | · | · | · | · |
| 51.23 | MacroFactor | ↳ Add Wear OS support | subtask | · | · | · | · |
| 51.24 | MacroFactor | ↳ Add Galaxy Watch support | subtask | · | · | · | · |
| 51.25 | MacroFactor | ↳ Fix Apple Health so app-finished workout calories don't overwrite Apple Watch calorie data | subtask | · | · | · | · |
| **52** | MacroFactor | **Smart Progression Weight Recommendation Improvement** | Released | Algorithm | 710 | Auto-adjusts target rep range so recommended weight matches the user's gym profile; opt-out; created Jan 2026. Subtasks are open post-release follow-ups. _(13 comments)_ | Yes |
| 52.1 | MacroFactor | ↳ Learn the user's pattern of weight/rep choices and default to the option they pick most often | subtask | · | · | · | · |
| 52.2 | MacroFactor | ↳ Keep the "Fix" tool to swap between higher-weight/lower-rep and lower-weight/higher-rep options | subtask | · | · | · | · |
| 52.3 | MacroFactor | ↳ Auto-resolve when switching gym profiles leaves a planned workout undoable with new equipment | subtask | · | · | · | · |
| 52.4 | MacroFactor | ↳ When the user declines to lower the weight, update the rep estimation to reflect the weight entered | subtask | · | · | · | · |
| 52.5 | MacroFactor | ↳ Allow smart progression when choosing "last lifts" as the workout baseline | subtask | · | · | · | · |
| 52.6 | MacroFactor | ↳ Avoid recommending non-existent weights like 0.5 lb increments | subtask | · | · | · | · |
| 52.7 | MacroFactor | ↳ Support machines with a standard fixed increment plus extra add-on plates | subtask | · | · | · | · |
| 52.8 | MacroFactor | ↳ Keep the user's target rep range and RIR per set and only vary the weight by availability | subtask | · | · | · | · |
| 52.9 | MacroFactor | ↳ Allow entering a weight and have the reps auto-populate | subtask | · | · | · | · |
| 52.10 | MacroFactor | ↳ Add a per-user progressive-overload preference setting | subtask | · | · | · | · |
| 52.11 | MacroFactor | ↳ Handle weights in the gym profile but not physically available at the current station | subtask | · | · | · | · |
| 52.12 | MacroFactor | ↳ Support fractional plates so the weight-increase button steps by 0.5 lb | subtask | · | · | · | · |
| 52.13 | MacroFactor | ↳ Suggest plate-loading changes additively instead of swapping plates | subtask | · | · | · | · |
| **53** | MacroFactor | **Write Workout Session to Apple Health** | Released | Integrations | 925 | Writes completed workout sessions to Apple Health for ring/activity tracking; created Jan 2026. Subtasks are open post-release follow-ups. _(28 comments)_ | Yes |
| 53.1 | MacroFactor | ↳ Write workout sessions to Android Health Connect, not just Apple Health | subtask | · | · | · | · |
| 53.2 | MacroFactor | ↳ Use scientifically reasonable calorie expenditure values for weightlifting | subtask | · | · | · | · |
| 53.3 | MacroFactor | ↳ Allow user customization of active calorie expenditure during weight training | subtask | · | · | · | · |
| 53.4 | MacroFactor | ↳ Capture/sync heart-rate data during workouts | subtask | · | · | · | · |
| 53.5 | MacroFactor | ↳ Make completed workouts count toward the Apple Watch activity rings | subtask | · | · | · | · |
| 53.6 | MacroFactor | ↳ Retroactively note old/historical Apple Health workouts in the Workouts app | subtask | · | · | · | · |
| 53.7 | MacroFactor | ↳ Also write workout sessions to Samsung Health | subtask | · | · | · | · |
| 53.8 | MacroFactor | ↳ Ensure heart-rate data is included in the Apple Health push | subtask | · | · | · | · |
| 53.9 | MacroFactor | ↳ Ensure completed workouts appear in Apple Fitness as structured strength sessions with metadata | subtask | · | · | · | · |
| **54** | MacroFactor | **iOS Live Activity** | Released | Features | 1430 | Shows active set and rest timer on lock screen plus rest timer in Dynamic Island; created Jan 2026. Subtasks are open post-release follow-ups. _(33 comments)_ | Yes |
| 54.1 | MacroFactor | ↳ Fix the rest-timer sound so it plays via AirPods / even when the phone is on silent | subtask | · | · | · | · |
| 54.2 | MacroFactor | ↳ Add the Android equivalent (live update / Samsung Now Bar) | subtask | · | · | · | · |
| 54.3 | MacroFactor | ↳ Add in-line rest timers between sets (like Strong) | subtask | · | · | · | · |
| 54.4 | MacroFactor | ↳ Add home-screen widgets (weekly workouts, total weight lifted) | subtask | · | · | · | · |
| 54.5 | MacroFactor | ↳ Show current-workout info on a paired Apple Watch via the Live Activity | subtask | · | · | · | · |
| 54.6 | MacroFactor | ↳ Add an app-specific notification sound | subtask | · | · | · | · |
| 54.7 | MacroFactor | ↳ Allow quickly switching to an in-progress workout from any screen | subtask | · | · | · | · |
| 54.8 | MacroFactor | ↳ Add full Apple Watch app compatibility | subtask | · | · | · | · |
| 54.9 | MacroFactor | ↳ Show the weight required for the next set on the Live Activity | subtask | · | · | · | · |
| 54.10 | MacroFactor | ↳ Show the plates required for the next set on the Live Activity | subtask | · | · | · | · |
| 54.11 | MacroFactor | ↳ Allow seeing and editing sets/reps and viewing notes from the lock-screen Live Activity | subtask | · | · | · | · |
| 54.12 | MacroFactor | ↳ Add an option to prevent iOS from suspending the app while a workout is in progress | subtask | · | · | · | · |
| 54.13 | MacroFactor | ↳ Add optional nudges when a rest finishes plus follow-up reminders | subtask | · | · | · | · |
| 54.14 | MacroFactor | ↳ Make the post-tap update animation more subtle | subtask | · | · | · | · |
| 54.15 | MacroFactor | ↳ Reconsider whether swiping between exercises changes the "current set" shown | subtask | · | · | · | · |
| 54.16 | MacroFactor | ↳ Reconsider whether the "Up Next" snippet is helpful | subtask | · | · | · | · |
| 54.17 | MacroFactor | ↳ Add an auto-next option after the rest timer hits zero | subtask | · | · | · | · |
| **55** | MacroFactor | **MacroFactor Year 4 Summary** | Released | Features | 24 | Links to the MacroFactor Annual Report for 2025; created Dec 2025. _(0 comments)_ | Yes |
| **56** | MacroFactor | **Workout App** | Released | Workouts | 2838 | Standalone evidence-based workout app; created Sep 2024. Subtasks are open post-release follow-ups. _(84 comments)_ | Yes |
| 56.1 | MacroFactor | ↳ Integrate the workout app with the existing MacroFactor nutrition app (shared experience) | subtask | · | · | · | · |
| 56.2 | MacroFactor | ↳ Allow integration with Apple Fitness if expenditure data is taken from the workout app | subtask | · | · | · | · |
| 56.3 | MacroFactor | ↳ Support subscribing to / importing pre-built workout plans (e.g. Jeff Nippard's) | subtask | · | · | · | · |
| 56.4 | MacroFactor | ↳ Support importing workouts available as RSS feeds | subtask | · | · | · | · |
| 56.5 | MacroFactor | ↳ Support logging CrossFit-style workouts | subtask | · | · | · | · |
| 56.6 | MacroFactor | ↳ Add individual per-side weight/rep counters for isolated exercises | subtask | · | · | · | · |
| 56.7 | MacroFactor | ↳ Add PR (personal record) tracking | subtask | · | · | · | · |
| 56.8 | MacroFactor | ↳ Provide a Wear OS version | subtask | · | · | · | · |
| 56.9 | MacroFactor | ↳ Combine weight + calories = result, don't just import exercises like generic trackers | subtask | · | · | · | · |
| 56.10 | MacroFactor | ↳ Select exercises based on Jeff Nippard's exercise tier lists | subtask | · | · | · | · |
| 56.11 | MacroFactor | ↳ Look at the RP Strength app as a reference | subtask | · | · | · | · |
| 56.12 | MacroFactor | ↳ Preplanned workouts with rep logging from watch or phone, reorder, automatic rest timers | subtask | · | · | · | · |
| 56.13 | MacroFactor | ↳ Frictionless fully-customizable tracking without forcing a training philosophy | subtask | · | · | · | · |
| 56.14 | MacroFactor | ↳ Support tracking cardio/endurance sessions in addition to lifting | subtask | · | · | · | · |
| 56.15 | MacroFactor | ↳ Allow custom intensity-set types, avoid forcing an RIR paradigm or mandatory deloads | subtask | · | · | · | · |
| 56.16 | MacroFactor | ↳ Acquire or merge with Future Fitness | subtask | · | · | · | · |
| 56.17 | MacroFactor | ↳ Allow importing data from the Strong app | subtask | · | · | · | · |
| 56.18 | MacroFactor | ↳ Incorporate cardio/endurance expenditure into TDEE and goals | subtask | · | · | · | · |
| 56.19 | MacroFactor | ↳ Pull cardio data from sources such as a Garmin watch | subtask | · | · | · | · |
| 56.20 | MacroFactor | ↳ Auto-upload purchased online programs so users only enter weight/reps/time | subtask | · | · | · | · |
| 56.21 | MacroFactor | ↳ Match the quality/feature set of the Hevy app | subtask | · | · | · | · |
| 56.22 | MacroFactor | ↳ Add a daily checklist for water, steps and supplements | subtask | · | · | · | · |
| 56.23 | MacroFactor | ↳ Cross-reference with the MacroFactor app for smart training based on goals | subtask | · | · | · | · |
| 56.24 | MacroFactor | ↳ Automatically incorporate progressive overload guidance for beginners | subtask | · | · | · | · |
| 56.25 | MacroFactor | ↳ Allow importing workout routines from a spreadsheet | subtask | · | · | · | · |
| 56.26 | MacroFactor | ↳ Integrate with Strava and Garmin Connect | subtask | · | · | · | · |
| 56.27 | MacroFactor | ↳ Offer programs for non-resistance disciplines (running, cycling, triathlon) | subtask | · | · | · | · |
| 56.28 | MacroFactor | ↳ Interface with Tonal machine workouts | subtask | · | · | · | · |
| 56.29 | MacroFactor | ↳ Sync with the diet app to detect stalled progress and adjust diet, lifts and rest | subtask | · | · | · | · |
| 56.30 | MacroFactor | ↳ Build in Jeff Nippard's programs with an unlock code on purchase | subtask | · | · | · | · |
| 56.31 | MacroFactor | ↳ Support mesocycle analysis with notes and strength/hypertrophy-focused analysis | subtask | · | · | · | · |
| 56.32 | MacroFactor | ↳ Offer a lifetime membership option | subtask | · | · | · | · |
| 56.33 | MacroFactor | ↳ Offer a founding-member one-time lifetime price promo | subtask | · | · | · | · |
| 56.34 | MacroFactor | ↳ Provide historical workout data with visualizations/graphs | subtask | · | · | · | · |
| 56.35 | MacroFactor | ↳ All-in-one app with photo logging, body metrics and workout logging/graphing | subtask | · | · | · | · |
| 56.36 | MacroFactor | ↳ Collaborate with @fitnovate | subtask | · | · | · | · |
| 56.37 | MacroFactor | ↳ Eventually offer MacroFactor food scales and hardware | subtask | · | · | · | · |
| 56.38 | MacroFactor | ↳ Improve the basic UX of the nutrition app before expanding | subtask | · | · | · | · |
| 56.39 | MacroFactor | ↳ Provide a bundle price with the MacroFactor subscription | subtask | · | · | · | · |
| 56.40 | MacroFactor | ↳ Link workout logging to body composition goals, support swimming/biking/etc. | subtask | · | · | · | · |
| 56.41 | MacroFactor | ↳ Add a friend leaderboard (as Gravl has) for motivation | subtask | · | · | · | · |
| 56.42 | MacroFactor | ↳ Include AI and a connection to MacroFactor | subtask | · | · | · | · |
| 56.43 | MacroFactor | ↳ Add Strava integration | subtask | · | · | · | · |
| 56.44 | MacroFactor | ↳ Keep it efficient — minimal clicks, taps and typing during a gym session | subtask | · | · | · | · |
| 56.45 | MacroFactor | ↳ Offer powerlifting and powerbuilding program options | subtask | · | · | · | · |
| 56.46 | MacroFactor | ↳ Automatically track reps and guess exercises from movement (Train app model) | subtask | · | · | · | · |
| 56.47 | MacroFactor | ↳ Track from Apple Watch | subtask | · | · | · | · |
| 56.48 | MacroFactor | ↳ Make automatic progressive overload work for both weight and reps | subtask | · | · | · | · |
| 56.49 | MacroFactor | ↳ Allow importing existing data from Strong, Hevy or a standardized CSV | subtask | · | · | · | · |
| 56.50 | MacroFactor | ↳ Provide a simple starting point for people new to working out | subtask | · | · | · | · |
| 56.51 | MacroFactor | ↳ Provide a web interface for the workout app | subtask | · | · | · | · |
| 56.52 | MacroFactor | ↳ Allow building PPL splits from YouTube exercises | subtask | · | · | · | · |
| 56.53 | MacroFactor | ↳ Sync with WHOOP so Recovery Score influences daily training load | subtask | · | · | · | · |
| 56.54 | MacroFactor | ↳ Use HRV trends to automatically adjust intensity recommendations | subtask | · | · | · | · |
| 56.55 | MacroFactor | ↳ Use sleep + strain data to suggest when to push or pull back (autoregulated training) | subtask | · | · | · | · |
| 56.56 | MacroFactor | ↳ Provide a "Recovery Score to Suggested Training Stress" model | subtask | · | · | · | · |
| 56.57 | MacroFactor | ↳ Support RPE for weight exercises | subtask | · | · | · | · |
| 56.58 | MacroFactor | ↳ Support Avg. Speed and Avg. Incline for treadmill workouts | subtask | · | · | · | · |
| 56.59 | MacroFactor | ↳ Allow one set to be split into right/left arm/leg | subtask | · | · | · | · |
| 56.60 | MacroFactor | ↳ Connect WHOOP/Apple Watch for heart-rate zones | subtask | · | · | · | · |
| 56.61 | MacroFactor | ↳ Link to exercise demonstration videos rather than long written descriptions | subtask | · | · | · | · |
| 56.62 | MacroFactor | ↳ Add an in-app place to give workout-app-specific feedback and see the pipeline | subtask | · | · | · | · |
| 56.63 | MacroFactor | ↳ Track cardio sessions (miles, time, type) and adjust calories/water accordingly | subtask | · | · | · | · |
| **57** | MacroFactor | **MacroFactor Year 3 Summary** | Released | Features | 29 | Links to the MacroFactor Annual Report for 2024; created Sep 2024. _(0 comments)_ | Yes |
| **58** | MacroFactor | **MacroFactor Year 2 Summary** | Released | Features | 30 | Links to the MacroFactor Annual Report for 2023; created Oct 2023. _(0 comments)_ | Yes |
| **59** | MacroFactor | **MacroFactor on Apple Watch** | Released | Integrations | 3597 | Brings MacroFactor to Apple Watch to view charts and log go-to foods; created Oct 2022. Overlaps #44 and Gravl #90. _(49 comments)_ | No — no watchOS app |
| 59.1 | MacroFactor | ↳ Add a watch app with food logging so users can track without a smartphone | subtask | · | · | · | · |
| 59.2 | MacroFactor | ↳ Add Garmin watch compatibility | subtask | · | · | · | · |
| 59.3 | MacroFactor | ↳ Add a watch face complication showing remaining calories / protein at a glance | subtask | · | · | · | · |
| 59.4 | MacroFactor | ↳ Implement simple voice commands for the watch app | subtask | · | · | · | · |
| 59.5 | MacroFactor | ↳ Add a weigh-in / weight reference view on the watch | subtask | · | · | · | · |
| 59.6 | MacroFactor | ↳ Add support for Samsung Galaxy Watch, including adding food via complication | subtask | · | · | · | · |
| 59.7 | MacroFactor | ↳ Add an Android / WearOS version with at least a macro dashboard | subtask | · | · | · | · |
| 59.8 | MacroFactor | ↳ Allow quickly logging body weight from the watch | subtask | · | · | · | · |
| 59.9 | MacroFactor | ↳ Add complications for weight graph, remaining/consumed calories, P/F/C macros and any nutrient | subtask | · | · | · | · |
| 59.10 | MacroFactor | ↳ Keep watch complications consistent with the iOS widget set | subtask | · | · | · | · |
| 59.11 | MacroFactor | ↳ Support quick-add, recipes, go-to foods and favorite foods from the watch | subtask | · | · | · | · |
| 59.12 | MacroFactor | ↳ Make the watch app Siri / dictation enabled for hands-free food logging | subtask | · | · | · | · |
| 59.13 | MacroFactor | ↳ Support quick-add calories functionality on the watch | subtask | · | · | · | · |
| 59.14 | MacroFactor | ↳ Add water tracking to the watch app | subtask | · | · | · | · |
| 59.15 | MacroFactor | ↳ Have the watch complication link to the dashboard and reflect all settings/data | subtask | · | · | · | · |
| 59.16 | MacroFactor | ↳ Ensure feature parity between Apple and Android (not OS-specific) | subtask | · | · | · | · |
| 59.17 | MacroFactor | ↳ Add support for additional nutrient complications (e.g. saturated fat, fiber) | subtask | · | · | · | · |
| 59.18 | MacroFactor | ↳ Add a quick-add feature for water with multiple measurement types | subtask | · | · | · | · |
| 59.19 | MacroFactor | ↳ Add a weight-trend complication, both modular-face and circular | subtask | · | · | · | · |
| 59.20 | MacroFactor | ↳ Allow quickly editing and completing workouts on Apple Watch | subtask | · | · | · | · |
| 59.21 | MacroFactor | ↳ Add direct integration with Garmin Connect | subtask | · | · | · | · |
| **60** | MacroFactor | **MacroFactor Year 1 Summary** | Released | Features | 67 | Links to the MacroFactor Annual Report for 2022; created Oct 2022. _(0 comments)_ | Yes |
| **61** | MacroFactor | **In-app Subscription Management** | Released | Features | 1035 | In-app subscription management letting users (esp. Android) view and change their plan; created Oct 2022. Subtasks are open post-release follow-ups. _(6 comments)_ | Yes |
| 61.1 | MacroFactor | ↳ Offer a discount for multi-year pricing | subtask | · | · | · | · |
| 61.2 | MacroFactor | ↳ Allow paying the subscription via Google instead of Apple Pay | subtask | · | · | · | · |
| 61.3 | MacroFactor | ↳ Allow paying directly without the Google or Apple app stores (avoid the 30% fee) | subtask | · | · | · | · |
| **62** | Gravl | **Reorder upcoming workouts** | Released | Improvements | N/A | App v1.38, released Jan 5, 2026. | Partial — exercises reorder within a workout; no reorder across days |
| **63** | Gravl | **Add steps in Stair Climber** | Released | Improvements | N/A | App v1.38, released Jan 5, 2026. | No — no stair-climber step field |
| **64** | Gravl | **Add Incline in Treadmill** | Released | Improvements | N/A | App v1.38, released Jan 5, 2026. | Yes |
| **65** | Gravl | **New Library screen** | Released | Improvements | N/A | App v1.37, released Dec 29, 2025. | Yes |
| 65.1 | Gravl | ↳ Faster navigation to manage favorite workouts and routines | subtask | · | · | · | · |
| 65.2 | Gravl | ↳ Create multiple custom routines | subtask | · | · | · | · |
| 65.3 | Gravl | ↳ Share custom routines with friends | subtask | · | · | · | · |
| **66** | Gravl | **Import workouts from socials** | Released | Features | N/A | App v1.37, released Dec 29, 2025. | Partial — PDF/photo/URL import for equipment + history files; no routine import from social |
| 66.1 | Gravl | ↳ Create workouts and routines from social media videos | subtask | · | · | · | · |
| 66.2 | Gravl | ↳ Create from web blogs | subtask | · | · | · | · |
| 66.3 | Gravl | ↳ Create from PDFs | subtask | · | · | · | · |
| **67** | Gravl | **Strava integration** | Released | Integrations | N/A | App v1.36, released Sep 28, 2025. | Yes |
| **68** | Gravl | **Equipment starting weight** | Released | Improvements | N/A | App v1.35.0, released Sep 14, 2025. | Yes |
| **69** | Gravl | **Static stretching** | Released | Features | N/A | App v1.34.0, released Jul 25, 2025. | Yes |
| **70** | Gravl | **Effort-based rating for cardio workouts** | Released | Improvements | N/A | App v1.33, released Jul 1, 2025. | Yes |
| **71** | Gravl | **React and comment on Friends workouts** | Released | Features | N/A | App v1.32, released Jun 17, 2025. | Yes |
| **72** | Gravl | **Google Health Connect** | Released | Integrations | N/A | App v1.31.2, released May 29, 2025. | Yes |
| **73** | Gravl | **Deload week** | Released | Algorithm | N/A | App v1.30.0, released Apr 29, 2025. | Yes |
| **74** | Gravl | **Select focus/exclude on specific muscle groups** | Released | Features | N/A | App v1.29, released Apr 10, 2025. | Yes |
| **75** | Gravl | **Split shoulders into front, side and rear delt** | Released | Improvements | N/A | App v1.29, released Apr 10, 2025. | Partial — delt sub-region aliases exist but collapse to "Shoulders" |
| **76** | Gravl | **Friends leaderboards and ranks** | Released | Features | N/A | App v1.28.0, released Mar 2, 2025. | Yes |
| **77** | Gravl | **Custom rep ranges and sets** | Released | Improvements | N/A | App v1.27.0, released Feb 26, 2025. | Yes |
| **78** | Gravl | **Widget iOS** | Released | Features | N/A | App v1.26.0, released Feb 21, 2025. | Yes |
| **79** | Gravl | **Add mobility warm up exercises** | Released | Features | N/A | App v1.26.0, released Feb 21, 2025. | Yes |
| **80** | Gravl | **Body measurements** | Released | Features | N/A | App v1.5.4, released Feb 14, 2025. | Yes |
| **81** | Gravl | **Gym Profiles** | Released | Features | N/A | App v1.5.4, released Feb 14, 2025. | Yes |
| **82** | Gravl | **New badges** | Released | Improvements | N/A | App v1.22.0, released Jan 15, 2025. | Yes |
| **83** | Gravl | **Max weight in machines** | Released | Improvements | N/A | App v1.21.0, released Jan 8, 2025. | Yes |
| **84** | Gravl | **Log workouts in the past** | Released | Features | N/A | App v1.19.3, released Dec 9, 2024. | Partial — no clear backdated manual workout logging |
| **85** | Gravl | **Custom exercises** | Released | Features | N/A | App v1.17.0, released Nov 22, 2024. | Yes |
| **86** | Gravl | **Include "Favorite" workouts within a custom split** | Released | Features | N/A | App v1.16.0, released Nov 6, 2024. | Partial — favorite workouts + custom split builder exist; inclusion within a split unverified |
| **87** | Gravl | **Support simultaneously lbs and kg in different gym equipment** | Released | Improvements | N/A | App v1.15.0, released Oct 23, 2024. | Yes |
| **88** | Gravl | **Reverse Pyramid sets** | Released | Improvements | N/A | App v1.14.0, released Oct 15, 2024. | Yes |
| **89** | Gravl | **Add crossfit and powerlifting exercises** | Released | Improvements | N/A | App v1.13.1, released Oct 1, 2024. | Yes |
| **90** | Gravl | **Apple Watch** | Released | Integrations | N/A | App v1.13.0, released Sep 27, 2024. Overlaps MacroFactor #44 and #59. | No — no watchOS app |
| **91** | Gravl | **Custom setting for warm up sets and rest timers** | Released | Improvements | N/A | App v1.12.0, released Jul 23, 2024. | Yes |
| **92** | Gravl | **Split Shoulders and Trapezius** | Released | Algorithm | N/A | App v1.11.0, released Jul 4, 2024. | Partial — trap/shoulder aliases exist but collapse to parent groups |
| **93** | Gravl | **See weekly workouts in advance** | Released | Features | N/A | App v1.11.0, released Jul 4, 2024. | Yes |
| **94** | Gravl | **View last weights lifted** | Released | Improvements | N/A | App v1.10.0, released Jun 16, 2024. | Yes |
| **95** | Gravl | **Notes in exercises** | Released | Features | N/A | App v1.10.0, released Jun 16, 2024. | Yes |
| **96** | Gravl | **Manually add warm up sets** | Released | Features | N/A | App v1.10.0, released Jun 16, 2024. | Yes |
| **97** | Gravl | **Pause workouts** | Released | Features | N/A | App v1.9.0, released Jun 3, 2024. | Yes |
| **98** | Gravl | **Upload photo and share** | Released | Features | N/A | App v1.9.0, released Jun 3, 2024. | Yes |
| **99** | Gravl | **Edit past workouts** | Released | Features | N/A | App v1.9.0, released Jun 3, 2024. | No — no edit of a past completed workout |
| **100** | Gravl | **Download exercise videos (offline)** | Released | Improvements | N/A | App v1.8.4, released May 14, 2024. | Yes |
| **101** | Gravl | **Cardio exercises** | Released | Features | N/A | App v1.8.4, released May 14, 2024. | Yes |
| **102** | Gravl | **Workout Splits Library** | Released | Features | N/A | App v1.8.0, released Apr 17, 2024. | Yes |
| **103** | Gravl | **Timer in time-based exercises** | Released | Improvements | N/A | App v1.7.0, released Apr 2, 2024. | Yes |
| **104** | Gravl | **Skip workouts** | Released | Features | N/A | App v1.7.0, released Apr 2, 2024. | Yes |
| **105** | Gravl | **Edit Muscle Recovery** | Released | Features | N/A | App v1.7.0, released Apr 2, 2024. | Partial — recovery surfaces exist; manual recovery editing unverified |
| **106** | Gravl | **Trends** | Released | Features | N/A | App v1.6.0, released Mar 14, 2024. | Yes |
| **107** | Gravl | **Custom weights** | Released | Features | N/A | App v1.6.0, released Mar 14, 2024. | Yes |
| **108** | Gravl | **Monthly summary with highlights** | In Progress | Features | N/A | No version/date yet. | Yes |
| **109** | Gravl | **AI form checker** | In Progress | Features | N/A | No version/date yet. Competitor parity with Zealova's form-analysis feature; also MacroFactor-adjacent. | Yes |
| 109.1 | Gravl | ↳ Upload videos of exercise execution | subtask | · | · | · | · |
| 109.2 | Gravl | ↳ Receive feedback on technique | subtask | · | · | · | · |
| **110** | Gravl | **Audio guidance in exercise videos** | Planned | Features | N/A | Planned for Q1 '26. | No — no exercise-video narration |
| **111** | Gravl | **Wear OS app** | Backlog | Integrations | N/A | No version/date yet. Overlaps MacroFactor #34 (Wear OS Workout App). | Partial — phone-side Wear plumbing; no watch module built |
| **112** | Gravl | **Workout programs** | Backlog | Features | N/A | No version/date yet. | Yes |
| **113** | Gravl | **Plate quantities** | Backlog | Improvements | N/A | No version/date yet. | Yes |
| **114** | Gravl | **Set type: Rest pause** | Backlog | Features | N/A | No version/date yet. | Yes |
| **115** | Gravl | **Custom equipment** | Backlog | Features | N/A | No version/date yet. | Yes |
| **116** | Gravl | **Garmin Connect** | Backlog | Integrations | N/A | No version/date yet. Heavily requested across MacroFactor comments; MacroFactor #51 marked it Won't Do. | Yes |
| **117** | Gravl | **Before and after pictures in Profile** | Backlog | Features | N/A | No version/date yet. | Yes |
| **118** | Gravl | **AI cardio recommendations** | Backlog | Features | N/A | No version/date yet. | Partial — cardio workout types generated; no dedicated cardio-rec engine |
