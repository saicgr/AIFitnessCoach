import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

// ═══════════════════════════════════════════════════════════════
// BEAST MODE UNLOCK PROVIDER (existing)
// ═══════════════════════════════════════════════════════════════

/// Provider for Beast Mode unlock state.
///
/// Persisted via SharedPreferences under key 'beast_mode_unlocked'.
/// Unlocked by tapping the version label 7 times in settings.
final beastModeProvider =
    StateNotifierProvider<BeastModeNotifier, bool>((ref) {
  return BeastModeNotifier();
});

class BeastModeNotifier extends StateNotifier<bool> {
  static const String _prefsKey = 'beast_mode_unlocked';

  BeastModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    state = true;
  }

  Future<void> lock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
    state = false;
  }
}

// ═══════════════════════════════════════════════════════════════
// BEAST MODE FULL CONFIG STATE
// ═══════════════════════════════════════════════════════════════

/// Holds the full beast mode configuration that can be synced with backend.
class BeastModeConfig {
  // --- Difficulty Multipliers ---
  final Map<String, Map<String, double>> difficultyMultipliers;

  // --- Mood Multipliers ---
  final Map<String, Map<String, dynamic>> moodMultipliers;

  // --- Scoring Weights ---
  final Map<String, double> scoringWeights;

  // --- Rest Timer ---
  final String restTimerMode; // 'fixed', 'auto_scaled', 'rpe_based', 'custom'
  final Map<String, int> restTimerFixed; // tier -> seconds
  final double restTimerBaseRest;
  final double restTimerMultiplier;
  final String restTimerCustomFormula;

  // --- Volume Progression ---
  final String progressionModel; // 'linear', 'step', 'undulating', 'custom'
  final double progressionRate; // % per week
  final int progressionStepWeeks;
  final double progressionStepJump;
  final String progressionCustomJson;

  // --- RPE Auto-Regulation ---
  final bool rpeAutoRegEnabled;
  final double rpeSensitivity;
  final String rpePromptMode; // 'per_set', 'per_exercise'

  // --- Workout Templates ---
  final List<WorkoutTemplate> workoutTemplates;

  // --- Sync metadata ---
  final DateTime updatedAt;

  const BeastModeConfig({
    required this.difficultyMultipliers,
    required this.moodMultipliers,
    required this.scoringWeights,
    this.restTimerMode = 'auto_scaled',
    this.restTimerFixed = const {'Easy': 120, 'Medium': 90, 'Hard': 60, 'Hell': 45},
    this.restTimerBaseRest = 90.0,
    this.restTimerMultiplier = 1.0,
    this.restTimerCustomFormula = 'base * (rpe / 7) * multiplier',
    this.progressionModel = 'linear',
    this.progressionRate = 5.0,
    this.progressionStepWeeks = 4,
    this.progressionStepJump = 10.0,
    this.progressionCustomJson = '',
    this.rpeAutoRegEnabled = false,
    this.rpeSensitivity = 1.0,
    this.rpePromptMode = 'per_set',
    this.workoutTemplates = const [],
    required this.updatedAt,
  });

  factory BeastModeConfig.defaults() {
    return BeastModeConfig(
      difficultyMultipliers: defaultDifficultyMultipliers,
      moodMultipliers: defaultMoodMultipliers,
      scoringWeights: defaultScoringWeights,
      updatedAt: DateTime.now(),
    );
  }

  static final Map<String, Map<String, double>> defaultDifficultyMultipliers = {
    'Easy': {'volume': 0.75, 'rest': 1.25, 'rpe': 5.5},
    'Medium': {'volume': 1.00, 'rest': 1.00, 'rpe': 7.5},
    'Hard': {'volume': 1.15, 'rest': 0.85, 'rpe': 8.5},
    'Hell': {'volume': 1.30, 'rest': 0.70, 'rpe': 9.5},
  };

