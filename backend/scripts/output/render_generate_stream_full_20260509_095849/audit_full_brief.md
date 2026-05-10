# Audit brief — scripts/output/render_generate_stream_full_20260509_095849/workouts.csv

- total: 540  ok: 486  err: 54

## Error buckets

- INCOMPATIBLE_EQUIPMENT_FOCUS_422: 14
- HTTP_401_session_expired: 40

## Per-section pass/fail/warn counts

| Section | pass | warn | fail | skip |
|---|---|---|---|---|
| A_schema | 486 | 0 | 0 | 0 |
| B_param_caps | 219 | 0 | 61 | 206 |
| C_difficulty | 250 | 17 | 13 | 206 |
| D_goal | 161 | 0 | 15 | 310 |
| E_density | 435 | 11 | 40 | 0 |
| F_pattern_diversity | 9 | 0 | 477 | 0 |
| G_compound_first | 291 | 0 | 68 | 127 |
| H_injury | 0 | 0 | 0 | 486 |
| I_integrity | 479 | 0 | 7 | 0 |
| J_physio | 0 | 0 | 0 | 486 |
| K_pattern_balance | 276 | 210 | 0 | 0 |
| L_structure | 0 | 425 | 0 | 61 |
| O_equipment | 236 | 0 | 33 | 217 |
| P_user_state | 0 | 0 | 0 | 486 |
| S_streaming | 486 | 0 | 0 | 0 |
| U_locale | 486 | 0 | 0 | 0 |
| W_excludes | 5 | 0 | 1 | 480 |
| X_duration_drift | 84 | 186 | 216 | 0 |
| Y_type_focus | 1 | 0 | 68 | 417 |
| R_personalization | 3 | 483 | 0 | 0 |

## Top-5 failing rows per section

### B_param_caps (61 flagged)
- idx=1 blk=1 `dur-sweep beginner/15min` → fail: #2 reps=15>12
- idx=2 blk=1 `dur-sweep beginner/20min` → fail: #4 reps=15>12
- idx=8 blk=1 `dur-sweep beginner/90min` → fail: #1 sets=4>3
- idx=16 blk=1 `dur-sweep intermediate/90min` → fail: #1 sets=5>4
- idx=118 blk=2 `matrix beginner/20/strength/arms/E8_fw` → fail: #2 reps=15>12

### X_duration_drift (402 flagged)
- idx=1 blk=1 `dur-sweep beginner/15min` → fail: requested=15 est=22 drift=49%
- idx=2 blk=1 `dur-sweep beginner/20min` → fail: requested=20 est=34 drift=72%
- idx=5 blk=1 `dur-sweep beginner/45min` → warn: requested=45 est=32 drift=28%
- idx=6 blk=1 `dur-sweep beginner/60min` → fail: requested=60 est=33 drift=44%
- idx=7 blk=1 `dur-sweep beginner/75min` → fail: requested=75 est=34 drift=55%

### R_personalization (483 flagged)
- idx=1 blk=1 `dur-sweep beginner/15min` → warn: empty notes
- idx=2 blk=1 `dur-sweep beginner/20min` → warn: empty notes
- idx=3 blk=1 `dur-sweep beginner/30min` → warn: empty notes
- idx=4 blk=1 `dur-sweep beginner/40min` → warn: empty notes
- idx=5 blk=1 `dur-sweep beginner/45min` → warn: empty notes

### E_density (51 flagged)
- idx=2 blk=1 `dur-sweep beginner/20min` → warn: 20min/5ex ratio=4.0
- idx=10 blk=1 `dur-sweep intermediate/20min` → warn: 20min/5ex ratio=4.0
- idx=18 blk=1 `dur-sweep advanced/20min` → warn: 20min/5ex ratio=4.0
- idx=112 blk=2 `matrix beginner/15/fat_loss/pull/E2_bw` → fail: 15min/6ex (cap=4)
- idx=113 blk=2 `matrix beginner/15/general_fitness/legs/E3_db` → fail: 15min/6ex (cap=4)

### F_pattern_diversity (477 flagged)
- idx=2 blk=1 `dur-sweep beginner/20min` → fail: patterns=['hinge', 'squat'] n=2<5
- idx=3 blk=1 `dur-sweep beginner/30min` → fail: patterns=['cardio'] n=1<5
- idx=4 blk=1 `dur-sweep beginner/40min` → fail: patterns=['cardio', 'pull_horizontal'] n=2<5
- idx=5 blk=1 `dur-sweep beginner/45min` → fail: patterns=['cardio'] n=1<5
- idx=6 blk=1 `dur-sweep beginner/60min` → fail: patterns=['cardio', 'pull_horizontal'] n=2<5

### G_compound_first (68 flagged)
- idx=3 blk=1 `dur-sweep beginner/30min` → fail: first 2 are isolation: ['Burpee', 'Major Groups Muscle Body']
- idx=5 blk=1 `dur-sweep beginner/45min` → fail: first 2 are isolation: ['Burpee', 'Major Groups Muscle Body']
- idx=21 blk=1 `dur-sweep advanced/45min` → fail: first 2 are isolation: ['Burpee', 'Half Burpees']
- idx=22 blk=1 `dur-sweep advanced/60min` → fail: first 2 are isolation: ['Burpee', 'Half Burpees']
- idx=23 blk=1 `dur-sweep advanced/75min` → fail: first 2 are isolation: ['Burpee', 'Half Burpees']

