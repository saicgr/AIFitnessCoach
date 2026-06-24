# Missing Exercise Images — Generation Tracker

**Source of truth:** `exercise_library_cleaned` (the MV the app reads) where `image_url IS NULL`.
**Total DISTINCT exercises with no image:** 318  (304 manual-origin, 14 base-origin)
**Generator:** `gemini-3.1-flash-image` — 1024px, ~$0.067/image standard · ~$0.034 batch
**Validator:** `gemini-3.1-flash` vision QA (scores each render against the style guidelines)
**Style prompt:** `docs/planning/exercise-images/style_prompt.txt`
**Est. full-batch cost:** ~$21 generation + ~$1 validation (one pass); budget 2-3x for regen on QA failures

> **Why 318 and not 700?** The raw `exercise_library_manual` table has 700 image-less rows, but ~half are
> `_Female`/gender-variant duplicates. The MV collapses them to one canonical row per exercise -> **318 distinct
> movements**. The ecorche figure is androgynous, so **one image per exercise covers both gender variants.**

## Status legend
- **Image Generated:** white-square Pending / In progress / Done / Failed
- **Validation:** Pending / Pass / Review (borderline) / Fail -> regenerate
- **S3 Upload:** Pending / Uploaded / Failed  *(gated on Validation = Pass)*

## Validation checklist (each generated image is scored on)
1. Solid white background, no clutter/floor/border.
2. Single anatomical ecorche figure (skin removed, musculature visible), anatomically plausible - **no extra/missing limbs**.
3. Non-target muscles gray; **the correct target muscle for THIS exercise highlighted red**.
4. **Correct equipment present** for this exercise (or none, if bodyweight).
5. Pose plausibly matches the movement.
6. No text, labels, numbers, arrows, watermark, grid, or UI.
Failures (any hard criterion) -> regenerate with an adjusted exercise block before upload.

## Per-exercise pipeline
1. **Generate** PNG (style prompt + exercise pose block) -> save to **Generated Path**.
2. **Validate** via vision QA -> set **Validation**. Fail -> regenerate (loop, cap N attempts).
3. **Upload** passing images to S3 -> set **S3 Upload**.
4. Set `image_s3_path` on the row, then `REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned`.

---

## Manual-origin exercises (304)

