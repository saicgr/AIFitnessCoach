// FitWiz Features Data - Extracted from FEATURES.md
// Categories and features for the searchable/filterable Features page

export type FeatureCategory =
  | 'workout'
  | 'ai-coach'
  | 'nutrition'
  | 'progress'
  | 'exercise-library'
  | 'scheduling'
  | 'injury-prevention'
  | 'accessibility'
  | 'social'
  | 'subscription'
  | 'trial-demo'
  | 'cardio'
  | 'skill-progressions'
  | 'gamification'
  | 'customization'
  | 'integration';

export type FeatureTier = 'free' | 'premium' | 'ultra' | 'lifetime' | 'all';

export interface Feature {
  id: string;
  title: string;
  description: string;
  category: FeatureCategory;
  tier: FeatureTier;
  tags: string[];
  isNew?: boolean;
  isPopular?: boolean;
}

export const categoryLabels: Record<FeatureCategory, string> = {
  'workout': 'Workout Generation',
  'ai-coach': 'AI Coach',
  'nutrition': 'Nutrition Tracking',
  'progress': 'Progress & Analytics',
  'exercise-library': 'Exercise Library',
  'scheduling': 'Scheduling',
  'injury-prevention': 'Injury Prevention',
  'accessibility': 'Accessibility',
  'social': 'Social & Sharing',
  'subscription': 'Subscription',
  'trial-demo': 'Trial & Demo',
  'cardio': 'Cardio & Endurance',
  'skill-progressions': 'Skill Progressions',
  'gamification': 'Gamification',
  'customization': 'Customization',
  'integration': 'Integration',
};

export const categoryIcons: Record<FeatureCategory, string> = {
  'workout': 'M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5',
  'ai-coach': 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z',
  'nutrition': 'M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175',
  'progress': 'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75z',
  'exercise-library': 'M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  'scheduling': 'M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25',
  'injury-prevention': 'M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  'accessibility': 'M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z',
  'social': 'M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0 0a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0-12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z',
  'subscription': 'M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z',
  'trial-demo': 'M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z',
  'cardio': 'M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z',
  'skill-progressions': 'M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941',
  'gamification': 'M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172',
  'customization': 'M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75',
  'integration': 'M13.5 16.875h3.375m0 0h3.375m-3.375 0V13.5m0 3.375v3.375M6 10.5h2.25a2.25 2.25 0 002.25-2.25V6a2.25 2.25 0 00-2.25-2.25H6A2.25 2.25 0 003.75 6v2.25A2.25 2.25 0 006 10.5zm0 9.75h2.25A2.25 2.25 0 0010.5 18v-2.25a2.25 2.25 0 00-2.25-2.25H6a2.25 2.25 0 00-2.25 2.25V18A2.25 2.25 0 006 20.25zm9.75-9.75H18a2.25 2.25 0 002.25-2.25V6A2.25 2.25 0 0018 3.75h-2.25A2.25 2.25 0 0013.5 6v2.25a2.25 2.25 0 002.25 2.25z',
};

