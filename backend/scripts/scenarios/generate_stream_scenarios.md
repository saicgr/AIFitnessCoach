# `/api/v1/workouts/generate-stream` — 500 Validation Scenarios

**Endpoint:** `POST https://aifitnesscoach-zqi3.onrender.com/api/v1/workouts/generate-stream`
**Surface:** Home screen carousel (initial generation, missing-day backfill)
**Scenario builder:** `backend/scripts/_scenarios_500.py:build_500()`
**Run:** `cd backend && .venv/bin/python scripts/run_generate_stream_full.py --scenario-set 500`

## Test user context

- `user_id`: `d54e6652-fdf1-4ca0-82d1-23d7c02df294` (reviewer@fitwiz.us)
- `gym_profile_id`: `0890400c-6900-4cd0-b55a-353ea1655206` (Peoria home, Tue/Thu/Sat)

## Block distribution

| Block | Theme | Count |
|---|---|---|
| 1 | Single-axis sweeps (duration / goal / focus / equipment / injury / range) | 110 |
| 2 | Fitness × intensity × duration matrix with rotating equipment | 96 |
| 3 | Comeback × custom_program × exclude × adjacent × batch_offset | 57 |
| 4 | Date variation + preferred-day gate stress | 30 |
| 5 | workout_type × focus tag matrix | 49 |
| 6 | Composite + extreme edge cases | 50 |
| 7 | Pad to 500 (rotational fill) | 108 |
| **Total** | | **500** |

## All 500 scenarios

