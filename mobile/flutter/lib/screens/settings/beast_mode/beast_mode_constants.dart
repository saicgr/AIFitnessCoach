import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Resolved theme colors passed to every Beast Mode widget.
class BeastThemeData {
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final Color cardBorder;

  const BeastThemeData({
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    required this.cardBorder,
  });

  factory BeastThemeData.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BeastThemeData(
      isDark: isDark,
      textPrimary: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
      textMuted: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
      elevated: isDark ? AppColors.elevated : AppColorsLight.elevated,
      cardBorder: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}

/// Shared constants for the Beast Mode feature.

// ─── Scoring factor colors ──────────────────────────────────

const kScoringColors = <String, Color>{
  'Freshness': Color(0xFF3B82F6),
  'Staple': Color(0xFF22C55E),
  'Known Data': Color(0xFFA855F7),
  'Collaborative': Color(0xFF14B8A6),
  'SFR': Color(0xFFF59E0B),
  'Random': Color(0xFF71717A),
};

// ─── Bias dropdown options for mood multipliers ─────────────

const kBiasOptions = <String>[
  'Compound',
  'Machine',
  'Cardio',
  'Balanced',
  'PR Push',
  'Isolation',
];

// ─── Default recovery rates from MuscleRecoveryTracker ──────

const kDefaultRecoveryRates = <String, double>{
  'calves': 0.083,
  'abs': 0.083,
  'obliques': 0.083,
  'forearms': 0.083,
  'shoulders': 0.063,
  'traps': 0.063,
  'biceps': 0.063,
  'triceps': 0.063,
  'chest': 0.042,
  'back': 0.042,
  'quads': 0.042,
  'hamstrings': 0.042,
  'glutes': 0.042,
};

// ─── AI model library ───────────────────────────────────────

/// Tuple: (name, size, ramReq, tier)
const kAiModels = <(String, String, String, String)>[
  ('Gemma 3 270M', '270 MB', '1 GB RAM', 'Basic'),
  ('Gemma 3 1B', '1.0 GB', '2 GB RAM', 'Standard'),
  ('Gemma 3n E2B', '2.0 GB', '4 GB RAM', 'Standard'),
  ('Gemma 3n E4B', '4.0 GB', '6 GB RAM', 'Optimal'),
  ('EmbeddingGemma 300M', '300 MB', '1 GB RAM', 'Basic'),
];

// ─── Difficulty tier colors ─────────────────────────────────

const kTierColors = <String, Color>{
  'Easy': Color(0xFF22C55E), // AppColors.success
  'Medium': Color(0xFFF59E0B), // AppColors.warning
  'Hard': Color(0xFFFF6B00), // AppColors.orange
  'Hell': Color(0xFFEF4444), // AppColors.error
};

// ─── SharedPreferences keys ─────────────────────────────────

const kPrefFreshnessDecay = 'beast_freshness_decay';
const kPrefRecoveryKPrefix = 'beast_recovery_k_';
const kPrefModelUnloadMinutes = 'beast_model_unload_minutes';
const kPrefGenerationModeOverride = 'beast_generation_mode_override';
const kPrefDeviceCapabilityOverride = 'beast_device_capability_override';

// ─── Choice option maps ─────────────────────────────────────

const kUnloadOptions = <int, String>{
  1: '1 min',
  5: '5 min',
  15: '15 min',
  0: 'Never',
};

const kGenerationModeOptions = <String, String>{
  'auto': 'Auto',
  'cloud': 'Cloud',
  'on_device': 'On-Device',
  'rule_based': 'Rule-Based',
};

const kDeviceCapabilityOptions = <String, String>{
  'auto': 'Auto',
  'basic': 'Basic',
  'standard': 'Standard',
  'optimal': 'Optimal',
};

const kRestTimerModes = <String, String>{
  'fixed': 'Fixed',
  'auto_scaled': 'Auto-Scaled',
  'rpe_based': 'RPE-Based',
  'custom': 'Custom',
};

const kProgressionModels = <String, String>{
  'linear': 'Linear',
  'step': 'Step',
  'undulating': 'Undulating',
  'custom': 'Custom',
};

const kRpePromptModes = <String, String>{
  'per_set': 'Per Set',
  'per_exercise': 'Per Exercise',
};

// ─── Recovery muscle groups ─────────────────────────────────

const kRecoveryGroups = <String, List<String>>{
  'Fast (~12h)': ['calves', 'abs', 'obliques', 'forearms'],
  'Medium (~16h)': ['shoulders', 'traps', 'biceps', 'triceps'],
  'Slow (~24h)': ['chest', 'back', 'quads', 'hamstrings', 'glutes'],
};
