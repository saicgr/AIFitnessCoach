# In-use exercise name reachability — resolution pass (2026-07-30)

Source: `python scripts/audit_exercise_name_reachability.py --workout-sample 1200`.

At the moment this task was picked up the audit reported **55 distinct
unresolvable in-use names (320 occurrences)**. Two things moved the baseline
before any work here happened:

1. **4 names resolved themselves organically** during investigation, because
   the concurrent illustration-generation pass (task "B6: Generate 125 missing
   exercise illustrations") was landing images in real time: `Bench Bulgarian
   Split Squats`, `Baithak (hindu Squat)`, `Suspension Trainer With Grips Wide
   Grip Inverted Row On Floor`, `Kabaddi Squat Jumps`. All four already had an
   exact-match `exercise_canonical` row and a correct self-alias
   (migration 2391) — they were only missing `exercise_demos` media, which
   landed mid-audit. **Real baseline for this task: 51 distinct names, 295
   occurrences.**
2. After migration 2394 (below) was applied, the count dropped to **39
   distinct names, 222 occurrences** — exactly the 12 names in Bucket A below,
   confirming no other name accidentally changed status.

## Method

For every unresolvable name: looked up candidates in `exercise_canonical`
(name/equipment/body_part/target_muscle/is_unilateral), and cross-checked
against `exercise_library_cleaned` (the richer, noisier, NOT-media-backed
source most curated-program generators actually draw names from — see
`scripts/match_exercises.py`, which exports it to
`exercise_library_lookup.json`/`exercise_names.txt` "for use by program
generation agents"). `exercise_library_cleaned` was the deciding evidence for
several calls below — it gave real equipment/target-muscle data that the name
string alone couldn't, and in a few cases **overturned an initial name-based
guess** (see "Corrections" below).

Classification followed the brief exactly: **A** = same movement (alias),
**B** = genuinely new (needs a new canonical + illustration, out of scope),
**C** = data-quality artifact (fix at the source, never alias to a real
exercise). When evidence was ambiguous, the name was kept in **B**, never
force-fit into A.

## Bucket A — aliased, migration `2394_inuse_exercise_name_aliases.sql` (11 core + 1 bonus)

All verified to resolve **with real media** after applying the migration
(`resolve_exercise_demo_media_batch`, checked individually below).

| In-use name | → Canonical | Evidence |
|---|---|---|
| Seated Row Machine Rows | Seated Row Machine (`443fc883…`) | Redundant plural "Rows" suffix on an exact name match. |
| The Wall Ball | Wall Ball (`2360d23e…`) | "The" article prefix only. |
| Triceps Rope | Triceps rope extension on crossover machine (`b8b7c779…`) | `exercise_library_cleaned` has the exact full name `Triceps Rope Extension On Crossover Machine` (Cable Machine, Triceps) for this same in-use name — confirms it's shorthand, not a different exercise. |
| Ankle Cars | Ankle Circles (`278fc36b…`) | CARS (Controlled Articular Rotations) at the ankle *is* a full circular ROM drill — same movement as "Ankle Circles". Target overlap: library lists `calves` for Ankle Cars; canonical Ankle Circles targets `Anterior Tibialis + Calves` (superset, consistent). |
| Calf Push Stretch with Hands Against Wall V.2 | Calf stretch with hands against wall (`b27a4840…`) | Same target muscle (Calves, Gastrocnemius/Soleus) in both `exercise_library_cleaned` entries for "V.2" and the base version; same wall-press stretch position. "Push"/"V.2" reads as a content-versioning suffix, not a different stretch. |
| Horizontal Leg Press | Leg press machine normal stance (`94a1483e…`) | `exercise_library_cleaned` confirms equipment = `Leg Press Machine` exactly, target Quadriceps/Glutes. No 45°/incline leg-press machine exists anywhere in this catalog to confuse it with — every canonical leg-press variant (`normal/close/wide-high stance`) is the same horizontal sled machine, so "Horizontal Leg Press" (no stance qualifier) maps to the default/normal-stance entry. |
| Horizontal Leg Press Calf Raise | Leg Press Calf Raise (`3c0c5744…`) | Same machine/target reasoning as above; Calves target matches exactly. |
| Horizontal Leg Press Calf Raise Single-Leg | Single leg calf raise leg press machine (`f084a829…`) | Same machine, unilateral flag matches (`is_unilateral=true` on both sides). **Bonus row** — this canonical had no media at classification time; it resolved anyway by the time the migration was verified (illustration pipeline landed it concurrently), so it's folded into the same migration rather than filed separately. |
| Kettlebell Sled Drag | Sled Pull (`0cc2ed40…`) | `exercise_library_cleaned` equipment = `Sled` (not "kettlebell" as an apparatus — the kettlebell is the load stacked on the sled). Target Hamstrings/Glutes matches Sled Pull's Hamstrings/Glutes/Back. |
| Heavy Bag Sled Drag | Sled Pull (`0cc2ed40…`) | Same correction as above — library equipment = `Sled`, not "heavy bag" as a distinct apparatus (initial name-only read guessed differently; overturned, see Corrections). Target Hamstrings/Glutes matches. |
| Single Kettlebell Sled Push | Sled Push (`2fed6718…`) | Library equipment = `Sled`, target Quadriceps/Glutes matches Sled Push's Quadriceps/Glutes/Calves. |
| 5K Run | Running (`80951e3d…`) | "5K" is a distance parameter on the same running gait/movement, not a different movement — same reasoning class as the plural/prefix cases above. |

Verification (`resolve_exercise_demo_media_batch` post-migration): all 12
resolve with `image_s3_path` populated; video is present for `5K Run`,
`Ankle Cars`, `Calf Push Stretch…`, `Horizontal Leg Press`, `Horizontal Leg
Press Calf Raise Single-Leg` and absent (image-only) for the rest — that's an
existing-media property of the target canonical, not something this migration
controls.

### Corrections made during research

Two calls were **reversed** after cross-checking `exercise_library_cleaned`
instead of trusting the name string alone — flagged here because they're a
useful caution for future passes:

- **Heavy Bag Sled Drag**: name suggested "heavy bag" was the apparatus
  (different equipment than a sled). Library data showed the recorded
  equipment is `Sled` — the heavy bag is the load, not the apparatus. Moved
  A instead of B.
- **Ankle Dorsiflexion Stretch**: initially looked like a safe alias to
  canonical's "Ankle - Dorsal Flexion". Library showed `Ankle Dorsiflexion
  Stretch` targets **Calves** (a passive stretch — you stretch the calf by
  holding ankle dorsiflexion), while canonical's "Ankle - Dorsal Flexion"
  targets **Anterior Tibialis** (an active strengthening drill for the
  opposing muscle). Opposite target muscle despite near-identical name — kept
  in Bucket B, not aliased.
- **Mountain Climber Jumps**: initially looked like a tempo variant of plain
  "Mountain Climber" (same target, abs/obliques). Library showed the recorded
  target is **Quadriceps/Glutes**, not abs — a materially different muscle
  emphasis. Kept in Bucket B.

## Bucket B — genuinely new, needs a new canonical + illustration (33 names, out of scope)

No exercise_canonical equivalent exists with matching equipment/target/body
position, or the one candidate with matching identity has no media and no
media-backed alternative was found without risking a wrong-identity alias.

| Name | Occ. | Why not aliased |
|---|---|---|
| Active Hang | 51 | Library: equipment `Pull-Up Bar`, target `lats`. Closest candidate ("Dead hang stretch") targets Lower Back/Lats/Shoulders broadly and reads as a passive stretch, not an active lat-engaged hang — different exercise intent. |
| Dumbbell Lying on Floor Chest Press | 36 | Bilateral (both arms) dumbbell floor press. Catalog only has the **unilateral** "Dumbbell One/Single Arm Floor Press" variants and a barbell (different equipment) floor press — no bilateral 2-dumbbell floor press exists. |
| Long Lever Plank | 25 | Extended-arm plank variant (harder lever). No canonical plank variant encodes hand/arm position this way; "High plank"/"Plank on elbows" are the standard positions, not the long-lever variant. |
| Mountain Climber Jumps | 18 | See Corrections above — target mismatch (Quads/Glutes vs Abs) rules out aliasing to "Mountain Climber". |
| Plate Good Morning | 13 | Equipment `Weight Plate` (library-confirmed) — no plate-loaded good morning exists; catalog only has barbell/dumbbell/kettlebell/bodyweight/band variants. |
| Landmine Squat and Press | 12 | Combo movement (squat + press in one landmine rep). Catalog has squat-only and press-only landmine entries, never combined. |
| Landmine Rotational Lift To Press | 6 | Same as above — combo movement, no combined entry in the Landmine cluster. |
| Lawnmower Row | 6 | Library: equipment `Cable Machine` (a diagonal low-cable pull), distinct from the library's own separate `Dumbbell Knee Lawnmower Row` entry (Dumbbells) — the library itself keeps these as two different exercises. No cable "lawnmower-style" row exists in canonical (only generic cable bent-over/seated rows). |
| Treadmill Walking Lunge | 4 | Library: equipment `Treadmill`, body_part `cardio` — a distinct equipment context; no plain bodyweight or treadmill-context walking lunge exists in canonical (only dumbbell/sandbag-loaded variants). |
| Chin-Up Grip Hang | 3 | Library: target `biceps` specifically (chin/underhand grip emphasis). Canonical's "Dead hang stretch" targets Back/Lats/Shoulders, not biceps — different muscle emphasis, different grip purpose. |
| Single-Leg Curl | 3 | Explicit example in the brief: unilateral vs bilateral leg curl are NOT the same. No unilateral leg-curl-machine entry has media. |
| Triangle Pose (Trikonasana) | 3 | Yoga asana. Only unrelated candidate found ("Bodyweight standing triangle fly" — a chest/shoulder fly, not a stretch pose). No equivalent. |
| Overhead Med Ball Throw | 3 | A full-body overhead throw. Candidates found ("Medicine Ball Chest Pass", "Hold the world med ball…") are chest-level passes or isometric holds — different trajectory/mechanics. |
| Suspension Trainer with Grips Inverted Row on floor | 2 | The *regular-grip* floor variant. Its target-muscle match in canonical ("Suspension Trainer with Grips Inverted Row" — Posterior Deltoids + Lats) has no media; the only media-backed candidate is the **Wide Grip** version, which library/canonical data shows a different target emphasis (Trapezius/Rhomboids instead of Posterior Deltoids) — grip width changes target muscle here, so not aliased. |
| Med Ball Slam Burpees | 2 | Combo movement (burpee + med ball slam). No combined entry exists; only standalone "Ball Slams" and "Burpee" variants. |
| Lateral Plank Walk | 1 | Distinct lateral-traveling plank movement (library: target Core+Shoulders). No canonical equivalent — Bear Crawl candidates move forward, not laterally in a plank. |
| Single-Leg Hamstring Stretch | 1 | Library keeps this as a **separate entry** from "Seated Single-Leg Hamstring Stretch" (different equipment: Bodyweight vs Yoga Mat) — the library itself treats standing/lying vs seated as different stretches. No media-backed match for the non-seated version. |
| Pike Hold | 1 | Library: equipment `bodyweight` (no apparatus). Canonical's only pike candidate ("Suspension Trainer with Grips Pike") requires a Suspension Trainer — different equipment. |
| Plate Deadlift | 1 | Equipment `Weight Plate` (library-confirmed) — no plate-loaded deadlift exists; catalog only has barbell/dumbbell/kettlebell/sandbag/trap-bar/band deadlifts. |
| Ankle Dorsiflexion Stretch | 1 | See Corrections above — opposite target muscle from the only candidate. |
| Unilateral Jumps | 1 | No single-leg/unilateral jump entry exists anywhere in canonical (0 candidates found). |
| Landmine Single Arm Push Press | 1 | Push press (leg-drive assisted) is mechanically distinct from a strict press; the closest candidate ("Landmine Alternating Single Arm Press") has no media regardless. |
| Pike Jacks Feet Kicking In And Out | 1 | No confident match; closest candidate ("Plank jack") has no media and a possibly different hip-elevation starting position (pike vs flat plank). |
| TRX Body-Up | 1 | No confident match found in canonical for this specific movement. |
| Prone Cobra | 1 | An active back-extensor exercise (limbs lifted off the ground), mechanically different from the passive "Cobra Stretch"/"Cobra yoga pose hold" (hips stay grounded, upper body pressed up by the arms). |
| Med Ball Jumping Jacks | 1 | Loaded variant (Medicine Ball equipment, library-confirmed) of the equipment-free "Jumping jack" — different equipment, not aliased. |
| Tyre Hammering | 1 | Genuinely ambiguous between the two real candidates — "Tire Sledgehammer Overhead Slams" (target: core) and "Tire Sledgehammer Side Slams" (target: obliques). No way to tell which without the source specifying overhead/side; per the brief, ambiguous stays unaliased. |
| Bodyweight Inverted Rows | 1 | Apparatus-ambiguous: candidates are Suspension-Trainer-specific or Smith-Machine-specific; no plain-bar/rings inverted row with media exists. |
| Flowing Inchworm to Cobra | 1 | A flow/combo movement (Inchworm transitioning into Cobra), not equal to standalone "Inchworm". |
| Rhythmic Lateral Lunges | 1 | Not present in `exercise_library_cleaned` at all — no independent equipment/target evidence beyond name similarity to "Lateral Lunge". Per the brief, name-only similarity isn't sufficient evidence; left unaliased. |
| Bear Crawl to Pike | 1 | Flow/combo movement (Bear Crawl transitioning into Pike), not equal to standalone "Bear Crawl". |
| Windmill Reaches | 1 | Not present in `exercise_library_cleaned` either — same insufficient-evidence reasoning as Rhythmic Lateral Lunges re: "Bodyweight windmill". |
| Zone 2 Bike | 1 | Equipment ambiguous — could be a regular stationary bike or an air/fan bike (which also engages the arms); the name doesn't disambiguate and the two are meaningfully different equipment. |

## Bucket C — data-quality artifacts, fix at the source (6 names)

None of these were aliased to a real exercise, per the brief's explicit rule.

| Name | Occ. | Evidence & source |
|---|---|---|
| Rowing Machine Intervals | 7 | Hardcoded literally, **with the author explicitly marking `"in_library": False`**, in curated-program generator scripts: `scripts/generate_metabolic_conditioning.py:62,168`, `scripts/generate_hiit_burner.py:97`, `scripts/gen_batch_bodyweight_endurance.py`, `scripts/generate_shred_program.py:198`, `scripts/batch_6_lifestyle.py:49`, `scripts/generate_fat_loss_remaining.py:274`, `scripts/gen_fat_loss_med_priority.py:88`, `scripts/generate_cut_and_maintain.py:62`. This is a cardio **protocol** description ("1 min hard/1 min easy × 5"), not a single movement — the original authors already knew it wasn't library-backed. Fix: either point these entries at the real "Gym Rowing Machine Fast/Normal/Sprint Speed" canonical rows as an approximation, or (better) stop writing a synthetic exercise name for protocol-based cardio blocks and render them with a dedicated interval-protocol UI treatment instead of an image-lookup. |
| Jump Rope Row White Screen | 3 | Stored verbatim (name **and** original_name) in `exercise_library_cleaned`, id `526397cf-0ad0-494b-8a9f-3cdf5a035cb4` — "white screen" is a leftover video-production background descriptor baked into the name at `exercise_library` import time, upstream of `scripts/match_exercises.py:52-56` (which just reads the view verbatim). The real exercise is "Jump Rope row" (already resolvable). Fix: correct/strip the malformed `exercise_library` row, or filter names containing production-artifact terms ("white screen", "green screen", etc.) before `match_exercises.py` exports the generation palette (`exercise_library_lookup.json`/`exercise_names.txt`). |
| Low rotational med ball chops (quarter squat, rotating med ball left and ride across core) | 1 | Same class as above — stored verbatim in `exercise_library_cleaned`, id `0037b81b-9108-495b-979f-e989f98d6fc8`: a full instructional sentence baked into the name field itself. Same fix path (clean the `exercise_library` row / filter parenthetical-instruction names before export). |
| Warrior Ii | 3 | Two stacked issues. (1) **Casing corruption at the source**: `exercise_library_cleaned` stores the name as `Warrior Ii` (id `a60402bc-9381-4785-8a08-9981954f3c8d`), not `Warrior II` — almost certainly a historical `.title()`-style transform applied when `exercise_library` was originally seeded (`"warrior ii".title() == "Warrior Ii"`); no currently-running code applies `.title()` to this data (`scripts/match_exercises.py` reads the view verbatim), so the bad casing is baked into the stored row, not reintroduced downstream. Correctly-cased "Warrior II" is used consistently elsewhere in the codebase (`scripts/exercise_lib.py:570`, `scripts/gen_batch_yoga_pilates.py:28`, and 6+ other `gen_batch_*.py` files). (2) Even fixing the casing doesn't resolve it: **no `exercise_canonical` bridge exists at all** for this pose — the only Warrior-family canonical row is "Reverse Warrior (Viparita Virabhadrasana)", a different pose (torso leans back, one arm reaches down) — so this is *also* effectively Bucket B (needs a new canonical + illustration) once the name is fixed. Not aliased either way. |
| Yoga | 2 | A workout/session-type **category** label, not a specific pose — and not present anywhere in `exercise_library_cleaned` either (every real entry there is a specific named pose, e.g. "Butterfly Yoga Pose"). No single deterministic generator file found; most likely a free-text LLM (`ai`/`rag_first` generation_method, per the audit's breakdown) emitting a category word into an individual exercise-name slot instead of a specific pose. Fix: constrain the warmup/stretch/cooldown generation prompt or schema to reject generic category words in the per-exercise name field. |
| Cat Nap | 1 | Not found anywhere — not in `exercise_library_cleaned`, not in any generator script. "Cat nap" isn't a real fitness-pose term; most likely a whimsical LLM-generated label for a brief rest/recovery beat in a stretch/cooldown block. Same fix direction as "Yoga" — constrain the generation prompt/schema to a controlled pose vocabulary rather than free-generating names. |

## Before / after

| | Distinct unresolvable | Occurrences |
|---|---|---|
| At task start (raw audit) | 55 | 320 |
| After 4 names resolved organically by concurrent illustration work | 51 | 295 |
| After migration 2394 (this task) | **39** | **222** |

The drop from 51 → 39 is exactly the 12 names in Bucket A (11 that resolved
immediately + the 1 bonus row, which also ended up resolving by verification
time thanks to the concurrent illustration pipeline). The remaining 39 =
33 Bucket B (genuinely new exercises, need illustrations — feed into the
missing-illustration pipeline) + 6 Bucket C (fix at the generator/data source,
listed above with file:line evidence where a source was traceable).

## 2026-07-31 pass — E2E register #122/#126/#127, scoped to the PUBLISHED PROGRAM SCHEDULE

Different measurement surface than the pass above: that one audited the exercise
*catalogue* + recent workout *logs*. This one audits every exercise occurrence in
`program_variant_weeks.workouts[].exercises[]` across all 45 published programs /
1,624 variants / 177,318 occurrences — the Schedule tab a user sees before ever
starting a workout — via the new standing gate,
`scripts/audit_program_exercise_media_resolution.py`, which replicates the app's
real 4-tier resolver (`api/v1/program_templates.py`) tier for tier: position match
→ name+week fallback → name-only fallback → by-id fallback.

| Stage | Missing occurrences | Distinct names | Programs affected |
|---|---|---|---|
| E2E register baseline (2026-07-30) | 20,332 | 263 | 31 of 45 |
| After migration 2391 applied (canonical self-alias backfill, #127) + migration 2395 (`exercise_name`-first resolver fix, #126) | 1,633 | 77 | 14 of 45 |
| After migration 2396 (4 hand-verified aliases, below) | **1,039** | **73** | 14 of 45 |

Migrations 2391 + 2395 alone cleared **94.9%** of the register baseline — almost
entirely #127 (the self-alias backfill; 1,612 canonical rows got their own name
registered) and #126 (the view was silently normalizing the display name instead
of the library-matched name for every position-matched lookup).

### Migration 2396 — the 4 names still worth aliasing at this volume

All confirmed same-movement (word-order / one-arm↔single-arm / pace-qualifier
variants), all confirmed to carry real `exercise_demos` media before aliasing —
see the migration file for full per-row evidence:

| In-use name | Occ. | → Canonical | Why safe |
|---|---|---|---|
| Romanian Deadlift Barbell | 470 | Barbell romanian deadlift | Word-order variant; equipment (Barbell) + target (Hamstrings, Glutes) match exactly. |
| Dumbbell Single-Arm Lateral Raise | 83 | Dumbbell One Arm Lateral Raise | "single-arm"/"one-arm" synonym (same class as 2394's Sled Drag rows); equipment + target (Shoulders/Lateral Deltoids) match exactly. |
| Dumbbell Single-Arm Snatch | 24 | Dumbbell One Arm Snatch | Same synonym pair; 3-muscle target list matches exactly. |
| Treadmill Tempo Run | 17 | Treadmill Running | "Tempo" is a pacing instruction on the same gait, same reasoning as 2394's "5K Run" → "Running"; equipment + target match exactly. |

### What's left (1,039 occurrences / 73 names / 14 programs) — not aliased, and why

Investigated every name above ~10 occurrences individually (pg_trgm similarity
against `exercise_canonical`, cross-checked equipment/target_muscle against
`exercise_library_cleaned`); the long single-digit tail was triaged by pattern.
None of the following got a Bucket-A alias:

* **Already-known Bucket B from the pass above** — Treadmill Walking Lunge (338
  occ) and Dumbbell Lying On Floor Chest Press (80 occ). No matching-equipment
  canonical exists (Treadmill Walking Lunge: no plain/treadmill-context walking
  lunge in canonical, only dumbbell/sandbag-loaded; Dumbbell Lying On Floor
  Chest Press: only unilateral floor-press variants exist). Unchanged.
* **The 91-exercise library→canonical bridging gap** (~74 occ) — Warrior II,
  Pyramid Pose, Triangle Pose, Goddess Pose (yoga poses) and Thoracic Extension
  Stretch, Thoracic Rotation Quadruped (~118 occ combined with the poses).
  `exercise_library_cleaned` has every one of these with a real name/equipment/
  target — some even have an `image_url` of their own — but **no
  `exercise_canonical` row exists to alias onto**. This is not an alias gap;
  it's the documented bridging gap
  ([[project_program_variants_and_schedule_media]]). "Warrior Ii" specifically
  is already tracked as Bucket C above (casing corruption at the source) and
  independently confirmed to have zero canonical bridge even once fixed.
  Fixing this class needs `scripts/bridge_library_exercises_to_canonical.py`
  extended to create canonical rows (+ exercise_demos rows pointing at
  `exercise_library_cleaned.image_url` where one exists) — a data-authoring
  task, not a migration.
* **Media genuinely missing, not a resolution bug** — Back Extension Machine
  (12 occ). Already has a `canonical_self` alias (migration 2391) and a real
  S3 *video*, but no *image*. No alias fixes a missing asset; feed into the
  illustration-generation backlog.
* **Movement/equipment difference material enough to withhold** — Banded
  Clamshell (8 occ, equipment differs: `resistance band` vs canonical
  Clamshell's bodyweight — the image would misrepresent the load, same caution
  class as the doc's "Single-Leg Curl" example above), Spiderman Lunge With
  Reach (6 occ, the "reach" adds a thoracic-rotation component the base
  "Spiderman Lunge" canonical row doesn't target), Kneeling Plank (34 occ, no
  plausible canonical candidate — "Plank Knee Tucks"/"Plank cross knee drive"
  are dynamic knee-drive exercises, not a static on-knees plank regression).
* **Rowing Machine Intervals** (11 occ here vs 7 in the pass above — more
  occurrences surfaced because this pass scans the full published-program
  schedule, not a workout-log sample) — already Bucket C, same generator-level
  cardio-protocol issue documented above, not re-litigated.
* **Session-type labels, not exercises** (~10 occ total: Deep Breathing,
  Meditation, Complete Rest, Hydration, Sleep, Nutrition, Mobility, Stretching,
  Yoga, Light Stretching) — stored in the same `exercises[]` array shape as real
  movements on recovery-day sessions. Whether the Schedule UI should attempt
  image resolution for these at all is a product call, not a data fix; flagged
  here rather than aliased to something misleading.
* **Long single-digit tail** (~380 occ across ~50 remaining names, 1-9
  occurrences each) — spot-checked a representative sample against the same
  evidence standard; all fell into one of the buckets above (bridging gap,
  equipment/movement mismatch, or no plausible candidate). Not enumerated
  individually here for space; re-run
  `scripts/audit_program_exercise_media_resolution.py` (no flags) for the full
  current list with occurrence counts.

### Negative-tested regression gate

`scripts/audit_program_exercise_media_resolution.py` — baseline-diff, same
convention as `audit_exercise_naming.py`. `--check` exits 1 only on NEW
findings vs `audit_program_exercise_media_resolution_baseline.json` (refreshed
to 1,039 accepted findings at the end of this pass). Verified to actually
fail: temporarily deleted the "Barbell romanian deadlift" self-alias, re-ran
`--check`, confirmed a NEW finding for "Romanian Deadlift Barbell" (470
occurrences) appeared and the script exited 1; restored the alias; re-ran
`--check`, confirmed a clean pass (0 NEW) again.
