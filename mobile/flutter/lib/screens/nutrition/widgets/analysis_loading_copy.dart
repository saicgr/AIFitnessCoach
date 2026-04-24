/// Per-mode copy banks for the FoodAnalysisLoadingIndicator.
///
/// Three distinct "voices" — plate (single meal), menu (restaurant menu
/// OCR), buffet (food spread) — each with a generous bank of phases +
/// tips so long analyses feel alive and varied instead of the same
/// "Examining your meal… Fiber is your gut's best friend" loop.
///
/// Adding new lines: keep phases ≤ 30 chars (rendered near a pulsing
/// orb), keep tips ≤ 60 chars (italic subtitle line). Tone: observational
/// + slightly playful, never saccharine. No exclamation points unless
/// the line itself is a genuine punchline.
library;

/// (message, emoji) pair. Emoji cycles with the phase so the orb feels
/// reactive rather than static.
typedef LoadingPhase = (String, String);

class AnalysisLoadingCopy {
  /// Headline phases for plate mode (single-meal analysis).
  static const List<LoadingPhase> platePhases = [
    ('Spotting your plate', '👀'),
    ('Identifying ingredients', '🥗'),
    ('Weighing each component', '⚖️'),
    ('Counting the protein', '🍗'),
    ('Estimating the oil hit', '🫒'),
    ('Pulling USDA numbers', '📊'),
    ('Checking portion sizes', '🍽️'),
    ('Looking for hidden sugar', '🍬'),
    ('Flagging inflammatory stuff', '🔥'),
    ('Mapping macros to goals', '🎯'),
    ('Tasting the math', '🧮'),
    ('Cross-checking allergens', '⚠️'),
    ('Asking what your gut thinks', '🫃'),
    ('Parsing textures + prep', '🍳'),
    ('Measuring greens vs grains', '🌾'),
    ('Sizing up the protein source', '🥩'),
    ('Noting the fiber payload', '🌱'),
    ('Factoring in the dressing', '🫗'),
    ('Reading between the bites', '👓'),
    ('Crunching the final numbers', '✨'),
    ('Almost plated', '🫴'),
  ];

  /// Subtitle micro-education lines for plate mode.
  static const List<String> plateTips = [
    'Fiber is your gut\'s best friend',
    'Protein keeps you full longer',
    'Slower meals = smaller portions',
    'Greens quietly replace half a side',
    'Olive oil is liquid gold (just less of it)',
    'Hydration changes how you read hunger',
    'Colour on the plate = micronutrient variety',
    'Plating affects portion size — smaller bowls win',
    'Chewing more extracts more nutrition',
    'A palm of protein is usually plenty',
    'Cooked vegetables still count as vegetables',
    'Healthy fats are essential for brain function',
    'Your plate\'s inflammation score matters for recovery',
    'Fat-soluble vitamins need fat to absorb',
    'Resistant starch is a gut-microbiome upgrade',
    'Spices bring antioxidants at zero calorie cost',
    'Temperature affects satiety — warm meals satisfy longer',
    'Eating protein first blunts glucose spikes',
    'Sauce on the side = ~200 cal saved on average',
    'Tracking meals builds awareness, not guilt',
    'Consistency beats perfection',
    'Every rep counts — same with every bite',
    'Fermented foods stabilise your mood',
    'Whole eggs beat egg-whites for nutrient density',
    'The last 3 bites rarely hit the same',
    'You can\'t out-discipline bad sleep',
    'Satisfaction + satiety aren\'t the same metric',
    'Distraction while eating costs ~25% more food',
    'Water with meals supports digestion',
    'Muscle is the organ of longevity',
    'Omega-3s work best from fatty fish or walnuts',
    'Zinc helps immune + testosterone both',
  ];

  /// Headline phases for menu mode (restaurant menu OCR).
  static const List<LoadingPhase> menuPhases = [
    ('Cracking open the menu', '📖'),
    ('Counting the dishes', '🔢'),
    ('Reading section headers', '📋'),
    ('Scanning breakfast items', '🥞'),
    ('Parsing the appetizers', '🥟'),
    ('Flipping through the mains', '🍽️'),
    ('Checking the sides', '🥔'),
    ('Peeking at desserts', '🍰'),
    ('OCR\'ing tricky handwriting', '✍️'),
    ('Guessing the portion sizes', '⚖️'),
    ('Weighing each dish in grams', '🧺'),
    ('Spotting the hidden cream', '🥛'),
    ('Looking for hidden sugar', '🍯'),
    ('Flagging the inflammatory stuff', '🔥'),
    ('Finding what fits your macros', '🎯'),
    ('Cross-checking with your allergens', '⚠️'),
    ('Matching dishes to your goals', '💪'),
    ('Tagging the protein sources', '🍗'),
    ('Pulling prices off the page', '💵'),
    ('Reading between the lines', '🧐'),
    ('Asking what your gut would want', '🫃'),
    ('Smart-swap shortlist forming', '🔄'),
    ('Final polish on the picks', '✨'),
    ('Ranking by your budget', '🧾'),
    ('Sorting by fit + fire + flavor', '🌶️'),
  ];

