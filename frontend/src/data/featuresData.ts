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
  | 'integration'
  | 'fasting'
  | 'hydration'
  | 'habits'
  | 'photos-body'
  | 'notifications'
  | 'settings'
  | 'support'
  | 'widgets'
  | 'health-devices'
  | 'diabetes'
  | 'hormonal-health';

export type FeatureTier = 'free' | 'premium' | 'premium_plus' | 'lifetime' | 'all';

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
  'fasting': 'Intermittent Fasting',
  'hydration': 'Hydration Tracking',
  'habits': 'Habit Tracking',
  'photos-body': 'Progress Photos & Body',
  'notifications': 'Notifications',
  'settings': 'Settings',
  'support': 'Customer Support',
  'widgets': 'Home Screen Widgets',
  'health-devices': 'Health Devices',
  'diabetes': 'Diabetes Management',
  'hormonal-health': 'Hormonal Health',
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
  'fasting': 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z',
  'hydration': 'M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418',
  'habits': 'M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  'photos-body': 'M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z',
  'notifications': 'M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0',
  'settings': 'M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z',
  'support': 'M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z',
  'widgets': 'M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z',
  'health-devices': 'M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z',
  'diabetes': 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z',
  'hormonal-health': 'M15.182 15.182a4.5 4.5 0 01-6.364 0M21 12a9 9 0 11-18 0 9 9 0 0118 0zM9.75 9.75c0 .414-.168.75-.375.75S9 10.164 9 9.75 9.168 9 9.375 9s.375.336.375.75zm-.375 0h.008v.015h-.008V9.75zm5.625 0c0 .414-.168.75-.375.75s-.375-.336-.375-.75.168-.75.375-.75.375.336.375.75zm-.375 0h.008v.015h-.008V9.75z',
};

