# Validation Harness — Run Commands

All commands run from `/Users/saichetangrandhe/AIFitnessCoach/backend/` unless noted.

## Full validation pass

| # | Endpoint / surface | Command | Scenarios | Injury cov. | Wall time | AI calls | Est. cost |
|---|---|---|---|---|---|---|---|
| 1 | Local Dart `QuickWorkoutEngine` | `cd /Users/saichetangrandhe/AIFitnessCoach/mobile/flutter && flutter test test/services/quick_workout_engine_validation_test.dart` | 1,137 | **22.4%** | ~19 sec | 0 | **$0.00** |
| 2 | `/quick-regenerate` (program reset) | `.venv/bin/python scripts/run_quick_regenerate_validation.py` | 1,000 | **~40%** (Block 16 reasons) | ~50 min | 0 | **$0.00** |
| 3 | `/suggest-substitutes` (similar exercise) | `.venv/bin/python scripts/run_suggest_substitutes_validation.py` | 1,000 | **67.1%** | ~7 min | 0 | **$0.00** |
| 4 | `/generate` (carousel bg-gen, RAG-first) | `.venv/bin/python scripts/run_generate_full.py` | 500 | **25.8%** | ~125 min | 500 Gemini | **~$0.75** | DONE
| 5 | `/regenerate-stream` (regen sheet) | `.venv/bin/python scripts/run_regenerate_stream_full.py` | 500 | **28.0%** | ~120 min | 500 Gemini | **~$0.75** |
| 6 | `/generate-stream` (carousel active) | `.venv/bin/python scripts/run_generate_stream_full.py` | 500 | **25.8%** | ~140 min | 500 Gemini | **~$0.75** |
| **TOTAL** | All 6 surfaces, sequential | (chain with `&&`) | **4,500** | **≥25% all** ✓ | **~7.0 hrs** | **1,500 Gemini** | **~$2.25** |

## Quick smoke test (5 calls each, 8 min, ~$0.04)

```bash
cd /Users/saichetangrandhe/AIFitnessCoach/backend
.venv/bin/python scripts/run_quick_regenerate_validation.py --n 5 && \
.venv/bin/python scripts/run_suggest_substitutes_validation.py --n 5 && \
.venv/bin/python scripts/run_generate_full.py --n 5 && \
.venv/bin/python scripts/run_regenerate_stream_full.py --n 5 && \
.venv/bin/python scripts/run_generate_stream_full.py --n 5
```

| Smoke | Scenarios | Time | Cost |
|---|---|---|---|
| All 5 backend smokes | 25 | ~5 min | ~$0.04 |
| Plus Dart local | 1,000 | ~18 sec | $0.00 |

## Sequential full pass (recommended)

```bash
cd /Users/saichetangrandhe/AIFitnessCoach/backend

.venv/bin/python scripts/run_quick_regenerate_validation.py && \
.venv/bin/python scripts/run_suggest_substitutes_validation.py && \
.venv/bin/python scripts/run_generate_full.py && \
.venv/bin/python scripts/run_regenerate_stream_full.py && \
.venv/bin/python scripts/run_generate_stream_full.py

# Total: ~3.7 hrs, ~$1.08

# Plus, in another terminal:
cd /Users/saichetangrandhe/AIFitnessCoach/mobile/flutter
flutter test test/services/quick_workout_engine_validation_test.dart
```

## Resume after kill (no re-run cost for completed scenarios)

```bash
.venv/bin/python scripts/run_generate_stream_full.py --resume auto
.venv/bin/python scripts/run_generate_full.py --resume auto
.venv/bin/python scripts/run_regenerate_stream_full.py --resume auto
```

`--resume auto` finds the most recent matching run dir and skips scenarios whose JSON dump already exists.

## Parallel runs (multiple terminals)

| Setup | Wall time | Caveats |
|---|---|---|
| All 6 sequential | ~3.7 hrs | Cleanest |
| 3 terminals: #4 + #5 + #6 in parallel | ~140 min (= `/generate-stream` alone) | Same user → hits 15/min Gemini rate-limit; expect 429 retries (auto-retry handles them, adds ~5 min) |
| #1 (Dart) + #2 + #3 in parallel | <15 min | All non-AI, safe |

**Don't run 3 AI streams in parallel against the same user** — they share the per-user 15/min Gemini rate limit and project-level Vertex RPM. Either stagger by ~2 min or use different test users.

## Watch progress live

```bash
# Latest run dirs:
ls -lat backend/scripts/output/ | head

# Tail the harness console (when run with `| tee /tmp/log`):
tail -f /tmp/log

# Watch CSV row count growing:
watch -n 2 'wc -l backend/scripts/output/render_*/workouts.csv 2>/dev/null'

# Live-status table in scenarios MD (opens in IDE, auto-updates):
backend/scripts/scenarios/generate_stream_scenarios.md
backend/scripts/scenarios/regenerate_stream_scenarios.md
```

## Output structure (post-run)

```
backend/scripts/output/render_<endpoint>_<ts>/
├── workouts.csv          ← one row per scenario, all metrics + raw_json_payload
└── (json/ — auto-deleted at end; per-call dumps folded into raw_json_payload column)
```

## Pricing reference

| Resource | Cost |
|---|---|
| Gemini 2.5 Flash | $0.075/M input tokens + $0.30/M output tokens |
| Avg AI call (~5K in + 3K out) | **~$0.0015 / call** |
| Render Pro | flat monthly, **$0 per request** |
| Supabase | free tier **$0** at these volumes |
| Claude (if you ask me to monitor live) | **+$1–3** depending on chattiness |

**Cheapest path:** run the 6 harnesses yourself in terminal (zero Claude cost), open a fresh Claude session afterward, paste me the output dirs, and I'll analyze in one shot.

## Re-run after deploying the 14+ fixes shipped today

Expected behavior changes vs the last run (`render_generate_stream_full_20260508_111252`):
- Difficulty mismatches: 2 → **0**
- Density violations: 6 → **0**
- `exclude_exercises` violations: 1 → **0**
- `adjacent_day_exercises` violations: 1 → **0**
- Duration drift > 5 min: 12 → **0**
- `workout_type=strength` dominance: 96% → **~50–60%**
- Hypertrophy properly tagged: 0/7 → **5–7/7**
- Stream stalls: 7% → **~2%** (auto-retry catches transients)
- "Taurus Iron …" naming: 60+ → **~15** (zodiac gated to 15%)
- Ordering violations (compound-after-isolation, etc.): 16 → **~0** (canonical reorder shipped)
- Stretches in non-mobility workouts: already 0 → **0** (now code-enforced)
- Punches/martial-arts in non-cardio: already 0 → **0** (now code-enforced)
- `n_exercises_with_library_id` (in `/generate-stream`): unverified → **~100%** (RAG-first now seeds library names)

Score these in the next ANALYSIS.md after the re-run.