export const features: Feature[] = [
  // Workout Generation Features
  {
    id: 'ai-workout-generation',
    title: 'AI-Powered Workout Generation',
    description: 'Get personalized workout plans tailored to your goals, equipment, and schedule using advanced AI.',
    category: 'workout',
    tier: 'free',
    tags: ['ai', 'personalization', 'workouts', 'gemini'],
    isPopular: true,
  },
  {
    id: 'equipment-support',
    title: '23+ Equipment Types',
    description: 'Support for gym machines, free weights, bodyweight, and specialty equipment like battle ropes and sandbags.',
    category: 'workout',
    tier: 'free',
    tags: ['equipment', 'gym', 'home', 'crossfit'],
  },
  {
    id: 'rep-set-customization',
    title: 'Rep & Set Customization',
    description: 'Full control over rep ranges (1-30) and sets (1-6) with configurable limits and preferences.',
    category: 'workout',
    tier: 'premium',
    tags: ['customization', 'reps', 'sets', 'control'],
  },
  {
    id: 'workout-editing',
    title: 'Real-time Workout Editing',
    description: 'Modify exercises, swap movements, adjust sets/reps during your workout session.',
    category: 'workout',
    tier: 'premium',
    tags: ['editing', 'flexibility', 'customization'],
  },
  {
    id: 'quick-workout',
    title: 'Quick Workouts (5-15 min)',
    description: 'Time-constrained workouts for busy users with cardio, strength, stretch, or full body focus.',
    category: 'workout',
    tier: 'free',
    tags: ['quick', 'time', 'busy', 'efficient'],
    isNew: true,
  },
  {
    id: 'warmup-cooldown',
    title: 'Dynamic Warmup & Cooldown',
    description: 'AI-generated muscle-specific warmups and cooldowns with customizable duration (1-15 min).',
    category: 'workout',
    tier: 'free',
    tags: ['warmup', 'cooldown', 'mobility', 'stretching'],
  },
  {
    id: 'workout-templates',
    title: 'Save as Template',
    description: 'Save your favorite workouts as templates for quick access and reuse.',
    category: 'workout',
    tier: 'ultra',
    tags: ['templates', 'favorites', 'save'],
  },
  {
    id: 'import-workouts',
    title: 'Import Workouts',
    description: 'Import workout data from other apps or share workouts with friends.',
    category: 'workout',
    tier: 'premium',
    tags: ['import', 'export', 'share'],
  },
  {
    id: 'history-based-generation',
    title: 'History-Based Generation',
    description: 'Workouts generated using your actual performance data and workout patterns.',
    category: 'workout',
    tier: 'premium',
    tags: ['history', 'personalization', 'patterns'],
  },

  // AI Coach Features
  {
    id: 'ai-coach-chat',
    title: '24/7 AI Coach Chat',
    description: 'Chat with your AI coach anytime for form tips, exercise swaps, nutrition advice, and motivation.',
    category: 'ai-coach',
    tier: 'free',
    tags: ['chat', 'ai', 'coach', 'support'],
    isPopular: true,
  },
  {
    id: 'photo-meal-analysis',
    title: 'Photo Meal Analysis',
    description: 'Take a photo of your meal and get instant macro breakdowns and nutritional information.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['photo', 'nutrition', 'macros', 'ai'],
  },
  {
    id: 'exercise-alternatives',
    title: 'Exercise Alternatives',
    description: 'Ask AI for exercise alternatives when equipment is busy or unavailable.',
    category: 'ai-coach',
    tier: 'free',
    tags: ['alternatives', 'swap', 'flexibility'],
  },
  {
    id: 'voice-announcements',
    title: 'Voice Announcements',
    description: 'Text-to-speech voice guidance during workouts with customizable announcements.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['voice', 'audio', 'tts', 'guidance'],
  },
  {
    id: 'chat-history',
    title: 'Extended Chat History',
    description: 'Access your chat history - 7 days free, 90 days premium, forever for ultra/lifetime.',
    category: 'ai-coach',
    tier: 'all',
    tags: ['history', 'chat', 'memory'],
  },

  // Exercise Library Features
  {
    id: 'exercise-library',
    title: '1700+ Exercise Library',
    description: 'Comprehensive library with HD video demonstrations, muscle targeting, and difficulty ratings.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['exercises', 'videos', 'library', 'demonstrations'],
    isPopular: true,
  },
  {
    id: 'muscle-mapping',
    title: 'Compound Muscle Mapping',
    description: 'Every exercise shows all muscles worked with involvement percentages.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['muscles', 'anatomy', 'targeting'],
  },
  {
    id: 'exercise-filters',
    title: 'Advanced Exercise Filters',
    description: 'Filter by body part, equipment, type, goals, suitability, and conditions to avoid.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['filters', 'search', 'discovery'],
  },
  {
    id: 'exercise-history',
    title: 'Per-Exercise History',
    description: 'Track your performance history for each exercise including PRs and trends.',
    category: 'exercise-library',
    tier: 'premium',
    tags: ['history', 'tracking', 'progress'],
  },

  // Progress & Analytics Features
  {
    id: 'progress-charts',
    title: 'Visual Progress Charts',
    description: 'Line charts for strength progression and bar charts for weekly volume trends.',
    category: 'progress',
    tier: 'premium',
    tags: ['charts', 'visualization', 'trends'],
    isNew: true,
  },
  {
    id: 'streak-tracking',
    title: 'Streak Tracking',
    description: 'Track consecutive workout days with fire animations and milestone celebrations.',
    category: 'progress',
    tier: 'free',
    tags: ['streaks', 'consistency', 'motivation'],
  },
  {
    id: 'pr-tracking',
    title: 'Personal Record Tracking',
    description: 'Automatic PR detection and celebration with historical tracking.',
    category: 'progress',
    tier: 'premium',
    tags: ['pr', 'personal records', 'achievements'],
  },
  {
    id: 'rep-accuracy',
    title: 'Rep Accuracy Tracking',
    description: 'Log actual reps completed vs planned and track accuracy over time.',
    category: 'progress',
    tier: 'premium',
    tags: ['accuracy', 'reps', 'tracking'],
  },
  {
    id: 'consistency-dashboard',
    title: 'Consistency Insights',
    description: 'Calendar heatmap, best/worst day analysis, and completion rate trends.',
    category: 'progress',
    tier: 'premium',
    tags: ['consistency', 'analytics', 'patterns'],
    isNew: true,
  },
  {
    id: 'subjective-tracking',
    title: 'Mood & Energy Tracking',
    description: 'Track how you feel before and after workouts with AI insights on patterns.',
    category: 'progress',
    tier: 'premium',
    tags: ['mood', 'energy', 'feelings', 'wellness'],
  },
  {
    id: 'muscle-analytics',
    title: 'Muscle Analytics',
    description: 'Body heatmap showing training frequency, balance analysis, and volume per muscle.',
    category: 'progress',
    tier: 'ultra',
    tags: ['muscles', 'heatmap', 'balance', 'analytics'],
  },

  // Nutrition Features
  {
    id: 'food-photo-scanning',
    title: 'Food Photo Scanning',
    description: 'AI-powered meal recognition from photos with macro estimation.',
    category: 'nutrition',
    tier: 'free',
    tags: ['photo', 'ai', 'macros', 'logging'],
  },
  {
    id: 'macro-tracking',
    title: 'Full Macro Tracking',
    description: 'Track calories, protein, carbs, and fat with daily/weekly summaries.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['macros', 'calories', 'nutrition'],
  },
  {
    id: 'barcode-scanner',
    title: 'Barcode Scanner',
    description: 'Scan packaged foods for instant nutritional information with fuzzy fallback.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['barcode', 'scanning', 'quick'],
  },
  {
    id: 'cooked-food-converter',
    title: 'Cooked Food Converter',
    description: 'Convert raw ingredient weights to cooked portions automatically.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['cooking', 'conversion', 'portions'],
  },
  {
    id: 'frequent-foods',
    title: 'Frequent Foods Quick Log',
    description: 'Quick access to your most logged foods for faster meal tracking.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['quick', 'favorites', 'logging'],
  },
  {
    id: 'restaurant-help',
    title: 'Restaurant Menu Help',
    description: 'Get macro estimates for restaurant meals and menu items.',
    category: 'nutrition',
    tier: 'ultra',
    tags: ['restaurant', 'eating out', 'estimates'],
  },

  // Scheduling Features
  {
    id: 'smart-scheduling',
    title: 'Smart Scheduling',
    description: 'Weekly workout plans that adapt to your schedule with 1-7 day flexibility.',
    category: 'scheduling',
    tier: 'free',
    tags: ['schedule', 'planning', 'calendar'],
  },
  {
    id: 'missed-workout-rescheduling',
    title: 'Missed Workout Rescheduling',
    description: 'Reschedule missed workouts with smart suggestions and reason tracking.',
    category: 'scheduling',
    tier: 'premium',
    tags: ['reschedule', 'missed', 'flexibility'],
    isNew: true,
  },
  {
    id: 'quick-day-change',
    title: 'Quick Day Change',
    description: 'Change workout days in 2 taps without regenerating entire program.',
    category: 'scheduling',
    tier: 'free',
    tags: ['quick', 'days', 'flexibility'],
  },
  {
    id: 'rest-timers',
    title: 'Automatic Rest Timers',
    description: 'Optimized recovery timing between sets with customizable durations.',
    category: 'scheduling',
    tier: 'free',
    tags: ['rest', 'timers', 'recovery'],
  },

  // Injury Prevention Features
  {
    id: 'strain-prevention',
    title: '10% Rule Strain Prevention',
    description: 'Automatic enforcement of safe volume increases to prevent overuse injuries.',
    category: 'injury-prevention',
    tier: 'premium',
    tags: ['safety', 'strain', 'volume', 'prevention'],
    isNew: true,
  },
  {
    id: 'injury-tracking',
    title: 'Injury Tracking',
    description: 'Report injuries, track recovery, and get automatic workout modifications.',
    category: 'injury-prevention',
    tier: 'free',
    tags: ['injuries', 'recovery', 'tracking'],
  },
  {
    id: 'body-part-exclusion',
    title: 'Body Part Exclusion',
    description: 'Exclude injured body parts with automatic exercise filtering.',
    category: 'injury-prevention',
    tier: 'free',
    tags: ['exclusion', 'injuries', 'safety'],
  },
  {
    id: 'comeback-workouts',
    title: 'Comeback Workouts',
    description: 'Gradual intensity reduction after breaks with age-aware adjustments.',
    category: 'injury-prevention',
    tier: 'premium',
    tags: ['comeback', 'breaks', 'gradual'],
  },
  {
    id: 'fatigue-detection',
    title: 'Fatigue Detection',
    description: 'AI monitors rep decline and RPE patterns to suggest reducing sets.',
    category: 'injury-prevention',
    tier: 'premium',
    tags: ['fatigue', 'ai', 'monitoring'],
  },

  // Skill Progressions Features
  {
    id: 'skill-chains',
    title: '7 Skill Progression Chains',
    description: '52+ exercises from wall pushups to one-arm pushups, dead hang to muscle-ups.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['skills', 'progressions', 'calisthenics'],
    isPopular: true,
  },
  {
    id: 'leverage-progressions',
    title: 'Leverage-Based Progressions',
    description: 'Progress by exercise difficulty, not just adding reps.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['leverage', 'difficulty', 'progressions'],
  },
  {
    id: 'mastery-tracking',
    title: 'Exercise Mastery Tracking',
    description: 'Track mastery of exercises with automatic progression suggestions.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['mastery', 'tracking', 'suggestions'],
  },

  // Cardio Features
  {
    id: 'gradual-cardio',
    title: 'Gradual Cardio Progressions',
    description: 'Couch-to-5K style programs with run/walk intervals and strain detection.',
    category: 'cardio',
    tier: 'premium',
    tags: ['running', 'c25k', 'progressions'],
    isNew: true,
  },
  {
    id: 'cardio-session-logging',
    title: 'Cardio Session Logging',
    description: 'Track duration, distance, pace, heart rate, and location (indoor/outdoor/treadmill).',
    category: 'cardio',
    tier: 'free',
    tags: ['cardio', 'logging', 'tracking'],
  },
  {
    id: 'heart-rate-zones',
    title: 'Heart Rate Zone Training',
    description: 'Train in specific heart rate zones with real-time monitoring.',
    category: 'cardio',
    tier: 'premium',
    tags: ['heart rate', 'zones', 'training'],
  },

  // Accessibility Features
  {
    id: 'senior-mode',
    title: 'Senior Mode',
    description: 'Age-appropriate workouts with extended recovery, low-impact alternatives, and larger UI.',
    category: 'accessibility',
    tier: 'free',
    tags: ['senior', 'accessibility', 'age'],
    isPopular: true,
  },
  {
    id: 'age-based-scaling',
    title: 'Age-Based Workout Scaling',
    description: 'Automatic intensity and rest adjustments based on age (60-75+).',
    category: 'accessibility',
    tier: 'free',
    tags: ['age', 'scaling', 'intensity'],
  },
  {
    id: 'low-impact-alternatives',
    title: 'Low-Impact Alternatives',
    description: 'Automatic substitution of high-impact exercises for safer options.',
    category: 'accessibility',
    tier: 'free',
    tags: ['low-impact', 'alternatives', 'safety'],
  },
  {
    id: 'hormonal-health',
    title: 'Hormonal Health Tracking',
    description: 'Menstrual cycle tracking with cycle-aware workout intensity adjustments.',
    category: 'accessibility',
    tier: 'premium',
    tags: ['hormonal', 'cycle', 'women'],
  },

  // Gamification Features
  {
    id: 'achievement-badges',
    title: '30+ Achievement Badges',
    description: 'Earn badges across workout count, streaks, strength gains, and milestones.',
    category: 'gamification',
    tier: 'free',
    tags: ['achievements', 'badges', 'rewards'],
  },
  {
    id: 'tier-system',
    title: '5-Tier Achievement System',
    description: 'Bronze, Silver, Gold, Platinum, and Diamond tiers for each achievement category.',
    category: 'gamification',
    tier: 'free',
    tags: ['tiers', 'levels', 'progression'],
  },
  {
    id: 'roi-summary',
    title: 'ROI Summary Cards',
    description: 'See total workouts, hours invested, calories burned, and strength improvements.',
    category: 'gamification',
    tier: 'premium',
    tags: ['roi', 'summary', 'progress'],
  },
  {
    id: 'neat-system',
    title: 'NEAT Improvement System',
    description: 'Progressive step goals, hourly movement reminders, and 35+ activity achievements.',
    category: 'gamification',
    tier: 'premium',
    tags: ['neat', 'steps', 'activity', 'gamification'],
    isNew: true,
  },

  // Social Features
  {
    id: 'shareable-workouts',
    title: 'Shareable Workout Links',
    description: 'Share your workouts with friends via unique links.',
    category: 'social',
    tier: 'ultra',
    tags: ['share', 'social', 'links'],
  },
  {
    id: 'instagram-sharing',
    title: 'Instagram Story Sharing',
    description: 'Share achievements and workout summaries to Instagram stories.',
    category: 'social',
    tier: 'premium',
    tags: ['instagram', 'social', 'sharing'],
  },
  {
    id: 'leaderboards',
    title: 'Leaderboards',
    description: 'Compete with friends and the community on workout metrics.',
    category: 'social',
    tier: 'ultra',
    tags: ['leaderboards', 'competition', 'social'],
  },
  {
    id: 'friends-following',
    title: 'Friends & Following',
    description: 'Connect with friends and follow their fitness journey.',
    category: 'social',
    tier: 'ultra',
    tags: ['friends', 'following', 'social'],
  },

  // Trial & Demo Features
  {
    id: 'demo-day',
    title: '24-Hour Demo Day',
    description: 'Full app access for 24 hours on first install - no account required.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['demo', 'trial', 'free'],
    isPopular: true,
  },
  {
    id: 'plan-preview',
    title: 'Plan Preview Before Paywall',
    description: 'See your complete personalized 4-week plan before subscribing.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['preview', 'plan', 'transparency'],
  },
  {
    id: 'try-workout',
    title: 'Try One Workout Free',
    description: 'Complete one full workout from your plan before subscribing.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['try', 'workout', 'free'],
  },
  {
    id: 'app-tour',
    title: 'Interactive App Tour',
    description: 'Animated walkthrough of all app features accessible anytime.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['tour', 'guide', 'onboarding'],
  },
  {
    id: 'seven-day-trial',
    title: '7-Day Free Trial',
    description: 'Full premium access for 7 days on all subscription plans.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['trial', 'free', 'premium'],
  },

  // Subscription Features
  {
    id: 'subscription-pause',
    title: 'Subscription Pause',
    description: 'Pause your subscription for 1 week to 3 months with automatic resume.',
    category: 'subscription',
    tier: 'premium',
    tags: ['pause', 'subscription', 'flexibility'],
  },
  {
    id: 'retention-offers',
    title: 'Retention Offers',
    description: 'Get personalized offers like 50% off or free month before canceling.',
    category: 'subscription',
    tier: 'premium',
    tags: ['offers', 'discounts', 'retention'],
  },
  {
    id: 'lifetime-tiers',
    title: 'Lifetime Member Tiers',
    description: 'Veteran, Loyal, Established, and New tiers with increasing benefits.',
    category: 'subscription',
    tier: 'lifetime',
    tags: ['lifetime', 'tiers', 'benefits'],
  },
  {
    id: 'in-app-management',
    title: 'In-App Subscription Management',
    description: 'Manage your subscription without going to App Store.',
    category: 'subscription',
    tier: 'premium',
    tags: ['management', 'subscription', 'control'],
  },

  // Customization Features
  {
    id: 'sound-customization',
    title: 'Sound Customization',
    description: 'Choose countdown sounds, completion sounds, and volume levels.',
    category: 'customization',
    tier: 'free',
    tags: ['sound', 'audio', 'customization'],
  },
  {
    id: 'progression-pace',
    title: 'Progression Pace Settings',
    description: 'Choose your progression speed: extra cautious, gradual, balanced, or aggressive.',
    category: 'customization',
    tier: 'premium',
    tags: ['progression', 'pace', 'settings'],
  },
  {
    id: 'email-preferences',
    title: 'Email Preference Management',
    description: 'Control workout reminders, weekly summaries, coach tips, and promotional emails.',
    category: 'customization',
    tier: 'free',
    tags: ['email', 'preferences', 'notifications'],
  },

  // Integration Features
  {
    id: 'split-screen',
    title: 'Split Screen Support',
    description: 'Use the app alongside music apps in split screen mode on Android and iOS.',
    category: 'integration',
    tier: 'free',
    tags: ['split screen', 'multitasking', 'music'],
    isNew: true,
  },
  {
    id: 'background-music',
    title: 'Background Music Support',
    description: 'Play Spotify, Apple Music, or other apps while working out without interruption.',
    category: 'integration',
    tier: 'free',
    tags: ['music', 'spotify', 'background'],
    isPopular: true,
  },
  {
    id: 'audio-ducking',
    title: 'Audio Ducking',
    description: 'Automatically lower music volume during voice announcements.',
    category: 'integration',
    tier: 'free',
    tags: ['audio', 'ducking', 'music'],
  },
  {
    id: 'data-export',
    title: 'Data Export (CSV/PDF)',
    description: 'Export your workout history, progress data, and nutrition logs.',
    category: 'integration',
    tier: 'premium',
    tags: ['export', 'csv', 'pdf', 'data'],
  },

  // Branded Programs
  {
    id: 'branded-programs',
    title: '12+ Branded Programs',
    description: 'Ultimate Strength, Lean Machine, Power Builder, Beach Body Ready, and more.',
    category: 'workout',
    tier: 'free',
    tags: ['programs', 'branded', 'structured'],
    isNew: true,
    isPopular: true,
  },
  {
    id: 'program-customization',
    title: 'Program Name Customization',
    description: 'Rename programs and create custom named programs.',
    category: 'workout',
    tier: 'premium',
    tags: ['programs', 'customization', 'naming'],
  },

  // Calibration
  {
    id: 'calibration-workout',
    title: 'Strength Calibration Workout',
    description: 'Post-subscription assessment to validate your actual fitness level with AI analysis.',
    category: 'workout',
    tier: 'premium',
    tags: ['calibration', 'assessment', 'strength'],
    isNew: true,
  },
];

// Helper functions
export function getFeaturesByCategory(category: FeatureCategory): Feature[] {
  return features.filter(f => f.category === category);
}

export function getFeaturesByTier(tier: FeatureTier): Feature[] {
  if (tier === 'all') return features;
  return features.filter(f => f.tier === tier || f.tier === 'all');
}

export function searchFeatures(query: string): Feature[] {
  const lowerQuery = query.toLowerCase();
  return features.filter(f =>
    f.title.toLowerCase().includes(lowerQuery) ||
    f.description.toLowerCase().includes(lowerQuery) ||
    f.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
  );
}

export function getPopularFeatures(): Feature[] {
  return features.filter(f => f.isPopular);
}

export function getNewFeatures(): Feature[] {
  return features.filter(f => f.isNew);
}

export function getAllCategories(): FeatureCategory[] {
  return Object.keys(categoryLabels) as FeatureCategory[];
}
