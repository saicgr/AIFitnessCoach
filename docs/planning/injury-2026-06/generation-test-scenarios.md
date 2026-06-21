# Injury generation test scenarios — live Render API safety matrix

**Purpose:** measure what the LIVE deployed generator actually produces for injured
users, to drive an evidence-based safety fix (Phase 0 of the injury plan).

**How it runs:** `backend/scripts/injury_test_harness.py` hits the real Render API.
Per scenario it admin-creates a confirmed throwaway user → `/auth/sync` → sets the
profile via SQL → calls the generation endpoint **N times** (Gemini is stochastic) →
cross-checks every produced exercise against `exercise_safety_index_mat` → records the
worst verdict → deletes the user. **Rows are written here ONE BY ONE as each scenario
finishes** (resumable: a restart skips rows already recorded).

**Verdict:** `PASS` = no `<injury>_safe=FALSE` for the user's injuries + ≥ floor real
exercises · `LEAK` = ≥1 contraindicated exercise shipped · `EMPTY` = 0 exercises ·
`THIN` = ≤2 exercises · `500` = crash. Only the 8 jointed injuries have a vetted
`*_safe` column (shoulder/lower_back/knee/elbow/wrist/ankle/hip/neck); muscle-area
chips have none → their rows show the produced exercises for the Opus pass to judge.

---

## Results matrix (written live, one row per scenario as it completes)

| # | injuries | equip | lvl | goal | focus | path | leaks/runs | sample unsafe (col/pattern) | VERDICT |
|---|----------|-------|-----|------|-------|------|-----------|------------------------------|---------|
| 1 | none | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 2 | lower_back | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 3 | knees | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 4 | shoulders | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 5 | wrists | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 6 | elbows | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 7 | hips | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 8 | ankles | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 9 | neck | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 10 | upper_back | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 11 | chest | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 12 | biceps | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 13 | triceps | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 14 | forearms | full_gym | beginner | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 15 | abs | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 16 | glutes | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 17 | groin | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 18 | quads | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 19 | hamstrings | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 20 | calves | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 21 | other: carpal tunnel | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 22 | lower_back,knees,shoulders | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 23 | knees,ankles | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 24 | shoulders,wrists,elbows | full_gym | intermediate | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 25 | lower_back,hips | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 26 | knees,lower_back,wrists,shoulders | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 27 | none | bodyweight | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 28 | lower_back | bodyweight | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 29 | knees | bodyweight | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 30 | lower_back,knees | bodyweight | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 31 | shoulders | bodyweight | intermediate | build_muscle | full_body | stream | 0/1 | — | **PASS** |
| 32 | lower_back | full_gym | beginner | build_muscle | full_body_push | stream | 0/1 | — | **PASS** |
| 33 | lower_back | full_gym | beginner | build_muscle | full_body_pull | stream | 0/1 | — | **PASS** |
| 34 | lower_back | full_gym | beginner | lose_weight | legs | stream | 0/1 | — | **PASS** |
| 35 | knees | full_gym | beginner | lose_weight | legs | stream | 0/1 | — | **PASS** |
| 36 | shoulders | full_gym | intermediate | build_muscle | full_body_push | stream | 0/1 | — | **PASS** |
| 37 | lower_back | full_gym | intermediate | get_stronger | full_body | stream | 0/1 | — | **PASS** |
| 38 | lower_back | full_gym | advanced | get_stronger | full_body | stream | 0/1 | — | **PASS** |
| 39 | knees | full_gym | intermediate | get_stronger | legs | stream | 0/1 | — | **PASS** |
| 40 | lower_back | full_gym | beginner | lose_weight | full_body | RAG | 0/1 | — | **PASS** |
| 41 | knees | full_gym | beginner | lose_weight | full_body | RAG | 0/1 | — | **PASS** |
| 42 | lower_back,knees,shoulders | full_gym | beginner | lose_weight | full_body | RAG | 0/1 | — | **PASS** |
| 43 | shoulders | bodyweight | beginner | build_muscle | full_body | RAG | 0/1 | — | **PASS** |
| 44 | abs,lower_back | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 45 | hamstrings,lower_back | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |
| 46 | wrists | full_gym | beginner | build_muscle | full_body_push | stream | 0/1 | — | **PASS** |
| 47 | ankles | full_gym | beginner | lose_weight | legs | stream | 0/1 | — | **PASS** |
| 48 | neck | full_gym | intermediate | build_muscle | full_body_push | stream | 0/1 | — | **PASS** |
| 49 | hips,knees | full_gym | beginner | lose_weight | legs | stream | 0/1 | — | **PASS** |
| 50 | none | full_gym | beginner | lose_weight | full_body | stream | 0/1 | — | **PASS** |

