// Central registry of all calculators. Used by:
//   - /tools index page (lists everything)
//   - RelatedCalcs component (cross-links from each calc page)
//   - Sitemap generation
//   - Internal SEO link graph

export type CalcCategory =
  | 'ai-tools'
  | 'photo-tools'
  | 'timers'
  | 'strength'
  | 'powerlifting'
  | 'body-composition'
  | 'nutrition'
  | 'cardio'
  | 'programming'
  | 'programs'
  | 'lifestyle'
  | 'wellness'
  | 'general';

export interface CalcEntry {
  slug: string;            // URL slug (route: /tools/<slug>)
  name: string;            // Display name
  description: string;     // 1-line description for cards
  category: CalcCategory;
  paidElsewhere?: boolean; // True if competitors charge for this
  competitor?: string;     // e.g. "MacroFactor ($11.99/mo)"
  keywords: string[];      // SEO keywords this page targets
}

export const CALC_REGISTRY: CalcEntry[] = [
  // AI-powered tools (rate-limited to 2 uses/IP/24h)
  {
    slug: 'ai-form-check',
    name: 'AI Form Check — Squat, Bench, Deadlift',
    description: 'Upload a video of your squat, bench, or deadlift. AI extracts keyframes and returns rep-by-rep form analysis: overall score, fault detection with severity, rep count, and concrete fix cues scored against NSCA and Starting Strength standards. 3 free checks per day.',
    category: 'ai-tools',
    paidElsewhere: true,
    competitor: 'Sculptor, Gymscore, personal-trainer form checks ($50-100/session)',
    keywords: ['ai form check', 'squat form analysis', 'bench press form check', 'deadlift form analyzer', 'lifting form ai', 'video form analysis', 'rep counter ai'],
  },
  {
    slug: 'ai-food-photo',
    name: 'AI Food Photo Analyzer',
    description: 'Photograph any meal. Gemini Vision identifies foods and estimates calories, macros, and micronutrients per item. 2 free scans per day.',
    category: 'ai-tools',
    paidElsewhere: true,
    competitor: 'Cal AI, MyFitnessPal Premium ($19.99/mo), Lose It Premium',
    keywords: ['ai food photo', 'food calorie scanner', 'photo to macros', 'ai meal analyzer'],
  },
  {
    slug: 'ai-workout-generator',
    name: 'AI Workout Generator',
    description: 'Pick a goal, days, and equipment. Get a custom-generated workout with warm-up, main work, and cooldown. 2 free workouts per day.',
    category: 'ai-tools',
    paidElsewhere: true,
    competitor: 'JuggernautAI, Fitbod ($15.99/mo)',
    keywords: ['ai workout generator', 'free workout plan ai', 'custom workout generator'],
  },
  {
    slug: 'ai-physique-analyzer',
    name: 'AI Physique Analyzer + 4-Week Program',
    description: 'Upload a torso photo. Gemini Vision estimates body fat, classifies somatotype, identifies muscle strengths and weaknesses, and builds a 4-week NSCA-guided program targeting your weak points. 10 free analyses per hour.',
    category: 'ai-tools',
    paidElsewhere: true,
    competitor: 'Bodbot, DEXA scans ($50-150), Macrofactor body audits',
    keywords: ['ai physique analyzer', 'ai body fat estimator', 'photo body fat', 'physique scan', 'ai program generator', 'weak muscle finder'],
  },
  {
    slug: 'ai-roast-my-routine',
    name: 'AI Roast My Routine',
    description: 'Paste your training routine. AI critiques volume balance, frequency, gaps, and gives a letter grade. Spicy or constructive tone. 2 free roasts per day.',
    category: 'ai-tools',
    paidElsewhere: false,
    keywords: ['routine critique', 'workout routine review', 'ai routine analyzer', 'roast my workout'],
  },
  // Photo tools + share cards
  {
    slug: 'photo-comparison',
    name: 'Progress Photo Comparison',
    description: 'Side-by-side before/after composer with date, weight, and Zealova watermark. Download as JPG, PNG, or WebP. Nothing uploaded.',
    category: 'photo-tools',
    keywords: ['progress photo comparison', 'before after photo', 'fitness photo collage'],
  },
  {
    slug: 'pr-celebration-card',
    name: 'PR Celebration Card Generator',
    description: 'Drop your lift, weight, reps, and bodyweight. Download a share-ready PR card with confetti, gradient burst, and bodyweight ratio.',
    category: 'photo-tools',
    paidElsewhere: true,
    competitor: 'Most fitness apps charge for branded share cards',
    keywords: ['pr card generator', 'personal record card', 'lift share card', 'pr celebration'],
  },
  {
    slug: 'streak-certificate',
    name: 'Streak Certificate Generator',
    description: 'Diploma-style certificate for any fitness streak. Workouts, cutting, bulking, cardio. Print-friendly 1200×900 landscape.',
    category: 'photo-tools',
    keywords: ['streak certificate', 'fitness streak generator', 'workout streak card'],
  },
  {
    slug: 'workout-summary-card',
    name: 'Workout Summary Card',
    description: 'TikTok and Reels ready 9:16 card with total volume, duration, and top 3 lifts. Hero volume number, gradient background.',
    category: 'photo-tools',
    paidElsewhere: true,
    competitor: 'Most fitness apps charge for branded share cards',
    keywords: ['workout summary card', 'workout share card', 'volume share image'],
  },
  {
    slug: 'year-in-fitness-wrapped',
    name: 'Year in Fitness Wrapped Preview',
    description: 'Spotify-Wrapped style annual stats card with top 3 lifts, total volume, and body weight change. 1080×1920.',
    category: 'photo-tools',
    paidElsewhere: true,
    competitor: 'Most fitness apps charge for branded share cards',
    keywords: ['year in fitness wrapped', 'fitness wrapped', 'gym wrapped', 'fitness year review'],
  },
  {
    slug: 'lifter-personality-quiz',
    name: 'Lifter Personality Quiz',
    description: '10 questions, 8 archetypes. Power Princess, Volume Goblin, Form Nerd, more. Download a shareable result card with your split.',
    category: 'photo-tools',
    keywords: ['lifter personality quiz', 'gym personality test', 'training style quiz'],
  },
  // Timers
  {
    slug: 'fasting-timer',
    name: 'Intermittent Fasting Timer',
    description: '8 protocols (12:12, 14:10, 16:8, 18:6, 20:4, OMAD, 36-hour, custom) with sound and notification when complete. Metabolic phase tracking. Resumes after tab close.',
    category: 'timers',
    paidElsewhere: true,
    competitor: 'Zero, Fasted, Fastly (most charge for protocol picker + phase tracking)',
    keywords: ['intermittent fasting timer', '16 8 fasting timer', 'OMAD timer', 'fasting tracker'],
  },
  // Strength
  {
    slug: '1rm-calculator',
    name: '1RM Calculator',
    description: 'Estimate your one-rep max from any submaximal set. 7 formulas side-by-side.',
    category: 'strength',
    keywords: ['1rm calculator', 'one rep max', 'epley formula', 'brzycki formula'],
  },
  {
    slug: 'rir-rpe-converter',
    name: 'RIR / RPE / %1RM Converter',
    description: 'Convert between Reps in Reserve, Rate of Perceived Exertion, and percentage of 1RM.',
    category: 'strength',
    paidElsewhere: true,
    competitor: 'Most powerlifting coaching apps',
    keywords: ['rir calculator', 'rpe to percent', 'rir to rpe', 'rpe chart'],
  },
  {
    slug: 'plate-loader',
    name: 'Plate Loader',
    description: 'See exactly which plates to load on the bar to hit a target weight. Supports 45/35/25/15/10/5/2.5 lb and 25/20/15/10/5/2.5/1.25 kg plates.',
    category: 'strength',
    keywords: ['plate calculator', 'barbell loader', 'plate math'],
  },
  {
    slug: 'strength-level',
    name: 'Strength Level Percentile',
    description: 'See where your lifts rank against millions of others, by bodyweight and sex.',
    category: 'strength',
    paidElsewhere: true,
    competitor: 'StrengthLevel.com (cookie-gated)',
    keywords: ['strength standards', 'lift percentile', 'how strong am i'],
  },

  // Powerlifting
  {
    slug: 'wilks-calculator',
    name: 'Wilks Calculator',
    description: 'Calculate your Wilks score for comparing powerlifters across bodyweights.',
    category: 'powerlifting',
    keywords: ['wilks calculator', 'wilks score', 'powerlifting score'],
  },
  {
    slug: 'dots-calculator',
    name: 'DOTS Calculator',
    description: 'Calculate DOTS score, the modern alternative to Wilks used outside the IPF.',
    category: 'powerlifting',
    keywords: ['dots calculator', 'dots score', 'powerlifting coefficient'],
  },
  {
    slug: 'ipf-gl-calculator',
    name: 'IPF GL Points Calculator',
    description: 'Calculate IPF GL (Goodlift) points, the official IPF scoring system since 2020.',
    category: 'powerlifting',
    keywords: ['ipf gl calculator', 'goodlift points', 'ipf scoring'],
  },
  {
    slug: 'schwartz-malone-calculator',
    name: 'Schwartz-Malone Calculator',
    description: 'Calculate Schwartz-Malone score, the older sex-adjusted powerlifting formula.',
    category: 'powerlifting',
    keywords: ['schwartz malone', 'powerlifting formula', 'classic powerlifting score'],
  },

  // Body composition
  {
    slug: 'bmr-calculator',
    name: 'BMR Calculator',
    description: 'Basal Metabolic Rate using all 4 major equations: Mifflin-St Jeor, Harris-Benedict, Katch-McArdle, Cunningham.',
    category: 'body-composition',
    keywords: ['bmr calculator', 'basal metabolic rate', 'mifflin st jeor'],
  },
  {
    slug: 'tdee-calculator',
    name: 'TDEE Calculator',
    description: 'Total Daily Energy Expenditure. 4 BMR equations × 5 activity multipliers, all compared.',
    category: 'body-composition',
    keywords: ['tdee calculator', 'maintenance calories', 'daily calorie needs'],
  },
  {
    slug: 'body-fat-calculator',
    name: 'Body Fat % Calculator',
    description: 'Estimate body fat using 5 methods: Navy, JP3, JP7, Covert Bailey, RFM.',
    category: 'body-composition',
    paidElsewhere: true,
    competitor: 'Coaching apps + clinical DEXA ($50-150)',
    keywords: ['body fat calculator', 'navy method', 'skinfold calculator'],
  },
  {
    slug: 'lean-body-mass-calculator',
    name: 'Lean Body Mass Calculator',
    description: 'Estimate your fat-free mass using Boer, James, and Hume formulas.',
    category: 'body-composition',
    keywords: ['lean body mass', 'lbm calculator', 'fat free mass'],
  },
  {
    slug: 'bmi-calculator',
    name: 'BMI Calculator',
    description: 'Body Mass Index with category, plus key caveats for muscular and athletic populations.',
    category: 'body-composition',
    keywords: ['bmi calculator', 'body mass index', 'bmi chart'],
  },
  {
    slug: 'ideal-weight-calculator',
    name: 'Ideal Weight Calculator',
    description: 'Estimate ideal body weight using Robinson, Miller, Devine, Hamwi, and BMI-range methods.',
    category: 'body-composition',
    keywords: ['ideal weight', 'healthy body weight', 'goal weight calculator'],
  },
  {
    slug: 'healthy-weight-calculator',
    name: 'Healthy Weight Range',
    description: 'Find your healthy weight range based on BMI, age, and frame size.',
    category: 'body-composition',
    keywords: ['healthy weight range', 'normal weight', 'weight chart'],
  },

  // Goal-oriented program guides (free hub for "how to" queries)
  {
    slug: 'how-to-get-jacked',
    name: 'How to Get Jacked, 16-Week Plan',
    description: 'Realistic 16-week hypertrophy plan with per-muscle weekly volume targets (Schoenfeld 2017), 1.6 to 2.2 g/kg protein, lean surplus, and Lyle McDonald natural gain curve.',
    category: 'programs',
    paidElsewhere: true,
    competitor: 'Jeff Nippard programs ($30-90), RP Hypertrophy app ($24.99/mo)',
    keywords: ['how to get jacked', 'hypertrophy plan', 'muscle gain calculator', 'lean bulk calculator'],
  },
  {
    slug: 'how-to-get-ripped',
    name: 'How to Get Ripped, Cutting Calculator',
    description: 'Cut from your current body fat to your target with a science-based deficit, 1.1 g per pound protein, cardio dose, refeed schedule, and week-by-week loss curve.',
    category: 'programs',
    paidElsewhere: true,
    competitor: 'Carbon Diet Coach, Stronger U, Renaissance Diet App',
    keywords: ['how to get ripped', 'cutting calculator', 'fat loss calculator', 'shredding plan'],
  },
  {
    slug: 'how-to-cut-without-losing-muscle',
    name: 'How to Cut Without Losing Muscle',
    description: 'Muscle preservation cutting protocol. Caps deficit at 500 cal, holds bench/squat/deadlift within 5%, cuts accessory volume first, schedules diet breaks every 7 weeks.',
    category: 'programs',
    paidElsewhere: true,
    competitor: 'Helms-style coaching ($150-400/mo), MASS Research Review',
    keywords: ['cut without losing muscle', 'muscle preservation diet', 'lift floor cut', 'protein floor cutting'],
  },
  // New utility tools
  {
    slug: 'workout-log-exporter',
    name: 'Workout Log Exporter',
    description: 'Log workouts in a clean multi-row form. Export as CSV or print to PDF. Fully local, nothing uploaded. Built for lifters who want their own data.',
    category: 'programs',
    paidElsewhere: true,
    competitor: 'Strong ($4.99/mo), Hevy Pro ($4.99/mo)',
    keywords: ['workout log export', 'workout csv export', 'workout pdf', 'training log exporter', 'gym log to csv'],
  },
  {
    slug: 'workout-plan-builder',
    name: 'Workout Plan Builder',
    description: '5-step wizard generates a 4-week training plan based on your goal, experience, equipment, and schedule. Volume calibrated to Schoenfeld hypertrophy research.',
    category: 'programs',
    paidElsewhere: true,
    competitor: 'Jeff Nippard programs ($30-90), Boostcamp Premium ($9.99/mo)',
    keywords: ['workout plan builder', 'free workout plan', 'training plan generator', '4 week program builder', 'gym plan generator'],
  },
  {
    slug: 'calorie-deficit-tracker',
    name: '7-Day Calorie Deficit Tracker',
    description: 'Log daily intake and weight for a week. Auto-computes total deficit, average daily deficit, projected fat loss. Saves to your browser.',
    category: 'nutrition',
    paidElsewhere: true,
    competitor: 'MyFitnessPal Premium ($19.99/mo), MacroFactor ($11.99/mo)',
    keywords: ['calorie deficit tracker', 'deficit calculator', 'weekly deficit tracker', 'fat loss tracker', 'calorie diary'],
  },
  {
    slug: 'supplement-stack-analyzer',
    name: 'Supplement Stack Analyzer',
    description: 'Paste your supplements. Get evidence tier, optimal timing, optimal dose, and PubMed citations per item. Flags redundancies, missing high-value supplements, and poor timing.',
    category: 'nutrition',
    paidElsewhere: true,
    competitor: 'Examine.com+ ($29/mo), supplement coaching ($75-200)',
    keywords: ['supplement stack analyzer', 'supplement review', 'supplement evidence tier', 'supplement timing', 'examine supplement guide'],
  },
  // Protocol / programming-nutrition hybrid
  {
    slug: 'fat-loss-protocol-calculator',
    name: 'Fat Loss Protocol Calculator',
    description: 'Variable-duration cut: maintenance × 15 minus 500, LBM-based protein, walking + alcohol bonuses, weekly weight projection. 4 to 26 weeks.',
    category: 'nutrition',
    paidElsewhere: true,
    competitor: 'Helms-style coaching apps, Renaissance Periodization Diet',
    keywords: ['fat loss calculator', 'cutting protocol', 'how much protein to lose fat', 'lean body mass protein'],
  },
  // Nutrition
  {
    slug: 'macro-calculator',
    name: 'Macro Calculator',
    description: 'Calculate daily protein / carbs / fat targets based on goal, body weight, and activity.',
    category: 'nutrition',
    keywords: ['macro calculator', 'protein carbs fat calculator', 'macro split'],
  },
  {
    slug: 'adaptive-macro-calculator',
    name: 'Adaptive Macro Calculator',
    description: '4-week macro simulation that adjusts weekly based on weight trend. Like MacroFactor, but free.',
    category: 'nutrition',
    paidElsewhere: true,
    competitor: 'MacroFactor ($11.99/mo)',
    keywords: ['adaptive macro calculator', 'flexible dieting', 'macro adjustment'],
  },
  {
    slug: 'adaptive-calorie-calculator',
    name: 'Adaptive Calorie Adjustment',
    description: 'Recalculate your TDEE from 7 days of actual intake and weight change. Break diet plateaus.',
    category: 'nutrition',
    paidElsewhere: true,
    competitor: 'MacroFactor, Carbon, Stronger U',
    keywords: ['adaptive calorie', 'plateau break', 'tdee adjustment'],
  },
  {
    slug: 'protein-per-meal-calculator',
    name: 'Protein-Per-Meal Optimizer',
    description: 'Optimal protein split per meal based on 0.4-0.55 g/kg per meal research (Schoenfeld, Aragon).',
    category: 'nutrition',
    keywords: ['protein per meal', 'protein timing', 'leucine threshold'],
  },
  {
    slug: 'carb-cycling-calculator',
    name: 'Carb Cycling Calculator',
    description: 'High / medium / low carb day macros based on training schedule.',
    category: 'nutrition',
    keywords: ['carb cycling', 'high low carb days', 'training day macros'],
  },
  {
    slug: 'alcohol-impact-calculator',
    name: 'Alcohol Impact on Muscle Gain',
    description: 'Translates drinks per week into MPS suppression, testosterone window, cortisol elevation, REM loss, and days delayed to next PR. Built on Parr 2014, Vingren 2013, Ebrahim 2013.',
    category: 'nutrition',
    paidElsewhere: false,
    keywords: ['alcohol and muscle', 'alcohol hypertrophy calculator', 'drinking and gains', 'alcohol testosterone', 'alcohol sleep impact'],
  },
  {
    slug: 'calories-burned-calculator',
    name: 'Calories Burned Calculator',
    description: 'Estimate calories burned during exercise using MET values from the Compendium of Physical Activities.',
    category: 'nutrition',
    keywords: ['calories burned', 'workout calorie calculator', 'met values'],
  },

  // Cardio
  {
    slug: 'vo2-max-calculator',
    name: 'VO2 Max Calculator',
    description: 'Estimate VO2 max from 5 protocols: Cooper, 1.5-mile run, 12-min run, Bruce, Queens College step.',
    category: 'cardio',
    paidElsewhere: true,
    competitor: 'Garmin (hardware-gated)',
    keywords: ['vo2 max calculator', 'cooper test', 'aerobic fitness'],
  },
  {
    slug: 'pace-calculator',
    name: 'Pace Calculator',
    description: 'Convert between pace, speed, distance, and time for runs and rides.',
    category: 'cardio',
    keywords: ['pace calculator', 'running pace', 'min per mile'],
  },
  {
    slug: 'target-heart-rate-calculator',
    name: 'Target Heart Rate Calculator',
    description: 'Find your training heart rate zones using Karvonen, Tanaka, and Fox formulas.',
    category: 'cardio',
    keywords: ['target heart rate', 'heart rate zones', 'karvonen formula'],
  },
  {
    slug: 'sweat-rate-calculator',
    name: 'Sweat Rate / Hydration Calculator',
    description: 'Calculate hourly sweat rate and per-workout fluid needs from pre/post weight.',
    category: 'cardio',
    paidElsewhere: true,
    competitor: 'Sports-science consults',
    keywords: ['sweat rate calculator', 'hydration calculator', 'fluid replacement'],
  },

  // Programming
  {
    slug: 'workout-volume-calculator',
    name: 'Workout Volume Calculator',
    description: 'Recommended weekly sets per muscle group based on Schoenfeld 2017 dose-response research.',
    category: 'programming',
    paidElsewhere: true,
    competitor: 'JuggernautAI, RP+',
    keywords: ['workout volume', 'sets per muscle', 'hypertrophy volume'],
  },
  {
    slug: 'mesocycle-volume-calculator',
    name: 'Mesocycle Volume Progression',
    description: 'Plan a 4-6 week volume ramp for each muscle group, MEV to MAV to MRV.',
    category: 'programming',
    paidElsewhere: true,
    competitor: 'RP+ ($24.99/mo)',
    keywords: ['mesocycle planner', 'mev mav mrv', 'volume progression'],
  },
  {
    slug: 'deload-week-calculator',
    name: 'Deload Week Calculator',
    description: 'Recommends deload timing and intensity based on accumulated weekly volume and training fatigue.',
    category: 'programming',
    keywords: ['deload calculator', 'deload week', 'training fatigue'],
  },
  {
    slug: 'cut-bulk-duration-calculator',
    name: 'Cut / Bulk Duration Estimator',
    description: 'Estimate weeks needed for your cut or bulk given start/end body fat % and weekly deficit/surplus.',
    category: 'programming',
    keywords: ['cut duration', 'bulk timeline', 'cutting weeks calculator'],
  },
  {
    slug: 'tapering-calculator',
    name: 'Tapering Calculator',
    description: 'Powerlifting peak week tapering plan. Volume reduction schedule for meet day.',
    category: 'programming',
    paidElsewhere: true,
    competitor: 'Paid powerlifting coaching',
    keywords: ['tapering calculator', 'peaking program', 'meet week'],
  },

  // Additional timers
  {
    slug: 'workout-rest-timer',
    name: 'Workout Rest Timer',
    description: 'Between-sets countdown with audible beep, browser notification, vibration, and presets for strength, hypertrophy, endurance, and powerlifting.',
    category: 'timers',
    keywords: ['rest timer', 'workout timer', 'between sets timer', 'gym timer'],
  },
  {
    slug: 'hiit-interval-timer',
    name: 'HIIT / Tabata / EMOM / AMRAP Timer',
    description: 'Five modes in one: Tabata, custom HIIT, EMOM, AMRAP, For Time. Phase cues, vibration, browser notification.',
    category: 'timers',
    paidElsewhere: true,
    competitor: 'Seconds Pro, Tabata apps',
    keywords: ['hiit timer', 'tabata timer', 'emom timer', 'amrap timer', 'crossfit timer'],
  },
  {
    slug: 'sleep-cycle-calculator',
    name: 'Sleep Cycle Calculator',
    description: 'Bedtime and wake time planner based on 90-minute sleep cycles, with a 15-minute fall-asleep buffer.',
    category: 'timers',
    keywords: ['sleep cycle calculator', 'bedtime calculator', 'sleep calculator', '90 minute sleep cycle'],
  },

  // Lifestyle / generators
  {
    slug: 'workout-vibe-generator',
    name: 'Workout Vibe Generator',
    description: 'Pick a vibe, get a real workout. Ten vibes, ten complete training sessions, no signup.',
    category: 'lifestyle',
    keywords: ['workout generator', 'random workout', 'mood workout', 'workout picker'],
  },
  {
    slug: 'aesthetic-body-type-matcher',
    name: 'Aesthetic Body Type Matcher',
    description: 'Pick the physique you want, get the training principles, sample split, and timeline.',
    category: 'lifestyle',
    keywords: ['body type', 'physique goal', 'aesthetic training', 'body recomposition'],
  },
  {
    slug: 'cost-of-skipping-calculator',
    name: 'Cost of Skipping Calculator',
    description: 'Lifetime cost of skipping the gym. Money, hours, muscle, VO2. Plus the motivational flip.',
    category: 'lifestyle',
    keywords: ['gym membership cost', 'cost of skipping gym', 'fitness motivation calculator'],
  },

  // Wellness
  {
    slug: 'caffeine-cutoff-calculator',
    name: 'Caffeine Cutoff Calculator',
    description: 'See how much caffeine is still in your system at bedtime, and the latest you can drink coffee for clean sleep. Pharmacokinetic decay model.',
    category: 'wellness',
    paidElsewhere: true,
    competitor: 'Sleep coaching apps, Calm/Headspace adjacent',
    keywords: ['caffeine calculator', 'caffeine half life', 'caffeine cutoff', 'coffee bedtime'],
  },
  {
    slug: 'recipe-scaler',
    name: 'Recipe Scaler',
    description: 'Scale any recipe up or down by servings. Paste an ingredient list, get scaled quantities. Includes a cooking-measurement converter.',
    category: 'wellness',
    keywords: ['recipe scaler', 'recipe calculator', 'serving size calculator', 'ingredient converter'],
  },
  {
    slug: 'should-i-train-today',
    name: 'Should I Train Today?',
    description: 'Five-question decision tool that tells you whether to train, modify, or rest today. Scores sleep, soreness, stress, frequency, and fueling.',
    category: 'wellness',
    paidElsewhere: true,
    competitor: 'Whoop, Oura recovery scores (hardware-gated)',
    keywords: ['should i train today', 'recovery score', 'readiness quiz', 'rest day calculator'],
  },
  {
    slug: 'workout-buddy-compatibility',
    name: 'Workout Buddy Compatibility Quiz',
    description: 'Eight questions, one shareable compatibility code. Compare codes with a friend to see if you would survive lifting together.',
    category: 'wellness',
    keywords: ['workout buddy', 'gym partner quiz', 'training partner match'],
  },
  {
    slug: 'marathon-plan-generator',
    name: 'Marathon Plan Generator',
    description: 'Free week-by-week marathon training plan tailored to your race date, goal time, mileage, and experience. Base, build, peak, taper.',
    category: 'wellness',
    paidElsewhere: true,
    competitor: 'TrainingPeaks, Runna ($14.99/mo)',
    keywords: ['marathon plan', 'marathon training plan', 'free marathon plan', 'marathon generator'],
  },
];

