import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/ai_target_recommendation_provider.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/ai_target_recommendation_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';

/// The three recommendation sections, used as keys for the per-section
/// "Applied ✓" state so each Apply button tracks itself.
enum _RecSection { daily, perMeal, perDay }

/// Bottom sheet that runs the AI "Recommend Targets" analysis and lets the user
/// apply the Daily / Per-Meal / Per-Day recommendations — per section or all at
/// once. Matches `docs/planning/nutrition-per-meal-2026-06/ai-recommend-mockup.html`.
///
/// Applying a section calls the EXISTING `NutritionPreferencesNotifier` methods
/// (`updateTargets` / `updatePerMealTargets` / `updateWeekdayTargets`), which
/// are optimistic + background-persisting — so the Edit Targets sheet and Home
/// reflect the change immediately. This sheet never writes targets itself.
class AiRecommendationSheet extends ConsumerStatefulWidget {
  /// The signed-in user id (passed through from the Edit Targets sheet so the
  /// apply calls don't have to re-resolve it).
  final String userId;

  const AiRecommendationSheet({super.key, required this.userId});

  @override
  ConsumerState<AiRecommendationSheet> createState() =>
      _AiRecommendationSheetState();
}

class _AiRecommendationSheetState extends ConsumerState<AiRecommendationSheet> {
  /// Which sections the user has applied this session (turns the button into
  /// "Applied ✓"). Optimistic — the notifier handles persistence + rollback.
  final Set<_RecSection> _applied = {};