  static const List<String> menuTips = [
    'Ask for sauce on the side — saves ~200 cal',
    'Grilled or baked beats fried most days',
    'Menus hide calories in the adjectives ("crispy", "glazed")',
    'The salad with cheese + dressing can out-calorie a burger',
    'Restaurant portions are 2–3× normal servings',
    'Bread baskets cost ~250 cal before you\'ve ordered',
    'Split entrées when eating out; share the dessert',
    'Sparkling water fills you before the bread does',
    '"Market fresh" usually means seasonal + leaner',
    'Soup starters shrink the main by about 20%',
    'Side salads beat fries in almost every case',
    'Avoid "smothered" and "loaded" — signal words',
    'Tomato-based sauces beat cream-based for macros',
    'Whole fish dishes tend to be honest about portions',
    'Steaks over 8oz are always sharable',
    'Small plates > tasting menus for portion control',
    'Lunch portions are usually 30% smaller than dinner',
    'Garlic bread + pasta is 1300+ calories easy',
    'Ethnic grilled plates pack the best protein-per-dollar',
    'Cocktails are 150–300 cal before you\'ve eaten',
    'Beer + burger = a 3-hour workout, roughly',
    'Brunch boards look healthy and rarely are',
    'Build the plate around the protein, not the carb',
    'A handful of nuts is a real serving, not a mouthful',
    'Dressing-drizzle beats dressing-pour',
    'Kids\' menus save money and usually macros',
    'Restaurant rice portions are ~3 cups; order half',
    'Tex-Mex combos are where calories hide',
    'Hidden butter lives under every "simple grilled" dish',
    'Acid (lemon/vinegar) makes "plain" tolerable',
    'The spicier the dish, the slower you eat',
    'Dessert hits better shared three ways',
    'Your own water refill counts as pacing',
  ];

  /// Headline phases for buffet mode (food-spread inventory).
  static const List<LoadingPhase> buffetPhases = [
    ('Surveying the spread', '👁️'),
    ('Counting every dish', '🔢'),
    ('Cataloging the proteins', '🍗'),
    ('Measuring the carb section', '🍚'),
    ('Eyeing the dessert table', '🍰'),
    ('Tagging what\'s fried vs baked', '🍳'),
    ('Estimating serving spoons', '🥄'),
    ('Guessing cream vs broth', '🥣'),
    ('Flagging ultra-processed items', '🏭'),
    ('Reading buffet labels', '🏷️'),
    ('Mapping sauces to macros', '🍯'),
    ('Spotting the salad sleepers', '🥗'),
    ('Sizing up the chafing trays', '🔥'),
    ('Building your ideal plate', '🍽️'),
    ('Triaging the "tastes-good" risks', '⚠️'),
    ('Asking what your gut would grab', '🫃'),
    ('Ranking by protein density', '💪'),
    ('Finding what actually fits today', '🎯'),
    ('Cross-checking with your allergens', '⚠️'),
    ('Giving priority to the greens', '🥬'),
    ('Noting which dishes repeat on camera', '🔁'),
    ('Smart-grab shortlist forming', '🧠'),
    ('Final pass on the winners', '✨'),
    ('Respecting your goals, politely', '🙂'),
  ];

  static const List<String> buffetTips = [
    'Survey the whole buffet before you plate anything',
    'Fill half your plate with vegetables first',
    'Use the small plate — cognitive portion control',
    'One trip > two trips in 95% of cases',
    'Pick the 2 proteins that look leanest',
    'Sauces are where buffets hide 400 calories',
    'The dessert table loses to the cheese board for macros',
    'Standing at the buffet = eating 40% more',
    'Sparkling water between plates resets hunger',
    'The chafing-dish steam means extra oil below',
    'Skip the "centerpiece" carbs — focus on the edges',
    'Grilled station beats the fryer station',
    'A broth-based soup starter shrinks the main course',
    'Watch the garnish — butter hides under herbs',
    'Buffet meat carvers will portion-control for you if asked',
    'The salad bar dressing alone can be 500 cal',
    'Rotate protein + vegetable + protein + vegetable',
    'Sit away from the buffet — out of eyeline',
    'Skip the bread station entirely; your goals will thank you',
    'The best buffet plates look like a home-cooked plate',
    'Shellfish + salad is usually the macro-friendliest combo',
    'Fried rice is carb + oil + soy — budget it, don\'t snack it',
    'Brunch buffets are where the math gets dangerous',
    'Quality of chew > quantity of chew',
    'Eat the vegetable starter before the meat carving line',
    'Coffee between trips is a legal hunger-hack',
    'Skip the chocolate fountain. It never ends well.',
    'Hotel buffets engineer you to overeat by design',
    'The "build-your-own" counter gives you honest macros',
    'Roasted > fried > creamed, in that order',
    'Pastries are designed to bypass your satiety signals',
  ];

  /// Extended "still working" subtitle lines for long analyses (≥ 15s).
  /// Rotate these instead of sticking on "Still working… 19s" which
  /// reads defensive. These feel like a coach running interference.
  static const List<String> stillWorkingLines = [
    'Large menus take a bit',
    'Parsing the tricky sections',
    'Double-checking the macros',
    'Making sure nothing got missed',
    'Some dishes need a closer look',
    'Thorough beats fast, promise',
    'Weighing each portion carefully',
    'Cross-referencing the nutrition DB',
    'One more pass on the tricky ones',
    'Last few dishes are the sneakiest',
    'Caffeine-ing up the AI',
    'Almost there — doing the rounding',
  ];

  /// Return phases bank for a given analysis mode. Falls back to plate
  /// bank for unknown modes so we never show a blank screen.
  static List<LoadingPhase> phasesFor(String mode) {
    switch (mode) {
      case 'menu':
        return menuPhases;
      case 'buffet':
        return buffetPhases;
      case 'plate':
      case 'auto':
      default:
        return platePhases;
    }
  }

  /// Return tips bank for a given analysis mode.
  static List<String> tipsFor(String mode) {
    switch (mode) {
      case 'menu':
        return menuTips;
      case 'buffet':
        return buffetTips;
      case 'plate':
      case 'auto':
      default:
        return plateTips;
    }
  }
}
