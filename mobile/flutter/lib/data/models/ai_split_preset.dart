/// AI Split Preset model for workout program templates
/// Combines research-backed splits with AI-powered special modes
class AISplitPreset {
  final String id;
  final String name;
  final int daysPerWeek;
  final String duration;
  final List<String> difficulty;
  final double hypertrophyScore;
  final String description;
  final List<String> schedule;
  final List<String> benefits;
  final String? warning;
  final bool isAIPowered;
  final Map<String, dynamic>? aiParams;
  final String? imageAsset;
  final String category; // classic, ai_powered, specialty

  const AISplitPreset({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    required this.duration,
    required this.difficulty,
    required this.hypertrophyScore,
    required this.description,
    required this.schedule,
    required this.benefits,
    this.warning,
    this.isAIPowered = false,
    this.aiParams,
    this.imageAsset,
    required this.category,
  });

  /// Get the training split value for API requests
  String get trainingSplitValue {
    switch (id) {
      case 'full_body':
      case 'full_body_minimal':
        return 'full_body';
      case 'upper_lower':
      case 'upper_lower_full':
        return 'upper_lower';
      case 'ppl_3day':
      case 'ppl_6day':
        return 'push_pull_legs';
      case 'pplul':
        return 'pplul';
      case 'phul':
        return 'phul';
      case 'arnold_split':
        return 'arnold_split';
      case 'bro_split':
        return 'body_part';
      default:
        return 'full_body';
    }
  }
}

