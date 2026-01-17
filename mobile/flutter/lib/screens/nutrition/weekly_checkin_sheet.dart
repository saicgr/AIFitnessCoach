import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';

/// Shows the weekly check-in bottom sheet from anywhere in the app
Future<void> showWeeklyCheckinSheet(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final userId = await ref.read(apiClientProvider).getUserId();

  if (userId == null || !context.mounted) return;

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    builder: (context) => WeeklyCheckinSheet(userId: userId, isDark: isDark),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Weekly check-in sheet with MacroFactor-style adaptive TDEE and recommendations
class WeeklyCheckinSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const WeeklyCheckinSheet({super.key, required this.userId, required this.isDark});

  @override
  ConsumerState<WeeklyCheckinSheet> createState() => _WeeklyCheckinSheetState();
}

class _WeeklyCheckinSheetState extends ConsumerState<WeeklyCheckinSheet> {
  bool _isLoading = true;
  String? _error;

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // Try to load enhanced MacroFactor-style data first
      final checkinData = await repository.getWeeklyCheckinData(widget.userId);

      // Also load legacy data for fallback
      final adaptiveCalc = await repository.calculateAdaptiveTdee(widget.userId);
      final weeklySummary = await repository.getWeeklySummary(widget.userId);
      final recommendation = await repository.getWeeklyRecommendation(widget.userId);

      if (mounted) {
        setState(() {
          _checkinData = checkinData;
          _adaptiveCalc = adaptiveCalc;
          _weeklySummary = weeklySummary;
          _recommendation = recommendation;
          _isLoading = false;

          // Pre-select the recommended option
          if (checkinData?.recommendationOptions?.recommendedOption != null) {
            _selectedOption = checkinData!.recommendationOptions!.recommendedOption;
          }
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
          Navigator.pop(context);
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

      if (mounted) {
        Navigator.pop(context);
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

      if (mounted) {
        Navigator.pop(context);
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
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

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
                        'Review progress & choose your path',
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
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weekly Summary Section
                            if (_weeklySummary != null)
                              _WeeklySummaryCard(
                                summary: _weeklySummary!,
                                isDark: isDark,
                              ),
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

                            // Multi-Option Recommendations (MacroFactor-style)
                            if (_checkinData?.hasMultipleOptions ?? false)
                              _MultiOptionRecommendationCard(
                                options: _checkinData!.recommendationOptions!,
                                selectedOption: _selectedOption,
                                onOptionSelected: (option) {
                                  setState(() => _selectedOption = option);
                                },
                                onApply: () {
                                  if (_selectedOption != null) {
                                    _selectRecommendationOption(_selectedOption!);
                                  }
                                },
                                isDark: isDark,
                              )
                            // Fallback to single recommendation
                            else if (_recommendation != null)
                              _RecommendationCard(
                                recommendation: _recommendation!,
                                isDark: isDark,
                                onAccept: _acceptRecommendation,
                                onDecline: _declineRecommendation,
                              )
                            else
                              _NoRecommendationCard(isDark: isDark),

                            const SizedBox(height: 24),

                            // Tips Section
                            _TipsCard(isDark: isDark),
                          ],
                        ),
                      ),
          ),
        ],
      ),
        ),
      ),
    );
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
                  color: AppColors.textPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Calories',
                  value: '${summary.avgCalories}',
                  icon: Icons.local_fire_department,
                  color: AppColors.textMuted,
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
                  color: AppColors.textSecondary,
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
    if (change.abs() < 0.2) return AppColors.textPrimary; // Stable
    if (change < 0) return AppColors.textSecondary; // Loss
    return AppColors.textSecondary; // Gain
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onApply;
  final bool isDark;

  const _MultiOptionRecommendationCard({
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onApply,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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

          // Option cards
          ...options.options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendationOptionCard(
              option: option,
              isSelected: selectedOption == option.optionType,
              isRecommended: options.recommendedOption == option.optionType,
              onTap: () => onOptionSelected(option.optionType),
              isDark: isDark,
            ),
          )),

          const SizedBox(height: 8),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedOption != null ? onApply : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: teal.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                selectedOption != null
                    ? 'Apply ${_getOptionDisplayName(selectedOption!)} Plan'
                    : 'Select a Plan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
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
}

class _RecommendationOptionCard extends StatelessWidget {
  final RecommendationOption option;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  final bool isDark;

  const _RecommendationOptionCard({
    required this.option,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // Option-specific colors
    Color optionColor;
    switch (option.optionType) {
      case 'aggressive':
        optionColor = AppColors.textMuted;
        break;
      case 'conservative':
        optionColor = AppColors.textPrimary;
        break;
      default:
        optionColor = AppColors.textSecondary;
    }

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
                  color: AppColors.textMuted,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.proteinG}g P',
                  color: AppColors.textSecondary,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.carbsG}g C',
                  color: AppColors.textPrimary,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.fatG}g F',
                  color: AppColors.textSecondary,
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    const primaryColor = Color(0xFF6BCB77); // Green for positive changes

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
                  color: AppColors.textMuted,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Protein',
                  value: '${recommendation.recommendedProteinG}',
                  unit: 'g',
                  color: AppColors.textSecondary,
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
                  color: AppColors.textPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Fat',
                  value: '${recommendation.recommendedFatG}',
                  unit: 'g',
                  color: AppColors.textSecondary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: textMuted),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Keep Current', style: TextStyle(color: textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Changes'),
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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

  const _TipsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

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
          _TipItem(
            text: 'Log meals consistently for more accurate TDEE calculations',
            isDark: isDark,
          ),
          _TipItem(
            text: 'Weigh yourself 2-3 times per week at the same time',
            isDark: isDark,
          ),
          _TipItem(
            text: 'Focus on weekly trends, not daily fluctuations',
            isDark: isDark,
          ),
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
          Icon(Icons.check, size: 14, color: AppColors.textPrimary),
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
