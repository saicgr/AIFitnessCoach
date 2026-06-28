# Program Library — Missing-Media Cross-Check v3 (ALL stores)

151 missing exercises matched against all 3 media stores: `exercise_canonical`+`exercise_demos` (alias-fixable now), `exercise_library_cleaned`, `exercise_library_manual` (both = bridge into demo stack to show). Non-exercises flagged.

## By media_store
| media_store | Exercises | Instances |
|---|---:|---:|
| canonical_demo | 98 | 261 |
| cleaned | 40 | 266 |
| manual | 3 | 6 |
| not_exercise | 1 | 2 |
| none | 9 | 16 |
| **TOTAL** | **151** | **551** |

- **Group 1 — alias now (canonical_demo): 98 ex / 261 inst** → coverage 89.1% → ~94.3%
- **Group 2 — bridge cleaned/manual→demo: 43 ex / 272 inst** → +5.4pts more
- **Combined recoverable: 141 ex / 533 of 551 inst (97%)** → coverage → ~99.6%
- Not an exercise: 1 · Genuinely none: 9

## Master table (by instances)
| # | Exercise | Inst | → Match | Store | canonical_exercise_id | Conf | Notes |
|---|---|---:|---|---|---|---|---|
| 1 | Samtola Overhead Press | 64 | Samtola Overhead Press | cleaned | a6061c4a-64c8-4c5d-8af8-83e568741b69 | high | Exact name match in cleaned (image+video); canonical exists but has_demo=false; not alias-fixable, media available in cleaned/manual |
| 2 | Sandbag Walking Lunge | 53 | Sandbag Walking Lunge | cleaned | 1fe132d7-4783-4ccb-8dca-40c40ae33d99 | high | Exact name match in cleaned (image+video); canonical exists but has_demo=false; not alias-fixable, media in cleaned |
| 3 | Sandbag Reverse Lunge | 42 | Sandbag Reverse Lunge | cleaned | 024cbd8d-7006-42cb-b4e7-50277f7143a2 | high | Exact name match in cleaned (image+video); canonical exists but has_demo=false; not alias-fixable, media in cleaned |
| 4 | Dumbbell single arm row | 31 | dumbbells single arm row | canonical_demo | 3404e7c0-7e07-4d83-8a3e-eff20d064f05 | high | Plural/case variant; same back/dumbbell row; canonical "Dumbbell single arm row" (0d0eaf7d) has_demo=false; alias to demo-backed "dumbbells single arm row" |
| 5 | Run | 23 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | Run-family; same outdoor running movement; has_demo=true |
| 6 | Incline dumbbell curl | 22 | Incline Dumbbell Curl | cleaned | c9552c23-be15-4328-a0bd-24f3c561a652 | high | Exact name match in cleaned (image+video); canonical exists (6ff4b7fe) but has_demo=false; not alias-fixable, media in cleaned |
| 7 | SkiErg | 20 | Ski Erg Easy | cleaned | 42e56ad9-ba0c-4ef9-b169-385e6031586f | medium | No plain SkiErg canonical with demo; "Ski Erg Easy" in cleaned has media and is same machine/lats movement; not alias-fixable |
| 8 | Overhead Barbell Press | 17 | Barbell standing shoulder press | canonical_demo | c75b1a72-e05a-44ca-840e-30828334fa12 | high | Standing barbell overhead press = barbell standing shoulder press; same deltoid/barbell/standing; has_demo=true; alias-fixable |
| 9 | Interval Run | 13 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | Run-family rule; modifier stripped; has_demo=true |
| 10 | Standing Military Press | 11 | Barbell standing military press | canonical_demo | fa8e1675-93d7-4904-9eea-1f87cfd3fb45 | high | Word-order variant; same standing barbell shoulder press; has_demo=true; alias-fixable |
| 11 | Wall Balls | 9 | Wall Ball | cleaned | ac5718ae-fb64-4806-a1c4-a7ff92d2b32a | high | Plural variant; exact match in cleaned (image, no video); also in manual; no canonical with demo; not alias-fixable |
| 12 | SkiErg Intervals | 8 | Ski Erg Intervals | cleaned | 52f08f58-73db-4930-bf87-5017556483f9 | high | Spacing variant (SkiErg vs Ski Erg); exact match in cleaned (image+video); same machine/lats; not alias-fixable |
| 13 | Steady State Run | 8 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | Run-family rule; modifier stripped; has_demo=true |
| 14 | Pelvic Tilts | 7 |  | none |  | none | Not found in any store (canonical, cleaned, manual); genuinely absent |
| 15 | SkiErg Interval | 7 | Ski Erg Intervals | cleaned | 52f08f58-73db-4930-bf87-5017556483f9 | high | Singular/spacing variant; exact match in cleaned (image+video); same machine/lats; not alias-fixable |
| 16 | Triceps Rope Pushdown | 7 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | medium | Shortest generic cable pushdown with has_demo=true; rope attachment not in name but same tricep/cable movement; alias-fixable |
| 17 | Pushups | 6 | Normal Push-up | canonical_demo | cfeba482-fc43-4431-b1a9-29c32259749c | high | Plain standard push-up; has_demo=true; also "Push ups bodyweight" (0f4eec76) available; Normal Push-up is shortest clean generic; alias-fixable |
| 18 | Seated Dumbbell Press | 6 | Dumbbell Seated Shoulder Press | canonical_demo | 51b2bddf-1cea-4520-a38b-a659dd3eecf9 | high | Word-order/abbreviation variant; same seated dumbbell shoulder press; has_demo=true; alias-fixable |
| 19 | Tricep Cable Pushdowns | 6 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | high | Plural/word-order variant; same cable tricep pushdown; has_demo=true; alias-fixable |
| 20 | Wall Ball Shots | 6 | Wall Ball | cleaned | ac5718ae-fb64-4806-a1c4-a7ff92d2b32a | high | HYROX terminology for wall ball; exact match in cleaned (image); no canonical with demo; not alias-fixable |
| 21 | Wall Sit With March | 6 | Wall sit bodyweight | canonical_demo | 97f4ce25-c145-458f-b0c7-f5094bda697b | medium | Base wall sit matches; March modifier not captured; same quads/bodyweight; has_demo=true; alias-fixable for wall sit portion |
| 22 | Chest Dips | 5 | Chest dip | canonical_demo | df9785bd-8c02-4ad4-816a-e94e8f4bd73c | high | Plural variant; exact same chest dip; has_demo=true; alias-fixable |
| 23 | Treadmill Run Intervals | 5 | Treadmill Running | canonical_demo | 07e29142-0323-4160-b70b-b5b4b0db04b7 | medium | No treadmill interval canonical; Treadmill Running same machine/muscle with has_demo=true; interval pacing not depicted |
| 24 | Cable Flyes | 4 | Cable middle fly | canonical_demo | 553297e8-4a2a-42fc-8763-8b2e4c8f0268 | low | Multiple cable fly angles all have_demo=true; middle fly chosen as neutral chest default; angle mismatch possible without workout context |
| 25 | Narrow Squat | 4 | Barbell narrow stance squat | canonical_demo | 5c1061d5-ee95-4fe6-9fab-881f502e135b | medium | Same narrow-stance squat; canonical specifies barbell; also "Dumbbell narrow stance squats" (9bdc916a) has_demo=true; barbell chosen as most common |
| 26 | Standard Push-up | 4 | Normal Push-up | canonical_demo | cfeba482-fc43-4431-b1a9-29c32259749c | high | "Standard" is redundant modifier; Normal Push-up is plain generic push-up with has_demo=true; alias-fixable |
| 27 | Goblet Bulgarian Split Squat | 3 | Bulgarian split squat | canonical_demo | 6e99af19-1567-4377-ab36-404947aea75e | high | Core=split squat; Bulgarian split squat (len 21, has_demo) matches exact movement; goblet hold is equipment modifier — core pattern identical |
| 28 | Tricep Cable Pushdown | 3 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | high | Core=pushdown; Cable pushdown (len 14, has_demo) is shortest canonical; exact movement match |
| 29 | Tricep Rope Pushdown | 3 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | high | Core=pushdown; no rope-specific canonical; Cable pushdown is correct base with demo; rope is attachment modifier only |
| 30 | Wide Grip Push-ups | 3 | Wide push ups bodyweight | canonical_demo | 6f538efb-f69d-4311-88f4-5f8aa61a030f | high | Core=wide push up; only canonical entry with demo (len 24); exact exercise match |
| 31 | Cable Tricep Extensions | 2 | Cable lying triceps extension | canonical_demo | df1d1a32-8188-41cb-8a31-568c103c9e74 | high | Core=cable tricep extension; shortest cable+tricep extension in canonical with demo; same muscle/equipment |
| 32 | Cow Face Pose (Arms) | 2 | Single-Arm Cow Face Pose - Easy | cleaned |  | medium | Not in canonical; exercise_library_cleaned has Single-Arm Cow Face Pose - Easy (has_media=true); same pose arms variant; bridgeable to canonical via alias |
| 33 | Diamond Pushups | 2 | Diamond push up | canonical_demo | 737b6e4d-fc93-4f39-bdf1-a232eae651b6 | high | Core=diamond push up; shortest canonical with demo (len 15); exact exercise match |
| 34 | Dumbbell Chest Supported Row | 2 | Dumbbell Incline Row | canonical_demo | 086241d3-f6e9-463d-9364-998472db7e11 | medium | No chest-supported-row in any store; Dumbbell Incline Row (len 20, has_demo) is closest dumbbell back-row variant — incline bench creates same chest-supported position |
| 35 | Dumbbell Press | 2 | Dumbbell Bench Press | canonical_demo | 2851d5e9-f6a8-4972-92c6-d9fe71a80419 | high | Core=dumbbell press; Dumbbell Bench Press (len 20, has_demo); shorter names (W press, Hex, Tate, Svend, Push Press) are specialty movements — reject |
| 36 | Dumbbell Seated Close Grip Press | 2 | Dumbbell Seated Close Grip Press | canonical_demo | 2e1087d9-e840-471c-b8f7-7d10c79db0fd | medium | Exact canonical name match but has_demo=false; entry exists and is alias-fixable; cleaned has it with media (in_base=true per source CSV) |
| 37 | Glute Bridge Pulse | 2 | Barbell glute bridge | canonical_demo | 3cf98f83-d5d0-4c25-893e-a65f1a0cef47 | medium | Core=glute bridge; Barbell glute bridge (len 20, has_demo) is shortest canonical glute bridge; pulse modifier absent; barbell qualifier minor mismatch |
| 38 | Goblet Box Squat | 2 | Dumbbell Goblet Squat | canonical_demo | 81ceecf6-1786-4e4e-850d-e85cf9202864 | medium | Core=goblet squat; Dumbbell Goblet Squat (len 21, has_demo); box touch-down modifier absent; same goblet squat pattern |
| 39 | Goblet Lunge | 2 | Dumbbell Goblet Forward Lunge | canonical_demo | a32fcde6-f2f0-4dcc-9e27-21e9a7169d53 | high | Core=goblet lunge; Dumbbell Goblet Forward Lunge (len 29, has_demo); forward lunge is standard goblet lunge; same muscle+equipment |
| 40 | Incline Cable Flyes | 2 | Incline bench cable fly | canonical_demo | 50f52f5b-830c-4b53-9cb7-03993c4c050c | high | Core=incline cable fly; Incline bench cable fly (len 23, has_demo); only match; plural/spelling variant only |
| 41 | Lateral Step-Ups | 2 | Dumbbell Step up on Bench | canonical_demo | f177e4dc-e2dd-4f54-b06a-ffd4ce952f79 | medium | Core=step up; no lateral step-up with demo in canonical; Dumbbell Step up on Bench (len 25, has_demo) is generic step-up — same movement; lateral direction absent; preferred over barbell variant |
| 42 | Lizard Lunge | 2 | Lizard Pose | cleaned |  | medium | Not in canonical; exercise_library_cleaned has Lizard Pose (has_media=true); same stretch (low hip-flexor lunge); yoga synonym; bridgeable to canonical via alias |
| 43 | Pelvic Tilt | 2 |  | not_exercise |  | none | Not in any store; pelvic tilt is a rehab/corrective movement not catalogued as a discrete exercise in this library |
| 44 | Pyramid Pose | 2 |  | none |  | none | Not in canonical or cleaned; manual Treadmill Gradient Pyramid is wrong exercise (cardio protocol); no valid pyramid pose match in any store |
| 45 | Rowing 1000m | 2 | Gym Rowing Machine Fast Speed | canonical_demo | e1a2cda4-0c68-46ce-a972-7e404fe65006 | medium | Core=rowing machine; Gym Rowing Machine Fast Speed (len 29, has_demo) is shortest canonical rowing machine entry; distance (1000m) vs effort/speed naming |
| 46 | Rowing 1km | 2 | Gym Rowing Machine Fast Speed | canonical_demo | e1a2cda4-0c68-46ce-a972-7e404fe65006 | medium | Same as idx 45 — distance variant of rowing machine; same canonical match |
| 47 | Samtola Bicep Curl | 2 | Samtola Bicep Curl | manual |  | high | Not in canonical; exercise_library_manual has Samtola Bicep Curl (has_media=true); exact name match; niche Indian barbell; bridgeable to canonical via alias |
| 48 | Sandbag Shoulder Carry | 2 | Sandbag Shoulder Carry | manual |  | high | Not in canonical; exercise_library_manual has Sandbag Shoulder Carry (has_media=true); exact name match; bridgeable to canonical via alias |
| 49 | Sphinx Pose | 2 | Sphinx Pose | manual |  | high | Not in canonical; exercise_library_manual has Sphinx Pose (has_media=true); exact name match; bridgeable to canonical via alias |
| 50 | Stationary Lunge | 2 | Dumbbell Static Lunge | canonical_demo | 5965671f-a20b-4cf8-929d-a9942127d3ec | high | Core=static/stationary lunge; Dumbbell Static Lunge (len 21, has_demo) is only canonical entry; stationary=static exact same movement |
| 51 | Sumo Squat Pulses | 2 | Kettlebell sumo squat | canonical_demo | 77714a45-67c2-4cb3-a9f2-6a739c79d4bc | medium | Core=sumo squat; Kettlebell sumo squat (len 21, has_demo) is shortest canonical sumo squat; pulse modifier absent; KB vs bodyweight minor mismatch |
| 52 | Sun Salutation A | 2 | Sun Salutation A | cleaned | a20679bb-9261-45e6-833c-95f2f4e97016 | high | exact name match in cleaned; has image; canonical has same pose but no demo |
| 53 | Triceps Cable Pushdowns | 2 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | high | shortest generic cable pushdown with demo; plural/modifier dropped; alias-fixable |
| 54 | Wide Leg Forward Fold | 2 | Wide-Legged Forward Fold (Prasarita Padottanasana) | cleaned | 8779a403-b635-4539-969c-5570be9803b8 | high | same yoga pose; minor name variant; has image in cleaned; not in canonical |
| 55 | 800m Run | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | rule: distance-specific run maps to generic Running; has_demo=true |
| 56 | Air Squat Pulse | 1 | Bodyweight pulse squat | canonical_demo | 90a6f168-a1ea-4861-8a03-554fa7d45f3c | high | same unweighted squat pulse; shortest match; has_demo=true |
| 57 | Alternating Forward Lunge | 1 | Bodyweight forward lunge | canonical_demo | c76b4891-54ca-471f-8b6e-7abccf61de9e | medium | base movement matches; alternating modifier dropped; shortest forward lunge with demo |
| 58 | Assisted Squat | 1 | none | none |  | none | no assisted squat in any store; Assisted Pistol Squat is a different exercise; no generic squat entry without modifier |
| 59 | Banded Paloff Press | 1 | Band Palloff Press | canonical_demo | c59e49a1-407d-4262-9a26-ad7517acb8e5 | high | spelling variant (Paloff/Palloff); same anti-rotation core press; has_demo=true |
| 60 | Banded Pull-Aparts | 1 | Resistance Band Pull Apart | canonical_demo | 8b26cbf3-98d9-4beb-bfdc-3986b38d428d | high | same movement; name variant; rear deltoids/upper back; has_demo=true |
| 61 | Bent Over Rear Delt Flyes | 1 | Bent over rear delt fly dumbbell | canonical_demo | 6fe48310-ba51-4c40-a9b3-9414dbcf9b9d | high | plural/hyphen variant; same posterior delt movement; has_demo=true |
| 62 | Bicep Barbell Curls | 1 | Barbell biceps curl | canonical_demo | b4de35da-089c-4cbf-94cb-02d5921aac51 | high | word-order/plural variant; same exercise; has_demo=true |
| 63 | Bird Dog with Extension | 1 | Bird dog | canonical_demo | 9b69e598-a4f8-4d23-922a-6b4a92b29fbf | medium | extension modifier dropped; same core/glute pattern; has_demo=true |
| 64 | Cable Woodchoppers | 1 | Cable Woodchop | cleaned | 09e868fe-5fe2-4cd5-8de1-cd83e1c7d21c | high | plural variant; Cable Woodchop exists in cleaned with image; not present in canonical |
| 65 | Calf Raise Hold | 1 | Calf Raise | cleaned | c88303b6-f900-481b-a769-bee0642599ad | high | hold modifier dropped; cleaned has Calf Raise with image+video; canonical only has specialised variants |
| 66 | Child's Pose with Reach | 1 | Child pose | canonical_demo | 818012cd-44b9-4463-a782-37b9f69dc028 | medium | reach modifier dropped; same base yoga stretch; has_demo=true |
| 67 | Close Grip Tricep Pushdowns | 1 | Cable triceps push down ez bar close grip | canonical_demo | 18005f7b-d4bb-4b75-84c9-535404661a08 | high | close grip cable tricep pushdown; same movement; has_demo=true |
| 68 | Commando Plank | 1 | none | none |  | none | no commando plank (up-down elbow-to-hand plank) in any store; Commando pull-up is a different exercise |
| 69 | Cow Face Pose | 1 | Single-Arm Cow Face Pose - Easy | cleaned | a83ccc09-855b-48da-b1dc-683f89ecf90b | medium | only cow face variant in any store; has image+video; single-arm modifier; no bilateral full-pose entry anywhere |
| 70 | Crescent Lunge Twist | 1 | none | none |  | none | no crescent lunge twist in any store; Landmine Alternating Lunge And Twist is wrong equipment; Crescent Moon Pose is different |
| 71 | Deadbugs | 1 | Dead bug | canonical_demo | fe0b6104-486c-4adb-b6e8-08a9e89ca366 | high | plural/spacing variant; same core stability movement; has_demo=true |
| 72 | Deadlifts | 1 | Barbell Deadlift | canonical_demo | 1ebec698-91a6-49dd-ba18-15d0399c3179 | high | generic deadlifts maps to standard barbell deadlift; has_demo=true |
| 73 | Dips on Chair | 1 | Chair triceps dips | canonical_demo | 169a1681-e6e1-4a37-a213-87fcefdf93c0 | high | same exercise; word-order variant; has_demo=true |
| 74 | Dumbbell Farmer Carry | 1 | Dumbbell farmer walks | canonical_demo | 4a176e0f-94cf-4030-a9e7-1c2006dd98f5 | high | carry=walks; same loaded carry; has_demo=true |
| 75 | Dumbbell Farmer Walk | 1 | Dumbbell farmer walks | canonical_demo | 4a176e0f-94cf-4030-a9e7-1c2006dd98f5 | high | plural variant; same exercise; has_demo=true |
| 76 | Dumbbell Incline Bench | 1 | Dumbbell Incline Bench Press | canonical_demo | 9c6a3a6b-809a-499d-9db8-1bd7c2c84894 | high | truncated name; same upper chest press; has_demo=true |
| 77 | Dumbbell Low-Incline Press | 1 | Dumbbell Incline Bench Press | canonical_demo | 9c6a3a6b-809a-499d-9db8-1bd7c2c84894 | high | Low-incline is an angle modifier; canonical has_demo=true; shortest dumbbell incline press match |
| 78 | Dumbbell Seated Press | 1 | Dumbbell Seated Shoulder Press | canonical_demo | 51b2bddf-1cea-4520-a38b-a659dd3eecf9 | high | Shoulder dropped from display name; identical seated DB shoulder press; canonical has_demo=true |
| 79 | Dumbbell Skull Crushers | 1 | Dumbbell Skullcrusher | canonical_demo | 66816e3c-ed51-4996-a2ed-79c464697213 | high | Plural vs singular; identical lying triceps movement; canonical has_demo=true |
| 80 | Easy Run | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | Run-family rule: Easy is pacing modifier; canonical Running has_demo=true; shortest generic running match |
| 81 | Fast Feet | 1 | Fast feet | canonical_demo | d7e32bc6-4ac3-4f97-94c9-14b387c29975 | high | Exact name match (case only); canonical has_demo=true |
| 82 | Forward Fold | 1 | Standing Forward Fold (Uttanasana) | cleaned | f5ac4546-ea13-4c88-8d5b-32d72daa09b1 | high | Not in canonical; cleaned has_media=true; standing variant is the correct generic standing forward fold base |
| 83 | Frog Pose | 1 | Frog Stretch | cleaned | 4d542fbb-b611-485f-aa08-24b7f6b0c8e6 | medium | Not in canonical; Frog Stretch in cleaned has_media=true; hip/adductor target matches; Frog Jump is plyometric so rejected |
| 84 | Heavy Dumbbell Farmers Carry | 1 | Farmer's Carry | cleaned | 9cf7070b-2ada-4f76-92cf-8038b183c3b6 | high | Heavy is intensity modifier; Farmer's Carry in cleaned has_media=true; shortest generic carry match |
| 85 | Heavy Farmers Carry | 1 | Farmer's Carry | cleaned | 9cf7070b-2ada-4f76-92cf-8038b183c3b6 | high | Heavy modifier dropped; Farmer's Carry in cleaned has_media=true; same bilateral carry pattern |
| 86 | Heavy Kettlebell Carry | 1 | Farmer's Carry | cleaned | 9cf7070b-2ada-4f76-92cf-8038b183c3b6 | medium | Kettlebell implement variant; no KB-specific carry with media in canonical; Farmer's Carry (cleaned, has_media=true) is generic base; equipment differs but same trap/grip pattern |
| 87 | Inchworms | 1 | Inchworm | cleaned | 6eb1a907-97eb-4c5a-a3d4-ae6a7a9953bd | high | Plural vs singular; Inchworm in cleaned has_media=true; not in canonical but cleaned+manual match confirmed |
| 88 | Incline Wall Push-Up | 1 | Wall Push-Up | cleaned | dfceecb8-cf39-4f37-a530-522c27918ac4 | high | Wall is the incline surface; Wall Push-Up in cleaned has_media=true; more specific than base Push-Up; also in manual |
| 89 | Interval Running | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | high | Run-family rule: Interval is structure modifier; canonical Running has_demo=true; shortest generic running match |
| 90 | Jump Squat to Burpee | 1 | Burpee squat | canonical_demo | 469fbdde-f1ab-49e9-8af4-66b942f611d4 | medium | Burpee squat is the closest compound match (squat+burpee); canonical has_demo=true; display name implies sequence but same quads/glutes/full-body pattern |
| 91 | Kabaddi Cant Breathing Practice | 1 | not_exercise | none |  | none | Sport-specific breathing drill; no canonical or library equivalent; category=not_exercise |
| 92 | Kettlebell Farmer Carry | 1 | Farmer's Carry | cleaned | 9cf7070b-2ada-4f76-92cf-8038b183c3b6 | medium | Kettlebell implement variant; Farmer's Carry (cleaned, has_media=true) is the generic base; same bilateral carry pattern; equipment differs KB vs DB |
| 93 | Lateral Lunge Pulse | 1 | Lateral Lunge | cleaned | 422d0e63-49a0-4fa5-b065-7679489c4b2b | high | Pulse is tempo modifier; Lateral Lunge in cleaned has_media=true; bodyweight base, shortest lateral lunge match |
| 94 | Lateral Step Ups | 1 | Box Step-Up | cleaned | 0d5931a3-3bab-46fb-aacc-43edcc601712 | high | Lateral is direction qualifier; Box Step-Up in cleaned has_media=true; shortest generic step-up match; same quad/glute movement |
| 95 | Low Lunge with Hip Flexor Stretch | 1 | Low Lunge (Anjaneyasana) | cleaned | dc87d502-9c94-4ad9-b246-2bca5fb8c60e | high | Hip Flexor Stretch is descriptive suffix; Low Lunge (Anjaneyasana) in cleaned has_media=true; same yoga hip-flexor base; also in manual |
| 96 | Low Lunge with Reach | 1 | Low Lunge (Anjaneyasana) | cleaned | dc87d502-9c94-4ad9-b246-2bca5fb8c60e | high | Reach is arm-extension modifier; same base low lunge; cleaned has_media=true |
| 97 | Low Lunge with Twist | 1 | Low Lunge (Anjaneyasana) | cleaned | dc87d502-9c94-4ad9-b246-2bca5fb8c60e | high | Twist is rotation modifier; same base anjaneyasana; cleaned has_media=true |
| 98 | Lying Tricep Extensions | 1 | Dumbbell Lying Triceps Extension | cleaned | 62bc303c-556e-4310-8383-d9ad689f45c6 | high | Plural + dumbbell implied; Dumbbell Lying Triceps Extension in cleaned has_media=true; canonical 354c5eed also has_demo=true |
| 99 | Mobility Drills | 1 | not_exercise | none |  | none | Category/sequence label, not a discrete exercise; no canonical or library equivalent; category=not_exercise |
| 100 | Mobility Flow | 1 | not_exercise | none |  | none | Sequence label, not a discrete exercise; no canonical or library equivalent; category=not_exercise |
| 101 | Mountain Climber Twist | 1 | Mountain Climber | cleaned | 3284b7dd-367d-471e-a1ff-ec34fcb633f9 | high | Mountain Climber in cleaned has_media=true; shortest generic base; Cross-Body Mountain Climber Bridge (30167c41) also has_media=true and is closer for twist variant |
| 102 | Mountain Climber Twist | 1 | Mountain climbers | canonical_demo | 23606d49-41b5-4cd1-8fbc-8c91f3a9110a | medium | Twist is a cross-body modifier; Mountain climbers (len 17, shortest with demo) is the base; core/obliques/bodyweight; has demo |
| 103 | Narrow Stance Squat | 1 | Barbell narrow stance squat | canonical_demo | 5c1061d5-ee95-4fe6-9fab-881f502e135b | high | Exact movement, len 27 shortest named narrow squat with demo; quads/glutes; Dumbbell narrow stance squats also present |
| 104 | Pelvic Floor Engagement (Diaphragmatic Breathing) | 1 | not_exercise | none |  | none | Breathing/rehab cue — no pelvic floor/diaphragmatic breathing entry in any store; not a trackable exercise |
| 105 | Pike Pushups | 1 | Pike push up | canonical_demo | 01e08c24-d28d-4a95-9716-b0b448b561da | high | Exact match len 12 shortest pike push with demo; shoulders/anterior deltoids/bodyweight |
| 106 | Plank Leg Lifts | 1 | Alternate Single Leg Raise Plank | canonical_demo | 3a6f0607-beeb-4c53-bc30-929527c6fedb | medium | Same movement (plank + unilateral leg raise); glutes/core/bodyweight; has demo; no shorter plank-leg entry exists |
| 107 | Plank on Knees | 1 | Plank Knee Tucks | canonical_demo | 2218c0e7-b765-41a7-8244-a5d8391f1756 | low | Plank Knee Tucks len 16 shortest knee+plank canonical entry with demo; movement differs (tucks vs static hold) but same position/equipment; no kneeling plank hold in any store |
| 108 | Plank-to-Pushup | 1 | Elbow Push Plank Up | canonical_demo | f3b2f359-6d8e-407f-a5d2-763c326dc06c | high | Exact movement (elbow plank to high plank); len 19 shortest matching entry with demo; core/bodyweight |
| 109 | Progressive Run | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | medium | Progressive is a pacing modifier; Running len 7 shortest generic run with demo; full lower body cardio; no fartlek/tempo entry in any store |
| 110 | Prone T-Raises | 1 | Dumbbell Chest Supported Y Raise | cleaned | 5a301ee7-3f01-4d9d-8f36-041d75713da5 | medium | Y-raise is functional equivalent of T-raise (prone/supported, scapular retraction, posterior deltoids/lower trapezius); has image+video; no canonical entry — cleaned only |
| 111 | Pulsing Squat | 1 | Bodyweight pulse squat | canonical_demo | 90a6f168-a1ea-4861-8a03-554fa7d45f3c | high | Exact same movement len 22 shortest pulse squat with demo; quads/glutes/bodyweight |
| 112 | Push-up AMRAP | 1 | Normal Push-up | canonical_demo | cfeba482-fc43-4431-b1a9-29c32259749c | high | AMRAP is a set-scheme modifier only; Normal Push-up len 14 shortest plain push-up with demo; chest/bodyweight |
| 113 | Push-up to Plank Rotation | 1 | Push up and rotation | canonical_demo | aa9d3f0e-cfd8-4e59-9a4a-7876eb7798aa | high | Exact same movement len 20 only entry; chest/shoulders/bodyweight; has demo |
| 114 | Push-up to T-Rotation | 1 | Push up and rotation | canonical_demo | aa9d3f0e-cfd8-4e59-9a4a-7876eb7798aa | high | Same movement as idx 112; T-rotation = rotational reach phase; both AI names resolve to same canonical entry; has demo |
| 115 | Reclined Hand to Big Toe | 1 | Supine Hamstring Stretch | cleaned | 317f5bbb-4f48-4387-93f8-b6a7eae7646b | medium | Supta Padangusthasana is functionally a supine hamstring stretch; present in cleaned and manual; has image; not aliased into canonical |
| 116 | Reverse Lunge to Knee Drive | 1 | Lunge to knee drive right bodyweight | canonical_demo | bff70c27-bd6d-435a-b27b-c1794da2d9d0 | high | Exact same movement; quads/glutes/hip flexors/bodyweight; left variant also present; has demo |
| 117 | Rowing Intervals | 1 | Gym Rowing Machine Fast Speed | canonical_demo | e1a2cda4-0c68-46ce-a972-7e404fe65006 | medium | No Rowing Machine Intervals in canonical; Fast Speed len 29 shortest rowing machine entry with demo; better fits interval-style than Sprint; full posterior chain |
| 118 | Rowing Sprints | 1 | Gym Rowing Machine Sprint Speed | canonical_demo | 135caa45-dd22-4576-bd69-885627883c1e | high | Sprint intensity on rowing machine; exact intent match; has demo |
| 119 | Savasana | 1 | Side Lying Parsva Savasana Variation | cleaned | b7bf6d05-1ef1-45aa-9dfd-4d995b647277 | low | Only entry containing "Savasana" in any store; side-lying variation not classic corpse pose; has image+video in cleaned; not in canonical |
| 120 | Seated Forward Fold | 1 | Seated Forward Fold | cleaned | 1d2be6fb-3536-420c-8678-8cf9bc5412d0 | high | Exact name match in cleaned and manual; hamstrings/bodyweight; has image; not aliased into canonical |
| 121 | Seated Row with Band | 1 | Seated Resistance band - cable rows | canonical_demo | 85c1e512-d650-4a7e-a324-33cfe1c22a6a | high | Exact same movement; resistance band/back (lats); has demo |
| 122 | Shoulder Press | 1 | Band Seated Shoulder Press | canonical_demo | 1f577c63-4bc8-4895-bb2e-21bfe0190c61 | medium | Generic name; Band Seated Shoulder Press len 26 shortest shoulder press entry with demo; shoulders/anterior deltoids |
| 123 | Skater Hops | 1 | Skater Hops | cleaned | 9c785584-38c1-44c9-a45b-eaa9e69e9a52 | high | Exact name match in cleaned and manual; glutes/quads/bodyweight; has image; not aliased into canonical |
| 124 | SkiErg Sprint | 1 | Ski Erg Intervals | cleaned | 52f08f58-73db-4930-bf87-5017556483f9 | medium | No sprint-tier SkiErg in any store; Ski Erg Intervals closest same-equipment intensity match (also in manual); has image; not in canonical |
| 125 | SkiErg Sprint Intervals | 1 | Ski Erg Intervals | cleaned | 52f08f58-73db-4930-bf87-5017556483f9 | medium | Same as idx 123; sprint intervals = intensity modifier on SkiErg base; Ski Erg Intervals is best available; has image |
| 126 | Slow Push-ups | 1 | Normal Push-up | canonical_demo | cfeba482-fc43-4431-b1a9-29c32259749c | medium | Slow/tempo is a cadence modifier only; Normal Push-up len 14 shortest plain push-up with demo; no tempo variant in any store |
| 127 | Squat Hold | 1 | Bodyweight squats hold | canonical_demo | 606fb2c3-88c3-4448-95d9-d3d641547849 | high | Core "squat hold"; canonical direct name match; has_demo=true |
| 128 | Squat Pulse | 1 | Bodyweight pulse squat | canonical_demo | 90a6f168-a1ea-4861-8a03-554fa7d45f3c | high | Core "squat pulse"; canonical word-order inversion only; has_demo=true |
| 129 | Squat to Jump | 1 | Jump squats bodyweight | canonical_demo | f476700f-764a-4b65-b704-9a8b33580873 | high | Core "jump squat"; bodyweight canonical preferred over barbell variants; has_demo=true |
| 130 | Standard Pushup | 1 | Normal Push-up | canonical_demo | cfeba482-fc43-4431-b1a9-29c32259749c | high | Core "push-up"; "Normal Push-up" is shortest generic bodyweight canonical with has_demo=true; "Push ups bodyweight" (0f4eec76) also valid |
| 131 | Standing Band Row | 1 | Band standing rear delt row | canonical_demo | 99320b67-4bd6-41cc-ba23-6198b8cb75c6 | medium | Core "band row"; canonical specifies rear delt (narrower than generic row intent); has_demo=true; best available canonical |
| 132 | Standing Row (Band) | 1 | Band standing rear delt row | canonical_demo | 99320b67-4bd6-41cc-ba23-6198b8cb75c6 | medium | Parenthetical variant of idx 131; same canonical match |
| 133 | Static Lunge Hold | 1 | Dumbbell Static Lunge | canonical_demo | 5965671f-a20b-4cf8-929d-a9942127d3ec | medium | Core "static lunge"; canonical specifies dumbbells — AI name may intend bodyweight; movement class identical; has_demo=true |
| 134 | Step-Back Lunge | 1 | Dumbbell reverse lunge on the spot | canonical_demo | 31582a1c-71ac-42cb-8244-21b1ed4a0e34 | medium | Core "reverse lunge"; no bodyweight-only reverse lunge in any store; "on the spot" is most neutral variant; all reverse lunge entries are equipment-loaded; has_demo=true |
| 135 | Sumo Squat Pulse | 1 | Bodyweight pulse squat | canonical_demo | 90a6f168-a1ea-4861-8a03-554fa7d45f3c | medium | Core "squat pulse"; sumo stance undifferentiated in canonical; pulse squat is closest functional match; has_demo=true |
| 136 | Technique Squats | 1 | bodyweight squats | canonical_demo | b674fc09-7059-4dfb-bb25-4d239179cd80 | low | "Technique" is a programming label not a distinct movement; maps to bodyweight squats as base; has_demo=true |
| 137 | Threshold Run Interval | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | medium | Core "run"; threshold-pace is a programming modifier; "Running" is shortest generic canonical with has_demo=true |
| 138 | Track Run | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | medium | Core "run"; outdoor track maps to base "Running" canonical; has_demo=true |
| 139 | Treadmill Intervals | 1 | Treadmill Running | canonical_demo | 07e29142-0323-4160-b70b-b5b4b0db04b7 | medium | Core "treadmill run"; interval structure is a programming modifier; "Treadmill Running" is the equipment-matched canonical; has_demo=true |
| 140 | Tricep Dips AMRAP | 1 | Chair triceps dips | canonical_demo | 169a1681-e6e1-4a37-a213-87fcefdf93c0 | high | Core "tricep dip"; AMRAP is rep-scheme modifier; Chair triceps dips has_demo=true; top bodyweight canonical |
| 141 | Tricep Overhead Extension | 1 | Bodyweight Overhead Triceps Extension | canonical_demo | 1a80a4a9-1b5c-4a1f-bd8d-da79ee71bf06 | high | Core "overhead tricep extension"; equipment-agnostic bodyweight canonical; has_demo=true; dumbbell variants also available |
| 142 | Tricep Rope Pushdowns | 1 | Cable pushdown | canonical_demo | 73b48ac7-d10b-419d-beaa-a552a75f8d6a | medium | Core "cable pushdown"; rope is attachment variant; no rope-specific canonical; "Cable pushdown" is cleanest equipment-matched canonical; has_demo=true |
| 143 | Tricep Skullcrushers | 1 | Barbell lying triceps skull crushers | canonical_demo | 157f2109-67e0-4fff-abe1-641c1fcfd36d | high | Core "skullcrusher"; barbell canonical is most standard; has_demo=true; Dumbbell Skullcrusher (66816e3c) also valid |
| 144 | Triceps Skullcrushers | 1 | Barbell lying triceps skull crushers | canonical_demo | 157f2109-67e0-4fff-abe1-641c1fcfd36d | high | Plural of idx 143; identical movement; same canonical |
| 145 | Wall Sit Pulse | 1 | Wall sit bodyweight | canonical_demo | 97f4ce25-c145-458f-b0c7-f5094bda697b | high | Core "wall sit"; pulse is minor range-of-motion modifier within hold; has_demo=true |
| 146 | Wall Sit with Hold | 1 | Wall sit bodyweight | canonical_demo | 97f4ce25-c145-458f-b0c7-f5094bda697b | high | "Hold" is redundant — wall sit is by definition static; same canonical as idx 145; has_demo=true |
| 147 | Wide Grip Push Ups | 1 | Wide push ups bodyweight | canonical_demo | 6f538efb-f69d-4311-88f4-5f8aa61a030f | high | Core "wide push-up"; direct canonical name match; chest/bodyweight; has_demo=true |
| 148 | Wide Grip Push-up | 1 | Wide push ups bodyweight | canonical_demo | 6f538efb-f69d-4311-88f4-5f8aa61a030f | high | Hyphenated singular of idx 147; same canonical |
| 149 | Wide Legged Forward Fold | 1 | Wide-Legged Forward Fold (Prasarita Padottanasana) | cleaned | 8779a403-b635-4539-969c-5570be9803b8 | high | Not in exercise_canonical; exact name match in cleaned+manual; has_media=true; hamstrings/adductors yoga stretch |
| 150 | Wide-Legged Forward Fold | 1 | Wide-Legged Forward Fold (Prasarita Padottanasana) | cleaned | 8779a403-b635-4539-969c-5570be9803b8 | high | Hyphenated form; exact match; same cleaned entry as idx 149 |
| 151 | Zone 2 Run | 1 | Running | canonical_demo | 80951e3d-8337-4187-8359-8a9c28a96bd1 | medium | Core "run"; zone 2 is training-intensity modifier not a separate canonical; "Running" is generic canonical; has_demo=true |