/// All available AI Split Presets
/// Organized by category: Classic Splits, AI-Powered, Specialty
const List<AISplitPreset> aiSplitPresets = [
  // ═══════════════════════════════════════════════════════════════
  // CLASSIC SPLITS (Research-Backed)
  // ═══════════════════════════════════════════════════════════════

  // --- BEGINNER FRIENDLY ---
  AISplitPreset(
    id: 'full_body',
    name: 'Full Body',
    daysPerWeek: 3,
    duration: '45-60 min',
    difficulty: ['Beginner', 'Intermediate'],
    hypertrophyScore: 7.5,
    description:
        'Train every muscle 3x/week. Research shows 50% better strength gains vs 1x/week. Perfect for beginners.',
    schedule: ['Mon: Full Body A', 'Wed: Full Body B', 'Fri: Full Body C'],
    benefits: [
      'Maximum frequency',
      'Learn compound lifts',
      'Fast progress for beginners'
    ],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'full_body_minimal',
    name: 'Full Body (Minimal)',
    daysPerWeek: 2,
    duration: '60-90 min',
    difficulty: ['Beginner'],
    hypertrophyScore: 6.0,
    description:
        'For busy schedules. Hit all muscles twice per week with efficient compound movements.',
    schedule: ['Mon: Full Body A', 'Thu: Full Body B'],
    benefits: ['Time efficient', 'Maintains muscle', 'Good for busy people'],
    category: 'classic',
  ),

  // --- INTERMEDIATE ---
  AISplitPreset(
    id: 'upper_lower',
    name: 'Upper, Lower',
    daysPerWeek: 4,
    duration: '50-75 min',
    difficulty: ['Beginner', 'Intermediate'],
    hypertrophyScore: 8.4,
    description:
        '85% of max gains with 30% less gym time. Each muscle trained 2x/week with optimal recovery.',
    schedule: ['Mon: Upper', 'Tue: Lower', 'Thu: Upper', 'Fri: Lower'],
    benefits: ['Great recovery', 'High frequency', 'Balanced growth'],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'ppl_3day',
    name: 'Push, Pull, Legs',
    daysPerWeek: 3,
    duration: '45-60 min',
    difficulty: ['Beginner', 'Intermediate', 'Advanced'],
    hypertrophyScore: 7.8,
    description:
        'The most popular split. Groups muscles by movement pattern for efficient training.',
    schedule: ['Mon: Push', 'Wed: Pull', 'Fri: Legs'],
    benefits: ['Simple structure', 'Prevents overlap', 'Flexible scheduling'],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'phul',
    name: 'PHUL',
    daysPerWeek: 4,
    duration: '60-75 min',
    difficulty: ['Intermediate'],
    hypertrophyScore: 8.6,
    description:
        'Power Hypertrophy Upper Lower. Best of both worlds: 2 power days + 2 hypertrophy days.',
    schedule: [
      'Mon: Upper Power',
      'Tue: Lower Power',
      'Thu: Upper Hypertrophy',
      'Fri: Lower Hypertrophy'
    ],
    benefits: ['Strength + size', 'Varied rep ranges', 'Powerbuilding'],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'upper_lower_full',
    name: 'Upper, Lower, Full Body',
    daysPerWeek: 3,
    duration: '45-75 min',
    difficulty: ['Intermediate'],
    hypertrophyScore: 7.9,
    description:
        'Hybrid approach combining the best of both worlds for balanced development.',
    schedule: ['Mon: Upper', 'Wed: Lower', 'Fri: Full Body'],
    benefits: ['Flexibility', '2x frequency', 'Balanced volume'],
    category: 'classic',
  ),

  // --- INTERMEDIATE-ADVANCED ---
  AISplitPreset(
    id: 'pplul',
    name: 'PPLUL (5-Day Hybrid)',
    daysPerWeek: 5,
    duration: '45-60 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 9.0,
    description:
        'Combines PPL + Upper/Lower. More volume than 4-day without 6-day commitment. Optimal for gains.',
    schedule: ['Mon: Push', 'Tue: Pull', 'Wed: Legs', 'Thu: Upper', 'Fri: Lower'],
    benefits: ['High volume', '2x frequency', 'Best hybrid'],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'ppl_6day',
    name: 'Push, Pull, Legs (6-Day)',
    daysPerWeek: 6,
    duration: '45-60 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 9.7,
    description:
        'Maximum hypertrophy. Each muscle 2x/week with high volume. For serious lifters.',
    schedule: [
      'Mon: Push',
      'Tue: Pull',
      'Wed: Legs',
      'Thu: Push',
      'Fri: Pull',
      'Sat: Legs'
    ],
    benefits: ['Maximum volume', 'Highest hypertrophy score', 'Serious gains'],
    category: 'classic',
  ),

  // --- ADVANCED ---
  AISplitPreset(
    id: 'arnold_split',
    name: 'Arnold Split',
    daysPerWeek: 6,
    duration: '60-90 min',
    difficulty: ['Advanced'],
    hypertrophyScore: 8.8,
    description:
        "Arnold Schwarzenegger's legendary split. Chest/Back, Shoulders/Arms, Legs - twice per week.",
    schedule: [
      'Mon: Chest+Back',
      'Tue: Shoulders+Arms',
      'Wed: Legs',
      'Thu: Chest+Back',
      'Fri: Shoulders+Arms',
      'Sat: Legs'
    ],
    benefits: [
      'Antagonist supersets',
      'Fresh shoulders/arms',
      'Classic bodybuilding'
    ],
    category: 'classic',
  ),

  AISplitPreset(
    id: 'bro_split',
    name: 'Bro Split',
    daysPerWeek: 5,
    duration: '30-45 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 6.5,
    description:
        'Classic bodybuilding split. One muscle per day with maximum volume per session.',
    schedule: ['Mon: Chest', 'Tue: Back', 'Wed: Shoulders', 'Thu: Arms', 'Fri: Legs'],
    benefits: ['Maximum pump', 'Simple focus', 'Short sessions'],
    category: 'classic',
  ),

  // --- SPECIALTY ---
  AISplitPreset(
    id: 'lower_focused',
    name: 'Lower Focused + Upper',
    daysPerWeek: 3,
    duration: '45-60 min',
    difficulty: ['Beginner', 'Intermediate'],
    hypertrophyScore: 7.5,
    description:
        'Extra leg volume for those wanting bigger legs. 2 leg days + 1 upper day.',
    schedule: ['Mon: Lower', 'Wed: Upper', 'Fri: Lower'],
    benefits: ['Leg emphasis', 'Glute development', 'Athletic base'],
    category: 'specialty',
  ),

  AISplitPreset(
    id: 'chest_back_focus',
    name: 'Chest & Back Focus',
    daysPerWeek: 4,
    duration: '45-60 min',
    difficulty: ['Intermediate'],
    hypertrophyScore: 7.8,
    description:
        'Upper body emphasis with extra chest and back volume. Legs maintained.',
    schedule: [
      'Mon: Chest+Triceps',
      'Tue: Back+Biceps',
      'Thu: Shoulders+Legs',
      'Fri: Chest+Back'
    ],
    benefits: ['V-taper focus', 'Upper body priority', 'Aesthetic goals'],
    category: 'specialty',
  ),

  // ═══════════════════════════════════════════════════════════════
  // AI-POWERED SPECIAL PRESETS (Unique to FitWiz)
  // ═══════════════════════════════════════════════════════════════

  AISplitPreset(
    id: 'hell_week',
    name: 'Hell Week',
    daysPerWeek: 6,
    duration: '60-90 min',
    difficulty: ['Advanced', 'Elite'],
    hypertrophyScore: 10.0,
    isAIPowered: true,
    aiParams: {
      'intensity_preference': 'hell',
      'min_sets': 5,
      'progressive_overload': 'aggressive',
    },
    description:
        'Maximum intensity. Uses HELL MODE exercises with 5+ sets, aggressive weights. Not for the faint-hearted.',
    schedule: ['Mon-Sat: Hell Mode workouts', 'Sun: Active Recovery'],
    benefits: ['Extreme challenge', 'Mental toughness', 'Plateau breaker'],
    warning: 'Requires advanced experience. High injury risk if form breaks.',
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'ai_adaptive',
    name: 'AI Adaptive',
    daysPerWeek: 4,
    duration: '45-60 min',
    difficulty: ['All Levels'],
    hypertrophyScore: 8.5,
    isAIPowered: true,
    aiParams: {
      'adaptive_mode': true,
      'uses_workout_history': true,
      'auto_progression': true,
    },
    description:
        'AI learns your progress and auto-adjusts. Gets harder as you get stronger. The smartest way to train.',
    schedule: ['AI determines optimal training days'],
    benefits: [
      'Personalized progression',
      'Prevents plateaus',
      'Learns your limits'
    ],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'quick_gains',
    name: 'Quick Gains',
    daysPerWeek: 3,
    duration: '30-40 min',
    difficulty: ['Beginner', 'Intermediate'],
    hypertrophyScore: 7.0,
    isAIPowered: true,
    aiParams: {
      'duration_minutes_max': 40,
      'compound_focus': true,
      'supersets_enabled': true,
    },
    description:
        'Maximum results in minimum time. Supersets and compound movements only. Perfect for busy schedules.',
    schedule: ['Mon: Full A', 'Wed: Full B', 'Fri: Full C'],
    benefits: ['Time efficient', 'High intensity', 'No fluff'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'home_warrior',
    name: 'Home Warrior',
    daysPerWeek: 5,
    duration: '30-45 min',
    difficulty: ['All Levels'],
    hypertrophyScore: 7.5,
    isAIPowered: true,
    aiParams: {
      'workout_environment': 'home',
      'equipment': ['dumbbells', 'resistance_bands', 'pull_up_bar'],
      'bodyweight_priority': true,
    },
    description:
        'No gym? No problem. AI creates killer workouts with minimal equipment.',
    schedule: ['Mon-Fri: Home workouts', 'Sat-Sun: Active rest'],
    benefits: ['No gym needed', 'Minimal equipment', 'Flexible timing'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'deload_recover',
    name: 'Deload & Recover',
    daysPerWeek: 3,
    duration: '30-40 min',
    difficulty: ['All Levels'],
    hypertrophyScore: 4.0,
    isAIPowered: true,
    aiParams: {
      'intensity_preference': 'easy',
      'max_rpe': 6,
      'focus': 'recovery',
      'mobility_included': true,
    },
    description:
        'Strategic recovery week. Lower intensity, focus on form and mobility. Use every 4-6 weeks.',
    schedule: ['Mon: Light Upper', 'Wed: Light Lower', 'Fri: Mobility'],
    benefits: ['Prevents overtraining', 'Joint recovery', 'Mental reset'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'strength_builder',
    name: 'Strength Builder',
    daysPerWeek: 4,
    duration: '60-75 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 7.8,
    isAIPowered: true,
    aiParams: {
      'primary_goal': 'muscle_strength',
      'rep_range': '3-6',
      'rest_seconds_min': 180,
      'compound_priority': true,
    },
    description:
        'Pure strength focus. Heavy weights, low reps, long rest. Build raw power.',
    schedule: ['Mon: Squat', 'Tue: Bench', 'Thu: Deadlift', 'Fri: OHP'],
    benefits: ['Maximum strength', 'CNS adaptation', 'Power development'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'mood_based',
    name: 'Mood-Based',
    daysPerWeek: 0, // Flexible
    duration: '30-60 min',
    difficulty: ['All Levels'],
    hypertrophyScore: 7.0,
    isAIPowered: true,
    aiParams: {
      'mood_based': true,
      'energy_adaptive': true,
      'no_fixed_schedule': true,
    },
    description:
        'Train when you feel like it. AI adapts to your energy and mood each day.',
    schedule: ['Flexible - based on daily mood/energy'],
    benefits: ['No pressure', 'Sustainable', 'Prevents burnout'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'hybrid_athlete',
    name: 'Hybrid Athlete',
    daysPerWeek: 5,
    duration: '45-60 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 8.0,
    isAIPowered: true,
    aiParams: {
      'workout_type': 'mixed',
      'cardio_included': true,
      'strength_cardio_balance': 0.6, // 60% strength, 40% cardio
    },
    description:
        'Best of both worlds. Build muscle AND endurance. Perfect for functional fitness.',
    schedule: [
      'Mon: Strength',
      'Tue: Cardio',
      'Wed: Strength',
      'Thu: HIIT',
      'Fri: Full Body'
    ],
    benefits: ['Well-rounded fitness', 'Athletic performance', 'Heart health'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'weak_point_destroyer',
    name: 'Weak Point Destroyer',
    daysPerWeek: 4,
    duration: '45-60 min',
    difficulty: ['Intermediate', 'Advanced'],
    hypertrophyScore: 8.2,
    isAIPowered: true,
    aiParams: {
      'uses_muscle_focus_points': true,
      'lagging_muscle_priority': true,
      'extra_volume_weak_points': true,
    },
    description:
        'AI identifies your lagging muscles and creates a plan to bring them up.',
    schedule: ['Prioritizes your weak points with extra volume'],
    benefits: ['Balanced physique', 'Fixes imbalances', 'Targeted growth'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'senior_strength',
    name: 'Senior Strength',
    daysPerWeek: 3,
    duration: '40-50 min',
    difficulty: ['Beginner'],
    hypertrophyScore: 6.0,
    isAIPowered: true,
    aiParams: {
      'age_appropriate': true,
      'low_impact': true,
      'joint_friendly': true,
      'balance_focus': true,
    },
    description:
        'Safe, effective training for 50+. Joint-friendly movements with balance work.',
    schedule: ['Mon: Upper', 'Wed: Lower', 'Fri: Full Body'],
    benefits: ['Joint health', 'Bone density', 'Functional strength'],
    category: 'ai_powered',
  ),

  AISplitPreset(
    id: 'comeback_program',
    name: 'Comeback Program',
    daysPerWeek: 3,
    duration: '30-45 min',
    difficulty: ['Beginner', 'Intermediate'],
    hypertrophyScore: 6.5,
    isAIPowered: true,
    aiParams: {
      'comeback_mode': true,
      'gradual_progression': true,
      'injury_prevention_focus': true,
      'weeks_to_full_intensity': 4,
    },
    description:
        'Been away from the gym? This 4-week program safely rebuilds your base.',
    schedule: ['Gradual 4-week ramp-up to full intensity'],
    benefits: ['Safe return', 'Prevents injury', 'Rebuilds work capacity'],
    category: 'ai_powered',
  ),
];

/// Get presets by category
List<AISplitPreset> getPresetsByCategory(String category) {
  return aiSplitPresets.where((p) => p.category == category).toList();
}

/// Get classic splits only
List<AISplitPreset> get classicSplits => getPresetsByCategory('classic');

/// Get AI-powered presets only
List<AISplitPreset> get aiPoweredPresets => getPresetsByCategory('ai_powered');

/// Get specialty presets only
List<AISplitPreset> get specialtyPresets => getPresetsByCategory('specialty');

/// Get preset by ID
AISplitPreset? getPresetById(String id) {
  try {
    return aiSplitPresets.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

/// Get presets filtered by difficulty
List<AISplitPreset> getPresetsForDifficulty(String difficulty) {
  return aiSplitPresets
      .where((p) =>
          p.difficulty.contains(difficulty) ||
          p.difficulty.contains('All Levels'))
      .toList();
}

/// Get presets filtered by days per week
List<AISplitPreset> getPresetsForDays(int days) {
  return aiSplitPresets
      .where((p) => p.daysPerWeek == days || p.daysPerWeek == 0)
      .toList();
}
