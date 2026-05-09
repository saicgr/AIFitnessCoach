# /api/v1/workouts/{workout_id}/regenerate-stream — 500 Validation Scenarios

**Endpoint:** `POST /api/v1/workouts/regenerate-stream` (SSE streaming, RAG-first)  
**Body:** `WorkoutRegenerateRequest` (workout_id required + ~25 optional fields)  
**Surface:** "Regenerate" sheet on home carousel — replaces an existing workout in-place.  
**Injury coverage:** 140/500 (28.0%) ≥ 25% target ✓  
**Cost per call:** ~$0.0015 (Gemini 2.5 Flash). 500 calls ≈ $0.75  
**Wall time:** ~120 min sequential (with 13s pacing for rate-limit headroom)  

## Block layout

| Block | Theme | Count | Injury rows |
|---|---|---|---|
| 1 | Difficulty intent (easy/medium/hard/hell) | 20 | 0 |
| 2 | Duration adjustment (15-90 min) | 15 | 0 |
| 3 | Equipment swap | 15 | 0 |
| 4 | Focus pivot | 15 | 0 |
| 5 | AI prompt overrides (curated) | 15 | 1 |
| 6 | Reschedule force_non_preferred_day | 10 | 0 |
| 7 | Injury injection during regen | 5 | 5 |
| 8 | Composite + extreme + max payload | 5 | 1 |
| 9 | Goal × Difficulty × Fitness-level grid | 50 | 0 |
| 10 | Equipment-restriction edges | 50 | 0 |
| 11 | Injury × Equipment combo matrix | 50 | 50 |
| 12 | AI prompt edge cases | 30 | 0 |
| 13 | Special populations | 50 | 3 |
| 14 | Reschedule × force × difficulty matrix (trimmed) | 20 | 0 |
| 15 | workout_name + preserve_history + fitness_level | 50 | 0 |
| 16 | Variety regression (same source same body, trimmed) | 20 | 0 |
| 17 | Dedicated injury sweep (8 joints × focus × duration) | 80 | 80 |
| **Total** | | **500** | **140 (28.0%)** |

## Live Run Status

_(populated per-call by harness)_

## All 500 scenarios

