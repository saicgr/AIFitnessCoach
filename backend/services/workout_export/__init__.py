"""
Workout export pipeline (Zealova → Hevy / Strong / Fitbod / CSV / JSON / Parquet /
XLSX / PDF / TCX / GPX).

This package is the mirror of services.workout_import: every format the import
adapters can parse is also emitable here, so round-trips (Zealova → Hevy →
Zealova) are byte-reversible on the (exercise, weight_kg, reps, performed_at.date())
tuple. See `orchestrator.export_user_data()` for the single entry point.
"""
