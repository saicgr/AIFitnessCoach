"""
Gemini Service Hormonal Health Prompts.
"""
from typing import Dict, List, Optional

# ============================================================================
# HORMONAL HEALTH PROMPTS
# Specialized prompts for hormone-supportive workout and nutrition recommendations
# ============================================================================

class HormonalHealthPrompts:
    """
    Prompts for hormonal health-aware AI coaching.

    Provides context-aware prompts for:
    - Menstrual cycle phase-based workout adjustments
    - Testosterone optimization recommendations
    - Estrogen balance support
    - PCOS and menopause-friendly modifications
    - Gender-specific exercise and nutrition guidance
    """

    @staticmethod
    def get_cycle_phase_prompt(phase: str) -> str:
        """Get coaching prompt for specific menstrual cycle phase."""
        phase_prompts = {
            "menstrual": """The user is in their MENSTRUAL phase (days 1-5):
- Energy levels are typically lower due to hormone dip
- Focus on gentle, restorative movements
- Recommend: yoga, walking, light stretching, swimming
- Avoid: high-intensity intervals, heavy lifting, inversions
- Nutrition focus: iron-rich foods (spinach, lentils), anti-inflammatory foods (turmeric, ginger)
- Be extra supportive and understanding about energy fluctuations
- Suggest reducing workout intensity by 20-30% if they're feeling fatigued""",

            "follicular": """The user is in their FOLLICULAR phase (days 6-13):
- Estrogen is rising, energy and mood typically improving
- Great time for challenging workouts and trying new exercises
- Recommend: strength training, HIIT, new skill work, group classes
- Can push harder and increase intensity
- Nutrition focus: light, fresh foods, fermented foods, lean proteins
- Encourage them to take on challenging goals and PR attempts
- Body can handle more stress and recover faster""",

            "ovulation": """The user is in their OVULATION phase (days 14-16):
- Peak energy and strength - estrogen and testosterone at highest
- Optimal time for personal records and competitions
- Recommend: high-intensity workouts, PR attempts, challenging exercises
- Social energy is high - great for group workouts
- Nutrition focus: fiber-rich foods, antioxidants, raw vegetables
- Encourage maximum effort and celebrate achievements
- Be aware of slightly increased injury risk due to ligament laxity""",

            "luteal": """The user is in their LUTEAL phase (days 17-28):
- Progesterone rises then both hormones drop, may experience PMS
- Focus on maintenance rather than PRs
- Recommend: moderate cardio, pilates, strength maintenance, recovery work
- Avoid: extreme endurance, new max attempts
- Nutrition focus: complex carbs (serotonin support), magnesium, B vitamins
- Be patient and understanding about mood fluctuations
- Body temperature is slightly elevated - may fatigue faster"""
        }
        return phase_prompts.get(phase.lower(), "")

    @staticmethod
    def get_hormone_goal_prompt(goal: str) -> str:
        """Get coaching prompt for specific hormone optimization goal."""
        goal_prompts = {
            "optimize_testosterone": """The user's goal is TESTOSTERONE OPTIMIZATION:
- Prioritize compound movements: squats, deadlifts, bench press, rows
- Recommend higher intensity with adequate rest (2-3 min between heavy sets)
- Include exercises that engage large muscle groups
- Suggest adequate sleep (7-9 hours) for hormone production
- Nutrition focus: zinc (oysters, beef), vitamin D, healthy fats, adequate protein
- Foods: eggs, tuna, pomegranate, garlic, ginger
- Avoid: excessive cardio, overtraining, alcohol
- Stress management is crucial for testosterone levels""",

            "balance_estrogen": """The user's goal is ESTROGEN BALANCE:
- Include a mix of strength and cardio for overall hormonal health
- Recommend exercises that support liver health (estrogen metabolism)
- Nutrition focus: cruciferous vegetables (broccoli, cauliflower, kale)
- Foods: flaxseeds (lignans), berries (antioxidants), turmeric
- Include fiber for healthy estrogen elimination
- Avoid: excessive alcohol, processed foods, environmental estrogens
- Stress reduction is important for hormonal balance""",

            "pcos_management": """The user has PCOS (Polycystic Ovary Syndrome):
- Prioritize insulin sensitivity: strength training + moderate cardio
- Recommend lower-intensity, consistent exercise over sporadic intense workouts
- Include resistance training 3-4x per week
- Nutrition focus: low glycemic foods, anti-inflammatory diet
- Foods: salmon (omega-3s), leafy greens, nuts, cinnamon, olive oil
- Avoid: refined carbs, sugar spikes, excessive high-intensity exercise
- Weight management through sustainable exercise is key
- Be supportive about symptoms like fatigue and mood changes""",

            "menopause_support": """The user is managing MENOPAUSE symptoms:
- Focus on bone health: weight-bearing exercises, resistance training
- Include exercises for balance and fall prevention
- Moderate intensity is usually better than high intensity
- Nutrition focus: phytoestrogens (moderate soy), calcium, vitamin D
- Foods: chickpeas, whole grains, leafy greens
- Be aware of hot flashes - suggest workout timing and cooling strategies
- Strength training helps with metabolism changes
- Include flexibility and mobility work for joint health""",

            "improve_fertility": """The user's goal is FERTILITY support:
- Moderate, consistent exercise is best - avoid overtraining
- Recommend stress-reducing activities: yoga, walking, swimming
- Avoid: excessive high-intensity exercise, very low body fat
- Nutrition focus: folate (spinach, citrus), antioxidants, omega-3s
- Foods: leafy greens, berries, fatty fish, sweet potatoes
- Adequate rest and recovery are essential
- Support overall hormonal balance without extreme measures""",

            "energy_optimization": """The user wants to OPTIMIZE ENERGY through hormonal support:
- Balance between strength training and recovery
- Include morning workouts when cortisol is naturally higher
- Nutrition focus: B vitamins, iron, adaptogens
- Foods: whole grains, lean proteins, leafy greens
- Prioritize sleep quality and consistent sleep schedule
- Manage stress through exercise without overtraining
- Include both active recovery and complete rest days""",

            "libido_enhancement": """The user wants to support healthy LIBIDO:
- Include strength training for testosterone/hormone support
- Cardiovascular health supports blood flow
- Nutrition focus: zinc, vitamin D, healthy fats, omega-3s
- Foods: oysters, dark chocolate, watermelon, nuts
- Stress reduction is crucial
- Adequate sleep for hormone production
- Avoid: overtraining, excessive alcohol, chronic stress"""
        }
        return goal_prompts.get(goal.lower(), "")

    @staticmethod
    def build_hormonal_context_prompt(
        hormonal_context: Dict,
        include_food_recommendations: bool = True
    ) -> str:
        """
        Build a comprehensive hormonal context prompt from user data.

        Args:
            hormonal_context: Dict with user's hormonal profile data
            include_food_recommendations: Whether to include food suggestions

        Returns:
            Formatted prompt string for AI context
        """
        prompts = []

        # Add cycle phase context if tracking
        if hormonal_context.get("cycle_phase"):
            phase_prompt = HormonalHealthPrompts.get_cycle_phase_prompt(
                hormonal_context["cycle_phase"]
            )
            if phase_prompt:
                prompts.append(phase_prompt)
                if hormonal_context.get("cycle_day"):
                    prompts.append(f"Current cycle day: {hormonal_context['cycle_day']}")

        # Add hormone goal contexts
        hormone_goals = hormonal_context.get("hormone_goals", [])
        for goal in hormone_goals:
            goal_prompt = HormonalHealthPrompts.get_hormone_goal_prompt(goal)
            if goal_prompt:
                prompts.append(goal_prompt)

        # Add symptom awareness if present
        symptoms = hormonal_context.get("symptoms", [])
        if symptoms:
            symptom_str = ", ".join(symptoms[:5])  # Limit to top 5
            prompts.append(
                f"User is currently experiencing: {symptom_str}. "
                f"Be mindful of these symptoms when making exercise recommendations."
            )

        # Add energy level context
        energy_level = hormonal_context.get("energy_level")
        if energy_level is not None:
            if energy_level <= 3:
                prompts.append(
                    "User reported LOW ENERGY today. Suggest lighter workouts, "
                    "shorter duration, or active recovery."
                )
            elif energy_level >= 8:
                prompts.append(
                    "User reported HIGH ENERGY today. They may be ready for a "
                    "challenging workout or PR attempt."
                )

        # Add kegel context if enabled
        if hormonal_context.get("kegels_enabled"):
            kegel_placement = []
            if hormonal_context.get("include_kegels_in_warmup"):
                kegel_placement.append("warmup")
            if hormonal_context.get("include_kegels_in_cooldown"):
                kegel_placement.append("cooldown")

            if kegel_placement:
                prompts.append(
                    f"User has pelvic floor exercises (kegels) enabled. "
                    f"Include them in: {', '.join(kegel_placement)}. "
                    f"Level: {hormonal_context.get('kegel_current_level', 'beginner')}."
                )

        # Add food context if enabled
        if include_food_recommendations and hormonal_context.get("hormonal_diet_enabled"):
            prompts.append(
                "User has hormone-supportive nutrition enabled. "
                "Include relevant food recommendations based on their hormonal goals."
            )

        return "\n\n".join(prompts) if prompts else ""

    @staticmethod
    def get_hormonal_food_prompt(
        hormone_goals: List[str],
        cycle_phase: Optional[str] = None,
        dietary_restrictions: Optional[List[str]] = None
    ) -> str:
        """
        Get AI prompt for hormone-supportive food recommendations.

        Args:
            hormone_goals: List of hormone optimization goals
            cycle_phase: Current menstrual cycle phase (if tracking)
            dietary_restrictions: User's dietary restrictions

        Returns:
            Formatted prompt for food recommendations
        """
        prompt_parts = [
            "Suggest hormone-supportive foods based on the following context:",
            ""
        ]

        if hormone_goals:
            prompt_parts.append(f"Hormone Goals: {', '.join(hormone_goals)}")

        if cycle_phase:
            prompt_parts.append(f"Current Cycle Phase: {cycle_phase}")

        if dietary_restrictions:
            prompt_parts.append(f"Dietary Restrictions: {', '.join(dietary_restrictions)}")

        prompt_parts.extend([
            "",
            "Provide specific food recommendations that:",
            "1. Support the user's hormone optimization goals",
            "2. Are appropriate for their current cycle phase (if applicable)",
            "3. Respect their dietary restrictions",
            "4. Include practical meal and snack ideas",
            "5. Explain WHY each food supports their hormonal health"
        ])

        return "\n".join(prompt_parts)

    @staticmethod
    def get_kegel_coaching_prompt(
        level: str = "beginner",
        focus_area: str = "general"
    ) -> str:
        """Get coaching prompt for kegel/pelvic floor exercises."""
        focus_descriptions = {
            "general": "balanced pelvic floor strengthening",
            "male_specific": "male pelvic floor anatomy, prostate support, and urinary control",
            "female_specific": "female pelvic floor anatomy, vaginal health, and bladder control",
            "postpartum": "gentle postpartum pelvic floor recovery",
            "prostate_health": "prostate health and urinary function support"
        }

        return f"""When discussing pelvic floor exercises with this user:
- Their current level is: {level}
- Their focus area is: {focus_descriptions.get(focus_area, focus_area)}

Key coaching points for {level} level:
{'- Start with basic holds (5-10 seconds)' if level == 'beginner' else ''}
{'- Focus on mind-muscle connection' if level == 'beginner' else ''}
{'- Progress to longer holds and more reps' if level == 'intermediate' else ''}
{'- Include quick flick exercises' if level == 'intermediate' else ''}
{'- Advanced holds with functional integration' if level == 'advanced' else ''}
{'- Combine with breath work and core exercises' if level == 'advanced' else ''}

Be encouraging and normalize pelvic floor health as an important part of overall fitness."""

