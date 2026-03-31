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

// ─────────────────────────────────────────────────────────────────
// Weekly Summary Card
// ─────────────────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final WeeklySummaryData summary;
  final bool isDark;

  const _WeeklySummaryCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Days Logged',
                  value: '${summary.daysLogged}/7',
                  icon: Icons.check_circle,
                  color: isDark ? AppColors.green : AppColorsLight.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Calories',
                  value: '${summary.avgCalories}',
                  icon: Icons.local_fire_department,
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Protein',
                  value: '${summary.avgProtein}g',
                  icon: Icons.fitness_center,
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Weight Change',
                  value: _formatWeightChange(summary.weightChange),
                  icon: Icons.trending_flat,
                  color: _getWeightChangeColor(summary.weightChange),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWeightChange(double? change) {
    if (change == null) return 'N/A';
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)} kg';
  }

  Color _getWeightChangeColor(double? change) {
    if (change == null) return Colors.grey;
    if (change.abs() < 0.2) return isDark ? AppColors.cyan : AppColorsLight.cyan; // Stable
    if (change < 0) return isDark ? AppColors.green : AppColorsLight.green; // Loss
    return isDark ? AppColors.orange : AppColorsLight.orange; // Gain
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Detailed TDEE Card (MacroFactor-style with confidence intervals)
// ─────────────────────────────────────────────────────────────────

class _DetailedTdeeCard extends StatelessWidget {
  final DetailedTDEE detailedTdee;
  final bool isDark;

  const _DetailedTdeeCard({required this.detailedTdee, required this.isDark});

  /// Check if we have insufficient data for meaningful calculation
  bool get hasInsufficientData =>
      detailedTdee.tdee == 0 || !detailedTdee.hasReliableData;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Show insufficient data state for first-time users
    if (hasInsufficientData) {
      return _buildInsufficientDataState(textPrimary, textMuted, textSecondary, teal);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.15),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_graph, size: 20, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Adaptive TDEE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'EMA-smoothed calculation',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '${detailedTdee.tdee}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
                // Confidence interval
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detailedTdee.uncertaintyDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'calories/day',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confidence range bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${detailedTdee.confidenceLow}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      'Confidence Range',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    Text(
                      '${detailedTdee.confidenceHigh}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detailedTdee.dataQualityScore,
                    backgroundColor: textMuted.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(teal),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weight trend
          Row(
            children: [
              Text(
                detailedTdee.weightTrend.directionEmoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weight trend: ${detailedTdee.weightTrend.formattedWeeklyRate}',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState(
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
    Color teal,
  ) {
    final dataQualityPercent = (detailedTdee.dataQualityScore * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_empty, size: 32, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            'Building Your Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging your meals and weight to unlock personalized TDEE calculations.',
            style: TextStyle(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.nearBlack : AppColorsLight.nearWhite).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data Quality', style: TextStyle(fontSize: 13, color: textPrimary)),
                    Text(
                      '$dataQualityPercent%',
                      style: TextStyle(
                        fontSize: 13,
                        color: dataQualityPercent >= 60 ? AppColors.textPrimary : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detailedTdee.dataQualityScore,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dataQualityPercent >= 60 ? AppColors.textPrimary : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Need 60% data quality for accurate calculations',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: teal),
              const SizedBox(width: 8),
              Text(
                'Log meals consistently for best results',
                style: TextStyle(
                  fontSize: 13,
                  color: teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Metabolic Adaptation Alert
// ─────────────────────────────────────────────────────────────────

class _MetabolicAdaptationAlert extends StatelessWidget {
  final MetabolicAdaptationInfo adaptation;
  final bool isDark;

  const _MetabolicAdaptationAlert({required this.adaptation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Color based on severity
    Color alertColor;
    switch (adaptation.severity) {
      case 'high':
        alertColor = AppColors.textMuted;
        break;
      case 'medium':
        alertColor = AppColors.textSecondary;
        break;
      default:
        alertColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                adaptation.isPlateau ? Icons.pause_circle : Icons.trending_down,
                color: alertColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  adaptation.isPlateau
                      ? 'Plateau Detected'
                      : 'Metabolic Adaptation Detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adaptation.actionDescription,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: alertColor),
                const SizedBox(width: 8),
                Text(
                  'Suggested: ${adaptation.actionDisplayName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Adherence & Sustainability Card
// ─────────────────────────────────────────────────────────────────

class _AdherenceCard extends StatelessWidget {
  final AdherenceSummary adherence;
  final bool isDark;

  const _AdherenceCard({required this.adherence, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Sustainability color
    Color sustainColor;
    switch (adherence.sustainabilityRating) {
      case 'high':
        sustainColor = AppColors.textPrimary;
        break;
      case 'medium':
        sustainColor = AppColors.textSecondary;
        break;
      default:
        sustainColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Adherence & Sustainability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Adherence and Sustainability scores side by side
          Row(
            children: [
              Expanded(
                child: _ScoreCircle(
                  label: 'Adherence',
                  value: adherence.averageAdherence,
                  color: AppColors.textSecondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScoreCircle(
                  label: 'Sustainability',
                  value: adherence.sustainabilityScore * 100,
                  color: sustainColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sustainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sustainColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    adherence.ratingEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${adherence.sustainabilityRating.toUpperCase()} SUSTAINABILITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sustainColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recommendation text
          if (adherence.recommendation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, size: 16, color: textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adherence.recommendation,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;

  const _ScoreCircle({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${value.round()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Multi-Option Recommendation Card (MacroFactor-style)
// ─────────────────────────────────────────────────────────────────

class _MultiOptionRecommendationCard extends StatelessWidget {
  final RecommendationOptions options;
  final String? selectedOption;
  final int? currentCalories;
  final ValueChanged<String> onOptionSelected;
  final bool isDark;

  const _MultiOptionRecommendationCard({
    required this.options,
    required this.selectedOption,
    this.currentCalories,
    required this.onOptionSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.route, size: 20, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Path',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Select a recommendation based on your preference',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option cards (no Apply button — it's in the sticky CTA)
          ...options.options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendationOptionCard(
              option: option,
              isSelected: selectedOption == option.optionType,
              isRecommended: options.recommendedOption == option.optionType,
              currentCalories: currentCalories,
              onTap: () => onOptionSelected(option.optionType),
              isDark: isDark,
            ),
          )),
        ],
      ),
    );
  }
}

class _RecommendationOptionCard extends StatelessWidget {
  final RecommendationOption option;
  final bool isSelected;
  final bool isRecommended;
  final int? currentCalories;
  final VoidCallback onTap;
  final bool isDark;

  const _RecommendationOptionCard({
    required this.option,
    required this.isSelected,
    required this.isRecommended,
    this.currentCalories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Use accent color for selected state
    final optionColor = teal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? optionColor.withValues(alpha: 0.15)
              : isDark
                  ? Colors.black12
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? optionColor
                : isDark
                    ? Colors.white10
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            option.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: teal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        option.formattedWeeklyChange,
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      if (currentCalories != null && currentCalories! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatCalorieDelta(currentCalories!, option.calories),
                          style: TextStyle(
                            fontSize: 11,
                            color: teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? optionColor : textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: optionColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Macros row
            Row(
              children: [
                _MacroChip(
                  label: '${option.calories} cal',
                  color: teal,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.proteinG}g P',
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.carbsG}g C',
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.fatG}g F',
                  color: isDark ? AppColors.purple : AppColorsLight.purple,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              option.description,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCalorieDelta(int current, int target) {
    final delta = target - current;
    final sign = delta >= 0 ? '+' : '';
    return '$current \u2192 $target ($sign$delta cal)';
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _MacroChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Adaptive TDEE Card (Legacy fallback)
// ─────────────────────────────────────────────────────────────────

class _AdaptiveTdeeCard extends StatelessWidget {
  final AdaptiveCalculation calculation;
  final bool isDark;

  const _AdaptiveTdeeCard({required this.calculation, required this.isDark});

  /// Check if we have insufficient data for meaningful calculation
  bool get hasInsufficientData =>
      calculation.calculatedTdee == 0 || calculation.daysLogged < 6 || calculation.weightEntries < 2;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Show insufficient data state
    if (hasInsufficientData) {
      return _buildInsufficientDataState(textPrimary, textMuted, textSecondary, teal);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.15),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_graph, size: 20, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Adaptive TDEE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Based on actual intake & weight changes',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '${calculation.calculatedTdee}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
                Text(
                  'calories/day',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Confidence indicator
          Row(
            children: [
              Icon(
                calculation.dataQualityScore >= 0.7
                    ? Icons.verified
                    : Icons.info_outline,
                size: 16,
                color: calculation.dataQualityScore >= 0.7
                    ? AppColors.textPrimary
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getConfidenceMessage(calculation.dataQualityScore),
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState(
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
    Color teal,
  ) {
    final daysNeeded = 6 - calculation.daysLogged;
    final weightsNeeded = 2 - calculation.weightEntries;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_empty, size: 32, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep Logging!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need a bit more data to calculate your personalized TDEE.',
            style: TextStyle(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Progress indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.nearBlack : AppColorsLight.nearWhite).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Food logging progress
                _buildProgressRow(
                  icon: Icons.restaurant,
                  label: 'Food Logging',
                  current: calculation.daysLogged,
                  target: 6,
                  color: calculation.daysLogged >= 6 ? AppColors.textPrimary : Colors.orange,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),
                // Weight logging progress
                _buildProgressRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight Logs',
                  current: calculation.weightEntries,
                  target: 2,
                  color: calculation.weightEntries >= 2 ? AppColors.textPrimary : Colors.orange,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Helpful tips
          Text(
            daysNeeded > 0 && weightsNeeded > 0
                ? 'Log meals for $daysNeeded more day${daysNeeded > 1 ? 's' : ''} and add $weightsNeeded weight${weightsNeeded > 1 ? 's' : ''}'
                : daysNeeded > 0
                    ? 'Log meals for $daysNeeded more day${daysNeeded > 1 ? 's' : ''} to unlock insights'
                    : 'Add $weightsNeeded more weight log${weightsNeeded > 1 ? 's' : ''} to unlock insights',
            style: TextStyle(
              fontSize: 13,
              color: teal,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: textPrimary)),
                  Text(
                    isComplete ? 'Complete!' : '$current / $target days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isComplete ? AppColors.textPrimary : textMuted,
                      fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getConfidenceMessage(double score) {
    if (score >= 0.8) {
      return 'High confidence - Based on ${(score * 100).round()}% data quality';
    } else if (score >= 0.5) {
      return 'Moderate confidence - Log more consistently for better accuracy';
    } else {
      return 'Low confidence - Need more data for accurate calculation';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Recommendation Card (Legacy fallback)
// ─────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final WeeklyRecommendation recommendation;
  final bool isDark;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final primaryColor = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recommended Adjustment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendation.adjustmentReason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 20, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation.adjustmentReason!,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // New targets
          Text(
            'New Targets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TargetItem(
                  label: 'Calories',
                  value: '${recommendation.recommendedCalories}',
                  unit: 'kcal',
                  color: primaryColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Protein',
                  value: '${recommendation.recommendedProteinG}',
                  unit: 'g',
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TargetItem(
                  label: 'Carbs',
                  value: '${recommendation.recommendedCarbsG}',
                  unit: 'g',
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Fat',
                  value: '${recommendation.recommendedFatG}',
                  unit: 'g',
                  color: isDark ? AppColors.purple : AppColorsLight.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _TargetItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// No Recommendation Card
// ─────────────────────────────────────────────────────────────────

class _NoRecommendationCard extends StatelessWidget {
  final bool isDark;

  const _NoRecommendationCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: teal),
          const SizedBox(height: 16),
          Text(
            'You\'re On Track!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your current targets are aligned with your progress. Keep up the great work!',
            style: TextStyle(fontSize: 14, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tips Card
// ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final bool isDark;
  final WeeklySummaryData? summary;
  final AdherenceSummary? adherence;

  const _TipsCard({
    required this.isDark,
    this.summary,
    this.adherence,
  });

  List<String> _getContextualTips() {
    final tips = <String>[];

    // Data-driven tips
    if (summary != null && summary!.daysLogged < 5) {
      tips.add('Log meals at least 5 days this week for accurate TDEE');
    }
    if (summary != null && summary!.weightChange == null) {
      tips.add('Add weight entries 2-3x per week at the same time');
    }
    if (adherence != null && adherence!.averageAdherence < 70) {
      tips.add('Focus on hitting your calorie target more consistently');
    }
    if (adherence != null && adherence!.sustainabilityRating == 'low') {
      tips.add('Consider a more moderate approach for long-term adherence');
    }

    // Fill with defaults if we don't have enough contextual tips
    if (tips.isEmpty || (summary == null && adherence == null)) {
      tips.clear();
      tips.addAll([
        'Log meals consistently for more accurate TDEE calculations',
        'Weigh yourself 2-3 times per week at the same time',
        'Focus on weekly trends, not daily fluctuations',
      ]);
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tips = _getContextualTips();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, size: 18, color: textMuted),
              const SizedBox(width: 8),
              Text(
                'Tips for Better Results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => _TipItem(text: tip, isDark: isDark)),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipItem({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 14, color: ThemeColors.of(context).accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
          ),
        ),
      ],
    );
  }
}