export const CATEGORIES: { key: CalcCategory; name: string; description: string }[] = [
  { key: 'ai-tools', name: 'AI Tools', description: 'Gemini-powered food scan, workout generator, routine critique. 2 free uses per day.' },
  { key: 'photo-tools', name: 'Photo Tools', description: 'Progress photo composer, share-ready cards' },
  { key: 'timers', name: 'Timers', description: 'Fasting, rest, interval, and sleep cycle timers' },
  { key: 'strength', name: 'Strength', description: '1RM, percentile rankings, plate loading' },
  { key: 'powerlifting', name: 'Powerlifting Scoring', description: 'Wilks, DOTS, IPF GL, Schwartz-Malone' },
  { key: 'body-composition', name: 'Body Composition', description: 'BMR, TDEE, body fat, lean mass' },
  { key: 'nutrition', name: 'Nutrition', description: 'Macros, calorie adjustment, protein timing' },
  { key: 'cardio', name: 'Cardio + Hydration', description: 'VO2 max, pace, heart rate, sweat rate' },
  { key: 'programming', name: 'Programming', description: 'Volume, mesocycles, deload, tapering' },
  { key: 'programs', name: 'Goal-Based Plans', description: 'How to get jacked, how to get ripped, how to cut without losing muscle' },
  { key: 'lifestyle', name: 'Lifestyle + Generators', description: 'Vibe-based workouts, aesthetics, cost-of-skipping' },
  { key: 'wellness', name: 'Wellness + Recovery', description: 'Caffeine, recipes, readiness, training partners, marathon plans' },
];

export function calcsByCategory(category: CalcCategory): CalcEntry[] {
  return CALC_REGISTRY.filter((c) => c.category === category);
}

export function findCalc(slug: string): CalcEntry | undefined {
  return CALC_REGISTRY.find((c) => c.slug === slug);
}

// Related calculators logic: same category, max 4, excluding self.
export function relatedCalcs(currentSlug: string, max = 4): CalcEntry[] {
  const current = findCalc(currentSlug);
  if (!current) return [];
  return CALC_REGISTRY.filter(
    (c) => c.category === current.category && c.slug !== currentSlug
  ).slice(0, max);
}
