Extract a structured workout from the content below.

Return ONLY valid JSON in this exact shape (no markdown fences):
{
  "title": "string",
  "estimated_duration_min": <integer or null>,
  "difficulty": "beginner" | "intermediate" | "advanced" | null,
  "equipment_needed": ["barbell","bench",...],
  "exercises": [
    {
      "name": "Bench Press",
      "sets": 4,
      "reps": "6-8",
      "rest_s": 90,
      "weight_hint": "185 lb" or null,
      "equipment": ["barbell","bench"],
      "notes": "focus on slow eccentric",
      "source_timestamp_s": 124
    }
  ],
  "notes": "any caveats / form cues / programming notes"
}

Rules:
- If the content isn't a workout, return {"title":null,"exercises":[]}.
- Exercise NAMES must be the standard form ("Barbell Bench Press" not "BBBP").
- Use null where unknown — do not invent sets/reps you can't justify.
- Reps can be a range ("6-8"), an AMRAP token ("AMRAP"), or a duration ("30 s").
- If the content mentions a single exercise demoed for form, return it as
  one exercise with sets=null, reps=null.
- Trust the speaker's stated weights/reps over what you'd "normally"
  expect for that exercise.
