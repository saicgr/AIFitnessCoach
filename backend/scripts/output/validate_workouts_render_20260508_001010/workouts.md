# Workout Generation Validation

## #001 — easy / beginner / 15min / strength / full_gym / push [render_api]

### Parameters
- intensity: `easy`
- fitness_level: `beginner`
- duration_minutes (target): `15`
- goal: `strength`
- equipment_set: `full_gym` → ['barbell', 'dumbbells', 'cable_machine', 'squat_rack', 'bench', 'pull_up_bar', 'kettlebell', 'leg_press_machine', 'lat_pulldown', 'smith_machine']
- focus: `push`
- injuries: `[]`
- round: `1`

### ❌ ERROR
```
http_500: {"detail":"Failed to generate workout: cannot access local variable 'gym_profile' where it is not associated with a value"}
```

### Prompt sent to Gemini
```
{
  "user_id": "00000000-0000-0000-0000-0000000000aa",
  "workout_type": "easy_strength",
  "duration_minutes": 15,
  "fitness_level": "beginner",
  "goals": [
    "strength"
  ],
  "equipment": [
    "barbell",
    "dumbbells",
    "cable_machine",
    "squat_rack",
    "bench",
    "pull_up_bar",
    "kettlebell",
    "leg_press_machine",
    "lat_pulldown",
    "smith_machine"
  ],
  "focus_areas": [
    "push"
  ],
  "scheduled_date": "2026-05-11",
  "force_non_preferred_day": true,
  "skip_comeback": false
}
```

- tokens: in=0 out=0

---
## #002 — easy / beginner / 30min / hypertrophy / home_dumbbells / pull [render_api]

### Parameters
- intensity: `easy`
- fitness_level: `beginner`
- duration_minutes (target): `30`
- goal: `hypertrophy`
- equipment_set: `home_dumbbells` → ['dumbbells', 'bench', 'resistance_bands']
- focus: `pull`
- injuries: `[]`
- round: `1`

### ❌ ERROR
```
http_500: {"detail":"Failed to generate workout: cannot access local variable 'gym_profile' where it is not associated with a value"}
```

### Prompt sent to Gemini
```
{
  "user_id": "00000000-0000-0000-0000-0000000000aa",
  "workout_type": "easy_hypertrophy",
  "duration_minutes": 30,
  "fitness_level": "beginner",
  "goals": [
    "hypertrophy"
  ],
  "equipment": [
    "dumbbells",
    "bench",
    "resistance_bands"
  ],
  "focus_areas": [
    "pull"
  ],
  "scheduled_date": "2026-05-12",
  "force_non_preferred_day": true,
  "skip_comeback": false
}
```

- tokens: in=0 out=0

---
## #003 — easy / beginner / 45min / fat_loss / bodyweight / legs [render_api]

### Parameters
- intensity: `easy`
- fitness_level: `beginner`
- duration_minutes (target): `45`
- goal: `fat_loss`
- equipment_set: `bodyweight` → []
- focus: `legs`
- injuries: `[]`
- round: `1`

### Library input (pre-filtered exercises sent to Gemini)
  (none)

### AI response
- workout_name: **Taurus Bull Strength**
- type: `legs`  difficulty: `medium`
- notes: 

### Final exercises (library + AI metadata)
- count: 0, est duration: 0.0m, total volume: 0.0kg

### Safety validation
- violations: 0

### Prompt sent to Gemini
```
{
  "user_id": "00000000-0000-0000-0000-0000000000aa",
  "workout_type": "easy_fat_loss",
  "duration_minutes": 45,
  "fitness_level": "beginner",
  "goals": [
    "fat_loss"
  ],
  "equipment": [],
  "focus_areas": [
    "legs"
  ],
  "scheduled_date": "2026-05-13",
  "force_non_preferred_day": true,
  "skip_comeback": false
}
```

- tokens: in=0 out=0

---
## #004 — easy / beginner / 60min / endurance / full_gym / full_body [render_api]

### Parameters
- intensity: `easy`
- fitness_level: `beginner`
- duration_minutes (target): `60`
- goal: `endurance`
- equipment_set: `full_gym` → ['barbell', 'dumbbells', 'cable_machine', 'squat_rack', 'bench', 'pull_up_bar', 'kettlebell', 'leg_press_machine', 'lat_pulldown', 'smith_machine']
- focus: `full_body`
- injuries: `[]`
- round: `1`

### ❌ ERROR
```
http_500: {"detail":"Failed to generate workout: cannot access local variable 'gym_profile' where it is not associated with a value"}
```

### Prompt sent to Gemini
```
{
  "user_id": "00000000-0000-0000-0000-0000000000aa",
  "workout_type": "easy_endurance",
  "duration_minutes": 60,
  "fitness_level": "beginner",
  "goals": [
    "endurance"
  ],
  "equipment": [
    "barbell",
    "dumbbells",
    "cable_machine",
    "squat_rack",
    "bench",
    "pull_up_bar",
    "kettlebell",
    "leg_press_machine",
    "lat_pulldown",
    "smith_machine"
  ],
  "focus_areas": [
    "full_body"
  ],
  "scheduled_date": "2026-05-14",
  "force_non_preferred_day": true,
  "skip_comeback": false
}
```

- tokens: in=0 out=0

---
## #005 — easy / beginner / 90min / general_fitness / home_dumbbells / core [render_api]

### Parameters
- intensity: `easy`
- fitness_level: `beginner`
- duration_minutes (target): `90`
- goal: `general_fitness`
- equipment_set: `home_dumbbells` → ['dumbbells', 'bench', 'resistance_bands']
- focus: `core`
- injuries: `[]`
- round: `1`

### ❌ ERROR
```
http_500: {"detail":"Failed to generate workout: cannot access local variable 'gym_profile' where it is not associated with a value"}
```

### Prompt sent to Gemini
```
{
  "user_id": "00000000-0000-0000-0000-0000000000aa",
  "workout_type": "easy_general_fitness",
  "duration_minutes": 90,
  "fitness_level": "beginner",
  "goals": [
    "general_fitness"
  ],
  "equipment": [
    "dumbbells",
    "bench",
    "resistance_bands"
  ],
  "focus_areas": [
    "core"
  ],
  "scheduled_date": "2026-05-15",
  "force_non_preferred_day": true,
  "skip_comeback": false
}
```

- tokens: in=0 out=0

---