| # | block | label | fitness | duration | focus | goals | equipment | injuries | extras |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | dur-sweep beginner/15min | beginner | 15 | full_body | - | barbell,dumbbells(+13) | - |  |
| 2 | 1 | dur-sweep beginner/20min | beginner | 20 | full_body | - | barbell,dumbbells(+13) | - |  |
| 3 | 1 | dur-sweep beginner/30min | beginner | 30 | full_body | - | barbell,dumbbells(+13) | - |  |
| 4 | 1 | dur-sweep beginner/40min | beginner | 40 | full_body | - | barbell,dumbbells(+13) | - |  |
| 5 | 1 | dur-sweep beginner/45min | beginner | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 6 | 1 | dur-sweep beginner/60min | beginner | 60 | full_body | - | barbell,dumbbells(+13) | - |  |
| 7 | 1 | dur-sweep beginner/75min | beginner | 75 | full_body | - | barbell,dumbbells(+13) | - |  |
| 8 | 1 | dur-sweep beginner/90min | beginner | 90 | full_body | - | barbell,dumbbells(+13) | - |  |
| 9 | 1 | dur-sweep intermediate/15min | intermediate | 15 | full_body | - | barbell,dumbbells(+13) | - |  |
| 10 | 1 | dur-sweep intermediate/20min | intermediate | 20 | full_body | - | barbell,dumbbells(+13) | - |  |
| 11 | 1 | dur-sweep intermediate/30min | intermediate | 30 | full_body | - | barbell,dumbbells(+13) | - |  |
| 12 | 1 | dur-sweep intermediate/40min | intermediate | 40 | full_body | - | barbell,dumbbells(+13) | - |  |
| 13 | 1 | dur-sweep intermediate/45min | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 14 | 1 | dur-sweep intermediate/60min | intermediate | 60 | full_body | - | barbell,dumbbells(+13) | - |  |
| 15 | 1 | dur-sweep intermediate/75min | intermediate | 75 | full_body | - | barbell,dumbbells(+13) | - |  |
| 16 | 1 | dur-sweep intermediate/90min | intermediate | 90 | full_body | - | barbell,dumbbells(+13) | - |  |
| 17 | 1 | dur-sweep advanced/15min | advanced | 15 | full_body | - | barbell,dumbbells(+13) | - |  |
| 18 | 1 | dur-sweep advanced/20min | advanced | 20 | full_body | - | barbell,dumbbells(+13) | - |  |
| 19 | 1 | dur-sweep advanced/30min | advanced | 30 | full_body | - | barbell,dumbbells(+13) | - |  |
| 20 | 1 | dur-sweep advanced/40min | advanced | 40 | full_body | - | barbell,dumbbells(+13) | - |  |
| 21 | 1 | dur-sweep advanced/45min | advanced | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 22 | 1 | dur-sweep advanced/60min | advanced | 60 | full_body | - | barbell,dumbbells(+13) | - |  |
| 23 | 1 | dur-sweep advanced/75min | advanced | 75 | full_body | - | barbell,dumbbells(+13) | - |  |
| 24 | 1 | dur-sweep advanced/90min | advanced | 90 | full_body | - | barbell,dumbbells(+13) | - |  |
| 25 | 1 | goal-sweep strength | intermediate | 45 | full_body | strength | barbell,dumbbells(+13) | - |  |
| 26 | 1 | goal-sweep hypertrophy | intermediate | 45 | full_body | hypertrophy | barbell,dumbbells(+13) | - |  |
| 27 | 1 | goal-sweep fat_loss | intermediate | 45 | full_body | fat_loss | barbell,dumbbells(+13) | - |  |
| 28 | 1 | goal-sweep endurance | intermediate | 45 | full_body | endurance | barbell,dumbbells(+13) | - |  |
| 29 | 1 | goal-sweep general_fitness | intermediate | 45 | full_body | general_fitness | barbell,dumbbells(+13) | - |  |
| 30 | 1 | goal-sweep mobility | intermediate | 45 | full_body | mobility | barbell,dumbbells(+13) | - |  |
| 31 | 1 | goal-sweep power | intermediate | 45 | full_body | power | barbell,dumbbells(+13) | - |  |
| 32 | 1 | goal-sweep athletic_performance | intermediate | 45 | full_body | athletic_performance | barbell,dumbbells(+13) | - |  |
| 33 | 1 | goal-sweep weight_loss | intermediate | 45 | full_body | weight_loss | barbell,dumbbells(+13) | - |  |
| 34 | 1 | goal-sweep muscle_tone | intermediate | 45 | full_body | muscle_tone | barbell,dumbbells(+13) | - |  |
| 35 | 1 | focus-sweep push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - |  |
| 36 | 1 | focus-sweep pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - |  |
| 37 | 1 | focus-sweep legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - |  |
| 38 | 1 | focus-sweep full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 39 | 1 | focus-sweep core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - |  |
| 40 | 1 | focus-sweep upper | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - |  |
| 41 | 1 | focus-sweep lower | intermediate | 45 | lower | - | barbell,dumbbells(+13) | - |  |
| 42 | 1 | focus-sweep arms | intermediate | 45 | arms | - | barbell,dumbbells(+13) | - |  |
| 43 | 1 | focus-sweep shoulders | intermediate | 45 | shoulders | - | barbell,dumbbells(+13) | - |  |
| 44 | 1 | focus-sweep glutes | intermediate | 45 | glutes | - | barbell,dumbbells(+13) | - |  |
| 45 | 1 | focus-sweep cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - |  |
| 46 | 1 | focus-sweep mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - |  |
| 47 | 1 | equip-sweep E1_full | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 48 | 1 | equip-sweep E2_bw | intermediate | 45 | full_body | - | [] | - |  |
| 49 | 1 | equip-sweep E3_db | intermediate | 45 | full_body | - | dumbbells,bench(+1) | - |  |
| 50 | 1 | equip-sweep E4_kb | intermediate | 45 | full_body | - | kettlebell | - |  |
| 51 | 1 | equip-sweep E5_mach | intermediate | 45 | full_body | - | cable_machine,leg_press_machine(+2) | - |  |
| 52 | 1 | equip-sweep E6_bands | intermediate | 45 | full_body | - | resistance_bands | - |  |
| 53 | 1 | equip-sweep E7_no_bb | intermediate | 45 | full_body | - | dumbbells,cable_machine(+5) | - |  |
| 54 | 1 | equip-sweep E8_fw | intermediate | 45 | full_body | - | barbell,dumbbells(+3) | - |  |
| 55 | 1 | equip-sweep E9_db1 | intermediate | 45 | full_body | - | dumbbells | - |  |
| 56 | 1 | equip-sweep E10_home | intermediate | 45 | full_body | - | dumbbells,resistance_bands(+1) | - |  |
| 57 | 1 | equip-sweep E11_cardio | intermediate | 45 | full_body | - | treadmill,rowing_machine(+2) | - |  |
| 58 | 1 | equip-sweep E12_bw_bands | intermediate | 45 | full_body | - | resistance_bands | - |  |
| 59 | 1 | equip-sweep E13_TRX | intermediate | 45 | full_body | - | TRX bands,resistance_bands(+1) | - |  |
| 60 | 1 | equip-sweep E14_gym_60 | intermediate | 45 | full_body | - | barbell,dumbbells(+26) | - |  |
| 61 | 1 | injury-sweep no-injury | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 62 | 1 | injury-sweep knee | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee |  |
| 63 | 1 | injury-sweep shoulder | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | shoulder |  |
| 64 | 1 | injury-sweep lower_back | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | lower_back |  |
| 65 | 1 | injury-sweep wrist | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | wrist |  |
| 66 | 1 | injury-sweep ankle | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | ankle |  |
| 67 | 1 | injury-sweep hip | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | hip |  |
| 68 | 1 | injury-sweep elbow | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | elbow |  |
| 69 | 1 | injury-sweep neck | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | neck |  |
| 70 | 1 | injury-sweep knee+shoulder | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee,shoulder |  |
| 71 | 1 | injury-sweep knee+lower_back | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee,lower_back |  |
| 72 | 1 | injury-sweep shoulder+wrist | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | shoulder,wrist |  |
| 73 | 1 | injury-sweep knee+shoulder+lower_back | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee,shoulder,lower_back |  |
| 74 | 1 | injury-sweep knee+shoulder+lower_back+wrist+ankle | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee,shoulder,lower_back,wrist,ankle |  |
| 75 | 1 | injury-sweep knee+shoulder+lower_back+wrist+ankle+hip+elbow | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 76 | 1 | dur-range 15-30 | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 15-30 |
| 77 | 1 | dur-range 20-40 | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 20-40 |
| 78 | 1 | dur-range 30-45 | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 30-45 |
| 79 | 1 | dur-range 45-60 | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 45-60 |
| 80 | 1 | dur-range 60-90 | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 60-90 |
| 81 | 1 | goal×focus strength/push | intermediate | 45 | push | strength | barbell,dumbbells(+13) | - |  |
| 82 | 1 | goal×focus strength/pull | intermediate | 45 | pull | strength | barbell,dumbbells(+13) | - |  |
| 83 | 1 | goal×focus strength/legs | intermediate | 45 | legs | strength | barbell,dumbbells(+13) | - |  |
| 84 | 1 | goal×focus hypertrophy/upper | intermediate | 45 | upper | hypertrophy | barbell,dumbbells(+13) | - |  |
| 85 | 1 | goal×focus hypertrophy/lower | intermediate | 45 | lower | hypertrophy | barbell,dumbbells(+13) | - |  |
| 86 | 1 | goal×focus hypertrophy/arms | intermediate | 45 | arms | hypertrophy | barbell,dumbbells(+13) | - |  |
| 87 | 1 | goal×focus fat_loss/cardio | intermediate | 45 | cardio | fat_loss | barbell,dumbbells(+13) | - |  |
| 88 | 1 | goal×focus fat_loss/full_body | intermediate | 45 | full_body | fat_loss | barbell,dumbbells(+13) | - |  |
| 89 | 1 | goal×focus endurance/cardio | intermediate | 45 | cardio | endurance | barbell,dumbbells(+13) | - |  |
| 90 | 1 | goal×focus endurance/lower | intermediate | 45 | lower | endurance | barbell,dumbbells(+13) | - |  |
| 91 | 1 | goal×focus mobility/mobility | intermediate | 45 | mobility | mobility | barbell,dumbbells(+13) | - |  |
| 92 | 1 | goal×focus mobility/core | intermediate | 45 | core | mobility | barbell,dumbbells(+13) | - |  |
| 93 | 1 | goal×focus power/legs | intermediate | 45 | legs | power | barbell,dumbbells(+13) | - |  |
| 94 | 1 | goal×focus power/full_body | intermediate | 45 | full_body | power | barbell,dumbbells(+13) | - |  |
| 95 | 1 | goal×focus athletic_performance/full_body | intermediate | 45 | full_body | athletic_performance | barbell,dumbbells(+13) | - |  |
| 96 | 1 | goal×focus athletic_performance/lower | intermediate | 45 | lower | athletic_performance | barbell,dumbbells(+13) | - |  |
| 97 | 1 | goal×focus weight_loss/cardio | intermediate | 45 | cardio | weight_loss | barbell,dumbbells(+13) | - |  |
| 98 | 1 | goal×focus weight_loss/upper | intermediate | 45 | upper | weight_loss | barbell,dumbbells(+13) | - |  |
| 99 | 1 | goal×focus muscle_tone/arms | intermediate | 45 | arms | muscle_tone | barbell,dumbbells(+13) | - |  |
| 100 | 1 | goal×focus muscle_tone/glutes | intermediate | 45 | glutes | muscle_tone | barbell,dumbbells(+13) | - |  |
| 101 | 1 | goal×focus general_fitness/full_body | intermediate | 45 | full_body | general_fitness | barbell,dumbbells(+13) | - |  |
| 102 | 1 | goal×focus general_fitness/core | intermediate | 45 | core | general_fitness | barbell,dumbbells(+13) | - |  |
| 103 | 1 | goal×focus strength/shoulders | intermediate | 45 | shoulders | strength | barbell,dumbbells(+13) | - |  |
| 104 | 1 | goal×focus hypertrophy/shoulders | intermediate | 45 | shoulders | hypertrophy | barbell,dumbbells(+13) | - |  |
| 105 | 1 | goal×focus hypertrophy/glutes | intermediate | 45 | glutes | hypertrophy | barbell,dumbbells(+13) | - |  |
| 106 | 1 | goal×focus strength/core | intermediate | 45 | core | strength | barbell,dumbbells(+13) | - |  |
| 107 | 1 | goal×focus endurance/full_body | intermediate | 45 | full_body | endurance | barbell,dumbbells(+13) | - |  |
| 108 | 1 | goal×focus power/upper | intermediate | 45 | upper | power | barbell,dumbbells(+13) | - |  |
| 109 | 1 | goal×focus athletic_performance/shoulders | intermediate | 45 | shoulders | athletic_performance | barbell,dumbbells(+13) | - |  |
| 110 | 1 | goal×focus muscle_tone/core | intermediate | 45 | core | muscle_tone | barbell,dumbbells(+13) | - |  |
| 111 | 2 | matrix beginner/15/strength/push/E1_full | beginner | 15 | push | strength | barbell,dumbbells(+13) | - |  |
| 112 | 2 | matrix beginner/15/fat_loss/pull/E2_bw | beginner | 15 | pull | fat_loss | [] | - |  |
| 113 | 2 | matrix beginner/15/general_fitness/legs/E3_db | beginner | 15 | legs | general_fitness | dumbbells,bench(+1) | - |  |
| 114 | 2 | matrix beginner/15/power/full_body/E4_kb | beginner | 15 | full_body | power | kettlebell | - |  |
| 115 | 2 | matrix beginner/20/general_fitness/core/E5_mach | beginner | 20 | core | general_fitness | cable_machine,leg_press_machine(+2) | - |  |
| 116 | 2 | matrix beginner/20/power/upper/E6_bands | beginner | 20 | upper | power | resistance_bands | - |  |
| 117 | 2 | matrix beginner/20/weight_loss/lower/E7_no_bb | beginner | 20 | lower | weight_loss | dumbbells,cable_machine(+5) | - |  |
| 118 | 2 | matrix beginner/20/strength/arms/E8_fw | beginner | 20 | arms | strength | barbell,dumbbells(+3) | - |  |
| 119 | 2 | matrix beginner/30/weight_loss/shoulders/E9_db1 | beginner | 30 | shoulders | weight_loss | dumbbells | - |  |
| 120 | 2 | matrix beginner/30/strength/glutes/E10_home | beginner | 30 | glutes | strength | dumbbells,resistance_bands(+1) | - |  |
| 121 | 2 | matrix beginner/30/fat_loss/cardio/E11_cardio | beginner | 30 | cardio | fat_loss | treadmill,rowing_machine(+2) | - |  |
| 122 | 2 | matrix beginner/30/general_fitness/mobility/E12_bw_bands | beginner | 30 | mobility | general_fitness | resistance_bands | - |  |
| 123 | 2 | matrix beginner/40/fat_loss/push/E13_TRX | beginner | 40 | push | fat_loss | TRX bands,resistance_bands(+1) | - |  |
| 124 | 2 | matrix beginner/40/general_fitness/pull/E14_gym_60 | beginner | 40 | pull | general_fitness | barbell,dumbbells(+26) | - |  |
| 125 | 2 | matrix beginner/40/power/legs/E1_full | beginner | 40 | legs | power | barbell,dumbbells(+13) | - |  |
| 126 | 2 | matrix beginner/40/weight_loss/full_body/E2_bw | beginner | 40 | full_body | weight_loss | [] | - |  |
| 127 | 2 | matrix beginner/45/power/core/E3_db | beginner | 45 | core | power | dumbbells,bench(+1) | - |  |
| 128 | 2 | matrix beginner/45/weight_loss/upper/E4_kb | beginner | 45 | upper | weight_loss | kettlebell | - |  |
| 129 | 2 | matrix beginner/45/strength/lower/E5_mach | beginner | 45 | lower | strength | cable_machine,leg_press_machine(+2) | - |  |
| 130 | 2 | matrix beginner/45/fat_loss/arms/E6_bands | beginner | 45 | arms | fat_loss | resistance_bands | - |  |
| 131 | 2 | matrix beginner/60/strength/shoulders/E7_no_bb | beginner | 60 | shoulders | strength | dumbbells,cable_machine(+5) | - |  |
| 132 | 2 | matrix beginner/60/fat_loss/glutes/E8_fw | beginner | 60 | glutes | fat_loss | barbell,dumbbells(+3) | - |  |
| 133 | 2 | matrix beginner/60/general_fitness/cardio/E9_db1 | beginner | 60 | cardio | general_fitness | dumbbells | - |  |
| 134 | 2 | matrix beginner/60/power/mobility/E10_home | beginner | 60 | mobility | power | dumbbells,resistance_bands(+1) | - |  |
| 135 | 2 | matrix beginner/75/general_fitness/push/E11_cardio | beginner | 75 | push | general_fitness | treadmill,rowing_machine(+2) | - |  |
| 136 | 2 | matrix beginner/75/power/pull/E12_bw_bands | beginner | 75 | pull | power | resistance_bands | - |  |
| 137 | 2 | matrix beginner/75/weight_loss/legs/E13_TRX | beginner | 75 | legs | weight_loss | TRX bands,resistance_bands(+1) | - |  |
| 138 | 2 | matrix beginner/75/strength/full_body/E14_gym_60 | beginner | 75 | full_body | strength | barbell,dumbbells(+26) | - |  |
| 139 | 2 | matrix beginner/90/weight_loss/core/E1_full | beginner | 90 | core | weight_loss | barbell,dumbbells(+13) | - |  |
| 140 | 2 | matrix beginner/90/strength/upper/E2_bw | beginner | 90 | upper | strength | [] | - |  |
| 141 | 2 | matrix beginner/90/fat_loss/lower/E3_db | beginner | 90 | lower | fat_loss | dumbbells,bench(+1) | - |  |
| 142 | 2 | matrix beginner/90/general_fitness/arms/E4_kb | beginner | 90 | arms | general_fitness | kettlebell | - |  |
| 143 | 2 | matrix intermediate/15/fat_loss/shoulders/E5_mach | intermediate | 15 | shoulders | fat_loss | cable_machine,leg_press_machine(+2) | - |  |
| 144 | 2 | matrix intermediate/15/general_fitness/glutes/E6_bands | intermediate | 15 | glutes | general_fitness | resistance_bands | - |  |
| 145 | 2 | matrix intermediate/15/power/cardio/E7_no_bb | intermediate | 15 | cardio | power | dumbbells,cable_machine(+5) | - |  |
| 146 | 2 | matrix intermediate/15/weight_loss/mobility/E8_fw | intermediate | 15 | mobility | weight_loss | barbell,dumbbells(+3) | - |  |
| 147 | 2 | matrix intermediate/20/power/push/E9_db1 | intermediate | 20 | push | power | dumbbells | - |  |
| 148 | 2 | matrix intermediate/20/weight_loss/pull/E10_home | intermediate | 20 | pull | weight_loss | dumbbells,resistance_bands(+1) | - |  |
| 149 | 2 | matrix intermediate/20/strength/legs/E11_cardio | intermediate | 20 | legs | strength | treadmill,rowing_machine(+2) | - |  |
| 150 | 2 | matrix intermediate/20/fat_loss/full_body/E12_bw_bands | intermediate | 20 | full_body | fat_loss | resistance_bands | - |  |
| 151 | 2 | matrix intermediate/30/strength/core/E13_TRX | intermediate | 30 | core | strength | TRX bands,resistance_bands(+1) | - |  |
| 152 | 2 | matrix intermediate/30/fat_loss/upper/E14_gym_60 | intermediate | 30 | upper | fat_loss | barbell,dumbbells(+26) | - |  |
| 153 | 2 | matrix intermediate/30/general_fitness/lower/E1_full | intermediate | 30 | lower | general_fitness | barbell,dumbbells(+13) | - |  |
| 154 | 2 | matrix intermediate/30/power/arms/E2_bw | intermediate | 30 | arms | power | [] | - |  |
| 155 | 2 | matrix intermediate/40/general_fitness/shoulders/E3_db | intermediate | 40 | shoulders | general_fitness | dumbbells,bench(+1) | - |  |
| 156 | 2 | matrix intermediate/40/power/glutes/E4_kb | intermediate | 40 | glutes | power | kettlebell | - |  |
| 157 | 2 | matrix intermediate/40/weight_loss/cardio/E5_mach | intermediate | 40 | cardio | weight_loss | cable_machine,leg_press_machine(+2) | - |  |
| 158 | 2 | matrix intermediate/40/strength/mobility/E6_bands | intermediate | 40 | mobility | strength | resistance_bands | - |  |
| 159 | 2 | matrix intermediate/45/weight_loss/push/E7_no_bb | intermediate | 45 | push | weight_loss | dumbbells,cable_machine(+5) | - |  |
| 160 | 2 | matrix intermediate/45/strength/pull/E8_fw | intermediate | 45 | pull | strength | barbell,dumbbells(+3) | - |  |
| 161 | 2 | matrix intermediate/45/fat_loss/legs/E9_db1 | intermediate | 45 | legs | fat_loss | dumbbells | - |  |
| 162 | 2 | matrix intermediate/45/general_fitness/full_body/E10_home | intermediate | 45 | full_body | general_fitness | dumbbells,resistance_bands(+1) | - |  |
| 163 | 2 | matrix intermediate/60/fat_loss/core/E11_cardio | intermediate | 60 | core | fat_loss | treadmill,rowing_machine(+2) | - |  |
| 164 | 2 | matrix intermediate/60/general_fitness/upper/E12_bw_bands | intermediate | 60 | upper | general_fitness | resistance_bands | - |  |
| 165 | 2 | matrix intermediate/60/power/lower/E13_TRX | intermediate | 60 | lower | power | TRX bands,resistance_bands(+1) | - |  |
| 166 | 2 | matrix intermediate/60/weight_loss/arms/E14_gym_60 | intermediate | 60 | arms | weight_loss | barbell,dumbbells(+26) | - |  |
| 167 | 2 | matrix intermediate/75/power/shoulders/E1_full | intermediate | 75 | shoulders | power | barbell,dumbbells(+13) | - |  |
| 168 | 2 | matrix intermediate/75/weight_loss/glutes/E2_bw | intermediate | 75 | glutes | weight_loss | [] | - |  |
| 169 | 2 | matrix intermediate/75/strength/cardio/E3_db | intermediate | 75 | cardio | strength | dumbbells,bench(+1) | - |  |
| 170 | 2 | matrix intermediate/75/fat_loss/mobility/E4_kb | intermediate | 75 | mobility | fat_loss | kettlebell | - |  |
| 171 | 2 | matrix intermediate/90/strength/push/E5_mach | intermediate | 90 | push | strength | cable_machine,leg_press_machine(+2) | - |  |
| 172 | 2 | matrix intermediate/90/fat_loss/pull/E6_bands | intermediate | 90 | pull | fat_loss | resistance_bands | - |  |
| 173 | 2 | matrix intermediate/90/general_fitness/legs/E7_no_bb | intermediate | 90 | legs | general_fitness | dumbbells,cable_machine(+5) | - |  |
| 174 | 2 | matrix intermediate/90/power/full_body/E8_fw | intermediate | 90 | full_body | power | barbell,dumbbells(+3) | - |  |
| 175 | 2 | matrix advanced/15/general_fitness/core/E9_db1 | advanced | 15 | core | general_fitness | dumbbells | - |  |
| 176 | 2 | matrix advanced/15/power/upper/E10_home | advanced | 15 | upper | power | dumbbells,resistance_bands(+1) | - |  |
| 177 | 2 | matrix advanced/15/weight_loss/lower/E11_cardio | advanced | 15 | lower | weight_loss | treadmill,rowing_machine(+2) | - |  |
| 178 | 2 | matrix advanced/15/strength/arms/E12_bw_bands | advanced | 15 | arms | strength | resistance_bands | - |  |
| 179 | 2 | matrix advanced/20/weight_loss/shoulders/E13_TRX | advanced | 20 | shoulders | weight_loss | TRX bands,resistance_bands(+1) | - |  |
| 180 | 2 | matrix advanced/20/strength/glutes/E14_gym_60 | advanced | 20 | glutes | strength | barbell,dumbbells(+26) | - |  |
| 181 | 2 | matrix advanced/20/fat_loss/cardio/E1_full | advanced | 20 | cardio | fat_loss | barbell,dumbbells(+13) | - |  |
| 182 | 2 | matrix advanced/20/general_fitness/mobility/E2_bw | advanced | 20 | mobility | general_fitness | [] | - |  |
| 183 | 2 | matrix advanced/30/fat_loss/push/E3_db | advanced | 30 | push | fat_loss | dumbbells,bench(+1) | - |  |
| 184 | 2 | matrix advanced/30/general_fitness/pull/E4_kb | advanced | 30 | pull | general_fitness | kettlebell | - |  |
| 185 | 2 | matrix advanced/30/power/legs/E5_mach | advanced | 30 | legs | power | cable_machine,leg_press_machine(+2) | - |  |
| 186 | 2 | matrix advanced/30/weight_loss/full_body/E6_bands | advanced | 30 | full_body | weight_loss | resistance_bands | - |  |
| 187 | 2 | matrix advanced/40/power/core/E7_no_bb | advanced | 40 | core | power | dumbbells,cable_machine(+5) | - |  |
| 188 | 2 | matrix advanced/40/weight_loss/upper/E8_fw | advanced | 40 | upper | weight_loss | barbell,dumbbells(+3) | - |  |
| 189 | 2 | matrix advanced/40/strength/lower/E9_db1 | advanced | 40 | lower | strength | dumbbells | - |  |
| 190 | 2 | matrix advanced/40/fat_loss/arms/E10_home | advanced | 40 | arms | fat_loss | dumbbells,resistance_bands(+1) | - |  |
| 191 | 2 | matrix advanced/45/strength/shoulders/E11_cardio | advanced | 45 | shoulders | strength | treadmill,rowing_machine(+2) | - |  |
| 192 | 2 | matrix advanced/45/fat_loss/glutes/E12_bw_bands | advanced | 45 | glutes | fat_loss | resistance_bands | - |  |
| 193 | 2 | matrix advanced/45/general_fitness/cardio/E13_TRX | advanced | 45 | cardio | general_fitness | TRX bands,resistance_bands(+1) | - |  |
| 194 | 2 | matrix advanced/45/power/mobility/E14_gym_60 | advanced | 45 | mobility | power | barbell,dumbbells(+26) | - |  |
| 195 | 2 | matrix advanced/60/general_fitness/push/E1_full | advanced | 60 | push | general_fitness | barbell,dumbbells(+13) | - |  |
| 196 | 2 | matrix advanced/60/power/pull/E2_bw | advanced | 60 | pull | power | [] | - |  |
| 197 | 2 | matrix advanced/60/weight_loss/legs/E3_db | advanced | 60 | legs | weight_loss | dumbbells,bench(+1) | - |  |
| 198 | 2 | matrix advanced/60/strength/full_body/E4_kb | advanced | 60 | full_body | strength | kettlebell | - |  |
| 199 | 2 | matrix advanced/75/weight_loss/core/E5_mach | advanced | 75 | core | weight_loss | cable_machine,leg_press_machine(+2) | - |  |
| 200 | 2 | matrix advanced/75/strength/upper/E6_bands | advanced | 75 | upper | strength | resistance_bands | - |  |
| 201 | 2 | matrix advanced/75/fat_loss/lower/E7_no_bb | advanced | 75 | lower | fat_loss | dumbbells,cable_machine(+5) | - |  |
| 202 | 2 | matrix advanced/75/general_fitness/arms/E8_fw | advanced | 75 | arms | general_fitness | barbell,dumbbells(+3) | - |  |
| 203 | 2 | matrix advanced/90/fat_loss/shoulders/E9_db1 | advanced | 90 | shoulders | fat_loss | dumbbells | - |  |
| 204 | 2 | matrix advanced/90/general_fitness/glutes/E10_home | advanced | 90 | glutes | general_fitness | dumbbells,resistance_bands(+1) | - |  |
| 205 | 2 | matrix advanced/90/power/cardio/E11_cardio | advanced | 90 | cardio | power | treadmill,rowing_machine(+2) | - |  |
| 206 | 2 | matrix advanced/90/weight_loss/mobility/E12_bw_bands | advanced | 90 | mobility | weight_loss | resistance_bands | - |  |
| 207 | 3 | comeback 0d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | skip_comeback |
| 208 | 3 | comeback 0d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | skip_comeback |
| 209 | 3 | comeback 0d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | skip_comeback |
| 210 | 3 | comeback 0d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | skip_comeback |
| 211 | 3 | comeback 7d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 212 | 3 | comeback 7d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 213 | 3 | comeback 7d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 214 | 3 | comeback 7d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 215 | 3 | comeback 14d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 216 | 3 | comeback 14d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 217 | 3 | comeback 14d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 218 | 3 | comeback 14d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 219 | 3 | comeback 30d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 220 | 3 | comeback 30d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 221 | 3 | comeback 30d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 222 | 3 | comeback 30d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 223 | 3 | comeback 60d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 224 | 3 | comeback 60d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 225 | 3 | comeback 60d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 226 | 3 | comeback 60d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 227 | 3 | comeback 90d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 228 | 3 | comeback 90d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 229 | 3 | comeback 90d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 230 | 3 | comeback 90d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 231 | 3 | comeback 180d + intensity easy | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 232 | 3 | comeback 180d + intensity medium | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 233 | 3 | comeback 180d + intensity hard | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 234 | 3 | comeback 180d + intensity hell | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 235 | 3 | custom_program: none | intermediate | 30 | full_body | - | barbell,dumbbells(+13) | - |  |
| 236 | 3 | custom_program: Train for HYROX in 12 weeks — week 4 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | cpd=Train for HYROX in 12 weeks —  |
| 237 | 3 | custom_program: Marathon training, week 8 of 16, easy ru | intermediate | 60 | full_body | - | barbell,dumbbells(+13) | - | cpd=Marathon training, week 8 of 1 |
| 238 | 3 | custom_program: Bodybuilding show prep, 8 weeks out, pea | intermediate | 75 | full_body | - | barbell,dumbbells(+13) | - | cpd=Bodybuilding show prep, 8 week |
| 239 | 3 | custom_program: Powerlifting meet in 6 weeks — squat day | intermediate | 90 | full_body | - | barbell,dumbbells(+13) | - | cpd=Powerlifting meet in 6 weeks — |
| 240 | 3 | custom_program: Calisthenics-only, working toward muscle | intermediate | 30 | full_body | - | barbell,dumbbells(+13) | - | cpd=Calisthenics-only, working tow |
| 241 | 3 | custom_program: Crossfit Open prep — varied modal domain | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | cpd=Crossfit Open prep — varied mo |
| 242 | 3 | custom_program: Athlete return-to-sport rehab phase 2 | intermediate | 60 | full_body | - | barbell,dumbbells(+13) | - | cpd=Athlete return-to-sport rehab  |
| 243 | 3 | custom_program: 12-week deload after marathon — rebuild  | intermediate | 75 | full_body | - | barbell,dumbbells(+13) | - | cpd=12-week deload after marathon  |
| 244 | 3 | custom_program: Morning routine before work — quick ener | intermediate | 90 | full_body | - | barbell,dumbbells(+13) | - | cpd=Morning routine before work —  |
| 245 | 3 | exclude=none | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 246 | 3 | exclude=bench press,barbell squat,dead | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | exclude=bench press,barbell squat,dead |
| 247 | 3 | exclude=pull-up,chin-up,muscle-up | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | exclude=pull-up,chin-up,muscle-up |
| 248 | 3 | exclude=burpee,jump squat,box jump | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | exclude=burpee,jump squat,box jump |
| 249 | 3 | exclude=plank,side plank,dead bug | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | exclude=plank,side plank,dead bug |
| 250 | 3 | exclude=overhead press,snatch,clean an | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | exclude=overhead press,snatch,clean an |
| 251 | 3 | adjacent=none | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - |  |
| 252 | 3 | adjacent=bench press,squat,deadlift,pul | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - | adjacent=bench press,squat,deadlift,pul |
| 253 | 3 | adjacent=barbell row,pull-up,lat pulldo | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - | adjacent=barbell row,pull-up,lat pulldo |
| 254 | 3 | adjacent=overhead press,lateral raise,f | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - | adjacent=overhead press,lateral raise,f |
| 255 | 3 | adjacent=leg press,lunges,step-ups | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - | adjacent=leg press,lunges,step-ups |
| 256 | 3 | adjacent=bicep curl,hammer curl,preache | intermediate | 45 | upper | - | barbell,dumbbells(+13) | - | adjacent=bicep curl,hammer curl,preache |
| 257 | 3 | batch_offset=0 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 258 | 3 | batch_offset=1 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=1 |
| 259 | 3 | batch_offset=2 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=2 |
| 260 | 3 | batch_offset=3 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=3 |
| 261 | 3 | batch_offset=5 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=5 |
| 262 | 3 | batch_offset=7 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=7 |
| 263 | 3 | batch_offset=10 | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | batch_offset=10 |
| 264 | 4 | date today force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 265 | 4 | date today force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 266 | 4 | date +1d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 267 | 4 | date +1d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 268 | 4 | date +2d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 269 | 4 | date +2d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 270 | 4 | date +3d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 271 | 4 | date +3d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 272 | 4 | date +5d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 273 | 4 | date +5d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 274 | 4 | date +7d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 275 | 4 | date +7d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 276 | 4 | date +10d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 277 | 4 | date +10d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 278 | 4 | date +14d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 279 | 4 | date +14d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 280 | 4 | date +21d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 281 | 4 | date +21d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 282 | 4 | date +30d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 283 | 4 | date +30d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 284 | 4 | date +45d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 285 | 4 | date +45d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 286 | 4 | date +60d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 287 | 4 | date +60d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 288 | 4 | date +90d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 289 | 4 | date +90d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 290 | 4 | date +120d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 291 | 4 | date +120d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 292 | 4 | date +180d force=True | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 293 | 4 | date +180d force=False | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 294 | 5 | wt=auto/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - |  |
| 295 | 5 | wt=auto/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - |  |
| 296 | 5 | wt=auto/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - |  |
| 297 | 5 | wt=auto/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - |  |
| 298 | 5 | wt=auto/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - |  |
| 299 | 5 | wt=auto/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - |  |
| 300 | 5 | wt=auto/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - |  |
| 301 | 5 | wt=strength/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=strength |
| 302 | 5 | wt=strength/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=strength |
| 303 | 5 | wt=strength/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=strength |
| 304 | 5 | wt=strength/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=strength |
| 305 | 5 | wt=strength/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=strength |
| 306 | 5 | wt=strength/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=strength |
| 307 | 5 | wt=strength/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=strength |
| 308 | 5 | wt=hypertrophy/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 309 | 5 | wt=hypertrophy/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 310 | 5 | wt=hypertrophy/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 311 | 5 | wt=hypertrophy/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 312 | 5 | wt=hypertrophy/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 313 | 5 | wt=hypertrophy/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 314 | 5 | wt=hypertrophy/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=hypertrophy |
| 315 | 5 | wt=cardio/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=cardio |
| 316 | 5 | wt=cardio/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=cardio |
| 317 | 5 | wt=cardio/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=cardio |
| 318 | 5 | wt=cardio/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=cardio |
| 319 | 5 | wt=cardio/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=cardio |
| 320 | 5 | wt=cardio/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=cardio |
| 321 | 5 | wt=cardio/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=cardio |
| 322 | 5 | wt=hiit/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=hiit |
| 323 | 5 | wt=hiit/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=hiit |
| 324 | 5 | wt=hiit/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=hiit |
| 325 | 5 | wt=hiit/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=hiit |
| 326 | 5 | wt=hiit/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=hiit |
| 327 | 5 | wt=hiit/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=hiit |
| 328 | 5 | wt=hiit/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=hiit |
| 329 | 5 | wt=mobility/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=mobility |
| 330 | 5 | wt=mobility/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=mobility |
| 331 | 5 | wt=mobility/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=mobility |
| 332 | 5 | wt=mobility/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=mobility |
| 333 | 5 | wt=mobility/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=mobility |
| 334 | 5 | wt=mobility/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=mobility |
| 335 | 5 | wt=mobility/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=mobility |
| 336 | 5 | wt=recovery/focus=push | intermediate | 45 | push | - | barbell,dumbbells(+13) | - | wt=recovery |
| 337 | 5 | wt=recovery/focus=pull | intermediate | 45 | pull | - | barbell,dumbbells(+13) | - | wt=recovery |
| 338 | 5 | wt=recovery/focus=legs | intermediate | 45 | legs | - | barbell,dumbbells(+13) | - | wt=recovery |
| 339 | 5 | wt=recovery/focus=full_body | intermediate | 45 | full_body | - | barbell,dumbbells(+13) | - | wt=recovery |
| 340 | 5 | wt=recovery/focus=core | intermediate | 45 | core | - | barbell,dumbbells(+13) | - | wt=recovery |
| 341 | 5 | wt=recovery/focus=cardio | intermediate | 45 | cardio | - | barbell,dumbbells(+13) | - | wt=recovery |
| 342 | 5 | wt=recovery/focus=mobility | intermediate | 45 | mobility | - | barbell,dumbbells(+13) | - | wt=recovery |
| 343 | 6 | max constraint stress | beginner | 90 | full_body | strength | [] | knee,shoulder,lower_back,wrist,ankle |  |
| 344 | 6 | lowest demand at top | advanced | 15 | mobility | mobility | barbell,dumbbells(+13) | - |  |
| 345 | 6 | empty goals + bodyweight | intermediate | 30 | full_body | - | [] | - |  |
| 346 | 6 | prompt bloat 12 focus areas | intermediate | 60 | push,pull,legs,full_body,core,upper,lower,arms,shoulders,glutes,cardio,mobility | strength,hypertrophy,fat_loss,endurance,general_fitness,mobility,power,athletic_performance,weight_loss,muscle_tone | barbell,dumbbells(+26) | - |  |
| 347 | 6 | composite real-world | intermediate | 45 | full_body | - | cable_machine,leg_press_machine(+2) | knee,hip,lower_back | cpd=Athlete return-to-sport rehab  |
| 348 | 6 | beginner+hell+bodyweight | beginner | 30 | full_body | strength | [] | - |  |
| 349 | 6 | advanced+easy+15min | advanced | 15 | full_body | general_fitness | barbell,dumbbells(+13) | - |  |
| 350 | 6 | 90min beginner | beginner | 90 | full_body | - | barbell,dumbbells(+13) | - |  |
| 351 | 6 | 5min express | advanced | 15 | cardio | - | treadmill,rowing_machine(+2) | - | wt=hiit |
| 352 | 6 | all-7 injuries + bodyweight | beginner | 30 | mobility | - | [] | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 353 | 6 | powerlifting prep | advanced | 75 | legs | strength | barbell,dumbbells(+3) | - | cpd=Powerlifting meet in 6 weeks — |
| 354 | 6 | marathon training | intermediate | 75 | cardio | endurance | treadmill,rowing_machine(+2) | - | cpd=Marathon training, week 8 of 1 |
| 355 | 6 | calisthenics | intermediate | 45 | upper | strength | [] | - | cpd=Calisthenics-only, working tow |
| 356 | 6 | crossfit varied | advanced | 60 | full_body | - | barbell,dumbbells(+26) | - | cpd=Crossfit Open prep — varied mo / wt=hybrid |
| 357 | 6 | senior with hell intent | beginner | 30 | full_body | general_fitness | barbell,dumbbells(+13) | - |  |
| 358 | 6 | multi-goal mobility+strength | intermediate | 45 | full_body | strength,mobility | barbell,dumbbells(+13) | - |  |
| 359 | 6 | multi-focus push+pull+core | intermediate | 60 | push,pull,core | - | barbell,dumbbells(+13) | - |  |
| 360 | 6 | range 15-30 strength | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 15-30 |
| 361 | 6 | range 60-90 hypertrophy | advanced | range | upper | hypertrophy | barbell,dumbbells(+13) | - | range 60-90 |
| 362 | 6 | single dumbbell only | intermediate | 30 | full_body | - | dumbbells | - | db_count=1 |
| 363 | 6 | cardio-machines + strength focus | intermediate | 30 | push | - | treadmill,rowing_machine(+2) | - |  |
| 364 | 6 | 60min bodyweight legs | intermediate | 60 | legs | - | [] | - |  |
| 365 | 6 | bands only + powerlifting | advanced | 45 | legs | strength | resistance_bands | - |  |
| 366 | 6 | 60-item gym + mobility | intermediate | 30 | mobility | mobility | barbell,dumbbells(+26) | - |  |
| 367 | 6 | TRX + strength | intermediate | 45 | full_body | strength | TRX bands,resistance_bands(+1) | - |  |
| 368 | 6 | excl + adj combined | intermediate | 60 | full_body | - | barbell,dumbbells(+13) | - | exclude=bench press,squat / adjacent=deadlift,row,pullup |
| 369 | 6 | variety #1 | intermediate | 45 | full_body | hypertrophy | barbell,dumbbells(+13) | - |  |
| 370 | 6 | variety #2 | intermediate | 45 | full_body | hypertrophy | barbell,dumbbells(+13) | - |  |
| 371 | 6 | variety #3 | intermediate | 45 | full_body | hypertrophy | barbell,dumbbells(+13) | - |  |
| 372 | 6 | KB power advanced | advanced | 45 | full_body | power | kettlebell | - |  |
| 373 | 6 | rehab ankle + cardio focus | intermediate | 30 | cardio | - | treadmill,rowing_machine(+2) | ankle |  |
| 374 | 6 | athletic_perf + knee | advanced | 60 | full_body | athletic_performance | barbell,dumbbells(+13) | knee |  |
| 375 | 6 | beginner KB only | beginner | 30 | full_body | - | kettlebell | - |  |
| 376 | 6 | senior 75+ proxy | beginner | 30 | full_body | general_fitness | barbell,dumbbells(+13) | - |  |
| 377 | 6 | adv + mobility + 90min | advanced | 90 | mobility | mobility | resistance_bands | - |  |
| 378 | 6 | multi-injury + cardio | intermediate | 30 | cardio | - | treadmill,rowing_machine(+2) | knee,hip,lower_back |  |
| 379 | 6 | range 45-60 full body | intermediate | range | full_body | - | barbell,dumbbells(+13) | - | range 45-60 |
| 380 | 6 | range 30-45 push | intermediate | range | push | - | dumbbells,bench(+1) | - | range 30-45 |
| 381 | 6 | HIIT + cardio + KB | advanced | 30 | cardio | - | kettlebell | - | wt=hiit |
| 382 | 6 | recovery + bands | intermediate | 30 | mobility | - | resistance_bands | - | wt=recovery |
| 383 | 6 | advanced 90min strength | advanced | 90 | full_body | strength | barbell,dumbbells(+13) | - |  |
| 384 | 6 | bodyweight cardio | intermediate | 30 | cardio | - | [] | - |  |
| 385 | 6 | glutes focus intermediate | intermediate | 45 | glutes | hypertrophy | barbell,dumbbells(+13) | - |  |
| 386 | 6 | arms + dumbbells | intermediate | 30 | arms | - | dumbbells,bench(+1) | - |  |
| 387 | 6 | shoulders + advanced | advanced | 45 | shoulders | strength | barbell,dumbbells(+13) | - |  |
| 388 | 6 | progressive overload sanity | intermediate | 60 | legs | strength | barbell,dumbbells(+13) | - |  |
| 389 | 6 | 75min endurance run | intermediate | 75 | cardio | endurance | treadmill | - |  |
| 390 | 6 | big-3 powerlift | advanced | 90 | full_body | strength | barbell,dumbbells(+3) | - |  |
| 391 | 6 | yoga style mobility | intermediate | 30 | mobility | mobility | TRX bands,resistance_bands(+1) | - |  |
| 392 | 6 | union all goals 60min | intermediate | 60 | full_body | strength,hypertrophy,fat_loss,endurance,general_fitness,mobility,power,athletic_performance,weight_loss,muscle_tone | barbell,dumbbells(+13) | - |  |
| 393 | 7 | pad beginner/15/strength/push/E1_full/none | beginner | 15 | push | strength | barbell,dumbbells(+13) | - |  |
| 394 | 7 | pad intermediate/20/hypertrophy/pull/E2_bw/knee | intermediate | 20 | pull | hypertrophy | [] | knee |  |
| 395 | 7 | pad advanced/30/fat_loss/legs/E3_db/shoulder | advanced | 30 | legs | fat_loss | dumbbells,bench(+1) | shoulder |  |
| 396 | 7 | pad beginner/40/endurance/full_body/E4_kb/lower_back | beginner | 40 | full_body | endurance | kettlebell | lower_back |  |
| 397 | 7 | pad intermediate/45/general_fitness/core/E5_mach/wrist | intermediate | 45 | core | general_fitness | cable_machine,leg_press_machine(+2) | wrist |  |
| 398 | 7 | pad advanced/60/mobility/upper/E6_bands/ankle | advanced | 60 | upper | mobility | resistance_bands | ankle |  |
| 399 | 7 | pad beginner/75/power/lower/E7_no_bb/hip | beginner | 75 | lower | power | dumbbells,cable_machine(+5) | hip |  |
| 400 | 7 | pad intermediate/90/athletic_performance/arms/E8_fw/elbow | intermediate | 90 | arms | athletic_performance | barbell,dumbbells(+3) | elbow |  |
| 401 | 7 | pad advanced/15/weight_loss/shoulders/E9_db1/neck | advanced | 15 | shoulders | weight_loss | dumbbells | neck |  |
| 402 | 7 | pad beginner/20/muscle_tone/glutes/E10_home/knee+shoulder | beginner | 20 | glutes | muscle_tone | dumbbells,resistance_bands(+1) | knee,shoulder |  |
| 403 | 7 | pad intermediate/30/strength/cardio/E11_cardio/knee+lower_back | intermediate | 30 | cardio | strength | treadmill,rowing_machine(+2) | knee,lower_back |  |
| 404 | 7 | pad advanced/40/hypertrophy/mobility/E12_bw_bands/shoulder+wrist | advanced | 40 | mobility | hypertrophy | resistance_bands | shoulder,wrist |  |
| 405 | 7 | pad beginner/45/fat_loss/push/E13_TRX/knee+shoulder+lower_back | beginner | 45 | push | fat_loss | TRX bands,resistance_bands(+1) | knee,shoulder,lower_back |  |
| 406 | 7 | pad intermediate/60/endurance/pull/E14_gym_60/knee+shoulder+lower_back+wrist+ankle | intermediate | 60 | pull | endurance | barbell,dumbbells(+26) | knee,shoulder,lower_back,wrist,ankle |  |
| 407 | 7 | pad advanced/75/general_fitness/legs/E1_full/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 75 | legs | general_fitness | barbell,dumbbells(+13) | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 408 | 7 | pad beginner/90/mobility/full_body/E2_bw/none | beginner | 90 | full_body | mobility | [] | - |  |
| 409 | 7 | pad intermediate/15/power/core/E3_db/knee | intermediate | 15 | core | power | dumbbells,bench(+1) | knee |  |
| 410 | 7 | pad advanced/20/athletic_performance/upper/E4_kb/shoulder | advanced | 20 | upper | athletic_performance | kettlebell | shoulder |  |
| 411 | 7 | pad beginner/30/weight_loss/lower/E5_mach/lower_back | beginner | 30 | lower | weight_loss | cable_machine,leg_press_machine(+2) | lower_back |  |
| 412 | 7 | pad intermediate/40/muscle_tone/arms/E6_bands/wrist | intermediate | 40 | arms | muscle_tone | resistance_bands | wrist |  |
| 413 | 7 | pad advanced/45/strength/shoulders/E7_no_bb/ankle | advanced | 45 | shoulders | strength | dumbbells,cable_machine(+5) | ankle |  |
| 414 | 7 | pad beginner/60/hypertrophy/glutes/E8_fw/hip | beginner | 60 | glutes | hypertrophy | barbell,dumbbells(+3) | hip |  |
| 415 | 7 | pad intermediate/75/fat_loss/cardio/E9_db1/elbow | intermediate | 75 | cardio | fat_loss | dumbbells | elbow |  |
| 416 | 7 | pad advanced/90/endurance/mobility/E10_home/neck | advanced | 90 | mobility | endurance | dumbbells,resistance_bands(+1) | neck |  |
| 417 | 7 | pad beginner/15/general_fitness/push/E11_cardio/knee+shoulder | beginner | 15 | push | general_fitness | treadmill,rowing_machine(+2) | knee,shoulder |  |
| 418 | 7 | pad intermediate/20/mobility/pull/E12_bw_bands/knee+lower_back | intermediate | 20 | pull | mobility | resistance_bands | knee,lower_back |  |
| 419 | 7 | pad advanced/30/power/legs/E13_TRX/shoulder+wrist | advanced | 30 | legs | power | TRX bands,resistance_bands(+1) | shoulder,wrist |  |
| 420 | 7 | pad beginner/40/athletic_performance/full_body/E14_gym_60/knee+shoulder+lower_back | beginner | 40 | full_body | athletic_performance | barbell,dumbbells(+26) | knee,shoulder,lower_back |  |
| 421 | 7 | pad intermediate/45/weight_loss/core/E1_full/knee+shoulder+lower_back+wrist+ankle | intermediate | 45 | core | weight_loss | barbell,dumbbells(+13) | knee,shoulder,lower_back,wrist,ankle |  |
| 422 | 7 | pad advanced/60/muscle_tone/upper/E2_bw/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 60 | upper | muscle_tone | [] | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 423 | 7 | pad beginner/75/strength/lower/E3_db/none | beginner | 75 | lower | strength | dumbbells,bench(+1) | - |  |
| 424 | 7 | pad intermediate/90/hypertrophy/arms/E4_kb/knee | intermediate | 90 | arms | hypertrophy | kettlebell | knee |  |
| 425 | 7 | pad advanced/15/fat_loss/shoulders/E5_mach/shoulder | advanced | 15 | shoulders | fat_loss | cable_machine,leg_press_machine(+2) | shoulder |  |
| 426 | 7 | pad beginner/20/endurance/glutes/E6_bands/lower_back | beginner | 20 | glutes | endurance | resistance_bands | lower_back |  |
| 427 | 7 | pad intermediate/30/general_fitness/cardio/E7_no_bb/wrist | intermediate | 30 | cardio | general_fitness | dumbbells,cable_machine(+5) | wrist |  |
| 428 | 7 | pad advanced/40/mobility/mobility/E8_fw/ankle | advanced | 40 | mobility | mobility | barbell,dumbbells(+3) | ankle |  |
| 429 | 7 | pad beginner/45/power/push/E9_db1/hip | beginner | 45 | push | power | dumbbells | hip |  |
| 430 | 7 | pad intermediate/60/athletic_performance/pull/E10_home/elbow | intermediate | 60 | pull | athletic_performance | dumbbells,resistance_bands(+1) | elbow |  |
| 431 | 7 | pad advanced/75/weight_loss/legs/E11_cardio/neck | advanced | 75 | legs | weight_loss | treadmill,rowing_machine(+2) | neck |  |
| 432 | 7 | pad beginner/90/muscle_tone/full_body/E12_bw_bands/knee+shoulder | beginner | 90 | full_body | muscle_tone | resistance_bands | knee,shoulder |  |
| 433 | 7 | pad intermediate/15/strength/core/E13_TRX/knee+lower_back | intermediate | 15 | core | strength | TRX bands,resistance_bands(+1) | knee,lower_back |  |
| 434 | 7 | pad advanced/20/hypertrophy/upper/E14_gym_60/shoulder+wrist | advanced | 20 | upper | hypertrophy | barbell,dumbbells(+26) | shoulder,wrist |  |
| 435 | 7 | pad beginner/30/fat_loss/lower/E1_full/knee+shoulder+lower_back | beginner | 30 | lower | fat_loss | barbell,dumbbells(+13) | knee,shoulder,lower_back |  |
| 436 | 7 | pad intermediate/40/endurance/arms/E2_bw/knee+shoulder+lower_back+wrist+ankle | intermediate | 40 | arms | endurance | [] | knee,shoulder,lower_back,wrist,ankle |  |
| 437 | 7 | pad advanced/45/general_fitness/shoulders/E3_db/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 45 | shoulders | general_fitness | dumbbells,bench(+1) | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 438 | 7 | pad beginner/60/mobility/glutes/E4_kb/none | beginner | 60 | glutes | mobility | kettlebell | - |  |
| 439 | 7 | pad intermediate/75/power/cardio/E5_mach/knee | intermediate | 75 | cardio | power | cable_machine,leg_press_machine(+2) | knee |  |
| 440 | 7 | pad advanced/90/athletic_performance/mobility/E6_bands/shoulder | advanced | 90 | mobility | athletic_performance | resistance_bands | shoulder |  |
| 441 | 7 | pad beginner/15/weight_loss/push/E7_no_bb/lower_back | beginner | 15 | push | weight_loss | dumbbells,cable_machine(+5) | lower_back |  |
| 442 | 7 | pad intermediate/20/muscle_tone/pull/E8_fw/wrist | intermediate | 20 | pull | muscle_tone | barbell,dumbbells(+3) | wrist |  |
| 443 | 7 | pad advanced/30/strength/legs/E9_db1/ankle | advanced | 30 | legs | strength | dumbbells | ankle |  |
| 444 | 7 | pad beginner/40/hypertrophy/full_body/E10_home/hip | beginner | 40 | full_body | hypertrophy | dumbbells,resistance_bands(+1) | hip |  |
| 445 | 7 | pad intermediate/45/fat_loss/core/E11_cardio/elbow | intermediate | 45 | core | fat_loss | treadmill,rowing_machine(+2) | elbow |  |
| 446 | 7 | pad advanced/60/endurance/upper/E12_bw_bands/neck | advanced | 60 | upper | endurance | resistance_bands | neck |  |
| 447 | 7 | pad beginner/75/general_fitness/lower/E13_TRX/knee+shoulder | beginner | 75 | lower | general_fitness | TRX bands,resistance_bands(+1) | knee,shoulder |  |
| 448 | 7 | pad intermediate/90/mobility/arms/E14_gym_60/knee+lower_back | intermediate | 90 | arms | mobility | barbell,dumbbells(+26) | knee,lower_back |  |
| 449 | 7 | pad advanced/15/power/shoulders/E1_full/shoulder+wrist | advanced | 15 | shoulders | power | barbell,dumbbells(+13) | shoulder,wrist |  |
| 450 | 7 | pad beginner/20/athletic_performance/glutes/E2_bw/knee+shoulder+lower_back | beginner | 20 | glutes | athletic_performance | [] | knee,shoulder,lower_back |  |
| 451 | 7 | pad intermediate/30/weight_loss/cardio/E3_db/knee+shoulder+lower_back+wrist+ankle | intermediate | 30 | cardio | weight_loss | dumbbells,bench(+1) | knee,shoulder,lower_back,wrist,ankle |  |
| 452 | 7 | pad advanced/40/muscle_tone/mobility/E4_kb/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 40 | mobility | muscle_tone | kettlebell | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 453 | 7 | pad beginner/45/strength/push/E5_mach/none | beginner | 45 | push | strength | cable_machine,leg_press_machine(+2) | - |  |
| 454 | 7 | pad intermediate/60/hypertrophy/pull/E6_bands/knee | intermediate | 60 | pull | hypertrophy | resistance_bands | knee |  |
| 455 | 7 | pad advanced/75/fat_loss/legs/E7_no_bb/shoulder | advanced | 75 | legs | fat_loss | dumbbells,cable_machine(+5) | shoulder |  |
| 456 | 7 | pad beginner/90/endurance/full_body/E8_fw/lower_back | beginner | 90 | full_body | endurance | barbell,dumbbells(+3) | lower_back |  |
| 457 | 7 | pad intermediate/15/general_fitness/core/E9_db1/wrist | intermediate | 15 | core | general_fitness | dumbbells | wrist |  |
| 458 | 7 | pad advanced/20/mobility/upper/E10_home/ankle | advanced | 20 | upper | mobility | dumbbells,resistance_bands(+1) | ankle |  |
| 459 | 7 | pad beginner/30/power/lower/E11_cardio/hip | beginner | 30 | lower | power | treadmill,rowing_machine(+2) | hip |  |
| 460 | 7 | pad intermediate/40/athletic_performance/arms/E12_bw_bands/elbow | intermediate | 40 | arms | athletic_performance | resistance_bands | elbow |  |
| 461 | 7 | pad advanced/45/weight_loss/shoulders/E13_TRX/neck | advanced | 45 | shoulders | weight_loss | TRX bands,resistance_bands(+1) | neck |  |
| 462 | 7 | pad beginner/60/muscle_tone/glutes/E14_gym_60/knee+shoulder | beginner | 60 | glutes | muscle_tone | barbell,dumbbells(+26) | knee,shoulder |  |
| 463 | 7 | pad intermediate/75/strength/cardio/E1_full/knee+lower_back | intermediate | 75 | cardio | strength | barbell,dumbbells(+13) | knee,lower_back |  |
| 464 | 7 | pad advanced/90/hypertrophy/mobility/E2_bw/shoulder+wrist | advanced | 90 | mobility | hypertrophy | [] | shoulder,wrist |  |
| 465 | 7 | pad beginner/15/fat_loss/push/E3_db/knee+shoulder+lower_back | beginner | 15 | push | fat_loss | dumbbells,bench(+1) | knee,shoulder,lower_back |  |
| 466 | 7 | pad intermediate/20/endurance/pull/E4_kb/knee+shoulder+lower_back+wrist+ankle | intermediate | 20 | pull | endurance | kettlebell | knee,shoulder,lower_back,wrist,ankle |  |
| 467 | 7 | pad advanced/30/general_fitness/legs/E5_mach/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 30 | legs | general_fitness | cable_machine,leg_press_machine(+2) | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 468 | 7 | pad beginner/40/mobility/full_body/E6_bands/none | beginner | 40 | full_body | mobility | resistance_bands | - |  |
| 469 | 7 | pad intermediate/45/power/core/E7_no_bb/knee | intermediate | 45 | core | power | dumbbells,cable_machine(+5) | knee |  |
| 470 | 7 | pad advanced/60/athletic_performance/upper/E8_fw/shoulder | advanced | 60 | upper | athletic_performance | barbell,dumbbells(+3) | shoulder |  |
| 471 | 7 | pad beginner/75/weight_loss/lower/E9_db1/lower_back | beginner | 75 | lower | weight_loss | dumbbells | lower_back |  |
| 472 | 7 | pad intermediate/90/muscle_tone/arms/E10_home/wrist | intermediate | 90 | arms | muscle_tone | dumbbells,resistance_bands(+1) | wrist |  |
| 473 | 7 | pad advanced/15/strength/shoulders/E11_cardio/ankle | advanced | 15 | shoulders | strength | treadmill,rowing_machine(+2) | ankle |  |
| 474 | 7 | pad beginner/20/hypertrophy/glutes/E12_bw_bands/hip | beginner | 20 | glutes | hypertrophy | resistance_bands | hip |  |
| 475 | 7 | pad intermediate/30/fat_loss/cardio/E13_TRX/elbow | intermediate | 30 | cardio | fat_loss | TRX bands,resistance_bands(+1) | elbow |  |
| 476 | 7 | pad advanced/40/endurance/mobility/E14_gym_60/neck | advanced | 40 | mobility | endurance | barbell,dumbbells(+26) | neck |  |
| 477 | 7 | pad beginner/45/general_fitness/push/E1_full/knee+shoulder | beginner | 45 | push | general_fitness | barbell,dumbbells(+13) | knee,shoulder |  |
| 478 | 7 | pad intermediate/60/mobility/pull/E2_bw/knee+lower_back | intermediate | 60 | pull | mobility | [] | knee,lower_back |  |
| 479 | 7 | pad advanced/75/power/legs/E3_db/shoulder+wrist | advanced | 75 | legs | power | dumbbells,bench(+1) | shoulder,wrist |  |
| 480 | 7 | pad beginner/90/athletic_performance/full_body/E4_kb/knee+shoulder+lower_back | beginner | 90 | full_body | athletic_performance | kettlebell | knee,shoulder,lower_back |  |
| 481 | 7 | pad intermediate/15/weight_loss/core/E5_mach/knee+shoulder+lower_back+wrist+ankle | intermediate | 15 | core | weight_loss | cable_machine,leg_press_machine(+2) | knee,shoulder,lower_back,wrist,ankle |  |
| 482 | 7 | pad advanced/20/muscle_tone/upper/E6_bands/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 20 | upper | muscle_tone | resistance_bands | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 483 | 7 | pad beginner/30/strength/lower/E7_no_bb/none | beginner | 30 | lower | strength | dumbbells,cable_machine(+5) | - |  |
| 484 | 7 | pad intermediate/40/hypertrophy/arms/E8_fw/knee | intermediate | 40 | arms | hypertrophy | barbell,dumbbells(+3) | knee |  |
| 485 | 7 | pad advanced/45/fat_loss/shoulders/E9_db1/shoulder | advanced | 45 | shoulders | fat_loss | dumbbells | shoulder |  |
| 486 | 7 | pad beginner/60/endurance/glutes/E10_home/lower_back | beginner | 60 | glutes | endurance | dumbbells,resistance_bands(+1) | lower_back |  |
| 487 | 7 | pad intermediate/75/general_fitness/cardio/E11_cardio/wrist | intermediate | 75 | cardio | general_fitness | treadmill,rowing_machine(+2) | wrist |  |
| 488 | 7 | pad advanced/90/mobility/mobility/E12_bw_bands/ankle | advanced | 90 | mobility | mobility | resistance_bands | ankle |  |
| 489 | 7 | pad beginner/15/power/push/E13_TRX/hip | beginner | 15 | push | power | TRX bands,resistance_bands(+1) | hip |  |
| 490 | 7 | pad intermediate/20/athletic_performance/pull/E14_gym_60/elbow | intermediate | 20 | pull | athletic_performance | barbell,dumbbells(+26) | elbow |  |
| 491 | 7 | pad advanced/30/weight_loss/legs/E1_full/neck | advanced | 30 | legs | weight_loss | barbell,dumbbells(+13) | neck |  |
| 492 | 7 | pad beginner/40/muscle_tone/full_body/E2_bw/knee+shoulder | beginner | 40 | full_body | muscle_tone | [] | knee,shoulder |  |
| 493 | 7 | pad intermediate/45/strength/core/E3_db/knee+lower_back | intermediate | 45 | core | strength | dumbbells,bench(+1) | knee,lower_back |  |
| 494 | 7 | pad advanced/60/hypertrophy/upper/E4_kb/shoulder+wrist | advanced | 60 | upper | hypertrophy | kettlebell | shoulder,wrist |  |
| 495 | 7 | pad beginner/75/fat_loss/lower/E5_mach/knee+shoulder+lower_back | beginner | 75 | lower | fat_loss | cable_machine,leg_press_machine(+2) | knee,shoulder,lower_back |  |
| 496 | 7 | pad intermediate/90/endurance/arms/E6_bands/knee+shoulder+lower_back+wrist+ankle | intermediate | 90 | arms | endurance | resistance_bands | knee,shoulder,lower_back,wrist,ankle |  |
| 497 | 7 | pad advanced/15/general_fitness/shoulders/E7_no_bb/knee+shoulder+lower_back+wrist+ankle+hip+elbow | advanced | 15 | shoulders | general_fitness | dumbbells,cable_machine(+5) | knee,shoulder,lower_back,wrist,ankle,hip,elbow |  |
| 498 | 7 | pad beginner/20/mobility/glutes/E8_fw/none | beginner | 20 | glutes | mobility | barbell,dumbbells(+3) | - |  |
| 499 | 7 | pad intermediate/30/power/cardio/E9_db1/knee | intermediate | 30 | cardio | power | dumbbells | knee |  |
| 500 | 7 | pad advanced/40/athletic_performance/mobility/E10_home/shoulder | advanced | 40 | mobility | athletic_performance | dumbbells,resistance_bands(+1) | shoulder |  |