export const features: Feature[] = [
  // ==========================================
  // WORKOUT GENERATION & MANAGEMENT FEATURES
  // ==========================================
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
    tier: 'premium_plus',
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
  {
    id: 'branded-programs',
    title: '12+ Branded Programs',
    description: 'Ultimate Strength, Lean Machine, Power Builder, Beach Body Ready, and more pre-built programs.',
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
  {
    id: 'calibration-workout',
    title: 'Strength Calibration Workout',
    description: 'Post-subscription assessment to validate your actual fitness level with AI analysis.',
    category: 'workout',
    tier: 'premium',
    tags: ['calibration', 'assessment', 'strength'],
    isNew: true,
  },
  {
    id: 'exercise-countdown-timer',
    title: 'Exercise Countdown Timer',
    description: 'Transition timers between exercises with voice announcements and countdown alerts.',
    category: 'workout',
    tier: 'free',
    tags: ['timer', 'countdown', 'transitions'],
  },
  {
    id: 'rest-period-timer',
    title: 'Rest Period Timer',
    description: 'Automatic rest timers between sets with customizable durations and audio alerts.',
    category: 'workout',
    tier: 'free',
    tags: ['rest', 'timer', 'recovery'],
  },
  {
    id: 'exercise-swap',
    title: 'Exercise Swap During Workout',
    description: 'Swap exercises mid-workout with AI-suggested alternatives or library search.',
    category: 'workout',
    tier: 'free',
    tags: ['swap', 'alternatives', 'flexibility'],
  },
  {
    id: 'workout-feedback',
    title: 'Post-Exercise Feedback',
    description: 'Rate exercises as too easy, just right, or too hard to improve future recommendations.',
    category: 'workout',
    tier: 'free',
    tags: ['feedback', 'ratings', 'personalization'],
  },
  {
    id: 'actual-reps-logging',
    title: 'Actual Reps Logging',
    description: 'Log the reps you actually completed vs planned for accurate tracking.',
    category: 'workout',
    tier: 'free',
    tags: ['logging', 'reps', 'tracking'],
  },
  {
    id: 'weight-tracking',
    title: 'Weight Tracking Per Set',
    description: 'Log weight used for each set with AI weight suggestions based on history.',
    category: 'workout',
    tier: 'free',
    tags: ['weight', 'tracking', 'progressive-overload'],
  },
  {
    id: 'quick-regenerate',
    title: 'Quick Regenerate Workouts',
    description: 'One-tap regeneration of workouts using current settings without wizard.',
    category: 'workout',
    tier: 'premium',
    tags: ['regenerate', 'quick', 'convenience'],
  },
  {
    id: 'workout-notes',
    title: 'Workout Notes',
    description: 'Add notes to individual exercises or entire workout sessions.',
    category: 'workout',
    tier: 'free',
    tags: ['notes', 'logging', 'journal'],
  },
  {
    id: 'superset-support',
    title: 'Superset & Circuit Support',
    description: 'Create and manage supersets, circuits, and compound exercise groupings.',
    category: 'workout',
    tier: 'premium',
    tags: ['superset', 'circuit', 'advanced'],
  },
  {
    id: 'workout-share',
    title: 'Share Workout Completion',
    description: 'Share workout summaries to social media with stats and achievements.',
    category: 'workout',
    tier: 'free',
    tags: ['share', 'social', 'summary'],
  },

  // ==========================================
  // AI COACH FEATURES
  // ==========================================
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
    description: 'Access your chat history - 7 days free, 90 days premium, forever for premium plus/lifetime.',
    category: 'ai-coach',
    tier: 'all',
    tags: ['history', 'chat', 'memory'],
  },
  {
    id: 'multi-agent-routing',
    title: 'Multi-Agent AI Routing',
    description: 'Automatic routing to specialized agents: Coach, Nutrition, Workout, Injury, Hydration.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['agents', 'routing', 'specialized'],
    isNew: true,
  },
  {
    id: 'specialized-knowledge',
    title: 'Specialized Fitness Knowledge',
    description: 'Your coach has deep expertise across nutrition, workouts, injury prevention, and hydration - all in one conversation.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['expertise', 'knowledge', 'comprehensive'],
  },
  {
    id: 'streaming-responses',
    title: 'Streaming AI Responses',
    description: 'Real-time token streaming for faster AI response display.',
    category: 'ai-coach',
    tier: 'free',
    tags: ['streaming', 'real-time', 'fast'],
  },
  {
    id: 'chat-to-action',
    title: 'Chat-to-Action Commands',
    description: 'Execute app actions directly from chat like starting workouts or logging meals.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['actions', 'commands', 'integration'],
  },
  {
    id: 'ai-persona-selection',
    title: 'AI Persona Selection',
    description: 'Choose your AI coach personality style for personalized interactions.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['persona', 'personality', 'customization'],
  },
  {
    id: 'quick-workout-from-chat',
    title: 'Generate Workout from Chat',
    description: 'Ask AI to generate a quick workout and start it immediately from chat.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['generate', 'quick', 'chat'],
  },
  {
    id: 'nutrition-logging-chat',
    title: 'Log Meals via Chat',
    description: 'Describe your meal in natural language and AI logs the nutrition.',
    category: 'ai-coach',
    tier: 'premium',
    tags: ['nutrition', 'logging', 'natural-language'],
  },

  // ==========================================
  // EXERCISE LIBRARY FEATURES
  // ==========================================
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
  {
    id: 'exercise-videos',
    title: 'HD Video Demonstrations',
    description: 'High-quality video demos for every exercise with proper form guidance.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['videos', 'form', 'demonstrations'],
  },
  {
    id: 'exercise-favorites',
    title: 'Favorite Exercises',
    description: 'Mark exercises as favorites for AI to prioritize in workout generation.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['favorites', 'preferences', 'personalization'],
  },
  {
    id: 'exercise-queue',
    title: 'Exercise Queue',
    description: 'Queue specific exercises to be included in your next workout.',
    category: 'exercise-library',
    tier: 'premium',
    tags: ['queue', 'planning', 'customization'],
  },
  {
    id: 'staple-exercises',
    title: 'Staple Exercises',
    description: 'Mark core lifts like Squat, Bench, Deadlift that never rotate out of your program.',
    category: 'exercise-library',
    tier: 'premium',
    tags: ['staples', 'core-lifts', 'consistency'],
  },
  {
    id: 'exercises-to-avoid',
    title: 'Exercises to Avoid',
    description: 'Mark exercises to skip due to injury or preference with safe alternatives.',
    category: 'exercise-library',
    tier: 'free',
    tags: ['avoid', 'injury', 'safety'],
  },
  {
    id: 'custom-exercises',
    title: 'Custom Exercises',
    description: 'Create and add your own custom exercises to the library.',
    category: 'exercise-library',
    tier: 'premium',
    tags: ['custom', 'create', 'personalization'],
  },
  {
    id: 'offline-videos',
    title: 'Offline Video Cache',
    description: '500MB LRU cache for offline exercise video access.',
    category: 'exercise-library',
    tier: 'premium',
    tags: ['offline', 'cache', 'videos'],
  },

  // ==========================================
  // PROGRESS & ANALYTICS FEATURES
  // ==========================================
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
    tier: 'premium_plus',
    tags: ['muscles', 'heatmap', 'balance', 'analytics'],
  },
  {
    id: 'overall-fitness-score',
    title: 'Overall Fitness Score',
    description: 'Combined 0-100 score from strength, consistency, nutrition, and readiness.',
    category: 'progress',
    tier: 'premium',
    tags: ['score', 'fitness', 'comprehensive'],
  },
  {
    id: 'strength-score',
    title: 'Strength Score',
    description: 'Score based on workout performance and progressive overload achievements.',
    category: 'progress',
    tier: 'premium',
    tags: ['strength', 'score', 'performance'],
  },
  {
    id: 'nutrition-score',
    title: 'Nutrition Score',
    description: 'Weekly nutrition adherence score based on logging, calories, protein, and health.',
    category: 'progress',
    tier: 'premium',
    tags: ['nutrition', 'score', 'adherence'],
  },
  {
    id: 'consistency-score',
    title: 'Consistency Score',
    description: 'Workout completion rate percentage over time.',
    category: 'progress',
    tier: 'premium',
    tags: ['consistency', 'score', 'completion'],
  },
  {
    id: 'exercise-progression-charts',
    title: 'Exercise Progression Charts',
    description: 'Line charts showing max weight, volume, and estimated 1RM trends per exercise.',
    category: 'progress',
    tier: 'premium',
    tags: ['charts', 'exercise', '1rm'],
  },
  {
    id: 'muscle-heatmap',
    title: 'Muscle Training Heatmap',
    description: 'Body diagram showing training intensity for each muscle group with colors.',
    category: 'progress',
    tier: 'premium_plus',
    tags: ['heatmap', 'muscles', 'visualization'],
  },
  {
    id: 'muscle-balance',
    title: 'Muscle Balance Analysis',
    description: 'Push/pull ratio, upper/lower ratio, and overall balance score.',
    category: 'progress',
    tier: 'premium_plus',
    tags: ['balance', 'muscles', 'ratio'],
  },
  {
    id: 'estimated-1rm',
    title: 'Estimated 1RM Calculation',
    description: 'Automatic calculation of one-rep max using the Epley formula.',
    category: 'progress',
    tier: 'premium',
    tags: ['1rm', 'calculation', 'strength'],
  },
  {
    id: 'weekly-summary',
    title: 'Weekly Summary Reports',
    description: 'End-of-week recap with AI-generated insights and recommendations.',
    category: 'progress',
    tier: 'premium',
    tags: ['summary', 'weekly', 'insights'],
  },

  // ==========================================
  // NUTRITION TRACKING FEATURES
  // ==========================================
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
    description: 'Convert raw ingredient weights to cooked portions with 55+ food support.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['cooking', 'conversion', 'portions'],
  },
  {
    id: 'frequent-foods',
    title: 'Frequent Foods Quick Log',
    description: 'One-tap re-logging of your most frequently eaten foods.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['quick', 'favorites', 'logging'],
  },
  {
    id: 'restaurant-help',
    title: 'Restaurant Menu Help',
    description: 'Get min/mid/max calorie estimates for restaurant meals.',
    category: 'nutrition',
    tier: 'premium_plus',
    tags: ['restaurant', 'eating out', 'estimates'],
  },
  {
    id: 'micronutrient-tracking',
    title: '40+ Micronutrient Tracking',
    description: 'Track vitamins, minerals, and fatty acids with three-tier goals.',
    category: 'nutrition',
    tier: 'premium_plus',
    tags: ['micronutrients', 'vitamins', 'minerals'],
  },
  {
    id: 'recipe-builder',
    title: 'Recipe Builder',
    description: 'Create custom recipes with automatic per-serving nutrition calculations.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['recipes', 'custom', 'cooking'],
  },
  {
    id: 'ai-recipes',
    title: 'AI-Generated Recipes',
    description: 'Get personalized recipe suggestions based on body type, culture, and diet.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['ai', 'recipes', 'personalized'],
    isNew: true,
  },
  {
    id: 'diet-types',
    title: '12 Diet Type Support',
    description: 'Vegetarian, vegan, keto, flexitarian, pescatarian, and more diet types.',
    category: 'nutrition',
    tier: 'free',
    tags: ['diet', 'vegetarian', 'vegan', 'keto'],
  },
  {
    id: 'cuisine-preferences',
    title: '20+ Cuisine Preferences',
    description: 'Indian, Italian, Mexican, Japanese, and more cuisines for recipe suggestions.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['cuisine', 'cultural', 'preferences'],
  },
  {
    id: 'inflammation-scanner',
    title: 'Ingredient Inflammation Analysis',
    description: 'AI-powered barcode ingredient analysis for inflammatory properties.',
    category: 'nutrition',
    tier: 'premium_plus',
    tags: ['inflammation', 'ingredients', 'health'],
    isNew: true,
  },
  {
    id: 'calm-mode',
    title: 'Calm Mode',
    description: 'Hide calorie numbers and focus on food quality instead.',
    category: 'nutrition',
    tier: 'free',
    tags: ['mental-health', 'calm', 'quality'],
  },
  {
    id: 'food-mood',
    title: 'Food-Mood Tracking',
    description: 'Log how you feel after meals to identify food sensitivities.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['mood', 'feelings', 'sensitivity'],
  },
  {
    id: 'tdee-calculation',
    title: 'Adaptive TDEE Calculation',
    description: 'Weekly recalculation of Total Daily Energy Expenditure based on data.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['tdee', 'calories', 'metabolism'],
  },
  {
    id: 'training-day-calories',
    title: 'Training Day Calories',
    description: 'Automatically higher calorie targets on workout days.',
    category: 'nutrition',
    tier: 'premium',
    tags: ['calories', 'workout', 'adjustment'],
  },

  // ==========================================
  // INTERMITTENT FASTING FEATURES
  // ==========================================
  {
    id: 'fasting-timer',
    title: 'Fasting Timer',
    description: 'Start/stop fasting timer with circular dial and metabolic zone tracking.',
    category: 'fasting',
    tier: 'free',
    tags: ['timer', 'fasting', 'tracking'],
    isPopular: true,
  },
  {
    id: 'fasting-protocols',
    title: '10+ Fasting Protocols',
    description: '12:12, 14:10, 16:8, 18:6, 20:4, OMAD, 5:2, ADF, and extended fasts.',
    category: 'fasting',
    tier: 'free',
    tags: ['protocols', 'intermittent', 'fasting'],
  },
  {
    id: 'metabolic-zones',
    title: 'Metabolic Zone Tracking',
    description: 'Track Fed, Fat Burning, Ketosis, and Deep Ketosis zones.',
    category: 'fasting',
    tier: 'premium',
    tags: ['zones', 'ketosis', 'metabolism'],
  },
  {
    id: 'fasting-streaks',
    title: 'Fasting Streaks',
    description: 'Track consecutive successful fasts with streak freeze option.',
    category: 'fasting',
    tier: 'free',
    tags: ['streaks', 'consistency', 'motivation'],
  },
  {
    id: 'fasting-safety',
    title: 'Fasting Safety Screening',
    description: '6 health questions with risk assessment and warning popups.',
    category: 'fasting',
    tier: 'free',
    tags: ['safety', 'health', 'screening'],
  },
  {
    id: 'fasting-impact',
    title: 'Fasting Impact Analysis',
    description: 'Analyze how fasting affects weight, goals, and workout performance.',
    category: 'fasting',
    tier: 'premium',
    tags: ['impact', 'analysis', 'correlation'],
    isNew: true,
  },
  {
    id: 'fasting-calendar',
    title: 'Fasting Calendar View',
    description: 'Calendar showing fasting days, weight logs, and workouts per day.',
    category: 'fasting',
    tier: 'premium',
    tags: ['calendar', 'history', 'visualization'],
  },
  {
    id: 'eating-window-timer',
    title: 'Eating Window Timer',
    description: 'Countdown timer to eating window close with notifications.',
    category: 'fasting',
    tier: 'free',
    tags: ['eating', 'window', 'timer'],
  },
  {
    id: 'smart-meal-detection',
    title: 'Smart Meal Detection',
    description: 'Auto-end fast when logging food during fasting window.',
    category: 'fasting',
    tier: 'premium',
    tags: ['smart', 'detection', 'automation'],
  },
  {
    id: 'fasting-ai-insights',
    title: 'AI Fasting Insights',
    description: 'Gemini-generated personalized insights about your fasting impact.',
    category: 'fasting',
    tier: 'premium',
    tags: ['ai', 'insights', 'personalized'],
  },

  // ==========================================
  // HYDRATION FEATURES
  // ==========================================
  {
    id: 'water-goal',
    title: 'Daily Water Goal',
    description: 'Customizable daily water intake target with progress tracking.',
    category: 'hydration',
    tier: 'free',
    tags: ['water', 'goal', 'tracking'],
  },
  {
    id: 'quick-water-log',
    title: 'Quick Water Logging',
    description: '8oz, 16oz, and custom amount quick add buttons.',
    category: 'hydration',
    tier: 'free',
    tags: ['quick', 'logging', 'water'],
  },
  {
    id: 'drink-types',
    title: 'Multiple Drink Types',
    description: 'Track water, protein shakes, coffee, and other beverages.',
    category: 'hydration',
    tier: 'free',
    tags: ['drinks', 'variety', 'tracking'],
  },

  // ==========================================
  // HABIT TRACKING FEATURES
  // ==========================================
  {
    id: 'habit-dashboard',
    title: 'Habit Dashboard',
    description: 'Main screen showing today\'s habits with progress indicators.',
    category: 'habits',
    tier: 'free',
    tags: ['dashboard', 'habits', 'progress'],
    isNew: true,
  },
  {
    id: 'positive-habits',
    title: 'Positive Habit Tracking',
    description: 'Track habits to build like drink water, meditate, exercise.',
    category: 'habits',
    tier: 'free',
    tags: ['positive', 'building', 'habits'],
  },
  {
    id: 'negative-habits',
    title: 'Negative Habit Breaking',
    description: 'Track habits to break like no DoorDash, no sugar, no alcohol.',
    category: 'habits',
    tier: 'free',
    tags: ['negative', 'breaking', 'habits'],
  },
  {
    id: 'habit-streaks',
    title: 'Habit Streak Tracking',
    description: 'Current and best streak tracking with auto-reset on missed days.',
    category: 'habits',
    tier: 'free',
    tags: ['streaks', 'consistency', 'tracking'],
  },
  {
    id: 'habit-templates',
    title: '16+ Habit Templates',
    description: 'Pre-built habits like water, steps, meditate, no sugar for quick setup.',
    category: 'habits',
    tier: 'free',
    tags: ['templates', 'quick', 'prebuilt'],
  },
  {
    id: 'custom-habits',
    title: 'Custom Habit Creation',
    description: 'Create habits with custom name, icon, color, and target.',
    category: 'habits',
    tier: 'free',
    tags: ['custom', 'create', 'personalization'],
  },
  {
    id: 'habit-reminders',
    title: 'Habit Reminders',
    description: 'Set reminder times for each individual habit.',
    category: 'habits',
    tier: 'free',
    tags: ['reminders', 'notifications', 'habits'],
  },
  {
    id: 'ai-habit-suggestions',
    title: 'AI Habit Suggestions',
    description: 'Gemini suggests habits based on your fitness goals.',
    category: 'habits',
    tier: 'premium',
    tags: ['ai', 'suggestions', 'personalized'],
  },

  // ==========================================
  // PROGRESS PHOTOS & BODY TRACKING
  // ==========================================
  {
    id: 'progress-photos',
    title: 'Progress Photo Capture',
    description: 'Take and store front, side, and back view progress photos.',
    category: 'photos-body',
    tier: 'free',
    tags: ['photos', 'progress', 'capture'],
  },
  {
    id: 'before-after',
    title: 'Before/After Comparison',
    description: 'Side-by-side photo comparison with date and weight overlay.',
    category: 'photos-body',
    tier: 'premium',
    tags: ['comparison', 'before-after', 'visualization'],
  },
  {
    id: 'body-measurements',
    title: '15 Body Measurements',
    description: 'Track chest, waist, arms, legs, and more measurement points.',
    category: 'photos-body',
    tier: 'free',
    tags: ['measurements', 'body', 'tracking'],
  },
  {
    id: 'weight-logging',
    title: 'Weight Logging',
    description: 'Track weight over time with trend smoothing and analysis.',
    category: 'photos-body',
    tier: 'free',
    tags: ['weight', 'logging', 'trends'],
  },
  {
    id: 'body-fat-tracking',
    title: 'Body Fat Percentage',
    description: 'Track body composition changes over time.',
    category: 'photos-body',
    tier: 'premium',
    tags: ['body-fat', 'composition', 'tracking'],
  },
  {
    id: 'photo-editor',
    title: 'Photo Editor',
    description: 'Crop photos and add FitWiz logo overlay.',
    category: 'photos-body',
    tier: 'free',
    tags: ['editor', 'crop', 'customize'],
  },
  {
    id: 'measurement-graphs',
    title: 'Measurement Trend Graphs',
    description: 'Visual charts of all measurement trends over time.',
    category: 'photos-body',
    tier: 'premium',
    tags: ['graphs', 'trends', 'visualization'],
  },

  // ==========================================
  // SCHEDULING FEATURES
  // ==========================================
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
  {
    id: 'weekly-calendar',
    title: 'Weekly Calendar View',
    description: '7-day grid view with workout/rest day indicators.',
    category: 'scheduling',
    tier: 'free',
    tags: ['calendar', 'weekly', 'view'],
  },
  {
    id: 'agenda-view',
    title: 'Agenda View',
    description: 'List view of upcoming workouts with completion status.',
    category: 'scheduling',
    tier: 'free',
    tags: ['agenda', 'list', 'upcoming'],
  },

  // ==========================================
  // INJURY PREVENTION FEATURES
  // ==========================================
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
  {
    id: 'muscles-to-avoid',
    title: 'Muscles to Avoid',
    description: 'Skip or reduce exercises targeting specific muscle groups.',
    category: 'injury-prevention',
    tier: 'free',
    tags: ['muscles', 'avoid', 'safety'],
  },
  {
    id: 'temporary-avoidance',
    title: 'Temporary Avoidance',
    description: 'Set end date for temporary exercise/muscle avoidances.',
    category: 'injury-prevention',
    tier: 'premium',
    tags: ['temporary', 'recovery', 'timeline'],
  },
  {
    id: 'safe-substitutes',
    title: 'Safe Substitute Suggestions',
    description: 'View injury-safe alternatives when avoiding exercises.',
    category: 'injury-prevention',
    tier: 'premium',
    tags: ['substitutes', 'alternatives', 'safe'],
  },

  // ==========================================
  // SKILL PROGRESSIONS FEATURES
  // ==========================================
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
  {
    id: 'unlock-criteria',
    title: 'Unlock Criteria System',
    description: 'Each progression step has specific rep/hold/session requirements to unlock.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['unlock', 'criteria', 'requirements'],
  },
  {
    id: 'skill-tree',
    title: 'Visual Skill Tree',
    description: 'Browse progression chains with visual locked/unlocked step display.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['visual', 'tree', 'progress'],
  },
  {
    id: 'rep-range-preferences',
    title: 'Rep Range Preferences',
    description: 'Set preferred training focus: Strength 4-6, Hypertrophy 8-12, Endurance 15+.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['rep-range', 'preferences', 'training'],
  },
  {
    id: 'avoid-high-reps',
    title: 'Avoid High-Rep Toggle',
    description: 'When enabled, caps all exercises at 12 reps maximum.',
    category: 'skill-progressions',
    tier: 'premium',
    tags: ['high-reps', 'cap', 'preference'],
  },

  // ==========================================
  // CARDIO & ENDURANCE FEATURES
  // ==========================================
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
  {
    id: 'treadmill-annotation',
    title: 'Treadmill Run Annotation',
    description: 'Mark runs as indoor/outdoor/treadmill for accurate tracking.',
    category: 'cardio',
    tier: 'free',
    tags: ['treadmill', 'indoor', 'annotation'],
  },

  // ==========================================
  // ACCESSIBILITY FEATURES
  // ==========================================
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
    id: 'large-touch-targets',
    title: 'Large Touch Targets',
    description: 'Bigger buttons and touch areas for easier interaction.',
    category: 'accessibility',
    tier: 'free',
    tags: ['touch', 'large', 'accessibility'],
  },
  {
    id: 'high-contrast',
    title: 'High Contrast Mode',
    description: 'Improved visibility with high contrast color scheme.',
    category: 'accessibility',
    tier: 'free',
    tags: ['contrast', 'visibility', 'accessibility'],
  },
  {
    id: 'text-size',
    title: 'Adjustable Text Size',
    description: 'Customize text size for better readability.',
    category: 'accessibility',
    tier: 'free',
    tags: ['text', 'size', 'readability'],
  },
  {
    id: 'reduced-motion',
    title: 'Reduced Motion',
    description: 'Fewer animations for users sensitive to motion.',
    category: 'accessibility',
    tier: 'free',
    tags: ['motion', 'animations', 'accessibility'],
  },
  {
    id: 'voiceover-support',
    title: 'VoiceOver/TalkBack Support',
    description: 'Screen reader compatibility for visually impaired users.',
    category: 'accessibility',
    tier: 'free',
    tags: ['voiceover', 'talkback', 'screen-reader'],
  },

  // ==========================================
  // HORMONAL HEALTH FEATURES
  // ==========================================
  {
    id: 'hormonal-health',
    title: 'Hormonal Health Tracking',
    description: 'Menstrual cycle tracking with cycle-aware workout intensity adjustments.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['hormonal', 'cycle', 'women'],
    isNew: true,
  },
  {
    id: 'menstrual-cycle-tracking',
    title: 'Menstrual Cycle Tracking',
    description: 'Log period dates with automatic cycle phase calculation.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['menstrual', 'cycle', 'tracking'],
  },
  {
    id: 'cycle-aware-workouts',
    title: 'Cycle-Aware Workouts',
    description: 'AI adjusts workout intensity based on menstrual/follicular/ovulation/luteal phases.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['cycle', 'workouts', 'adaptation'],
  },
  {
    id: 'symptom-tracking',
    title: 'Symptom Tracking',
    description: 'Log fatigue, cramps, mood swings, bloating with AI adjustments.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['symptoms', 'tracking', 'adjustment'],
  },
  {
    id: 'kegel-exercises',
    title: '16 Kegel Exercises',
    description: 'Pelvic floor training with male/female-specific exercises and tracking.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['kegel', 'pelvic', 'exercises'],
    isNew: true,
  },
  {
    id: 'hormonal-diet',
    title: 'Hormonal Diet Recommendations',
    description: '50+ hormone-supportive foods for testosterone, estrogen, PCOS, menopause.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['diet', 'hormones', 'nutrition'],
  },
  {
    id: 'cycle-phase-nutrition',
    title: 'Cycle Phase Nutrition',
    description: 'Phase-specific food recommendations for menstrual, follicular, ovulation, luteal.',
    category: 'hormonal-health',
    tier: 'premium',
    tags: ['cycle', 'nutrition', 'phases'],
  },

  // ==========================================
  // GAMIFICATION FEATURES
  // ==========================================
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
  {
    id: 'weekly-goals',
    title: 'Weekly Personal Goals',
    description: 'Set goals like "How many push-ups can I do?" or "500 push-ups this week".',
    category: 'gamification',
    tier: 'free',
    tags: ['goals', 'weekly', 'challenges'],
  },
  {
    id: 'goal-leaderboard',
    title: 'Goal Leaderboard',
    description: 'Compare with friends on the same weekly goals.',
    category: 'gamification',
    tier: 'premium',
    tags: ['leaderboard', 'friends', 'competition'],
  },

  // ==========================================
  // SOCIAL FEATURES
  // ==========================================
  {
    id: 'activity-feed',
    title: 'Activity Feed',
    description: 'See workout posts from friends with likes and comments.',
    category: 'social',
    tier: 'premium',
    tags: ['feed', 'activity', 'social'],
  },
  {
    id: 'friend-system',
    title: 'Friend System',
    description: 'Find, add, and manage friends with request system.',
    category: 'social',
    tier: 'premium',
    tags: ['friends', 'connections', 'social'],
  },
  {
    id: 'challenges',
    title: 'Fitness Challenges',
    description: 'Create and join volume, reps, or workout challenges with friends.',
    category: 'social',
    tier: 'premium',
    tags: ['challenges', 'competition', 'friends'],
  },
  {
    id: 'leaderboards',
    title: 'Leaderboards',
    description: 'Global and friends-only weekly, monthly, all-time rankings.',
    category: 'social',
    tier: 'premium_plus',
    tags: ['leaderboards', 'competition', 'rankings'],
  },
  {
    id: 'shareable-workouts',
    title: 'Shareable Workout Links',
    description: 'Share your workouts with friends via unique links.',
    category: 'social',
    tier: 'premium_plus',
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
    id: 'emoji-reactions',
    title: 'Emoji Reactions',
    description: '5 reaction types on posts from friends.',
    category: 'social',
    tier: 'premium',
    tags: ['reactions', 'emoji', 'engagement'],
  },
  {
    id: 'feature-voting',
    title: 'Feature Voting System',
    description: 'Upvote and suggest new features for the app.',
    category: 'social',
    tier: 'free',
    tags: ['voting', 'features', 'community'],
  },

  // ==========================================
  // TRIAL & DEMO FEATURES
  // ==========================================
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
    title: 'Try 3 Workouts Free',
    description: 'Complete 3 full workouts from your plan before subscribing.',
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
  {
    id: 'guest-preview',
    title: '10-Minute Guest Preview',
    description: 'Guest session with limited home screen, 20 exercises, sample workouts.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['guest', 'preview', 'demo'],
  },
  {
    id: 'pricing-preview',
    title: 'Pre-Auth Pricing Preview',
    description: 'See all pricing tiers before creating an account.',
    category: 'trial-demo',
    tier: 'free',
    tags: ['pricing', 'preview', 'transparency'],
  },

  // ==========================================
  // SUBSCRIPTION FEATURES
  // ==========================================
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
    description: 'Manage, pause, or cancel subscription without going to App Store.',
    category: 'subscription',
    tier: 'premium',
    tags: ['management', 'subscription', 'control'],
  },
  {
    id: 'subscription-history',
    title: 'Subscription History',
    description: 'Timeline view of all subscription changes, upgrades, downgrades.',
    category: 'subscription',
    tier: 'premium',
    tags: ['history', 'timeline', 'changes'],
  },
  {
    id: 'renewal-reminders',
    title: 'Renewal Reminder Notifications',
    description: 'Push notifications 5 days and 1 day before renewal.',
    category: 'subscription',
    tier: 'premium',
    tags: ['renewal', 'reminders', 'notifications'],
  },
  {
    id: 'refund-request',
    title: 'In-App Refund Request',
    description: 'Submit refund requests with reason selection and tracking ID.',
    category: 'subscription',
    tier: 'premium',
    tags: ['refund', 'request', 'support'],
  },
  {
    id: 'feature-comparison',
    title: 'Tier Feature Comparison',
    description: 'Side-by-side comparison of Free, Premium, Premium Plus, and Lifetime features.',
    category: 'subscription',
    tier: 'free',
    tags: ['comparison', 'tiers', 'features'],
  },

  // ==========================================
  // CUSTOMIZATION FEATURES
  // ==========================================
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
  {
    id: 'theme-selector',
    title: 'Theme Selector',
    description: 'Light, Dark, or Auto theme based on system settings.',
    category: 'customization',
    tier: 'free',
    tags: ['theme', 'dark-mode', 'appearance'],
  },
  {
    id: 'haptic-feedback',
    title: 'Haptic Feedback Settings',
    description: 'Enable/disable vibration with light, medium, strong intensity options.',
    category: 'customization',
    tier: 'free',
    tags: ['haptic', 'vibration', 'feedback'],
  },
  {
    id: 'coaching-style',
    title: 'AI Coaching Style',
    description: 'Choose encouraging, scientific, motivational, or casual coaching tone.',
    category: 'customization',
    tier: 'premium',
    tags: ['coaching', 'style', 'personality'],
  },
  {
    id: 'weekly-variation',
    title: 'Weekly Variation Slider',
    description: 'Control exercise variety from 0-100% (default 30%).',
    category: 'customization',
    tier: 'premium',
    tags: ['variation', 'variety', 'exercises'],
  },
  {
    id: 'warmup-duration',
    title: 'Warmup Duration Setting',
    description: 'Set preferred warmup length from 1-15 minutes.',
    category: 'customization',
    tier: 'free',
    tags: ['warmup', 'duration', 'setting'],
  },
  {
    id: 'stretch-duration',
    title: 'Stretch Duration Setting',
    description: 'Set preferred post-workout stretch length from 1-15 minutes.',
    category: 'customization',
    tier: 'free',
    tags: ['stretch', 'cooldown', 'duration'],
  },

  // ==========================================
  // INTEGRATION FEATURES
  // ==========================================
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
  {
    id: 'apple-health',
    title: 'Apple HealthKit Sync',
    description: 'Sync workouts, steps, calories, and body metrics with Apple Health.',
    category: 'integration',
    tier: 'free',
    tags: ['apple', 'health', 'sync'],
  },
  {
    id: 'health-connect',
    title: 'Health Connect (Android)',
    description: 'Sync with Android Health Connect for unified health data.',
    category: 'integration',
    tier: 'free',
    tags: ['android', 'health', 'sync'],
  },

  // ==========================================
  // HEALTH DEVICE FEATURES
  // ==========================================
  {
    id: 'step-tracking',
    title: 'Daily Step Count',
    description: 'Read and sync daily step count from health apps.',
    category: 'health-devices',
    tier: 'free',
    tags: ['steps', 'tracking', 'health'],
  },
  {
    id: 'heart-rate-sync',
    title: 'Heart Rate & HRV Sync',
    description: 'Read heart rate and heart rate variability from wearables.',
    category: 'health-devices',
    tier: 'premium',
    tags: ['heart-rate', 'hrv', 'wearables'],
  },
  {
    id: 'body-metrics-sync',
    title: 'Body Metrics Sync',
    description: 'Sync weight, body fat, and BMI from smart scales.',
    category: 'health-devices',
    tier: 'premium',
    tags: ['weight', 'body-fat', 'scales'],
  },
  {
    id: 'workout-write-back',
    title: 'Workout Write-Back',
    description: 'Sync completed workouts back to Apple Health and Health Connect.',
    category: 'health-devices',
    tier: 'free',
    tags: ['sync', 'workouts', 'write'],
  },

  // ==========================================
  // DIABETES MANAGEMENT FEATURES
  // ==========================================
  {
    id: 'glucose-tracking',
    title: 'Blood Glucose Tracking',
    description: 'Log glucose readings with meal context and color-coded status.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['glucose', 'diabetes', 'tracking'],
    isNew: true,
  },
  {
    id: 'insulin-logging',
    title: 'Insulin Dose Logging',
    description: 'Log rapid and long-acting insulin doses with history.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['insulin', 'logging', 'diabetes'],
  },
  {
    id: 'a1c-tracking',
    title: 'A1C Tracking',
    description: 'Log lab A1C results and calculate estimated A1C from readings.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['a1c', 'tracking', 'diabetes'],
  },
  {
    id: 'carb-counting',
    title: 'Carbohydrate Counting',
    description: 'Track carb intake by meal with daily totals.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['carbs', 'counting', 'diabetes'],
  },
  {
    id: 'cgm-integration',
    title: 'CGM Device Integration',
    description: 'Sync with Dexcom, Libre, and Medtronic continuous glucose monitors.',
    category: 'diabetes',
    tier: 'premium_plus',
    tags: ['cgm', 'integration', 'devices'],
  },
  {
    id: 'time-in-range',
    title: 'Time In Range Analysis',
    description: 'Calculate percentage of time in, below, and above target range.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['time-in-range', 'analysis', 'glucose'],
  },
  {
    id: 'pre-workout-glucose',
    title: 'Pre-Workout Glucose Check',
    description: 'Assess glucose safety before starting exercise.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['pre-workout', 'glucose', 'safety'],
  },
  {
    id: 'diabetes-ai-coach',
    title: 'Diabetes AI Coach',
    description: 'AI coaching with diabetes-aware recommendations and insights.',
    category: 'diabetes',
    tier: 'premium',
    tags: ['ai', 'coach', 'diabetes'],
  },

  // ==========================================
  // NOTIFICATION FEATURES
  // ==========================================
  {
    id: 'workout-reminders',
    title: 'Workout Reminders',
    description: 'Scheduled push notifications for upcoming workouts.',
    category: 'notifications',
    tier: 'free',
    tags: ['reminders', 'workouts', 'push'],
  },
  {
    id: 'nutrition-reminders',
    title: 'Nutrition Reminders',
    description: 'Breakfast, lunch, and dinner logging reminders.',
    category: 'notifications',
    tier: 'free',
    tags: ['reminders', 'nutrition', 'meals'],
  },
  {
    id: 'streak-alerts',
    title: 'Streak Alerts',
    description: 'Don\'t break your streak reminder notifications.',
    category: 'notifications',
    tier: 'free',
    tags: ['streak', 'alerts', 'reminders'],
  },
  {
    id: 'quiet-hours',
    title: 'Quiet Hours',
    description: 'Do not disturb time range for notifications.',
    category: 'notifications',
    tier: 'free',
    tags: ['quiet', 'dnd', 'schedule'],
  },
  {
    id: 'social-notifications',
    title: 'Social Notifications',
    description: 'Friend activity, likes, and comment notifications.',
    category: 'notifications',
    tier: 'premium',
    tags: ['social', 'friends', 'notifications'],
  },
  {
    id: 'challenge-notifications',
    title: 'Challenge Notifications',
    description: 'Real-time updates on challenge progress.',
    category: 'notifications',
    tier: 'premium',
    tags: ['challenges', 'updates', 'notifications'],
  },

  // ==========================================
  // SETTINGS FEATURES
  // ==========================================
  {
    id: 'ai-settings',
    title: 'AI Settings Screen',
    description: 'Dedicated configuration for AI coaching style, tone, and agents.',
    category: 'settings',
    tier: 'premium',
    tags: ['ai', 'settings', 'configuration'],
  },
  {
    id: 'environment-management',
    title: '8 Workout Environments',
    description: 'Configure equipment for gym, home, outdoor, hotel, and more.',
    category: 'settings',
    tier: 'free',
    tags: ['environments', 'equipment', 'locations'],
  },
  {
    id: 'equipment-quantities',
    title: 'Equipment Quantities',
    description: 'Set quantity and weight ranges per equipment piece.',
    category: 'settings',
    tier: 'free',
    tags: ['equipment', 'quantities', 'weights'],
  },
  {
    id: 'custom-equipment',
    title: 'Custom Equipment',
    description: 'Add your own custom equipment to environments.',
    category: 'settings',
    tier: 'premium',
    tags: ['custom', 'equipment', 'personalization'],
  },
  {
    id: 'ai-settings-search',
    title: 'AI-Powered Settings Search',
    description: 'Natural language search to find settings quickly.',
    category: 'settings',
    tier: 'free',
    tags: ['search', 'ai', 'settings'],
  },
  {
    id: 'delete-account',
    title: 'Delete Account',
    description: 'Permanently remove your account and all data.',
    category: 'settings',
    tier: 'free',
    tags: ['delete', 'account', 'privacy'],
  },
  {
    id: 'data-privacy',
    title: 'Privacy Controls',
    description: 'Control profile visibility and data sharing settings.',
    category: 'settings',
    tier: 'free',
    tags: ['privacy', 'visibility', 'data'],
  },

  // ==========================================
  // CUSTOMER SUPPORT FEATURES
  // ==========================================
  {
    id: 'support-tickets',
    title: 'Support Ticket System',
    description: 'Create, view, and track support tickets with unique IDs.',
    category: 'support',
    tier: 'free',
    tags: ['tickets', 'support', 'help'],
  },
  {
    id: 'ticket-categories',
    title: 'Ticket Categories',
    description: 'Billing, Technical, Account, Feature Request, Other categories.',
    category: 'support',
    tier: 'free',
    tags: ['categories', 'tickets', 'organization'],
  },
  {
    id: 'live-chat-support',
    title: 'Live Chat Support',
    description: 'Real-time chat with human support agents in-app.',
    category: 'support',
    tier: 'premium',
    tags: ['live-chat', 'human', 'support'],
    isNew: true,
  },
  {
    id: 'ai-to-human-handoff',
    title: 'AI-to-Human Handoff',
    description: 'Escalate from AI coach to human support with conversation context.',
    category: 'support',
    tier: 'premium',
    tags: ['escalate', 'human', 'handoff'],
  },
  {
    id: 'message-reporting',
    title: 'In-Chat Message Reporting',
    description: 'Long-press AI messages to report problems directly.',
    category: 'support',
    tier: 'free',
    tags: ['report', 'messages', 'feedback'],
  },
  {
    id: 'faq',
    title: 'FAQ Section',
    description: 'Frequently asked questions accessible in settings.',
    category: 'support',
    tier: 'free',
    tags: ['faq', 'help', 'questions'],
  },

  // ==========================================
  // HOME SCREEN WIDGETS
  // ==========================================
  {
    id: 'workout-widget',
    title: 'Today\'s Workout Widget',
    description: 'Home screen widget for quick workout access.',
    category: 'widgets',
    tier: 'free',
    tags: ['widget', 'workout', 'quick'],
  },
  {
    id: 'goals-widget',
    title: 'Personal Goals Widget',
    description: 'Widget showing weekly goal progress.',
    category: 'widgets',
    tier: 'premium',
    tags: ['widget', 'goals', 'progress'],
  },
  {
    id: 'widget-deep-links',
    title: 'Widget Deep Links',
    description: 'Tap widgets to navigate directly to app screens.',
    category: 'widgets',
    tier: 'free',
    tags: ['deep-links', 'navigation', 'widgets'],
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