  static final Map<String, Map<String, dynamic>> defaultMoodMultipliers = {
    'Energized': {'intensity': 1.10, 'volume': 1.10, 'rest': 0.90, 'bias': 'Compound'},
    'Tired': {'intensity': 0.85, 'volume': 0.85, 'rest': 1.20, 'bias': 'Machine'},
    'Stressed': {'intensity': 0.90, 'volume': 0.90, 'rest': 1.15, 'bias': 'Cardio'},
    'Chill': {'intensity': 0.95, 'volume': 1.00, 'rest': 1.00, 'bias': 'Balanced'},
    'Motivated': {'intensity': 1.05, 'volume': 1.15, 'rest': 0.90, 'bias': 'PR Push'},
    'Low Energy': {'intensity': 0.80, 'volume': 0.80, 'rest': 1.30, 'bias': 'Isolation'},
  };

  static final Map<String, double> defaultScoringWeights = {
    'Freshness': 0.25,
    'Staple': 0.18,
    'Known Data': 0.12,
    'Collaborative': 0.12,
    'SFR': 0.10,
    'Random': 0.10,
  };

  BeastModeConfig copyWith({
    Map<String, Map<String, double>>? difficultyMultipliers,
    Map<String, Map<String, dynamic>>? moodMultipliers,
    Map<String, double>? scoringWeights,
    String? restTimerMode,
    Map<String, int>? restTimerFixed,
    double? restTimerBaseRest,
    double? restTimerMultiplier,
    String? restTimerCustomFormula,
    String? progressionModel,
    double? progressionRate,
    int? progressionStepWeeks,
    double? progressionStepJump,
    String? progressionCustomJson,
    bool? rpeAutoRegEnabled,
    double? rpeSensitivity,
    String? rpePromptMode,
    List<WorkoutTemplate>? workoutTemplates,
    DateTime? updatedAt,
  }) {
    return BeastModeConfig(
      difficultyMultipliers: difficultyMultipliers ?? this.difficultyMultipliers,
      moodMultipliers: moodMultipliers ?? this.moodMultipliers,
      scoringWeights: scoringWeights ?? this.scoringWeights,
      restTimerMode: restTimerMode ?? this.restTimerMode,
      restTimerFixed: restTimerFixed ?? this.restTimerFixed,
      restTimerBaseRest: restTimerBaseRest ?? this.restTimerBaseRest,
      restTimerMultiplier: restTimerMultiplier ?? this.restTimerMultiplier,
      restTimerCustomFormula: restTimerCustomFormula ?? this.restTimerCustomFormula,
      progressionModel: progressionModel ?? this.progressionModel,
      progressionRate: progressionRate ?? this.progressionRate,
      progressionStepWeeks: progressionStepWeeks ?? this.progressionStepWeeks,
      progressionStepJump: progressionStepJump ?? this.progressionStepJump,
      progressionCustomJson: progressionCustomJson ?? this.progressionCustomJson,
      rpeAutoRegEnabled: rpeAutoRegEnabled ?? this.rpeAutoRegEnabled,
      rpeSensitivity: rpeSensitivity ?? this.rpeSensitivity,
      rpePromptMode: rpePromptMode ?? this.rpePromptMode,
      workoutTemplates: workoutTemplates ?? this.workoutTemplates,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'difficulty_multipliers': difficultyMultipliers,
      'mood_multipliers': moodMultipliers,
      'scoring_weights': scoringWeights,
      'rest_timer_mode': restTimerMode,
      'rest_timer_fixed': restTimerFixed,
      'rest_timer_base_rest': restTimerBaseRest,
      'rest_timer_multiplier': restTimerMultiplier,
      'rest_timer_custom_formula': restTimerCustomFormula,
      'progression_model': progressionModel,
      'progression_rate': progressionRate,
      'progression_step_weeks': progressionStepWeeks,
      'progression_step_jump': progressionStepJump,
      'progression_custom_json': progressionCustomJson,
      'rpe_auto_reg_enabled': rpeAutoRegEnabled,
      'rpe_sensitivity': rpeSensitivity,
      'rpe_prompt_mode': rpePromptMode,
      'workout_templates': workoutTemplates.map((t) => t.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BeastModeConfig.fromJson(Map<String, dynamic> json) {
    return BeastModeConfig(
      difficultyMultipliers: _parseNestedDoubleMap(json['difficulty_multipliers']),
      moodMultipliers: _parseNestedDynamicMap(json['mood_multipliers']),
      scoringWeights: _parseDoubleMap(json['scoring_weights']),
      restTimerMode: json['rest_timer_mode'] as String? ?? 'auto_scaled',
      restTimerFixed: (json['rest_timer_fixed'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {'Easy': 120, 'Medium': 90, 'Hard': 60, 'Hell': 45},
      restTimerBaseRest: (json['rest_timer_base_rest'] as num?)?.toDouble() ?? 90.0,
      restTimerMultiplier: (json['rest_timer_multiplier'] as num?)?.toDouble() ?? 1.0,
      restTimerCustomFormula:
          json['rest_timer_custom_formula'] as String? ?? 'base * (rpe / 7) * multiplier',
      progressionModel: json['progression_model'] as String? ?? 'linear',
      progressionRate: (json['progression_rate'] as num?)?.toDouble() ?? 5.0,
      progressionStepWeeks: (json['progression_step_weeks'] as num?)?.toInt() ?? 4,
      progressionStepJump: (json['progression_step_jump'] as num?)?.toDouble() ?? 10.0,
      progressionCustomJson: json['progression_custom_json'] as String? ?? '',
      rpeAutoRegEnabled: json['rpe_auto_reg_enabled'] as bool? ?? false,
      rpeSensitivity: (json['rpe_sensitivity'] as num?)?.toDouble() ?? 1.0,
      rpePromptMode: json['rpe_prompt_mode'] as String? ?? 'per_set',
      workoutTemplates: (json['workout_templates'] as List<dynamic>?)
              ?.map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Map<String, Map<String, double>> _parseNestedDoubleMap(dynamic data) {
    if (data == null) return defaultDifficultyMultipliers;
    final outer = data as Map<String, dynamic>;
    return outer.map((key, value) {
      final inner = (value as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      return MapEntry(key, inner);
    });
  }

  static Map<String, Map<String, dynamic>> _parseNestedDynamicMap(dynamic data) {
    if (data == null) return defaultMoodMultipliers;
    final outer = data as Map<String, dynamic>;
    return outer.map((key, value) {
      final inner = Map<String, dynamic>.from(value as Map);
      // Ensure numeric fields are doubles
      for (final k in ['intensity', 'volume', 'rest']) {
        if (inner[k] is num) {
          inner[k] = (inner[k] as num).toDouble();
        }
      }
      return MapEntry(key, inner);
    });
  }

  static Map<String, double> _parseDoubleMap(dynamic data) {
    if (data == null) return defaultScoringWeights;
    final map = data as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}

// ═══════════════════════════════════════════════════════════════
// WORKOUT TEMPLATE MODEL
// ═══════════════════════════════════════════════════════════════

class WorkoutTemplate {
  final String id;
  final String name;
  final int exerciseCount;
  final String setScheme; // e.g., '3x10', '5x5', '4x8-12'
  final String restPattern; // e.g., '60s', '90-120s', 'auto'
  final bool supersets;
  final String notes;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.exerciseCount = 5,
    this.setScheme = '3x10',
    this.restPattern = '90s',
    this.supersets = false,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercise_count': exerciseCount,
        'set_scheme': setScheme,
        'rest_pattern': restPattern,
        'supersets': supersets,
        'notes': notes,
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled',
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ?? 5,
      setScheme: json['set_scheme'] as String? ?? '3x10',
      restPattern: json['rest_pattern'] as String? ?? '90s',
      supersets: json['supersets'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    int? exerciseCount,
    String? setScheme,
    String? restPattern,
    bool? supersets,
    String? notes,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      setScheme: setScheme ?? this.setScheme,
      restPattern: restPattern ?? this.restPattern,
      supersets: supersets ?? this.supersets,
      notes: notes ?? this.notes,
    );
  }

  static List<WorkoutTemplate> prebuiltTemplates = [
    const WorkoutTemplate(
      id: 'push_day',
      name: 'Push Day',
      exerciseCount: 6,
      setScheme: '4x8-12',
      restPattern: '90s',
      supersets: true,
      notes: 'Chest, shoulders, triceps',
    ),
    const WorkoutTemplate(
      id: '5x5_strength',
      name: '5x5 Strength',
      exerciseCount: 5,
      setScheme: '5x5',
      restPattern: '180s',
      supersets: false,
      notes: 'Compound lifts, heavy weight',
    ),
    const WorkoutTemplate(
      id: 'gvt',
      name: 'GVT (10x10)',
      exerciseCount: 4,
      setScheme: '10x10',
      restPattern: '60s',
      supersets: false,
      notes: 'German Volume Training',
    ),
    const WorkoutTemplate(
      id: 'upper_lower',
      name: 'Upper/Lower',
      exerciseCount: 6,
      setScheme: '3x10',
      restPattern: '90s',
      supersets: true,
      notes: 'Balanced upper or lower split',
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// BEAST MODE CONFIG NOTIFIER + PROVIDER
// ═══════════════════════════════════════════════════════════════

final beastModeConfigProvider =
    StateNotifierProvider<BeastModeConfigNotifier, BeastModeConfig>((ref) {
  return BeastModeConfigNotifier(ref);
});

class BeastModeConfigNotifier extends StateNotifier<BeastModeConfig> {
  final Ref _ref;
  Timer? _syncDebounce;
  static const _syncDelay = Duration(milliseconds: 300);
  String? _lastSyncError;

  /// Last sync error message, or null if last sync succeeded.
  String? get lastSyncError => _lastSyncError;

  /// Clears the last sync error.
  void clearSyncError() => _lastSyncError = null;

  BeastModeConfigNotifier(this._ref) : super(BeastModeConfig.defaults()) {
    _loadFromPrefs();
  }

  // ─── Local persistence ────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('beast_mode_config');
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        state = BeastModeConfig.fromJson(map);
      } catch (e) {
        debugPrint('Failed to load beast config from prefs: $e');
        state = BeastModeConfig.defaults();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('beast_mode_config', jsonEncode(state.toJson()));
  }

  // ─── Debounced sync to backend ────────────────────────────

  void _scheduleSyncToBackend() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(_syncDelay, () => _syncToBackend());
  }

  Future<void> _syncToBackend() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        '/api/v1/beast-mode/config',
        data: state.toJson(),
      );
      _lastSyncError = null;
    } catch (e) {
      debugPrint('Beast mode sync to backend failed (offline?): $e');
      _lastSyncError = e.toString();
    }
  }

  /// Fetch config from backend and merge (backend wins for newer updated_at).
  Future<void> fetchAndMerge() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/api/v1/beast-mode/config');
      if (response.data != null) {
        Map<String, dynamic> parsed;
        try {
          parsed = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : jsonDecode(response.data.toString()) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Beast mode: failed to parse remote config: $e');
          _lastSyncError = 'Invalid response format from server';
          return;
        }
        final remoteConfig = BeastModeConfig.fromJson(parsed);
        // Backend wins if newer
        if (remoteConfig.updatedAt.isAfter(state.updatedAt)) {
          state = remoteConfig;
          await _saveToPrefs();
        }
        _lastSyncError = null;
      }
    } catch (e) {
      debugPrint('Beast mode fetch failed (offline?): $e');
      _lastSyncError = e.toString();
    }
  }

  // ─── Public update methods ────────────────────────────────

  void _update(BeastModeConfig Function(BeastModeConfig) updater) {
    state = updater(state).copyWith(updatedAt: DateTime.now());
    _saveToPrefs();
    _scheduleSyncToBackend();
  }

  // --- Difficulty Multipliers ---

  void updateDifficultyMultiplier(String tier, String field, double value) {
    final updated = Map<String, Map<String, double>>.from(
      state.difficultyMultipliers.map((k, v) => MapEntry(k, Map<String, double>.from(v))),
    );
    if (!updated.containsKey(tier)) return;
    updated[tier]![field] = value;
    _update((c) => c.copyWith(difficultyMultipliers: updated));
  }

  void resetDifficultyTier(String tier) {
    final defaults = BeastModeConfig.defaultDifficultyMultipliers[tier];
    if (defaults == null) return;
    final updated = Map<String, Map<String, double>>.from(
      state.difficultyMultipliers.map((k, v) => MapEntry(k, Map<String, double>.from(v))),
    );
    updated[tier] = Map<String, double>.from(defaults);
    _update((c) => c.copyWith(difficultyMultipliers: updated));
  }

  void resetAllDifficultyMultipliers() {
    _update((c) => c.copyWith(
      difficultyMultipliers: Map<String, Map<String, double>>.from(
        BeastModeConfig.defaultDifficultyMultipliers.map(
          (k, v) => MapEntry(k, Map<String, double>.from(v)),
        ),
      ),
    ));
  }

  // --- Mood Multipliers ---

  void updateMoodMultiplier(String mood, String field, dynamic value) {
    final updated = Map<String, Map<String, dynamic>>.from(
      state.moodMultipliers.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
    );
    if (!updated.containsKey(mood)) return;
    updated[mood]![field] = value;
    _update((c) => c.copyWith(moodMultipliers: updated));
  }

  void resetAllMoodMultipliers() {
    _update((c) => c.copyWith(
      moodMultipliers: Map<String, Map<String, dynamic>>.from(
        BeastModeConfig.defaultMoodMultipliers.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
        ),
      ),
    ));
  }

  // --- Scoring Weights ---

  void updateScoringWeight(String factor, double value) {
    final updated = Map<String, double>.from(state.scoringWeights);
    updated[factor] = value;
    _update((c) => c.copyWith(scoringWeights: updated));
  }

  void normalizeScoringWeights() {
    final weights = Map<String, double>.from(state.scoringWeights);
    final total = weights.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      for (final key in weights.keys) {
        weights[key] = weights[key]! / total;
      }
    }
    _update((c) => c.copyWith(scoringWeights: weights));
  }

  void resetScoringWeights() {
    _update((c) => c.copyWith(
      scoringWeights: Map<String, double>.from(BeastModeConfig.defaultScoringWeights),
    ));
  }

  // --- Rest Timer ---

  void updateRestTimerMode(String mode) {
    _update((c) => c.copyWith(restTimerMode: mode));
  }

  void updateRestTimerFixed(String tier, int seconds) {
    final updated = Map<String, int>.from(state.restTimerFixed);
    if (!updated.containsKey(tier)) return;
    updated[tier] = seconds;
    _update((c) => c.copyWith(restTimerFixed: updated));
  }

  void updateRestTimerBaseRest(double value) {
    _update((c) => c.copyWith(restTimerBaseRest: value));
  }

  void updateRestTimerMultiplier(double value) {
    _update((c) => c.copyWith(restTimerMultiplier: value));
  }

  void updateRestTimerCustomFormula(String formula) {
    _update((c) => c.copyWith(restTimerCustomFormula: formula));
  }

  // --- Volume Progression ---

  void updateProgressionModel(String model) {
    _update((c) => c.copyWith(progressionModel: model));
  }

  void updateProgressionRate(double rate) {
    _update((c) => c.copyWith(progressionRate: rate));
  }

  void updateProgressionStepWeeks(int weeks) {
    _update((c) => c.copyWith(progressionStepWeeks: weeks));
  }

  void updateProgressionStepJump(double jump) {
    _update((c) => c.copyWith(progressionStepJump: jump));
  }

  void updateProgressionCustomJson(String json) {
    _update((c) => c.copyWith(progressionCustomJson: json));
  }

  // --- RPE Auto-Regulation ---

  void updateRpeAutoReg(bool enabled) {
    _update((c) => c.copyWith(rpeAutoRegEnabled: enabled));
  }

  void updateRpeSensitivity(double sensitivity) {
    _update((c) => c.copyWith(rpeSensitivity: sensitivity));
  }

  void updateRpePromptMode(String mode) {
    _update((c) => c.copyWith(rpePromptMode: mode));
  }

  // --- Workout Templates ---

  void addTemplate(WorkoutTemplate template) {
    _update((c) => c.copyWith(
      workoutTemplates: [...c.workoutTemplates, template],
    ));
  }

  void updateTemplate(String id, WorkoutTemplate updated) {
    _update((c) => c.copyWith(
      workoutTemplates: c.workoutTemplates.map((t) => t.id == id ? updated : t).toList(),
    ));
  }

  void removeTemplate(String id) {
    _update((c) => c.copyWith(
      workoutTemplates: c.workoutTemplates.where((t) => t.id != id).toList(),
    ));
  }

  void duplicateTemplate(String id) {
    final original = state.workoutTemplates.where((t) => t.id == id).firstOrNull;
    if (original == null) return;
    final copy = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${original.name} (Copy)',
    );
    addTemplate(copy);
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }
}
