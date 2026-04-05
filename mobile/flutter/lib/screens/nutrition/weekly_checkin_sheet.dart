import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/main_shell.dart';

part 'weekly_checkin_sheet_part_weekly_summary_card.dart';
part 'weekly_checkin_sheet_part_recommendation_option_card.dart';


/// Shows the weekly check-in bottom sheet from anywhere in the app
Future<void> showWeeklyCheckinSheet(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final userId = await ref.read(apiClientProvider).getUserId();

  if (userId == null || !context.mounted) return;

  // First time = never completed a check-in AND never dismissed before
  final prefs = ref.read(nutritionPreferencesProvider).preferences;
  final isFirstTime = prefs != null &&
      prefs.lastWeeklyCheckinAt == null &&
      prefs.weeklyCheckinDismissCount == 0;

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  final result = await showGlassSheet<bool>(
    context: context,
    builder: (context) => GlassSheet(
      child: WeeklyCheckinSheet(userId: userId, isDark: isDark, isFirstTime: isFirstTime),
    ),
  );

  // Track dismiss without completing — increment DB counter
  if (result != true) {
    final prefsState = ref.read(nutritionPreferencesProvider);
    if (prefsState.preferences != null) {
      final currentCount = prefsState.preferences!.weeklyCheckinDismissCount;
      try {
        await ref.read(nutritionPreferencesProvider.notifier).savePreferences(
          userId: userId,
          preferences: prefsState.preferences!.copyWith(
            weeklyCheckinDismissCount: currentCount + 1,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ [WeeklyCheckin] Failed to save dismiss count: $e');
      }
    }
  }

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Weekly check-in sheet with MacroFactor-style adaptive TDEE and recommendations
class WeeklyCheckinSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final bool isFirstTime;

  const WeeklyCheckinSheet({
    super.key,
    required this.userId,
    required this.isDark,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<WeeklyCheckinSheet> createState() => _WeeklyCheckinSheetState();
}

class _WeeklyCheckinSheetState extends ConsumerState<WeeklyCheckinSheet> {
  bool _isLoading = true;
  String? _error;
  late bool _showIntro;

  // Legacy data
  WeeklyRecommendation? _recommendation;
  AdaptiveCalculation? _adaptiveCalc;
  WeeklySummaryData? _weeklySummary;

  // New MacroFactor-style data
  WeeklyCheckinData? _checkinData;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _showIntro = widget.isFirstTime;
    if (!_showIntro) _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // Load all data in parallel with 15s timeout
      final results = await Future.wait([
        repository.getWeeklyCheckinData(widget.userId),
        repository.calculateAdaptiveTdee(widget.userId).catchError((_) => null),
        repository.getWeeklyRecommendation(widget.userId).catchError((_) => null),
      ]).timeout(const Duration(seconds: 15));

      final checkinData = results[0] as WeeklyCheckinData?;
      final adaptiveCalc = results[1] as AdaptiveCalculation?;
      final recommendation = results[2] as WeeklyRecommendation?;

      // Use weeklySummary from checkinData (already fetched inside getWeeklyCheckinData)
      // Only fetch separately if null
      WeeklySummaryData? weeklySummary = checkinData?.weeklySummary;
      if (weeklySummary == null) {
        try {
          weeklySummary = await repository.getWeeklySummary(widget.userId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _checkinData = checkinData;
          _adaptiveCalc = adaptiveCalc;
          _weeklySummary = weeklySummary;
          _recommendation = recommendation;
          _isLoading = false;

          // Pre-select the recommended option only if user hasn't chosen yet
          if (_selectedOption == null &&
              checkinData?.recommendationOptions?.recommendedOption != null) {
            _selectedOption = checkinData!.recommendationOptions!.recommendedOption;
          }
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Loading timed out. Check your connection and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectRecommendationOption(String optionType) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final success = await repository.selectRecommendationOption(
        userId: widget.userId,
        optionType: optionType,
      );

      if (success) {
        // Record the weekly check-in completion
        await ref.read(nutritionPreferencesProvider.notifier).recordWeeklyCheckin(
          userId: widget.userId,
        );


        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackbar('Targets updated! Your new $optionType plan is active.');
        }
      } else {
        throw Exception('Failed to apply recommendation');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDisableConfirmation(Color textPrimary, Color textMuted, Color teal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Disable Weekly Check-In?',
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ll miss out on:',
                style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildAdvantageRow(Icons.trending_up_rounded, 'Auto-adjusted calorie targets based on your real progress', textPrimary),
              const SizedBox(height: 10),
              _buildAdvantageRow(Icons.analytics_rounded, 'Weekly adherence & sustainability scores', textPrimary),
              const SizedBox(height: 10),
              _buildAdvantageRow(Icons.lightbulb_rounded, 'Personalized tips to stay on track', textPrimary),
              const SizedBox(height: 10),
              _buildAdvantageRow(Icons.speed_rounded, 'TDEE recalculation from actual weight trends', textPrimary),
              const SizedBox(height: 16),
              Text(
                'You can re-enable this anytime in Nutrition Settings.',
                style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep It', style: TextStyle(color: teal, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Disable', style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final prefsState = ref.read(nutritionPreferencesProvider);
        if (prefsState.preferences != null) {
          await ref.read(nutritionPreferencesProvider.notifier).savePreferences(
            userId: widget.userId,
            preferences: prefsState.preferences!.copyWith(weeklyCheckinEnabled: false),
          );
        }
      } catch (e) {
        debugPrint('⚠️ [WeeklyCheckin] Failed to disable: $e');
      }
      if (mounted) Navigator.pop(context, false);
    }
  }

  Widget _buildAdvantageRow(IconData icon, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRecommendation() async {
    if (_recommendation == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.respondToRecommendation(
        userId: widget.userId,
        recommendationId: _recommendation!.id,
        accepted: true,
      );

      // Record the weekly check-in completion
      await ref.read(nutritionPreferencesProvider.notifier).recordWeeklyCheckin(
        userId: widget.userId,
      );
      // Dismiss counter is reset inside recordWeeklyCheckin

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackbar('Targets updated! Your new goals are active.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineRecommendation() async {
    if (_recommendation == null) return;

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.respondToRecommendation(
        userId: widget.userId,
        recommendationId: _recommendation!.id,
        accepted: false,
      );

      // Record the weekly check-in completion (declining also counts)
      await ref.read(nutritionPreferencesProvider.notifier).recordWeeklyCheckin(
        userId: widget.userId,
      );
      // Dismiss counter is reset inside recordWeeklyCheckin

      if (mounted) {
        Navigator.pop(context, true);
        _showInfoSnackbar('Keeping your current targets.');
      }
    } catch (e) {
      debugPrint('Error declining recommendation: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: widget.isDark ? AppColors.success : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    final teal = ThemeColors.of(context).accent;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context, Color textPrimary, Color textMuted, Color teal) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.insights, color: teal, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Check-In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Appears once a week',
                        style: TextStyle(fontSize: 14, color: textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero description
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: teal.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Every week, FitWiz analyses your food logs to calculate how many calories your body is actually burning — then suggests smarter calorie & macro targets based on your real progress.',
                      style: TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'What happens each week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildIntroStep(
                    number: '1',
                    title: 'We analyse your week',
                    description: 'Your logged meals and weight data are used to calculate your real TDEE — more accurate than any formula.',
                    color: teal,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    elevated: elevated,
                    cardBorder: cardBorder,
                  ),
                  const SizedBox(height: 12),
                  _buildIntroStep(
                    number: '2',
                    title: 'You see 2–3 plan options',
                    description: 'Conservative, Moderate, or Aggressive — each with different calorie targets and expected weekly change.',
                    color: teal,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    elevated: elevated,
                    cardBorder: cardBorder,
                  ),
                  const SizedBox(height: 12),
                  _buildIntroStep(
                    number: '3',
                    title: 'You choose — or skip',
                    description: 'Pick a plan to update your targets, or skip to keep things as they are. Nothing changes automatically.',
                    color: teal,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    elevated: elevated,
                    cardBorder: cardBorder,
                  ),

                  const SizedBox(height: 24),

                  // Disable hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 18, color: textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can turn this off anytime in Nutrition Settings → Weekly Check-in Reminders.',
                            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showIntro = false;
                    _isLoading = true;
                  });
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it — Show My Check-In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroStep({
    required String number,
    required String title,
    required String description,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required Color elevated,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, Color textPrimary, Color textMuted, Color teal) {
    final isDark = widget.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.insights, color: teal, size: 22),
            const SizedBox(width: 10),
            Text(
              'What is Weekly Check-In?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.calculate_outlined,
              color: teal,
              text: 'Analyzes your actual food logs to calculate your real calorie burn (TDEE) — more accurate than formulas.',
              textColor: textMuted,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.tune_rounded,
              color: teal,
              text: 'Suggests calorie & macro targets based on your adherence and progress over the past week.',
              textColor: textMuted,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              color: teal,
              text: 'Appears once a week. You choose to apply a new plan or skip — nothing changes automatically.',
              textColor: textMuted,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.settings_outlined,
              color: textMuted,
              text: 'You can turn this off anytime in Nutrition Settings → Weekly Check-in Reminders.',
              textColor: textMuted,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: TextStyle(color: teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Show intro page on first ever open
    if (_showIntro) return _buildIntroPage(context, textPrimary, textMuted, teal);

    // Read current targets for delta display
    final currentCalories = ref.watch(nutritionPreferencesProvider).preferences?.targetCalories;

    final hasMultiOptions = _checkinData?.hasMultipleOptions ?? false;
    final hasLegacyRec = _recommendation != null;
    final showStickyCta = !_isLoading && _error == null;

    return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
        children: [
          // Header (fixed)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.insights, color: teal, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Check-In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Review progress & choose your path',
                        style: TextStyle(fontSize: 14, color: textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showInfoDialog(context, textPrimary, textMuted, teal),
                  icon: Icon(Icons.help_outline_rounded, color: textMuted, size: 22),
                  tooltip: 'What is this?',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: teal),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzing your progress...',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? _buildErrorState(textPrimary, textMuted, teal)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // RECOMMENDATIONS FIRST (above fold)
                            if (hasMultiOptions)
                              _MultiOptionRecommendationCard(
                                options: _checkinData!.recommendationOptions!,
                                selectedOption: _selectedOption,
                                currentCalories: currentCalories,
                                onOptionSelected: (option) {
                                  setState(() => _selectedOption = option);
                                },
                                isDark: isDark,
                              )
                            else if (hasLegacyRec)
                              _RecommendationCard(
                                recommendation: _recommendation!,
                                isDark: isDark,
                              )
                            else
                              _NoRecommendationCard(isDark: isDark),
                            const SizedBox(height: 20),

                            // Weekly Summary Section
                            if (_weeklySummary != null)
                              _WeeklySummaryCard(
                                summary: _weeklySummary!,
                                isDark: isDark,
                              ),
                            if (_weeklySummary != null)
                              const SizedBox(height: 20),

                            // Enhanced TDEE Section with Confidence Intervals
                            if (_checkinData?.detailedTdee != null)
                              _DetailedTdeeCard(
                                detailedTdee: _checkinData!.detailedTdee!,
                                isDark: isDark,
                              )
                            else if (_adaptiveCalc != null)
                              _AdaptiveTdeeCard(
                                calculation: _adaptiveCalc!,
                                isDark: isDark,
                              ),
                            if (_checkinData?.detailedTdee != null || _adaptiveCalc != null)
                              const SizedBox(height: 20),

                            // Metabolic Adaptation Alert (if detected)
                            if (_checkinData?.hasMetabolicAdaptation ?? false)
                              _MetabolicAdaptationAlert(
                                adaptation: _checkinData!.detailedTdee!.metabolicAdaptation!,
                                isDark: isDark,
                              ),
                            if (_checkinData?.hasMetabolicAdaptation ?? false)
                              const SizedBox(height: 20),

                            // Adherence & Sustainability Section
                            if (_checkinData?.adherenceSummary != null)
                              _AdherenceCard(
                                adherence: _checkinData!.adherenceSummary!,
                                isDark: isDark,
                              ),
                            if (_checkinData?.adherenceSummary != null)
                              const SizedBox(height: 20),

                            // Contextual Tips Section
                            _TipsCard(
                              isDark: isDark,
                              summary: _weeklySummary,
                              adherence: _checkinData?.adherenceSummary,
                            ),
                          ],
                        ),
                      ),
          ),

          // Sticky bottom CTA (pinned outside scroll)
          if (showStickyCta) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMultiOptions) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedOption != null
                            ? () => _selectRecommendationOption(_selectedOption!)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: teal.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedOption != null
                              ? 'Apply ${_getOptionDisplayName(_selectedOption!)} Plan'
                              : 'Select a Plan',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ] else if (hasLegacyRec) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _declineRecommendation,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: textMuted),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Keep Current',
                                style: TextStyle(color: textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _acceptRecommendation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Apply Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Skip this week',
                      style: TextStyle(color: textMuted, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showDisableConfirmation(textPrimary, textMuted, teal),
                    child: Text(
                      'Don\'t show this again',
                      style: TextStyle(
                        color: textMuted.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getOptionDisplayName(String optionType) {
    switch (optionType) {
      case 'aggressive':
        return 'Aggressive';
      case 'moderate':
        return 'Moderate';
      case 'conservative':
        return 'Conservative';
      default:
        return optionType;
    }
  }

  Widget _buildErrorState(Color textPrimary, Color textMuted, Color teal) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please try again later',
              style: TextStyle(fontSize: 14, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
