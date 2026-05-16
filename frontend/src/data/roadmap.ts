// Curated content for the public /roadmap kanban board.
//
// This is the single source of truth for WHAT is on the roadmap. It is plain
// data so the board prerenders as static HTML (good for SEO / LLM citation).
// Dynamic state — vote counts + comments — lives in Postgres keyed by `slug`
// and hydrates client-side (see lib/roadmapApi.ts + migration 2078).
//
// Editing rules:
//  - `slug` is a STABLE key. Never rename one once it has votes/comments.
//  - Accepted entries from roadmap_suggestions get hand-added here.
//  - Released / Won't Do cards are not votable.

export type RoadmapColumnId =
  | 'under_consideration'
  | 'planned'
  | 'in_progress'
  | 'released'
  | 'wont_do';

export type RoadmapTag =
  | 'Workouts'
  | 'Nutrition'
  | 'AI Coach'
  | 'Tracking'
  | 'Social'
  | 'Platform'
  | 'Other';

export interface RoadmapFeature {
  slug: string;
  title: string;
  description: string;
  column: RoadmapColumnId;
  tags: RoadmapTag[];
  votable: boolean;
  /** Rough timing label, shown on planned / in-progress cards. */
  eta?: string;
  /** Honest reason, shown on Won't Do cards. */
  reason?: string;
}

export interface RoadmapColumnMeta {
  id: RoadmapColumnId;
  label: string;
  emoji: string;
  /** Accent color (works on light + dark) for the column's top rule. */
  accent: string;
  blurb: string;
}

export const ROADMAP_COLUMNS: RoadmapColumnMeta[] = [
  {
    id: 'under_consideration',
    label: 'Under Consideration',
    emoji: '💭',
    accent: '#94a3b8',
    blurb: 'Ideas we are weighing. Votes here directly shape what gets built next.',
  },
  {
    id: 'planned',
    label: 'Planned',
    emoji: '📌',
    accent: '#3b82f6',
    blurb: 'Committed and queued. Not started yet, but it is happening.',
  },
  {
    id: 'in_progress',
    label: 'In Progress',
    emoji: '🚧',
    accent: '#f59e0b',
    blurb: 'Actively being built right now.',
  },
  {
    id: 'released',
    label: 'Released',
    emoji: '✅',
    accent: '#10b981',
    blurb: 'Shipped and live in the app.',
  },
  {
    id: 'wont_do',
    label: "Won't Do",
    emoji: '🚫',
    accent: '#f43f5e',
    blurb: 'Things we have deliberately decided against — and why.',
  },
];

/** Tag chip colors — semi-transparent fill + solid text, theme-agnostic. */
export const TAG_COLORS: Record<RoadmapTag, { bg: string; text: string }> = {
  Workouts: { bg: 'rgba(16, 185, 129, 0.14)', text: 'rgb(5, 150, 105)' },
  Nutrition: { bg: 'rgba(249, 115, 22, 0.14)', text: 'rgb(234, 88, 12)' },
  'AI Coach': { bg: 'rgba(139, 92, 246, 0.14)', text: 'rgb(124, 58, 237)' },
  Tracking: { bg: 'rgba(56, 189, 248, 0.16)', text: 'rgb(2, 132, 199)' },
  Social: { bg: 'rgba(236, 72, 153, 0.14)', text: 'rgb(219, 39, 119)' },
  Platform: { bg: 'rgba(99, 102, 241, 0.14)', text: 'rgb(79, 70, 229)' },
  Other: { bg: 'rgba(148, 163, 184, 0.18)', text: 'rgb(71, 85, 105)' },
};

export const ROADMAP_TAGS: RoadmapTag[] = [
  'Workouts',
  'Nutrition',
  'AI Coach',
  'Tracking',
  'Social',
  'Platform',
  'Other',
];

