# Missing Warmup / Stretch / Yoga / Mobility Exercises — Generation Tracker

**Total:** 72 movements audited as ABSENT (0 images in exercise_library / exercise_library_manual).
**Audit basis:** RAMP (Raise/Activate/Mobilize/Potentiate) warm-ups + SMR/static cooldown (NASM) + yoga + equipment-assisted mobility.
**Generator:** `gemini-3.1-flash-image` (3:4)  ·  **Validator:** `gemini-3.5-flash` vision QA.
**Style prompts (by Type):** `style_prompt_dynamic.txt` (raise/activate/potentiate/mobilize) · `style_prompt_static.txt` (static-stretch/yoga) · `style_prompt_smr.txt` (foam roll) · `style_prompt_cars.txt` (rolls/circles).
**Candidate source:** `missing_warmup_stretch_candidates.json` → `python run_pipeline.py --candidates missing_warmup_stretch_candidates.json`

| # | Name | Type | Equipment | Target Muscle | Filename | Image Generated | Validation | S3 Upload |
|---|------|------|-----------|---------------|----------|-----------------|------------|-----------|
| 1 | Jog in Place | raise | bodyweight | Calves, Full Body | `jog_in_place.png` | ✅ Done | ✅ Pass | ✅ Live |
| 2 | Pogo Hops | raise | bodyweight | Calves | `pogo_hops.png` | ✅ Done | ✅ Pass | ✅ Live |
| 3 | Lateral Bound | raise | bodyweight | Glutes, Quadriceps | `lateral_bound.png` | ✅ Done | ✅ Pass | ✅ Live |
| 4 | Line Hops | raise | bodyweight | Calves | `line_hops.png` | ✅ Done | ✅ Pass | ✅ Live |
| 5 | Grapevine | raise | bodyweight | Adductors, Hips | `grapevine.png` | ✅ Done | ✅ Pass | ✅ Live |
| 6 | Skater Hops | raise | bodyweight | Glutes, Quadriceps | `skater_hops.png` | ✅ Done | ✅ Pass | ✅ Live |
| 7 | Squat Jacks | raise | bodyweight | Quadriceps, Glutes | `squat_jacks.png` | ✅ Done | ⚠️ Review | ✅ Live |
| 8 | Monster Walk | activate | resistance band | Gluteus Medius | `monster_walk.png` | ✅ Done | ✅ Pass | ✅ Live |
| 9 | Standing Lateral Leg Raise | activate | bodyweight | Gluteus Medius | `standing_lateral_leg_raise.png` | ✅ Done | ✅ Pass | ✅ Live |
| 10 | Scapular Push-Up | activate | bodyweight | Serratus Anterior | `scapular_push_up.png` | ✅ Done | ✅ Pass | ✅ Live |
| 11 | Glute March | activate | bodyweight | Glutes | `glute_march.png` | ✅ Done | ✅ Pass | ✅ Live |
| 12 | Tibialis Raise | activate | bodyweight | Tibialis Anterior | `tibialis_raise.png` | ✅ Done | ⚠️ Review | ✅ Live |
| 13 | Copenhagen Plank | activate | bodyweight | Adductors | `copenhagen_plank.png` | ✅ Done | ✅ Pass | ✅ Live |
| 14 | Banded Squat | activate | resistance band | Quadriceps, Glutes | `banded_squat.png` | ✅ Done | ✅ Pass | ✅ Live |
| 15 | X-Band Walk | activate | resistance band | Gluteus Medius | `x_band_walk.png` | ✅ Done | ✅ Pass | ✅ Live |
| 16 | Banded Clamshell | activate | resistance band | Gluteus Medius | `banded_clamshell.png` | ✅ Done | ✅ Pass | ✅ Live |
| 17 | Terminal Knee Extension | activate | resistance band | Quadriceps (VMO) | `terminal_knee_extension.png` | ✅ Done | ✅ Pass | ✅ Live |
| 18 | Cable Pull-Through | activate | cable machine | Glutes, Hamstrings | `cable_pull_through.png` | ✅ Done | ✅ Pass | ✅ Live |
| 19 | Shoulder Rolls | mobilize | bodyweight | Shoulders, Upper Trapezius | `shoulder_rolls.png` | ✅ Done | ✅ Pass | ✅ Live |
| 20 | Wrist Circles | mobilize | bodyweight | Forearms, Wrists | `wrist_circles.png` | ✅ Done | ✅ Pass | ✅ Live |
| 21 | Knee Circles | mobilize | bodyweight | Knees, Quadriceps | `knee_circles.png` | ✅ Done | ✅ Pass | ✅ Live |
| 22 | Leg Cradle | mobilize | bodyweight | Glutes, Hip Flexors | `leg_cradle.png` | ✅ Done | ✅ Pass | ✅ Live |
| 23 | Hip Airplane | mobilize | bodyweight | Glutes, Hips | `hip_airplane.png` | ✅ Done | ✅ Pass | ✅ Live |
| 24 | Gate Opener | mobilize | bodyweight | Hip Abductors | `gate_opener.png` | ✅ Done | ✅ Pass | ✅ Live |
| 25 | Gate Closer | mobilize | bodyweight | Hip Adductors | `gate_closer.png` | ✅ Done | ✅ Pass | ✅ Live |
| 26 | Toy Soldier Walk | mobilize | bodyweight | Hamstrings | `toy_soldier_walk.png` | ✅ Done | ✅ Pass | ✅ Live |
| 27 | Straight-Leg Kicks | mobilize | bodyweight | Hamstrings | `straight_leg_kicks.png` | ✅ Done | ✅ Pass | ✅ Live |
| 28 | Crab Walk | mobilize | bodyweight | Shoulders, Triceps, Glutes | `crab_walk.png` | ✅ Done | ✅ Pass | ✅ Live |
| 29 | Duck Walk | mobilize | bodyweight | Quadriceps, Hips | `duck_walk.png` | ✅ Done | ✅ Pass | ✅ Live |
| 30 | Beast Crawl | mobilize | bodyweight | Core, Shoulders | `beast_crawl.png` | ✅ Done | ✅ Pass | ✅ Live |
| 31 | Ankle Rocks | mobilize | bodyweight | Calves, Ankles | `ankle_rocks.png` | ✅ Done | ✅ Pass | ✅ Live |
| 32 | Quadruped Rock-Back | mobilize | bodyweight | Hips, Lower Back | `quadruped_rock_back.png` | ✅ Done | ✅ Pass | ✅ Live |
| 33 | Segmental Cat-Cow | mobilize | bodyweight | Spine, Core | `segmental_cat_cow.png` | ✅ Done | ✅ Pass | ✅ Live |
| 34 | Wall Angel | mobilize | bodyweight | Shoulders, Upper Back | `wall_angel.png` | ✅ Done | ✅ Pass | ✅ Live |
| 35 | Spiderman Lunge with Reach | mobilize | bodyweight | Hip Flexors, Thoracic Spine | `spiderman_lunge_with_reach.png` | ✅ Done | ✅ Pass | ✅ Live |
| 36 | Sciatic Nerve Floss | mobilize | bodyweight | Hamstrings, Sciatic Nerve | `sciatic_nerve_floss.png` | ✅ Done | ✅ Pass | ✅ Live |
| 37 | Cobra to Child Flow | mobilize | bodyweight | Spine, Lats | `cobra_to_child_flow.png` | ✅ Done | ✅ Pass | ✅ Live |
| 38 | Band Shoulder Pass-Through | mobilize | resistance band | Shoulders | `band_shoulder_pass_through.png` | ✅ Done | ✅ Pass | ✅ Live |
| 39 | Band Hip Distraction | mobilize | resistance band | Hips | `band_hip_distraction.png` | ✅ Done | ✅ Pass | ✅ Live |
| 40 | Band Ankle Mobilization | mobilize | resistance band | Ankles, Calves | `band_ankle_mobilization.png` | ✅ Done | ✅ Pass | ✅ Live |
| 41 | Broad Jump | potentiate | bodyweight | Quadriceps, Glutes | `broad_jump.png` | ✅ Done | ✅ Pass | ✅ Live |
| 42 | Tuck Jump | potentiate | bodyweight | Quadriceps | `tuck_jump.png` | ✅ Done | ✅ Pass | ✅ Live |
| 43 | Depth Jump | potentiate | bodyweight | Quadriceps, Glutes | `depth_jump.png` | ✅ Done | ✅ Pass | ✅ Live |
| 44 | Split Squat Jump | potentiate | bodyweight | Quadriceps, Glutes | `split_squat_jump.png` | ✅ Done | ✅ Pass | ✅ Live |
| 45 | Single-Leg Hop | potentiate | bodyweight | Calves, Quadriceps | `single_leg_hop.png` | ✅ Done | ✅ Pass | ✅ Live |
| 46 | Medicine Ball Chest Pass | potentiate | medicine ball | Chest, Triceps | `medicine_ball_chest_pass.png` | ✅ Done | ✅ Pass | ✅ Live |
| 47 | Foam Roll Calves | smr | foam roller | Calves | `foam_roll_calves.png` | ✅ Done | ✅ Pass | ✅ Live |
| 48 | Foam Roll TFL | smr | foam roller | Tensor Fasciae Latae | `foam_roll_tfl.png` | ✅ Done | ✅ Pass | ✅ Live |
| 49 | Foam Roll Shins | smr | foam roller | Tibialis Anterior | `foam_roll_shins.png` | ✅ Done | ✅ Pass | ✅ Live |
| 50 | Foam Roll Forearms | smr | foam roller | Forearms | `foam_roll_forearms.png` | ✅ Done | ✅ Pass | ✅ Live |
| 51 | Foam Roll Feet | smr | foam roller | Plantar Fascia, Feet | `foam_roll_feet.png` | ✅ Done | ✅ Pass | ✅ Live |
| 52 | Upper Trap Stretch | static-stretch | bodyweight | Upper Trapezius | `upper_trap_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 53 | Levator Scapulae Stretch | static-stretch | bodyweight | Levator Scapulae | `levator_scapulae_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 54 | Scalene Stretch | static-stretch | bodyweight | Scalenes | `scalene_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 55 | Suboccipital Stretch | static-stretch | bodyweight | Suboccipitals | `suboccipital_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 56 | Overhead Shoulder Stretch | static-stretch | bodyweight | Shoulders, Lats | `overhead_shoulder_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 57 | Pec Minor Stretch | static-stretch | bodyweight | Pectoralis Minor | `pec_minor_stretch.png` | ❌ Failed | ❌ Fail | — |
| 58 | Floor Pec Stretch | static-stretch | bodyweight | Pectorals | `floor_pec_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 59 | Tibialis Stretch | static-stretch | bodyweight | Tibialis Anterior | `tibialis_stretch.png` | ✅ Done | ⚠️ Review | ✅ Live |
| 60 | Piriformis Stretch | static-stretch | bodyweight | Piriformis, Glutes | `piriformis_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 61 | Psoas Stretch | static-stretch | bodyweight | Psoas, Hip Flexors | `psoas_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 62 | Quadratus Lumborum Stretch | static-stretch | bodyweight | Quadratus Lumborum | `quadratus_lumborum_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 63 | Seated Pigeon Stretch | static-stretch | bodyweight | Glutes | `seated_pigeon_stretch.png` | ✅ Done | ⚠️ Review | ✅ Live |
| 64 | Standing Figure-Four Stretch | static-stretch | bodyweight | Glutes | `standing_figure_four_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 65 | Thoracic Extension Stretch | static-stretch | bodyweight | Thoracic Spine | `thoracic_extension_stretch.png` | ✅ Done | ⚠️ Review | ✅ Live |
| 66 | Hamstring Scoop Stretch | static-stretch | bodyweight | Hamstrings | `hamstring_scoop_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 67 | Band Hamstring Stretch | static-stretch | resistance band | Hamstrings | `band_hamstring_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 68 | TRX Hamstring Stretch | static-stretch | suspension trainer | Hamstrings | `trx_hamstring_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 69 | TRX Shoulder Stretch | static-stretch | suspension trainer | Shoulders | `trx_shoulder_stretch.png` | ✅ Done | ✅ Pass | ✅ Live |
| 70 | Sphinx Pose | yoga | yoga mat | Lower Back, Abdominals | `sphinx_pose.png` | ✅ Done | ✅ Pass | ✅ Live |
| 71 | Lizard Pose | yoga | yoga mat | Hip Flexors, Hips | `lizard_pose.png` | ✅ Done | ✅ Pass | ✅ Live |
| 72 | Legs Up the Wall | yoga | yoga mat | Hamstrings | `legs_up_the_wall.png` | ✅ Done | ✅ Pass | ✅ Live |