<!-- LIVE-RUN-STATUS — auto-updated by harness; do not edit -->
## 🔴 Live Run Status
_Run started 2026-05-09T12:03:54._ Updated as each scenario completes.

| # | Status | Label | Workout name | n_ex | latency_ms | error |
|---|---|---|---|---|---|---|
| 1 | ✅ | dur-sweep beginner/15min | Steady Gentle Muscle Flow | 3 | 26726 |  |
| 2 | ✅ | dur-sweep beginner/20min | Gentle Foundation Body Flow | 5 | 10469 |  |
| 3 | ✅ | dur-sweep beginner/30min | Gentle Rising Sun Flow | 5 | 9511 |  |
| 4 | ✅ | dur-sweep beginner/40min | Gentle Harmony Flow | 5 | 9623 |  |
| 5 | ✅ | dur-sweep beginner/45min | Gentle Peak Performance | 5 | 12676 |  |
| 6 | ✅ | dur-sweep beginner/60min | Gentle Giant Muscle Flow | 5 | 9781 |  |
| 7 | ✅ | dur-sweep beginner/75min | Gentle Peak Performance | 5 | 10508 |  |
| 8 | ✅ | dur-sweep beginner/90min | Ignite Explosive Peak Performance | 3 | 9427 |  |
| 9 | ✅ | dur-sweep intermediate/15min | Titan Steel Body Sculpt | 3 | 12212 |  |
| 10 | ✅ | dur-sweep intermediate/20min | Titan Sculpting Blast | 5 | 11797 |  |
| 11 | ✅ | dur-sweep intermediate/30min | Titan Sculpting Peak | 5 | 11696 |  |
| 12 | ✅ | dur-sweep intermediate/40min | Titan Sculpting Peak | 6 | 12402 |  |
| 13 | ✅ | dur-sweep intermediate/45min | Titan Physique Sculpt | 7 | 10973 |  |
| 14 | ✅ | dur-sweep intermediate/60min | Titan Sculpting Blast | 7 | 12255 |  |
| 15 | ✅ | dur-sweep intermediate/75min | Titan Savage Blast | 7 | 10408 |  |
| 16 | ✅ | dur-sweep intermediate/90min | Titan Unleashed Peak Performance | 3 | 12435 |  |
| 17 | ✅ | dur-sweep advanced/15min | Titan Savage Blast | 3 | 11959 |  |
| 18 | ✅ | dur-sweep advanced/20min | Savage Beast Body Blast | 5 | 11615 |  |
| 19 | ✅ | dur-sweep advanced/30min | Apex Predator Body Shock | 5 | 11421 |  |
| 20 | ✅ | dur-sweep advanced/40min | Apex Warrior Full Blast | 6 | 12595 |  |
| 21 | ✅ | dur-sweep advanced/45min | Apex Titan Full Body | 8 | 11496 |  |
| 22 | ✅ | dur-sweep advanced/60min | Titan Unleashed Peak Performance | 8 | 11475 |  |
| 23 | ✅ | dur-sweep advanced/75min | Apex Titan Full Burn | 8 | 12912 |  |
| 24 | ✅ | dur-sweep advanced/90min | Titan Forge Full Intensity | 6 | 12194 |  |
| 25 | ✅ | goal-sweep strength | Titan Full Body Core | 6 | 10197 |  |
| 26 | ✅ | goal-sweep hypertrophy | Apex Full Body Burn | 6 | 12194 |  |
| 27 | ✅ | goal-sweep fat_loss | Endurance Peak Flow | 6 | 11017 |  |
| 28 | ✅ | goal-sweep endurance | Apex Full Body Surge | 6 | 10432 |  |
| 29 | ✅ | goal-sweep general_fitness | Limitless Flow Full Body | 6 | 11014 |  |
| 30 | ✅ | goal-sweep mobility | Explosive Peak Power | 6 | 10530 |  |
| 31 | ✅ | goal-sweep power | Apex Performance Athletic Flow | 6 | 10655 |  |
| 32 | ✅ | goal-sweep athletic_performance | Rapid Fire Total Burn | 6 | 12199 |  |
| 33 | ✅ | goal-sweep weight_loss | Peak Performance Kinetic Flow | 6 | 10480 |  |
| 34 | ✅ | goal-sweep muscle_tone | Titan Push Precision | 6 | 12153 |  |
| 35 | ✅ | focus-sweep push | Athletic Peak Foundation | 5 | 10034 |  |
| 36 | ✅ | focus-sweep pull | Titan Leg Furnace | 6 | 11328 |  |
| 37 | ✅ | focus-sweep legs | Apex Beast Full Body | 6 | 11042 |  |
| 38 | ✅ | focus-sweep full_body | Absolute Core Apex | 5 | 12299 |  |
| 39 | ✅ | focus-sweep core | Apex Upper Body Fusion | 6 | 8611 |  |
| 40 | ✅ | focus-sweep upper | Titan Lower Body Peak | 6 | 10822 |  |
| 41 | ✅ | focus-sweep lower | Titan Sculpt Arm Blast | 3 | 12465 |  |
| 42 | ✅ | focus-sweep arms | Titan Sculpt Shoulder Peak | 6 | 11664 |  |
| 43 | ✅ | focus-sweep shoulders | Titan Glute Sculpting Session | 6 | 8918 |  |
| 44 | ✅ | focus-sweep glutes | Rapid Pulse Peak Performance | 6 | 9225 |  |
| 45 | ✅ | focus-sweep cardio | Apex Prime Body Flow | 6 | 11168 |  |
| 46 | ✅ | focus-sweep mobility | Titan Full Body Blast | 6 | 11889 |  |
| 47 | ✅ | equip-sweep E1_full | Total Body Kinetic Surge | 6 | 11122 |  |
| 48 | ✅ | equip-sweep E2_bw | Titan Total Body | 6 | 11010 |  |
| 49 | ✅ | equip-sweep E3_db | Kettlebell Titan Strength Circuit | 6 | 10973 |  |
| 50 | ✅ | equip-sweep E4_kb | Gentle Push Strength Flow | 3 | 10963 |  |
| 51 | ✅ | equip-sweep E5_mach | Gentle Flow Motion | 3 | 10252 |  |
| 52 | ✅ | equip-sweep E6_bands | Titan Peak Kinetic Flow | 6 | 11945 |  |
| 53 | ✅ | equip-sweep E7_no_bb | Titan Full Body Velocity | 6 | 11779 |  |
| 54 | ✅ | equip-sweep E8_fw | Titan Sculpting Peak Performance | 6 | 13065 |  |
| 55 | ✅ | equip-sweep E9_db1 | Titan Sculpting Session | 6 | 12338 |  |
| 56 | ✅ | equip-sweep E10_home | Steady Gentle Foundation | 3 | 13036 |  |
| 57 | ❌ | equip-sweep E11_cardio |  | 0 | 711 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 58 | ✅ | equip-sweep E12_bw_bands | Gentle Sculpt Shoulder Flow | 5 | 12658 |  |
| 59 | ✅ | equip-sweep E13_TRX | Absolute Peak Upper Sculpt | 8 | 11326 |  |
| 60 | ✅ | equip-sweep E14_gym_60 | Gentle Motion Vitality Flow | 3 | 11512 |  |
| 61 | ✅ | injury-sweep no-injury | Steady Gentle Muscle Flow | 3 | 12006 |  |
| 62 | ✅ | injury-sweep knee | Gentle Foundation Body Flow | 5 | 10623 |  |
| 63 | ✅ | injury-sweep shoulder | Gentle Rising Sun Flow | 5 | 10108 |  |
| 64 | ✅ | injury-sweep lower_back | Gentle Harmony Flow | 5 | 12784 |  |
| 65 | ✅ | injury-sweep wrist | Gentle Peak Performance | 5 | 10758 |  |
| 66 | ✅ | injury-sweep ankle | Gentle Giant Muscle Flow | 5 | 11162 |  |
| 67 | ✅ | injury-sweep hip | Gentle Peak Performance | 5 | 11699 |  |
| 68 | ✅ | injury-sweep elbow | Ignite Explosive Peak Performance | 3 | 10149 |  |
| 69 | ✅ | injury-sweep neck | Titan Steel Body Sculpt | 3 | 11586 |  |
| 70 | ✅ | injury-sweep knee+shoulder | Titan Sculpting Blast | 5 | 10651 |  |
| 71 | ✅ | injury-sweep knee+lower_back | Titan Sculpting Peak | 5 | 11360 |  |
| 72 | ✅ | injury-sweep shoulder+wrist | Titan Sculpting Peak | 6 | 11427 |  |
| 73 | ✅ | injury-sweep knee+shoulder+lower_back | Titan Physique Sculpt | 7 | 9734 |  |
| 74 | ✅ | injury-sweep knee+shoulder+lower_back+wrist+ankle | Titan Sculpting Blast | 7 | 10328 |  |
| 75 | ✅ | injury-sweep knee+shoulder+lower_back+wrist+ankle+hip+elbow | Titan Savage Blast | 7 | 11816 |  |
| 76 | ✅ | dur-range 15-30 | Titan Unleashed Peak Performance | 3 | 9893 |  |
| 77 | ✅ | dur-range 20-40 | Titan Savage Blast | 3 | 10984 |  |
| 78 | ✅ | dur-range 30-45 | Savage Beast Body Blast | 5 | 9621 |  |
| 79 | ✅ | dur-range 45-60 | Apex Predator Body Shock | 5 | 10682 |  |
| 80 | ✅ | dur-range 60-90 | Apex Warrior Full Blast | 6 | 12492 |  |
| 81 | ✅ | goal×focus strength/push | Apex Titan Full Body | 8 | 12381 |  |
| 82 | ✅ | goal×focus strength/pull | Titan Unleashed Peak Performance | 8 | 11428 |  |
| 83 | ✅ | goal×focus strength/legs | Apex Titan Full Burn | 8 | 10899 |  |
| 84 | ✅ | goal×focus hypertrophy/upper | Titan Forge Full Intensity | 6 | 11407 |  |
| 85 | ✅ | goal×focus hypertrophy/lower | Titan Full Body Core | 6 | 11941 |  |
| 86 | ✅ | goal×focus hypertrophy/arms | Apex Full Body Burn | 6 | 10893 |  |
| 87 | ✅ | goal×focus fat_loss/cardio | Endurance Peak Flow | 6 | 11186 |  |
| 88 | ✅ | goal×focus fat_loss/full_body | Apex Full Body Surge | 6 | 11378 |  |
| 89 | ✅ | goal×focus endurance/cardio | Limitless Flow Full Body | 6 | 10899 |  |
| 90 | ✅ | goal×focus endurance/lower | Explosive Peak Power | 6 | 10928 |  |
| 91 | ✅ | goal×focus mobility/mobility | Apex Performance Athletic Flow | 6 | 10794 |  |
| 92 | ✅ | goal×focus mobility/core | Rapid Fire Total Burn | 6 | 10524 |  |
| 93 | ✅ | goal×focus power/legs | Peak Performance Kinetic Flow | 6 | 11378 |  |
| 94 | ✅ | goal×focus power/full_body | Titan Push Precision | 6 | 11578 |  |
| 95 | ✅ | goal×focus athletic_performance/full_body | Athletic Peak Foundation | 5 | 12576 |  |
| 96 | ✅ | goal×focus athletic_performance/lower | Titan Leg Furnace | 6 | 10921 |  |
| 97 | ✅ | goal×focus weight_loss/cardio | Apex Beast Full Body | 6 | 10221 |  |
| 98 | ✅ | goal×focus weight_loss/upper | Absolute Core Apex | 5 | 9432 |  |
| 99 | ✅ | goal×focus muscle_tone/arms | Apex Upper Body Fusion | 6 | 10813 |  |
| 100 | ✅ | goal×focus muscle_tone/glutes | Titan Lower Body Peak | 6 | 8761 |  |
| 101 | ✅ | goal×focus general_fitness/full_body | Titan Sculpt Arm Blast | 3 | 10147 |  |
| 102 | ✅ | goal×focus general_fitness/core | Titan Sculpt Shoulder Peak | 6 | 8303 |  |
| 103 | ✅ | goal×focus strength/shoulders | Titan Glute Sculpting Session | 6 | 9942 |  |
| 104 | ✅ | goal×focus hypertrophy/shoulders | Rapid Pulse Peak Performance | 6 | 8775 |  |
| 105 | ✅ | goal×focus hypertrophy/glutes | Apex Prime Body Flow | 6 | 8994 |  |
| 106 | ✅ | goal×focus strength/core | Titan Full Body Blast | 6 | 8392 |  |
| 107 | ✅ | goal×focus endurance/full_body | Total Body Kinetic Surge | 6 | 12866 |  |
| 108 | ✅ | goal×focus power/upper | Titan Total Body | 6 | 9882 |  |
| 109 | ✅ | goal×focus athletic_performance/shoulders | Kettlebell Titan Strength Circuit | 6 | 9629 |  |
| 110 | ✅ | goal×focus muscle_tone/core | Gentle Push Strength Flow | 3 | 8375 |  |
| 111 | ✅ | matrix beginner/15/strength/push/E1_full | Gentle Flow Motion | 3 | 10352 |  |
| 112 | ✅ | matrix beginner/15/fat_loss/pull/E2_bw | Titan Peak Kinetic Flow | 6 | 9958 |  |
| 113 | ✅ | matrix beginner/15/general_fitness/legs/E3_db | Titan Full Body Velocity | 6 | 10860 |  |
| 114 | ✅ | matrix beginner/15/power/full_body/E4_kb | Titan Sculpting Peak Performance | 6 | 9851 |  |
| 115 | ✅ | matrix beginner/20/general_fitness/core/E5_mach | Titan Sculpting Session | 6 | 8398 |  |
| 116 | ✅ | matrix beginner/20/power/upper/E6_bands | Steady Gentle Foundation | 3 | 9620 |  |
| 117 | ✅ | matrix beginner/20/weight_loss/lower/E7_no_bb | Gentle Arm Sculpt Flow | 3 | 10468 |  |
| 118 | ✅ | matrix beginner/20/strength/arms/E8_fw | Gentle Sculpt Shoulder Flow | 5 | 9529 |  |
| 119 | ✅ | matrix beginner/30/weight_loss/shoulders/E9_db1 | Absolute Peak Upper Sculpt | 8 | 12610 |  |
| 120 | ✅ | matrix beginner/30/strength/glutes/E10_home | Gentle Motion Vitality Flow | 3 | 9892 |  |
| 121 | ✅ | matrix beginner/30/fat_loss/cardio/E11_cardio | Steady Gentle Muscle Flow | 3 | 9861 |  |
| 122 | ✅ | matrix beginner/30/general_fitness/mobility/E12_bw_bands | Gentle Foundation Body Flow | 5 | 10044 |  |
| 123 | ✅ | matrix beginner/40/fat_loss/push/E13_TRX | Gentle Rising Sun Flow | 5 | 9973 |  |
| 124 | ✅ | matrix beginner/40/general_fitness/pull/E14_gym_60 | Gentle Harmony Flow | 5 | 10149 |  |
| 125 | ✅ | matrix beginner/40/power/legs/E1_full | Gentle Peak Performance | 5 | 9774 |  |
| 126 | ✅ | matrix beginner/40/weight_loss/full_body/E2_bw | Gentle Giant Muscle Flow | 5 | 9811 |  |
| 127 | ✅ | matrix beginner/45/power/core/E3_db | Gentle Peak Performance | 5 | 8815 |  |
| 128 | ✅ | matrix beginner/45/weight_loss/upper/E4_kb | Ignite Explosive Peak Performance | 3 | 10345 |  |
| 129 | ✅ | matrix beginner/45/strength/lower/E5_mach | Titan Steel Body Sculpt | 3 | 10183 |  |
| 130 | ✅ | matrix beginner/45/fat_loss/arms/E6_bands | Titan Sculpting Blast | 5 | 8552 |  |
| 131 | ✅ | matrix beginner/60/strength/shoulders/E7_no_bb | Titan Sculpting Peak | 5 | 9553 |  |
| 132 | ✅ | matrix beginner/60/fat_loss/glutes/E8_fw | Titan Sculpting Peak | 6 | 9232 |  |
| 133 | ✅ | matrix beginner/60/general_fitness/cardio/E9_db1 | Titan Physique Sculpt | 7 | 9537 |  |
| 134 | ✅ | matrix beginner/60/power/mobility/E10_home | Titan Sculpting Blast | 7 | 10250 |  |
| 135 | ❌ | matrix beginner/75/general_fitness/push/E11_cardio |  | 0 | 724 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 136 | ✅ | matrix beginner/75/power/pull/E12_bw_bands | Titan Unleashed Peak Performance | 3 | 9614 |  |
| 137 | ✅ | matrix beginner/75/weight_loss/legs/E13_TRX | Titan Savage Blast | 3 | 9865 |  |
| 138 | ✅ | matrix beginner/75/strength/full_body/E14_gym_60 | Savage Beast Body Blast | 5 | 10039 |  |
| 139 | ✅ | matrix beginner/90/weight_loss/core/E1_full | Apex Predator Body Shock | 5 | 9950 |  |
| 140 | ✅ | matrix beginner/90/strength/upper/E2_bw | Apex Warrior Full Blast | 6 | 10036 |  |
| 141 | ✅ | matrix beginner/90/fat_loss/lower/E3_db | Apex Titan Full Body | 8 | 9851 |  |
| 142 | ✅ | matrix beginner/90/general_fitness/arms/E4_kb | Titan Unleashed Peak Performance | 8 | 9604 |  |
| 143 | ✅ | matrix intermediate/15/fat_loss/shoulders/E5_mach | Apex Titan Full Burn | 8 | 9048 |  |
| 144 | ✅ | matrix intermediate/15/general_fitness/glutes/E6_bands | Titan Forge Full Intensity | 6 | 9084 |  |
| 145 | ✅ | matrix intermediate/15/power/cardio/E7_no_bb | Titan Full Body Core | 6 | 9592 |  |
| 146 | ✅ | matrix intermediate/15/weight_loss/mobility/E8_fw | Apex Full Body Burn | 6 | 10853 |  |
| 147 | ✅ | matrix intermediate/20/power/push/E9_db1 | Endurance Peak Flow | 6 | 10487 |  |
| 148 | ✅ | matrix intermediate/20/weight_loss/pull/E10_home | Apex Full Body Surge | 6 | 10607 |  |
| 149 | ❌ | matrix intermediate/20/strength/legs/E11_cardio |  | 0 | 612 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 150 | ✅ | matrix intermediate/20/fat_loss/full_body/E12_bw_bands | Explosive Peak Power | 6 | 11538 |  |
| 151 | ✅ | matrix intermediate/30/strength/core/E13_TRX | Apex Performance Athletic Flow | 6 | 8311 |  |
| 152 | ✅ | matrix intermediate/30/fat_loss/upper/E14_gym_60 | Rapid Fire Total Burn | 6 | 10637 |  |
| 153 | ✅ | matrix intermediate/30/general_fitness/lower/E1_full | Peak Performance Kinetic Flow | 6 | 11991 |  |
| 154 | ✅ | matrix intermediate/30/power/arms/E2_bw | Titan Push Precision | 6 | 10560 |  |
| 155 | ✅ | matrix intermediate/40/general_fitness/shoulders/E3_db | Athletic Peak Foundation | 5 | 10700 |  |
| 156 | ✅ | matrix intermediate/40/power/glutes/E4_kb | Titan Leg Furnace | 6 | 8235 |  |
| 157 | ✅ | matrix intermediate/40/weight_loss/cardio/E5_mach | Apex Beast Full Body | 6 | 10164 |  |
| 158 | ✅ | matrix intermediate/40/strength/mobility/E6_bands | Absolute Core Apex | 5 | 11830 |  |
| 159 | ✅ | matrix intermediate/45/weight_loss/push/E7_no_bb | Apex Upper Body Fusion | 6 | 11828 |  |
| 160 | ✅ | matrix intermediate/45/strength/pull/E8_fw | Titan Lower Body Peak | 6 | 11214 |  |
| 161 | ✅ | matrix intermediate/45/fat_loss/legs/E9_db1 | Titan Sculpt Arm Blast | 3 | 10656 |  |
| 162 | ✅ | matrix intermediate/45/general_fitness/full_body/E10_home | Titan Sculpt Shoulder Peak | 6 | 10740 |  |
| 163 | ❌ | matrix intermediate/60/fat_loss/core/E11_cardio |  | 0 | 589 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 164 | ✅ | matrix intermediate/60/general_fitness/upper/E12_bw_bands | Rapid Pulse Peak Performance | 6 | 10880 |  |
| 165 | ✅ | matrix intermediate/60/power/lower/E13_TRX | Apex Prime Body Flow | 6 | 11555 |  |
| 166 | ✅ | matrix intermediate/60/weight_loss/arms/E14_gym_60 | Titan Full Body Blast | 6 | 11226 |  |
| 167 | ✅ | matrix intermediate/75/power/shoulders/E1_full | Total Body Kinetic Surge | 6 | 9667 |  |
| 168 | ✅ | matrix intermediate/75/weight_loss/glutes/E2_bw | Titan Total Body | 6 | 9927 |  |
| 169 | ✅ | matrix intermediate/75/strength/cardio/E3_db | Kettlebell Titan Strength Circuit | 6 | 10380 |  |
| 170 | ✅ | matrix intermediate/75/fat_loss/mobility/E4_kb | Gentle Push Strength Flow | 3 | 11933 |  |
| 171 | ✅ | matrix intermediate/90/strength/push/E5_mach | Gentle Flow Motion | 3 | 9451 |  |
| 172 | ✅ | matrix intermediate/90/fat_loss/pull/E6_bands | Titan Peak Kinetic Flow | 6 | 11903 |  |
| 173 | ✅ | matrix intermediate/90/general_fitness/legs/E7_no_bb | Titan Full Body Velocity | 6 | 11270 |  |
| 174 | ✅ | matrix intermediate/90/power/full_body/E8_fw | Titan Sculpting Peak Performance | 6 | 12292 |  |
| 175 | ✅ | matrix advanced/15/general_fitness/core/E9_db1 | Titan Sculpting Session | 6 | 8724 |  |
| 176 | ✅ | matrix advanced/15/power/upper/E10_home | Steady Gentle Foundation | 3 | 11056 |  |
| 177 | ❌ | matrix advanced/15/weight_loss/lower/E11_cardio |  | 0 | 536 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 178 | ✅ | matrix advanced/15/strength/arms/E12_bw_bands | Gentle Sculpt Shoulder Flow | 5 | 10970 |  |
| 179 | ✅ | matrix advanced/20/weight_loss/shoulders/E13_TRX | Absolute Peak Upper Sculpt | 8 | 9664 |  |
| 180 | ✅ | matrix advanced/20/strength/glutes/E14_gym_60 | Gentle Motion Vitality Flow | 3 | 9814 |  |
| 181 | ✅ | matrix advanced/20/fat_loss/cardio/E1_full | Steady Gentle Muscle Flow | 3 | 11795 |  |
| 182 | ✅ | matrix advanced/20/general_fitness/mobility/E2_bw | Gentle Foundation Body Flow | 5 | 12460 |  |
| 183 | ✅ | matrix advanced/30/fat_loss/push/E3_db | Gentle Rising Sun Flow | 5 | 9046 |  |
| 184 | ✅ | matrix advanced/30/general_fitness/pull/E4_kb | Gentle Harmony Flow | 5 | 11869 |  |
| 185 | ✅ | matrix advanced/30/power/legs/E5_mach | Gentle Peak Performance | 5 | 10794 |  |
| 186 | ✅ | matrix advanced/30/weight_loss/full_body/E6_bands | Gentle Giant Muscle Flow | 5 | 12871 |  |
| 187 | ✅ | matrix advanced/40/power/core/E7_no_bb | Gentle Peak Performance | 5 | 8964 |  |
| 188 | ✅ | matrix advanced/40/weight_loss/upper/E8_fw | Ignite Explosive Peak Performance | 3 | 11376 |  |
| 189 | ✅ | matrix advanced/40/strength/lower/E9_db1 | Titan Steel Body Sculpt | 3 | 11492 |  |
| 190 | ✅ | matrix advanced/40/fat_loss/arms/E10_home | Titan Sculpting Blast | 5 | 10727 |  |
| 191 | ❌ | matrix advanced/45/strength/shoulders/E11_cardio |  | 0 | 748 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 192 | ✅ | matrix advanced/45/fat_loss/glutes/E12_bw_bands | Titan Sculpting Peak | 6 | 8304 |  |
| 193 | ✅ | matrix advanced/45/general_fitness/cardio/E13_TRX | Titan Physique Sculpt | 7 | 10785 |  |
| 194 | ✅ | matrix advanced/45/power/mobility/E14_gym_60 | Titan Sculpting Blast | 7 | 11452 |  |
| 195 | ✅ | matrix advanced/60/general_fitness/push/E1_full | Titan Savage Blast | 7 | 10568 |  |
| 196 | ✅ | matrix advanced/60/power/pull/E2_bw | Titan Unleashed Peak Performance | 3 | 7995 |  |
| 197 | ✅ | matrix advanced/60/weight_loss/legs/E3_db | Titan Savage Blast | 3 | 11942 |  |
| 198 | ✅ | matrix advanced/60/strength/full_body/E4_kb | Savage Beast Body Blast | 5 | 11945 |  |
| 199 | ✅ | matrix advanced/75/weight_loss/core/E5_mach | Apex Predator Body Shock | 5 | 8843 |  |
| 200 | ✅ | matrix advanced/75/strength/upper/E6_bands | Apex Warrior Full Blast | 6 | 12392 |  |
| 201 | ✅ | matrix advanced/75/fat_loss/lower/E7_no_bb | Apex Titan Full Body | 8 | 10689 |  |
| 202 | ✅ | matrix advanced/75/general_fitness/arms/E8_fw | Titan Unleashed Peak Performance | 8 | 13351 |  |
| 203 | ✅ | matrix advanced/90/fat_loss/shoulders/E9_db1 | Apex Titan Full Burn | 8 | 10357 |  |
| 204 | ✅ | matrix advanced/90/general_fitness/glutes/E10_home | Titan Forge Full Intensity | 6 | 9955 |  |
| 205 | ✅ | matrix advanced/90/power/cardio/E11_cardio | Titan Full Body Core | 6 | 10515 |  |
| 206 | ✅ | matrix advanced/90/weight_loss/mobility/E12_bw_bands | Apex Full Body Burn | 6 | 10815 |  |
| 207 | ✅ | comeback 0d + intensity easy | Endurance Peak Flow | 6 | 9954 |  |
| 208 | ✅ | comeback 0d + intensity medium | Apex Full Body Surge | 6 | 12655 |  |
| 209 | ✅ | comeback 0d + intensity hard | Limitless Flow Full Body | 6 | 10252 |  |
| 210 | ✅ | comeback 0d + intensity hell | Explosive Peak Power | 6 | 10340 |  |
| 211 | ✅ | comeback 7d + intensity easy | Apex Performance Athletic Flow | 6 | 11606 |  |
| 212 | ✅ | comeback 7d + intensity medium | Rapid Fire Total Burn | 6 | 11076 |  |
| 213 | ✅ | comeback 7d + intensity hard | Peak Performance Kinetic Flow | 6 | 10743 |  |
| 214 | ✅ | comeback 7d + intensity hell | Titan Push Precision | 6 | 11239 |  |
| 215 | ✅ | comeback 14d + intensity easy | Athletic Peak Foundation | 5 | 10500 |  |
| 216 | ✅ | comeback 14d + intensity medium | Titan Leg Furnace | 6 | 11937 |  |
| 217 | ✅ | comeback 14d + intensity hard | Apex Beast Full Body | 6 | 10180 |  |
| 218 | ✅ | comeback 14d + intensity hell | Absolute Core Apex | 5 | 11272 |  |
| 219 | ✅ | comeback 30d + intensity easy | Apex Upper Body Fusion | 6 | 10759 |  |
| 220 | ✅ | comeback 30d + intensity medium | Titan Lower Body Peak | 6 | 11439 |  |
| 221 | ✅ | comeback 30d + intensity hard | Titan Sculpt Arm Blast | 3 | 12322 |  |
| 222 | ✅ | comeback 30d + intensity hell | Titan Sculpt Shoulder Peak | 6 | 11229 |  |
| 223 | ✅ | comeback 60d + intensity easy | Titan Glute Sculpting Session | 6 | 10404 |  |
| 224 | ✅ | comeback 60d + intensity medium | Rapid Pulse Peak Performance | 6 | 11318 |  |
| 225 | ✅ | comeback 60d + intensity hard | Apex Prime Body Flow | 6 | 11100 |  |
| 226 | ✅ | comeback 60d + intensity hell | Titan Full Body Blast | 6 | 10564 |  |
| 227 | ✅ | comeback 90d + intensity easy | Total Body Kinetic Surge | 6 | 10963 |  |
| 228 | ✅ | comeback 90d + intensity medium | Titan Total Body | 6 | 11548 |  |
| 229 | ✅ | comeback 90d + intensity hard | Kettlebell Titan Strength Circuit | 6 | 10495 |  |
| 230 | ✅ | comeback 90d + intensity hell | Gentle Push Strength Flow | 3 | 10876 |  |
| 231 | ✅ | comeback 180d + intensity easy | Gentle Flow Motion | 3 | 10708 |  |
| 232 | ✅ | comeback 180d + intensity medium | Titan Peak Kinetic Flow | 6 | 11461 |  |
| 233 | ❌ | comeback 180d + intensity hard |  | 0 | 377 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 234 | ❌ | comeback 180d + intensity hell |  | 0 | 528 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 235 | ❌ | custom_program: none |  | 0 | 457 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 236 | ❌ | custom_program: Train for HYROX in 12 weeks — week 4 |  | 0 | 496 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 237 | ❌ | custom_program: Marathon training, week 8 of 16, easy ru |  | 0 | 622 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 238 | ❌ | custom_program: Bodybuilding show prep, 8 weeks out, pea |  | 0 | 505 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 233 | ✅ | comeback 180d + intensity hard | Titan Full Body Velocity | 6 | 25244 |  |
| 234 | ✅ | comeback 180d + intensity hell | Titan Sculpting Peak Performance | 6 | 13522 |  |
| 235 | ✅ | custom_program: none | Titan Sculpting Session | 6 | 11654 |  |
| 236 | ✅ | custom_program: Train for HYROX in 12 weeks — week 4 | Steady Gentle Foundation | 3 | 12004 |  |
| 237 | ✅ | custom_program: Marathon training, week 8 of 16, easy ru | Gentle Arm Sculpt Flow | 3 | 12084 |  |
| 238 | ✅ | custom_program: Bodybuilding show prep, 8 weeks out, pea | Gentle Sculpt Shoulder Flow | 5 | 10780 |  |
| 239 | ✅ | custom_program: Powerlifting meet in 6 weeks — squat day | Absolute Peak Upper Sculpt | 8 | 10343 |  |
| 240 | ✅ | custom_program: Calisthenics-only, working toward muscle | Gentle Motion Vitality Flow | 3 | 10552 |  |
| 241 | ✅ | custom_program: Crossfit Open prep — varied modal domain | Steady Gentle Muscle Flow | 3 | 11692 |  |
| 242 | ✅ | custom_program: Athlete return-to-sport rehab phase 2 | Gentle Foundation Body Flow | 5 | 11781 |  |
| 243 | ✅ | custom_program: 12-week deload after marathon — rebuild  | Gentle Rising Sun Flow | 5 | 12154 |  |
| 244 | ✅ | custom_program: Morning routine before work — quick ener | Gentle Harmony Flow | 5 | 12898 |  |
| 245 | ✅ | exclude=none | Gentle Peak Performance | 5 | 13151 |  |
| 246 | ✅ | exclude=bench press,barbell squat,dead | Gentle Giant Muscle Flow | 5 | 10864 |  |
| 247 | ✅ | exclude=pull-up,chin-up,muscle-up | Gentle Peak Performance | 5 | 11384 |  |
| 248 | ✅ | exclude=burpee,jump squat,box jump | Ignite Explosive Peak Performance | 3 | 11716 |  |
| 249 | ✅ | exclude=plank,side plank,dead bug | Titan Steel Body Sculpt | 3 | 11000 |  |
| 250 | ✅ | exclude=overhead press,snatch,clean an | Titan Sculpting Blast | 5 | 11095 |  |
| 251 | ✅ | adjacent=none | Titan Sculpting Peak | 5 | 11735 |  |
| 252 | ✅ | adjacent=bench press,squat,deadlift,pul | Titan Sculpting Peak | 6 | 11818 |  |
| 253 | ✅ | adjacent=barbell row,pull-up,lat pulldo | Titan Physique Sculpt | 7 | 10885 |  |
| 254 | ✅ | adjacent=overhead press,lateral raise,f | Titan Sculpting Blast | 7 | 11435 |  |
| 255 | ✅ | adjacent=leg press,lunges,step-ups | Titan Savage Blast | 7 | 12140 |  |
| 256 | ✅ | adjacent=bicep curl,hammer curl,preache | Titan Unleashed Peak Performance | 3 | 11517 |  |
| 257 | ✅ | batch_offset=0 | Titan Savage Blast | 3 | 10881 |  |
| 258 | ✅ | batch_offset=1 | Savage Beast Body Blast | 5 | 11074 |  |
| 259 | ✅ | batch_offset=2 | Apex Predator Body Shock | 5 | 10939 |  |
| 260 | ✅ | batch_offset=3 | Apex Warrior Full Blast | 6 | 11919 |  |
| 261 | ✅ | batch_offset=5 | Apex Titan Full Body | 8 | 11345 |  |
| 262 | ✅ | batch_offset=7 | Titan Unleashed Peak Performance | 8 | 11266 |  |
| 263 | ✅ | batch_offset=10 | Apex Titan Full Burn | 8 | 11857 |  |
| 264 | ✅ | date today | Titan Steel Kinetic Flow | 6 | 10403 |  |
| 265 | ✅ | date +1d | Gentle Motion Vitality Flow | 3 | 10621 |  |
| 266 | ✅ | date +2d | Steady Gentle Muscle Flow | 3 | 12839 |  |
| 267 | ✅ | date +3d | Gentle Foundation Body Flow | 5 | 10926 |  |
| 268 | ✅ | date +5d | Gentle Harmony Flow | 5 | 10320 |  |
| 269 | ✅ | date +7d | Gentle Giant Muscle Flow | 5 | 11936 |  |
| 270 | ✅ | date +10d | Titan Steel Body Sculpt | 3 | 11672 |  |
| 271 | ✅ | date +14d | Titan Physique Sculpt | 7 | 12362 |  |
| 272 | ✅ | date +21d | Apex Warrior Full Blast | 6 | 11095 |  |
| 273 | ✅ | date +30d | Limitless Flow Full Body | 6 | 12769 |  |
| 274 | ✅ | date +45d | Rapid Pulse Peak Performance | 6 | 10515 |  |
| 275 | ✅ | date +60d | Absolute Peak Upper Sculpt | 8 | 10148 |  |
| 276 | ✅ | date +90d | Apex Predator Full Body Surge | 6 | 11502 |  |
| 277 | ✅ | date +120d | Titan Full Body Ascension | 6 | 12656 |  |
| 278 | ✅ | date +180d | Titan Full Body Ignition | 6 | 14143 |  |
| 279 | ✅ | wt=auto/focus=push | Apex Upper Body Fusion | 6 | 12613 |  |
| 280 | ✅ | wt=auto/focus=pull | Titan Lower Body Peak | 6 | 10762 |  |
| 281 | ✅ | wt=auto/focus=legs | Titan Sculpt Arm Blast | 3 | 10495 |  |
| 282 | ✅ | wt=auto/focus=full_body | Titan Sculpt Shoulder Peak | 6 | 10739 |  |
| 283 | ✅ | wt=auto/focus=core | Titan Glute Sculpting Session | 6 | 8510 |  |
| 284 | ✅ | wt=auto/focus=cardio | Rapid Pulse Peak Performance | 6 | 10920 |  |
| 285 | ✅ | wt=auto/focus=mobility | Apex Prime Body Flow | 6 | 12135 |  |
| 286 | ✅ | wt=strength/focus=push | Titan Full Body Blast | 6 | 11251 |  |
| 287 | ✅ | wt=strength/focus=pull | Total Body Kinetic Surge | 6 | 11768 |  |
| 288 | ✅ | wt=strength/focus=legs | Titan Total Body | 6 | 11579 |  |
| 289 | ✅ | wt=strength/focus=full_body | Kettlebell Titan Strength Circuit | 6 | 12215 |  |
| 290 | ✅ | wt=strength/focus=core | Gentle Push Strength Flow | 3 | 8556 |  |
| 291 | ✅ | wt=strength/focus=cardio | Gentle Flow Motion | 3 | 12303 |  |
| 292 | ✅ | wt=strength/focus=mobility | Titan Peak Kinetic Flow | 6 | 12112 |  |
| 293 | ✅ | wt=hypertrophy/focus=push | Titan Full Body Velocity | 6 | 11776 |  |
| 294 | ✅ | wt=hypertrophy/focus=pull | Titan Sculpting Peak Performance | 6 | 10357 |  |
| 295 | ✅ | wt=hypertrophy/focus=legs | Titan Sculpting Session | 6 | 10438 |  |
| 296 | ✅ | wt=hypertrophy/focus=full_body | Steady Gentle Foundation | 3 | 16218 |  |
| 297 | ✅ | wt=hypertrophy/focus=core | Gentle Arm Sculpt Flow | 3 | 9843 |  |
| 298 | ✅ | wt=hypertrophy/focus=cardio | Gentle Sculpt Shoulder Flow | 5 | 11815 |  |
| 299 | ✅ | wt=hypertrophy/focus=mobility | Absolute Peak Upper Sculpt | 8 | 11461 |  |
| 300 | ✅ | wt=cardio/focus=push | Gentle Motion Vitality Flow | 3 | 11847 |  |
| 301 | ✅ | wt=cardio/focus=pull | Steady Gentle Muscle Flow | 3 | 11049 |  |
| 302 | ✅ | wt=cardio/focus=legs | Gentle Foundation Body Flow | 5 | 11587 |  |
| 303 | ✅ | wt=cardio/focus=full_body | Gentle Rising Sun Flow | 5 | 13622 |  |
| 304 | ✅ | wt=cardio/focus=core | Gentle Harmony Flow | 5 | 9089 |  |
| 305 | ✅ | wt=cardio/focus=cardio | Gentle Peak Performance | 5 | 11314 |  |
| 306 | ✅ | wt=cardio/focus=mobility | Gentle Giant Muscle Flow | 5 | 10911 |  |
| 307 | ✅ | wt=hiit/focus=push | Gentle Peak Performance | 5 | 11830 |  |
| 308 | ✅ | wt=hiit/focus=pull | Ignite Explosive Peak Performance | 3 | 11360 |  |
| 309 | ✅ | wt=hiit/focus=legs | Titan Steel Body Sculpt | 3 | 10699 |  |
| 310 | ✅ | wt=hiit/focus=full_body | Titan Sculpting Blast | 5 | 12269 |  |
| 311 | ✅ | wt=hiit/focus=core | Titan Sculpting Peak | 5 | 9332 |  |
| 312 | ✅ | wt=hiit/focus=cardio | Titan Sculpting Peak | 6 | 10945 |  |
| 313 | ✅ | wt=hiit/focus=mobility | Titan Physique Sculpt | 7 | 10650 |  |
| 314 | ✅ | wt=mobility/focus=push | Titan Sculpting Blast | 7 | 13123 |  |
| 315 | ✅ | wt=mobility/focus=pull | Titan Savage Blast | 7 | 12530 |  |
| 316 | ✅ | wt=mobility/focus=legs | Titan Unleashed Peak Performance | 3 | 10693 |  |
| 317 | ✅ | wt=mobility/focus=full_body | Titan Savage Blast | 3 | 10748 |  |
| 318 | ✅ | wt=mobility/focus=core | Savage Beast Body Blast | 5 | 9020 |  |
| 319 | ✅ | wt=mobility/focus=cardio | Apex Predator Body Shock | 5 | 12083 |  |
| 320 | ✅ | wt=mobility/focus=mobility | Apex Warrior Full Blast | 6 | 11544 |  |
| 321 | ✅ | wt=recovery/focus=push | Apex Titan Full Body | 8 | 11177 |  |
| 322 | ✅ | wt=recovery/focus=pull | Titan Unleashed Peak Performance | 8 | 11968 |  |
| 323 | ✅ | wt=recovery/focus=legs | Apex Titan Full Burn | 8 | 9798 |  |
| 324 | ✅ | wt=recovery/focus=full_body | Titan Forge Full Intensity | 6 | 11893 |  |
| 325 | ✅ | wt=recovery/focus=core | Titan Full Body Core | 6 | 8476 |  |
| 326 | ✅ | wt=recovery/focus=cardio | Apex Full Body Burn | 6 | 10899 |  |
| 327 | ✅ | wt=recovery/focus=mobility | Endurance Peak Flow | 6 | 12187 |  |
| 328 | ✅ | max constraint stress | Apex Full Body Surge | 6 | 9451 |  |
| 329 | ✅ | lowest demand at top | Limitless Flow Full Body | 6 | 11952 |  |
| 330 | ✅ | empty goals + bodyweight | Explosive Peak Power | 6 | 10462 |  |
| 331 | ✅ | prompt bloat 12 focus areas | Apex Performance Athletic Flow | 6 | 11068 |  |
| 332 | ✅ | composite real-world | Rapid Fire Total Burn | 6 | 11309 |  |
| 333 | ✅ | beginner+hell+bodyweight | Peak Performance Kinetic Flow | 6 | 9606 |  |
| 334 | ✅ | advanced+easy+15min | Titan Push Precision | 6 | 13017 |  |
| 335 | ✅ | 90min beginner | Athletic Peak Foundation | 5 | 9367 |  |
| 336 | ✅ | 5min express | Titan Leg Furnace | 6 | 11662 |  |
| 337 | ✅ | all-7 injuries + bodyweight | Apex Beast Full Body | 6 | 9888 |  |
| 338 | ✅ | powerlifting prep | Absolute Core Apex | 5 | 9388 |  |
| 339 | ✅ | marathon training | Apex Upper Body Fusion | 6 | 10846 |  |
| 340 | ✅ | calisthenics | Titan Lower Body Peak | 6 | 11635 |  |
| 341 | ✅ | crossfit varied | Titan Sculpt Arm Blast | 3 | 15997 |  |
| 342 | ✅ | senior with hell intent | Titan Sculpt Shoulder Peak | 6 | 10704 |  |
| 343 | ✅ | multi-goal mobility+strength | Titan Glute Sculpting Session | 6 | 11881 |  |
| 344 | ✅ | multi-focus push+pull+core | Rapid Pulse Peak Performance | 6 | 11098 |  |
| 345 | ✅ | range 15-30 strength | Apex Prime Body Flow | 6 | 10907 |  |
| 346 | ✅ | range 60-90 hypertrophy | Titan Full Body Blast | 6 | 13917 |  |
| 347 | ✅ | single dumbbell only | Total Body Kinetic Surge | 6 | 11921 |  |
| 348 | ❌ | cardio-machines + strength focus |  | 0 | 621 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 349 | ✅ | 60min bodyweight legs | Kettlebell Titan Strength Circuit | 6 | 10026 |  |
| 350 | ✅ | bands only + powerlifting | Gentle Push Strength Flow | 3 | 12373 |  |
| 351 | ✅ | 60-item gym + mobility | Gentle Flow Motion | 3 | 11160 |  |
| 352 | ✅ | TRX + strength | Titan Peak Kinetic Flow | 6 | 11306 |  |
| 353 | ✅ | excl + adj combined | Titan Full Body Velocity | 6 | 12422 |  |
| 354 | ✅ | variety #1 | Titan Sculpting Peak Performance | 6 | 11205 |  |
| 355 | ✅ | variety #2 | Titan Sculpting Session | 6 | 11034 |  |
| 356 | ✅ | variety #3 | Steady Gentle Foundation | 3 | 11430 |  |
| 357 | ✅ | KB power advanced | Gentle Arm Sculpt Flow | 3 | 11513 |  |
| 358 | ✅ | rehab ankle + cardio focus | Gentle Sculpt Shoulder Flow | 5 | 9669 |  |
| 359 | ✅ | athletic_perf + knee | Absolute Peak Upper Sculpt | 8 | 11654 |  |
| 360 | ✅ | beginner KB only | Gentle Motion Vitality Flow | 3 | 11399 |  |
| 361 | ✅ | senior 75+ proxy | Steady Gentle Muscle Flow | 3 | 10034 |  |
| 362 | ✅ | adv + mobility + 90min | Gentle Foundation Body Flow | 5 | 10866 |  |
| 363 | ✅ | multi-injury + cardio | Gentle Rising Sun Flow | 5 | 10353 |  |
| 364 | ✅ | range 45-60 full body | Gentle Harmony Flow | 5 | 9852 |  |
| 365 | ✅ | range 30-45 push | Gentle Peak Performance | 5 | 10452 |  |
| 366 | ✅ | HIIT + cardio + KB | Gentle Giant Muscle Flow | 5 | 10693 |  |
| 367 | ✅ | recovery + bands | Gentle Peak Performance | 5 | 10605 |  |
| 368 | ✅ | advanced 90min strength | Ignite Explosive Peak Performance | 3 | 14829 |  |
| 369 | ✅ | bodyweight cardio | Titan Steel Body Sculpt | 3 | 10705 |  |
| 370 | ✅ | glutes focus intermediate | Titan Sculpting Blast | 5 | 9435 |  |
| 371 | ✅ | arms + dumbbells | Titan Sculpting Peak | 5 | 11684 |  |
| 372 | ✅ | shoulders + advanced | Titan Sculpting Peak | 6 | 10760 |  |
| 373 | ✅ | progressive overload sanity | Titan Physique Sculpt | 7 | 9858 |  |
| 374 | ✅ | 75min endurance run | Titan Sculpting Blast | 7 | 11178 |  |
| 375 | ✅ | big-3 powerlift | Titan Savage Blast | 7 | 10942 |  |
| 376 | ✅ | yoga style mobility | Titan Unleashed Peak Performance | 3 | 10157 |  |
| 377 | ✅ | union all goals 60min | Titan Savage Blast | 3 | 10972 |  |
| 378 | ✅ | pad beginner/15/strength/push/E1_full/inj=knee | Savage Beast Body Blast | 5 | 9460 |  |
| 379 | ✅ | pad intermediate/20/hypertrophy/pull/E2_bw/inj=shoulder | Apex Predator Body Shock | 5 | 13356 |  |
| 380 | ✅ | pad advanced/30/fat_loss/legs/E3_db/inj=lower_back | Apex Warrior Full Blast | 6 | 15500 |  |
| 381 | ✅ | pad beginner/40/endurance/full_body/E4_kb/inj=wrist | Apex Titan Full Body | 8 | 10236 |  |
| 382 | ✅ | pad intermediate/45/general_fitness/core/E5_mach/inj=ankle | Titan Unleashed Peak Performance | 8 | 8522 |  |
| 383 | ✅ | pad advanced/60/mobility/upper/E6_bands/inj=hip | Apex Titan Full Burn | 8 | 12117 |  |
| 384 | ✅ | pad beginner/75/power/lower/E7_no_bb/inj=elbow | Titan Forge Full Intensity | 6 | 10781 |  |
| 385 | ✅ | pad intermediate/90/athletic_performance/arms/E8_fw/inj=neck | Titan Full Body Core | 6 | 11151 |  |
| 386 | ✅ | pad advanced/15/weight_loss/shoulders/E9_db1/inj=knee+should | Apex Full Body Burn | 6 | 10572 |  |
| 387 | ✅ | pad beginner/20/muscle_tone/glutes/E10_home/inj=knee+lower_b | Endurance Peak Flow | 6 | 11476 |  |
| 388 | ✅ | pad intermediate/30/strength/cardio/E11_cardio/inj=shoulder+ | Apex Full Body Surge | 6 | 10306 |  |
| 389 | ✅ | pad advanced/40/hypertrophy/mobility/E12_bw_bands/inj=knee+s | Limitless Flow Full Body | 6 | 11101 |  |
| 390 | ✅ | pad beginner/45/fat_loss/push/E13_TRX/inj=knee+shoulder+lowe | Explosive Peak Power | 6 | 9576 |  |
| 391 | ✅ | pad intermediate/60/endurance/pull/E14_gym_60/inj=knee+shoul | Apex Performance Athletic Flow | 6 | 10827 |  |
| 392 | ✅ | pad advanced/75/general_fitness/legs/E1_full/inj=knee | Rapid Fire Total Burn | 6 | 9147 |  |
| 393 | ✅ | pad beginner/90/mobility/full_body/E2_bw/inj=shoulder | Peak Performance Kinetic Flow | 6 | 9487 |  |
| 394 | ✅ | pad intermediate/15/power/core/E3_db/inj=lower_back | Titan Push Precision | 6 | 11209 |  |
| 395 | ✅ | pad advanced/20/athletic_performance/upper/E4_kb/inj=wrist | Athletic Peak Foundation | 5 | 12162 |  |
| 396 | ✅ | pad beginner/30/weight_loss/lower/E5_mach/inj=ankle | Titan Leg Furnace | 6 | 9520 |  |
| 397 | ✅ | pad intermediate/40/muscle_tone/arms/E6_bands/inj=hip | Apex Beast Full Body | 6 | 10289 |  |
| 398 | ✅ | pad advanced/45/strength/shoulders/E7_no_bb/inj=elbow | Absolute Core Apex | 5 | 10752 |  |
| 399 | ✅ | pad beginner/60/hypertrophy/glutes/E8_fw/inj=neck | Apex Upper Body Fusion | 6 | 9687 |  |
| 400 | ✅ | pad intermediate/75/fat_loss/cardio/E9_db1/inj=knee+shoulder | Titan Lower Body Peak | 6 | 10631 |  |
| 401 | ✅ | pad advanced/90/endurance/mobility/E10_home/inj=knee+lower_b | Titan Sculpt Arm Blast | 3 | 11748 |  |
| 402 | ❌ | pad beginner/15/general_fitness/push/E11_cardio/inj=shoulder |  | 0 | 568 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 403 | ✅ | pad intermediate/20/mobility/pull/E12_bw_bands/inj=knee+shou | Titan Glute Sculpting Session | 6 | 11502 |  |
| 404 | ✅ | pad advanced/30/power/legs/E13_TRX/inj=knee+shoulder+lower_b | Rapid Pulse Peak Performance | 6 | 11703 |  |
| 405 | ✅ | pad beginner/40/athletic_performance/full_body/E14_gym_60/in | Apex Prime Body Flow | 6 | 10357 |  |
| 406 | ✅ | pad intermediate/45/weight_loss/core/E1_full/inj=knee | Titan Full Body Blast | 6 | 10611 |  |
| 407 | ✅ | pad advanced/60/muscle_tone/upper/E2_bw/inj=shoulder | Total Body Kinetic Surge | 6 | 10546 |  |
| 408 | ✅ | pad beginner/75/strength/lower/E3_db/inj=lower_back | Titan Total Body | 6 | 9757 |  |
| 409 | ✅ | pad intermediate/90/hypertrophy/arms/E4_kb/inj=wrist | Kettlebell Titan Strength Circuit | 6 | 11152 |  |
| 410 | ✅ | pad advanced/15/fat_loss/shoulders/E5_mach/inj=ankle | Gentle Push Strength Flow | 3 | 8781 |  |
| 411 | ✅ | pad beginner/20/endurance/glutes/E6_bands/inj=hip | Gentle Flow Motion | 3 | 9365 |  |
| 412 | ✅ | pad intermediate/30/general_fitness/cardio/E7_no_bb/inj=elbo | Titan Peak Kinetic Flow | 6 | 11007 |  |
| 413 | ✅ | pad advanced/40/mobility/mobility/E8_fw/inj=neck | Titan Full Body Velocity | 6 | 12043 |  |
| 414 | ✅ | pad beginner/45/power/push/E9_db1/inj=knee+shoulder | Titan Sculpting Peak Performance | 6 | 9532 |  |
| 415 | ✅ | pad intermediate/60/athletic_performance/pull/E10_home/inj=k | Titan Sculpting Session | 6 | 12261 |  |
| 416 | ❌ | pad advanced/75/weight_loss/legs/E11_cardio/inj=shoulder+wri |  | 0 | 698 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 417 | ✅ | pad beginner/90/muscle_tone/full_body/E12_bw_bands/inj=knee+ | Gentle Arm Sculpt Flow | 3 | 12399 |  |
| 418 | ✅ | pad intermediate/15/strength/core/E13_TRX/inj=knee+shoulder+ | Gentle Sculpt Shoulder Flow | 5 | 10139 |  |
| 419 | ✅ | pad advanced/20/hypertrophy/upper/E14_gym_60/inj=knee+should | Absolute Peak Upper Sculpt | 8 | 12093 |  |
| 420 | ✅ | pad beginner/30/fat_loss/lower/E1_full/inj=knee | Gentle Motion Vitality Flow | 3 | 10445 |  |
| 421 | ✅ | pad intermediate/40/endurance/arms/E2_bw/inj=shoulder | Steady Gentle Muscle Flow | 3 | 12095 |  |
| 422 | ✅ | pad advanced/45/general_fitness/shoulders/E3_db/inj=lower_ba | Gentle Foundation Body Flow | 5 | 14703 |  |
| 423 | ✅ | pad beginner/60/mobility/glutes/E4_kb/inj=wrist | Gentle Rising Sun Flow | 5 | 9770 |  |
| 424 | ✅ | pad intermediate/75/power/cardio/E5_mach/inj=ankle | Gentle Harmony Flow | 5 | 12562 |  |
| 425 | ✅ | pad advanced/90/athletic_performance/mobility/E6_bands/inj=h | Gentle Peak Performance | 5 | 12928 |  |
| 426 | ✅ | pad beginner/15/weight_loss/push/E7_no_bb/inj=elbow | Gentle Giant Muscle Flow | 5 | 11436 |  |
| 427 | ✅ | pad intermediate/20/muscle_tone/pull/E8_fw/inj=neck | Gentle Peak Performance | 5 | 14090 |  |
| 428 | ✅ | pad advanced/30/strength/legs/E9_db1/inj=knee+shoulder | Ignite Explosive Peak Performance | 3 | 12177 |  |
| 429 | ✅ | pad beginner/40/hypertrophy/full_body/E10_home/inj=knee+lowe | Titan Steel Body Sculpt | 3 | 10643 |  |
| 430 | ❌ | pad intermediate/45/fat_loss/core/E11_cardio/inj=shoulder+wr |  | 0 | 2301 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 431 | ✅ | pad advanced/60/endurance/upper/E12_bw_bands/inj=knee+should | Titan Sculpting Peak | 5 | 15952 |  |
| 432 | ✅ | pad beginner/75/general_fitness/lower/E13_TRX/inj=knee+shoul | Titan Sculpting Peak | 6 | 10966 |  |
| 433 | ✅ | pad intermediate/90/mobility/arms/E14_gym_60/inj=knee+should | Titan Physique Sculpt | 7 | 12934 |  |
| 434 | ✅ | pad advanced/15/power/shoulders/E1_full/inj=knee | Titan Sculpting Blast | 7 | 12426 |  |
| 435 | ✅ | pad beginner/20/athletic_performance/glutes/E2_bw/inj=should | Titan Savage Blast | 7 | 10290 |  |
| 436 | ✅ | pad intermediate/30/weight_loss/cardio/E3_db/inj=lower_back | Titan Unleashed Peak Performance | 3 | 11134 |  |
| 437 | ✅ | pad advanced/40/muscle_tone/mobility/E4_kb/inj=wrist | Titan Savage Blast | 3 | 11707 |  |
| 438 | ✅ | pad beginner/45/strength/push/E5_mach/inj=ankle | Savage Beast Body Blast | 5 | 10831 |  |
| 439 | ✅ | pad intermediate/60/hypertrophy/pull/E6_bands/inj=hip | Apex Predator Body Shock | 5 | 12286 |  |
| 440 | ✅ | pad advanced/75/fat_loss/legs/E7_no_bb/inj=elbow | Apex Warrior Full Blast | 6 | 12779 |  |
| 441 | ✅ | pad beginner/90/endurance/full_body/E8_fw/inj=neck | Apex Titan Full Body | 8 | 10870 |  |
| 442 | ✅ | pad intermediate/15/general_fitness/core/E9_db1/inj=knee+sho | Titan Unleashed Peak Performance | 8 | 8744 |  |
| 443 | ❌ | pad advanced/20/mobility/upper/E10_home/inj=knee+lower_back |  | 0 | 538 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 444 | ❌ | pad beginner/30/power/lower/E11_cardio/inj=shoulder+wrist |  | 0 | 345 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 445 | ❌ | pad intermediate/40/athletic_performance/arms/E12_bw_bands/i |  | 0 | 646 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 446 | ❌ | pad advanced/45/weight_loss/shoulders/E13_TRX/inj=knee+shoul |  | 0 | 506 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 447 | ❌ | pad beginner/60/muscle_tone/glutes/E14_gym_60/inj=knee+shoul |  | 0 | 418 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 448 | ❌ | pad intermediate/75/strength/cardio/E1_full/inj=knee |  | 0 | 470 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 449 | ❌ | pad advanced/90/hypertrophy/mobility/E2_bw/inj=shoulder |  | 0 | 504 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 450 | ❌ | pad beginner/15/fat_loss/push/E3_db/inj=lower_back |  | 0 | 320 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 451 | ❌ | pad intermediate/20/endurance/pull/E4_kb/inj=wrist |  | 0 | 479 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 452 | ❌ | pad advanced/30/general_fitness/legs/E5_mach/inj=ankle |  | 0 | 584 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 453 | ❌ | pad beginner/40/mobility/full_body/E6_bands/inj=hip |  | 0 | 352 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 454 | ❌ | pad intermediate/45/power/core/E7_no_bb/inj=elbow |  | 0 | 338 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 455 | ❌ | pad advanced/60/athletic_performance/upper/E8_fw/inj=neck |  | 0 | 415 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 456 | ❌ | pad beginner/75/weight_loss/lower/E9_db1/inj=knee+shoulder |  | 0 | 367 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 457 | ❌ | pad intermediate/90/muscle_tone/arms/E10_home/inj=knee+lower |  | 0 | 477 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 458 | ❌ | pad advanced/15/strength/shoulders/E11_cardio/inj=shoulder+w |  | 0 | 567 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 459 | ❌ | pad beginner/20/hypertrophy/glutes/E12_bw_bands/inj=knee+sho |  | 0 | 376 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 460 | ❌ | pad intermediate/30/fat_loss/cardio/E13_TRX/inj=knee+shoulde |  | 0 | 363 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 461 | ❌ | pad advanced/40/endurance/mobility/E14_gym_60/inj=knee+shoul |  | 0 | 421 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 462 | ❌ | pad beginner/45/general_fitness/push/E1_full/inj=knee |  | 0 | 473 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 463 | ❌ | pad intermediate/60/mobility/pull/E2_bw/inj=shoulder |  | 0 | 575 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 464 | ❌ | pad advanced/75/power/legs/E3_db/inj=lower_back |  | 0 | 423 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 465 | ❌ | pad beginner/90/athletic_performance/full_body/E4_kb/inj=wri |  | 0 | 525 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 466 | ❌ | pad intermediate/15/weight_loss/core/E5_mach/inj=ankle |  | 0 | 418 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 467 | ❌ | pad advanced/20/muscle_tone/upper/E6_bands/inj=hip |  | 0 | 344 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 468 | ❌ | pad beginner/30/strength/lower/E7_no_bb/inj=elbow |  | 0 | 396 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 469 | ❌ | pad intermediate/40/hypertrophy/arms/E8_fw/inj=neck |  | 0 | 422 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 470 | ❌ | pad advanced/45/fat_loss/shoulders/E9_db1/inj=knee+shoulder |  | 0 | 332 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 471 | ❌ | pad beginner/60/endurance/glutes/E10_home/inj=knee+lower_bac |  | 0 | 447 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 472 | ❌ | pad intermediate/75/general_fitness/cardio/E11_cardio/inj=sh |  | 0 | 469 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 473 | ❌ | pad advanced/90/mobility/mobility/E12_bw_bands/inj=knee+shou |  | 0 | 430 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 474 | ❌ | pad beginner/15/power/push/E13_TRX/inj=knee+shoulder+lower_b |  | 0 | 513 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 475 | ❌ | pad intermediate/20/athletic_performance/pull/E14_gym_60/inj |  | 0 | 343 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 476 | ❌ | pad advanced/30/weight_loss/legs/E1_full/inj=knee |  | 0 | 334 | HTTP 401: b'{"detail":"Session expired \xe2\x80\x94 please log in again."}' |
| 443 | ✅ | pad advanced/20/mobility/upper/E10_home/inj=knee+lower_back | Apex Titan Full Burn | 8 | 16728 |  |
| 444 | ❌ | pad beginner/30/power/lower/E11_cardio/inj=shoulder+wrist |  | 0 | 660 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 445 | ✅ | pad intermediate/40/athletic_performance/arms/E12_bw_bands/i | Titan Full Body Core | 6 | 9740 |  |
| 446 | ✅ | pad advanced/45/weight_loss/shoulders/E13_TRX/inj=knee+shoul | Apex Full Body Burn | 6 | 8881 |  |
| 447 | ✅ | pad beginner/60/muscle_tone/glutes/E14_gym_60/inj=knee+shoul | Endurance Peak Flow | 6 | 11270 |  |
| 448 | ✅ | pad intermediate/75/strength/cardio/E1_full/inj=knee | Apex Full Body Surge | 6 | 11137 |  |
| 449 | ✅ | pad advanced/90/hypertrophy/mobility/E2_bw/inj=shoulder | Limitless Flow Full Body | 6 | 11083 |  |
| 450 | ✅ | pad beginner/15/fat_loss/push/E3_db/inj=lower_back | Explosive Peak Power | 6 | 9889 |  |
| 451 | ✅ | pad intermediate/20/endurance/pull/E4_kb/inj=wrist | Apex Performance Athletic Flow | 6 | 11584 |  |
| 452 | ✅ | pad advanced/30/general_fitness/legs/E5_mach/inj=ankle | Rapid Fire Total Burn | 6 | 12661 |  |
| 453 | ✅ | pad beginner/40/mobility/full_body/E6_bands/inj=hip | Peak Performance Kinetic Flow | 6 | 9942 |  |
| 454 | ✅ | pad intermediate/45/power/core/E7_no_bb/inj=elbow | Titan Push Precision | 6 | 11934 |  |
| 455 | ✅ | pad advanced/60/athletic_performance/upper/E8_fw/inj=neck | Athletic Peak Foundation | 5 | 11701 |  |
| 456 | ✅ | pad beginner/75/weight_loss/lower/E9_db1/inj=knee+shoulder | Titan Leg Furnace | 6 | 9904 |  |
| 457 | ✅ | pad intermediate/90/muscle_tone/arms/E10_home/inj=knee+lower | Apex Beast Full Body | 6 | 11384 |  |
| 458 | ❌ | pad advanced/15/strength/shoulders/E11_cardio/inj=shoulder+w |  | 0 | 594 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 459 | ✅ | pad beginner/20/hypertrophy/glutes/E12_bw_bands/inj=knee+sho | Apex Upper Body Fusion | 6 | 9351 |  |
| 460 | ✅ | pad intermediate/30/fat_loss/cardio/E13_TRX/inj=knee+shoulde | Titan Lower Body Peak | 6 | 11616 |  |
| 461 | ✅ | pad advanced/40/endurance/mobility/E14_gym_60/inj=knee+shoul | Titan Sculpt Arm Blast | 3 | 12504 |  |
| 462 | ✅ | pad beginner/45/general_fitness/push/E1_full/inj=knee | Titan Sculpt Shoulder Peak | 6 | 10522 |  |
| 463 | ✅ | pad intermediate/60/mobility/pull/E2_bw/inj=shoulder | Titan Glute Sculpting Session | 6 | 13132 |  |
| 464 | ✅ | pad advanced/75/power/legs/E3_db/inj=lower_back | Rapid Pulse Peak Performance | 6 | 12849 |  |
| 465 | ✅ | pad beginner/90/athletic_performance/full_body/E4_kb/inj=wri | Apex Prime Body Flow | 6 | 9477 |  |
| 466 | ✅ | pad intermediate/15/weight_loss/core/E5_mach/inj=ankle | Titan Full Body Blast | 6 | 11558 |  |
| 467 | ✅ | pad advanced/20/muscle_tone/upper/E6_bands/inj=hip | Total Body Kinetic Surge | 6 | 11905 |  |
| 468 | ✅ | pad beginner/30/strength/lower/E7_no_bb/inj=elbow | Titan Total Body | 6 | 9725 |  |
| 469 | ✅ | pad intermediate/40/hypertrophy/arms/E8_fw/inj=neck | Kettlebell Titan Strength Circuit | 6 | 11623 |  |
| 470 | ✅ | pad advanced/45/fat_loss/shoulders/E9_db1/inj=knee+shoulder | Gentle Push Strength Flow | 3 | 11607 |  |
| 471 | ✅ | pad beginner/60/endurance/glutes/E10_home/inj=knee+lower_bac | Gentle Flow Motion | 3 | 13330 |  |
| 472 | ✅ | pad intermediate/75/general_fitness/cardio/E11_cardio/inj=sh | Titan Peak Kinetic Flow | 6 | 12807 |  |
| 473 | ✅ | pad advanced/90/mobility/mobility/E12_bw_bands/inj=knee+shou | Titan Full Body Velocity | 6 | 11777 |  |
| 474 | ✅ | pad beginner/15/power/push/E13_TRX/inj=knee+shoulder+lower_b | Titan Sculpting Peak Performance | 6 | 11598 |  |
| 475 | ✅ | pad intermediate/20/athletic_performance/pull/E14_gym_60/inj | Titan Sculpting Session | 6 | 11554 |  |
| 476 | ✅ | pad advanced/30/weight_loss/legs/E1_full/inj=knee | Steady Gentle Foundation | 3 | 11960 |  |
| 477 | ✅ | pad beginner/40/muscle_tone/full_body/E2_bw/inj=shoulder | Gentle Arm Sculpt Flow | 3 | 10211 |  |
| 478 | ✅ | pad intermediate/45/strength/core/E3_db/inj=lower_back | Gentle Sculpt Shoulder Flow | 5 | 11036 |  |
| 479 | ✅ | pad advanced/60/hypertrophy/upper/E4_kb/inj=wrist | Absolute Peak Upper Sculpt | 8 | 12131 |  |
| 480 | ✅ | pad beginner/75/fat_loss/lower/E5_mach/inj=ankle | Gentle Motion Vitality Flow | 3 | 9110 |  |
| 481 | ✅ | pad intermediate/90/endurance/arms/E6_bands/inj=hip | Steady Gentle Muscle Flow | 3 | 10667 |  |
| 482 | ✅ | pad advanced/15/general_fitness/shoulders/E7_no_bb/inj=elbow | Gentle Foundation Body Flow | 5 | 12792 |  |
| 483 | ✅ | pad beginner/20/mobility/glutes/E8_fw/inj=neck | Gentle Rising Sun Flow | 5 | 10040 |  |
| 484 | ✅ | pad intermediate/30/power/cardio/E9_db1/inj=knee+shoulder | Gentle Harmony Flow | 5 | 11282 |  |
| 485 | ✅ | pad advanced/40/athletic_performance/mobility/E10_home/inj=k | Gentle Peak Performance | 5 | 12211 |  |
| 486 | ❌ | pad beginner/45/weight_loss/push/E11_cardio/inj=shoulder+wri |  | 0 | 680 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
| 487 | ✅ | pad intermediate/60/muscle_tone/pull/E12_bw_bands/inj=knee+s | Gentle Peak Performance | 5 | 11107 |  |
| 488 | ✅ | pad advanced/75/strength/legs/E13_TRX/inj=knee+shoulder+lowe | Ignite Explosive Peak Performance | 3 | 12667 |  |
| 489 | ✅ | pad beginner/90/hypertrophy/full_body/E14_gym_60/inj=knee+sh | Titan Steel Body Sculpt | 3 | 11077 |  |
| 490 | ✅ | pad intermediate/15/fat_loss/core/E1_full/inj=knee | Titan Sculpting Blast | 5 | 11157 |  |
| 491 | ✅ | pad advanced/20/endurance/upper/E2_bw/inj=shoulder | Titan Sculpting Peak | 5 | 11115 |  |
| 492 | ✅ | pad beginner/30/general_fitness/lower/E3_db/inj=lower_back | Titan Sculpting Peak | 6 | 9232 |  |
| 493 | ✅ | pad intermediate/40/mobility/arms/E4_kb/inj=wrist | Titan Physique Sculpt | 7 | 11162 |  |
| 494 | ✅ | pad advanced/45/power/shoulders/E5_mach/inj=ankle | Titan Sculpting Blast | 7 | 9669 |  |
| 495 | ✅ | pad beginner/60/athletic_performance/glutes/E6_bands/inj=hip | Titan Savage Blast | 7 | 10950 |  |
| 496 | ✅ | pad intermediate/75/weight_loss/cardio/E7_no_bb/inj=elbow | Titan Unleashed Peak Performance | 3 | 12457 |  |
| 497 | ✅ | pad advanced/90/muscle_tone/mobility/E8_fw/inj=neck | Titan Savage Blast | 3 | 13725 |  |
| 498 | ✅ | pad beginner/15/strength/push/E9_db1/inj=knee+shoulder | Savage Beast Body Blast | 5 | 10011 |  |
| 499 | ✅ | pad intermediate/20/hypertrophy/pull/E10_home/inj=knee+lower | Apex Predator Body Shock | 5 | 13842 |  |
| 500 | ❌ | pad advanced/30/fat_loss/legs/E11_cardio/inj=shoulder+wrist |  | 0 | 564 | HTTP 422: b'{"detail":{"code":"INCOMPATIBLE_EQUIPMENT_FOCUS","message":"Your equ |
