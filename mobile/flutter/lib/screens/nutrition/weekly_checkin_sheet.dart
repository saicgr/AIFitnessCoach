import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition_preferences.dart';
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
    builder: (context) => WeeklyCheckinSheet(userId: userId, isDark: isDark),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Weekly check-in sheet with adaptive TDEE and recommendations
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
  WeeklyRecommendation? _recommendation;
  AdaptiveCalculation? _adaptiveCalc;
  WeeklySummaryData? _weeklySummary;

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

      // Trigger calculation of adaptive TDEE
      final adaptiveCalc = await repository.calculateAdaptiveTdee(widget.userId);

      // Get weekly summary
      final weeklySummary = await repository.getWeeklySummary(widget.userId);

      // Get any pending recommendation or generate one
      final recommendation = await repository.getWeeklyRecommendation(widget.userId);

      if (mounted) {
        setState(() {
          _adaptiveCalc = adaptiveCalc;
          _weeklySummary = weeklySummary;
          _recommendation = recommendation;
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        'Review your progress & adjust targets',
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

                            // Adaptive TDEE Section
                            if (_adaptiveCalc != null)
                              _AdaptiveTdeeCard(
                                calculation: _adaptiveCalc!,
                                isDark: isDark,
                              ),
                            const SizedBox(height: 20),

                            // Recommendation Section
                            if (_recommendation != null)
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
                  color: const Color(0xFF6BCB77),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Calories',
                  value: '${summary.avgCalories}',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFFF6B6B),
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
                  color: const Color(0xFFFFD93D),
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
    if (change.abs() < 0.2) return const Color(0xFF6BCB77); // Stable
    if (change < 0) return const Color(0xFF4D96FF); // Loss
    return const Color(0xFFFF9800); // Gain
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
// Adaptive TDEE Card
// ─────────────────────────────────────────────────────────────────

class _AdaptiveTdeeCard extends StatelessWidget {
  final AdaptiveCalculation calculation;
  final bool isDark;

  const _AdaptiveTdeeCard({required this.calculation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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
                    ? const Color(0xFF6BCB77)
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
// Recommendation Card
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
                  color: const Color(0xFFFF6B6B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Protein',
                  value: '${recommendation.recommendedProteinG}',
                  unit: 'g',
                  color: const Color(0xFFFFD93D),
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
                  color: const Color(0xFF6BCB77),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Fat',
                  value: '${recommendation.recommendedFatG}',
                  unit: 'g',
                  color: const Color(0xFF4D96FF),
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
          Icon(Icons.check, size: 14, color: const Color(0xFF6BCB77)),
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

// Models imported from '../../data/models/nutrition_preferences.dart':
// - WeeklySummaryData
// - AdaptiveCalculation
// - WeeklyRecommendation
