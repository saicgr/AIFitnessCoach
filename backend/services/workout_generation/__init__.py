"""
Workout-generation helpers that are NOT part of the AI-Gemini pipeline.

Today this package contains only `template_player.py`, which materializes a
workout_program_templates row into a concrete GeneratedWorkoutResponse.
When the daily-workout endpoint runs it asks the template_player first —
if the user has an active imported creator program, that program drives the
workout. Only when there is no active template does the AI generator run.
"""