| idx | block | label | body fields | inj? |
|---|---|---|---|---|
| 1 | 1 | diff=easy | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 2 | 1 | diff=medium | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 3 | 1 | diff=hard | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 4 | 1 | diff=hell | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 5 | 1 | diff=easy | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 6 | 1 | diff=medium | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 7 | 1 | diff=hard | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 8 | 1 | diff=hell | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 9 | 1 | diff=easy | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 10 | 1 | diff=medium | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 11 | 1 | diff=hard | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 12 | 1 | diff=hell | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 13 | 1 | diff=easy | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 14 | 1 | diff=medium | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 15 | 1 | diff=hard | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 16 | 1 | diff=hell | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 17 | 1 | diff=easy | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 18 | 1 | diff=medium | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 19 | 1 | diff=hard | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 20 | 1 | diff=hell | difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 21 | 2 | duration=15 | difficulty, duration_minutes, user_id, workout_id |  |
| 22 | 2 | duration=20 | difficulty, duration_minutes, user_id, workout_id |  |
| 23 | 2 | duration=25 | difficulty, duration_minutes, user_id, workout_id |  |
| 24 | 2 | duration=30 | difficulty, duration_minutes, user_id, workout_id |  |
| 25 | 2 | duration=45 | difficulty, duration_minutes, user_id, workout_id |  |
| 26 | 2 | duration=60 | difficulty, duration_minutes, user_id, workout_id |  |
| 27 | 2 | duration=75 | difficulty, duration_minutes, user_id, workout_id |  |
| 28 | 2 | duration=90 | difficulty, duration_minutes, user_id, workout_id |  |
| 29 | 2 | duration=75 | difficulty, duration_minutes, user_id, workout_id |  |
| 30 | 2 | duration=90 | difficulty, duration_minutes, user_id, workout_id |  |
| 31 | 2 | duration=15 | difficulty, duration_minutes, user_id, workout_id |  |
| 32 | 2 | duration=90 | difficulty, duration_minutes, user_id, workout_id |  |
| 33 | 2 | duration=30 | difficulty, duration_minutes, user_id, workout_id |  |
| 34 | 2 | duration=60 | difficulty, duration_minutes, user_id, workout_id |  |
| 35 | 2 | duration=45 | difficulty, duration_minutes, user_id, workout_id |  |
| 36 | 3 | equip=bodyweight | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 37 | 3 | equip=bodyweight | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 38 | 3 | equip=dumbbells+bench | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 39 | 3 | equip=dumbbells | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 40 | 3 | equip=kettlebell | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 41 | 3 | equip=kettlebell | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 42 | 3 | equip=cable_machine+leg_press_machine | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 43 | 3 | equip=resistance_bands | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 44 | 3 | equip=treadmill | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 45 | 3 | equip=dumbbells+pull_up_bar | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 46 | 3 | equip=barbell+dumbbells | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 47 | 3 | equip=resistance_bands | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 48 | 3 | equip=barbell+squat_rack+bench | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 49 | 3 | equip=bodyweight | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 50 | 3 | equip=dumbbells+kettlebell | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 51 | 4 | focus=pull | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 52 | 4 | focus=upper | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 53 | 4 | focus=cardio | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 54 | 4 | focus=mobility | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 55 | 4 | focus=HIIT | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 56 | 4 | focus=push | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 57 | 4 | focus=legs | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 58 | 4 | focus=core | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 59 | 4 | focus=arms | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 60 | 4 | focus=shoulders | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 61 | 4 | focus=cardio | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 62 | 4 | focus=core | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 63 | 4 | focus=glutes | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 64 | 4 | focus=upper | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 65 | 4 | focus=full_body | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 66 | 5 | ai_prompt='make it more compound-focused, fewer iso...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 67 | 5 | ai_prompt='no jumping or impact today, my knees hur...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 68 | 5 | ai_prompt='more cardio please, I want to sweat...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 69 | 5 | ai_prompt='shorter rest periods between sets, like ...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 70 | 5 | ai_prompt='longer rest, 2-3 min, I'm trying to lift...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 71 | 5 | ai_prompt='include 5 minutes of warmup specific to ...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 72 | 5 | ai_prompt='no barbell exercises today...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 73 | 5 | ai_prompt='make it a pyramid set structure (10-8-6-...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 74 | 5 | ai_prompt='I want supersets and giant sets, push in...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 75 | 5 | ai_prompt='easy day, foam rolling and stretching on...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 76 | 5 | ai_prompt='I'm pregnant, second trimester — adjust ...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 77 | 5 | ai_prompt='post-injury return-to-running phase 2...' | ai_prompt, duration_minutes, user_id, workout_id | ✓ |
| 78 | 5 | ai_prompt='12 weeks out from a powerlifting meet — ...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 79 | 5 | ai_prompt='menstrual cycle day 2, please de-escalat...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 80 | 5 | ai_prompt='fasted training, low energy, keep it und...' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 81 | 6 | today + force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 82 | 6 | today force #2 | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 83 | 6 | today force #3 | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 84 | 6 | +7d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 85 | 6 | +14d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 86 | 6 | +1d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 87 | 6 | +3d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 88 | 6 | +5d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 89 | 6 | +30d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 90 | 6 | +60d force | duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 91 | 7 | injuries=knee/focus=legs | difficulty, duration_minutes, focus_areas, injuries, user_id, workout_id | ✓ |
| 92 | 7 | injuries=shoulder/focus=push | difficulty, duration_minutes, focus_areas, injuries, user_id, workout_id | ✓ |
| 93 | 7 | injuries=lower_back/focus=pull | difficulty, duration_minutes, focus_areas, injuries, user_id, workout_id | ✓ |
| 94 | 7 | injuries=knee,shoulder,wrist/focus=full_body | difficulty, duration_minutes, focus_areas, injuries, user_id, workout_id | ✓ |
| 95 | 7 | injuries=knee,shoulder,lower_back,wrist,ankle,hip,elbow/focus=core | difficulty, duration_minutes, focus_areas, injuries, user_id, workout_id | ✓ |
| 96 | 8 | same source variety #1 | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 97 | 8 | same source variety #2 | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 98 | 8 | same source variety #3 | difficulty, duration_minutes, focus_areas, user_id, workout_id |  |
| 99 | 8 | max payload | ai_prompt, difficulty, dumbbell_count, duration_minutes, equipment, fitness_level, +6 more | ✓ |
| 100 | 8 | minimal payload | user_id, workout_id |  |
| 101 | 9 | goal=strength/diff=easy/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 102 | 9 | goal=hypertrophy/diff=medium/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 103 | 9 | goal=endurance/diff=hard/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 104 | 9 | goal=power/diff=hell/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 105 | 9 | goal=fat_loss/diff=easy/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 106 | 9 | goal=strength/diff=medium/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 107 | 9 | goal=hypertrophy/diff=hard/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 108 | 9 | goal=endurance/diff=hell/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 109 | 9 | goal=power/diff=easy/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 110 | 9 | goal=fat_loss/diff=medium/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 111 | 9 | goal=strength/diff=hard/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 112 | 9 | goal=hypertrophy/diff=hell/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 113 | 9 | goal=endurance/diff=easy/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 114 | 9 | goal=power/diff=medium/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 115 | 9 | goal=fat_loss/diff=hard/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 116 | 9 | goal=strength/diff=hell/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 117 | 9 | goal=hypertrophy/diff=easy/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 118 | 9 | goal=endurance/diff=medium/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 119 | 9 | goal=power/diff=hard/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 120 | 9 | goal=fat_loss/diff=hell/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 121 | 9 | goal=strength/diff=easy/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 122 | 9 | goal=hypertrophy/diff=medium/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 123 | 9 | goal=endurance/diff=hard/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 124 | 9 | goal=power/diff=hell/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 125 | 9 | goal=fat_loss/diff=easy/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 126 | 9 | goal=strength/diff=medium/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 127 | 9 | goal=hypertrophy/diff=hard/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 128 | 9 | goal=endurance/diff=hell/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 129 | 9 | goal=power/diff=easy/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 130 | 9 | goal=fat_loss/diff=medium/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 131 | 9 | goal=strength/diff=hard/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 132 | 9 | goal=hypertrophy/diff=hell/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 133 | 9 | goal=endurance/diff=easy/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 134 | 9 | goal=power/diff=medium/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 135 | 9 | goal=fat_loss/diff=hard/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 136 | 9 | goal=strength/diff=hell/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 137 | 9 | goal=hypertrophy/diff=easy/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 138 | 9 | goal=endurance/diff=medium/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 139 | 9 | goal=power/diff=hard/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 140 | 9 | goal=fat_loss/diff=hell/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 141 | 9 | goal=strength/diff=easy/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 142 | 9 | goal=hypertrophy/diff=medium/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 143 | 9 | goal=endurance/diff=hard/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 144 | 9 | goal=power/diff=hell/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 145 | 9 | goal=fat_loss/diff=easy/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 146 | 9 | goal=strength/diff=medium/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 147 | 9 | goal=hypertrophy/diff=hard/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 148 | 9 | goal=endurance/diff=hell/fl=advanced | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 149 | 9 | goal=power/diff=easy/fl=beginner | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 150 | 9 | goal=fat_loss/diff=medium/fl=intermediate | difficulty, duration_minutes, fitness_level, goals, user_id, workout_id |  |
| 151 | 10 | equip: bodyweight only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 152 | 10 | equip: 1 dumbbell only | difficulty, dumbbell_count, duration_minutes, equipment, user_id, workout_id |  |
| 153 | 10 | equip: 1 dumbbell pair | difficulty, dumbbell_count, duration_minutes, equipment, user_id, workout_id |  |
| 154 | 10 | equip: 1 kettlebell | difficulty, duration_minutes, equipment, kettlebell_count, user_id, workout_id |  |
| 155 | 10 | equip: 2 kettlebells | difficulty, duration_minutes, equipment, kettlebell_count, user_id, workout_id |  |
| 156 | 10 | equip: machine-only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 157 | 10 | equip: smith machine only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 158 | 10 | equip: 2 machines | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 159 | 10 | equip: bands only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 160 | 10 | equip: bands + pullup | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 161 | 10 | equip: jump rope only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 162 | 10 | equip: yoga mat only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 163 | 10 | equip: treadmill only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 164 | 10 | equip: rower only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 165 | 10 | equip: assault bike only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 166 | 10 | equip: elliptical only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 167 | 10 | equip: park / pullup bar | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 168 | 10 | equip: sandbag only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 169 | 10 | equip: medicine ball only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 170 | 10 | equip: sliders only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 171 | 10 | equip: TRX only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 172 | 10 | equip: bulgarian bag | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 173 | 10 | equip: mace only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 174 | 10 | equip: home gym minimal | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 175 | 10 | equip: home gym mid | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 176 | 10 | equip: garage gym | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 177 | 10 | equip: full commercial gym | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 178 | 10 | equip: bodyweight only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 179 | 10 | equip: 1 dumbbell only | difficulty, dumbbell_count, duration_minutes, equipment, user_id, workout_id |  |
| 180 | 10 | equip: 1 dumbbell pair | difficulty, dumbbell_count, duration_minutes, equipment, user_id, workout_id |  |
| 181 | 10 | equip: 1 kettlebell | difficulty, duration_minutes, equipment, kettlebell_count, user_id, workout_id |  |
| 182 | 10 | equip: 2 kettlebells | difficulty, duration_minutes, equipment, kettlebell_count, user_id, workout_id |  |
| 183 | 10 | equip: machine-only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 184 | 10 | equip: smith machine only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 185 | 10 | equip: 2 machines | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 186 | 10 | equip: bands only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 187 | 10 | equip: bands + pullup | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 188 | 10 | equip: jump rope only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 189 | 10 | equip: yoga mat only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 190 | 10 | equip: treadmill only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 191 | 10 | equip: rower only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 192 | 10 | equip: assault bike only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 193 | 10 | equip: elliptical only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 194 | 10 | equip: park / pullup bar | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 195 | 10 | equip: sandbag only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 196 | 10 | equip: medicine ball only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 197 | 10 | equip: sliders only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 198 | 10 | equip: TRX only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 199 | 10 | equip: bulgarian bag | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 200 | 10 | equip: mace only | difficulty, duration_minutes, equipment, user_id, workout_id |  |
| 201 | 11 | inj=knee eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 202 | 11 | inj=knee eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 203 | 11 | inj=shoulder eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 204 | 11 | inj=shoulder eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 205 | 11 | inj=lower_back eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 206 | 11 | inj=lower_back eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 207 | 11 | inj=elbow eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 208 | 11 | inj=elbow eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 209 | 11 | inj=wrist eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 210 | 11 | inj=wrist eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 211 | 11 | inj=hip eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 212 | 11 | inj=hip eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 213 | 11 | inj=ankle eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 214 | 11 | inj=ankle eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 215 | 11 | inj=neck eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 216 | 11 | inj=neck eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 217 | 11 | inj=knee eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 218 | 11 | inj=knee eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 219 | 11 | inj=knee eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 220 | 11 | inj=shoulder eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 221 | 11 | inj=shoulder eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 222 | 11 | inj=shoulder eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 223 | 11 | inj=lower_back eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 224 | 11 | inj=lower_back eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 225 | 11 | inj=lower_back eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 226 | 11 | inj=elbow eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 227 | 11 | inj=elbow eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 228 | 11 | inj=elbow eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 229 | 11 | inj=wrist eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 230 | 11 | inj=wrist eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 231 | 11 | inj=wrist eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 232 | 11 | inj=hip eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 233 | 11 | inj=hip eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 234 | 11 | inj=hip eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 235 | 11 | inj=ankle eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 236 | 11 | inj=ankle eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 237 | 11 | inj=ankle eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 238 | 11 | inj=neck eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 239 | 11 | inj=neck eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 240 | 11 | inj=neck eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 241 | 11 | inj=knee+shoulder eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 242 | 11 | inj=lower_back+knee eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 243 | 11 | inj=wrist+elbow+shoulder eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 244 | 11 | inj=hip+knee+ankle eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 245 | 11 | inj=knee+shoulder eq=resistance_bands | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 246 | 11 | inj=lower_back+knee eq=cable_machine+leg_press_machine | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 247 | 11 | inj=wrist+elbow+shoulder eq=BW | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 248 | 11 | inj=hip+knee+ankle eq=dumbbells | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 249 | 11 | inj=knee+shoulder eq=barbell+bench | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 250 | 11 | inj=lower_back+knee eq=kettlebell | difficulty, duration_minutes, equipment, injuries, user_id, workout_id | ✓ |
| 251 | 12 | ai='I want a workout that focuses on hypertr' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 252 | 12 | ai='Hazlo más difícil, por favor' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 253 | 12 | ai='もっとハードにしてください' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 254 | 12 | ai='更加挑战性的训练' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 255 | 12 | ai='Сделайте тренировку сложнее' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 256 | 12 | ai='एक चुनौतीपूर्ण कसरत बनाएं' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 257 | 12 | ai='make it harder but easier on my joints' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 258 | 12 | ai='more cardio but no impact' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 259 | 12 | ai='pure strength but high reps' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 260 | 12 | ai='shorter workout but more exercises' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 261 | 12 | ai="I'm fasted, last meal 18 hours ago" | ai_prompt, duration_minutes, user_id, workout_id |  |
| 262 | 12 | ai='post-workout, I have a heavy meal in 30 ' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 263 | 12 | ai='keto for 6 months, glycogen low' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 264 | 12 | ai='DOMS in legs, day 2 after heavy squats' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 265 | 12 | ai='slept 4 hours last night' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 266 | 12 | ai='feeling great, want to push it' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 267 | 12 | ai='minor cold, congestion, low energy' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 268 | 12 | ai='back from 2-week vacation, deconditioned' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 269 | 12 | ai='only have 15 minutes before a meeting' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 270 | 12 | ai='have 90 minutes — go full intensity' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 271 | 12 | ai='double session, this is workout 2 of 2 t' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 272 | 12 | ai="I'm 65 years old, joint-friendly please" | ai_prompt, duration_minutes, user_id, workout_id |  |
| 273 | 12 | ai="I'm 14, just started lifting, learn-the-" | ai_prompt, duration_minutes, user_id, workout_id |  |
| 274 | 12 | ai="I'm 6 months post-partum, gentle progres" | ai_prompt, duration_minutes, user_id, workout_id |  |
| 275 | 12 | ai="I'm pregnant first trimester, no supine " | ai_prompt, duration_minutes, user_id, workout_id |  |
| 276 | 12 | ai='training for a 5K in 8 weeks' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 277 | 12 | ai='training for a powerlifting meet in 12 w' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 278 | 12 | ai='training for an obstacle course race' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 279 | 12 | ai='training for a marathon — long run is to' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 280 | 12 | ai='feeling stressed, want to release tensio' | ai_prompt, duration_minutes, user_id, workout_id |  |
| 281 | 13 | pop: senior beginner | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 282 | 13 | pop: senior intermediate | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 283 | 13 | pop: senior advanced | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 284 | 13 | pop: senior frail | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 285 | 13 | pop: teen 14 | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 286 | 13 | pop: teen 16 | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 287 | 13 | pop: teen 17 | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 288 | 13 | pop: pregnant T1 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 289 | 13 | pop: pregnant T2 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 290 | 13 | pop: pregnant T3 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 291 | 13 | pop: postpartum 6w | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 292 | 13 | pop: postpartum 12w | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 293 | 13 | pop: postpartum 6mo | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 294 | 13 | pop: seated wheelchair | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 295 | 13 | pop: amputee BK | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 296 | 13 | pop: MS mild | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 297 | 13 | pop: Parkinson's mild | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 298 | 13 | pop: Diabetes T2 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 299 | 13 | pop: hypertension | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 300 | 13 | pop: RTS week 1 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 301 | 13 | pop: RTS week 6 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 302 | 13 | pop: post-COVID | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 303 | 13 | pop: luteal phase | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 304 | 13 | pop: ovulation peak | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 305 | 13 | pop: menstrual day 1 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 306 | 13 | pop: bariatric postop | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 307 | 13 | pop: competitive cut | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 308 | 13 | pop: offseason bulk | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 309 | 13 | pop: phase 1 PT | ai_prompt, difficulty, duration_minutes, injuries, user_id, workout_id | ✓ |
| 310 | 13 | pop: phase 2 PT | ai_prompt, difficulty, duration_minutes, injuries, user_id, workout_id | ✓ |
| 311 | 13 | pop: phase 3 PT | ai_prompt, difficulty, duration_minutes, injuries, user_id, workout_id | ✓ |
| 312 | 13 | pop: night shift worker | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 313 | 13 | pop: jet-lagged | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 314 | 13 | pop: masters 50+ | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 315 | 13 | pop: masters 60+ | ai_prompt, difficulty, duration_minutes, fitness_level, user_id, workout_id |  |
| 316 | 13 | pop: blind | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 317 | 13 | pop: hearing impaired | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 318 | 13 | pop: fibromyalgia | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 319 | 13 | pop: chronic LBP | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 320 | 13 | pop: RA mild | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 321 | 13 | pop: post-MI 6mo | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 322 | 13 | pop: AFib controlled | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 323 | 13 | pop: depression | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 324 | 13 | pop: anxiety | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 325 | 13 | pop: ED recovery | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 326 | 13 | pop: kid 8 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 327 | 13 | pop: kid 11 | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 328 | 13 | pop: stroke recovery | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 329 | 13 | pop: prehab knee | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 330 | 13 | pop: prehab back | ai_prompt, difficulty, duration_minutes, user_id, workout_id |  |
| 331 | 14 | resched=-1d force=True diff=easy | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 332 | 14 | resched=+0d force=False diff=medium | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 333 | 14 | resched=+1d force=True diff=hard | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 334 | 14 | resched=+2d force=False diff=hell | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 335 | 14 | resched=+3d force=True diff=easy | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 336 | 14 | resched=+5d force=False diff=medium | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 337 | 14 | resched=+7d force=True diff=hard | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 338 | 14 | resched=+10d force=False diff=hell | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 339 | 14 | resched=+14d force=True diff=easy | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 340 | 14 | resched=+21d force=False diff=medium | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 341 | 14 | resched=+30d force=True diff=hard | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 342 | 14 | resched=+45d force=False diff=hell | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 343 | 14 | resched=+60d force=True diff=easy | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 344 | 14 | resched=+90d force=False diff=medium | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 345 | 14 | resched=+120d force=True diff=hard | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 346 | 14 | resched=-1d force=False diff=hell | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 347 | 14 | resched=+0d force=True diff=easy | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 348 | 14 | resched=+1d force=False diff=medium | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 349 | 14 | resched=+2d force=True diff=hard | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 350 | 14 | resched=+3d force=False diff=hell | difficulty, duration_minutes, force_non_preferred_day, new_scheduled_date, user_id, workout_id |  |
| 351 | 15 | name='Phoenix Rising' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 352 | 15 | name='Iron Forge' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 353 | 15 | name='Steel Resolve' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 354 | 15 | name='Apex Hunt' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 355 | 15 | name='Quantum Lift' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 356 | 15 | name='Solar Flare' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 357 | 15 | name='Tidal Force' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 358 | 15 | name='Granite Will' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 359 | 15 | name='Velvet Hammer' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 360 | 15 | name='Crimson Dawn' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 361 | 15 | name='Eclipse Protocol' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 362 | 15 | name='Zenith Push' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 363 | 15 | name='Inferno Block' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 364 | 15 | name='Avalanche Set' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 365 | 15 | name='Tempest Surge' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 366 | 15 | name='Nebula Climb' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 367 | 15 | name='Vortex Crush' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 368 | 15 | name='Lightning Round' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 369 | 15 | name='Glacier Mass' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 370 | 15 | name='Ember Burn' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 371 | 15 | name='' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 372 | 15 | name=' ' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 373 | 15 | name='xxxxxxxxxxxxxxxxxxxx' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 374 | 15 | name='Workout 🔥' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 375 | 15 | name='Léger' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 376 | 15 | name='ベンチデー' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 377 | 15 | name='VERY LONG NAME WITH ' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 378 | 15 | name='name w/ sp3c!al ch@r' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 379 | 15 | name='tabs\there' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 380 | 15 | name='Phoenix Rising' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 381 | 15 | name='Iron Forge' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 382 | 15 | name='Steel Resolve' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 383 | 15 | name='Apex Hunt' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 384 | 15 | name='Quantum Lift' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 385 | 15 | name='Solar Flare' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 386 | 15 | name='Tidal Force' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 387 | 15 | name='Granite Will' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 388 | 15 | name='Velvet Hammer' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 389 | 15 | name='Crimson Dawn' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 390 | 15 | name='Eclipse Protocol' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 391 | 15 | name='Zenith Push' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 392 | 15 | name='Inferno Block' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 393 | 15 | name='Avalanche Set' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 394 | 15 | name='Tempest Surge' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 395 | 15 | name='Nebula Climb' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 396 | 15 | name='Vortex Crush' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 397 | 15 | name='Lightning Round' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 398 | 15 | name='Glacier Mass' preserve=False fl=advanced | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 399 | 15 | name='Ember Burn' preserve=True fl=beginner | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 400 | 15 | name='' preserve=False fl=intermediate | difficulty, duration_minutes, fitness_level, preserve_history, user_id, workout_id, +1 more |  |
| 401 | 16 | variety #1/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 402 | 16 | variety #2/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 403 | 16 | variety #3/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 404 | 16 | variety #4/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 405 | 16 | variety #5/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 406 | 16 | variety #6/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 407 | 16 | variety #7/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 408 | 16 | variety #8/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 409 | 16 | variety #9/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 410 | 16 | variety #10/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 411 | 16 | variety #11/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 412 | 16 | variety #12/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 413 | 16 | variety #13/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 414 | 16 | variety #14/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 415 | 16 | variety #15/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 416 | 16 | variety #16/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 417 | 16 | variety #17/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 418 | 16 | variety #18/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 419 | 16 | variety #19/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 420 | 16 | variety #20/20 same source same body | difficulty, duration_minutes, fitness_level, focus_areas, user_id, workout_id |  |
| 421 | 17 | inj=knee foc=full_body diff=easy dur=30 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 422 | 17 | inj=knee foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 423 | 17 | inj=knee foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 424 | 17 | inj=knee foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 425 | 17 | inj=knee foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 426 | 17 | inj=knee foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 427 | 17 | inj=shoulder foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 428 | 17 | inj=shoulder foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 429 | 17 | inj=shoulder foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 430 | 17 | inj=shoulder foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 431 | 17 | inj=shoulder foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 432 | 17 | inj=shoulder foc=mobility diff=hard dur=45 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 433 | 17 | inj=lower_back foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 434 | 17 | inj=lower_back foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 435 | 17 | inj=lower_back foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 436 | 17 | inj=lower_back foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 437 | 17 | inj=lower_back foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 438 | 17 | inj=lower_back foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 439 | 17 | inj=elbow foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 440 | 17 | inj=elbow foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 441 | 17 | inj=elbow foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 442 | 17 | inj=elbow foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 443 | 17 | inj=elbow foc=cardio diff=medium dur=45 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 444 | 17 | inj=elbow foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 445 | 17 | inj=wrist foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 446 | 17 | inj=wrist foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 447 | 17 | inj=wrist foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 448 | 17 | inj=wrist foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 449 | 17 | inj=wrist foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 450 | 17 | inj=wrist foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 451 | 17 | inj=hip foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 452 | 17 | inj=hip foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 453 | 17 | inj=hip foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 454 | 17 | inj=hip foc=core diff=easy dur=30 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 455 | 17 | inj=hip foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 456 | 17 | inj=hip foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 457 | 17 | inj=ankle foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 458 | 17 | inj=ankle foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 459 | 17 | inj=ankle foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 460 | 17 | inj=ankle foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 461 | 17 | inj=ankle foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 462 | 17 | inj=ankle foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 463 | 17 | inj=neck foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 464 | 17 | inj=neck foc=upper diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 465 | 17 | inj=neck foc=lower diff=hard dur=45 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 466 | 17 | inj=neck foc=core diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 467 | 17 | inj=neck foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 468 | 17 | inj=neck foc=mobility diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 469 | 17 | inj=knee+shoulder foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 470 | 17 | inj=knee+shoulder foc=lower diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 471 | 17 | inj=knee+shoulder foc=cardio diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 472 | 17 | inj=knee+shoulder foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 473 | 17 | inj=knee+lower_back foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 474 | 17 | inj=knee+lower_back foc=full_body diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 475 | 17 | inj=knee+lower_back foc=lower diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 476 | 17 | inj=knee+lower_back foc=cardio diff=medium dur=45 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 477 | 17 | inj=shoulder+wrist foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 478 | 17 | inj=shoulder+wrist foc=cardio diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 479 | 17 | inj=shoulder+wrist foc=full_body diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 480 | 17 | inj=shoulder+wrist foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 481 | 17 | inj=shoulder+elbow foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 482 | 17 | inj=shoulder+elbow foc=lower diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 483 | 17 | inj=shoulder+elbow foc=cardio diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 484 | 17 | inj=shoulder+elbow foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 485 | 17 | inj=lower_back+hip foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 486 | 17 | inj=lower_back+hip foc=full_body diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 487 | 17 | inj=lower_back+hip foc=lower diff=easy dur=30 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 488 | 17 | inj=lower_back+hip foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 489 | 17 | inj=knee+ankle foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 490 | 17 | inj=knee+ankle foc=cardio diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 491 | 17 | inj=knee+ankle foc=full_body diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 492 | 17 | inj=knee+ankle foc=lower diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 493 | 17 | inj=wrist+elbow+shoulder foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 494 | 17 | inj=wrist+elbow+shoulder foc=lower diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 495 | 17 | inj=wrist+elbow+shoulder foc=cardio diff=hard dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 496 | 17 | inj=wrist+elbow+shoulder foc=full_body diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 497 | 17 | inj=knee+hip+ankle foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 498 | 17 | inj=knee+hip+ankle foc=full_body diff=hard dur=45 | difficulty, duration_minutes, equipment, fitness_level, focus_areas, injuries, +2 more | ✓ |
| 499 | 17 | inj=knee+hip+ankle foc=lower diff=easy dur=30 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
| 500 | 17 | inj=knee+hip+ankle foc=cardio diff=medium dur=45 | ai_prompt, difficulty, duration_minutes, equipment, fitness_level, focus_areas, +3 more | ✓ |