  @override
  void initState() {
    super.initState();
    // Kick off the analysis as soon as the sheet opens — the loading state is
    // the first thing the user sees (feedback_instant_feel_ai_generation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiTargetRecommendationProvider.notifier).analyze();
    });
  }

  // ── Meal + weekday display helpers ─────────────────────────────────────
  static const Map<String, String> _mealLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snacks': 'Snacks',
  };
  // Mon..Sun — matches the Python weekday ints (0 = Mon … 6 = Sun) the backend
  // uses for high_days, and the By-Day chips in the Edit Targets sheet.
  static const List<String> _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _mealLabel(String id) => _mealLabels[id] ?? _titleCase(id);

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Apply handlers (reuse existing notifier methods only) ───────────────

  void _applyDaily(DailyRec d) {
    ref.read(nutritionPreferencesProvider.notifier).updateTargets(
          userId: widget.userId,
          targetCalories: d.calories,
          targetProteinG: d.proteinG,
          targetCarbsG: d.carbsG,
          targetFatG: d.fatG,
        );
    setState(() => _applied.add(_RecSection.daily));
    HapticFeedback.selectionClick();
  }

  void _applyPerMeal(PerMealRec m) {
    if (m.meals.isEmpty) return;
    // Match the JSON shape `_buildPerMealMacroTargetsJson` persists:
    // {mode:'custom', split:{...}, overrides:{mealId:{protein_g,carbs_g,fat_g}}, locks:{...}}.
    // We persist an explicit override for every recommended meal (so the day's
    // total is deterministic) and lock each meal's calorie budget ON by default,
    // mirroring the manual editor's "meals drive the day" behavior.
    final overrides = <String, dynamic>{};
    final locks = <String, dynamic>{};
    for (final entry in m.meals.entries) {
      overrides[entry.key] = {
        'protein_g': entry.value.proteinG,
        'carbs_g': entry.value.carbsG,
        'fat_g': entry.value.fatG,
      };
      locks[entry.key] = true;
    }
    ref.read(nutritionPreferencesProvider.notifier).updatePerMealTargets(
          userId: widget.userId,
          enabled: true, // applying flips the per-meal master toggle on
          macroTargets: {
            'mode': 'custom',
            'overrides': overrides,
            'locks': locks,
          },
        );
    setState(() => _applied.add(_RecSection.perMeal));
    HapticFeedback.selectionClick();
  }

  void _applyPerDay(PerDayRec p) {
    if (p.isEmpty) return;
    // Match the `per_weekday_targets` shape `_buildWeekdayTargetsJson` persists.
    ref.read(nutritionPreferencesProvider.notifier).updateWeekdayTargets(
          userId: widget.userId,
          weekdayTargets: {
            'enabled': true, // applying flips the By-Day master toggle on
            'bind_to_training_days': p.bindToTrainingDays,
            'high_days': (List<int>.from(p.highDays)..sort()),
            'high': {
              'protein_g': p.high.proteinG,
              'carbs_g': p.high.carbsG,
              'fat_g': p.high.fatG,
            },
            'base': {
              'protein_g': p.base.proteinG,
              'carbs_g': p.base.carbsG,
              'fat_g': p.base.fatG,
            },
          },
        );
    setState(() => _applied.add(_RecSection.perDay));
    HapticFeedback.selectionClick();
  }

  void _applyAll(NutritionTargetsRecommendation rec) {
    _applyDaily(rec.daily);
    if (!rec.perMeal.isEmpty) _applyPerMeal(rec.perMeal);
    if (!rec.perDay.isEmpty) _applyPerDay(rec.perDay);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTargetRecommendationProvider);
    final colors = ThemeColors.of(context);

    return GlassSheet(
      opaque: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: _buildBody(state, colors),
      ),
    );
  }

  Widget _buildBody(
    AiTargetRecommendationState state,
    ThemeColors colors,
  ) {
    // Loading takes precedence only when there's no prior result to keep on
    // screen (a forced re-analyze keeps the old recommendation under a chip).
    if (state.isLoading && state.result == null) {
      return _buildAnalyzing(colors);
    }
    if (state.error != null && state.result == null) {
      return _buildError(colors, state.error!);
    }
    final rec = state.result;
    if (rec == null) {
      // Pre-first-frame (analyze fires post-frame) — show the analyzing state
      // so there's never a blank flash.
      return _buildAnalyzing(colors);
    }
    return _buildRecommendation(rec, colors, state.isLoading);
  }

  // ── Analyzing state ─────────────────────────────────────────────────────
  Widget _buildAnalyzing(ThemeColors colors) {
    final accent = colors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              backgroundColor: colors.cardBorder,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Analyzing your nutrition…',
            style: ZType.lbl(15, color: colors.textPrimary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile & goal · weight trend · 14-day logs · training schedule',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────
  Widget _buildError(ThemeColors colors, String message) {
    final accent = colors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 34, color: colors.textMuted),
          const SizedBox(height: 14),
          Text(
            "Couldn't build your recommendation",
            textAlign: TextAlign.center,
            style: ZType.lbl(15, color: colors.textPrimary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'The coach hit a snag analyzing your data. Give it another go.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => ref
                .read(aiTargetRecommendationProvider.notifier)
                .analyze(force: true),
            icon: Icon(Icons.refresh, size: 16, color: accent),
            label: Text(
              'Try again',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommendation state ────────────────────────────────────────────────
  Widget _buildRecommendation(
    NutritionTargetsRecommendation rec,
    ThemeColors colors,
    bool refreshing,
  ) {
    final accent = colors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: ✨ AI Recommendation + confidence chip.
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Recommendation',
                style: ZType.lbl(17,
                    color: colors.textPrimary, letterSpacing: 0.5),
              ),
            ),
            _confidenceChip(rec.confidence, colors),
          ],
        ),
        if (rec.basis.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            rec.basis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: colors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Daily section.
        _dailySection(rec.daily, colors),
        const SizedBox(height: 11),

        // Per-meal section (only when the AI returned a split).
        if (!rec.perMeal.isEmpty) ...[
          _perMealSection(rec.perMeal, colors),
          const SizedBox(height: 11),
        ],

        // Per-day section (only when the AI returned high/base sets).
        if (!rec.perDay.isEmpty) ...[
          _perDaySection(rec.perDay, colors),
          const SizedBox(height: 11),
        ],

        // 🛡️ Kept-safe clamp note.
        if (rec.clamped.isNotEmpty) ...[
          _clampNote(rec.clamped, colors),
          const SizedBox(height: 4),
        ],

        // Apply all.
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _allApplied(rec) ? null : () => _applyAll(rec),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: colors.accentContrast,
              disabledBackgroundColor: colors.success.withValues(alpha: 0.16),
              disabledForegroundColor: colors.success,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              _allApplied(rec) ? 'All applied ✓' : 'Apply all',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'or tweak any value manually after applying',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ),
        // Subtle refreshing indicator when a forced re-analyze is in flight
        // while the prior result stays on screen.
        if (refreshing) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Re-analyzing…',
              style: TextStyle(fontSize: 11, color: colors.accent),
            ),
          ),
        ],
      ],
    );
  }

  bool _allApplied(NutritionTargetsRecommendation rec) {
    if (!_applied.contains(_RecSection.daily)) return false;
    if (!rec.perMeal.isEmpty && !_applied.contains(_RecSection.perMeal)) {
      return false;
    }
    if (!rec.perDay.isEmpty && !_applied.contains(_RecSection.perDay)) {
      return false;
    }
    return true;
  }

  // ── Section: Daily ──────────────────────────────────────────────────────
  Widget _dailySection(DailyRec d, ThemeColors colors) {
    final pColor = _macroColor(colors.isDark, 'p');
    final cColor = _macroColor(colors.isDark, 'c');
    final fColor = _macroColor(colors.isDark, 'f');
    return _sectionShell(
      colors: colors,
      title: 'Daily target',
      section: _RecSection.daily,
      onApply: () => _applyDaily(d),
      children: [
        Row(
          children: [
            _statTile(colors, '${d.calories}', 'KCAL', colors.accent,
                d.currentCalories, d.calories),
            const SizedBox(width: 8),
            _statTile(colors, '${d.proteinG}', 'P', pColor,
                d.currentProteinG, d.proteinG),
            const SizedBox(width: 8),
            _statTile(colors, '${d.carbsG}', 'C', cColor, d.currentCarbsG,
                d.carbsG),
            const SizedBox(width: 8),
            _statTile(
                colors, '${d.fatG}', 'F', fColor, d.currentFatG, d.fatG),
          ],
        ),
        if (d.reasoning.isNotEmpty) ...[
          const SizedBox(height: 10),
          _whyLine(d.reasoning, colors),
        ],
      ],
    );
  }

  // ── Section: Per-meal ───────────────────────────────────────────────────
  Widget _perMealSection(PerMealRec m, ThemeColors colors) {
    return _sectionShell(
      colors: colors,
      title: 'Per-meal split',
      section: _RecSection.perMeal,
      onApply: () => _applyPerMeal(m),
      children: [
        ...m.meals.entries.map((e) => _mealMiniRow(e.key, e.value, colors)),
        if (m.reasoning.isNotEmpty) ...[
          const SizedBox(height: 9),
          _whyLine(m.reasoning, colors),
        ],
      ],
    );
  }

  Widget _mealMiniRow(String mealId, MacroTriple t, ThemeColors colors) {
    final pColor = _macroColor(colors.isDark, 'p');
    final cColor = _macroColor(colors.isDark, 'c');
    final fColor = _macroColor(colors.isDark, 'f');
    final kcal = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            _mealLabel(mealId),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 11.5),
              children: [
                TextSpan(
                  text: '${t.proteinG}P',
                  style: TextStyle(
                      color: pColor, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                    text: ' · ', style: TextStyle(color: colors.textMuted)),
                TextSpan(
                  text: '${t.carbsG}C',
                  style: TextStyle(
                      color: cColor, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                    text: ' · ', style: TextStyle(color: colors.textMuted)),
                TextSpan(
                  text: '${t.fatG}F',
                  style: TextStyle(
                      color: fColor, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '  ·  $kcal kcal',
                  style: TextStyle(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Per-day ────────────────────────────────────────────────────
  Widget _perDaySection(PerDayRec p, ThemeColors colors) {
    final highSet = p.highDays.toSet();
    return _sectionShell(
      colors: colors,
      title: 'By-day (high / base)',
      section: _RecSection.perDay,
      onApply: () => _applyPerDay(p),
      children: [
        // Mon..Sun chips, high days highlighted.
        Row(
          children: List.generate(7, (i) {
            final isHigh = highSet.contains(i);
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 6 ? 0 : 5),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isHigh
                      ? colors.accent.withValues(alpha: 0.16)
                      : colors.elevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHigh
                        ? colors.accent.withValues(alpha: 0.5)
                        : colors.cardBorder,
                  ),
                ),
                child: Text(
                  _weekdayLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isHigh ? colors.accent : colors.textMuted,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 9),
        if (p.bindToTrainingDays) ...[
          Text(
            'High days follow your training schedule',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 7),
        ],
        _highBaseRow('High days', p.high, colors.accent, colors),
        const SizedBox(height: 4),
        _highBaseRow('Base days', p.base, colors.textMuted, colors),
        if (p.reasoning.isNotEmpty) ...[
          const SizedBox(height: 9),
          _whyLine(p.reasoning, colors),
        ],
      ],
    );
  }

  Widget _highBaseRow(
      String label, MacroTriple t, Color labelColor, ThemeColors colors) {
    final pColor = _macroColor(colors.isDark, 'p');
    final cColor = _macroColor(colors.isDark, 'c');
    final fColor = _macroColor(colors.isDark, 'f');
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            children: [
              TextSpan(text: 'P${t.proteinG}', style: TextStyle(color: pColor)),
              TextSpan(
                  text: '  C${t.carbsG}', style: TextStyle(color: cColor)),
              TextSpan(text: '  F${t.fatG}', style: TextStyle(color: fColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared section shell (title + Apply button + body) ───────────────────
  Widget _sectionShell({
    required ThemeColors colors,
    required String title,
    required _RecSection section,
    required VoidCallback onApply,
    required List<Widget> children,
  }) {
    final applied = _applied.contains(section);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _applyButton(colors, applied, onApply),
            ],
          ),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }

  Widget _applyButton(ThemeColors colors, bool applied, VoidCallback onApply) {
    final accent = colors.accent;
    final success = colors.success;
    return GestureDetector(
      onTap: applied ? null : onApply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: applied ? success.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: applied
                ? success.withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          applied ? 'Applied ✓' : 'Apply',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: applied ? success : accent,
          ),
        ),
      ),
    );
  }

  // ── Stat tile (recommended value + macro-colored Anton numeral + delta) ──
  Widget _statTile(
    ThemeColors colors,
    String value,
    String key,
    Color valueColor,
    int? current,
    int recommended,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: ZType.disp(20, color: valueColor),
            ),
            const SizedBox(height: 3),
            Text(
              key,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: colors.textMuted,
              ),
            ),
            if (current != null) ...[
              const SizedBox(height: 2),
              _deltaChip(colors, current, recommended),
            ],
          ],
        ),
      ),
    );
  }

  /// A small up/down/same delta chip vs the current value. Up = good (green),
  /// down = warn, same = muted — per the brief.
  Widget _deltaChip(ThemeColors colors, int current, int recommended) {
    final delta = recommended - current;
    final String text;
    final Color color;
    if (delta > 0) {
      text = '+$delta';
      color = colors.success;
    } else if (delta < 0) {
      text = '$delta'; // already carries the minus sign
      color = colors.warning;
    } else {
      text = '0';
      color = colors.textMuted;
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  // ── Fraunces "why" line ─────────────────────────────────────────────────
  Widget _whyLine(String text, ThemeColors colors) {
    return Text(
      text,
      style: ZType.ser(
        12.5,
        color: colors.textSecondary,
      ).copyWith(height: 1.45),
    );
  }

  // ── 🛡️ Kept-safe clamp note ─────────────────────────────────────────────
  Widget _clampNote(List<String> clamped, ThemeColors colors) {
    final info = colors.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kept safe',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: info,
                  ),
                ),
                const SizedBox(height: 3),
                ...clamped.map((c) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence chip ─────────────────────────────────────────────────────
  Widget _confidenceChip(String confidence, ThemeColors colors) {
    final Color color;
    final String label;
    switch (confidence) {
      case 'high':
        color = colors.success;
        label = 'High confidence';
        break;
      case 'low':
        color = colors.warning;
        label = 'Low confidence';
        break;
      case 'medium':
      default:
        color = colors.accent;
        label = 'Medium confidence';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }

  // ── Macro colors (mirror the Edit Targets sheet) ─────────────────────────
  Color _macroColor(bool isDark, String macro) {
    switch (macro) {
      case 'p':
        return isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
      case 'c':
        return isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
      case 'f':
      default:
        return isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    }
  }
}

/// Opens the AI recommendation sheet over the Edit Targets sheet.
Future<void> showAiRecommendationSheet(
  BuildContext context, {
  required String userId,
}) {
  return showGlassSheet<void>(
    context: context,
    opaque: true,
    builder: (_) => AiRecommendationSheet(userId: userId),
  );
}
