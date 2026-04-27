"""Second part of prompts_helpers.py (auto-split for size)."""
from typing import Any


class PromptsMixinPart2:
    """Second half of PromptsMixin methods. Use as mixin."""

    def _form_biomechanics(self) -> str:
        """General biomechanics principles for form analysis (~3K tokens)."""
        return """
## GENERAL BIOMECHANICS PRINCIPLES

### Joint Stacking and Alignment
- Joints should be "stacked" — aligned vertically under load when possible. For example, in a squat, the knees should track over the toes, and the bar should remain over the midfoot.
- Misalignment increases the moment arm (distance between the load and the joint axis), which increases the force the muscles and connective tissues must produce, raising injury risk.
- In pressing movements, the wrist should stack over the elbow, which should stack over the shoulder at the bottom of the movement.

### Neutral Spine Principle
- The spine has three natural curves: cervical lordosis (neck), thoracic kyphosis (upper back), and lumbar lordosis (lower back). "Neutral spine" means maintaining these natural curves under load.
- Any deviation from neutral under load (rounding, hyperextension) creates shear forces on the intervertebral discs that increase exponentially with the deviation angle.
- The Valsalva maneuver (deep breath, braced core) increases intra-abdominal pressure, which supports the spine like an internal weightlifting belt. Use for heavy compound lifts (squats, deadlifts, overhead press).
- The erector spinae muscles run along the spine and must contract isometrically to maintain neutral position. If these muscles fatigue, the spine will round under load — this is a signal to stop the set.

### Force Vectors and Muscle Activation
- Muscles generate force along their line of pull. Changing body angle changes which muscles are emphasized.
- Incline bench: Upper chest (clavicular pectorals) because the force vector is more aligned with that fiber direction.
- Decline bench: Lower chest (sternal pectorals) for the same reason.
- Different grip widths change the relative contribution of muscles. Narrow grip bench = more triceps; wide grip = more chest.
- Cable angle changes determine which part of a movement is hardest. Low cable = hardest at top; high cable = hardest at bottom.

### Range of Motion (ROM) Principles
- Full range of motion provides the greatest stimulus for muscle growth and strength.
- "Partial reps" are appropriate for: overloading a specific portion of the movement, working around an injury, or advanced intensity techniques (not for avoiding difficulty).
- Passive flexibility (how far a joint can move) vs. active flexibility (how far you can control the movement). Training should stay within active flexibility.
- At the end range, connective tissues (tendons, ligaments, joint capsule) bear more of the load. This is where injuries occur most frequently. Control at end range is essential.

### Bilateral Symmetry
- The human body should produce roughly equal force on both sides. Asymmetries greater than 10-15% between left and right indicate an imbalance that should be addressed.
- Common causes: dominant side preference, previous injury, habitual posture, occupational patterns.
- Assessment: watch for uneven bar tilt, hip shift in squats, one shoulder rising faster in bench press, one arm extending faster in overhead press.
- Correction: unilateral training (dumbbell work, single-leg exercises), mobility work on the restricted side.

### Eccentric vs. Concentric Control
- Eccentric (lowering) phase should ALWAYS be controlled. It provides the greatest stimulus for muscle growth and the greatest risk for injury when uncontrolled.
- Concentric (lifting) phase can be explosive for power training or controlled for time-under-tension.
- The eccentric phase should generally be 2-4 seconds for most exercises.
- "Dropping" the weight (uncontrolled eccentric) is the single most common cause of acute training injuries.

### Breathing and Intra-Abdominal Pressure
- For heavy compound lifts (squat, deadlift, overhead press): Valsalva maneuver — deep breath into the belly (not chest), brace the core in all directions (360-degree brace), hold through the most difficult portion, exhale after the sticking point.
- For moderate compound lifts: Exhale during the concentric (exertion) phase, inhale during the eccentric (lowering) phase.
- For isolation exercises: Steady, rhythmic breathing. Do not hold breath for extended sets.
- The diaphragm is a core muscle. Proper breathing mechanics contribute to core stability and spinal protection.

### Progressive Overload Principle
- Form should be evaluated in the context of the load. Perfect form at light weight is expected. Form at near-maximal weight may show acceptable deviations.
- Critical safety issues (rounded lower back, knee valgus under heavy load) are NEVER acceptable regardless of the load.
- Minor deviations (slight elbow flare, minor bar path deviation, slightly less depth) may be acceptable at heavy loads for experienced lifters but should be noted.

### Warming Up and Movement Preparation
- Cold muscles and connective tissues are less elastic and more prone to injury.
- General warm-up: 5-10 minutes of light cardio to increase core body temperature.
- Specific warm-up: 2-3 progressively heavier warm-up sets of the exercise before working weight.
- Dynamic stretching (movement-based) before training. Static stretching (held) after training.
- Warm-up sets also serve as a form check — if form deteriorates during warm-ups, the working weight should be reconsidered.

"""

    def _form_video_methodology(self) -> str:
        """Video analysis methodology and rep counting guide (~2K tokens)."""
        return """
## VIDEO ANALYSIS METHODOLOGY

### Frame-by-Frame Analysis Protocol
1. **First Pass — Overview**: Watch the entire video once to identify the exercise, count approximate reps, and note the general quality of movement.
2. **Second Pass — Detail**: Focus on specific body parts and joint angles. Pause at critical points (bottom of squat, lockout of press, etc.) to assess alignment.
3. **Third Pass — Consistency**: Check if form remains consistent across all reps or deteriorates (fatigue pattern).

### Camera Angle Considerations
- **Side View (Sagittal)**: Best for assessing depth, bar path, spinal alignment, hip hinge pattern, knee tracking (forward/back). Ideal for squats, deadlifts, bench press, overhead press.
- **Front View (Frontal)**: Best for assessing knee valgus/varus, shoulder symmetry, bilateral balance, foot placement. Ideal for squats, lunges, deadlifts, overhead press.
- **Rear View (Posterior)**: Best for assessing scapular movement, hip shift, foot alignment. Ideal for deadlifts, squats, rows.
- **Overhead/Diagonal**: Good for assessing bar path in pressing movements, overall movement pattern.
- When the camera angle limits analysis of certain aspects, note this in the video_quality assessment and lower confidence appropriately.

### Rep Counting Methodology
- A repetition is defined as ONE COMPLETE MOVEMENT CYCLE: from the starting position through the full range of motion and back to the starting position.
- Count reps by identifying the consistent phase (e.g., for squats: count each time the person stands back up to full extension).
- If the video starts mid-rep, count that first rep only if at least 50% of the range of motion is visible.
- If the video ends mid-rep, count that last rep only if at least 50% of the range of motion was completed.
- For isometric holds (planks): count as 1 "rep" and estimate the duration.
- Be precise. Double-check by counting the number of complete descent-ascent cycles. If unsure, err on the lower count and note the uncertainty.
- Common counting errors: confusing the setup/unracking with a rep, counting the reracking as a rep, counting partial bounces as reps.

### Confidence Assessment
- **High Confidence**: Clear video, good angle showing the key body parts, well-lit, minimal obstruction. Full exercise visible from start to finish.
- **Medium Confidence**: Acceptable video but with some limitations — partial view, moderate distance, some key body parts occasionally obscured. Analysis is likely accurate but some aspects are estimated.
- **Low Confidence**: Poor video quality, bad angle, key body parts not visible, very short clip, dark/blurry footage. Analysis is best-effort but may be inaccurate. Should recommend re-recording.

### Factors That Reduce Confidence
- Dark/poorly lit environment
- Camera too far from the subject
- Camera placed at a non-ideal angle (e.g., overhead for a deadlift)
- Other people/objects obstructing the view
- Very short clip (fewer than 3 reps makes pattern analysis unreliable)
- Shaky camera/motion blur
- Subject wearing very loose clothing that obscures joint positions
- Low video resolution

### Re-Recording Suggestions
When video quality limits analysis, provide a gentle, constructive suggestion for next time:
- Suggest a better camera angle for the specific exercise
- Recommend adequate lighting
- Suggest proper distance (full body should be visible)
- Keep it brief and friendly — one sentence maximum
- Only suggest once, not repeatedly

### Fatigue Detection
As a set progresses, watch for:
- Decreasing range of motion (shallower reps)
- Increasing compensatory movements (more body English, hip shift)
- Slower concentric speed
- Bar path deviation
- Loss of core bracing
Note which rep number the form begins to deteriorate — this is valuable feedback for the user about their true working capacity at that weight.

"""

    def _build_nutrition_analysis_cache_system_instruction(self) -> str:
        """Build the system instruction for nutrition analysis cache."""
        return """You are Zealova AI Nutritionist, an expert registered dietitian, certified sports nutritionist, and food science specialist. You analyze food images and text descriptions to provide accurate, detailed nutrition estimates.

## YOUR ROLE
- Identify all food items visible in images or described in text
- Estimate portion sizes using visual comparison references
- Calculate macronutrient breakdown (calories, protein, carbs, fat, fiber)
- Classify foods using the traffic-light system (green/yellow/red)
- Provide coaching feedback on meal quality
- Support multiple analysis modes (plate, buffet, menu)
- Account for cultural cuisines and regional food variations

## ANALYSIS MODES
1. **Plate Mode**: Single plate/bowl of food. Focus on identifying individual items, estimating portions, and providing per-item and total nutrition.
2. **Buffet Mode**: Multiple dishes visible (e.g., buffet, family-style dining, spread). Identify each dish and estimate what a typical serving would contain.
3. **Menu Mode**: Photo of a restaurant menu. Analyze the menu items and provide nutrition estimates based on standard restaurant portions.

## ACCURACY STANDARDS
- Calorie estimates should be within +/- 20% of actual values for identifiable foods
- Protein estimates should be within +/- 5g for a standard serving
- When uncertain about a food item, provide a reasonable estimate and note the uncertainty
- NEVER refuse to estimate — always provide your best assessment

## PORTION SIZE ESTIMATION
Use visual anchors for estimation:
- Fist = ~1 cup
- Palm = ~3-4 oz of protein
- Thumb = ~1 tablespoon
- Fingertip = ~1 teaspoon
- Deck of cards = ~3 oz meat
- Tennis ball = ~1/2 cup

## OUTPUT FORMAT
Always return valid JSON matching the exact schema provided. No markdown, no explanations outside JSON.

## HEALTH SCORE RUBRIC
Score meals on a 1-10 scale:
- 9-10: Excellent balance of macros, whole foods, adequate protein, high fiber
- 7-8: Good meal with minor improvements possible (slightly low on veggies, or could use more protein)
- 5-6: Average meal, some processed items, imbalanced macros
- 3-4: Poor meal quality, mostly processed, low protein, high sugar/fat
- 1-2: Very poor, essentially junk food, no nutritional value

## INFLAMMATION SCORE RUBRIC
Every food_item AND the meal as a whole must emit inflammation_score (1-10, higher = more inflammatory):
- 1-2: Strongly anti-inflammatory — wild salmon, turmeric, berries, leafy greens, ginger tea, extra-virgin olive oil
- 3-4: Mildly anti-inflammatory — most vegetables, whole grains, nuts, legumes, plain yogurt, eggs from pasture-raised hens
- 5: Neutral — plain rice, plain chicken breast, milk, plain pasta
- 6-7: Mildly inflammatory — white bread, red meat, full-fat cheese, pan-fried foods, butter
- 8-9: Moderately inflammatory — processed meats (bacon, sausage, salami), fast food, sugary drinks, packaged snacks, instant noodles
- 10: Highly inflammatory — deep-fried ultra-processed combos, items with trans fats, candy + soda meals
Meal-level inflammation_score = calorie-weighted average of per-item scores, rounded to the nearest integer.

## ULTRA-PROCESSED (is_ultra_processed) RUBRIC
Emit is_ultra_processed (boolean) for every food_item AND the meal as a whole.
- true = the food would be NOVA Group 4. Hallmarks: industrial emulsifiers, hydrogenated or interesterified oils, artificial sweeteners, protein isolates, modified starches, high-fructose corn syrup, flavor enhancers beyond standard herbs/spices.
- Examples true: Coca-Cola, instant ramen, packaged white bread, hot-dog buns, cheese puffs, most breakfast cereals, protein bars with >5 ingredients ending in "-ose" or "-ate".
- Examples false: grilled chicken, steamed rice, homemade samosa, plain Greek yogurt, raw vegetables, whole-milk cheese, home-cooked curry.
Meal-level is_ultra_processed = true when ultra-processed items dominate the meal's calories."""

    def _build_nutrition_analysis_cache_content(self) -> str:
        """
        Build the static content for nutrition analysis cache.
        Targets ~35K tokens (~140K chars) with food database and guidelines.
        """
        return self._nutrition_mode_templates() + self._nutrition_portion_rules() + self._nutrition_traffic_light() + self._nutrition_usda_reference() + self._nutrition_cultural_reference()

    def _nutrition_mode_templates(self) -> str:
        """Analysis mode templates (~2K tokens)."""
        return """
## ANALYSIS MODE TEMPLATES

### PLATE MODE (Single Plate/Bowl)
When analyzing a single plate or bowl:
1. Scan the entire image to identify all visible food items
2. Estimate the plate size (standard dinner plate is ~10-11 inches / 25-28 cm)
3. Estimate each food item's portion relative to the plate size
4. Calculate per-item nutrition from the USDA reference data
5. Sum totals for the complete meal
6. Assess the meal balance: protein source present? vegetables? complex carbs?
7. Check the protein-to-calorie ratio (aim for > 30g protein per 500 calories for fitness goals)

Expected output structure:
- Individual food items with amounts and per-item nutrition
- Total meal nutrition (calories, protein, carbs, fat, fiber)
- Health score (1-10)
- Brief coaching feedback

### BUFFET MODE (Multiple Dishes)
When analyzing multiple dishes or a spread:
1. Identify each distinct dish visible in the image
2. For each dish, estimate what a single serving would contain
3. If the user indicates what they ate, use that; otherwise, estimate a reasonable single-person plate from the spread
4. Flag dishes that are particularly calorie-dense or nutritious
5. Suggest an optimal plate composition from the available options

Expected output structure:
- Each dish identified with estimated single-serving nutrition
- Suggested plate composition for fitness goals
- Total estimated meal nutrition based on reasonable portions
- Health score and coaching feedback

### MENU MODE (Restaurant Menu Photo)
When analyzing a menu:
1. Read all menu items visible in the photo
2. Categorize items (appetizers, mains, sides, desserts, drinks)
3. Estimate nutrition for each item based on standard restaurant portions (restaurants typically serve 1.5-2x home portions)
4. Flag the best options for fitness goals (high protein, balanced macros)
5. Flag items to avoid or limit (high calorie, low nutrition density)
6. Suggest modifications that would improve nutrition (dressing on side, grilled instead of fried, etc.)

Expected output structure:
- Per-item nutrition estimates
- "Best choices" and "items to limit" sections
- Suggested modifications
- Overall restaurant strategy tips

"""

    def _nutrition_portion_rules(self) -> str:
        """Portion estimation rules with visual size comparisons (~3K tokens)."""
        return """
## PORTION ESTIMATION REFERENCE GUIDE

### Visual Anchors for Portion Estimation

| Visual Reference | Equivalent | Weight/Volume | Example Foods |
|-----------------|------------|---------------|---------------|
| Closed fist | 1 cup / 240 ml | ~240g for liquids | Rice, pasta, cereal, soup |
| Open palm (no fingers) | 3-4 oz / 85-115g | ~100g for protein | Chicken breast, fish fillet, steak |
| Cupped hand | 1/2 cup / 120 ml | ~120g | Nuts, trail mix, dried fruit, grains |
| Thumb (tip to base) | 1 tablespoon / 15 ml | ~15g | Peanut butter, oil, butter, dressings |
| Thumb tip (first joint) | 1 teaspoon / 5 ml | ~5g | Oil drizzle, sugar, salt |
| Two fingers together | 1 oz / 28g | ~28g | Cheese slice |
| Deck of cards | 3 oz / 85g | ~85g | Meat portion |
| Tennis ball | 1/2 cup / 120 ml | ~120g | Fruit, ice cream scoop |
| Baseball | 1 cup / 240 ml | ~180g for solid foods | Cereal, chopped vegetables |
| Golf ball | 2 tablespoons / 30 ml | ~30g | Nut butter, hummus, salad dressing |
| Computer mouse | ~4 oz / 115g | ~115g | Baked potato, chicken breast |
| Checkbook | ~3 oz / 85g | ~85g | Fish fillet |
| Hockey puck | ~3 oz / 85g | ~85g | Hamburger patty |
| Dice (single) | ~1 teaspoon / 5 ml | ~5g | Butter pat |
| Smartphone | ~8 oz / 225g | ~225g | Steak |

### Plate Proportion Method
For a standard 10-11 inch dinner plate:
- **1/2 plate**: Vegetables (~2 cups) — approximately 50-100 calories
- **1/4 plate**: Protein (~4-6 oz) — approximately 150-250 calories
- **1/4 plate**: Complex carbs (~1 cup) — approximately 150-250 calories
- Total balanced plate: approximately 350-600 calories

### Common Serving Size Adjustments
- **Restaurant portions** are typically 1.5-2x standard portions. A restaurant pasta dish may be 2-3 cups rather than the standard 1 cup serving.
- **Fast food** portions have standardized sizes: small, medium, large. Use chain-specific data when identifiable.
- **Home cooking** portions vary widely. Estimate based on visible plate coverage and food height/depth.
- **Liquid calories** are frequently underestimated. A standard glass of juice is ~8 oz (100-140 cal), but glasses at restaurants may be 12-16 oz.
- **Sauces and dressings** are frequently underestimated. Most restaurant sauces add 100-300 calories to a dish. Estimate based on visible coverage.
- **Fried vs. grilled** cooking method adds approximately 50-100% more calories to an equivalent portion of protein.
- **Bread and chips** basket calories: estimate per piece/chip. One restaurant breadstick is ~150 cal; one tortilla chip is ~13 cal.

### Density and Weight Estimation
- **Leafy greens**: Very low density. A large salad bowl (3 cups) may weigh only 100g and contain 20-30 calories before dressing.
- **Rice and grains**: High density. A seemingly small amount can weigh 200-300g and contain 300-400 calories.
- **Cheese**: Very high calorie density. A thin slice (~28g) contains 100-110 calories.
- **Nuts**: Extremely calorie-dense. A small handful (~28g / 1 oz) contains 160-200 calories.
- **Oils and butter**: Maximum calorie density at ~120 cal per tablespoon. Even a light drizzle can add 50-100 calories.
- **Fruit**: Moderate density. A medium apple is ~95 cal, a medium banana is ~105 cal.
- **Cooked vegetables**: Low to moderate density. 1 cup cooked broccoli is ~55 cal, 1 cup cooked sweet potato is ~180 cal.

### Confidence Indicators for Portion Estimation
- **High confidence**: Food is on a plate with recognizable size reference (dinnerware, utensils), clearly identifiable items, unobstructed view.
- **Medium confidence**: Food is identifiable but portion is estimated (e.g., wrapped items, mixed dishes, partially obscured). Estimate may vary +/- 30%.
- **Low confidence**: Food type is uncertain, or portion cannot be reliably estimated (e.g., food in opaque container, very unfamiliar dish, extreme camera angle).

"""

    def _nutrition_traffic_light(self) -> str:
        """Traffic-light classification criteria (~2K tokens)."""
        return """
## TRAFFIC-LIGHT FOOD CLASSIFICATION SYSTEM

### GREEN (Eat Freely / Excellent Choices)
Foods that are nutrient-dense, support fitness goals, and can be consumed regularly without concern.

**Criteria** (meet at least 2):
- Calorie density < 1.5 cal/gram
- Protein content > 20% of calories
- Fiber content > 3g per serving
- Minimal processing (whole food or minimally processed)
- Rich in micronutrients (vitamins, minerals)

**Examples**:
- **Vegetables**: Broccoli, spinach, kale, bell peppers, tomatoes, carrots, zucchini, asparagus, Brussels sprouts, cauliflower, green beans, cucumber, celery, mushrooms, onions, sweet potatoes
- **Fruits**: Berries (strawberries, blueberries, raspberries), apples, oranges, kiwi, grapefruit, watermelon
- **Lean Proteins**: Chicken breast, turkey breast, white fish (cod, tilapia, halibut), shrimp, egg whites, Greek yogurt (plain), cottage cheese (low-fat), tofu
- **Whole Grains**: Oats, quinoa, brown rice, whole wheat bread (minimally processed), barley
- **Legumes**: Lentils, chickpeas, black beans, kidney beans, edamame
- **Healthy Fats (small portions)**: Avocado, almonds, walnuts, olive oil (measured)

### YELLOW (Moderate / Eat in Controlled Portions)
Foods that provide nutrition but also have higher calorie density, some processing, or less optimal macronutrient ratios. Fine in controlled portions.

**Criteria** (meet at least 1):
- Calorie density 1.5-4.0 cal/gram
- Moderate processing
- Higher fat content but from natural sources
- Contains added sugars but also provides nutrients
- High in healthy fats but calorie-dense

**Examples**:
- **Proteins**: Whole eggs, salmon, beef (lean cuts like sirloin), pork loin, chicken thighs (skin-on), cheese (in moderation), whole milk
- **Carbs**: White rice, pasta, bread (refined), potatoes (not fried), cereal (lower sugar varieties), granola, dried fruit, honey, maple syrup (small amounts)
- **Fats**: Nut butters, seeds, coconut, dark chocolate (70%+), full-fat dairy
- **Mixed Dishes**: Homemade stir-fry, soups with some cream, sandwiches, wraps, sushi rolls
- **Drinks**: Smoothies (watch portions), milk (whole), 100% fruit juice (small portions)

### RED (Limit / Occasional Treats)
Foods that are calorie-dense with low nutritional value, highly processed, or have very unfavorable macronutrient ratios. Not "forbidden" — just not ideal for regular consumption in a fitness-oriented diet.

**Criteria** (meet at least 1):
- Calorie density > 4.0 cal/gram
- Highly processed with many additives
- High in added sugars (> 25% of calories from sugar)
- High in trans fats or excessive saturated fat
- Very low protein and fiber relative to calories
- Deep-fried

**Examples**:
- **Fried Foods**: French fries, fried chicken, onion rings, mozzarella sticks, tempura, samosas
- **Sweets**: Candy, cookies, cake, donuts, pastries, ice cream (premium), chocolate bars (milk/white)
- **Processed Snacks**: Chips, crackers, pretzels (large portions), microwave popcorn (buttered)
- **Fast Food**: Burgers with extra cheese/bacon, large pizza slices, loaded nachos, hot dogs
- **Sugary Drinks**: Regular soda, energy drinks (sugared), frappuccinos, milkshakes, sweetened iced tea
- **Processed Meats**: Bacon, sausage, hot dogs, salami, pepperoni (high in sodium and saturated fat)
- **Sauces**: Ranch dressing, alfredo sauce, mayo-based sauces, BBQ sauce (high sugar)

### Classification Rules for Mixed Dishes
1. Classify based on the PRIMARY component and cooking method
2. A grilled chicken salad with dressing on the side = GREEN
3. A Caesar salad with croutons, cheese, and heavy dressing = YELLOW
4. A fried chicken salad with ranch = RED
5. When in doubt, consider: "Would a sports nutritionist recommend this to an athlete?"

"""

    def _nutrition_usda_reference(self) -> str:
        """USDA reference: top 200 common foods (~20K tokens)."""
        return """
## USDA FOOD NUTRITION REFERENCE DATABASE
### Per Standard Serving Size (calories / protein_g / carbs_g / fat_g / fiber_g)

### PROTEINS — Poultry

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Chicken breast, grilled, skinless | 4 oz (113g) | 187 | 35.2 | 0 | 4.1 | 0 |
| Chicken breast, fried | 4 oz (113g) | 252 | 30.8 | 7.2 | 10.5 | 0.3 |
| Chicken thigh, skin-on, roasted | 4 oz (113g) | 232 | 26.2 | 0 | 13.4 | 0 |
| Chicken thigh, skinless, grilled | 4 oz (113g) | 198 | 28.8 | 0 | 8.6 | 0 |
| Chicken wing, fried (3 wings) | 3 wings (96g) | 286 | 22.5 | 8.2 | 18.1 | 0.2 |
| Chicken drumstick, roasted | 2 drumsticks (132g) | 234 | 30.4 | 0 | 11.6 | 0 |
| Chicken tenders, breaded, fried | 4 pieces (128g) | 340 | 24.0 | 18.0 | 19.0 | 1.0 |
| Turkey breast, roasted | 4 oz (113g) | 153 | 34.0 | 0 | 0.8 | 0 |
| Turkey, ground, 93% lean | 4 oz (113g) | 170 | 22.0 | 0 | 8.5 | 0 |
| Turkey, dark meat, roasted | 4 oz (113g) | 212 | 30.5 | 0 | 9.2 | 0 |
| Duck breast, skin-on, roasted | 4 oz (113g) | 228 | 26.5 | 0 | 13.0 | 0 |
| Cornish hen, roasted | 1/2 hen (145g) | 295 | 32.0 | 0 | 18.0 | 0 |

### PROTEINS — Beef

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Beef, sirloin steak, grilled | 6 oz (170g) | 312 | 46.8 | 0 | 12.2 | 0 |
| Beef, ribeye steak, grilled | 6 oz (170g) | 396 | 40.8 | 0 | 24.6 | 0 |
| Beef, filet mignon, grilled | 6 oz (170g) | 348 | 48.0 | 0 | 16.2 | 0 |
| Beef, NY strip steak, grilled | 6 oz (170g) | 360 | 44.4 | 0 | 19.2 | 0 |
| Beef, ground 90% lean, cooked | 4 oz (113g) | 196 | 26.8 | 0 | 9.2 | 0 |
| Beef, ground 80% lean, cooked | 4 oz (113g) | 246 | 24.4 | 0 | 15.6 | 0 |
| Beef, ground 73% lean, cooked | 4 oz (113g) | 280 | 22.0 | 0 | 20.8 | 0 |
| Beef, chuck roast, braised | 4 oz (113g) | 264 | 32.4 | 0 | 13.8 | 0 |
| Beef, brisket, smoked | 4 oz (113g) | 288 | 28.0 | 0 | 18.8 | 0 |
| Beef, flank steak, grilled | 4 oz (113g) | 200 | 32.0 | 0 | 7.2 | 0 |
| Beef, short ribs, braised | 4 oz (113g) | 340 | 26.4 | 0 | 25.2 | 0 |
| Beef jerky | 1 oz (28g) | 116 | 9.4 | 3.1 | 7.3 | 0.5 |
| Beef liver, pan-fried | 4 oz (113g) | 196 | 29.0 | 5.4 | 5.3 | 0 |
| Corned beef | 4 oz (113g) | 240 | 20.0 | 0.5 | 17.0 | 0 |

### PROTEINS — Pork

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Pork loin, roasted | 4 oz (113g) | 194 | 30.4 | 0 | 7.4 | 0 |
| Pork tenderloin, grilled | 4 oz (113g) | 165 | 30.0 | 0 | 4.2 | 0 |
| Pork chop, bone-in, grilled | 4 oz (113g) | 210 | 28.0 | 0 | 10.0 | 0 |
| Bacon, cooked | 3 slices (24g) | 129 | 9.0 | 0.4 | 10.0 | 0 |
| Ham, deli sliced | 3 oz (85g) | 90 | 14.0 | 2.0 | 2.5 | 0 |
| Pork sausage, cooked | 2 links (56g) | 192 | 8.4 | 1.2 | 17.0 | 0 |
| Pulled pork, smoked | 4 oz (113g) | 240 | 26.0 | 4.0 | 13.0 | 0 |
| Pork belly, roasted | 4 oz (113g) | 420 | 16.0 | 0 | 40.0 | 0 |
| Pork ribs, BBQ | 4 oz (113g) | 320 | 24.0 | 8.0 | 22.0 | 0 |

### PROTEINS — Seafood

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Salmon, Atlantic, baked | 4 oz (113g) | 234 | 25.0 | 0 | 14.4 | 0 |
| Salmon, smoked (lox) | 3 oz (85g) | 100 | 15.5 | 0 | 3.7 | 0 |
| Tuna, yellowfin, grilled | 4 oz (113g) | 150 | 34.0 | 0 | 0.8 | 0 |
| Tuna, canned in water | 1 can (142g) | 179 | 39.3 | 0 | 1.4 | 0 |
| Tuna, canned in oil | 1 can (142g) | 290 | 36.0 | 0 | 15.4 | 0 |
| Cod, baked | 4 oz (113g) | 104 | 23.0 | 0 | 0.9 | 0 |
| Tilapia, baked | 4 oz (113g) | 145 | 30.0 | 0 | 2.5 | 0 |
| Shrimp, grilled | 4 oz (113g) | 120 | 24.0 | 1.0 | 1.8 | 0 |
| Shrimp, fried (breaded) | 6 pieces (100g) | 242 | 14.0 | 18.0 | 12.0 | 0.8 |
| Halibut, baked | 4 oz (113g) | 140 | 28.0 | 0 | 2.8 | 0 |
| Mahi mahi, grilled | 4 oz (113g) | 124 | 26.8 | 0 | 1.2 | 0 |
| Swordfish, grilled | 4 oz (113g) | 174 | 28.4 | 0 | 5.8 | 0 |
| Sea bass, baked | 4 oz (113g) | 140 | 26.0 | 0 | 3.0 | 0 |
| Catfish, fried | 4 oz (113g) | 252 | 18.0 | 10.0 | 15.0 | 0.5 |
| Crab meat, lump | 4 oz (113g) | 97 | 21.0 | 0 | 0.6 | 0 |
| Lobster tail, steamed | 4 oz (113g) | 112 | 24.0 | 0 | 0.8 | 0 |
| Scallops, seared | 4 oz (113g) | 112 | 20.0 | 4.8 | 0.8 | 0 |
| Clams, steamed | 4 oz (113g) | 126 | 22.0 | 4.4 | 1.6 | 0 |
| Oysters, raw | 6 medium (84g) | 57 | 5.9 | 3.3 | 2.1 | 0 |
| Sardines, canned in oil | 1 can (92g) | 191 | 22.6 | 0 | 10.5 | 0 |
| Anchovies, canned | 5 fillets (20g) | 42 | 5.8 | 0 | 1.9 | 0 |
| Calamari, fried | 4 oz (113g) | 232 | 14.0 | 14.0 | 13.0 | 0.5 |

### PROTEINS — Eggs & Dairy

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Egg, whole, large | 1 large (50g) | 72 | 6.3 | 0.4 | 4.8 | 0 |
| Egg whites | 3 large whites (99g) | 51 | 10.8 | 0.7 | 0.2 | 0 |
| Greek yogurt, plain, nonfat | 1 cup (245g) | 130 | 22.0 | 9.0 | 0.7 | 0 |
| Greek yogurt, plain, whole | 1 cup (245g) | 220 | 20.0 | 9.0 | 11.0 | 0 |
| Greek yogurt, flavored | 1 cup (245g) | 240 | 18.0 | 32.0 | 4.5 | 0 |
| Cottage cheese, low-fat (2%) | 1 cup (226g) | 183 | 24.0 | 9.5 | 5.0 | 0 |
| Cottage cheese, whole | 1 cup (226g) | 222 | 25.0 | 8.0 | 10.0 | 0 |
| Milk, whole | 1 cup (244ml) | 149 | 8.0 | 12.0 | 8.0 | 0 |
| Milk, 2% | 1 cup (244ml) | 122 | 8.1 | 11.7 | 4.8 | 0 |
| Milk, skim | 1 cup (244ml) | 83 | 8.3 | 12.2 | 0.2 | 0 |
| Cheddar cheese | 1 oz (28g) | 113 | 7.0 | 0.4 | 9.3 | 0 |
| Mozzarella cheese | 1 oz (28g) | 85 | 6.3 | 0.7 | 6.3 | 0 |
| Parmesan cheese, grated | 2 tbsp (10g) | 42 | 3.8 | 0.4 | 2.8 | 0 |
| Swiss cheese | 1 oz (28g) | 108 | 7.6 | 1.5 | 7.9 | 0 |
| Cream cheese | 2 tbsp (29g) | 99 | 1.7 | 1.6 | 9.8 | 0 |
| Ricotta cheese, part-skim | 1/4 cup (62g) | 86 | 7.0 | 3.2 | 5.0 | 0 |
| Butter | 1 tbsp (14g) | 102 | 0.1 | 0 | 11.5 | 0 |
| Sour cream | 2 tbsp (30g) | 60 | 0.7 | 1.0 | 5.8 | 0 |
| Whey protein powder | 1 scoop (30g) | 120 | 24.0 | 3.0 | 1.5 | 0 |
| Casein protein powder | 1 scoop (33g) | 120 | 24.0 | 4.0 | 1.0 | 0 |

### PROTEINS — Plant-Based

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Tofu, firm | 1/2 block (126g) | 111 | 12.0 | 2.4 | 6.0 | 0.5 |
| Tofu, silken | 1/2 block (126g) | 68 | 6.0 | 3.4 | 3.2 | 0 |
| Tempeh | 4 oz (113g) | 222 | 20.8 | 7.6 | 12.8 | 5.2 |
| Seitan | 4 oz (113g) | 140 | 28.0 | 4.0 | 1.0 | 0.5 |
| Edamame, shelled | 1 cup (155g) | 188 | 18.5 | 13.8 | 8.1 | 8.0 |
| Black beans, cooked | 1 cup (172g) | 227 | 15.2 | 40.8 | 0.9 | 15.0 |
| Chickpeas (garbanzo), cooked | 1 cup (164g) | 269 | 14.5 | 45.0 | 4.2 | 12.5 |
| Lentils, cooked | 1 cup (198g) | 230 | 17.9 | 39.9 | 0.8 | 15.6 |
| Kidney beans, cooked | 1 cup (177g) | 225 | 15.3 | 40.4 | 0.9 | 11.3 |
| Pinto beans, cooked | 1 cup (171g) | 245 | 15.4 | 44.8 | 1.1 | 15.4 |
| Navy beans, cooked | 1 cup (182g) | 255 | 15.0 | 47.4 | 1.1 | 19.1 |
| Black-eyed peas, cooked | 1 cup (171g) | 198 | 13.2 | 35.7 | 0.9 | 11.2 |
| Split peas, cooked | 1 cup (196g) | 231 | 16.4 | 41.4 | 0.8 | 16.3 |
| Beyond Burger (plant-based) | 1 patty (113g) | 250 | 20.0 | 5.0 | 18.0 | 3.0 |
| Impossible Burger (plant-based) | 1 patty (113g) | 240 | 19.0 | 9.0 | 14.0 | 3.0 |

### GRAINS & STARCHES

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| White rice, cooked | 1 cup (186g) | 206 | 4.3 | 44.5 | 0.4 | 0.6 |
| Brown rice, cooked | 1 cup (195g) | 216 | 5.0 | 44.8 | 1.8 | 3.5 |
| Jasmine rice, cooked | 1 cup (186g) | 205 | 4.2 | 45.0 | 0.4 | 0.6 |
| Basmati rice, cooked | 1 cup (186g) | 210 | 4.4 | 45.6 | 0.5 | 0.6 |
| Quinoa, cooked | 1 cup (185g) | 222 | 8.1 | 39.4 | 3.6 | 5.2 |
| Oatmeal, cooked | 1 cup (234g) | 154 | 5.4 | 27.4 | 2.6 | 4.0 |
| Oats, dry (rolled) | 1/2 cup (40g) | 150 | 5.0 | 27.0 | 2.5 | 4.0 |
| Pasta, cooked (spaghetti) | 1 cup (140g) | 220 | 8.1 | 43.2 | 1.3 | 2.5 |
| Pasta, whole wheat, cooked | 1 cup (140g) | 174 | 7.5 | 37.2 | 0.8 | 6.3 |
| Bread, white | 1 slice (25g) | 66 | 1.9 | 12.7 | 0.8 | 0.6 |
| Bread, whole wheat | 1 slice (28g) | 69 | 3.6 | 11.6 | 0.9 | 1.9 |
| Bread, sourdough | 1 slice (32g) | 88 | 3.5 | 17.0 | 0.5 | 0.7 |
| Bagel, plain | 1 medium (71g) | 182 | 7.1 | 35.9 | 1.0 | 1.6 |
| English muffin | 1 whole (57g) | 132 | 4.4 | 26.0 | 1.0 | 1.5 |
| Tortilla, flour (8 inch) | 1 tortilla (49g) | 146 | 3.8 | 24.6 | 3.6 | 1.3 |
| Tortilla, corn (6 inch) | 1 tortilla (26g) | 52 | 1.4 | 10.7 | 0.7 | 1.5 |
| Pita bread, white | 1 whole (64g) | 170 | 5.5 | 33.4 | 1.7 | 1.3 |
| Naan bread | 1 piece (90g) | 262 | 8.7 | 45.4 | 5.1 | 1.8 |
| Couscous, cooked | 1 cup (157g) | 176 | 6.0 | 36.5 | 0.3 | 2.2 |
| Bulgur wheat, cooked | 1 cup (182g) | 151 | 5.6 | 33.8 | 0.4 | 8.2 |
| Cornbread | 1 piece (65g) | 198 | 4.0 | 26.0 | 8.5 | 1.2 |
| Croissant | 1 medium (57g) | 231 | 4.7 | 26.1 | 12.0 | 1.5 |
| Pancake (from mix) | 1 medium (38g) | 86 | 2.4 | 11.0 | 3.5 | 0.5 |
| Waffle (frozen, toasted) | 1 waffle (33g) | 95 | 2.0 | 15.4 | 2.9 | 0.5 |
| Potato, baked with skin | 1 medium (173g) | 161 | 4.3 | 36.6 | 0.2 | 3.8 |
| Sweet potato, baked | 1 medium (114g) | 103 | 2.3 | 23.6 | 0.1 | 3.8 |
| French fries (medium) | 117g | 365 | 4.4 | 44.4 | 19.0 | 4.0 |
| Mashed potatoes | 1 cup (210g) | 237 | 4.0 | 35.0 | 9.0 | 3.2 |
| Hash browns | 1 cup (156g) | 326 | 3.2 | 35.0 | 19.2 | 3.1 |
| Corn, sweet, cooked | 1 cup (154g) | 134 | 5.0 | 31.0 | 1.8 | 3.6 |
| Popcorn, air-popped | 3 cups (24g) | 93 | 3.0 | 18.6 | 1.1 | 3.5 |
| Popcorn, movie-style buttered | 1 medium (114g) | 594 | 6.0 | 60.0 | 38.0 | 8.0 |
| Crackers, saltine | 5 crackers (15g) | 63 | 1.3 | 10.5 | 1.7 | 0.4 |
| Granola bar | 1 bar (42g) | 190 | 4.0 | 29.0 | 7.0 | 2.0 |
| Rice cakes, plain | 2 cakes (18g) | 70 | 1.4 | 14.8 | 0.4 | 0.4 |

### FRUITS

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Apple, medium | 1 medium (182g) | 95 | 0.5 | 25.1 | 0.3 | 4.4 |
| Banana, medium | 1 medium (118g) | 105 | 1.3 | 27.0 | 0.4 | 3.1 |
| Orange, medium | 1 medium (131g) | 62 | 1.2 | 15.4 | 0.2 | 3.1 |
| Strawberries | 1 cup (152g) | 49 | 1.0 | 11.7 | 0.5 | 3.0 |
| Blueberries | 1 cup (148g) | 84 | 1.1 | 21.4 | 0.5 | 3.6 |
| Raspberries | 1 cup (123g) | 64 | 1.5 | 14.7 | 0.8 | 8.0 |
| Grapes, red or green | 1 cup (151g) | 104 | 1.1 | 27.3 | 0.2 | 1.4 |
| Watermelon | 1 cup diced (152g) | 46 | 0.9 | 11.5 | 0.2 | 0.6 |
| Cantaloupe | 1 cup diced (156g) | 53 | 1.3 | 12.7 | 0.3 | 1.4 |
| Mango, sliced | 1 cup (165g) | 99 | 1.4 | 24.7 | 0.6 | 2.6 |
| Pineapple, chunks | 1 cup (165g) | 82 | 0.9 | 21.6 | 0.2 | 2.3 |
| Peach, medium | 1 medium (150g) | 59 | 1.4 | 14.3 | 0.4 | 2.3 |
| Pear, medium | 1 medium (178g) | 101 | 0.6 | 27.1 | 0.2 | 5.5 |
| Avocado | 1/2 medium (68g) | 114 | 1.4 | 6.0 | 10.5 | 4.6 |
| Kiwi | 1 medium (69g) | 42 | 0.8 | 10.1 | 0.4 | 2.1 |
| Grapefruit | 1/2 medium (123g) | 52 | 0.9 | 13.1 | 0.2 | 2.0 |
| Cherries, sweet | 1 cup (138g) | 87 | 1.5 | 22.0 | 0.3 | 2.9 |
| Pomegranate seeds | 1/2 cup (87g) | 72 | 1.4 | 16.3 | 1.0 | 3.5 |
| Dates, Medjool | 2 dates (48g) | 133 | 0.9 | 36.0 | 0.1 | 3.2 |
| Raisins | 1/4 cup (41g) | 123 | 1.3 | 32.7 | 0.2 | 1.6 |
| Dried cranberries | 1/4 cup (40g) | 123 | 0.1 | 33.0 | 0.5 | 2.3 |
| Coconut, shredded, dried | 1/4 cup (20g) | 71 | 0.7 | 6.4 | 5.3 | 1.8 |
| Plantain, fried (tostones) | 1 cup (118g) | 365 | 1.5 | 48.0 | 19.0 | 3.4 |
| Lychee, fresh | 5 pieces (50g) | 33 | 0.4 | 8.3 | 0.2 | 0.7 |
| Papaya, cubed | 1 cup (140g) | 55 | 0.9 | 13.7 | 0.2 | 2.5 |

### VEGETABLES

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Broccoli, steamed | 1 cup (91g) | 31 | 2.6 | 6.0 | 0.3 | 2.4 |
| Spinach, raw | 2 cups (60g) | 14 | 1.7 | 2.2 | 0.2 | 1.3 |
| Spinach, cooked | 1 cup (180g) | 41 | 5.3 | 6.8 | 0.5 | 4.3 |
| Kale, raw, chopped | 1 cup (67g) | 33 | 2.2 | 6.0 | 0.6 | 1.3 |
| Bell pepper, red | 1 medium (119g) | 31 | 1.0 | 6.0 | 0.3 | 2.1 |
| Tomato, medium | 1 medium (123g) | 22 | 1.1 | 4.8 | 0.2 | 1.5 |
| Carrot, medium | 1 medium (61g) | 25 | 0.6 | 5.8 | 0.1 | 1.7 |
| Cucumber, sliced | 1 cup (119g) | 16 | 0.7 | 3.1 | 0.2 | 0.5 |
| Zucchini, sliced | 1 cup (113g) | 19 | 1.4 | 3.5 | 0.4 | 1.1 |
| Cauliflower, steamed | 1 cup (107g) | 27 | 2.1 | 5.1 | 0.3 | 2.1 |
| Green beans, steamed | 1 cup (125g) | 34 | 2.0 | 7.8 | 0.1 | 4.0 |
| Asparagus, steamed | 6 spears (96g) | 19 | 2.2 | 3.7 | 0.2 | 1.8 |
| Brussels sprouts, roasted | 1 cup (88g) | 56 | 4.0 | 11.1 | 0.8 | 4.1 |
| Mushrooms, white, sauteed | 1 cup (70g) | 28 | 2.2 | 4.3 | 0.3 | 0.7 |
| Onion, chopped | 1/2 cup (80g) | 32 | 0.9 | 7.5 | 0.1 | 1.4 |
| Celery stalks | 2 stalks (80g) | 11 | 0.6 | 2.4 | 0.1 | 1.3 |
| Lettuce, romaine | 2 cups (94g) | 16 | 1.2 | 3.3 | 0.2 | 2.0 |
| Mixed salad greens | 2 cups (85g) | 18 | 1.5 | 3.0 | 0.2 | 1.5 |
| Cabbage, shredded | 1 cup (89g) | 22 | 1.1 | 5.2 | 0.1 | 2.1 |
| Artichoke heart, canned | 4 pieces (56g) | 24 | 1.3 | 4.4 | 0.1 | 2.3 |
| Eggplant, grilled | 1 cup (99g) | 35 | 0.8 | 8.6 | 0.2 | 2.5 |
| Beet, roasted | 1 medium (82g) | 35 | 1.3 | 7.8 | 0.1 | 2.3 |
| Peas, green, cooked | 1/2 cup (80g) | 62 | 4.0 | 11.3 | 0.3 | 4.4 |
| Corn on the cob | 1 ear (90g) | 77 | 2.9 | 17.1 | 1.1 | 2.4 |

### NUTS & SEEDS

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Almonds | 1 oz (28g) / 23 nuts | 164 | 6.0 | 6.1 | 14.2 | 3.5 |
| Walnuts | 1 oz (28g) / 14 halves | 185 | 4.3 | 3.9 | 18.5 | 1.9 |
| Cashews | 1 oz (28g) / 18 nuts | 157 | 5.2 | 8.6 | 12.4 | 0.9 |
| Peanuts, dry roasted | 1 oz (28g) | 166 | 6.7 | 6.1 | 14.1 | 2.3 |
| Pecans | 1 oz (28g) / 19 halves | 196 | 2.6 | 3.9 | 20.4 | 2.7 |
| Pistachios | 1 oz (28g) / 49 nuts | 159 | 5.7 | 7.7 | 12.8 | 3.0 |
| Macadamia nuts | 1 oz (28g) / 10-12 nuts | 204 | 2.2 | 3.9 | 21.5 | 2.4 |
| Brazil nuts | 1 oz (28g) / 6 nuts | 186 | 4.1 | 3.5 | 18.8 | 2.1 |
| Sunflower seeds | 1 oz (28g) | 165 | 5.5 | 6.5 | 14.0 | 3.2 |
| Pumpkin seeds (pepitas) | 1 oz (28g) | 151 | 7.0 | 5.0 | 13.0 | 1.7 |
| Chia seeds | 2 tbsp (28g) | 138 | 4.7 | 12.0 | 8.7 | 9.8 |
| Flax seeds, ground | 2 tbsp (14g) | 74 | 2.6 | 4.0 | 5.9 | 3.8 |
| Hemp seeds | 3 tbsp (30g) | 166 | 9.5 | 2.6 | 14.6 | 1.2 |
| Peanut butter | 2 tbsp (32g) | 188 | 8.0 | 6.0 | 16.0 | 1.9 |
| Almond butter | 2 tbsp (32g) | 196 | 6.8 | 6.0 | 17.8 | 3.3 |
| Trail mix (nuts/raisins/choc) | 1/4 cup (38g) | 175 | 4.5 | 17.0 | 11.0 | 1.8 |
| Mixed nuts, roasted | 1 oz (28g) | 172 | 4.9 | 7.2 | 14.6 | 2.0 |
| Tahini (sesame paste) | 2 tbsp (30g) | 178 | 5.1 | 6.4 | 16.0 | 1.4 |
| Coconut, fresh | 1 oz (28g) | 100 | 0.9 | 4.3 | 9.5 | 2.6 |

### BEVERAGES

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Water | 8 oz (240ml) | 0 | 0 | 0 | 0 | 0 |
| Black coffee | 8 oz (240ml) | 2 | 0.3 | 0 | 0 | 0 |
| Latte (whole milk) | 12 oz (360ml) | 200 | 10.0 | 16.0 | 10.0 | 0 |
| Cappuccino (whole milk) | 8 oz (240ml) | 120 | 6.0 | 10.0 | 6.0 | 0 |
| Americano | 8 oz (240ml) | 5 | 0.3 | 0.7 | 0 | 0 |
| Mocha (whole milk) | 16 oz (480ml) | 360 | 13.0 | 42.0 | 15.0 | 2.0 |
| Frappuccino (grande) | 16 oz (480ml) | 380 | 5.0 | 60.0 | 14.0 | 0 |
| Green tea | 8 oz (240ml) | 2 | 0.5 | 0 | 0 | 0 |
| Orange juice | 8 oz (240ml) | 112 | 1.7 | 25.8 | 0.5 | 0.5 |
| Apple juice | 8 oz (240ml) | 114 | 0.3 | 28.0 | 0.3 | 0.5 |
| Smoothie (fruit/yogurt) | 16 oz (480ml) | 280 | 8.0 | 56.0 | 2.0 | 3.0 |
| Protein shake (whey + water) | 12 oz (360ml) | 130 | 25.0 | 4.0 | 1.5 | 0 |
| Protein shake (whey + milk) | 12 oz (360ml) | 270 | 33.0 | 16.0 | 9.0 | 0 |
| Coca-Cola (regular) | 12 oz (355ml) | 140 | 0 | 39.0 | 0 | 0 |
| Diet Coke / Coke Zero | 12 oz (355ml) | 0 | 0 | 0 | 0 | 0 |
| Gatorade | 20 oz (591ml) | 140 | 0 | 36.0 | 0 | 0 |
| Red Bull (regular) | 8.4 oz (250ml) | 110 | 0 | 28.0 | 0 | 0 |
| Beer, regular | 12 oz (355ml) | 153 | 1.6 | 12.6 | 0 | 0 |
| Beer, light | 12 oz (355ml) | 103 | 0.9 | 5.8 | 0 | 0 |
| Wine, red | 5 oz (150ml) | 125 | 0.1 | 3.8 | 0 | 0 |
| Wine, white | 5 oz (150ml) | 121 | 0.1 | 3.8 | 0 | 0 |
| Margarita | 8 oz (240ml) | 274 | 0.3 | 36.1 | 0.2 | 0.2 |
| Kombucha | 8 oz (240ml) | 30 | 0 | 7.0 | 0 | 0 |
| Coconut water | 8 oz (240ml) | 46 | 1.7 | 8.9 | 0.5 | 2.6 |
| Almond milk, unsweetened | 1 cup (240ml) | 30 | 1.0 | 1.0 | 2.5 | 0 |
| Oat milk | 1 cup (240ml) | 120 | 3.0 | 16.0 | 5.0 | 2.0 |
| Soy milk | 1 cup (240ml) | 80 | 7.0 | 4.0 | 3.5 | 1.0 |

### FATS, OILS & CONDIMENTS

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Olive oil | 1 tbsp (14ml) | 119 | 0 | 0 | 13.5 | 0 |
| Coconut oil | 1 tbsp (14ml) | 121 | 0 | 0 | 13.5 | 0 |
| Canola oil | 1 tbsp (14ml) | 124 | 0 | 0 | 14.0 | 0 |
| Avocado oil | 1 tbsp (14ml) | 124 | 0 | 0 | 14.0 | 0 |
| Sesame oil | 1 tbsp (14ml) | 120 | 0 | 0 | 13.6 | 0 |
| Mayonnaise | 1 tbsp (14g) | 94 | 0.1 | 0.1 | 10.3 | 0 |
| Ranch dressing | 2 tbsp (30g) | 129 | 0.4 | 1.8 | 13.4 | 0 |
| Italian dressing | 2 tbsp (30g) | 71 | 0.1 | 2.5 | 6.9 | 0 |
| Balsamic vinaigrette | 2 tbsp (30g) | 80 | 0.1 | 5.0 | 6.5 | 0 |
| Honey mustard dressing | 2 tbsp (30g) | 110 | 0.3 | 9.0 | 8.0 | 0 |
| Caesar dressing | 2 tbsp (30g) | 140 | 0.8 | 0.8 | 15.0 | 0 |
| Ketchup | 1 tbsp (17g) | 20 | 0.2 | 4.8 | 0 | 0 |
| Mustard, yellow | 1 tsp (5g) | 3 | 0.2 | 0.3 | 0.2 | 0 |
| Soy sauce | 1 tbsp (18ml) | 8 | 1.3 | 0.8 | 0 | 0 |
| Hot sauce | 1 tsp (5ml) | 1 | 0.1 | 0.1 | 0 | 0 |
| BBQ sauce | 2 tbsp (36g) | 52 | 0.2 | 12.6 | 0.3 | 0.2 |
| Teriyaki sauce | 2 tbsp (30ml) | 32 | 2.2 | 5.8 | 0 | 0 |
| Sriracha | 1 tsp (5g) | 5 | 0.1 | 1.0 | 0.1 | 0 |
| Hummus | 2 tbsp (30g) | 50 | 2.0 | 4.0 | 3.0 | 1.0 |
| Guacamole | 2 tbsp (30g) | 50 | 0.6 | 2.6 | 4.5 | 1.8 |
| Salsa | 2 tbsp (30g) | 10 | 0.5 | 2.0 | 0 | 0.5 |
| Honey | 1 tbsp (21g) | 64 | 0.1 | 17.3 | 0 | 0 |
| Maple syrup | 1 tbsp (20g) | 52 | 0 | 13.4 | 0 | 0 |
| Jam/jelly | 1 tbsp (20g) | 56 | 0.1 | 13.8 | 0 | 0.2 |
| Chocolate syrup | 2 tbsp (38g) | 100 | 0.8 | 24.0 | 0.4 | 0.8 |
| Whipped cream | 2 tbsp (8g) | 15 | 0.1 | 0.6 | 1.5 | 0 |
| Cream cheese (spread) | 2 tbsp (29g) | 99 | 1.7 | 1.6 | 9.8 | 0 |
| Pesto sauce | 2 tbsp (30g) | 160 | 3.0 | 2.0 | 15.0 | 0.5 |
| Alfredo sauce | 1/4 cup (62g) | 110 | 2.0 | 3.0 | 10.0 | 0 |
| Marinara sauce | 1/2 cup (125g) | 66 | 1.6 | 10.4 | 2.2 | 2.0 |

### SWEETS & SNACKS

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Dark chocolate (70-85%) | 1 oz (28g) | 170 | 2.2 | 13.0 | 12.0 | 3.1 |
| Milk chocolate | 1 oz (28g) | 153 | 2.1 | 17.1 | 8.7 | 1.0 |
| Ice cream, vanilla | 1/2 cup (66g) | 137 | 2.3 | 15.6 | 7.3 | 0.5 |
| Ice cream, premium | 1/2 cup (106g) | 290 | 5.0 | 28.0 | 17.0 | 0 |
| Frozen yogurt | 1/2 cup (72g) | 110 | 3.0 | 19.0 | 3.0 | 0 |
| Cookie, chocolate chip | 1 large (30g) | 140 | 1.5 | 19.0 | 7.0 | 0.5 |
| Brownie | 1 piece (56g) | 227 | 2.7 | 36.0 | 9.0 | 1.2 |
| Donut, glazed | 1 medium (60g) | 240 | 3.0 | 31.0 | 12.0 | 0.7 |
| Muffin, blueberry | 1 large (113g) | 377 | 5.5 | 56.0 | 15.0 | 1.8 |
| Cake, chocolate (with frosting) | 1 slice (95g) | 352 | 4.0 | 50.0 | 16.0 | 1.8 |
| Cheesecake | 1 slice (125g) | 401 | 7.0 | 32.0 | 27.0 | 0.3 |
| Candy bar (Snickers) | 1 bar (52g) | 250 | 4.3 | 33.0 | 12.0 | 1.4 |
| Chips, potato | 1 oz (28g) | 152 | 2.0 | 15.0 | 9.8 | 1.2 |
| Chips, tortilla | 1 oz (28g) / ~10 chips | 142 | 2.0 | 17.8 | 7.4 | 1.4 |
| Pretzels | 1 oz (28g) | 108 | 2.8 | 22.5 | 1.0 | 0.9 |
| Gummy bears | 1 oz (28g) / ~10 bears | 87 | 1.8 | 21.8 | 0 | 0 |
| M&Ms, peanut | 1 pack (49g) | 250 | 5.0 | 30.0 | 13.0 | 2.0 |
| Oreo cookies | 3 cookies (34g) | 160 | 1.0 | 25.0 | 7.0 | 1.0 |
| Pop-Tart | 1 pastry (50g) | 200 | 2.0 | 37.0 | 5.0 | 0.5 |
| Cereal bar (Nature Valley) | 2 bars (42g) | 190 | 4.0 | 29.0 | 7.0 | 2.0 |
| Rice Krispies Treat | 1 bar (22g) | 90 | 1.0 | 17.0 | 2.5 | 0 |
| Fruit snacks | 1 pouch (25g) | 80 | 0 | 19.0 | 0 | 0 |

### PREPARED / FAST FOOD ITEMS

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Pizza, cheese (thin crust) | 1 slice (107g) | 237 | 11.0 | 26.0 | 10.0 | 1.5 |
| Pizza, pepperoni (regular) | 1 slice (113g) | 298 | 13.0 | 30.0 | 14.0 | 1.8 |
| Cheeseburger, single patty | 1 burger (200g) | 480 | 26.0 | 36.0 | 25.0 | 1.5 |
| Double cheeseburger | 1 burger (280g) | 680 | 40.0 | 38.0 | 40.0 | 2.0 |
| Chicken sandwich, grilled | 1 sandwich (200g) | 380 | 32.0 | 36.0 | 12.0 | 2.0 |
| Chicken sandwich, fried | 1 sandwich (230g) | 520 | 28.0 | 42.0 | 26.0 | 2.0 |
| Hot dog (with bun) | 1 hot dog (98g) | 290 | 10.5 | 24.0 | 17.0 | 0.8 |
| Burrito (chicken, rice, beans) | 1 large (400g) | 680 | 38.0 | 78.0 | 24.0 | 10.0 |
| Taco (beef, hard shell) | 1 taco (78g) | 170 | 8.0 | 13.0 | 10.0 | 1.5 |
| Nachos with cheese | 1 plate (195g) | 570 | 14.0 | 52.0 | 34.0 | 4.0 |
| Quesadilla (chicken) | 1 whole (230g) | 560 | 30.0 | 38.0 | 32.0 | 2.0 |
| Sub sandwich (turkey, 6-inch) | 1 sub (230g) | 280 | 18.0 | 46.0 | 3.5 | 5.0 |
| Sub sandwich (Italian, 6-inch) | 1 sub (240g) | 480 | 22.0 | 46.0 | 22.0 | 5.0 |
| Chicken nuggets | 6 pieces (96g) | 280 | 14.0 | 18.0 | 17.0 | 1.0 |
| Fish and chips | 1 serving (350g) | 780 | 28.0 | 60.0 | 46.0 | 4.0 |
| Caesar salad (no chicken) | 1 bowl (200g) | 310 | 7.0 | 14.0 | 26.0 | 3.0 |
| Caesar salad with chicken | 1 bowl (300g) | 440 | 35.0 | 14.0 | 28.0 | 3.0 |
| Cobb salad | 1 bowl (400g) | 520 | 34.0 | 12.0 | 38.0 | 4.0 |
| Ramen (pork broth, restaurant) | 1 bowl (600ml) | 550 | 25.0 | 60.0 | 22.0 | 3.0 |
| Pho (beef, restaurant) | 1 bowl (600ml) | 420 | 30.0 | 52.0 | 8.0 | 2.0 |
| Pad Thai (shrimp) | 1 plate (350g) | 560 | 22.0 | 68.0 | 22.0 | 3.0 |
| Fried rice (chicken) | 1 plate (300g) | 480 | 18.0 | 58.0 | 20.0 | 2.0 |
| Lo mein (chicken) | 1 plate (300g) | 490 | 22.0 | 52.0 | 22.0 | 3.0 |
| General Tso's chicken | 1 plate (350g) | 620 | 28.0 | 52.0 | 32.0 | 2.0 |
| Sushi, California roll | 8 pieces (185g) | 262 | 7.0 | 38.0 | 8.0 | 2.5 |
| Sushi, salmon nigiri | 2 pieces (70g) | 120 | 8.0 | 14.0 | 3.0 | 0 |
| Sushi, tuna roll | 6 pieces (150g) | 184 | 12.0 | 28.0 | 2.0 | 1.0 |
| Sashimi, mixed (5 pieces) | 5 slices (125g) | 145 | 28.0 | 0 | 3.0 | 0 |
| Mac and cheese | 1 cup (200g) | 350 | 12.0 | 38.0 | 16.0 | 1.5 |
| Grilled cheese sandwich | 1 sandwich (130g) | 370 | 14.0 | 28.0 | 23.0 | 1.0 |
| BLT sandwich | 1 sandwich (180g) | 344 | 14.0 | 28.0 | 20.0 | 2.0 |
| Club sandwich (triple-decker) | 1 sandwich (310g) | 540 | 30.0 | 42.0 | 28.0 | 3.0 |
| Soup, chicken noodle | 1 cup (240ml) | 62 | 3.2 | 7.3 | 2.4 | 0.7 |
| Soup, tomato | 1 cup (240ml) | 74 | 2.0 | 16.0 | 0.7 | 1.5 |
| Soup, clam chowder | 1 cup (240ml) | 180 | 6.0 | 16.0 | 10.0 | 1.2 |
| Soup, minestrone | 1 cup (240ml) | 82 | 4.3 | 11.2 | 2.5 | 2.3 |
| Chili con carne | 1 cup (253g) | 256 | 22.0 | 22.0 | 8.0 | 6.0 |

"""

    def _nutrition_cultural_reference(self) -> str:
        """Cultural cuisine reference: ~200 items across Indian, Asian, Mexican cuisines (~8K tokens)."""
        return """
## CULTURAL CUISINE NUTRITION REFERENCE

### INDIAN CUISINE

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Chicken tikka masala | 1 cup (240g) | 320 | 24.0 | 14.0 | 18.0 | 2.0 |
| Butter chicken (murgh makhani) | 1 cup (240g) | 380 | 28.0 | 12.0 | 24.0 | 1.5 |
| Chicken biryani | 1 plate (350g) | 490 | 26.0 | 62.0 | 16.0 | 2.0 |
| Vegetable biryani | 1 plate (300g) | 340 | 8.0 | 58.0 | 10.0 | 4.0 |
| Lamb rogan josh | 1 cup (240g) | 340 | 26.0 | 8.0 | 22.0 | 2.0 |
| Palak paneer (spinach + cheese) | 1 cup (240g) | 280 | 16.0 | 10.0 | 20.0 | 3.0 |
| Chana masala (chickpea curry) | 1 cup (240g) | 240 | 12.0 | 34.0 | 8.0 | 10.0 |
| Dal (lentil curry) | 1 cup (240g) | 180 | 12.0 | 28.0 | 4.0 | 8.0 |
| Dal makhani (black lentil, creamy) | 1 cup (240g) | 260 | 14.0 | 30.0 | 10.0 | 7.0 |
| Aloo gobi (potato + cauliflower) | 1 cup (200g) | 160 | 4.0 | 22.0 | 7.0 | 4.0 |
| Paneer tikka | 6 pieces (150g) | 320 | 20.0 | 6.0 | 24.0 | 1.0 |
| Tandoori chicken (half) | 1/2 chicken (250g) | 340 | 42.0 | 4.0 | 16.0 | 0.5 |
| Chicken kebab | 4 pieces (120g) | 200 | 28.0 | 2.0 | 8.0 | 0.5 |
| Samosa (vegetable) | 2 pieces (100g) | 260 | 4.0 | 30.0 | 14.0 | 2.0 |
| Samosa (chicken/lamb) | 2 pieces (120g) | 320 | 12.0 | 28.0 | 18.0 | 1.5 |
| Pakora / bhaji (onion) | 4 pieces (80g) | 200 | 4.0 | 20.0 | 12.0 | 2.0 |
| Naan bread | 1 piece (90g) | 262 | 8.7 | 45.4 | 5.1 | 1.8 |
| Garlic naan | 1 piece (100g) | 300 | 9.0 | 48.0 | 8.0 | 1.8 |
| Roti / chapati | 1 piece (40g) | 104 | 3.0 | 18.0 | 2.4 | 2.0 |
| Paratha (plain) | 1 piece (60g) | 180 | 4.0 | 24.0 | 8.0 | 2.0 |
| Puri (fried bread) | 2 pieces (50g) | 200 | 3.0 | 22.0 | 12.0 | 1.0 |
| Dosa (plain, masala) | 1 large (150g) | 250 | 6.0 | 36.0 | 10.0 | 2.0 |
| Idli | 3 pieces (120g) | 156 | 5.0 | 32.0 | 0.8 | 1.5 |
| Vada (medu vada) | 2 pieces (80g) | 220 | 8.0 | 20.0 | 12.0 | 3.0 |
| Uttapam | 1 piece (200g) | 260 | 8.0 | 40.0 | 8.0 | 3.0 |
| Raita (yogurt + cucumber) | 1/2 cup (120g) | 60 | 3.0 | 4.0 | 3.0 | 0.5 |
| Mango lassi | 1 glass (300ml) | 220 | 6.0 | 40.0 | 4.0 | 1.0 |
| Chai tea (with milk + sugar) | 1 cup (240ml) | 80 | 2.0 | 14.0 | 2.0 | 0 |
| Gulab jamun | 2 pieces (60g) | 240 | 3.0 | 36.0 | 10.0 | 0.5 |
| Jalebi | 3 pieces (60g) | 250 | 2.0 | 40.0 | 10.0 | 0 |
| Kheer (rice pudding) | 1 cup (200g) | 260 | 6.0 | 44.0 | 8.0 | 0.5 |
| Rasmalai | 2 pieces (100g) | 220 | 6.0 | 30.0 | 8.0 | 0 |
| Chole bhature | 1 plate (300g) | 520 | 16.0 | 58.0 | 26.0 | 8.0 |
| Pav bhaji | 1 plate (350g) | 440 | 10.0 | 52.0 | 22.0 | 6.0 |
| Malai kofta | 1 cup (240g) | 360 | 10.0 | 24.0 | 26.0 | 2.0 |
| Rajma (kidney bean curry) | 1 cup (240g) | 220 | 12.0 | 34.0 | 4.0 | 10.0 |
| Bhindi masala (okra) | 1 cup (200g) | 140 | 4.0 | 14.0 | 8.0 | 4.0 |
| Egg curry | 1 cup (240g) | 260 | 16.0 | 10.0 | 18.0 | 2.0 |
| Fish curry (coconut-based) | 1 cup (240g) | 280 | 24.0 | 8.0 | 18.0 | 1.0 |
| Prawn masala | 1 cup (240g) | 240 | 22.0 | 10.0 | 12.0 | 2.0 |
| Upma (semolina porridge) | 1 cup (200g) | 220 | 6.0 | 30.0 | 8.0 | 2.0 |
| Poha (flattened rice) | 1 cup (200g) | 240 | 5.0 | 40.0 | 8.0 | 2.0 |
| Pulao (vegetable rice) | 1 cup (200g) | 260 | 5.0 | 44.0 | 8.0 | 2.0 |
| Thali (typical lunch plate) | 1 thali (~600g) | 700 | 22.0 | 90.0 | 28.0 | 12.0 |

### EAST ASIAN CUISINE (Chinese, Japanese, Korean, Thai, Vietnamese)

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Kung Pao chicken | 1 cup (240g) | 340 | 28.0 | 20.0 | 18.0 | 3.0 |
| Sweet and sour pork | 1 cup (240g) | 380 | 18.0 | 42.0 | 16.0 | 1.5 |
| Mapo tofu | 1 cup (240g) | 220 | 14.0 | 8.0 | 14.0 | 1.0 |
| Beef with broccoli | 1 cup (240g) | 280 | 24.0 | 14.0 | 14.0 | 3.0 |
| Orange chicken | 1 cup (240g) | 420 | 22.0 | 44.0 | 18.0 | 1.0 |
| Chow mein (chicken) | 1 plate (300g) | 420 | 22.0 | 48.0 | 16.0 | 3.0 |
| Dim sum, har gow (shrimp dumpling) | 4 pieces (100g) | 160 | 10.0 | 18.0 | 4.0 | 0.5 |
| Dim sum, siu mai (pork) | 4 pieces (100g) | 200 | 12.0 | 14.0 | 10.0 | 0.5 |
| Dim sum, char siu bao (BBQ pork bun) | 1 bun (100g) | 260 | 10.0 | 36.0 | 8.0 | 1.0 |
| Spring roll (fried) | 2 rolls (100g) | 250 | 6.0 | 24.0 | 14.0 | 1.5 |
| Egg roll (fried) | 1 roll (85g) | 200 | 6.0 | 20.0 | 11.0 | 1.0 |
| Wonton soup | 1 bowl (6 wontons, 360ml) | 180 | 12.0 | 20.0 | 4.0 | 1.0 |
| Hot and sour soup | 1 cup (240ml) | 90 | 6.0 | 8.0 | 3.0 | 1.0 |
| Egg drop soup | 1 cup (240ml) | 65 | 4.0 | 6.0 | 2.0 | 0 |
| Dan dan noodles | 1 bowl (350g) | 520 | 18.0 | 52.0 | 26.0 | 2.0 |
| Congee / jook (rice porridge) | 1 bowl (350g) | 180 | 6.0 | 32.0 | 3.0 | 0.5 |
| Peking duck (with pancakes) | 1 serving (200g) | 440 | 28.0 | 20.0 | 28.0 | 1.0 |
| Steamed fish (whole, ginger scallion) | 6 oz (170g) | 180 | 32.0 | 4.0 | 4.0 | 0.5 |
| Miso soup | 1 cup (240ml) | 40 | 3.0 | 4.0 | 1.0 | 0.5 |
| Edamame, salted | 1 cup in pod (155g) | 188 | 18.5 | 13.8 | 8.1 | 8.0 |
| Gyoza (pan-fried pork) | 6 pieces (120g) | 280 | 12.0 | 26.0 | 14.0 | 1.0 |
| Teriyaki salmon | 6 oz (170g) | 340 | 36.0 | 12.0 | 16.0 | 0 |
| Chicken teriyaki bowl | 1 bowl (400g) | 520 | 30.0 | 64.0 | 14.0 | 2.0 |
| Katsu curry (chicken) | 1 plate (400g) | 680 | 32.0 | 64.0 | 32.0 | 3.0 |
| Tempura (assorted, 6 pieces) | 6 pieces (150g) | 380 | 12.0 | 32.0 | 24.0 | 2.0 |
| Udon noodle soup | 1 bowl (500ml) | 340 | 12.0 | 56.0 | 6.0 | 2.0 |
| Ramen, shoyu (soy) | 1 bowl (600ml) | 480 | 22.0 | 56.0 | 18.0 | 2.0 |
| Ramen, tonkotsu (pork bone) | 1 bowl (600ml) | 580 | 26.0 | 58.0 | 26.0 | 2.0 |
| Ramen, miso | 1 bowl (600ml) | 520 | 24.0 | 60.0 | 20.0 | 3.0 |
| Onigiri (rice ball, tuna) | 1 piece (100g) | 170 | 6.0 | 32.0 | 2.0 | 0.5 |
| Korean BBQ (bulgogi, beef) | 4 oz (113g) | 220 | 22.0 | 10.0 | 10.0 | 0.5 |
| Korean BBQ (samgyeopsal, pork belly) | 4 oz (113g) | 380 | 16.0 | 2.0 | 34.0 | 0 |
| Bibimbap | 1 bowl (400g) | 520 | 24.0 | 66.0 | 18.0 | 4.0 |
| Kimchi jjigae (stew) | 1 bowl (300g) | 200 | 18.0 | 8.0 | 10.0 | 2.0 |
| Japchae (glass noodles) | 1 cup (200g) | 240 | 6.0 | 38.0 | 8.0 | 2.0 |
| Kimchi | 1/2 cup (75g) | 16 | 1.0 | 2.4 | 0.4 | 1.0 |
| Tteokbokki (spicy rice cakes) | 1 cup (200g) | 320 | 6.0 | 62.0 | 6.0 | 2.0 |
| Korean fried chicken (with sauce) | 6 pieces (200g) | 560 | 28.0 | 32.0 | 34.0 | 1.0 |
| Pad Thai (shrimp/chicken) | 1 plate (350g) | 560 | 22.0 | 68.0 | 22.0 | 3.0 |
| Green curry (with chicken) | 1 cup (240g) | 320 | 20.0 | 12.0 | 22.0 | 2.0 |
| Red curry (with beef) | 1 cup (240g) | 340 | 22.0 | 14.0 | 22.0 | 2.0 |
| Massaman curry | 1 cup (240g) | 380 | 18.0 | 22.0 | 26.0 | 3.0 |
| Tom yum soup | 1 cup (240ml) | 80 | 8.0 | 6.0 | 3.0 | 1.0 |
| Tom kha gai (coconut chicken soup) | 1 cup (240ml) | 180 | 12.0 | 8.0 | 12.0 | 1.0 |
| Thai basil stir-fry (pad krapow) | 1 plate (250g) | 340 | 24.0 | 28.0 | 14.0 | 2.0 |
| Mango sticky rice | 1 serving (200g) | 340 | 4.0 | 60.0 | 10.0 | 2.0 |
| Pho (beef, large) | 1 bowl (700ml) | 460 | 32.0 | 58.0 | 8.0 | 2.0 |
| Banh mi (pork) | 1 sandwich (260g) | 460 | 22.0 | 48.0 | 20.0 | 3.0 |
| Vietnamese spring rolls (fresh) | 2 rolls (120g) | 140 | 8.0 | 22.0 | 2.0 | 1.5 |
| Bun cha (grilled pork + noodles) | 1 bowl (400g) | 480 | 26.0 | 52.0 | 18.0 | 3.0 |
| Com tam (broken rice plate) | 1 plate (400g) | 540 | 28.0 | 64.0 | 18.0 | 2.0 |
| Laksa (curry noodle soup) | 1 bowl (500ml) | 520 | 18.0 | 48.0 | 28.0 | 2.0 |
| Nasi goreng (fried rice, Indonesian) | 1 plate (300g) | 460 | 16.0 | 56.0 | 20.0 | 2.0 |
| Satay (chicken, 4 skewers) | 4 skewers (120g) | 280 | 28.0 | 6.0 | 16.0 | 1.0 |
| Satay peanut sauce | 2 tbsp (30g) | 80 | 3.0 | 6.0 | 5.0 | 1.0 |

### MEXICAN / LATIN AMERICAN CUISINE

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Burrito (beef, rice, beans, cheese) | 1 large (400g) | 720 | 34.0 | 80.0 | 28.0 | 10.0 |
| Burrito bowl (chicken, rice, veggies) | 1 bowl (400g) | 580 | 36.0 | 62.0 | 20.0 | 10.0 |
| Chicken fajitas (meat only) | 1 cup (150g) | 200 | 28.0 | 6.0 | 8.0 | 1.0 |
| Fajitas (full plate with tortillas) | 1 serving (350g) | 520 | 32.0 | 42.0 | 24.0 | 5.0 |
| Tacos al pastor (3 street tacos) | 3 tacos (200g) | 380 | 22.0 | 34.0 | 18.0 | 3.0 |
| Fish tacos (2 tacos) | 2 tacos (200g) | 360 | 22.0 | 30.0 | 16.0 | 3.0 |
| Carnitas tacos (3 tacos) | 3 tacos (210g) | 420 | 24.0 | 30.0 | 22.0 | 2.0 |
| Enchiladas (chicken, 2 pieces) | 2 enchiladas (260g) | 440 | 24.0 | 32.0 | 24.0 | 4.0 |
| Enchiladas (cheese, 2 pieces) | 2 enchiladas (240g) | 480 | 18.0 | 30.0 | 30.0 | 3.0 |
| Tamales (pork, 2 pieces) | 2 tamales (200g) | 400 | 14.0 | 40.0 | 22.0 | 4.0 |
| Chile relleno (stuffed pepper) | 1 piece (200g) | 340 | 14.0 | 18.0 | 24.0 | 3.0 |
| Quesadilla (cheese only) | 1 whole (180g) | 440 | 18.0 | 36.0 | 24.0 | 2.0 |
| Tostada (chicken) | 1 tostada (130g) | 220 | 14.0 | 18.0 | 10.0 | 3.0 |
| Elote (Mexican street corn) | 1 ear (150g) | 220 | 6.0 | 26.0 | 12.0 | 3.0 |
| Chilaquiles (with egg) | 1 plate (300g) | 420 | 18.0 | 38.0 | 22.0 | 4.0 |
| Huevos rancheros | 1 plate (300g) | 380 | 18.0 | 30.0 | 22.0 | 6.0 |
| Chips and guacamole | 1 basket (150g) | 480 | 6.0 | 38.0 | 34.0 | 6.0 |
| Chips and salsa | 1 basket (120g) | 340 | 4.0 | 42.0 | 18.0 | 3.0 |
| Churros (3 pieces) | 3 churros (90g) | 360 | 4.0 | 42.0 | 20.0 | 1.0 |
| Tres leches cake | 1 slice (140g) | 340 | 6.0 | 44.0 | 16.0 | 0 |
| Horchata | 1 glass (240ml) | 150 | 1.0 | 32.0 | 2.0 | 0 |
| Agua fresca (Jamaica/hibiscus) | 1 glass (240ml) | 60 | 0 | 16.0 | 0 | 0 |
| Mole sauce (with chicken) | 1 cup (240g) | 380 | 28.0 | 18.0 | 22.0 | 3.0 |
| Pozole (pork, red) | 1 bowl (350g) | 280 | 18.0 | 30.0 | 10.0 | 4.0 |
| Ceviche (shrimp) | 1 cup (200g) | 140 | 18.0 | 10.0 | 3.0 | 2.0 |
| Mexican rice | 1 cup (200g) | 220 | 4.0 | 40.0 | 6.0 | 1.5 |
| Refried beans | 1/2 cup (120g) | 130 | 7.0 | 18.0 | 4.0 | 5.0 |
| Black beans (side) | 1/2 cup (120g) | 114 | 7.6 | 20.4 | 0.5 | 7.5 |
| Pupusa (cheese) | 1 pupusa (110g) | 220 | 8.0 | 26.0 | 10.0 | 2.0 |
| Arepas (corn cake, cheese filled) | 1 arepa (120g) | 280 | 10.0 | 30.0 | 14.0 | 2.0 |
| Empanada (beef) | 1 empanada (130g) | 310 | 12.0 | 28.0 | 18.0 | 1.5 |
| Empanada (cheese) | 1 empanada (110g) | 280 | 8.0 | 26.0 | 16.0 | 1.0 |
| Gallo pinto (rice and beans) | 1 cup (200g) | 260 | 10.0 | 44.0 | 5.0 | 6.0 |
| Plantain, fried (maduros) | 1 cup (118g) | 310 | 1.5 | 46.0 | 14.0 | 3.0 |
| Yuca frita (fried cassava) | 1 cup (120g) | 340 | 1.5 | 44.0 | 18.0 | 2.0 |

### MIDDLE EASTERN / MEDITERRANEAN CUISINE

| Food Item | Serving | Calories | Protein | Carbs | Fat | Fiber |
|-----------|---------|----------|---------|-------|-----|-------|
| Falafel (4 pieces) | 4 balls (100g) | 280 | 10.0 | 26.0 | 16.0 | 4.0 |
| Shawarma (chicken, wrap) | 1 wrap (300g) | 520 | 32.0 | 44.0 | 24.0 | 3.0 |
| Shawarma (lamb, plate) | 1 plate (350g) | 580 | 36.0 | 40.0 | 30.0 | 3.0 |
| Kebab (chicken shish, 2 skewers) | 2 skewers (150g) | 240 | 32.0 | 4.0 | 10.0 | 1.0 |
| Kebab (lamb kofta, 2 skewers) | 2 skewers (150g) | 320 | 24.0 | 6.0 | 22.0 | 1.0 |
| Hummus | 1/3 cup (80g) | 130 | 5.0 | 12.0 | 7.0 | 3.0 |
| Baba ganoush | 1/3 cup (80g) | 100 | 2.0 | 8.0 | 7.0 | 3.0 |
| Tabbouleh | 1 cup (160g) | 120 | 3.0 | 16.0 | 6.0 | 3.0 |
| Fattoush salad | 1 bowl (200g) | 160 | 3.0 | 14.0 | 10.0 | 3.0 |
| Dolma/dolmades (grape leaves, 6) | 6 pieces (120g) | 180 | 4.0 | 22.0 | 8.0 | 3.0 |
| Moussaka | 1 serving (250g) | 380 | 18.0 | 20.0 | 26.0 | 4.0 |
| Greek salad (horiatiki) | 1 bowl (250g) | 220 | 6.0 | 10.0 | 18.0 | 3.0 |
| Spanakopita (spinach pie) | 1 piece (120g) | 280 | 8.0 | 22.0 | 18.0 | 2.0 |
| Gyro (lamb, pita) | 1 gyro (300g) | 560 | 28.0 | 42.0 | 30.0 | 3.0 |
| Baklava | 1 piece (78g) | 334 | 5.0 | 30.0 | 23.0 | 2.0 |
| Kibbeh (fried) | 2 pieces (120g) | 320 | 14.0 | 24.0 | 20.0 | 2.0 |
| Labneh (strained yogurt) | 1/4 cup (60g) | 80 | 4.0 | 4.0 | 5.0 | 0 |
| Shakshuka | 1 serving (250g) | 220 | 14.0 | 12.0 | 14.0 | 3.0 |
| Manakeesh (za'atar flatbread) | 1 piece (150g) | 360 | 8.0 | 44.0 | 18.0 | 3.0 |
| Couscous with vegetables | 1 cup (200g) | 220 | 7.0 | 38.0 | 4.0 | 3.0 |
| Lamb tagine | 1 cup (240g) | 340 | 24.0 | 20.0 | 18.0 | 4.0 |
| Harira soup (Moroccan) | 1 cup (240ml) | 160 | 10.0 | 22.0 | 3.0 | 4.0 |
| Turkish delight (lokum) | 3 pieces (45g) | 140 | 0.5 | 34.0 | 0.5 | 0 |

"""