### K_pattern_balance (210 flagged)
- idx=3 blk=1 `dur-sweep beginner/30min` → warn: cardio=1/1
- idx=5 blk=1 `dur-sweep beginner/45min` → warn: cardio=1/1
- idx=10 blk=1 `dur-sweep intermediate/20min` → warn: cardio=2/3
- idx=16 blk=1 `dur-sweep intermediate/90min` → warn: cardio=2/3
- idx=17 blk=1 `dur-sweep advanced/15min` → warn: cardio=2/3

### L_structure (425 flagged)
- idx=3 blk=1 `dur-sweep beginner/30min` → warn: no warmup/cooldown marker in notes
- idx=4 blk=1 `dur-sweep beginner/40min` → warn: no warmup/cooldown marker in notes
- idx=5 blk=1 `dur-sweep beginner/45min` → warn: no warmup/cooldown marker in notes
- idx=6 blk=1 `dur-sweep beginner/60min` → warn: no warmup/cooldown marker in notes
- idx=7 blk=1 `dur-sweep beginner/75min` → warn: no warmup/cooldown marker in notes

### Y_type_focus (68 flagged)
- idx=45 blk=1 `focus-sweep cardio` → fail: focus=cardio → expected type∈['cardio', 'hiit'], got strength
- idx=46 blk=1 `focus-sweep mobility` → fail: focus=mobility → expected type∈['mobility'], got strength
- idx=87 blk=1 `goal×focus fat_loss/cardio` → fail: focus=cardio → expected type∈['cardio', 'hiit'], got strength
- idx=89 blk=1 `goal×focus endurance/cardio` → fail: focus=cardio → expected type∈['cardio', 'hiit'], got strength
- idx=91 blk=1 `goal×focus mobility/mobility` → fail: focus=mobility → expected type∈['mobility'], got strength

### O_equipment (33 flagged)
- idx=48 blk=1 `equip-sweep E2_bw` → fail: BW-only req={'dumbbell'}: Dumbbell Kneeling Hold To Stand Clean Grip; BW-only req={'dumbbell'}: Dumbbell Swing; BW-only req={'dumbbell'}: Prone Bench Row Dumbbells
- idx=49 blk=1 `equip-sweep E3_db` → fail: need=kettlebell not in ['bench', 'dumbbells', 'resistance_bands']: Kettlebell Silverback Shrug; need=kettlebell not in ['bench', 'dumbbells', 'resistance_bands']: Kettlebell Strict Press; need=kettlebell not in ['bench', 'dumbbells', 'resistance_bands']: Kettlebell Windmill
- idx=50 blk=1 `equip-sweep E4_kb` → fail: need=dumbbell not in ['kettlebell']: Dumbbell Standing Overhead Press; need=dumbbell not in ['kettlebell']: Dumbbell Bench Seated Press
- idx=52 blk=1 `equip-sweep E6_bands` → fail: need=dumbbell not in ['resistance_bands']: Dumbbell Lunge To Overhead Press; need=kettlebell not in ['resistance_bands']: Kettlebell Snatch; need=kettlebell not in ['resistance_bands']: Kettlebell Sumo Deadlift With High Pull
- idx=53 blk=1 `equip-sweep E7_no_bb` → fail: need=barbell not in ['bench', 'cable_machine', 'dumbbells', 'kettlebell', 'lat_pulldown', 'pull_up_bar', 'resistance_bands']: Barbell Bench Squats

### I_integrity (7 flagged)
- idx=56 blk=1 `equip-sweep E10_home` → fail: dup triple: ('squat', 'quadriceps (quadriceps femoris)', 'dumbbell')
- idx=116 blk=2 `matrix beginner/20/power/upper/E6_bands` → fail: dup triple: ('squat', 'quadriceps (quadriceps femoris)', 'dumbbell')
- idx=176 blk=2 `matrix advanced/15/power/upper/E10_home` → fail: dup triple: ('squat', 'quadriceps (quadriceps femoris)', 'dumbbell')
- idx=236 blk=3 `custom_program: Train for HYROX in 12 weeks — week 4` → fail: dup triple: ('squat', 'quadriceps (quadriceps femoris)', 'dumbbell')
- idx=296 blk=5 `wt=hypertrophy/focus=full_body` → fail: dup triple: ('squat', 'quadriceps (quadriceps femoris)', 'dumbbell')

### D_goal (15 flagged)
- idx=111 blk=2 `matrix beginner/15/strength/push/E1_full` → fail: strength but all reps>10
- idx=118 blk=2 `matrix beginner/20/strength/arms/E8_fw` → fail: strength but all reps>10
- idx=120 blk=2 `matrix beginner/30/strength/glutes/E10_home` → fail: strength but all reps>10
- idx=158 blk=2 `matrix intermediate/40/strength/mobility/E6_bands` → fail: strength but all reps>10
- idx=171 blk=2 `matrix intermediate/90/strength/push/E5_mach` → fail: strength but all reps>10

### C_difficulty (30 flagged)
- idx=119 blk=2 `matrix beginner/30/weight_loss/shoulders/E9_db1` → fail: beginner→hard
- idx=136 blk=2 `matrix beginner/75/power/pull/E12_bw_bands` → fail: beginner→hard
- idx=137 blk=2 `matrix beginner/75/weight_loss/legs/E13_TRX` → fail: beginner→hard
- idx=138 blk=2 `matrix beginner/75/strength/full_body/E14_gym_60` → fail: beginner→hard
- idx=139 blk=2 `matrix beginner/90/weight_loss/core/E1_full` → fail: beginner→hard

### W_excludes (1 flagged)
- idx=248 blk=3 `exclude=burpee,jump squat,box jump` → fail: excluded leak: Burpee
