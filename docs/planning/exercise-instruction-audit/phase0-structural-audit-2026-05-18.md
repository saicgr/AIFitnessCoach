# Exercise Instruction Audit — Phase 0 (structural)

Generated 2026-05-18, read-only deterministic scan. Flags are CANDIDATES for source-grounded review, not verdicts.

**Scope:** 2192 instructions (`exercise_library` 2439 + `exercise_library_manual` 786).

## Headline

- Length is NOT the problem: 0 empty, 0 short.
- The problem is GENERIC / TEMPLATED text: **193 of 2192 (9%)** instructions are templated, generic-filler, or contain a risky phrase.
- Heavy-compound lifts with a deficient instruction: **69 of 594**.

## Buckets

| Bucket | Count | % |
|---|---|---|
| empty | 0 | 0.0% |
| short <120c | 0 | 0.0% |
| thin 120-249c | 60 | 2.7% |
| substantive | 2132 | 97.3% |

## Largest template groups

| Count | Example | Text start |
|---|---|---|
| 14 | Dumbbell Alternating Arnold Press | 1. set up on the bench with proper back support and foot placement. 2. grip the weight at the appropriate widt |
| 12 | Crescent Moon Pose | 1. begin in a comfortable starting position on your yoga mat. 2. move into the pose slowly and with control, f |
| 12 | Dumbbell Alternating Pendlay Row | 1. set up in the proper position with a flat back and engaged core. 2. grip the weight with the appropriate gr |
| 11 | Calf Push Stretch With Hands Against Wall V.2 | 1. get into the starting position for the stretch. 2. slowly move into the stretch until you feel a gentle pul |
| 8 | Bodyweight Squats | 1. stand with feet shoulder-width apart, toes slightly pointed out. 2. brace your core and keep your chest up. |
| 6 | Alternate Biceps Curl Standing Dumbbells | 1. stand or sit with proper posture, holding the weight with the appropriate grip. 2. keep your elbows close t |
| 6 | Dumbbell Chest Supported Y Raise | 1. stand or sit with proper posture, holding the weight at your sides. 2. with a slight bend in your elbows, r |
| 6 | Dumbbell Goblet Reverse Lunge | 1. stand with feet hip-width apart. 2. step forward (or into position) with one leg. 3. lower your body by ben |
| 4 | Dumbbell Elbow Side Plank | 1. start in the appropriate plank position (forearms or hands). 2. keep your body in a straight line from head |
| 4 | Dumbbell Feet Elevated Figure Four Glute Bridge | 1. sit on the ground with your upper back against a bench (or lie flat for bridges). 2. place your feet flat o |
| 3 | 45 Degree Hyperextension (Arms In Front Of Chest) | 1. fix your feet to the footrests and press your thighs against the padded platform. 2. place your arms across |
| 3 | Barbell Full Squat | 1. stand with your feet shoulder-width apart, holding a barbell across your upper back. grip the bar with your |
| 3 | Barbell Lunge | 1. stand with your feet shoulder-width apart, holding a barbell across your upper back. grip the bar with your |
| 3 | Bulgarian Split Squat | 1. stand a few feet in front of a bench or elevated surface, facing away from it. place your left foot behind  |
| 3 | Cable Reverse Grip Pushdown | 1. stand facing the cable machine with a straight bar attached to the high pulley. grasp the bar with both han |
| 3 | Cable Reverse Grip Triceps Pushdown (Ez-Bar) | 1. set up at the appropriate station with proper grip and stance. 2. keep your elbows stationary and close to  |
| 3 | Dumbbell Single-Leg Single-Arm Deadlift | 1. stand with feet hip-width apart, weight in front of you. 2. hinge at the hips, pushing your hips back while |
| 3 | Landmine Romanian Deadlift | 1. stand with feet hip-width apart, weight positioned over mid-foot. 2. hinge at the hips and grip the bar/wei |
| 3 | Plate Clean | 1. stand with feet hip-width apart, weight in front of you. 2. hinge at the hips and bend your knees to grip t |
| 2 | 45 Degree Bicycle Twist Knee To Elbow | 1. align yourself to 45 degrees to the floor by fixing your left foot into the footrest and supporting your th |
| 2 | 90 Degree Heel Touch | 1. lie down on your back with your hips and knees bent to 90 degrees and your arms extended overhead. 2. raise |
| 2 | Alternate Single-Leg Raise Plank | 1. start in a plank position with your hands directly under your shoulders and your body forming a straight li |
| 2 | Ankle - Dorsal Flexion | 1. stand with your feet shoulder-width apart and your hands resting on your hips or at your sides for balance. |
| 2 | Ankle - Plantar Flexion | 1. stand with your feet shoulder-width apart and your hands resting on your hips or at your sides for balance. |
| 2 | Archer Step Back | 1. stand tall with your back straight and feet shoulder-width apart. 2. extend your arms forward while keeping |
| 2 | Assisted Chin-Up Normal Width Reverse Grip | 1. kneel on the platform pad of an assisted chin-up machine and grasp the handles with a reverse grip (palms f |
| 2 | Assisted Pull-Up | 1. kneel on the platform pad of an assisted chin-up machine and grasp the handles with an overhand grip (palms |
| 2 | Back And Forward Leg Swings | 1. stand with your feet shoulder-width apart and use a nearby support (such as a squat cage, wall or a chair)  |
| 2 | Back And Shoulder Stretch | 1. sit on a block with your back straight, feet shoulder-width apart and raise your right arm overhead. 2. ben |
| 2 | Back Slaps Wrap Around Stretch | 1. stand with your feet shoulder-width apart. 2. swing your arms out to the sides, keeping them lightly bent.  |

## Risky-phrase candidates (manual review)

| Count | Concern |
|---|---|
| 11 | momentum cue |
| 10 | bounce cue |
| 9 | cue to round the back |
| 5 | max-speed cue |
| 3 | naive breath-hold cue |
| 2 | jerk cue |
| 1 | elbow lockout under load |
| 1 | knee lockout under load |
| 1 | swing-the-weight cue |

## Priority list — deficient AND (beginner OR heavy compound) = 161

| id | name | equipment | pattern | why |
|---|---|---|---|---|
| fb8e7224-17c3-4d4c-b97d-fed28307eac5 | Alternating Oblique Sit Ups | Bodyweight | hinge | generic-filler |
| 3af49d4b-90b3-44a9-b562-aa97963836c3 | Ball Sit-Up | Stability Ball | hinge | generic-filler |
| a569ad67-787a-48de-b5bf-7a8a37dd587a | Barbell Clean And Jerk | Barbell | hinge | generic-filler |
| 4071a270-051f-4932-a38a-1f4f868a84d9 | Barbell Clean And Jerk Split Squat | Barbell | hinge | generic-filler |
| 8ded0c32-26e2-40fd-b691-8b24f2f25497 | Barbell Full Squat | Barbell | squat | templated x3 |
| bff6fb7b-bd24-4c30-a6ad-df4b70713786 | Barbell Full Squat Side Pov | Barbell | squat | templated x3 |
| 7836c152-2c22-41db-912c-994b2a6f7d96 | Barbell Full Squat(Back) | Barbell | squat | templated x3 |
| fb7ff9c2-cbc6-4b4a-94ad-a4d20fdf46f8 | Barbell Larsen Bench Press | Barbell | horizontal_push | risky:bounce cue |
| 45b71f6d-3df3-4f93-94d2-302513bd57d3 | Barbell Lunge | Barbell | squat | templated x3 |
| f7e35ee7-9e69-4f8f-b974-de7bfff30c37 | Barbell Rear Delt Raise | Barbell | horizontal_push | generic-filler |
| 8d765fbb-1e19-4ff6-9cbb-d74a6463292a | Barbell Reverse Close-Grip Bench Press | Barbell | horizontal_push | generic-filler |
| a5778c69-bb7f-42a4-a30b-cda06aa9b580 | Barbell Reverse Deadlift | Barbell | hinge | risky:cue to round the back;jerk cue |
| 874dd0e5-832b-4d86-bae8-820175b73397 | Barbell Reverse Grip Bench Press | Barbell | horizontal_push | generic-filler |
| d1ee5a83-0a06-48b0-8f01-d4ac2e6ca742 | Barbell Supinated Pendlay Row | Barbell | horizontal_pull | risky:momentum cue |
| f6e797f5-1bb7-48b7-a16f-b6741222c328 | Barbell Zercher Good Morning | Barbell | hinge | risky:cue to round the back |
| 51d71c18-8fc8-4308-acee-f783e9fa3362 | Bench Triceps Dip Straight Legs | Bodyweight | horizontal_push | generic-filler |
| bfb14f19-72c4-4532-9bbc-c8e8c0926c9a | Bodyweight Bent-Over Rear Delt Fly | Bodyweight | horizontal_push | generic-filler |
| 184ebc96-f304-416c-8506-95cc1d8d307f | Bulgarian Split Squat | Bodyweight | squat | templated x3 |
| bcb891fc-6050-428d-b841-48a25851af81 | Bulgarian Split Squat Bodyweight Right | Bodyweight | squat | templated x3 |
| a36b583c-20df-4301-8e01-824f16aae24d | Bulgarian Split Squat Right Bodyweight Side View | Bodyweight | squat | templated x3 |
| 5d01badd-5bc8-4b13-807a-c481968e9c24 | Cable Low Seated Row | Cable Machine | horizontal_pull | generic-filler |
| df96c033-2fca-4ea7-9b53-1f2032b37193 | Clock Push Ups | Bodyweight | horizontal_push | generic-filler |
| a760bfd7-b351-44ee-80d5-bf2354d25bc8 | Cobra Full Push-Up | Bodyweight | horizontal_push | generic-filler |
| 3204e39d-bcdb-4496-8d8e-6643e8163082 | Cossack Squat | Bodyweight | squat | generic-filler |
| 349f24d8-c645-4120-ba0a-14adac67bc0f | Curtsy Lunges Resistance Band | Resistance Band | squat | generic-filler |
| f3e28bfc-a6f7-4b29-95c9-ec5c69486e9e | Dumbbell Alternating Pendlay Row | Dumbbells | horizontal_pull | templated x12, generic-filler |
| b2e47ce1-235e-427d-a39b-64fb0d85c0a9 | Dumbbell Bent-Over Face Pull | Dumbbells | horizontal_pull | generic-filler |
| e2e55b0b-9987-42a2-8e23-3c9612497c8b | Dumbbell Elbow Side Plank | Dumbbells | horizontal_push | templated x4 |
| 158427f3-0142-43cb-ae22-d2ba617c0d3e | Dumbbell Feet Elevated Figure Four Glute Bridge | Dumbbells | hinge | templated x4 |
| e04886a6-5f73-4a8a-bdcd-9505528d74c5 | Dumbbell Goblet Reverse Lunge | Dumbbells | squat | templated x6 |
| dc079faf-ae3d-4e0c-9a9e-e2401495c25e | Dumbbell Hand Side Plank | Dumbbells | horizontal_push | templated x4 |
| c0918e72-e518-4f5c-850c-6df98a89459e | Dumbbell Lying On Floor Chest Press | Dumbbells | horizontal_push | templated x14, generic-filler |
| b96b2364-e920-4ed6-b17f-6f1e4c9ebcf3 | Dumbbell Offset Squat | Dumbbells | squat | templated x8 |
| f3eee79f-f7c3-4157-8be0-070976687397 | Dumbbell Pendlay Row | Dumbbells | horizontal_pull | templated x12, generic-filler |
| aecee3b1-d354-4914-bca9-c5f9c56ecf5d | Dumbbell Single-Leg Hip Thrust | Dumbbells | hinge | templated x4 |
| 25aac40e-020b-48c1-b1a8-aceb3e3996d4 | Dumbbell Single-Leg Single-Arm Deadlift | Dumbbells | hinge | templated x3 |
| a5c66245-5b6a-45fc-82e4-5fdf9cb3df37 | Dumbbell Single-Leg Squat With Support (Pistol) | Dumbbells | squat | generic-filler |
| 8b36817d-7765-4a94-8fdb-1090f549c7f6 | Dumbbell Staggered Deadlift | Dumbbells | hinge | templated x3 |
| 47a58529-d7fd-46bb-bcf9-4112cb4d0050 | Dumbbell Staggered Glute Bridge | Dumbbells | hinge | templated x4 |
| 1539cd5a-6c54-49e1-a1ef-1ac8c59769d7 | Dumbbell Staggered Hip Thrust | Dumbbells | hinge | templated x4 |
| 87928423-9489-4783-a9bc-40e8edb53d60 | Forward Lunge | Bodyweight | squat | generic-filler |
| e9e2808c-28af-4b40-beeb-f9a7d4f5bac5 | Hold The World Med Ball Chest Press | Medicine Ball | horizontal_push | templated x14, generic-filler |
| 4741eccd-15b5-432d-beed-f3fdc84779d6 | Kettlebell Single-Arm Row | Kettlebell | horizontal_pull | risky:cue to round the back |
| 457fe392-213b-4bd5-b221-c5f2f05ea498 | Landmine Chest Press | Landmine | horizontal_push | templated x14, generic-filler |
| ef5aa777-b4e1-4140-a0dc-ced7bbc09b7c | Landmine Romanian Deadlift | Landmine | hinge | templated x3 |
| a491d8a4-0bb3-469f-a9c9-73f692b94c28 | Landmine Squat And Press | Landmine | squat | templated x8 |
| 43ff0bdc-fe3c-445b-b5ca-9e24229665ca | Long Lever Plank | Bodyweight | horizontal_push | templated x4 |
| 97476489-c462-4d67-bfcb-bbd216a8c9ea | Med Ball Front Squat Raise | Medicine Ball | squat | templated x8 |
| b577a5e6-0745-4061-95bc-988ac8463b72 | Narrow Stance Heels Elevated Dumbbell Goblet Squats | Dumbbells | squat | templated x8 |
| da5958a7-6782-4b60-918c-98451632bc2d | Normal Squat Smith Machine | Smith Machine | squat | templated x8 |
| 0553a035-660b-46c8-b0b8-52a446635247 | Pistol Squat To Box | Bodyweight | squat | templated x8 |
| 5712d320-1e3e-4cca-85c4-f4368b0684e6 | Plate Alternating Deadstop Row | Weight Plate | horizontal_pull | templated x12, generic-filler |
| 24af763f-610a-487f-a1eb-ea673e61c2e4 | Plate Clean | Weight Plate | hinge | templated x3 |
| 9dcd6e2c-040d-45e6-9f17-cb639d0d45c6 | Plate Clean And Press | Weight Plate | hinge | templated x3 |
| 4ebc2d8a-ed96-4c95-97bb-20114cfeef35 | Plate Curtsy Lunge | Weight Plate | squat | templated x6 |
| 2441a2a2-f228-405a-a519-0bfdbcab8fb6 | Plate Deadlift | Weight Plate | hinge | templated x3 |
| 9ca442ee-f7b7-426a-afb3-51a148cd193d | Plate Deficit Lunge | Weight Plate | squat | templated x6 |
| 1a4f66d2-807b-44ed-8261-989b8f6554f4 | Plate Forward Lunge | Weight Plate | squat | templated x6 |
| 4dc2bb13-9898-4226-8207-9d2758b7efc0 | Plate Glute Bridge To Chest Press | Weight Plate | horizontal_push | templated x14, generic-filler |
| be865292-30c5-4002-a82e-4258e4c1ef6e | Plate Internally Rotated Rear Delt Fly | Weight Plate | horizontal_push | templated x6, generic-filler |
| 8ac7b11a-b7dd-4843-b97e-aaaa2c8d4c98 | Plate Lateral Lunge | Weight Plate | squat | templated x6 |
| 14d68e75-083c-4a5a-b769-656912f59a68 | Plate Pinch Grip Deadlift | Weight Plate | hinge | templated x3 |
| b1c78e62-97f8-4e23-96da-08cb95ecbebc | Romanian Deadlift Barbell | Barbell | hinge | templated x3 |
| e84a6b7e-ae65-44e1-bfa2-acba2306c08a | Seated Cable Row V Bar Machine | Seated Cable Row Machine | horizontal_pull | generic-filler |
| d420bea4-9f03-4a38-995b-b2cb1ce20f48 | Seated Row Machine Rows | Seated Cable Row Machine | horizontal_pull | templated x12, generic-filler |
| 1a23c0bc-c661-4402-ace1-0f91ace8c4b8 | Suspension Trainer With Grips Inverted Row | Suspension Trainer | horizontal_pull | templated x12, generic-filler |
| a68574b6-71e5-4dcc-9120-7b4483a81547 | Suspension Trainer With Grips Inverted Row On Floor | Suspension Trainer | horizontal_pull | templated x12, generic-filler |
| 9d42dc0c-da15-4344-8aeb-385653a372b9 | Suspension Trainer With Grips Wide-Grip Inverted Row On Floor 1 | Bodyweight | horizontal_pull | templated x12, generic-filler |
| 73ac9134-f93b-4f7e-868f-63b2bd7fa8cf | Suspension Trainer With Grips Wide-Grip Inverted Row On Floor Female 1 | Bodyweight | horizontal_pull | templated x12, generic-filler |
| b942f7f6-f23f-442d-8038-2d2c33da5e56 | 45 Degree Hyperextension (Arms In Front Of Chest) | Hyperextension Bench | None | templated x3 |
| 5ac9fb9c-0959-490e-b825-67894a5da7ce | 45 Degree Hyperextension Arms To Chest | Hyperextension Bench | None | templated x3 |
| bf3594ac-32fa-4b2d-a65b-00bd724bc76c | Ab Tuck | Dip Station | None | generic-filler |
| 916a7a01-1bb6-41ee-81e4-3736cbfecb2c | Agility Ladder In In Out Out With Knee Lift | Agility Ladder | None | risky:bounce cue |
| af60efa6-6628-483b-902e-231394ffef88 | Alternate Biceps Curl Standing Dumbbells | Dumbbells | None | templated x6, generic-filler |
| 585633c0-d32c-498c-b50d-a6ddbd3f87c7 | Alternate Heel Touches | Bodyweight | None | generic-filler |
| c6bbf304-dd87-48e2-b5fb-194ddea2d885 | Alternate Leg Pull | Bodyweight | None | generic-filler |
| 652b1b3a-ac2e-4f25-85f0-f486fa912dc5 | Alternate Toe Tap Leg Lift | Bodyweight | None | generic-filler |
| c55d36b7-ae09-44f1-9b8b-3dcce9849401 | Alternating Biceps Hammer Curl Resistance Band | Resistance Band | None | templated x6, generic-filler |
| d0b8723f-baff-446a-9336-d1e271c7b080 | Alternating Toe Tap | Bodyweight | None | generic-filler |
| c7da401e-100d-467f-9202-ff068b1f780c | Arm Circle | Bodyweight | None | generic-filler |
| cc8ba4b3-fa8e-4d39-853e-e575b6907d28 | Arm Circles Backward | Bodyweight | None | generic-filler |
| 10d613b3-a8fb-4da6-a79f-06411ae36ee0 | Assault Airbike Sprint Speed | Assault Bike | plyometric | risky:max-speed cue |
| d0971e98-e875-4eb2-abdd-4d6db72064df | Back Extension Machine | Hyperextension Bench | None | templated x3 |
| e7d3a706-e53e-485c-aa59-d6fe40562133 | Barbell Jump Shrug | Barbell | plyometric | risky:naive breath-hold cue |
| b78c7b3d-eafd-4dd2-b79f-e138ac8f9e6a | Barbell Reverse Biceps Curl | Barbell | None | generic-filler |
| 728d242f-d6d3-45b7-a270-9ab1e3b5f9b4 | Barbell Seated Military Press | Barbell | overhead_press | generic-filler |
| 548be319-47a3-4b7f-830b-e64cbf0ed604 | Barbell Seated Overhead Press | Barbell | overhead_press | generic-filler |
| 552b4ee4-7bf5-4579-a35b-50b738d83ab6 | Biceps Curl Resistance Band | Resistance Band | None | generic-filler |
| 3b2a8bdb-1976-41db-ac97-783ee5578002 | Bodyweight Lying Leg Curl | Bodyweight | None | generic-filler |
| b8bb7a2b-3ed4-4889-a30b-34e91d48dbc2 | Bodyweight Squats | Bodyweight | None | templated x8 |
| bd6a566e-457d-4821-a6bb-012cc911b7dd | Bodyweight Standing Shrug | Bodyweight | overhead_press | generic-filler |
| 602e7e38-ca10-499f-8c7e-e74fcde6c330 | Cable Biceps Curl (Ez-Bar) | Cable Machine | None | templated x6, generic-filler |
| 1f40c682-7ec8-49e2-9905-99ad75bd78a4 | Cable Reverse Grip Pushdown | Cable Machine | None | templated x3 |
| b7e7be2b-7641-4448-8da6-5e65df5a4ef1 | Cable Reverse Grip Triceps Push Down Straight Bar On Crossover | Cable Machine | None | templated x3 |
| c75b0706-2892-4346-a482-f7efc7c2be9f | Cable Reverse Grip Triceps Pushdown (Ez-Bar) | Cable Machine | None | templated x3, generic-filler |
| dbf0e302-013f-4586-9be5-0631b92ae66a | Cable Reverse Grip Triceps Pushdown Back Side Pov | Cable Machine | None | templated x3 |
| cd8e0d19-b7ef-43dc-880b-bd3409188b8d | Cable Twisting Overhead Press | Cable Machine | loaded_rotation | generic-filler |
| bda60552-085e-42d7-bb5a-c50ad14a19ae | Calf Push Stretch With Hands Against Wall V.2 | Bodyweight | mobility | templated x11 |
| 9c12c83e-cea3-45b5-85ae-c6abf1ae79b6 | Cat Pose | Bodyweight | None | risky:cue to round the back |
| e3cb826b-20b6-4889-9144-e9bf5e19ebac | Cat-Cow Stretch | Bodyweight | mobility | risky:cue to round the back |
| 2c6b8195-057f-470d-99f7-deff35b48ae0 | Child Pose Lower Back Stretch | Bodyweight | mobility | templated x11 |
| 54585459-6ebf-4527-a42d-b02b20ae34ad | Cobra Side Ab Stretch | Yoga Mat | mobility | generic-filler |
| bb2e5ed4-ac8a-46a9-99e1-cb69f5ff32fb | Cobra Yoga Pose Hold | Bodyweight | isometric | generic-filler |
| 187caef8-c12b-4932-a5d4-cf57133e61c8 | Crescent Moon Pose | Bodyweight | None | templated x12, generic-filler |
| 1576c24e-526c-4e16-a960-e4d5050d9978 | Crescent Moon Pose Quad Stretch With Block | Yoga Block | mobility | templated x11 |
| 6d1c3f60-e416-48f2-9c26-44d84df303ce | Criss Cross Bow Tie Pose | Bodyweight | None | templated x12, generic-filler |
| 84bdb842-907c-4eb7-a4a2-82d73c242840 | Cross Body Elbow Pull Shoulder Stretch | Bodyweight | mobility | templated x11 |
| 5a6c9af5-1b59-491f-9d61-461184321737 | Cross Body Shoulder Stretch | Bodyweight | mobility | templated x11 |
| 17e9f89e-7771-4432-892d-57805de1bb68 | Diagonal Chop Cable | Cable Machine | None | generic-filler |
| ae228147-296d-43e9-a707-359bac37f0a3 | Double Pigeon Pose | Bodyweight | mobility | templated x12, generic-filler |
| bd8ff344-400c-4c27-afb7-32d267c86e38 | Downward Dog Toe To Heel | Bodyweight | mobility | templated x12, generic-filler |
| 477f15b8-8669-48c9-8b1c-546fe92f73de | Downward Dog With Fingers Facing Feet | Bodyweight | mobility | templated x12, generic-filler |
| 5a301ee7-3f01-4d9d-8f36-041d75713da5 | Dumbbell Chest Supported Y Raise | Dumbbells | None | templated x6, generic-filler |
| 38aabc11-2d3b-43f8-aa9c-ab2dc55a63b0 | Dumbbell Curl Press Extend | Dumbbells | None | generic-filler |
| f3c9c27e-7a0a-46dc-9793-0aa620557ba7 | Dumbbell Half-Kneeling Wood Chopper | Dumbbells | loaded_rotation | risky:momentum cue |
| 44f315fa-6d9c-4de0-92c3-b182ea7e93e8 | Dumbbell Knee Lawnmower Row | Dumbbells | None | templated x12, generic-filler |
| 320055ab-7b76-4519-956d-d224d718eb17 | Dumbbell Seated Lateral Raise | Dumbbells | None | risky:elbow lockout under load |
| 1fe8c2fb-e5dc-4395-abc3-f3fa8bd7f967 | Dumbbell Standing Wrist Curl | Dumbbells | None | generic-filler |
| 2678f51c-be2d-4b52-82bd-b86bdcb99ecf | Horizontal Leg Press | Leg Press Machine | None | risky:knee lockout under load |
| 437c0469-7993-45b2-a774-ebbc49db1393 | Jump Rope Alternate Foot Step | Jump Rope | plyometric | risky:bounce cue |
| 19c20c44-7119-403b-bc33-5604af26351c | Jump Rope Double Bounce | Jump Rope | plyometric | risky:bounce cue |
| 526397cf-0ad0-494b-8a9f-3cdf5a035cb4 | Jump Rope Row White Screen | Cable Machine | plyometric | templated x12, generic-filler |
| c4431811-04ba-4962-9a78-5d9d98323bfd | Kettlebell Curl | Kettlebell | None | risky:momentum cue |
| 8ed12762-6557-4700-814b-ae38101a3fa4 | Kettlebell Front Raise | Kettlebell | None | risky:momentum cue |
| 265b23bb-e4b8-4c23-9e56-606ef6a2670b | Kettlebell Goblet Curl | Kettlebell | None | risky:momentum cue |
| 4009981d-a428-4b00-b9a8-e59b2bff843e | Kettlebell Gorilla Row | Kettlebell | None | risky:cue to round the back |
| 28a5d007-304e-4f35-bff5-ed50293d57c5 | Kettlebell Row | Kettlebell | None | risky:cue to round the back |
| f882108b-97cd-4a9a-8dbf-94354a82c898 | Landmine Bicep Curl | Landmine | None | risky:swing-the-weight cue |
| dadb408a-150d-4888-ac95-20e161e2e04c | Landmine Overhead Press | Landmine | overhead_press | templated x14, generic-filler |
| 293f8456-c550-4a55-a67f-79d6bd64a6cc | Landmine Seated Alternating Overhead Press | Landmine | overhead_press | templated x14, generic-filler |
| b869b640-20c9-4817-aa36-83c173a7b4a6 | Landmine Seated Overhead Press | Landmine | overhead_press | templated x14, generic-filler |
| c79a7bf8-3b25-4fc6-9510-7536dfb0f0c9 | Lats Stretch Elbow On Wall | Bodyweight | mobility | templated x11 |
| d2f9df2b-3f50-47b6-a4f6-03c227a553d7 | Lats Stretch On Wall | Bodyweight | mobility | templated x11 |
| 8c6fb3c2-5877-4a91-9882-bdf6e11256bf | Lawnmower Row | Cable Machine | None | templated x12, generic-filler |
| a06effca-ef7b-4c50-993f-795e0e8fb00a | Laying Lateral Raise | Dumbbells | None | templated x6, generic-filler |
| f92b9bf4-28ac-46b8-970f-77b985742cd9 | Low Box Quick Feet | Plyo Box | None | risky:naive breath-hold cue;max-speed cue |
| 0037b81b-9108-495b-979f-e989f98d6fc8 | Low Rotational Med Ball Chops (Quarter Squat, Rotating Med Ball Left And Ride Across Core) | Medicine Ball | loaded_rotation | templated x8 |
| 0b05331c-4430-456a-baae-77dacacbb23f | Lying Bent Knee Cross Glutes Stretch | Bodyweight | mobility | templated x11 |
| 731d5acd-84b1-41c6-b89f-bc48489aa7e2 | Lying Knee Hugs Lower Back Stretch | Bodyweight | mobility | templated x11 |
| bbb8f1a8-383d-4386-ad10-2478309445e6 | Lying Knees To Floor Lower Back Stretch | Bodyweight | mobility | templated x11 |
| 9d8693e2-cee7-4571-b854-96f87d816a38 | Lying Neck Curls | Bodyweight | None | risky:momentum cue |
| 1e9473da-2622-4619-a7ed-7040a8ed1fd2 | Mountain Climber Jump | Bodyweight | plyometric | risky:max-speed cue |
| 99b10723-464b-43f1-b88c-e5ab0ca6ccd1 | Mountain Climber Jumps | Bodyweight | plyometric | risky:max-speed cue |
| 12a1d454-2383-487e-a6af-519ea0e51475 | Pec Deck Fly Machine Flies | Pec Deck / Fly Machine | None | templated x6, generic-filler |
| 7b2e31e6-b927-4ea1-b371-faad871a8151 | Pigeon Pose | Bodyweight | mobility | templated x12, generic-filler |
| 725411da-e7f3-40f4-90ff-40adb3957211 | Plate Full Front Raise | Weight Plate | None | templated x6, generic-filler |
| 124efe8c-16fe-4873-8598-87fe550f3fff | Plate Lateral Raise | Weight Plate | None | templated x6, generic-filler |
| a9c7162f-f09b-4a74-bf7b-999455d25f3e | Plate Overhead Press To Tricep Extension | Weight Plate | overhead_press | templated x14, generic-filler |
| 250e4bb6-b302-4122-a3f2-fab668806a65 | Plate Overhead Walking Lunge | Weight Plate | overhead_press | templated x6 |
| 4ca19b2a-ce4f-48fd-ac6d-8e7d0b480009 | Rebounder Knee Jumps | Rebounder | plyometric | risky:bounce cue |
| 00479d2e-7908-4b45-b7df-f170e4b22e4f | Rebounder Knee Pushes | Rebounder | plyometric | risky:bounce cue |
| 86528984-f653-4253-a062-3950aaa49760 | Rebounder Light Jumps | Rebounder | plyometric | risky:bounce cue |
| 52a21139-88f4-43e5-b4c2-fdafbe79d896 | Resistance Band Standing External Rotation | Resistance Band | loaded_rotation | generic-filler |
| 65aa5897-39c5-4d04-b160-19c8121be902 | Reverse Curl Barbell | Barbell | None | templated x6, generic-filler |
| ac7348a4-0b5d-4070-bb90-1f35af666367 | Seated Single-Leg Toe Touch Hamstring Stretch | Bodyweight | mobility | risky:cue to round the back |
| 4592b816-e2aa-4606-aa87-97081f4e51dd | Side Bend Standing Lats Stretch | Bodyweight | mobility | templated x11 |
| 9c06d7bf-64fa-4fc6-8d77-716e25a1e37b | Side Chest Stretch On Wall | Bodyweight | mobility | risky:naive breath-hold cue |
| b7bf6d05-1ef1-45aa-9dfd-4d995b647277 | Side Lying Parsva Savasana Variation | Bodyweight | None | templated x12, generic-filler |
| 71e835e0-794d-4d2c-add9-879a40a1965b | Standing Hamstring Stretch | Bodyweight | mobility | risky:bounce cue |
| a8374aa2-4983-4020-bf3b-0985cc14e37c | Svend Press Flat Bench | Dumbbells | None | templated x14, generic-filler |
| ab9e4278-d218-4f5a-80b1-bfab304281a0 | Yoga Flow Sequences Sun Salutations | Bodyweight | None | templated x12, generic-filler |
