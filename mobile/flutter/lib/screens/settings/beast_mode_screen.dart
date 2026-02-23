import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/beast_mode_provider.dart';
import '../../data/services/data_cache_service.dart';
import '../../data/services/haptic_service.dart';
import '../../services/muscle_recovery_tracker.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glass_back_button.dart';

class BeastModeScreen extends ConsumerStatefulWidget {
  const BeastModeScreen({super.key});

  @override
  ConsumerState<BeastModeScreen> createState() => _BeastModeScreenState();
}

class _BeastModeScreenState extends ConsumerState<BeastModeScreen> {
  // --- Section 1 state ---
  double _freshnessDecay = 0.3;

  // --- Section 2 state ---
  Map<String, double> _recoveryScores = {};
  Map<String, double> _recoveryKValues = {};
  bool _recoveryLoaded = false;

  // --- Section 3 state ---
  int _modelUnloadMinutes = 5;
  String _generationModeOverride = 'auto';
  String _deviceCapabilityOverride = 'auto';

  // --- 1RM Calculator state ---
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double? _epley1rm;
  double? _brzycki1rm;
  double? _mayhew1rm;

  // Difficulty multiplier data (read-only display)
  static const _difficultyMultipliers = <String, Map<String, String>>{
    'Easy': {'Volume': '0.75x', 'Rest': '1.25x', 'RPE': '5-6'},
    'Medium': {'Volume': '1.00x', 'Rest': '1.00x', 'RPE': '7-8'},
    'Hard': {'Volume': '1.15x', 'Rest': '0.85x', 'RPE': '8-9'},
    'Hell': {'Volume': '1.30x', 'Rest': '0.70x', 'RPE': '9-10'},
  };

  // Mood multiplier data (read-only display)
  static const _moodMultipliers = <String, Map<String, String>>{
    'Energized': {'Intensity': '1.10x', 'Volume': '1.10x', 'Rest': '0.90x', 'Bias': 'Compound'},
    'Tired': {'Intensity': '0.85x', 'Volume': '0.85x', 'Rest': '1.20x', 'Bias': 'Machine'},
    'Stressed': {'Intensity': '0.90x', 'Volume': '0.90x', 'Rest': '1.15x', 'Bias': 'Cardio'},
    'Chill': {'Intensity': '0.95x', 'Volume': '1.00x', 'Rest': '1.00x', 'Bias': 'Balanced'},
    'Motivated': {'Intensity': '1.05x', 'Volume': '1.15x', 'Rest': '0.90x', 'Bias': 'PR Push'},
    'Low Energy': {'Intensity': '0.80x', 'Volume': '0.80x', 'Rest': '1.30x', 'Bias': 'Isolation'},
  };

  // Scoring factor data
  static const _scoringFactors = <_ScoringFactor>[
    _ScoringFactor('Freshness', 0.25, Color(0xFF3B82F6)),
    _ScoringFactor('Staple', 0.18, Color(0xFF22C55E)),
    _ScoringFactor('Known Data', 0.12, Color(0xFFA855F7)),
    _ScoringFactor('Collaborative', 0.12, Color(0xFF14B8A6)),
    _ScoringFactor('SFR', 0.10, Color(0xFFF59E0B)),
    _ScoringFactor('Random', 0.10, Color(0xFF71717A)),
  ];

