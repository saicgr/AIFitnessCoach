"""
Workout-import pipeline.

Ingests historical workout + cardio data and creator program templates from
fitness-app exports (Hevy, Strong, Fitbod, Jefit, FitNotes, Gravitus,
Boostcamp, MyFitnessPal, Garmin FIT, Apple Health XML, Strava, Peloton,
Nike Run Club, Fitbit) and creator programs (Jeff Nippard, Renaissance
Periodization, Greg Nuckols SBS, Wendler 5/3/1, nSuns, GZCLP,
Metallicadpa PPL, Starting Strength, StrongLifts, Meg Squats Uplifted,
Lyle McDonald, Built With Science, BUFF Dudes, Athlean-X, generic
spreadsheet templates).

Normalizes everything to CanonicalSetRow / CanonicalCardioRow /
CanonicalProgramTemplate, resolves exercise names to the library,
dedupes via source_row_hash, and writes to Supabase + ChromaDB.

Public entry points:
  - WorkoutHistoryImporter.run(job)   — orchestrator for async jobs
  - parse_file(...)                    — sync classify + normalize (no writes)
  - index_session_to_rag(...)          — upsert a (user, exercise, date) doc
"""