| # | Exercise | Target | Equipment | Image Filename | Generated Path | Image Generated | Validation | S3 Upload |
|---|----------|--------|-----------|----------------|----------------|-----------------|------------|-----------|
| 1 | 90/90 Hip Stretch | glutes | Bodyweight | `90_90_hip_stretch.png` | `docs/planning/exercise-images/generated/90_90_hip_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 2 | A-Skip | hip_flexors | Bodyweight | `a_skip.png` | `docs/planning/exercise-images/generated/a_skip.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 3 | Active Hang | lats | Pull-Up Bar | `active_hang.png` | `docs/planning/exercise-images/generated/active_hang.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 4 | Alternate Bicep Curl Resistance Band | Biceps | Resistance Band | `alternate_bicep_curl_resistance_band.png` | `docs/planning/exercise-images/generated/alternate_bicep_curl_resistance_band.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 5 | Alternate Bicep Curl Standing Dumbbells | Biceps | Dumbbells | `alternate_bicep_curl_standing_dumbbells.png` | `docs/planning/exercise-images/generated/alternate_bicep_curl_standing_dumbbells.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 6 | Ankle Cars | calves | Bodyweight | `ankle_cars.png` | `docs/planning/exercise-images/generated/ankle_cars.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 7 | Ankle Dorsiflexion Stretch | calves | Bodyweight | `ankle_dorsiflexion_stretch.png` | `docs/planning/exercise-images/generated/ankle_dorsiflexion_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 8 | Arm Circle Backward | shoulders | Bodyweight | `arm_circle_backward.png` | `docs/planning/exercise-images/generated/arm_circle_backward.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 9 | Arm Circle Forward | shoulders | Bodyweight | `arm_circle_forward.png` | `docs/planning/exercise-images/generated/arm_circle_forward.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 10 | Ashwa Vadivu (Horse Stance) | quadriceps | Bodyweight | `ashwa_vadivu_horse_stance.png` | `docs/planning/exercise-images/generated/ashwa_vadivu_horse_stance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 11 | Assault Bike Calories | quadriceps | Assault Bike | `assault_bike_calories.png` | `docs/planning/exercise-images/generated/assault_bike_calories.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 12 | Assault Bike Easy | quadriceps | Assault Bike | `assault_bike_easy.png` | `docs/planning/exercise-images/generated/assault_bike_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 13 | Assault Bike Hiit | quadriceps | Assault Bike | `assault_bike_hiit.png` | `docs/planning/exercise-images/generated/assault_bike_hiit.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 14 | Assisted Chin-Up | biceps | Assisted Pull-Up Machine | `assisted_chin_up.png` | `docs/planning/exercise-images/generated/assisted_chin_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 15 | Assisted Dip | triceps | Assisted Pull-Up Machine | `assisted_dip.png` | `docs/planning/exercise-images/generated/assisted_dip.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 16 | B-Skip | hamstrings | Bodyweight | `b_skip.png` | `docs/planning/exercise-images/generated/b_skip.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 17 | Baithak (Hindu Squat) | quadriceps | Bodyweight | `baithak_hindu_squat.png` | `docs/planning/exercise-images/generated/baithak_hindu_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 18 | Barbell Behind Neck Military Press | Front Shoulders | Barbell | `barbell_behind_neck_military_press.png` | `docs/planning/exercise-images/generated/barbell_behind_neck_military_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 19 | Barbell Full Squat Back Pov | Quadriceps | Barbell | `barbell_full_squat_back_pov.png` | `docs/planning/exercise-images/generated/barbell_full_squat_back_pov.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 20 | Battle Rope Alternating Waves | shoulders | battle ropes | `battle_rope_alternating_waves.png` | `docs/planning/exercise-images/generated/battle_rope_alternating_waves.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 21 | Battle Rope Circles | shoulders | battle ropes | `battle_rope_circles.png` | `docs/planning/exercise-images/generated/battle_rope_circles.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 22 | Battle Rope Double Waves | shoulders | battle ropes | `battle_rope_double_waves.png` | `docs/planning/exercise-images/generated/battle_rope_double_waves.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 23 | Battle Rope Grappler Throws | core | battle ropes | `battle_rope_grappler_throws.png` | `docs/planning/exercise-images/generated/battle_rope_grappler_throws.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 24 | Battle Rope Hip Toss | core | battle ropes | `battle_rope_hip_toss.png` | `docs/planning/exercise-images/generated/battle_rope_hip_toss.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 25 | Battle Rope Jumping Jacks | shoulders | battle ropes | `battle_rope_jumping_jacks.png` | `docs/planning/exercise-images/generated/battle_rope_jumping_jacks.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 26 | Battle Rope Lunges With Waves | quadriceps | battle ropes | `battle_rope_lunges_with_waves.png` | `docs/planning/exercise-images/generated/battle_rope_lunges_with_waves.png` | ✅ Done | ❌ Fail | ⬜ Pending |
| 27 | Battle Rope Side-To-Side Waves | core | battle ropes | `battle_rope_side_to_side_waves.png` | `docs/planning/exercise-images/generated/battle_rope_side_to_side_waves.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 28 | Battle Rope Slams | shoulders | battle ropes | `battle_rope_slams.png` | `docs/planning/exercise-images/generated/battle_rope_slams.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 29 | Battle Rope Snakes | shoulders | battle ropes | `battle_rope_snakes.png` | `docs/planning/exercise-images/generated/battle_rope_snakes.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 30 | Battle Rope Squat To Press | quadriceps | battle ropes | `battle_rope_squat_to_press.png` | `docs/planning/exercise-images/generated/battle_rope_squat_to_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 31 | Bear Crawl | core | Bodyweight | `bear_crawl.png` | `docs/planning/exercise-images/generated/bear_crawl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 32 | Behind Neck Lat Pulldown | lats | Lat Pulldown Machine | `behind_neck_lat_pulldown.png` | `docs/planning/exercise-images/generated/behind_neck_lat_pulldown.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 33 | Bodyweight Good Morning | hamstrings | Bodyweight | `bodyweight_good_morning.png` | `docs/planning/exercise-images/generated/bodyweight_good_morning.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 34 | Bodyweight Kneeling To Hand Tap | Hip Flexors | Bodyweight | `bodyweight_kneeling_to_hand_tap.png` | `docs/planning/exercise-images/generated/bodyweight_kneeling_to_hand_tap.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 35 | Bretzel Stretch | hip_flexors | Bodyweight | `bretzel_stretch.png` | `docs/planning/exercise-images/generated/bretzel_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 36 | Butt Kick Run | hamstrings | Bodyweight | `butt_kick_run.png` | `docs/planning/exercise-images/generated/butt_kick_run.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 37 | Butterfly Stretch | adductors | Bodyweight | `butterfly_stretch.png` | `docs/planning/exercise-images/generated/butterfly_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 38 | Cable Bicep Curl | biceps | Cable Machine | `cable_bicep_curl.png` | `docs/planning/exercise-images/generated/cable_bicep_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 39 | Cable Crunch | abs | Cable Machine | `cable_crunch.png` | `docs/planning/exercise-images/generated/cable_crunch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 40 | Cable Face Pull | rear_delts | Cable Machine | `cable_face_pull.png` | `docs/planning/exercise-images/generated/cable_face_pull.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 41 | Cable Reverse Fly | Rear Shoulders | Cable Machine | `cable_reverse_fly.png` | `docs/planning/exercise-images/generated/cable_reverse_fly.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 42 | Cable Seated Row With V Bar | Middle Back (Latissimus Dorsi | Seated Row Machine | `cable_seated_row_with_v_bar.png` | `docs/planning/exercise-images/generated/cable_seated_row_with_v_bar.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 43 | Cable Tricep Pushdown | triceps | Cable Machine | `cable_tricep_pushdown.png` | `docs/planning/exercise-images/generated/cable_tricep_pushdown.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 44 | Cable Woodchop | obliques | Cable Machine | `cable_woodchop.png` | `docs/planning/exercise-images/generated/cable_woodchop.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 45 | Carioca Drill | adductors | Bodyweight | `carioca_drill.png` | `docs/planning/exercise-images/generated/carioca_drill.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 46 | Cat-Cow Stretch | lower_back | Bodyweight | `cat_cow_stretch.png` | `docs/planning/exercise-images/generated/cat_cow_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 47 | Chair Bulgarian Split Squats Bodyweight | Quadriceps | Bodyweight | `chair_bulgarian_split_squats_bodyweight.png` | `docs/planning/exercise-images/generated/chair_bulgarian_split_squats_bodyweight.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 48 | Chakki Chalanasana (Mill Churning Pose) | abdominals | Bodyweight | `chakki_chalanasana_mill_churning_pose.png` | `docs/planning/exercise-images/generated/chakki_chalanasana_mill_churning_pose.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 49 | Chest Doorway Stretch | chest | Bodyweight | `chest_doorway_stretch.png` | `docs/planning/exercise-images/generated/chest_doorway_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 50 | Child's Pose | lower_back | Bodyweight | `child_s_pose.png` | `docs/planning/exercise-images/generated/child_s_pose.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 51 | Chin-Up Grip Hang | biceps | Pull-Up Bar | `chin_up_grip_hang.png` | `docs/planning/exercise-images/generated/chin_up_grip_hang.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 52 | Close-Grip Lat Pulldown | lats | Lat Pulldown Machine | `close_grip_lat_pulldown.png` | `docs/planning/exercise-images/generated/close_grip_lat_pulldown.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 53 | Cobra Pose | lower_back | Bodyweight | `cobra_pose.png` | `docs/planning/exercise-images/generated/cobra_pose.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 54 | Cross-Body Shoulder Stretch | rear_delts | Bodyweight | `cross_body_shoulder_stretch.png` | `docs/planning/exercise-images/generated/cross_body_shoulder_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 55 | Dand (Hindu Push-Up) | chest | Bodyweight | `dand_hindu_push_up.png` | `docs/planning/exercise-images/generated/dand_hindu_push_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 56 | Dead Hang | forearms | Pull-Up Bar | `dead_hang.png` | `docs/planning/exercise-images/generated/dead_hang.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 57 | Decline Bench Oblique Crunches | Obliques | Dumbbells | `decline_bench_oblique_crunches.png` | `docs/planning/exercise-images/generated/decline_bench_oblique_crunches.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 58 | Deep Squat Hold | quadriceps | Bodyweight | `deep_squat_hold.png` | `docs/planning/exercise-images/generated/deep_squat_hold.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 59 | Doorway Pec Stretch High | chest | Bodyweight | `doorway_pec_stretch_high.png` | `docs/planning/exercise-images/generated/doorway_pec_stretch_high.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 60 | Downward Facing Dog | hamstrings | Bodyweight | `downward_facing_dog.png` | `docs/planning/exercise-images/generated/downward_facing_dog.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 61 | Dumbbell Curl Press | Biceps | Dumbbells | `dumbbell_curl_press.png` | `docs/planning/exercise-images/generated/dumbbell_curl_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 62 | Dumbbell Lying Single-Arm Supinated Triceps Extension | Full Body | Dumbbells | `dumbbell_lying_single_arm_supinated_triceps_extension.png` | `docs/planning/exercise-images/generated/dumbbell_lying_single_arm_supinated_triceps_extension.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 63 | Dumbbell Plyo Squat | Quadriceps | Dumbbells | `dumbbell_plyo_squat.png` | `docs/planning/exercise-images/generated/dumbbell_plyo_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 64 | Dumbbell Seated Close-Grip Press | Shoulders | Dumbbells | `dumbbell_seated_close_grip_press.png` | `docs/planning/exercise-images/generated/dumbbell_seated_close_grip_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 65 | Dumbbell Single-Arm Leaning Lateral Raise | Shoulders | Dumbbells | `dumbbell_single_arm_leaning_lateral_raise.png` | `docs/planning/exercise-images/generated/dumbbell_single_arm_leaning_lateral_raise.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 66 | Dumbbell Single-Arm Row | Middle Back (Latissimus Dorsi | Dumbbells | `dumbbell_single_arm_row.png` | `docs/planning/exercise-images/generated/dumbbell_single_arm_row.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 67 | Dumbbell Standing Around World | Shoulders | Dumbbells | `dumbbell_standing_around_world.png` | `docs/planning/exercise-images/generated/dumbbell_standing_around_world.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 68 | Dumbbells Around The World | Shoulders | Dumbbells | `dumbbells_around_the_world.png` | `docs/planning/exercise-images/generated/dumbbells_around_the_world.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 69 | Elliptical Easy | quadriceps | Elliptical | `elliptical_easy.png` | `docs/planning/exercise-images/generated/elliptical_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 70 | Elliptical High Incline Forward | glutes | Elliptical | `elliptical_high_incline_forward.png` | `docs/planning/exercise-images/generated/elliptical_high_incline_forward.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 71 | Elliptical Interval Bursts | quadriceps | Elliptical | `elliptical_interval_bursts.png` | `docs/planning/exercise-images/generated/elliptical_interval_bursts.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 72 | Elliptical Moderate | quadriceps | Elliptical | `elliptical_moderate.png` | `docs/planning/exercise-images/generated/elliptical_moderate.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 73 | Elliptical No Hands | core | Elliptical | `elliptical_no_hands.png` | `docs/planning/exercise-images/generated/elliptical_no_hands.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 74 | Elliptical Reverse Stride | hamstrings | Elliptical | `elliptical_reverse_stride.png` | `docs/planning/exercise-images/generated/elliptical_reverse_stride.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 75 | Figure Four Stretch | glutes | Bodyweight | `figure_four_stretch.png` | `docs/planning/exercise-images/generated/figure_four_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 76 | Foam Roll Adductors | adductors | Foam Roller | `foam_roll_adductors.png` | `docs/planning/exercise-images/generated/foam_roll_adductors.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 77 | Foam Roll Calves | calves | Foam Roller | `foam_roll_calves.png` | `docs/planning/exercise-images/generated/foam_roll_calves.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 78 | Foam Roll Glutes | glutes | Foam Roller | `foam_roll_glutes.png` | `docs/planning/exercise-images/generated/foam_roll_glutes.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 79 | Foam Roll Hamstrings | hamstrings | Foam Roller | `foam_roll_hamstrings.png` | `docs/planning/exercise-images/generated/foam_roll_hamstrings.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 80 | Foam Roll Hip Flexors | hip_flexors | Foam Roller | `foam_roll_hip_flexors.png` | `docs/planning/exercise-images/generated/foam_roll_hip_flexors.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 81 | Foam Roll It Band | abductors | Foam Roller | `foam_roll_it_band.png` | `docs/planning/exercise-images/generated/foam_roll_it_band.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 82 | Foam Roll Lats | lats | Foam Roller | `foam_roll_lats.png` | `docs/planning/exercise-images/generated/foam_roll_lats.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 83 | Foam Roll Pecs | chest | Foam Roller | `foam_roll_pecs.png` | `docs/planning/exercise-images/generated/foam_roll_pecs.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 84 | Foam Roll Peroneals | calves | Foam Roller | `foam_roll_peroneals.png` | `docs/planning/exercise-images/generated/foam_roll_peroneals.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 85 | Foam Roll Quadriceps | quadriceps | Foam Roller | `foam_roll_quadriceps.png` | `docs/planning/exercise-images/generated/foam_roll_quadriceps.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 86 | Foam Roll Thoracic Spine | thoracic_spine | Foam Roller | `foam_roll_thoracic_spine.png` | `docs/planning/exercise-images/generated/foam_roll_thoracic_spine.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 87 | Foam Roll Upper Back | traps | Foam Roller | `foam_roll_upper_back.png` | `docs/planning/exercise-images/generated/foam_roll_upper_back.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 88 | Frankenstein Walk | hamstrings | Bodyweight | `frankenstein_walk.png` | `docs/planning/exercise-images/generated/frankenstein_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 89 | Frog Stretch | adductors | Bodyweight | `frog_stretch.png` | `docs/planning/exercise-images/generated/frog_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 90 | Front Raises Dumbbell Seated | Shoulders | Dumbbells | `front_raises_dumbbell_seated.png` | `docs/planning/exercise-images/generated/front_raises_dumbbell_seated.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 91 | Front Squats Kettlelbell Over Shoulders | Quadriceps | Bodyweight | `front_squats_kettlelbell_over_shoulders.png` | `docs/planning/exercise-images/generated/front_squats_kettlelbell_over_shoulders.png` | ✅ Done | ❌ Fail | ⬜ Pending |
| 92 | Gada 360-Degree Swing | shoulders | gada (mace) | `gada_360_degree_swing.png` | `docs/planning/exercise-images/generated/gada_360_degree_swing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 93 | Gada Figure 8 Swing | core | gada (mace) | `gada_figure_8_swing.png` | `docs/planning/exercise-images/generated/gada_figure_8_swing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 94 | Gada Pendulum Swing | shoulders | gada (mace) | `gada_pendulum_swing.png` | `docs/planning/exercise-images/generated/gada_pendulum_swing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 95 | Gaja Vadivu (Elephant Stance) | quadriceps | Bodyweight | `gaja_vadivu_elephant_stance.png` | `docs/planning/exercise-images/generated/gaja_vadivu_elephant_stance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 96 | Gar Nal Weighted Baithak | quadriceps | gar nal (stone neck ring) | `gar_nal_weighted_baithak.png` | `docs/planning/exercise-images/generated/gar_nal_weighted_baithak.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 97 | Good Morning Resistace Band | Hamstrings (Biceps Femoris | Resistance Band | `good_morning_resistace_band.png` | `docs/planning/exercise-images/generated/good_morning_resistace_band.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 98 | Hanuman Dand (Power Hindu Push-Up) | chest | Bodyweight | `hanuman_dand_power_hindu_push_up.png` | `docs/planning/exercise-images/generated/hanuman_dand_power_hindu_push_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 99 | Hay Bale Clean | trapezius | hay bale | `hay_bale_clean.png` | `docs/planning/exercise-images/generated/hay_bale_clean.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 100 | Hay Bale Clean Burpee | quadriceps | hay bale, hay bale wall | `hay_bale_clean_burpee.png` | `docs/planning/exercise-images/generated/hay_bale_clean_burpee.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 101 | Hay Bale Deadlift | hamstrings | hay bale | `hay_bale_deadlift.png` | `docs/planning/exercise-images/generated/hay_bale_deadlift.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 102 | Hay Bale Farmer's Carry | trapezius | hay bale | `hay_bale_farmer_s_carry.png` | `docs/planning/exercise-images/generated/hay_bale_farmer_s_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 103 | Hay Bale Lunge With Rotation | quadriceps | hay bale | `hay_bale_lunge_with_rotation.png` | `docs/planning/exercise-images/generated/hay_bale_lunge_with_rotation.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 104 | Hay Bale Over-Shoulder Throw | glutes | hay bale | `hay_bale_over_shoulder_throw.png` | `docs/planning/exercise-images/generated/hay_bale_over_shoulder_throw.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 105 | Hay Bale Overhead Press | deltoids | hay bale | `hay_bale_overhead_press.png` | `docs/planning/exercise-images/generated/hay_bale_overhead_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 106 | Hay Bale Russian Twist | obliques | hay bale | `hay_bale_russian_twist.png` | `docs/planning/exercise-images/generated/hay_bale_russian_twist.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 107 | Hay Bale Shoulder Load | trapezius | hay bale | `hay_bale_shoulder_load.png` | `docs/planning/exercise-images/generated/hay_bale_shoulder_load.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 108 | Hay Bale Squat | quadriceps | hay bale | `hay_bale_squat.png` | `docs/planning/exercise-images/generated/hay_bale_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 109 | Hay Bale Step-Up | quadriceps | hay bale | `hay_bale_step_up.png` | `docs/planning/exercise-images/generated/hay_bale_step_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 110 | High Knee Run | hip_flexors | Bodyweight | `high_knee_run.png` | `docs/planning/exercise-images/generated/high_knee_run.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 111 | Hip 90/90 Switch | glutes | Bodyweight | `hip_90_90_switch.png` | `docs/planning/exercise-images/generated/hip_90_90_switch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 112 | Hip Cars | hip_flexors | Bodyweight | `hip_cars.png` | `docs/planning/exercise-images/generated/hip_cars.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 113 | Hip Circle | hip_flexors | Bodyweight | `hip_circle.png` | `docs/planning/exercise-images/generated/hip_circle.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 114 | Hip Flexor Couch Stretch | hip_flexors | Bodyweight | `hip_flexor_couch_stretch.png` | `docs/planning/exercise-images/generated/hip_flexor_couch_stretch.png` | ✅ Done | ❌ Fail | ⬜ Pending |
| 115 | Inchworm | core | Bodyweight | `inchworm.png` | `docs/planning/exercise-images/generated/inchworm.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 116 | Incline Machine Press | upper_chest | Chest Press Machine | `incline_machine_press.png` | `docs/planning/exercise-images/generated/incline_machine_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 117 | It Band Stretch Standing | abductors | Bodyweight | `it_band_stretch_standing.png` | `docs/planning/exercise-images/generated/it_band_stretch_standing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 118 | Jori Basic Swing | shoulders | jori (indian clubs) | `jori_basic_swing.png` | `docs/planning/exercise-images/generated/jori_basic_swing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 119 | Jori Circular Swings | shoulders | jori (indian clubs) | `jori_circular_swings.png` | `docs/planning/exercise-images/generated/jori_circular_swings.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 120 | Jori Figure 8 | shoulders | jori (indian clubs) | `jori_figure_8.png` | `docs/planning/exercise-images/generated/jori_figure_8.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 121 | Jori Windmill | shoulders | jori (indian clubs) | `jori_windmill.png` | `docs/planning/exercise-images/generated/jori_windmill.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 122 | Jump Rope Alternate Foot Step | calves | Jump Rope | `jump_rope_alternate_foot_step.png` | `docs/planning/exercise-images/generated/jump_rope_alternate_foot_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 123 | Jump Rope Basic Bounce | calves | Jump Rope | `jump_rope_basic_bounce.png` | `docs/planning/exercise-images/generated/jump_rope_basic_bounce.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 124 | Jump Rope Boxer Step | calves | Jump Rope | `jump_rope_boxer_step.png` | `docs/planning/exercise-images/generated/jump_rope_boxer_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 125 | Jump Rope Criss-Cross | calves | Jump Rope | `jump_rope_criss_cross.png` | `docs/planning/exercise-images/generated/jump_rope_criss_cross.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 126 | Jump Rope Double Under | calves | Jump Rope | `jump_rope_double_under.png` | `docs/planning/exercise-images/generated/jump_rope_double_under.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 127 | Jump Rope High Knees | hip_flexors | Jump Rope | `jump_rope_high_knees.png` | `docs/planning/exercise-images/generated/jump_rope_high_knees.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 128 | Kabaddi Cant Breathing Practice | diaphragm | Bodyweight | `kabaddi_cant_breathing_practice.png` | `docs/planning/exercise-images/generated/kabaddi_cant_breathing_practice.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 129 | Kabaddi Shuttle Run | quadriceps | Bodyweight | `kabaddi_shuttle_run.png` | `docs/planning/exercise-images/generated/kabaddi_shuttle_run.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 130 | Kabaddi Squat Jumps | quadriceps | Bodyweight | `kabaddi_squat_jumps.png` | `docs/planning/exercise-images/generated/kabaddi_squat_jumps.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 131 | Kalaripayattu High Kick (Kalugal) | hip_flexors | Bodyweight | `kalaripayattu_high_kick_kalugal.png` | `docs/planning/exercise-images/generated/kalaripayattu_high_kick_kalugal.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 132 | Kuan Pani Khinchna (Well Water Drawing) | biceps | rope | `kuan_pani_khinchna_well_water_drawing.png` | `docs/planning/exercise-images/generated/kuan_pani_khinchna_well_water_drawing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 133 | Lat Stretch Wall | lats | Bodyweight | `lat_stretch_wall.png` | `docs/planning/exercise-images/generated/lat_stretch_wall.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 134 | Lateral Lunge | adductors | Bodyweight | `lateral_lunge.png` | `docs/planning/exercise-images/generated/lateral_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 135 | Lateral Shuffle | abductors | Bodyweight | `lateral_shuffle.png` | `docs/planning/exercise-images/generated/lateral_shuffle.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 136 | Lathi Basic Staff Handling | forearms | lathi (bamboo staff) | `lathi_basic_staff_handling.png` | `docs/planning/exercise-images/generated/lathi_basic_staff_handling.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 137 | Lathi Overhead Side Bend | obliques | lathi (bamboo staff) | `lathi_overhead_side_bend.png` | `docs/planning/exercise-images/generated/lathi_overhead_side_bend.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 138 | Lathi Single-Leg Balance | core | lathi (bamboo staff) | `lathi_single_leg_balance.png` | `docs/planning/exercise-images/generated/lathi_single_leg_balance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 139 | Leg Press Narrow Stance | quadriceps | Leg Press Machine | `leg_press_narrow_stance.png` | `docs/planning/exercise-images/generated/leg_press_narrow_stance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 140 | Leg Swing Forward-Backward | hip_flexors | Bodyweight | `leg_swing_forward_backward.png` | `docs/planning/exercise-images/generated/leg_swing_forward_backward.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 141 | Leg Swing Lateral | adductors | Bodyweight | `leg_swing_lateral.png` | `docs/planning/exercise-images/generated/leg_swing_lateral.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 142 | Low Lunge (Anjaneyasana) | hip_flexors | Bodyweight | `low_lunge_anjaneyasana.png` | `docs/planning/exercise-images/generated/low_lunge_anjaneyasana.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 143 | Machine Shoulder Press | shoulders | Shoulder Press Machine | `machine_shoulder_press.png` | `docs/planning/exercise-images/generated/machine_shoulder_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 144 | Mallakhamb Basic Mounting | core | mallakhamb pole | `mallakhamb_basic_mounting.png` | `docs/planning/exercise-images/generated/mallakhamb_basic_mounting.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 145 | Mallakhamb Pole Sit (Danda) | core | mallakhamb pole | `mallakhamb_pole_sit_danda.png` | `docs/planning/exercise-images/generated/mallakhamb_pole_sit_danda.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 146 | Matka Head Carry | core | matka (water pot) | `matka_head_carry.png` | `docs/planning/exercise-images/generated/matka_head_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 147 | Matka Hip Carry | obliques | matka (water pot) | `matka_hip_carry.png` | `docs/planning/exercise-images/generated/matka_hip_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 148 | Mixed Grip Hang | forearms | Pull-Up Bar | `mixed_grip_hang.png` | `docs/planning/exercise-images/generated/mixed_grip_hang.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 149 | Nal Stone Lock Lift | grip | nal (stone lock) | `nal_stone_lock_lift.png` | `docs/planning/exercise-images/generated/nal_stone_lock_lift.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 150 | Neck Side Bend Stretch | traps | Bodyweight | `neck_side_bend_stretch.png` | `docs/planning/exercise-images/generated/neck_side_bend_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 151 | Open Book Stretch | thoracic_spine | Bodyweight | `open_book_stretch.png` | `docs/planning/exercise-images/generated/open_book_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 152 | Overhead Triceps Stretch | triceps | Bodyweight | `overhead_triceps_stretch.png` | `docs/planning/exercise-images/generated/overhead_triceps_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 153 | Pec Deck Fly | chest | Pec Fly Machine | `pec_deck_fly.png` | `docs/planning/exercise-images/generated/pec_deck_fly.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 154 | Pigeon Stretch | glutes | Bodyweight | `pigeon_stretch.png` | `docs/planning/exercise-images/generated/pigeon_stretch.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 155 | Plate Loaded Chest Press Incline | Chest | Chest Press Machine | `plate_loaded_chest_press_incline.png` | `docs/planning/exercise-images/generated/plate_loaded_chest_press_incline.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 156 | Prone Quad Stretch | quadriceps | Bodyweight | `prone_quad_stretch.png` | `docs/planning/exercise-images/generated/prone_quad_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 157 | Prone Scorpion | hip_flexors | Bodyweight | `prone_scorpion.png` | `docs/planning/exercise-images/generated/prone_scorpion.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 158 | Ram Murti Dand (Dive Bomber Push-Up) | shoulders | Bodyweight | `ram_murti_dand_dive_bomber_push_up.png` | `docs/planning/exercise-images/generated/ram_murti_dand_dive_bomber_push_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 159 | Rassi Chadna (Rope Climbing) | latissimus_dorsi | rope | `rassi_chadna_rope_climbing.png` | `docs/planning/exercise-images/generated/rassi_chadna_rope_climbing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 160 | Recumbent Bike Easy | quadriceps | Stationary Bike | `recumbent_bike_easy.png` | `docs/planning/exercise-images/generated/recumbent_bike_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 161 | Reverse Cable Fly On Crossover | Upper Back (Rhomboids | Resistance Band | `reverse_cable_fly_on_crossover.png` | `docs/planning/exercise-images/generated/reverse_cable_fly_on_crossover.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 162 | Reverse Grip Lat Pulldown | lats | Lat Pulldown Machine | `reverse_grip_lat_pulldown.png` | `docs/planning/exercise-images/generated/reverse_grip_lat_pulldown.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 163 | Reverse Hack Squat | glutes | Hack Squat Machine | `reverse_hack_squat.png` | `docs/planning/exercise-images/generated/reverse_hack_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 164 | Reverse Lunge With Overhead Reach | quadriceps | Bodyweight | `reverse_lunge_with_overhead_reach.png` | `docs/planning/exercise-images/generated/reverse_lunge_with_overhead_reach.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 165 | Reverse Pec Deck | rear_delts | Pec Fly Machine | `reverse_pec_deck.png` | `docs/planning/exercise-images/generated/reverse_pec_deck.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 166 | Rowing Machine Arms Only | lats | Rowing Machine | `rowing_machine_arms_only.png` | `docs/planning/exercise-images/generated/rowing_machine_arms_only.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 167 | Rowing Machine Easy | lats | Rowing Machine | `rowing_machine_easy.png` | `docs/planning/exercise-images/generated/rowing_machine_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 168 | Rowing Machine Intervals | lats | Rowing Machine | `rowing_machine_intervals.png` | `docs/planning/exercise-images/generated/rowing_machine_intervals.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 169 | Rowing Machine Legs Only | quadriceps | Rowing Machine | `rowing_machine_legs_only.png` | `docs/planning/exercise-images/generated/rowing_machine_legs_only.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 170 | Rowing Machine Moderate | lats | Rowing Machine | `rowing_machine_moderate.png` | `docs/planning/exercise-images/generated/rowing_machine_moderate.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 171 | Rowing Machine Pick Drill | lats | Rowing Machine | `rowing_machine_pick_drill.png` | `docs/planning/exercise-images/generated/rowing_machine_pick_drill.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 172 | Samtola Bent-Over Row | latissimus_dorsi | samtola (indian barbell) | `samtola_bent_over_row.png` | `docs/planning/exercise-images/generated/samtola_bent_over_row.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 173 | Samtola Bicep Curl | biceps | samtola (indian barbell) | `samtola_bicep_curl.png` | `docs/planning/exercise-images/generated/samtola_bicep_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 174 | Samtola Overhead Press | shoulders | samtola (indian barbell) | `samtola_overhead_press.png` | `docs/planning/exercise-images/generated/samtola_overhead_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 175 | Samtola Rotational Swing | core | samtola (indian barbell) | `samtola_rotational_swing.png` | `docs/planning/exercise-images/generated/samtola_rotational_swing.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 176 | Sandbag Bear Hug Carry | core | sandbag | `sandbag_bear_hug_carry.png` | `docs/planning/exercise-images/generated/sandbag_bear_hug_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 177 | Sandbag Bent-Over Row | latissimus dorsi | sandbag | `sandbag_bent_over_row.png` | `docs/planning/exercise-images/generated/sandbag_bent_over_row.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 178 | Sandbag Clean | glutes | sandbag | `sandbag_clean.png` | `docs/planning/exercise-images/generated/sandbag_clean.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 179 | Sandbag Clean And Press | deltoids | sandbag | `sandbag_clean_and_press.png` | `docs/planning/exercise-images/generated/sandbag_clean_and_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 180 | Sandbag Deadlift | hamstrings | sandbag | `sandbag_deadlift.png` | `docs/planning/exercise-images/generated/sandbag_deadlift.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 181 | Sandbag Drag | glutes | sandbag | `sandbag_drag.png` | `docs/planning/exercise-images/generated/sandbag_drag.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 182 | Sandbag Front Squat | quadriceps | sandbag | `sandbag_front_squat.png` | `docs/planning/exercise-images/generated/sandbag_front_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 183 | Sandbag Get-Up | core | sandbag | `sandbag_get_up.png` | `docs/planning/exercise-images/generated/sandbag_get_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 184 | Sandbag Goblet Squat | quadriceps | sandbag | `sandbag_goblet_squat.png` | `docs/planning/exercise-images/generated/sandbag_goblet_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 185 | Sandbag Ground To Overhead | glutes | sandbag | `sandbag_ground_to_overhead.png` | `docs/planning/exercise-images/generated/sandbag_ground_to_overhead.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 186 | Sandbag Over Shoulder Toss | glutes | sandbag | `sandbag_over_shoulder_toss.png` | `docs/planning/exercise-images/generated/sandbag_over_shoulder_toss.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 187 | Sandbag Overhead Slam | core | sandbag | `sandbag_overhead_slam.png` | `docs/planning/exercise-images/generated/sandbag_overhead_slam.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 188 | Sandbag Reverse Lunge | glutes | sandbag | `sandbag_reverse_lunge.png` | `docs/planning/exercise-images/generated/sandbag_reverse_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 189 | Sandbag Rotational Lunge | glutes | sandbag | `sandbag_rotational_lunge.png` | `docs/planning/exercise-images/generated/sandbag_rotational_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 190 | Sandbag Rotational Throw | obliques | sandbag, wall | `sandbag_rotational_throw.png` | `docs/planning/exercise-images/generated/sandbag_rotational_throw.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 191 | Sandbag Shoulder Carry | core | sandbag | `sandbag_shoulder_carry.png` | `docs/planning/exercise-images/generated/sandbag_shoulder_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 192 | Sandbag Shouldering | glutes | sandbag | `sandbag_shouldering.png` | `docs/planning/exercise-images/generated/sandbag_shouldering.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 193 | Sandbag Thruster | quadriceps | sandbag | `sandbag_thruster.png` | `docs/planning/exercise-images/generated/sandbag_thruster.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 194 | Sandbag Walking Lunge | glutes | sandbag | `sandbag_walking_lunge.png` | `docs/planning/exercise-images/generated/sandbag_walking_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 195 | Sandbag Zercher Carry | core | sandbag | `sandbag_zercher_carry.png` | `docs/planning/exercise-images/generated/sandbag_zercher_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 196 | Sarpa Vadivu (Snake Stance) | core | Bodyweight | `sarpa_vadivu_snake_stance.png` | `docs/planning/exercise-images/generated/sarpa_vadivu_snake_stance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 197 | Scapular Pull-Up | traps | Pull-Up Bar | `scapular_pull_up.png` | `docs/planning/exercise-images/generated/scapular_pull_up.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 198 | Scorpion Stretch | hip_flexors | Bodyweight | `scorpion_stretch.png` | `docs/planning/exercise-images/generated/scorpion_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 199 | Seal Jack | chest | Bodyweight | `seal_jack.png` | `docs/planning/exercise-images/generated/seal_jack.png` | ✅ Done | ❌ Fail | ⬜ Pending |
| 200 | Seated Elbow In Alternating Dumbbell Overhead Pres | Full Body | Dumbbells | `seated_elbow_in_alternating_dumbbell_overhead_pres.png` | `docs/planning/exercise-images/generated/seated_elbow_in_alternating_dumbbell_overhead_pres.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 201 | Seated Forward Fold | hamstrings | Bodyweight | `seated_forward_fold.png` | `docs/planning/exercise-images/generated/seated_forward_fold.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 202 | Seated Hamstring Stretch | hamstrings | Bodyweight | `seated_hamstring_stretch.png` | `docs/planning/exercise-images/generated/seated_hamstring_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 203 | Seated Neck Rotation Stretch | traps | Bodyweight | `seated_neck_rotation_stretch.png` | `docs/planning/exercise-images/generated/seated_neck_rotation_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 204 | Seated Straddle Stretch | adductors | Bodyweight | `seated_straddle_stretch.png` | `docs/planning/exercise-images/generated/seated_straddle_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 205 | Sheaf Toss | deltoids | pitchfork, hay bale, sheaf bag | `sheaf_toss.png` | `docs/planning/exercise-images/generated/sheaf_toss.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 206 | Shinbox Get-Up | glutes | Bodyweight | `shinbox_get_up.png` | `docs/planning/exercise-images/generated/shinbox_get_up.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 207 | Shirshasana (Headstand) | core | Bodyweight | `shirshasana_headstand.png` | `docs/planning/exercise-images/generated/shirshasana_headstand.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 208 | Shoulder Cars | shoulders | Bodyweight | `shoulder_cars.png` | `docs/planning/exercise-images/generated/shoulder_cars.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 209 | Shoulder Sleeper Stretch | rear_delts | Bodyweight | `shoulder_sleeper_stretch.png` | `docs/planning/exercise-images/generated/shoulder_sleeper_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 210 | Simha Vadivu (Lion Stance) | quadriceps | Bodyweight | `simha_vadivu_lion_stance.png` | `docs/planning/exercise-images/generated/simha_vadivu_lion_stance.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 211 | Single-Leg Balance On Hay Bale | core | hay bale | `single_leg_balance_on_hay_bale.png` | `docs/planning/exercise-images/generated/single_leg_balance_on_hay_bale.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 212 | Single-Leg Curl | hamstrings | Leg Curl Machine | `single_leg_curl.png` | `docs/planning/exercise-images/generated/single_leg_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 213 | Single-Leg Extension | quadriceps | Leg Extension Machine | `single_leg_extension.png` | `docs/planning/exercise-images/generated/single_leg_extension.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 214 | Single-Leg Hamstring Stretch | hamstrings | Bodyweight | `single_leg_hamstring_stretch.png` | `docs/planning/exercise-images/generated/single_leg_hamstring_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 215 | Single-Leg Press | quadriceps | Leg Press Machine | `single_leg_press.png` | `docs/planning/exercise-images/generated/single_leg_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 216 | Sit-Ups | Abdominals | Bodyweight | `sit_ups.png` | `docs/planning/exercise-images/generated/sit_ups.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 217 | Ski Erg Easy | lats | ski_erg | `ski_erg_easy.png` | `docs/planning/exercise-images/generated/ski_erg_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 218 | Ski Erg Intervals | lats | ski_erg | `ski_erg_intervals.png` | `docs/planning/exercise-images/generated/ski_erg_intervals.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 219 | Sled Drag | glutes | sled | `sled_drag.png` | `docs/planning/exercise-images/generated/sled_drag.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 220 | Sled Pull | hamstrings | sled | `sled_pull.png` | `docs/planning/exercise-images/generated/sled_pull.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 221 | Sled Push | quadriceps | sled | `sled_push.png` | `docs/planning/exercise-images/generated/sled_push.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 222 | Smith Machine Bench Press | chest | Smith Machine | `smith_machine_bench_press.png` | `docs/planning/exercise-images/generated/smith_machine_bench_press.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 223 | Smith Machine Romanian Deadlift | hamstrings | Smith Machine | `smith_machine_romanian_deadlift.png` | `docs/planning/exercise-images/generated/smith_machine_romanian_deadlift.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 224 | Smith Machine Squat | quadriceps | Smith Machine | `smith_machine_squat.png` | `docs/planning/exercise-images/generated/smith_machine_squat.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 225 | Soleus Stretch | calves | Bodyweight | `soleus_stretch.png` | `docs/planning/exercise-images/generated/soleus_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 226 | Spiderman Lunge | hip_flexors | Bodyweight | `spiderman_lunge.png` | `docs/planning/exercise-images/generated/spiderman_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 227 | Spin Bike Hiit | quadriceps | Stationary Bike | `spin_bike_hiit.png` | `docs/planning/exercise-images/generated/spin_bike_hiit.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 228 | Squat To Stand | hamstrings | Bodyweight | `squat_to_stand.png` | `docs/planning/exercise-images/generated/squat_to_stand.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 229 | Stair Climber Easy | quadriceps | Stair Climber | `stair_climber_easy.png` | `docs/planning/exercise-images/generated/stair_climber_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 230 | Stair Climber Moderate | glutes | Stair Climber | `stair_climber_moderate.png` | `docs/planning/exercise-images/generated/stair_climber_moderate.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 231 | Stairmaster Calf Raise Step | calves | Stair Climber | `stairmaster_calf_raise_step.png` | `docs/planning/exercise-images/generated/stairmaster_calf_raise_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 232 | Stairmaster Crossover Step | adductors | Stair Climber | `stairmaster_crossover_step.png` | `docs/planning/exercise-images/generated/stairmaster_crossover_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 233 | Stairmaster Double Step Sprint | quadriceps | Stair Climber | `stairmaster_double_step_sprint.png` | `docs/planning/exercise-images/generated/stairmaster_double_step_sprint.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 234 | Stairmaster Intervals | quadriceps | Stair Climber | `stairmaster_intervals.png` | `docs/planning/exercise-images/generated/stairmaster_intervals.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 235 | Stairmaster Lateral Step Left | abductors | Stair Climber | `stairmaster_lateral_step_left.png` | `docs/planning/exercise-images/generated/stairmaster_lateral_step_left.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 236 | Stairmaster Lateral Step Right | abductors | Stair Climber | `stairmaster_lateral_step_right.png` | `docs/planning/exercise-images/generated/stairmaster_lateral_step_right.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 237 | Stairmaster Skip Step | glutes | Stair Climber | `stairmaster_skip_step.png` | `docs/planning/exercise-images/generated/stairmaster_skip_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 238 | Stairmaster Slow Deep Step | glutes | Stair Climber | `stairmaster_slow_deep_step.png` | `docs/planning/exercise-images/generated/stairmaster_slow_deep_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 239 | Standing Calf Stretch | calves | Bodyweight | `standing_calf_stretch.png` | `docs/planning/exercise-images/generated/standing_calf_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 240 | Standing Forward Fold (Uttanasana) | hamstrings | Bodyweight | `standing_forward_fold_uttanasana.png` | `docs/planning/exercise-images/generated/standing_forward_fold_uttanasana.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 241 | Standing Hamstring Stretch | hamstrings | Bodyweight | `standing_hamstring_stretch.png` | `docs/planning/exercise-images/generated/standing_hamstring_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 242 | Standing Hay Baler | obliques | medicine ball, hay bale | `standing_hay_baler.png` | `docs/planning/exercise-images/generated/standing_hay_baler.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 243 | Standing Quad Stretch | quadriceps | Bodyweight | `standing_quad_stretch.png` | `docs/planning/exercise-images/generated/standing_quad_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 244 | Standing Side Bend | obliques | Bodyweight | `standing_side_bend.png` | `docs/planning/exercise-images/generated/standing_side_bend.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 245 | Stationary Bike Easy | quadriceps | Stationary Bike | `stationary_bike_easy.png` | `docs/planning/exercise-images/generated/stationary_bike_easy.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 246 | Stationary Bike High Cadence Spin | quadriceps | Stationary Bike | `stationary_bike_high_cadence_spin.png` | `docs/planning/exercise-images/generated/stationary_bike_high_cadence_spin.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 247 | Stationary Bike Light Spin | quadriceps | Stationary Bike | `stationary_bike_light_spin.png` | `docs/planning/exercise-images/generated/stationary_bike_light_spin.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 248 | Stationary Bike Moderate | quadriceps | Stationary Bike | `stationary_bike_moderate.png` | `docs/planning/exercise-images/generated/stationary_bike_moderate.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 249 | Stationary Bike Single-Leg Drill | quadriceps | Stationary Bike | `stationary_bike_single_leg_drill.png` | `docs/planning/exercise-images/generated/stationary_bike_single_leg_drill.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 250 | Stationary Bike Standing Climb | glutes | Stationary Bike | `stationary_bike_standing_climb.png` | `docs/planning/exercise-images/generated/stationary_bike_standing_climb.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 251 | Stationary Bike Tabata Sprint | quadriceps | Stationary Bike | `stationary_bike_tabata_sprint.png` | `docs/planning/exercise-images/generated/stationary_bike_tabata_sprint.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 252 | Sun Salutation A | core | Bodyweight | `sun_salutation_a.png` | `docs/planning/exercise-images/generated/sun_salutation_a.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 253 | Supine Hamstring Stretch | hamstrings | Bodyweight | `supine_hamstring_stretch.png` | `docs/planning/exercise-images/generated/supine_hamstring_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 254 | Supine Spinal Twist | obliques | Bodyweight | `supine_spinal_twist.png` | `docs/planning/exercise-images/generated/supine_spinal_twist.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 255 | Surya Namaskar (Sun Salutation) | full_body | Bodyweight | `surya_namaskar_sun_salutation.png` | `docs/planning/exercise-images/generated/surya_namaskar_sun_salutation.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 256 | Suspension Trainer With Grips Wide-Grip Inverted Row On Floor | Upper Back (Trapezius | Suspension Trainer | `suspension_trainer_with_grips_wide_grip_inverted_row_on_floor.png` | `docs/planning/exercise-images/generated/suspension_trainer_with_grips_wide_grip_inverted_row_on_floor.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 257 | Thoracic Rotation Quadruped | thoracic_spine | Bodyweight | `thoracic_rotation_quadruped.png` | `docs/planning/exercise-images/generated/thoracic_rotation_quadruped.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 258 | Thread The Needle | thoracic_spine | Bodyweight | `thread_the_needle.png` | `docs/planning/exercise-images/generated/thread_the_needle.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 259 | Tire Box Jump | quadriceps | tire | `tire_box_jump.png` | `docs/planning/exercise-images/generated/tire_box_jump.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 260 | Tire Center Squat Jump | quadriceps | tire | `tire_center_squat_jump.png` | `docs/planning/exercise-images/generated/tire_center_squat_jump.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 261 | Tire Drag Backward | quadriceps | tire, harness, rope | `tire_drag_backward.png` | `docs/planning/exercise-images/generated/tire_drag_backward.png` | ✅ Done | ❌ Fail | ⬜ Pending |
| 262 | Tire Drag Forward | glutes | tire, harness, rope | `tire_drag_forward.png` | `docs/planning/exercise-images/generated/tire_drag_forward.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 263 | Tire Flip | quadriceps | tire | `tire_flip.png` | `docs/planning/exercise-images/generated/tire_flip.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 264 | Tire Lateral Jumps | quadriceps | tire | `tire_lateral_jumps.png` | `docs/planning/exercise-images/generated/tire_lateral_jumps.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 265 | Tire Push | quadriceps | tire | `tire_push.png` | `docs/planning/exercise-images/generated/tire_push.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 266 | Tire Quick Feet | calves | tire | `tire_quick_feet.png` | `docs/planning/exercise-images/generated/tire_quick_feet.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 267 | Tire Single-Leg Box Jump | quadriceps | tire | `tire_single_leg_box_jump.png` | `docs/planning/exercise-images/generated/tire_single_leg_box_jump.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 268 | Tire Sledgehammer Overhead Slams | core | tire, sledgehammer | `tire_sledgehammer_overhead_slams.png` | `docs/planning/exercise-images/generated/tire_sledgehammer_overhead_slams.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 269 | Tire Sledgehammer Side Slams | obliques | tire, sledgehammer | `tire_sledgehammer_side_slams.png` | `docs/planning/exercise-images/generated/tire_sledgehammer_side_slams.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 270 | Tire Step-Ups | quadriceps | tire | `tire_step_ups.png` | `docs/planning/exercise-images/generated/tire_step_ups.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 271 | Tire-Anchored Battle Rope Slams | shoulders | tire, battle ropes | `tire_anchored_battle_rope_slams.png` | `docs/planning/exercise-images/generated/tire_anchored_battle_rope_slams.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 272 | Tire-Anchored Battle Rope Waves | shoulders | tire, battle ropes | `tire_anchored_battle_rope_waves.png` | `docs/planning/exercise-images/generated/tire_anchored_battle_rope_waves.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 273 | Torso Twist | obliques | Bodyweight | `torso_twist.png` | `docs/planning/exercise-images/generated/torso_twist.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 274 | Towel Hang | forearms | Pull-Up Bar | `towel_hang.png` | `docs/planning/exercise-images/generated/towel_hang.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 275 | Treadmill Backward Walk | quadriceps | Treadmill | `treadmill_backward_walk.png` | `docs/planning/exercise-images/generated/treadmill_backward_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 276 | Treadmill Gradient Pyramid | glutes | Treadmill | `treadmill_gradient_pyramid.png` | `docs/planning/exercise-images/generated/treadmill_gradient_pyramid.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 277 | Treadmill High Knee Walk | hip_flexors | Treadmill | `treadmill_high_knee_walk.png` | `docs/planning/exercise-images/generated/treadmill_high_knee_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 278 | Treadmill Incline Jog | glutes | Treadmill | `treadmill_incline_jog.png` | `docs/planning/exercise-images/generated/treadmill_incline_jog.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 279 | Treadmill Incline Walk | glutes | Treadmill | `treadmill_incline_walk.png` | `docs/planning/exercise-images/generated/treadmill_incline_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 280 | Treadmill Jog | quadriceps | Treadmill | `treadmill_jog.png` | `docs/planning/exercise-images/generated/treadmill_jog.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 281 | Treadmill Power Walk | glutes | Treadmill | `treadmill_power_walk.png` | `docs/planning/exercise-images/generated/treadmill_power_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 282 | Treadmill Run | quadriceps | Treadmill | `treadmill_run.png` | `docs/planning/exercise-images/generated/treadmill_run.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 283 | Treadmill Side Shuffle Left | abductors | Treadmill | `treadmill_side_shuffle_left.png` | `docs/planning/exercise-images/generated/treadmill_side_shuffle_left.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 284 | Treadmill Side Shuffle Right | abductors | Treadmill | `treadmill_side_shuffle_right.png` | `docs/planning/exercise-images/generated/treadmill_side_shuffle_right.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 285 | Treadmill Sprint Intervals | quadriceps | Treadmill | `treadmill_sprint_intervals.png` | `docs/planning/exercise-images/generated/treadmill_sprint_intervals.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 286 | Treadmill Steep Incline Walk | glutes | Treadmill | `treadmill_steep_incline_walk.png` | `docs/planning/exercise-images/generated/treadmill_steep_incline_walk.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 287 | Treadmill Tempo Run | quadriceps | Treadmill | `treadmill_tempo_run.png` | `docs/planning/exercise-images/generated/treadmill_tempo_run.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 288 | Treadmill Walking Lunge | quadriceps | Treadmill | `treadmill_walking_lunge.png` | `docs/planning/exercise-images/generated/treadmill_walking_lunge.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 289 | Triangle Pose (Trikonasana) | hamstrings | Bodyweight | `triangle_pose_trikonasana.png` | `docs/planning/exercise-images/generated/triangle_pose_trikonasana.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 290 | Triceps Rope Extension On Crossover Machine | Triceps | Cable Machine | `triceps_rope_extension_on_crossover_machine.png` | `docs/planning/exercise-images/generated/triceps_rope_extension_on_crossover_machine.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 291 | Upward Facing Dog | chest | Bodyweight | `upward_facing_dog.png` | `docs/planning/exercise-images/generated/upward_facing_dog.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 292 | Walking Knee Hug | glutes | Bodyweight | `walking_knee_hug.png` | `docs/planning/exercise-images/generated/walking_knee_hug.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 293 | Walking Lunge With Rotation | quadriceps | Bodyweight | `walking_lunge_with_rotation.png` | `docs/planning/exercise-images/generated/walking_lunge_with_rotation.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 294 | Walking Quad Pull | quadriceps | Bodyweight | `walking_quad_pull.png` | `docs/planning/exercise-images/generated/walking_quad_pull.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 295 | Wall Slide | shoulders | Bodyweight | `wall_slide.png` | `docs/planning/exercise-images/generated/wall_slide.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 296 | Warrior I | quadriceps | Bodyweight | `warrior_i.png` | `docs/planning/exercise-images/generated/warrior_i.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 297 | Warrior Ii | quadriceps | Bodyweight | `warrior_ii.png` | `docs/planning/exercise-images/generated/warrior_ii.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 298 | Wide-Grip Hang | lats | Pull-Up Bar | `wide_grip_hang.png` | `docs/planning/exercise-images/generated/wide_grip_hang.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 299 | Wide-Grip Lat Pulldown | lats | Lat Pulldown Machine | `wide_grip_lat_pulldown.png` | `docs/planning/exercise-images/generated/wide_grip_lat_pulldown.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 300 | Wide-Grip Seated Row | upper_back | Seated Row Machine | `wide_grip_seated_row.png` | `docs/planning/exercise-images/generated/wide_grip_seated_row.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 301 | World's Greatest Stretch | hip_flexors | Bodyweight | `world_s_greatest_stretch.png` | `docs/planning/exercise-images/generated/world_s_greatest_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 302 | Wrist Extensor Stretch | forearms | Bodyweight | `wrist_extensor_stretch.png` | `docs/planning/exercise-images/generated/wrist_extensor_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 303 | Wrist Flexor Stretch | forearms | Bodyweight | `wrist_flexor_stretch.png` | `docs/planning/exercise-images/generated/wrist_flexor_stretch.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 304 | Zotman Curl Dumbbell Simultaneous | Biceps | Dumbbells | `zotman_curl_dumbbell_simultaneous.png` | `docs/planning/exercise-images/generated/zotman_curl_dumbbell_simultaneous.png` | ✅ Done | ✅ Pass | ⬜ Pending |

---

## Base-origin exercises (14)

| # | Exercise | Target | Equipment | Image Filename | Generated Path | Image Generated | Validation | S3 Upload |
|---|----------|--------|-----------|----------------|----------------|-----------------|------------|-----------|
| 1 | 4 Coners Side Step | Quadriceps | Bodyweight | `4_coners_side_step.png` | `docs/planning/exercise-images/generated/4_coners_side_step.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 2 | Band Hammer Grip Incline Bench Two Arm Row | Full Body | Resistance Band | `band_hammer_grip_incline_bench_two_arm_row.png` | `docs/planning/exercise-images/generated/band_hammer_grip_incline_bench_two_arm_row.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 3 | Barbell Finger Curls | Grip Muscles (Flexor Digitorum Superficialis | Barbell | `barbell_finger_curls.png` | `docs/planning/exercise-images/generated/barbell_finger_curls.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 4 | Behind-The-Back Wrist Curl | Forearms (Flexor Carpi Radialis | Barbell | `behind_the_back_wrist_curl.png` | `docs/planning/exercise-images/generated/behind_the_back_wrist_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 5 | Cable Twisting Curl | Full Body | Cable Machine | `cable_twisting_curl.png` | `docs/planning/exercise-images/generated/cable_twisting_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 6 | Dumbbell Wrist Curl | Forearms (Flexor Carpi Radialis | Dumbbells | `dumbbell_wrist_curl.png` | `docs/planning/exercise-images/generated/dumbbell_wrist_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 7 | Farmer's Carry | Forearms | Dumbbells | `farmer_s_carry.png` | `docs/planning/exercise-images/generated/farmer_s_carry.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 8 | Farmer's Hold | Forearms | Dumbbells | `farmer_s_hold.png` | `docs/planning/exercise-images/generated/farmer_s_hold.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 9 | Gripper Crush | Forearms (Grip - Flexor Digitorum Superficialis | Grip Trainer | `gripper_crush.png` | `docs/planning/exercise-images/generated/gripper_crush.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 10 | Plate Pinch Hold | Forearms (Grip - Flexor Digitorum Superficialis | Weight Plate | `plate_pinch_hold.png` | `docs/planning/exercise-images/generated/plate_pinch_hold.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 11 | Reverse Curl | Forearms | Barbell | `reverse_curl.png` | `docs/planning/exercise-images/generated/reverse_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 12 | Reverse Wrist Curl | Forearms (Extensor Carpi Radialis | Barbell | `reverse_wrist_curl.png` | `docs/planning/exercise-images/generated/reverse_wrist_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
| 13 | Single-Arm Rear Delt Machine Fly | Shoulders | Pec Deck / Fly Machine | `single_arm_rear_delt_machine_fly.png` | `docs/planning/exercise-images/generated/single_arm_rear_delt_machine_fly.png` | ✅ Done | ⚠️ Review | ⬜ Pending |
| 14 | Zottman Curl | Biceps | Dumbbells | `zottman_curl.png` | `docs/planning/exercise-images/generated/zottman_curl.png` | ✅ Done | ✅ Pass | ⬜ Pending |