  // Default recovery rates from MuscleRecoveryTracker
  static const _defaultRecoveryRates = <String, double>{
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadRecoveryData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _freshnessDecay = prefs.getDouble('beast_freshness_decay') ?? 0.3;
      // Load custom k-values or use defaults
      for (final entry in _defaultRecoveryRates.entries) {
        _recoveryKValues[entry.key] =
            prefs.getDouble('beast_recovery_k_${entry.key}') ?? entry.value;
      }
      // Load section 3 prefs
      _modelUnloadMinutes = prefs.getInt('beast_model_unload_minutes') ?? 5;
      _generationModeOverride =
          prefs.getString('beast_generation_mode_override') ?? 'auto';
      _deviceCapabilityOverride =
          prefs.getString('beast_device_capability_override') ?? 'auto';
    });
  }

  Future<void> _loadRecoveryData() async {
    final scores = await MuscleRecoveryTracker.getAllRecoveryScores();
    if (!mounted) return;
    setState(() {
      _recoveryScores = scores;
      // Fill in default 100% for muscles with no data
      for (final muscle in _defaultRecoveryRates.keys) {
        _recoveryScores.putIfAbsent(muscle, () => 100.0);
      }
      _recoveryLoaded = true;
    });
  }

  Future<void> _saveFreshnessDecay(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('beast_freshness_decay', value);
  }

  Future<void> _saveRecoveryK(String muscle, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('beast_recovery_k_$muscle', value);
  }

  void _calculate1rm() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    if (weight == null || weight <= 0 || reps == null || reps <= 0) {
      setState(() {
        _epley1rm = null;
        _brzycki1rm = null;
        _mayhew1rm = null;
      });
      return;
    }
    setState(() {
      _epley1rm = weight * (1 + reps / 30.0);
      _brzycki1rm = weight * (36.0 / (37.0 - reps));
      _mayhew1rm = (100 * weight) / (52.2 + (41.9 * exp(-0.055 * reps)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const GlassBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              'Beast Mode',
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeaderCard(isDark),
              const SizedBox(height: 24),
              _buildAlgorithmInspectorSection(
                  isDark, textPrimary, textMuted, elevated, cardBorder),
              const SizedBox(height: 24),
              _buildRecoveryProgressionSection(
                  isDark, textPrimary, textMuted, elevated, cardBorder),
              const SizedBox(height: 24),
              // === SECTIONS 3-4: AI & MODELS + DATA & SYNC TOOLS ===
              // Implemented by beast-screen-bottom agent
              _buildAiModelsSection(
                  isDark, textPrimary, textMuted, elevated, cardBorder),
              const SizedBox(height: 24),
              _buildDataSyncSection(
                  isDark, textPrimary, textMuted, elevated, cardBorder),
              const SizedBox(height: 24),
              _buildAboutSection(
                  isDark, textPrimary, textMuted, elevated, cardBorder),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: isDark ? 0.25 : 0.15),
            AppColors.orange.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEAST MODE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Power user toolkit',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION 1: ALGORITHM INSPECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAlgorithmInspectorSection(bool isDark, Color textPrimary,
      Color textMuted, Color elevated, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'ALGORITHM INSPECTOR',
          'See the math behind your workouts',
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 12),
        // Exercise Scoring Breakdown
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Scoring Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '6-factor weighted selection algorithm',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 16),
              // Stacked bar
              _buildScoringBar(),
              const SizedBox(height: 12),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: _scoringFactors.map((f) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: f.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${f.label} ${(f.weight * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Freshness Decay Tuner
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Freshness Decay Tuner',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Controls how quickly exercise freshness decays: e^(-k * sessions)',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'k = ${_freshnessDecay.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Range: 0.10 - 0.60',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.orange,
                  inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
                  thumbColor: AppColors.orange,
                  overlayColor: AppColors.orange.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _freshnessDecay,
                  min: 0.1,
                  max: 0.6,
                  divisions: 50,
                  onChanged: (v) {
                    HapticService.selection();
                    setState(() => _freshnessDecay = v);
                  },
                  onChangeEnd: (v) => _saveFreshnessDecay(v),
                ),
              ),
              // Live preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(4, (i) {
                      final sessions = i + 1;
                      final freshness = exp(-_freshnessDecay * sessions);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: Text(
                                'Used $sessions session${sessions > 1 ? 's' : ''} ago',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textPrimary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Text(
                              'freshness: ${(1 - freshness).toStringAsFixed(3)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.orange,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Difficulty Multipliers Table
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Difficulty Multipliers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Read-only scaling factors per difficulty tier',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              _buildMultiplierTable(
                headers: ['Tier', 'Volume', 'Rest', 'RPE'],
                data: _difficultyMultipliers,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                tierColors: {
                  'Easy': AppColors.success,
                  'Medium': AppColors.warning,
                  'Hard': AppColors.orange,
                  'Hell': AppColors.error,
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mood Multipliers Table
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood Multipliers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How your mood adjusts workout parameters',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              _buildMultiplierTable(
                headers: ['Mood', 'Intensity', 'Volume', 'Rest', 'Bias'],
                data: _moodMultipliers,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION 2: RECOVERY & PROGRESSION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecoveryProgressionSection(bool isDark, Color textPrimary,
      Color textMuted, Color elevated, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'RECOVERY & PROGRESSION',
          'Visualize your body\'s recovery and forecast growth',
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 12),
        // Per-Muscle Recovery Grid
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Per-Muscle Recovery Grid',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Color-coded: red <40% | yellow 40-70% | green >70%',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              if (!_recoveryLoaded)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                _buildRecoveryGrid(isDark, textPrimary, textMuted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Recovery Constants Editor
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Constants Editor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Per-muscle exponential decay rate (k values)',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _resetRecoveryKValues();
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildRecoverySliders(isDark, textPrimary, textMuted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 1RM Calculator Playground
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1RM Calculator Playground',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Compare Epley, Brzycki, and Mayhew estimates',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(color: textMuted, fontSize: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.orange),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _calculate1rm(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        labelStyle: TextStyle(color: textMuted, fontSize: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.orange),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _calculate1rm(),
                    ),
                  ),
                ],
              ),
              if (_epley1rm != null) ...[
                const SizedBox(height: 16),
                _build1rmResult(
                  'Epley',
                  _epley1rm!,
                  'Best for 2-10 reps',
                  const Color(0xFF3B82F6),
                  textPrimary,
                  textMuted,
                ),
                const SizedBox(height: 8),
                _build1rmResult(
                  'Brzycki',
                  _brzycki1rm!,
                  'Best for 1-6 reps',
                  const Color(0xFF22C55E),
                  textPrimary,
                  textMuted,
                ),
                const SizedBox(height: 8),
                _build1rmResult(
                  'Mayhew',
                  _mayhew1rm!,
                  'Best for 5-10 reps',
                  const Color(0xFFA855F7),
                  textPrimary,
                  textMuted,
                ),
                const SizedBox(height: 8),
                _buildBestFormulaHint(textMuted),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION 3: AI & MODELS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAiModelsSection(bool isDark, Color textPrimary,
      Color textMuted, Color elevated, Color cardBorder) {
    const models = <(String, String, String, String)>[
      ('Gemma 3 270M', '270 MB', '1 GB RAM', 'Basic'),
      ('Gemma 3 1B', '1.0 GB', '2 GB RAM', 'Standard'),
      ('Gemma 3n E2B', '2.0 GB', '4 GB RAM', 'Standard'),
      ('Gemma 3n E4B', '4.0 GB', '6 GB RAM', 'Optimal'),
      ('EmbeddingGemma 300M', '300 MB', '1 GB RAM', 'Basic'),
    ];

    final unloadOptions = {1: '1 min', 5: '5 min', 15: '15 min', 0: 'Never'};
    final modeOptions = {
      'auto': 'Auto',
      'cloud': 'Cloud',
      'on_device': 'On-Device',
      'rule_based': 'Rule-Based',
    };
    final capOptions = {
      'auto': 'Auto',
      'basic': 'Basic',
      'standard': 'Standard',
      'optimal': 'Optimal',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'AI & MODELS',
          'Full control over on-device AI',
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 12),

        // Full Model Library
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full Model Library',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All on-device AI models (overrides device compatibility)',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              ...models.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              color: AppColors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.$1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${m.$2}  |  ${m.$3}  |  Tier: ${m.$4}',
                                  style:
                                      TextStyle(fontSize: 11, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Model Auto-Unload Timer
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model Auto-Unload Timer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How long Gemma stays loaded in memory after last use',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unloadOptions.entries.map((e) {
                  final isSelected = _modelUnloadMinutes == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: AppColors.orange.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.orange : textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.orange.withValues(alpha: 0.5)
                          : cardBorder,
                    ),
                    onSelected: (_) async {
                      HapticService.selection();
                      setState(() => _modelUnloadMinutes = e.key);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('beast_model_unload_minutes', e.key);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Generation Mode Override
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generation Mode Override',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Force a specific mode regardless of connectivity',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: modeOptions.entries.map((e) {
                  final isSelected = _generationModeOverride == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: AppColors.orange.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.orange : textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.orange.withValues(alpha: 0.5)
                          : cardBorder,
                    ),
                    onSelected: (_) async {
                      HapticService.selection();
                      setState(() => _generationModeOverride = e.key);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                          'beast_generation_mode_override', e.key);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Device Capability Override
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Capability Override',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Force device tier to unlock model downloads',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'May cause crashes on low-memory devices',
                        style: TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: capOptions.entries.map((e) {
                  final isSelected = _deviceCapabilityOverride == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: AppColors.orange.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.orange : textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.orange.withValues(alpha: 0.5)
                          : cardBorder,
                    ),
                    onSelected: (_) async {
                      HapticService.selection();
                      setState(() => _deviceCapabilityOverride = e.key);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                          'beast_device_capability_override', e.key);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION 4: DATA & SYNC TOOLS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDataSyncSection(bool isDark, Color textPrimary,
      Color textMuted, Color elevated, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'DATA & SYNC TOOLS',
          'Debug sync issues and manage your data',
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 12),

        // Navigation tiles
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            children: [
              // Sync Recovery
              InkWell(
                onTap: () {
                  HapticService.light();
                  context.push('/settings/equipment-offline');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.sync_problem_outlined,
                          color: AppColors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sync Recovery',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Dead letter queue & retry',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: textMuted, size: 18),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: cardBorder),
              // Notification Tester
              InkWell(
                onTap: () {
                  HapticService.light();
                  context.push('/settings/sound-notifications');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          color: AppColors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Tester',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Send test notifications',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            children: [
              // Clear All Caches
              InkWell(
                onTap: () async {
                  HapticService.medium();
                  await DataCacheService.instance.clearAll();
                  if (mounted) {
                    AppSnackBar.success(context, 'All caches cleared');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.cleaning_services_outlined,
                            color: AppColors.orange, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear All Caches',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Free memory by clearing in-memory caches',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: cardBorder),
              // Force Full Sync
              InkWell(
                onTap: () async {
                  HapticService.medium();
                  await DataCacheService.instance.clearAll();
                  if (mounted) {
                    AppSnackBar.success(
                        context, 'Caches cleared. Sync triggered.');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.sync_outlined,
                            color: AppColors.orange, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Force Full Sync',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Invalidate caches & trigger immediate sync',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Device Info Card
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text(
                      'Loading...',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    );
                  }
                  final info = snapshot.data!;
                  return Column(
                    children: [
                      _buildInfoRow(
                          'App Version', info.version, textPrimary, textMuted),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                          'Build', info.buildNumber, textPrimary, textMuted),
                      const SizedBox(height: 6),
                      _buildInfoRow('Package', info.packageName, textPrimary,
                          textMuted),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        'Platform',
                        Theme.of(context).platform.name,
                        textPrimary,
                        textMuted,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION 5: ABOUT BEAST MODE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAboutSection(bool isDark, Color textPrimary, Color textMuted,
      Color elevated, Color cardBorder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'ABOUT BEAST MODE',
          'Build information and controls',
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 12),
        _buildCard(
          isDark: isDark,
          cardBorder: cardBorder,
          elevated: elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Build info
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text(
                      'Loading build info...',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    );
                  }
                  final info = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Package', info.packageName, textPrimary, textMuted),
                      const SizedBox(height: 6),
                      _buildInfoRow('Version', info.version, textPrimary, textMuted),
                      const SizedBox(height: 6),
                      _buildInfoRow('Build', info.buildNumber, textPrimary, textMuted),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Disable Beast Mode button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticService.medium();
                    ref.read(beastModeProvider.notifier).lock();
                    AppSnackBar.info(context, 'Beast Mode disabled');
                    context.pop();
                  },
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Disable Beast Mode'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionTitle(
      String title, String subtitle, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.orange,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Color cardBorder,
    required Color elevated,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildScoringBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 28,
        child: Row(
          children: _scoringFactors.map((f) {
            return Expanded(
              flex: (f.weight * 100).toInt(),
              child: Tooltip(
                message: '${f.label}: ${(f.weight * 100).toInt()}%',
                child: Container(
                  color: f.color,
                  alignment: Alignment.center,
                  child: f.weight >= 0.12
                      ? Text(
                          '${(f.weight * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMultiplierTable({
    required List<String> headers,
    required Map<String, Map<String, String>> data,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    Map<String, Color>? tierColors,
  }) {
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(1.2),
        for (int i = 1; i < headers.length; i++)
          i: const FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          children: headers.map((h) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                h,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...data.entries.map((entry) {
          final tierColor = tierColors?[entry.key];
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tierColor ?? textPrimary,
                  ),
                ),
              ),
              ...entry.value.values.map((v) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    v,
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRecoveryGrid(
      bool isDark, Color textPrimary, Color textMuted) {
    final muscles = _recoveryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: muscles.map((entry) {
        final score = entry.value;
        final color = score < 40
            ? AppColors.error
            : score < 70
                ? AppColors.warning
                : AppColors.success;
        final name = entry.key.replaceAll('_', ' ');

        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name[0].toUpperCase() + name.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${score.toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildRecoverySliders(
      bool isDark, Color textPrimary, Color textMuted) {
    // Group muscles by recovery speed
    final groups = <String, List<String>>{
      'Fast (~12h)': ['calves', 'abs', 'obliques', 'forearms'],
      'Medium (~16h)': ['shoulders', 'traps', 'biceps', 'triceps'],
      'Slow (~24h)': ['chest', 'back', 'quads', 'hamstrings', 'glutes'],
    };

    final widgets = <Widget>[];
    for (final group in groups.entries) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 12),
          child: Text(
            group.key,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      for (final muscle in group.value) {
        final k = _recoveryKValues[muscle] ?? _defaultRecoveryRates[muscle]!;
        final name = muscle.replaceAll('_', ' ');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    name[0].toUpperCase() + name.substring(1),
                    style: TextStyle(fontSize: 12, color: textPrimary),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.orange,
                      inactiveTrackColor:
                          AppColors.orange.withValues(alpha: 0.15),
                      thumbColor: AppColors.orange,
                      overlayColor: AppColors.orange.withValues(alpha: 0.08),
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: k,
                      min: 0.02,
                      max: 0.15,
                      divisions: 65,
                      onChanged: (v) {
                        setState(() => _recoveryKValues[muscle] = v);
                      },
                      onChangeEnd: (v) => _saveRecoveryK(muscle, v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 46,
                  child: Text(
                    k.toStringAsFixed(3),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.orange,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _resetRecoveryKValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final entry in _defaultRecoveryRates.entries) {
        _recoveryKValues[entry.key] = entry.value;
        prefs.remove('beast_recovery_k_${entry.key}');
      }
    });
    if (mounted) {
      AppSnackBar.info(context, 'Recovery constants reset to defaults');
    }
  }

  Widget _build1rmResult(String formula, double value, String note,
      Color color, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  note,
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestFormulaHint(Color textMuted) {
    final reps = int.tryParse(_repsController.text) ?? 0;
    String best;
    if (reps <= 3) {
      best = 'Brzycki is typically most accurate for low rep ranges (1-6)';
    } else if (reps <= 6) {
      best = 'Brzycki and Epley are both reliable for this rep range';
    } else {
      best = 'Mayhew tends to be most accurate for higher reps (5-10+)';
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.info.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              best,
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, Color textPrimary, Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// Internal helper for scoring factor metadata.
class _ScoringFactor {
  final String label;
  final double weight;
  final Color color;

  const _ScoringFactor(this.label, this.weight, this.color);
}