---

## ✅ Post-fix verification (Phase 1.5 — live re-run)

The matrix above is the **AFTER-FIX** run against the deployed guard:
**50/50 PASS · 0 LEAK · 0 EMPTY · 0 500.** Down from the pre-fix baseline of
**30 LEAK / 16 PASS / 4 EMPTY** (analysis below). Every single-joint injury, every
multi-injury combo (incl. `lower_back,knees,shoulders` which was 7/7 unsafe),
bodyweight-only, all focus variants, and both the streaming and RAG paths now ship a
full, injury-safe workout. Codified gate: `backend/tests/test_injury_safety_matrix.py`.

---

## Opus analysis (Phase 0.3 — pre-fix baseline)

**Pre-fix corpus:** 50 scenarios × 2 runs vs live Render + backend logs. Corrected
tally (the harness's `"500" in r.text` substring check falsely flagged successful SSEs
whose body contained a `500` calorie/weight number — recomputed from the reliable
per-run `n_ex`/`n_leak` data):

```
LEAK 30 · PASS 16 · EMPTY 4   (0 genuine HTTP 500s — all 23 "500" were the substring bug)
LEAK:  2,3,4,5,7,8,9, 22,23,24,25,26,28,29,30,31,32,33,34,35,36,37,38,39, 44,45,46,47,48,49
PASS:  1,6,10,11,12,13,14,15,16,17,18,19,20,21,27,50
EMPTY: 40,41,42,43   (RAG path)
```

### Failure modes (evidence-grounded)

**FM-1 — `/generate-stream` had NO injury gate (headline, 30 LEAK).** Every JOINT
injury + multi-combo shipped contraindicated movements: lower_back→Barbell Deadlift /
Reverse Deadlift / Kettlebell Swing (`hinge`); knees→Goblet Reverse Lunge / Barbell
Full Squat (`squat`); shoulders→Seated Overhead Press / Close-Grip Pull-up
(`overhead_press`/`overhead_pull`); wrists/ankles/neck/hips analogous; #22 multi = 7/7
unsafe. Root cause: injuries reached neither the Gemini prompt nor any post-filter.

**FM-2 — muscle-area "PASS" was UNVERIFIED.** chest/biceps/abs/… (#10–21) showed PASS
only because the index has no `*_safe` column to check them. Handled upstream by
`avoided_muscles`; kept + verified, not regressed.

**FM-3 — RAG path collapsed injured users to ALL STRETCHES.** `fetch_safe_candidates`
returned 0 rows for a `full_body_upper` focus → empty pool → stretch backfill. Root
cause: `is_full_body` only gated the anchored branch; a `full_body_upper` focus fell
through to a literal `body_part ILIKE '%full_body_upper%'` matching ZERO rows (443
shoulder-safe / 470 knee-safe beginner non-stretch candidates exist — code, not data).

**FM-4 — RAG `.single()` 0-rows → HTTP 500.** `generation_endpoints.py` refetched the
just-updated placeholder with `.single()`; a concurrent gen deleting it → PGRST116 →
500 → stuck onboarding.

**FM-5 — FK-race 404** on placeholder insert (BG-GEN before auth_sync). Fails-soft;
monitor only. **FM-6 — AI-selector duplicate indices** thinned the pool; quality nit.

### Phase-1 fix (shipped)

1. **`services/exercise_rag/injury_guard.py::enforce_injury_safety`** — the single
   chokepoint: drop any exercise the index marks `<joint>_safe=FALSE` for an active
   injury (+ canonical name-keyword backstop for name-variant misses), REPLACE from
   `fetch_safe_candidates` cloning the survivor's set/rep structure. Fail-open.
2. **Streaming:** read injuries via `get_active_injuries_with_muscles`; inject per-injury
   movement bans into the Gemini prompt (prevention) + run the guard after
   `validate_set_targets_strict` (guarantee).
3. **RAG:** terminal guard before persist + `.single()` 500 resilience + the FM-3
   `is_full_body` fix.
