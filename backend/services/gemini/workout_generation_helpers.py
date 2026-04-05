"""Helper functions extracted from workout_generation.
Gemini Service Workout Generation - Core workout plan generation.


"""
class WorkoutGenerationMixin:
    """Mixin providing core workout generation methods for GeminiService."""

    async def generate_workout_plan(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        custom_exercises: Optional[List[Dict]] = None,
        workout_environment: Optional[str] = None,
        equipment_details: Optional[List[Dict]] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[dict]] = None,
        comeback_context: Optional[str] = None,
        progression_philosophy: Optional[str] = None,
        workout_patterns_context: Optional[str] = None,
        favorite_workouts_context: Optional[str] = None,
        neat_context: Optional[str] = None,
        set_type_context: Optional[str] = None,
        primary_goal: Optional[str] = None,
        muscle_focus_points: Optional[Dict[str, int]] = None,
        training_split: Optional[str] = None,
        workout_days: Optional[List[int]] = None,
        # Fitness Assessment fields - for smarter workout personalization
        pushup_capacity: Optional[str] = None,
        pullup_capacity: Optional[str] = None,
        plank_capacity: Optional[str] = None,
        squat_capacity: Optional[str] = None,
        cardio_capacity: Optional[str] = None,
        training_experience: Optional[str] = None,
        user_dob: Optional[str] = None,
        user_id: Optional[str] = None,
        workout_weight_unit: Optional[str] = None,
    ) -> Dict:
        """
        Generate a personalized workout plan using AI.

        Args:
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            equipment: List of available equipment
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Optional list of words to avoid in the workout name (for variety)
            workout_date: Optional date for the workout (ISO format) to enable holiday theming
            age: Optional user's age for age-appropriate exercise selection
            activity_level: Optional activity level (sedentary, lightly_active, moderately_active, very_active)
            intensity_preference: Optional intensity preference (easy, medium, hard) - overrides fitness_level for difficulty
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX", "Improve box jump height")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed) - affects exercise selection
            custom_exercises: Optional list of user's custom exercises to potentially include
            workout_environment: Optional workout environment (commercial_gym, home_gym, home, outdoors, hotel, etc.)
            equipment_details: Optional detailed equipment info with quantities and weights
                               [{"name": "dumbbells", "quantity": 2, "weights": [15, 25, 40], "weight_unit": "lbs"}]
            avoided_exercises: Optional list of exercise names the user wants to avoid (e.g., injuries, preferences)
            avoided_muscles: Optional dict with 'avoid' (completely skip) and 'reduce' (minimize) muscle groups
            staple_exercises: Optional list of dicts with name, reason, muscle_group for user's staple exercises
            comeback_context: Optional context string for users returning from extended breaks (includes specific
                            adjustments for volume, intensity, rest periods, and age-specific modifications)
            progression_philosophy: Optional progression philosophy prompt section for leverage-based progressions
                                  and user rep preferences. Built by build_progression_philosophy_prompt().
            workout_patterns_context: Optional context string with user's historical workout patterns including
                                     set/rep limits and exercise-specific averages. Built by get_user_workout_patterns().
            neat_context: Optional NEAT (Non-Exercise Activity Thermogenesis) context string with user's daily
                         activity patterns, step goals, streaks, and sedentary habits. Built by
                         user_context_service.get_neat_context_for_ai().
            set_type_context: Optional context string with user's historical set type preferences (drop sets,
                            failure sets, AMRAP) and acceptance rates. Built by build_set_type_context().
            primary_goal: Optional primary training goal ('muscle_hypertrophy', 'muscle_strength', or
                         'strength_hypertrophy'). Affects rep ranges and exercise selection.
            muscle_focus_points: Optional dict mapping muscle groups to focus points (1-5).
                                Example: {"triceps": 2, "lats": 1, "obliques": 2}
                                Muscles with more points get emphasized more in workouts.
            training_split: Optional training split identifier (full_body, push_pull_legs, pplul, etc.)
                           Used to provide rich context about the split's schedule, hypertrophy score,
                           and scientific rationale to the AI.
            pushup_capacity: Optional fitness assessment - push-up capacity
                            (e.g., 'none', '1-10', '11-25', '26-40', '40+')
            pullup_capacity: Optional fitness assessment - pull-up capacity
                            (e.g., 'none', 'assisted', '1-5', '6-10', '10+')
            plank_capacity: Optional fitness assessment - plank hold duration
                           (e.g., '<15sec', '15-30sec', '31-60sec', '1-2min', '2+min')
            squat_capacity: Optional fitness assessment - bodyweight squat capacity
                           (e.g., '0-10', '11-25', '26-40', '40+')
            cardio_capacity: Optional fitness assessment - cardio endurance
                            (e.g., '<5min', '5-15min', '15-30min', '30+min')
            training_experience: Optional fitness assessment - weight training experience
                                (e.g., 'never', '3-12mo', '1-3yr', '3-5yr', '5+yr')

        Returns:
            Dict with workout structure including name, type, difficulty, exercises
        """
        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hell":
                logger.warning(f"[Gemini] Beginner fitness level with HELL intensity - this is extremely challenging!")
            elif fitness_level == "beginner" and intensity_preference == "hard":
                logger.warning(f"[Gemini] Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hell":
                logger.info(f"[Gemini] Intermediate fitness level with HELL intensity - maximum challenge mode")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                logger.info(f"[Gemini] Intermediate fitness level with hard intensity - will challenge the user")
            elif intensity_preference == "hell":
                logger.info(f"[Gemini] HELL MODE ACTIVATED - generating maximum intensity workout")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction if provided
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ IMPORTANT: Do NOT use these words in the workout name (they've been used recently): {', '.join(avoid_name_words)}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date, user_dob=user_dob)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Build age and activity level context
        # Import senior-specific prompt additions from adaptive_workout_service
        from services.adaptive_workout_service import get_senior_workout_prompt_additions

        age_activity_context = ""
        senior_critical_instruction = ""  # For seniors 60+, this adds critical limits
        if age:
            bracket = age_to_bracket(age)
            if age < 30:
                age_activity_context += f"\n- Age group: {bracket} (can handle higher intensity, explosive movements, max 25 reps/exercise)"
            elif age < 45:
                age_activity_context += f"\n- Age group: {bracket} (balanced approach to intensity, max 20 reps/exercise)"
            elif age < 60:
                age_activity_context += f"\n- Age group: {bracket} (focus on joint-friendly exercises, longer warm-ups, max 16 reps/exercise)"
            else:
                # Senior users (60+) - get detailed safety instructions
                senior_prompt_data = get_senior_workout_prompt_additions(age)
                if senior_prompt_data:
                    age_activity_context += f"\n- Age group: {bracket} ({senior_prompt_data['age_bracket']} - REDUCED INTENSITY REQUIRED)"
                    # Add critical senior instructions to the prompt
                    senior_critical_instruction = senior_prompt_data["critical_instructions"]
                    # Also append movement guidance
                    movements_to_avoid = ", ".join(senior_prompt_data.get("movements_to_avoid", [])[:5])
                    movement_priorities = ", ".join(senior_prompt_data.get("movement_priorities", [])[:5])
                    senior_critical_instruction += f"\n- PRIORITIZE: {movement_priorities}"
                    senior_critical_instruction += f"\n- AVOID: {movements_to_avoid}"
                else:
                    age_activity_context += f"\n- Age group: {bracket} (prioritize low-impact, balance exercises, max 12 reps/exercise)"

        if activity_level:
            activity_descriptions = {
                'sedentary': 'sedentary (new to exercise - start slow, more rest periods)',
                'lightly_active': 'lightly active (exercises 1-3 days/week - moderate intensity)',
                'moderately_active': 'moderately active (exercises 3-5 days/week - can handle challenging workouts)',
                'very_active': 'very active (exercises 6-7 days/week - high intensity appropriate)'
            }
            activity_desc = activity_descriptions.get(activity_level, activity_level)
            age_activity_context += f"\n- Activity Level: {activity_desc}"

        # Add safety instruction if there's a mismatch between fitness level and intensity
        # Also add special instructions for HELL mode workouts
        safety_instruction = ""
        if difficulty == "hell":
            safety_instruction = """

🔥 HELL MODE - MAXIMUM INTENSITY WORKOUT:
This is an EXTREME intensity workout. You MUST:
1. Use heavier weights than normal (increase by 20-30% from typical recommendations)
2. Minimize rest periods (30-45 seconds max between sets)
3. Include advanced techniques: drop sets, supersets, AMRAP sets, tempo training
4. Push rep ranges to near-failure (aim for RPE 9-10)
5. Include explosive and compound movements
6. Add intensity boosters like pause reps, 1.5 reps, or slow eccentrics
7. This workout should be BRUTAL - make users feel accomplished for finishing
8. Include challenging exercise variations (see HELL MODE EXERCISES below)
9. Higher volume: more sets per exercise (4-5 sets minimum)

🏋️ HELL MODE EXERCISES - USE THESE HARD VARIATIONS:
LEGS (choose from these):
- Barbell Back Squat (heavy), Front Squat, Pause Squat, Bulgarian Split Squat
- Romanian Deadlift, Stiff-Leg Deadlift, Sumo Deadlift
- Walking Lunges (weighted), Reverse Lunges, Jump Lunges
- Leg Press (heavy), Hack Squat, Sissy Squat
- Box Jumps, Jump Squats, Pistol Squats

CHEST (choose from these):
- Barbell Bench Press (heavy), Incline Barbell Press, Decline Press
- Dumbbell Bench Press (heavy), Incline Dumbbell Press
- Weighted Dips, Deficit Push-Ups, Clap Push-Ups
- Cable Flyes (heavy), Dumbbell Flyes

BACK (choose from these):
- Deadlift (conventional or sumo), Rack Pulls
- Barbell Row (heavy), Pendlay Row, T-Bar Row
- Weighted Pull-Ups, Weighted Chin-Ups, Muscle-Ups
- Lat Pulldown (heavy), Seated Cable Row (heavy)

SHOULDERS (choose from these):
- Overhead Press (barbell), Push Press, Arnold Press
- Dumbbell Shoulder Press (heavy), Z-Press
- Lateral Raise (heavy), Cable Lateral Raise
- Face Pulls (heavy), Rear Delt Flyes, Upright Row

ARMS (choose from these):
- Barbell Curl (heavy), Preacher Curl, Spider Curl
- Skull Crushers, Close-Grip Bench Press, Overhead Tricep Extension
- Weighted Dips (tricep focus), Diamond Push-Ups

⛔ DO NOT USE THESE EASY EXERCISES IN HELL MODE:
- Bodyweight squats (use barbell squats instead)
- Regular push-ups (use weighted/deficit/clap variations)
- Dumbbell curls with light weight (use barbell or heavy dumbbells)
- Machine exercises when free weights are available
- Any exercise without added resistance/weight

HELL MODE NAMING: Use intense, aggressive names like "Inferno", "Apocalypse", "Devastation", "Annihilation", "Carnage", "Rampage"."""
            if fitness_level == "beginner":
                safety_instruction += "\n\n⚠️ BEGINNER IN HELL MODE: Scale weights appropriately but maintain high intensity. Focus on form while pushing limits. Include extra rest if needed for safety."
            elif fitness_level == "intermediate":
                safety_instruction += "\n\n💪 INTERMEDIATE IN HELL MODE: Push to your limits with challenging weights and minimal rest. You can handle this - make it count!"
        elif fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Choose challenging exercises but ensure proper form is achievable. Include more rest periods and focus on compound movements with moderate weights rather than advanced techniques."

        # Add difficulty-based rep/weight scaling
        difficulty_scaling_instruction = ""
        if difficulty == "easy":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - EASY MODE:
- Sets: 3 sets per exercise (MINIMUM 3 sets - never use 2 sets)
- Reps: 10-12 reps (higher rep range, lighter load)
- Weights: Use 60-70% of typical recommendations
- Rest: 90-120 seconds between sets
- RPE Target: 5-6 (comfortable, could do 4+ more reps)
- Focus: Form and technique over intensity
- set_targets: Generate 3 set targets for each exercise (all working sets)"""
        elif difficulty == "medium" or difficulty == "moderate":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - MODERATE MODE:
- Sets: 3-4 sets per exercise
- Reps: 8-12 reps (standard hypertrophy range)
- Weights: Use typical recommended weights for fitness level
- Rest: 60-90 seconds between sets
- RPE Target: 7-8 (challenging but sustainable)
- Focus: Balance of form and progressive overload
- set_targets: Generate 3-4 set targets for each exercise (all working sets)"""
        elif difficulty == "challenging" or difficulty == "hard":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - CHALLENGING MODE:
- Sets: 3-4 sets per exercise (compound: 4 sets)
- Reps: 6-10 reps (slightly lower reps, heavier weights)
- Weights: Increase typical recommendations by 10-15%
- Rest: 60-75 seconds between sets (shorter rest)
- RPE Target: 8-9 (pushing limits, 1-2 reps in reserve)
- Include: 1-2 exercises with failure on last set
- Focus: Progressive overload and intensity
- set_targets: Generate 3-4 set targets for each exercise (include failure sets)"""
        elif difficulty == "hell" or difficulty == "extreme":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - HELL MODE:
- Sets: 4-5 sets per exercise (MINIMUM 4 sets, preferably 5)
- Reps: 6-8 for compounds, 8-10 for isolation, AMRAP on final sets
- Weights: Increase typical recommendations by 20-30% (use HEAVY weights)
- Rest: 30-45 seconds between sets (minimal rest, NO 60s+ rest periods)
- RPE Target: 9-10 (near failure or failure on every working set)
- Include: At least 2 drop set exercises, 1 superset pair, AMRAP finisher
- Volume: 6-8 exercises minimum, high total volume
- Exercise Selection: ONLY use advanced/compound exercises - NO basic bodyweight moves
- Focus: Maximum intensity, muscle breakdown, mental toughness
- Mark is_failure_set: true on at least 2 exercises
- Mark is_drop_set: true on at least 1 isolation exercise
- set_targets: Generate 4-5 set targets for each exercise (include warmup, working, drop, failure sets)"""

        safety_instruction += difficulty_scaling_instruction

        # Determine workout type (strength, cardio, or mixed)
        # Addresses competitor feedback: "I hate how you can't pick cardio for one of your workouts"
        workout_type = workout_type_preference if workout_type_preference else "strength"
        workout_type_instruction = ""
        if workout_type == "cardio":
            workout_type_instruction = """

🏃 CARDIO WORKOUT TYPE:
This is a CARDIO-focused workout. You MUST:
1. Include time-based exercises (running, cycling, rowing, jump rope)
2. Use duration_seconds instead of reps for cardio exercises (e.g., "30 seconds jump rope")
3. Focus on heart rate elevation and endurance
4. Include intervals if appropriate (e.g., 30s work / 15s rest)
5. Minimize rest periods between exercises (30-45 seconds max)
6. For cardio exercises, use sets=1 and reps=1, with duration_seconds for the work period

CARDIO EXERCISE EXAMPLES:
- Jumping Jacks: 45 duration_seconds, sets=1, reps=1
- High Knees: 30 duration_seconds, sets=3
- Burpees: 20 duration_seconds, sets=4
- Mountain Climbers: 30 duration_seconds, sets=3
- Running in Place: 60 duration_seconds, sets=1
- Jump Rope: 45 duration_seconds, sets=4"""
        elif workout_type == "mixed":
            workout_type_instruction = """

🔥 MIXED WORKOUT TYPE:
This is a MIXED workout combining strength AND cardio. You MUST:
1. Alternate between strength and cardio exercises
2. Include 2-3 cardio bursts between strength sets
3. Use circuit-style training where possible
4. Keep rest periods shorter than pure strength workouts (45-60 seconds)
5. Include both weighted exercises AND time-based cardio movements

STRUCTURE SUGGESTION:
- Start with compound strength movement
- Follow with cardio burst (30-45 seconds)
- Repeat pattern for full workout"""
        elif workout_type == "mobility":
            workout_type_instruction = """

🧘 MOBILITY WORKOUT TYPE:
This is a MOBILITY/FLEXIBILITY-focused workout. You MUST:
1. Focus on stretching, yoga poses, and mobility drills
2. Use hold_seconds for static stretches (typically 30-60 seconds)
3. Include dynamic mobility movements with controlled tempo
4. Emphasize joint range of motion and flexibility
5. Keep rest minimal (15-30 seconds) - these are low-intensity movements
6. Include unilateral (single-side) exercises for balance work

MOBILITY EXERCISE CATEGORIES TO INCLUDE:
- Static stretches: Hip flexor stretch, Hamstring stretch, Pigeon pose (hold_seconds: 30-60)
- Dynamic mobility: Leg swings, Arm circles, Cat-cow (sets: 2-3, reps: 10-15)
- Yoga poses: Downward dog, Cobra, Child's pose, Warrior poses (hold_seconds: 30-45)
- Joint circles: Ankle circles, Wrist circles, Neck rotations (sets: 2, reps: 10 each direction)
- Foam rolling/Self-myofascial release: IT band roll, Quad roll (hold_seconds: 30-45 per area)

STRUCTURE FOR MOBILITY:
- Start with joint circles and dynamic warm-up (5 min)
- Progress to deeper stretches and yoga poses (15-20 min)
- Include balance and stability work (5 min)
- End with relaxation poses and breathing (5 min)

MOBILITY-SPECIFIC JSON FIELDS:
- Use "hold_seconds" for static holds instead of reps
- Set reps=1 for held positions
- Include "is_unilateral": true for single-side exercises
- Add detailed notes about proper form and breathing"""
        elif workout_type == "recovery":
            workout_type_instruction = """

💆 RECOVERY WORKOUT TYPE:
This is a RECOVERY/ACTIVE REST workout. You MUST:
1. Keep intensity very low (RPE 3-4 out of 10)
2. Focus on blood flow and gentle movement
3. Include light stretching and mobility work
4. Use longer holds and slower tempos
5. Emphasize breathing and relaxation
6. NO heavy weights or intense cardio

RECOVERY EXERCISE CATEGORIES:
- Light cardio: Walking, slow cycling, easy swimming (duration_seconds: 300-600)
- Gentle stretches: All major muscle groups with 45-60 second holds
- Foam rolling: Full body self-massage (30-60 seconds per muscle group)
- Breathing exercises: Box breathing, diaphragmatic breathing (duration_seconds: 120-180)
- Yoga flow: Gentle sun salutations, restorative poses
- Light mobility: Joint circles, gentle twists, easy hip openers

STRUCTURE FOR RECOVERY:
- Start with 5-10 min light cardio (walking, easy cycling)
- Gentle full-body stretching (15-20 min)
- Foam rolling/self-massage (5-10 min)
- End with breathing and relaxation (5 min)

RECOVERY-SPECIFIC NOTES:
- This is NOT a challenging workout - it should feel restorative
- Perfect for rest days or after intense training
- Focus on areas that feel tight or sore
- Encourage slow, controlled breathing throughout"""

        # Build custom program instruction if user has specified a custom training goal
        custom_program_instruction = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_instruction = f"""

🎯 CRITICAL - CUSTOM TRAINING PROGRAM:
The user has specified a custom training goal: "{custom_program_description}"

This is the user's PRIMARY training focus. You MUST:
1. Select exercises that directly support this goal
2. Structure sets/reps/rest to match this training style
3. Include skill-specific progressions where applicable
4. Name the workout to reflect this training focus

Examples:
- "Train for HYROX" → Include sled-style pushes, farmer carries, rowing, running intervals
- "Improve box jump height" → Plyometrics, power movements, explosive leg work
- "Prepare for marathon" → Running-focused, leg endurance, core stability
- "Get better at pull-ups" → Back strengthening, lat work, grip training, assisted progressions"""

        # Build custom exercises instruction if user has custom exercises
        custom_exercises_instruction = ""
        if custom_exercises and len(custom_exercises) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(custom_exercises)} custom exercises in prompt")
            exercise_list = []
            for ex in custom_exercises:
                name = ex.get("name", "")
                muscle = ex.get("primary_muscle", "")
                equip = ex.get("equipment", "")
                sets = ex.get("default_sets", 3)
                reps = ex.get("default_reps", 10)
                exercise_list.append(f"  - {name} (targets: {muscle}, equipment: {equip}, default: {sets}x{reps})")
                logger.info(f"🏋️ [Gemini Service] Custom exercise: {name} - {muscle}/{equip}")
            custom_exercises_instruction = f"""

🏋️ USER'S CUSTOM EXERCISES:
The user has created these custom exercises. You SHOULD include 1-2 of them if they match the workout focus:
{chr(10).join(exercise_list)}

When including custom exercises, use the user's default sets/reps as a starting point."""
        else:
            logger.info(f"🏋️ [Gemini Service] No custom exercises to include in prompt")

        # Build workout environment instruction if provided
        environment_instruction = ""
        if workout_environment:
            env_descriptions = {
                'commercial_gym': ('🏢 COMMERCIAL GYM', 'Full access to machines, cables, and free weights. Can use any equipment.'),
                'home_gym': ('🏠 HOME GYM', 'Dedicated home gym setup. Focus on free weights and basic equipment available.'),
                'home': ('🏡 HOME (MINIMAL)', 'Limited equipment at home. Prefer bodyweight exercises and minimal equipment.'),
                'outdoors': ('🌳 OUTDOORS', 'Outdoor workout (park, trail). Use bodyweight exercises, running, outdoor-friendly movements.'),
                'hotel': ('🧳 HOTEL/TRAVEL', 'Hotel gym with limited equipment. Focus on bodyweight and dumbbells.'),
                'apartment_gym': ('🏬 APARTMENT GYM', 'Basic apartment building gym. Focus on machines and basic weights.'),
                'office_gym': ('💼 OFFICE GYM', 'Workplace fitness center. Use machines and basic equipment.'),
                'custom': ('⚙️ CUSTOM SETUP', 'User has specific equipment they selected. Use only the equipment listed.'),
            }
            env_name, env_desc = env_descriptions.get(workout_environment, ('', workout_environment))
            if env_name:
                environment_instruction = f"\n- Workout Environment: {env_name} - {env_desc}"

        # Build detailed equipment instruction if provided
        equipment_details_instruction = ""
        if equipment_details and len(equipment_details) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(equipment_details)} detailed equipment items in prompt")
            equip_list = []
            for item in equipment_details:
                name = item.get("name", "unknown")
                quantity = item.get("quantity", 1)
                weights = item.get("weights", [])
                unit = item.get("weight_unit", "lbs")
                notes = item.get("notes", "")

                if weights:
                    weights_str = f", weights: {', '.join(str(w) for w in weights)} {unit}"
                else:
                    weights_str = ""

                notes_str = f" ({notes})" if notes else ""
                equip_list.append(f"  - {name}: qty {quantity}{weights_str}{notes_str}")

            equipment_details_instruction = f"""

🏋️ DETAILED EQUIPMENT AVAILABLE:
The user has specified exact equipment with quantities and weights. Use ONLY these items and recommend weights from this list:
{chr(10).join(equip_list)}

When recommending weights for exercises, select from the user's available weights listed above.
If user has multiple weight options, pick appropriate weights based on fitness level and exercise type."""

        # Build user preference constraints (avoided exercises, avoided muscles, staple exercises)
        preference_constraints_instruction = ""

        # Avoided exercises - CRITICAL constraint
        if avoided_exercises and len(avoided_exercises) > 0:
            logger.info(f"🚫 [Gemini Service] User has {len(avoided_exercises)} avoided exercises: {avoided_exercises[:5]}...")
            preference_constraints_instruction += f"""

🚫 CRITICAL - EXERCISES TO AVOID:
The user has EXPLICITLY requested to avoid these exercises. Do NOT include ANY of them:
{chr(10).join(f'  - {ex}' for ex in avoided_exercises)}

This is a HARD CONSTRAINT. If you include any of these exercises, the workout will be rejected.
Find suitable alternatives that work the same muscle groups."""

        # Avoided muscles - CRITICAL constraint
        if avoided_muscles:
            avoid_completely = avoided_muscles.get("avoid", [])
            reduce_usage = avoided_muscles.get("reduce", [])

            if avoid_completely:
                logger.info(f"🚫 [Gemini Service] User avoiding muscles: {avoid_completely}")
                preference_constraints_instruction += f"""

🚫 CRITICAL - MUSCLE GROUPS TO AVOID:
The user has requested to COMPLETELY AVOID these muscle groups (e.g., due to injury):
{chr(10).join(f'  - {muscle}' for muscle in avoid_completely)}

Do NOT include exercises that primarily target these muscles.
If the workout focus conflicts with this (e.g., "chest day" but avoiding chest), prioritize safety and adjust."""

            if reduce_usage:
                logger.info(f"⚠️ [Gemini Service] User reducing muscles: {reduce_usage}")
                preference_constraints_instruction += f"""

⚠️ MUSCLE GROUPS TO MINIMIZE:
The user prefers to minimize exercises for these muscle groups:
{chr(10).join(f'  - {muscle}' for muscle in reduce_usage)}

Include at most 1 exercise targeting these muscles, and prefer compound movements over isolation."""

        # Staple exercises - pre-filtered for this workout's scheduled day
        if staple_exercises and len(staple_exercises) > 0:
            staple_names = [s.get("name", s) if isinstance(s, dict) else s for s in staple_exercises]
            logger.info(f"⭐ [Gemini Service] User has {len(staple_names)} MANDATORY staple exercises for this workout: {staple_names}")

            preference_constraints_instruction += f"""

⭐ USER'S STAPLE EXERCISES - MANDATORY INCLUSION:
The user has marked these exercises as STAPLES for this workout day. You MUST include ALL of them:
{chr(10).join(f'  - {name}' for name in staple_names)}

CRITICAL: These staple exercises are NON-NEGOTIABLE for this workout. Include every one listed above. They have already been filtered for relevance to this workout day — just include them."""

        # Build comeback instruction for users returning from extended breaks
        comeback_instruction = ""
        if comeback_context and comeback_context.strip():
            logger.info(f"🔄 [Gemini Service] User is in comeback mode - applying reduced intensity instructions")
            comeback_instruction = f"""

{comeback_context}

🔄 COMEBACK WORKOUT REQUIREMENTS:
Based on the comeback context above, you MUST:
1. REDUCE the number of sets compared to normal (typically 2-3 sets max)
2. REDUCE the number of reps per set
3. INCREASE rest periods between sets
4. AVOID explosive or high-intensity movements
5. INCLUDE joint mobility exercises where appropriate
6. Focus on controlled movements and proper form
7. Keep the workout SHORTER than normal duration

This is a RETURN-TO-TRAINING workout - safety and gradual progression are CRITICAL."""

        # Build progression philosophy instruction for leverage-based progressions
        progression_philosophy_instruction = ""
        if progression_philosophy and progression_philosophy.strip():
            logger.info(f"[Gemini Service] Including progression philosophy context for leverage-based progressions")
            progression_philosophy_instruction = progression_philosophy

        # Build workout patterns context with historical data and set/rep limits
        workout_patterns_instruction = ""
        if workout_patterns_context and workout_patterns_context.strip():
            logger.info(f"[Gemini Service] Including workout patterns context with set/rep limits and historical data")
            workout_patterns_instruction = workout_patterns_context

        # Build favorite workouts context for inspiration
        favorite_workouts_instruction = ""
        if favorite_workouts_context and favorite_workouts_context.strip():
            logger.info(f"[Gemini Service] Including favorite workouts context for personalized generation")
            favorite_workouts_instruction = "\n\n" + favorite_workouts_context

        # Build set type context with user's historical preferences for advanced set types
        set_type_context_str = ""
        if set_type_context and set_type_context.strip():
            logger.info(f"[Gemini Service] Including set type context for personalized drop/failure set recommendations")
            set_type_context_str = set_type_context

        # Build primary training goal instruction (hypertrophy vs strength vs both)
        primary_goal_instruction = ""
        if primary_goal:
            logger.info(f"🎯 [Gemini Service] User has primary training goal: {primary_goal}")
            goal_mappings = {
                'muscle_hypertrophy': """
🎯 PRIMARY TRAINING FOCUS: MUSCLE HYPERTROPHY (Muscle Size)
The user's primary goal is to BUILD MUSCLE SIZE. You MUST:
- Use moderate weights with higher rep ranges (8-12 reps for compounds, 12-15 for isolation)
- Focus on time under tension - slower eccentric (3-4 seconds)
- Include more isolation exercises to target individual muscles
- Moderate rest periods (60-90 seconds)
- Include techniques like drop sets for advanced users
- RPE typically 7-9 (leave 1-3 reps in reserve)""",
                'muscle_strength': """
🎯 PRIMARY TRAINING FOCUS: MUSCLE STRENGTH (Maximal Strength)
The user's primary goal is to GET STRONGER. You MUST:
- Use heavier weights with lower rep ranges (3-6 reps for compounds, 6-8 for accessory)
- Prioritize compound movements (squat, deadlift, bench, overhead press)
- Longer rest periods (2-4 minutes) for full recovery between heavy sets
- Focus on progressive overload with weight increases
- Fewer total exercises but more sets (4-5 sets per movement)
- RPE typically 8-10 (close to or at failure on heavy sets)""",
                'strength_hypertrophy': """
🎯 PRIMARY TRAINING FOCUS: STRENGTH & HYPERTROPHY (Balanced)
The user wants BOTH strength AND muscle size. You MUST:
- Vary rep ranges within the workout (6-10 reps most common)
- Start with heavy compound movements (5-6 reps, strength focus)
- Finish with moderate isolation work (10-12 reps, hypertrophy focus)
- Moderate rest periods (90-120 seconds)
- Mix of compound and isolation exercises
- Include both strength techniques (heavy singles/doubles) and hypertrophy techniques (drop sets)
- RPE varies: 8-9 for compounds, 7-8 for isolation""",
                'endurance': """
🎯 PRIMARY TRAINING FOCUS: MUSCULAR ENDURANCE (Stamina)
The user's primary goal is to BUILD STAMINA and MUSCULAR ENDURANCE. You MUST:
- Use SHORT rest periods (30-60 seconds) between sets to build lactate threshold
- Prioritize higher total volume — more sets per session at a sustainable effort
- Structure workouts as circuits or supersets where possible to maintain elevated heart rate
- Select exercises that translate to cardiovascular endurance (compound movements, bodyweight, cardio-adjacent like battle ropes, sled push, box jumps)
- Avoid training to failure — RPE typically 6-8 (challenging but maintainable pace)
- Focus on smooth continuous tension and controlled breathing between reps
- Prefer exercise variety within a session to engage multiple energy systems""",
            }
            primary_goal_instruction = goal_mappings.get(primary_goal, "")

        # Build muscle focus points instruction (priority muscles)
        muscle_focus_instruction = ""
        if muscle_focus_points and len(muscle_focus_points) > 0:
            total_points = sum(muscle_focus_points.values())
            logger.info(f"🏋️ [Gemini Service] User has {total_points} muscle focus points allocated: {muscle_focus_points}")
            # Sort by points descending
            sorted_muscles = sorted(muscle_focus_points.items(), key=lambda x: x[1], reverse=True)
            muscle_list = "\n".join([f"  - {muscle.replace('_', ' ').title()}: {points} point{'s' if points > 1 else ''}" for muscle, points in sorted_muscles])
            muscle_focus_instruction = f"""

🏋️ MUSCLE PRIORITY - USER HAS ALLOCATED FOCUS POINTS:
The user wants EXTRA emphasis on these specific muscle groups:
{muscle_list}

REQUIREMENTS:
- Include at least ONE exercise specifically targeting each high-priority muscle (2+ points)
- For muscles with 3+ points, include TWO exercises targeting that muscle
- Place priority muscle exercises earlier in the workout (when energy is highest)
- Use slightly higher volume (extra set) for priority muscles
- These preferences should COMPLEMENT the workout focus, not replace it"""

        # Build focus area instruction based on the training split/focus
        focus_instruction = ""
        if focus_areas and len(focus_areas) > 0:
            focus = focus_areas[0].lower()
            logger.info(f"🎯 [Gemini Service] Workout focus area: {focus}")
            # Map focus areas to strict exercise selection guidelines
            focus_mapping = {
                'push': '🎯 PUSH FOCUS: Select exercises that target chest, shoulders, and triceps. Include bench press variations, shoulder press, push-ups, dips, tricep extensions.',
                'pull': '🎯 PULL FOCUS: Select exercises that target back and biceps. Include rows, pull-ups/lat pulldowns, deadlifts, curls, face pulls.',
                'legs': '🎯 LEG FOCUS: Select exercises that target quads, hamstrings, glutes, and calves. Include squats, lunges, leg press, deadlifts, calf raises.',
                'upper': '🎯 UPPER BODY: Select exercises for chest, back, shoulders, and arms. Mix pushing and pulling movements.',
                'lower': '🎯 LOWER BODY: Select exercises for quads, hamstrings, glutes, and calves. Focus on compound leg movements.',
                'chest': '🎯 CHEST FOCUS: At least 70% of exercises must target chest. Include bench press, flyes, push-ups, cable crossovers.',
                'back': '🎯 BACK FOCUS: At least 70% of exercises must target back. Include rows, pull-ups, lat pulldowns, deadlifts.',
                'shoulders': '🎯 SHOULDER FOCUS: At least 70% of exercises must target shoulders. Include overhead press, lateral raises, front raises, rear delts.',
                'arms': '🎯 ARMS FOCUS: At least 70% of exercises must target biceps and triceps. Include curls, extensions, dips, hammer curls.',
                'core': '🎯 CORE FOCUS: At least 70% of exercises must target abs and obliques. Include planks, crunches, leg raises, russian twists.',
                'glutes': '🎯 GLUTE FOCUS: At least 70% of exercises must target glutes. Include hip thrusts, glute bridges, lunges, deadlifts.',
                'full_body': '🎯 FULL BODY — MANDATORY MUSCLE GROUP COVERAGE:\n'
                    '  You MUST include exercises from ALL of these groups:\n'
                    '  1. LEGS/GLUTES (squats, lunges, leg press, deadlifts, hip thrusts) — at least 1 exercise\n'
                    '  2. BACK/PULL (rows, pull-ups, lat pulldowns) — at least 1 exercise\n'
                    '  3. CHEST/PUSH (bench press, push-ups, flyes) — at least 1 exercise\n'
                    '  4. SHOULDERS or CORE (overhead press, lateral raises, planks, crunches) — at least 1 exercise\n'
                    '  A full_body workout that is missing ANY of legs, back, or chest is INVALID.\n'
                    '  Distribute exercises across upper and lower body — do NOT load all exercises into one muscle group.',
                'full_body_push': '🎯 FULL BODY with PUSH EMPHASIS: Include exercises for all major muscle groups, but prioritize chest, shoulders, and triceps (at least 50% pushing movements).',
                'full_body_pull': '🎯 FULL BODY with PULL EMPHASIS: Include exercises for all major muscle groups, but prioritize back and biceps (at least 50% pulling movements).',
                'full_body_legs': '🎯 FULL BODY with LEG EMPHASIS: Include exercises for all major muscle groups, but prioritize legs and glutes (at least 50% lower body movements).',
                'full_body_core': '🎯 FULL BODY with CORE EMPHASIS: Include exercises for all major muscle groups, but prioritize core/abs (at least 40% core movements).',
                'full_body_upper': '🎯 FULL BODY with UPPER EMPHASIS: Include exercises for all major muscle groups, but prioritize upper body (at least 60% upper body movements).',
                'full_body_lower': '🎯 FULL BODY with LOWER EMPHASIS: Include exercises for all major muscle groups, but prioritize lower body (at least 60% lower body movements).',
                'full_body_power': '🎯 FULL BODY POWER: Focus on explosive, compound movements across all muscle groups. Include power cleans, box jumps, kettlebell swings.',
                'upper_power': '🎯 UPPER BODY POWER: Heavy compound upper body movements. Lower reps (4-6), higher weight. Include bench press, overhead press, rows.',
                'lower_power': '🎯 LOWER BODY POWER: Heavy compound leg movements. Lower reps (4-6), higher weight. Include squats, deadlifts, leg press.',
                'upper_hypertrophy': '🎯 UPPER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for chest, back, shoulders, arms.',
                'lower_hypertrophy': '🎯 LOWER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for quads, hamstrings, glutes.',
            }
            focus_instruction = focus_mapping.get(focus, f'🎯 FOCUS: {focus.upper()} - Select exercises primarily targeting this area.')

        # Build duration text - use range if both min and max provided
        if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
            duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
        else:
            duration_text = str(duration_minutes)

        # Build training split context with scientific rationale
        training_split_instruction = ""
        if training_split:
            split_context = get_split_context(training_split, workout_days=workout_days)
            training_split_instruction = f"""

📊 TRAINING SPLIT CONTEXT (Research-Backed):
{split_context}

Use this split information to guide exercise selection and workout structure."""

        # Build fitness assessment instruction for smarter workout personalization
        fitness_assessment_instruction = ""
        assessment_fields = []
        if pushup_capacity:
            assessment_fields.append(f"Push-ups: {pushup_capacity}")
        if pullup_capacity:
            assessment_fields.append(f"Pull-ups: {pullup_capacity}")
        if plank_capacity:
            assessment_fields.append(f"Plank hold: {plank_capacity}")
        if squat_capacity:
            assessment_fields.append(f"Bodyweight squats: {squat_capacity}")
        if cardio_capacity:
            assessment_fields.append(f"Cardio endurance: {cardio_capacity}")
        if training_experience:
            assessment_fields.append(f"Training experience: {training_experience}")

        if assessment_fields:
            logger.info(f"💪 [Gemini Service] Including fitness assessment data: {assessment_fields}")
            fitness_assessment_instruction = f"""

💪 USER FITNESS ASSESSMENT (Use for Personalization):
The user completed a fitness assessment with the following results:
{chr(10).join(f'  - {field}' for field in assessment_fields)}

CRITICAL - USE THIS DATA TO PERSONALIZE THE WORKOUT:
1. SET APPROPRIATE REP RANGES:
   - User with 1-10 push-ups → prescribe 6-8 reps for pressing exercises
   - User with 11-25 push-ups → prescribe 8-12 reps for pressing exercises
   - User with 26-40+ push-ups → prescribe 10-15 reps for pressing exercises

2. CHOOSE EXERCISE DIFFICULTY:
   - User with 'none' or 'assisted' pull-ups → use lat pulldowns, assisted pull-ups, band-assisted variations
   - User with 1-5 pull-ups → include 1-2 pull-up sets with low reps, supplement with rows
   - User with 6+ pull-ups → include weighted pull-ups or higher volume

3. SCALE CORE EXERCISES:
   - User with <15sec or 15-30sec plank → shorter hold times (15-20 sec), include easier core variations
   - User with 31-60sec plank → moderate holds (30-45 sec), standard core exercises
   - User with 1-2min+ plank → longer holds (45-60+ sec), advanced core variations

4. ADJUST LEG EXERCISES:
   - User with 0-10 squats → lighter loads, focus on form, maybe assisted squats
   - User with 11-25 squats → moderate loads and volume
   - User with 26-40+ squats → higher volume, heavier loads, advanced variations

5. SET REST PERIODS:
   - Lower capacity users → longer rest periods (90-120 sec)
   - Higher capacity users → standard rest periods (60-90 sec)

6. CARDIO COMPONENTS:
   - <5min cardio capacity → very short cardio bursts (30-60 sec), more rest
   - 5-15min → moderate cardio intervals (1-2 min work periods)
   - 15-30min+ → longer cardio segments if workout type requires it

7. EXERCISE COMPLEXITY BY TRAINING EXPERIENCE:
   - 'never' to '1-3yr' → barbell compounds (squat, bench, deadlift, OHP, rows), cable variations, supersets, fundamental dumbbell movements, machine exercises, include form cues for newer lifters
   - '3-5yr' → all of the above plus advanced techniques (drop sets, pause reps, tempo work), varied grips/stances, isolation work for weak points
   - '5+yr' → all of the above plus advanced programming (cluster sets, mechanical drop sets, advanced supersets), complex movement patterns, periodization-aware exercise selection

This assessment data reflects the user's ACTUAL capabilities - use it to create a workout that challenges them appropriately without being too easy or impossibly hard."""

        # Detect bench/rack availability for conditional exercise examples
        _eq_normalised = [e.strip().lower() if isinstance(e, str) else (e.get("name") or e.get("value") or "").strip().lower() for e in (equipment or [])]
        has_bench_in_equipment = any("bench" in e for e in _eq_normalised) or any("home_gym" in e or "full_gym" in e for e in _eq_normalised)
        has_rack_in_equipment = any("squat_rack" in e or "rack" in e or "power_rack" in e for e in _eq_normalised) or any("full_gym" in e for e in _eq_normalised)
        dumbbell_examples = (
            "Dumbbell Bench Press, Dumbbell Rows, Dumbbell Lunges, Dumbbell Shoulder Press, Goblet Squats, Dumbbell Curls"
            if has_bench_in_equipment else
            "Dumbbell Floor Press, Dumbbell Rows, Dumbbell Lunges, Dumbbell Shoulder Press, Goblet Squats, Dumbbell Curls, Dumbbell Deadlift"
        )
        barbell_examples = (
            "Barbell Squat, Deadlift, Bench Press, Barbell Row, Overhead Press"
            if has_rack_in_equipment else
            "Deadlift, Romanian Deadlift, Barbell Row, Good Morning, Barbell Hip Thrust"
        )

        prompt = f"""Generate a {duration_text}-minute workout plan for a user with:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(goals, 'General fitness')}
- Available Equipment: {safe_join_list(equipment, 'Bodyweight only')}
- Focus Areas: {safe_join_list(focus_areas, 'Full body')}
- Workout Type: {workout_type}{environment_instruction}{age_activity_context}{training_split_instruction}{fitness_assessment_instruction}{safety_instruction}{workout_type_instruction}{custom_program_instruction}{custom_exercises_instruction}{equipment_details_instruction}{preference_constraints_instruction}{comeback_instruction}{progression_philosophy_instruction}{workout_patterns_instruction}{favorite_workouts_instruction}{primary_goal_instruction}{muscle_focus_instruction}

⚠️ CRITICAL - MUSCLE GROUP TARGETING:
{focus_instruction if focus_instruction else 'Select a balanced mix of exercises.'}
You MUST follow this focus area strictly. Do NOT give random exercises that don't match the focus.
EXAMPLE: If focus is LEGS, you MUST include squats, lunges, leg press - NOT push-ups or bench press!
If focus is PUSH, include chest/shoulder/tricep exercises - NOT squats or rows!
{senior_critical_instruction}

Return a valid JSON object with this exact structure:
{{
  "name": "A CREATIVE, UNIQUE workout name ENDING with body part focus (e.g., 'Thunder Legs', 'Phoenix Chest', 'Cobra Back')",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "duration_minutes_min": {duration_minutes_min or 'null'},
  "duration_minutes_max": {duration_minutes_max or 'null'},
  "estimated_duration_minutes": null,
  "target_muscles": ["Primary muscle 1", "Primary muscle 2"],
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": 12,
      "weight_kg": 10,
      "rest_seconds": 60,
      "duration_seconds": null,
      "hold_seconds": null,
      "equipment": "equipment used or bodyweight",
      "muscle_group": "primary muscle targeted",
      "is_unilateral": false,
      "is_drop_set": false,
      "is_failure_set": false,
      "drop_set_count": null,
      "drop_set_percentage": null,
      "notes": "Form tips or modifications",
      "set_targets": [
        {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 15, "target_rpe": 5, "target_rir": null}},
        {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 25, "target_rpe": 7, "target_rir": 3}},
        {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 25, "target_rpe": 8, "target_rir": 2}},
        {{"set_number": 4, "set_type": "failure", "target_reps": 8, "target_weight_kg": 25, "target_rpe": 10, "target_rir": 0}}
      ]
    }}
  ],
  "notes": "Overall workout tips including warm-up and cool-down recommendations"
}}

⏱️ ESTIMATED DURATION CALCULATION (CRITICAL):
After generating the workout, you MUST calculate the actual estimated duration and set "estimated_duration_minutes".
Calculate it as: SUM of (each exercise's sets × (reps × 3 seconds + rest_seconds)) / 60
Include time for transitions between exercises (add ~30 seconds per exercise).
Round to nearest integer.

🚨 DURATION CONSTRAINT (MANDATORY):
- If duration_minutes_max is provided, the calculated estimated_duration_minutes MUST be ≤ duration_minutes_max
- If duration_minutes_min is provided, aim for estimated_duration_minutes to be ≥ duration_minutes_min
- If range is 30-45 min, aim for 35-42 min (comfortably within range)
- Adjust number of exercises or sets to fit within the time constraint
- NEVER exceed the maximum duration - users have limited time!

Example calculation for 4 exercises:
- Exercise 1: 4 sets × (10 reps × 3s + 60s rest) = 4 × 90s = 360s
- Exercise 2: 3 sets × (12 reps × 3s + 60s rest) = 3 × 96s = 288s
- Exercise 3: 3 sets × (8 reps × 3s + 90s rest) = 3 × 114s = 342s
- Exercise 4: 3 sets × (12 reps × 3s + 45s rest) = 3 × 81s = 243s
- Transitions: 4 exercises × 30s = 120s
- Total: (360 + 288 + 342 + 243 + 120) / 60 = 22.55 ≈ 23 minutes
Set "estimated_duration_minutes": 23

🚨🚨🚨 SET TARGETS - ABSOLUTELY REQUIRED (DO NOT SKIP) 🚨🚨🚨
This is the MOST IMPORTANT field in the entire response!
For EVERY exercise without exception, you MUST include a "set_targets" array.
NEVER leave set_targets empty or null - the app will break without it!

Each set_targets entry must include:
- set_number: 1-indexed set number
- set_type: One of "warmup", "working", "drop", "failure", "amrap"
- target_reps: Specific rep target for this set
- target_weight_kg: Specific weight target for this set (reduces for drop sets)
- target_rpe: Target Rate of Perceived Exertion (1-10, where 10 is max effort)
- target_rir: Target Reps in Reserve (0-5, where 0 means failure)

SET TYPE GUIDELINES:
- Include 1 warmup set at 50% weight for compound exercises
- Working sets should increase RPE progressively (7, 8, 9)
- Drop sets: Each drop reduces weight by 20-25% with same reps
- Failure/AMRAP sets: RPE 10, RIR 0

PER-SET REP CEILINGS BY EXERCISE TYPE (MANDATORY - NEVER EXCEED):
- Compound exercises (squat, deadlift, bench press, overhead press, row, pull-up, lunge, dip, pulldown): MAX 12 reps per set
- Isolation exercises (curl, extension, raise, fly, kickback, pullover): MAX 15 reps per set
- Bodyweight conditioning (plank, crunch, burpee, mountain climber): MAX 20 reps per set
- These ceilings apply to EVERY set in set_targets including the first set of pyramid patterns
- Example: For a 3-set pyramid on bench press, use 12/10/8 reps (NOT 16/14/12)

EXAMPLE for a 4-set exercise with 2 drop sets:
"set_targets": [
  {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 20, "target_rpe": 5, "target_rir": null}},
  {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 40, "target_rpe": 8, "target_rir": 2}},
  {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 40, "target_rpe": 9, "target_rir": 1}},
  {{"set_number": 4, "set_type": "drop", "target_reps": 10, "target_weight_kg": 30, "target_rpe": 9, "target_rir": 1}},
  {{"set_number": 5, "set_type": "drop", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 10, "target_rir": 0}}
]

NOTE: For cardio exercises, use duration_seconds (e.g., 30) instead of reps (set reps to 1).
For strength exercises, set duration_seconds to null and use reps normally.
For mobility/stretching exercises, use hold_seconds (e.g., 30-60) for static holds instead of reps.
For unilateral exercises (single-arm, single-leg), set is_unilateral: true.

For ISOMETRIC/TIME-BASED exercises (planks, wall sits, dead hangs, L-sits, hollow holds, static holds):
- Set hold_seconds to the BASE time (e.g., 30)
- Use target_hold_seconds in set_targets for PROGRESSIVE hold times per set
- Set reps to 1 for each set (since it's time-based, not rep-based)

EXAMPLE for progressive plank (15s -> 30s -> 45s):
{{
  "name": "Forearm Plank",
  "sets": 3,
  "reps": 1,
  "hold_seconds": 30,
  "rest_seconds": 60,
  "set_targets": [
    {{"set_number": 1, "set_type": "warmup", "target_reps": 1, "target_hold_seconds": 15}},
    {{"set_number": 2, "set_type": "working", "target_reps": 1, "target_hold_seconds": 30}},
    {{"set_number": 3, "set_type": "working", "target_reps": 1, "target_hold_seconds": 45}}
  ]
}}
{set_type_context_str}
🚨🚨🚨 MANDATORY ADVANCED TECHNIQUES (NON-NEGOTIABLE FOR NON-BEGINNERS) 🚨🚨🚨

FOR INTERMEDIATE FITNESS LEVEL - YOU MUST INCLUDE:
- At least 1 exercise with is_failure_set: true (final isolation exercise)
- The failure set exercise MUST have notes containing "AMRAP" or "to failure"

FOR ADVANCED FITNESS LEVEL - YOU MUST INCLUDE:
- At least 2 exercises with is_failure_set: true
- At least 1 exercise with is_drop_set: true (on an isolation exercise)
- When is_drop_set: true, ALSO set drop_set_count: 2 and drop_set_percentage: 20

FOR BEGINNER FITNESS LEVEL:
- NO failure sets (is_failure_set: false for all)
- NO drop sets (is_drop_set: false for all)

FAILURE SET RULES (is_failure_set: true):
- Apply to the LAST isolation exercise in the workout
- Set notes to include "AMRAP" or "Final set to failure"
- Example exercises: Bicep Curl, Lateral Raise, Tricep Extension, Leg Curl

DROP SET RULES (is_drop_set: true):
- Apply to isolation exercises ONLY (never compounds)
- MUST also set: drop_set_count: 2, drop_set_percentage: 20
- Set notes to include "Drop set: reduce weight 20% twice"

EXAMPLE INTERMEDIATE WORKOUT (notice failure set on last exercise):
Exercise 5: {{"name": "Bicep Curl", "sets": 3, "reps": 12, "is_failure_set": true, "is_drop_set": false, "notes": "Final set: AMRAP"}}

EXAMPLE ADVANCED WORKOUT (notice both failure AND drop set):
Exercise 6: {{"name": "Lateral Raise", "sets": 3, "reps": 15, "is_failure_set": true, "is_drop_set": true, "drop_set_count": 2, "drop_set_percentage": 20, "notes": "AMRAP then drop 20% twice"}}

⚠️ CRITICAL - REALISTIC WEIGHT RECOMMENDATIONS:
For each exercise, include a starting weight_kg that follows industry-standard equipment increments:
- Dumbbell exercises: Use weights in 2.5kg (5lb) increments (2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20...)
- Barbell exercises: Use weights in 2.5kg (5lb) increments
- Machine exercises: Use weights in 5kg (10lb) increments (5, 10, 15, 20, 25...)
- Kettlebell exercises: Use weights in 4kg (8lb) increments (4, 8, 12, 16, 20, 24...)
- Bodyweight exercises: Use weight_kg: 0

Starting weight guidelines by fitness level:
- Beginner: Compound exercises 5-10kg, Isolation exercises 2.5-5kg
- Intermediate: Compound exercises 15-25kg, Isolation exercises 7.5-12.5kg
- Advanced: Compound exercises 30-50kg, Isolation exercises 15-20kg

NEVER recommend unrealistic increments like 2.5 lbs for dumbbells - the minimum is 5 lbs (2.5 kg)!

🏋️ PERIODIZATION - VARY SETS/REPS BY EXERCISE TYPE (MANDATORY):

❌ DO NOT use 3x10 for every exercise! This is lazy and ineffective programming.

COMPOUND EXERCISES (Squat, Deadlift, Bench Press, Row, Overhead Press, Pull-Up):
- Sets: 4-5
- Reps: 5-8 (heavier weight, lower reps for strength)
- Example: Barbell Squat 4x6, Bench Press 5x5, Deadlift 4x5

ISOLATION EXERCISES (Curls, Extensions, Raises, Flyes, Kickbacks):
- Sets: 3
- Reps: 12-15 (lighter weight, higher reps for hypertrophy)
- Example: Bicep Curl 3x12, Lateral Raise 3x15, Tricep Extension 3x15

MACHINE/CABLE EXERCISES:
- Sets: 3-4
- Reps: 10-12
- Example: Leg Press 3x12, Cable Fly 3x12, Lat Pulldown 4x10

BODYWEIGHT EXERCISES:
- Beginner: 3x8-10 (or to near failure)
- Intermediate: 3x12-15
- Advanced: 4x15+ or add weight

SMALL MUSCLE GROUPS (Calves, Forearms, Rear Delts):
- Sets: 3-4
- Reps: 15-20 (higher reps for endurance muscles)
- Example: Calf Raise 4x20, Wrist Curl 3x15

⚠️ REST TIME VARIATION (VARY BY EXERCISE):
- Compound Heavy (Squat, Deadlift, Bench): rest_seconds: 120-180
- Compound Moderate (Row, Lunge, Press): rest_seconds: 90-120
- Isolation (Curls, Extensions, Raises): rest_seconds: 60-90
- Bodyweight/Machine: rest_seconds: 60-75

EXAMPLE GOOD LEG WORKOUT (VARIED SETS/REPS):
1. Barbell Squat: 4x6, rest: 150s (compound - low reps, long rest)
2. Romanian Deadlift: 4x8, rest: 120s (compound - moderate)
3. Leg Press: 3x12, rest: 90s (machine - higher reps)
4. Leg Curl: 3x15, rest: 60s (isolation - high reps, short rest)
5. Calf Raise: 4x20, rest: 45s (small muscle - endurance)

EXAMPLE BAD WORKOUT (REJECTED - DO NOT DO THIS):
❌ Squat 3x10, RDL 3x10, Leg Press 3x10, Leg Curl 3x10, Calf Raise 3x10 (all same!)

🎯 WORKOUT NAME - BE EXTREMELY CREATIVE:
Create a name that makes users PUMPED to work out! Use diverse vocabulary:

ACTION WORDS (pick creatively):
- Power: Blitz, Surge, Blast, Strike, Rush, Bolt, Flash, Charge, Jolt, Spark
- Intensity: Inferno, Blaze, Scorch, Burn, Fire, Flame, Heat, Ember, Torch, Ignite
- Nature: Storm, Thunder, Lightning, Hurricane, Tornado, Avalanche, Earthquake, Tsunami, Cyclone, Tempest
- Force: Crush, Smash, Shatter, Break, Demolish, Destroy, Wreck, Obliterate, Annihilate, Pulverize
- Speed: Sprint, Dash, Zoom, Rocket, Jet, Turbo, Hyper, Sonic, Rapid, Swift
- Combat: Warrior, Gladiator, Viking, Spartan, Samurai, Ninja, Knight, Conqueror, Champion, Fighter
- Animal: Wolf, Lion, Tiger, Bear, Hawk, Eagle, Dragon, Phoenix, Panther, Cobra
- Mythic: Titan, Atlas, Zeus, Thor, Hercules, Apollo, Odin, Valkyrie, Olympus, Valhalla

⚠️ CRITICAL NAMING RULES:
1. Name MUST be 3-4 words
2. Name MUST end with the body part/muscle focus
3. Be creative and motivating!

EXAMPLES OF GOOD 3-4 WORD NAMES:
- "Savage Wolf Legs" ✓ (3 words, ends with body part)
- "Iron Phoenix Chest" ✓ (3 words, ends with body part)
- "Thunder Strike Back" ✓ (3 words, ends with body part)
- "Mighty Storm Core" ✓ (3 words, ends with body part)
- "Ultimate Power Shoulders" ✓ (3 words, ends with body part)
- "Blazing Beast Glutes" ✓ (3 words, ends with body part)

BAD EXAMPLES:
- "Thunder Legs" ✗ (only 2 words!)
- "Blitz Panther Pounce" ✗ (no body part!)
- "Wolf" ✗ (too short, no body part!)

BODY PARTS TO END WITH:
- Upper: Chest, Back, Shoulders, Arms, Biceps, Triceps
- Core: Core, Abs, Obliques
- Lower: Legs, Quads, Glutes, Hamstrings, Calves
- Full: Full Body, Total Body

FORMAT: [Adjective/Action] + [Animal/Mythic/Theme] + [Body Part]
- "Raging Bull Legs", "Silent Ninja Back", "Golden Phoenix Chest"
- "Explosive Tiger Core", "Relentless Warrior Arms", "Primal Beast Shoulders"
{holiday_instruction}{avoid_instruction}

Requirements:
- MUST include AT LEAST 5 exercises (minimum 5, ideally 6-8) appropriate for {fitness_level} fitness level
- EVERY exercise MUST match the focus area - do NOT include exercises for other muscle groups!
- ONLY use equipment from this list: {safe_join_list(equipment, 'bodyweight')}

🚨🚨🚨 ABSOLUTE CRITICAL RULE - EQUIPMENT USAGE 🚨🚨🚨
Available equipment: {safe_join_list(equipment, 'bodyweight only')}

{_build_equipment_usage_rule(equipment)}

MANDATORY EQUIPMENT-BASED EXERCISES (include these when equipment is available):
- full_gym/commercial_gym: Barbell Squat, Bench Press, Lat Pulldown, Cable Row, Leg Press, Dumbbell Rows
- dumbbells: {dumbbell_examples}
- barbell: {barbell_examples}
- cable_machine: Cable Fly, Face Pull, Tricep Pushdown, Cable Row, Lat Pulldown
- machines: Leg Press, Chest Press Machine, Lat Pulldown, Leg Curl, Shoulder Press Machine
- kettlebell/kettlebells: Kettlebell Swings, Goblet Squats, KB Clean & Press, KB Turkish Get-up, KB Deadlift, KB Snatch
- resistance_bands: Banded Squats, Band Pull-Aparts, Banded Push-Ups, Band Rows, Banded Lateral Walks
- pull_up_bar: Pull-Ups, Chin-Ups, Hanging Leg Raises, Dead Hangs
- trx/suspension_trainer: TRX Rows, TRX Push-Ups, TRX Pistol Squats, TRX Y-Raises

FOR BEGINNERS WITH GYM ACCESS - THIS IS CRITICAL:
Beginners benefit MORE from weighted exercises than bodyweight! Use machines and dumbbells for:
- Better muscle activation with controlled resistance
- Easier to maintain proper form than advanced calisthenics
- Measurable progressive overload
EXAMPLE BEGINNER GYM WORKOUT (LEGS): Leg Press, Goblet Squat, Dumbbell Romanian Deadlift, Leg Extension Machine, Lying Leg Curl, Calf Raises on Machine
EXAMPLE BEGINNER GYM WORKOUT (PUSH): Dumbbell Bench Press, Machine Shoulder Press, Cable Fly, Dumbbell Lateral Raise, Tricep Pushdown
NOT: Push-ups, Planks, Bodyweight Squats (these are for home/no-equipment only!)

⚠️ CRITICAL FOR BEGINNERS: Do NOT include advanced/elite calisthenics movements like planche push-ups, front levers, muscle-ups, handstand push-ups, one-arm pull-ups, pistol squats, human flags, or L-sits. These require YEARS of training.

- For intermediate: balanced challenge, mix of compound and isolation movements
- For advanced: higher intensity, complex movements, advanced techniques, less rest
- For HELL difficulty: MAXIMUM intensity! Supersets, drop sets, minimal rest (30-45s), heavy weights, near-failure reps. This should be the hardest workout possible. Include at least 7-8 exercises with 4-5 sets each.
- Align exercise selection with goals: {', '.join(goals) if goals else 'general fitness'}

🚨 CRITICAL EXERCISE VARIETY RULES - MUST FOLLOW:
- Each exercise MUST be a DIFFERENT movement pattern
- NEVER include multiple variations of the same exercise type:
  * NO: 2+ push-up variations (push-ups, diamond push-ups, decline push-ups, explosive push-ups)
  * NO: 2+ curl variations (bicep curls, hammer curls, preacher curls)
  * NO: 2+ squat variations (goblet squats, front squats, back squats, jump squats)
  * NO: 2+ row variations (bent-over rows, cable rows, dumbbell rows)
- Instead, vary movement patterns across the workout:
  * Horizontal push (bench press, push-ups, fly)
  * Vertical push (overhead press, lateral raise)
  * Horizontal pull (rows)
  * Vertical pull (pull-ups, pulldowns)
  * Squat pattern (squats)
  * Hinge pattern (deadlifts, RDLs)
  * Lunge pattern (lunges, step-ups)
  * Core work
- Example GOOD chest workout: Bench Press, Cable Fly, Dips, Incline Dumbbell Press, Push-ups (only 1 push-up), Face Pulls
- Example BAD chest workout: Push-ups, Diamond Push-ups, Decline Push-ups, Wide Push-ups, Explosive Push-ups (REJECTED - all same pattern!)

- Each exercise should have helpful form notes

🚨 FINAL VALIDATION CHECKLIST (You MUST verify before responding):
1. ✅ Focus area check: ALL exercises match the focus area (legs/push/pull/etc.)
2. ✅ Equipment check: If gym equipment available, AT LEAST 4-5 exercises use weights/machines
3. ✅ Beginner check: If beginner + gym, mostly machine/dumbbell exercises (NOT bodyweight)
4. ✅ No advanced calisthenics for beginners
5. ✅ VARIETY CHECK: No more than 2 exercises per movement pattern (no 3+ push-ups, no 3+ curls)
6. ✅ PERIODIZATION CHECK: Sets/reps MUST vary by exercise type (NOT all 3x10!)
7. ✅ REST TIME CHECK: Rest times MUST vary (compounds: 120-180s, isolation: 60-90s)
8. ✅ ADVANCED TECHNIQUES (MANDATORY for intermediate/advanced):
   - INTERMEDIATE: Last exercise MUST have is_failure_set: true, notes: "AMRAP"
   - ADVANCED: 2 exercises with is_failure_set: true, 1 with is_drop_set: true
   - BEGINNER: ALL exercises have is_failure_set: false, is_drop_set: false

If focus is "legs" - every exercise should target quads, hamstrings, glutes, or calves.
If focus is "push" - every exercise should target chest, shoulders, or triceps.
If focus is "pull" - every exercise should target back or biceps.
If user has gym equipment - most exercises MUST use that equipment!"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_plan]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, equipment={equipment}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Age: {age}, Activity level: {activity_level}")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

        try:
            async with _gemini_semaphore(user_id=user_id):
                response = await asyncio.wait_for(
                    client.aio.models.generate_content(
                        model=self.model,
                        contents=prompt,
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            response_schema=GeneratedWorkoutResponse,
                            temperature=0.7,  # Higher creativity for unique workout names
                            max_output_tokens=8000  # Increased for detailed workout plans with set_targets
                        ),
                    ),
                    timeout=90,  # 90s for full workout generation (large prompt + response)
                )

            _log_token_usage(response, "generate_workout_plan")

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                # Debug: log raw response details
                logger.error(f"[DEBUG] response.parsed is None!")
                logger.error(f"[DEBUG] response.text exists: {bool(response.text)}")
                if response.text:
                    logger.error(f"[DEBUG] response.text (first 500): {response.text[:500]}")
                if hasattr(response, 'candidates') and response.candidates:
                    for i, cand in enumerate(response.candidates):
                        logger.error(f"[DEBUG] candidate {i} finish_reason: {cand.finish_reason}")
                raise ValueError("Gemini returned empty workout response")

            # Handle case where parsed may be a Pydantic model or raw data
            if hasattr(parsed, 'model_dump'):
                workout_data = parsed.model_dump()
            elif isinstance(parsed, dict):
                workout_data = parsed
            elif isinstance(parsed, str):
                # SDK sometimes returns raw string instead of parsed model
                try:
                    workout_data = json.loads(parsed)
                except (json.JSONDecodeError, ValueError):
                    raise ValueError(f"Gemini returned unparseable string response: {parsed[:200]}")
            else:
                raise ValueError(f"Unexpected parsed type from Gemini: {type(parsed).__name__}")

            if not isinstance(workout_data, dict):
                raise ValueError(f"workout_data is not a dict after parsing: type={type(workout_data).__name__}")

            # Validate required fields
            if "exercises" not in workout_data or not workout_data["exercises"]:
                raise ValueError("AI response missing exercises")

            # CRITICAL: Validate set_targets - FAIL if missing (no fallback)
            user_context = {
                "fitness_level": fitness_level,
                "difficulty": intensity_preference or "medium",
                "goals": goals,
                "equipment": equipment,
                "generation_source": "gemini_generate_workout_plan",
            }
            workout_data["exercises"] = validate_set_targets_strict(workout_data["exercises"], user_context)

            return workout_data

        except Exception as e:
            logger.error(f"Workout generation failed: {e}")
            raise

