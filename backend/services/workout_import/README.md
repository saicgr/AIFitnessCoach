# workout_import — Developer Guide

End-to-end pipeline that ingests workout data exported from every major fitness
app, creator program, and generic spreadsheet, normalizes it into a canonical
schema, resolves exercise names against our library, dedupes against existing
rows, writes to Supabase, and indexes into ChromaDB for the chat coach.

## Pipeline

```
POST /workout-history/import/file
         │
         ▼
  media_analysis_jobs row (job_type=workout_history_import)
         │
         ▼
  media_job_runner ─── async task ──► WorkoutHistoryImporter.run(job)
                                            │
                                            ├─ detect(bytes, filename)
                                            │      → DetectionResult(source_app, mode)
                                            │
                                            ├─ _load_adapter(source_app)
                                            │      → services.workout_import.adapters.<slug>
                                            │     OR services.workout_import.programs.<slug>
                                            │
                                            ├─ adapter.parse(data, ...)
                                            │      → ParseResult(strength_rows, cardio_rows, template)
                                            │
                                            ├─ ExerciseResolver (4-level cascade)
                                            │     1. 200+ alias dict
                                            │     2. exact match on exercise_library
                                            │     3. ExerciseRAGService semantic
                                            │     4. unresolved → surface in bulk-remap sheet
                                            │
                                            ├─ bulk upsert(workout_history_imports / cardio_logs)
                                            │     dedup via (user_id, source_row_hash) unique index
                                            │
                                            └─ index_strength_sessions / index_cardio_sessions
                                                   → ChromaDB user_exercise_history / user_cardio_history
```

## Adapter contract

Every adapter (app + creator) exports exactly one entry point:

```python
async def parse(
    *,
    data: bytes,               # full file bytes; caller already downloaded from S3
    filename: str,             # for heuristics + error messages
    user_id: UUID,
    unit_hint: str,            # 'kg' | 'lb' — used when source doesn't encode units
    tz_hint: str,              # IANA timezone for naive timestamps
    mode_hint: ImportMode,     # from the detector; adapter may override
) -> ParseResult:
    ...
```

Return shape:

```python
ParseResult(
    mode=ImportMode.HISTORY | ImportMode.CARDIO_ONLY | ImportMode.TEMPLATE | ...,
    source_app="hevy",                 # fine-grained slug; matches DB source_app column
    strength_rows=[CanonicalSetRow(...), ...],
    cardio_rows=[CanonicalCardioRow(...), ...],
    template=CanonicalProgramTemplate(...) | None,
    unresolved_exercise_names=["foo", "bar"],  # optional; usually empty — resolver runs later
    warnings=["..."],
    sample_rows_for_preview=[dict, dict, ...],  # first 20 rows for preview sheet
)
```

The adapter does **not** touch the DB, resolver, or RAG — those are orchestrator concerns. This keeps adapters pure-functional and testable with in-memory fixtures.

## Adding a new source_app adapter

1. Pick a slug (e.g. `"zwift"`) and add it to `format_detector.py` fingerprints (`_CSV_FINGERPRINTS` for CSVs, `_SHEET_FINGERPRINTS` for spreadsheets).
2. Create `services/workout_import/adapters/zwift.py` exporting `async def parse(...)`.
3. Reuse helpers from `adapters/_common.py` (encoding sniff, dateparser wrapper, weight/reps parsers).
4. For creator programs: put the file in `services/workout_import/programs/` instead, and add the slug to the `is_creator` set in `service.py::_load_adapter`.
5. Fixture at `tests/fixtures/workout_imports/zwift_sample.csv` + test at `tests/services/workout_import/adapters/test_zwift.py`.

Slugs that already route correctly: see `service.py::_load_adapter`.

## Growing the alias dictionary

`exercise_resolver.py::EXERCISE_ALIASES` currently has 214 entries covering the top exercises across Hevy / Strong / Fitbod / Jefit / FitNotes and the major creator programs. Every unresolved name a user remaps via the bulk-remap sheet is logged to `exercise_alias_contributions`; when the same raw→canonical mapping shows up from ≥10 distinct users, it auto-promotes into this dict (offline review + PR).

Keys must be **fully normalized** via `_normalize()` — lowercase, punctuation stripped, whitespace collapsed, emoji removed, trailing parentheticals stripped. Values are canonical slugs that match `exercise_library.exercise_name` after the same slug transform.

## Template vs history routing

`TemplateClassifier` in `format_detector.py` scores a spreadsheet on 13 signals and returns a score in [0, 1]:

- `score >= 0.65` → `ImportMode.TEMPLATE`  (blank Nippard/RP/Wendler-style prescription)
- `score <= 0.35` → `ImportMode.HISTORY`  (filled-in log)
- in between → `ImportMode.AMBIGUOUS`  (preview sheet asks the user to pick)

Signals: date fill ratio, weight fill ratio, formula density, single-1RM-input cell, protected cells, tab names (week/day vs dates), static-vs-monotonic weight progression, prescription-style vs reflection-style notes, copyright header, etc. Weights are tuned on the fixture corpus.

## CLI debugging

```bash
# Classify without dispatching to an adapter
python -m scripts.workout_import_cli --file tests/fixtures/workout_imports/hevy_sample.csv --classify-only

# Full dry-run with first 5 parsed rows
python -m scripts.workout_import_cli --file /path/to/export.csv --verbose

# Inspect what landed in RAG
python -m scripts.inspect_rag_collections \
    --collection user_exercise_history \
    --user-id 00000000-0000-0000-0000-000000000001 \
    --query "what was my best bench press?"
```

## Test fixtures

Anonymized, ≤1 MB each, checked in at `backend/tests/fixtures/workout_imports/`. Generators (for binary formats like Garmin FIT) live next to their fixtures. Adding a new fixture:

1. Anonymize: scrub PII (names, emails, timestamps too specific to identify someone).
2. Trim: 3-5 representative rows per format; full files bloat the repo.
3. Per-app quirk in the fixture name: `hevy_sample_superset.csv`, `strong_sample_dropset.csv`, etc.
4. One test per fixture asserting: row count, source_app matches, at least one weight_kg > 0, tz-aware performed_at, 64-char source_row_hash, plus any app-specific invariant (Hevy's superset_id preserved, Strong's "1h 12m" Duration string parsed to 4320 seconds, etc.).

## Gotchas

- **Python 3.9 vs 3.11 conftest clash** — the project-wide `tests/conftest.py` loads `core/exceptions.py` which uses `str | None` (3.10+). Use `--confcutdir=tests/services/workout_import` when running in the shipped venv.
- **Supabase PostgREST row cap** — default 1000/query. The library cache loader in the resolver paginates via `.range(offset, offset + 999)` — don't revert to a bare `.limit(N)` call.
- **ChromaDB upsert** — the HTTP v2 client doesn't support true upsert; `rag_indexer.py` does `delete(ids=...); add(ids=...)` as a pair, tolerating the pre-delete miss on first write.
- **timezone-naive datetimes** — the canonical models reject them outright. Every adapter must attach a tz via `dateparser`'s `RETURN_AS_TIMEZONE_AWARE` flag or an explicit `replace(tzinfo=...)`.
- **Weight unit ambiguity** — Strong/Jefit/Boostcamp exports DO NOT encode the user's weight unit. The `unit_hint` parameter is authoritative for these. Never default to kg in an adapter; always thread through the parameter.