// Ordered: within each column, the data order is the default "newest" order.
// The board re-sorts by live vote count when the sort toggle is set to votes.
export const ROADMAP_FEATURES: RoadmapFeature[] = [
  // ---- Released --------------------------------------------------------
  {
    slug: 'android-launch',
    title: 'Android launch',
    description:
      'Zealova is live on the Google Play Store — the full app, AI coach included.',
    column: 'released',
    tags: ['Platform'],
    votable: false,
  },
  {
    slug: 'ai-workout-plans',
    title: 'AI monthly workout plans',
    description:
      'Personalized month-long training plans generated from your goals, equipment, and history.',
    column: 'released',
    tags: ['Workouts', 'AI Coach'],
    votable: false,
  },
  {
    slug: 'food-photo-logging',
    title: 'Food photo logging',
    description:
      'Snap a meal — up to 10 photos, including mixed plates and buffets — and get calories and macros.',
    column: 'released',
    tags: ['Nutrition', 'AI Coach'],
    votable: false,
  },
  {
    slug: 'menu-scan',
    title: 'Menu scanning',
    description:
      'Photograph a restaurant menu and Zealova identifies the dishes with calorie and macro estimates.',
    column: 'released',
    tags: ['Nutrition'],
    votable: false,
  },
  {
    slug: 'multi-agent-coach',
    title: 'Multi-agent AI coach',
    description:
      'A chat coach backed by specialist agents for workouts, nutrition, injury, and hydration.',
    column: 'released',
    tags: ['AI Coach'],
    votable: false,
  },
  {
    slug: 'workout-export',
    title: 'Workout export — 10 formats',
    description:
      'Export your plans and logs to Hevy, Strong, Fitbod, CSV, JSON, PDF, and more. No lock-in.',
    column: 'released',
    tags: ['Workouts', 'Platform'],
    votable: false,
  },
  {
    slug: 'exercise-history',
    title: 'Per-exercise & per-muscle history',
    description:
      'Every set tracked and rolled up by exercise and by muscle group over time.',
    column: 'released',
    tags: ['Tracking', 'Workouts'],
    votable: false,
  },
  {
    slug: 'live-activity',
    title: 'iOS Live Activity',
    description:
      'Your active set and rest timer on the lock screen and Dynamic Island during a workout.',
    column: 'released',
    tags: ['Workouts', 'Platform'],
    votable: false,
  },

  // ---- In Progress -----------------------------------------------------
  {
    slug: 'ios-launch',
    title: 'iOS App Store launch',
    description:
      'Bringing the full Zealova experience to the App Store, right behind the Android release.',
    column: 'in_progress',
    tags: ['Platform'],
    votable: true,
    eta: 'Next',
  },
  {
    slug: 'form-check-video',
    title: 'Form check from video',
    description:
      'Upload a squat, bench, or deadlift clip and get rep-by-rep coaching grounded in NSCA / NASM cues.',
    column: 'in_progress',
    tags: ['Workouts', 'AI Coach'],
    votable: true,
    eta: 'Soon',
  },
  {
    slug: 'recipe-import',
    title: 'Recipe import',
    description:
      'Paste a recipe link or screenshot — Zealova extracts ingredients, scales portions, and logs it.',
    column: 'in_progress',
    tags: ['Nutrition'],
    votable: true,
    eta: 'Soon',
  },
  {
    slug: 'sharper-food-recognition',
    title: 'Sharper food recognition',
    description:
      'Better calorie and macro estimates on mixed plates, with an expanding international food database.',
    column: 'in_progress',
    tags: ['Nutrition', 'AI Coach'],
    votable: true,
    eta: 'Ongoing',
  },

  // ---- Planned ---------------------------------------------------------
  {
    slug: 'food-preferences',
    title: 'Food preferences profile',
    description:
      'Allergens, cooking skill, budget, and dietary restrictions feeding every AI meal suggestion.',
    column: 'planned',
    tags: ['Nutrition'],
    votable: true,
    eta: 'Q3 2026',
  },
  {
    slug: 'what-should-i-eat-widget',
    title: '"What should I eat?" widget',
    description:
      'One tap on your home screen for an AI meal idea with macros and a one-tap log button.',
    column: 'planned',
    tags: ['Nutrition', 'AI Coach'],
    votable: true,
    eta: 'Q3 2026',
  },
  {
    slug: 'ble-heart-rate',
    title: 'Bluetooth heart-rate support',
    description:
      'Pair BLE chest straps and HR monitors for live in-workout BPM, zones, and recovery insight.',
    column: 'planned',
    tags: ['Tracking', 'Workouts'],
    votable: true,
    eta: 'Q3 2026',
  },
  {
    slug: 'progress-analytics',
    title: 'Progress analytics & charts',
    description:
      'Strength and volume trends over time, plus a muscle heatmap of what you have trained.',
    column: 'planned',
    tags: ['Tracking'],
    votable: true,
    eta: 'Q3 2026',
  },
  {
    slug: 'home-screen-widgets',
    title: 'Home-screen widget suite',
    description:
      'Toggleable widgets: fitness score, daily stats, weight trend, macro rings, quick start.',
    column: 'planned',
    tags: ['Platform', 'Tracking'],
    votable: true,
    eta: 'Q4 2026',
  },
  {
    slug: 'recipe-discovery-feed',
    title: 'Recipe discovery feed',
    description:
      'Browse, save, and remix recipes shared by the community — ships alongside the social tab.',
    column: 'planned',
    tags: ['Nutrition', 'Social'],
    votable: true,
    eta: 'Q4 2026',
  },

  // ---- Under Consideration --------------------------------------------
  {
    slug: 'wearables-watch-app',
    title: 'Wear OS & Apple Watch app',
    description:
      'Log workouts, see rest timers, and track heart rate straight from your wrist.',
    column: 'under_consideration',
    tags: ['Platform', 'Workouts'],
    votable: true,
  },
  {
    slug: 'web-app',
    title: 'Web app',
    description: 'Plan and review your workouts and nutrition from any browser.',
    column: 'under_consideration',
    tags: ['Platform'],
    votable: true,
  },
  {
    slug: 'holistic-weekly-plan',
    title: 'Holistic weekly plan',
    description:
      'One weekly view blending workouts, nutrition, and hydration, with rest-day recovery tips.',
    column: 'under_consideration',
    tags: ['AI Coach', 'Workouts', 'Nutrition'],
    votable: true,
  },
  {
    slug: 'mood-aware-workouts',
    title: 'Mood-aware workouts',
    description:
      "A quick mood check-in that adapts the day's session — lighter when you're drained, harder when you're ready.",
    column: 'under_consideration',
    tags: ['AI Coach', 'Workouts'],
    votable: true,
  },
  {
    slug: 'custom-ai-coach',
    title: 'Custom AI coach personality',
    description: "Tune your coach's tone and style — gentle, blunt, or somewhere between.",
    column: 'under_consideration',
    tags: ['AI Coach'],
    votable: true,
  },
  {
    slug: 'ai-coach-audio',
    title: 'AI coach workout audio',
    description:
      'Real-time voice cues, exercise transitions, and PR celebrations during your session.',
    column: 'under_consideration',
    tags: ['AI Coach', 'Workouts'],
    votable: true,
  },
  {
    slug: 'recovery-score',
    title: 'Recovery & readiness score',
    description:
      'A daily readiness score from training load, rest, and logged volume — no new tracker needed.',
    column: 'under_consideration',
    tags: ['Tracking'],
    votable: true,
  },
  {
    slug: 'sleep-trend-analysis',
    title: 'Sleep trend analysis',
    description:
      'Track sleep patterns and see how they line up with your training performance.',
    column: 'under_consideration',
    tags: ['Tracking'],
    votable: true,
  },
  {
    slug: 'body-measurement-tracking',
    title: 'Body & measurement tracking',
    description:
      'Quick body measurements and before/after photo compare in one place.',
    column: 'under_consideration',
    tags: ['Tracking'],
    votable: true,
  },
  {
    slug: 'journey-roi',
    title: 'Journey & ROI view',
    description:
      'Your fitness journey over months and years — total workouts, time invested, milestones.',
    column: 'under_consideration',
    tags: ['Tracking'],
    votable: true,
  },
  {
    slug: 'social-challenges',
    title: 'Friends & challenges',
    description:
      'Opt-in challenges, leaderboards, and friend activity — never the default, always your choice.',
    column: 'under_consideration',
    tags: ['Social'],
    votable: true,
  },
  {
    slug: 'branded-programs',
    title: 'Structured training programs',
    description: 'Follow proven multi-week programs instead of a fully generated plan.',
    column: 'under_consideration',
    tags: ['Workouts'],
    votable: true,
  },
  {
    slug: 'event-based-training',
    title: 'Event-based training',
    description: 'Train for a marathon, Hyrox, or a specific event with a goal-dated plan.',
    column: 'under_consideration',
    tags: ['Workouts'],
    votable: true,
  },
  {
    slug: 'restaurant-chain-menus',
    title: 'Restaurant chain menus',
    description:
      'Built-in nutrition for popular restaurant chains so eating out is one tap to log.',
    column: 'under_consideration',
    tags: ['Nutrition'],
    votable: true,
  },
  {
    slug: 'coach-companion-app',
    title: 'Coach companion app',
    description:
      'A trainer-side product where coaches build and assign programs to their clients.',
    column: 'under_consideration',
    tags: ['Platform'],
    votable: true,
  },
  {
    slug: 'more-languages',
    title: 'More languages',
    description: 'Full Zealova in more languages beyond English.',
    column: 'under_consideration',
    tags: ['Platform', 'Other'],
    votable: true,
  },

  // ---- Won't Do --------------------------------------------------------
  {
    slug: 'merch-store',
    title: 'Branded merch store',
    description: 'Selling shirts and shakers.',
    column: 'wont_do',
    tags: ['Other'],
    votable: false,
    reason: "Not our focus — Zealova is a coaching app, not a storefront.",
  },
  {
    slug: 'public-social-feed',
    title: 'Public social feed',
    description: 'An infinite scrolling feed of strangers’ workouts.',
    column: 'wont_do',
    tags: ['Social'],
    votable: false,
    reason: 'Opt-in challenges and friend activity, yes. An attention-farming feed, no.',
  },
  {
    slug: 'body-comp-ai',
    title: 'Body-fat % from a photo',
    description: 'Estimating body composition from a progress photo.',
    column: 'wont_do',
    tags: ['Tracking'],
    votable: false,
    reason: "The accuracy bar isn't met. We won't show a number we can't stand behind.",
  },
  {
    slug: 'step-calorie-estimates',
    title: 'Calorie burn from phone steps',
    description: 'Estimating calories burned purely from phone step counts.',
    column: 'wont_do',
    tags: ['Tracking'],
    votable: false,
    reason: 'Too inaccurate to base real decisions on — it would mislead more than it helps.',
  },
  {
    slug: 'ad-supported-tier',
    title: 'Ad-supported free tier',
    description: 'Funding a free tier with in-app advertising.',
    column: 'wont_do',
    tags: ['Other'],
    votable: false,
    reason: "We won't sell your attention. The free web tools stay free, without ads.",
  },
];

/** Lookup a feature by slug — used by the drawer + deep links. */
export function getFeatureBySlug(slug: string): RoadmapFeature | undefined {
  return ROADMAP_FEATURES.find((f) => f.slug === slug);
}
