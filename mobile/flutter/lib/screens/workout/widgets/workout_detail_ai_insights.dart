import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/workout_generation_params.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../widgets/glass_sheet.dart';
import 'workout_detail_helpers.dart';

/// Mixin providing AI insights, reasoning, and parameters modal functionality
/// for the WorkoutDetailScreen.
mixin WorkoutDetailAIInsightsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {

  /// Strip markdown formatting from text
  String stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'^-\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^•\s*', multiLine: true), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1')
        .trim();
  }

  /// Get color from string name
  Color getColorFromName(String colorName, Color accentColor) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return accentColor;
      case 'purple':
        return accentColor;
      case 'orange':
        return AppColors.orange;
      case 'green':
        return AppColors.green;
      default:
        return accentColor;
    }
  }

  /// Parse structured JSON insights
  Map<String, dynamic>? parseInsightsJson(String? summary) {
    if (summary == null) return null;
    try {
      return json.decode(summary) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('\u26a0\ufe0f [WorkoutDetail] Failed to parse insights JSON: $e');
      return null;
    }
  }

  /// Build workout summary section widget
  Widget buildWorkoutSummarySection({
    required String? workoutSummary,
    required bool isLoadingSummary,
    required VoidCallback onTapInsights,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;

    final insights = parseInsightsJson(workoutSummary);
    String? shortPreview;
    String? previewBody;

    if (insights != null) {
      shortPreview = insights['headline'] as String?;
      final sections = insights['sections'] as List<dynamic>?;
      if (sections != null && sections.isNotEmpty) {
        previewBody = sections.first['content'] as String?;
      }
    } else if (workoutSummary != null) {
      final cleanSummary = stripMarkdown(workoutSummary);
      final words = cleanSummary.split(' ');
      if (words.length <= 6) {
        shortPreview = cleanSummary;
      } else {
        shortPreview = '${words.take(6).join(' ')}...';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: workoutSummary != null ? onTapInsights : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.15),
                accentColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI INSIGHTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isLoadingSummary)
                      Text(
                        'Generating insights...',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (shortPreview != null) ...[
                      Text(
                        shortPreview,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (previewBody != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          previewBody,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isLoadingSummary && workoutSummary != null)
                Icon(
                  Icons.open_in_new,
                  color: accentColor.withValues(alpha: 0.7),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show AI insights in a draggable popup modal with formatted sections
  void showAIInsightsPopup({
    required String summaryJson,
    required String workoutId,
    required void Function(String newSummary) onSummaryUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentColor = ref.colors(context).accent;

    var currentSummary = summaryJson;
    var insights = parseInsightsJson(currentSummary);
    var headline = insights?['headline'] as String? ?? 'Workout Insights';
    var sections = (insights?['sections'] as List<dynamic>?) ?? [];
    var isRegenerating = false;

    showGlassSheet(
      context: context,
      builder: (modalContext) => GlassSheet(
        maxHeightFraction: 0.6,
        child: StatefulBuilder(
        builder: (sheetContext, setModalState) {
          Future<void> regenerateInsights() async {
            setModalState(() => isRegenerating = true);
            try {
              final workoutRepo = ref.read(workoutRepositoryProvider);
              final newSummary = await workoutRepo.regenerateWorkoutSummary(workoutId);
              if (newSummary != null) {
                currentSummary = newSummary;
                insights = parseInsightsJson(newSummary);
                headline = insights?['headline'] as String? ?? 'Workout Insights';
                sections = (insights?['sections'] as List<dynamic>?) ?? [];
                onSummaryUpdated(newSummary);
              }
            } catch (e) {
              debugPrint('\u274c Error regenerating insights: $e');
            }
            setModalState(() => isRegenerating = false);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.3),
                            accentColor.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        headline,
                        style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isRegenerating ? null : regenerateInsights,
                      tooltip: 'Regenerate insights',
                      icon: isRegenerating
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                            )
                          : Icon(Icons.refresh, color: accentColor),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),
              Flexible(
                child: isRegenerating
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: accentColor),
                            const SizedBox(height: 16),
                            Text('Generating new insights...', style: TextStyle(color: textMuted)),
                          ],
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (sections.isNotEmpty)
                            ...sections.map((section) {
                              final icon = section['icon'] as String? ?? '\u{1F4A1}';
                              final title = section['title'] as String? ?? 'Tip';
                              final content = section['content'] as String? ?? '';
                              final colorName = section['color'] as String? ?? 'cyan';
                              final color = getColorFromName(colorName, accentColor);
                              return _buildInsightSection(icon, title, content, color, textPrimary);
                            })
                          else
                            Text(
                              stripMarkdown(currentSummary),
                              style: TextStyle(fontSize: 15, color: textPrimary, height: 1.6),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildInsightSection(String icon, String title, String content, Color color, Color textPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(content, style: TextStyle(fontSize: 14, color: textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build targeted muscles section - compact version
  Widget buildTargetedMusclesSection(List<String> muscles) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final shortMuscles = muscles
        .map(_shortenMuscleName)
        .where((m) => m.isNotEmpty)
        .toSet()
        .take(6)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.accessibility_new, color: accentColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: shortMuscles.map((muscle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscle,
                      style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  String _shortenMuscleName(String muscle) {
    final match = RegExp(r'^([^(]+)').firstMatch(muscle);
    if (match != null) return match.group(1)!.trim();
    if (muscle.contains(',')) return muscle.split(',').first.trim();
    return muscle.trim();
  }

  /// Build AI Reasoning section
  Widget buildAIReasoningSection({
    required WorkoutGenerationParams? generationParams,
    required bool isLoadingParams,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onViewParameters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isExpanded ? 0 : 12),
                  bottomRight: Radius.circular(isExpanded ? 0 : 12),
                ),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology, color: AppColors.green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHY THESE EXERCISES?',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        if (isLoadingParams)
                          Text('Loading AI reasoning...',
                            style: TextStyle(fontSize: 13, color: textSecondary, fontStyle: FontStyle.italic))
                        else
                          Text('Tap to see AI reasoning for exercise selection',
                            style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.green, size: 22),
                ],
              ),
            ),
          ),
          if (isExpanded && generationParams != null)
            Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.auto_awesome, color: accentColor, size: 16),
                          const SizedBox(width: 8),
                          Text('Workout Design',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                        ]),
                        const SizedBox(height: 8),
                        Text(generationParams.workoutReasoning,
                          style: TextStyle(fontSize: 13, color: textPrimary, height: 1.5)),
                      ],
                    ),
                  ),
                  Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),
                  if (generationParams.exerciseReasoning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.fitness_center, color: accentColor, size: 16),
                            const SizedBox(width: 8),
                            Text('Exercise Selection',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                          ]),
                          const SizedBox(height: 12),
                          ...generationParams.exerciseReasoning.take(5).map((er) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(top: 6, right: 10),
                                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(er.exerciseName,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(er.reasoning,
                                          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (generationParams.exerciseReasoning.length > 5)
                            Text('+ ${generationParams.exerciseReasoning.length - 5} more exercises...',
                              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: onViewParameters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune, color: AppColors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text('View All Parameters Sent to AI',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show modal with all parameters sent to AI
  void showViewParametersModal(WorkoutGenerationParams params) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    showGlassSheet(
      context: context,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (scrollCtx, scrollController) => GlassSheet(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.orange.withValues(alpha: 0.3),
                          accentColor.withValues(alpha: 0.2),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('AI Generation Parameters',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: textPrimary)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildParamsSection(
                      title: 'User Profile', icon: Icons.person, color: accentColor,
                      items: [
                        if (params.userProfile.fitnessLevel != null)
                          ParamItem('Fitness Level', params.userProfile.fitnessLevel!.capitalize()),
                        if (params.userProfile.goals.isNotEmpty)
                          ParamItem('Goals', params.userProfile.goals.join(', ')),
                        if (params.userProfile.equipment.isNotEmpty)
                          ParamItem('Equipment', params.userProfile.equipment.join(', ')),
                        if (params.userProfile.injuries.isNotEmpty)
                          ParamItem('Injuries/Limitations', params.userProfile.injuries.join(', ')),
                        if (params.userProfile.age != null)
                          ParamItem('Age', '${params.userProfile.age}'),
                        if (params.userProfile.gender != null)
                          ParamItem('Gender', params.userProfile.gender!.capitalize()),
                      ],
                      textPrimary: textPrimary, textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    _buildParamsSection(
                      title: 'Program Preferences', icon: Icons.settings, color: accentColor,
                      items: [
                        if (params.programPreferences.difficulty != null)
                          ParamItem('Difficulty', DifficultyUtils.getDisplayName(params.programPreferences.difficulty!)),
                        if (params.programPreferences.durationMinutes != null)
                          ParamItem('Duration', '${params.programPreferences.durationMinutes} min'),
                        if (params.programPreferences.workoutType != null)
                          ParamItem('Workout Type', params.programPreferences.workoutType!.capitalize()),
                        if (params.programPreferences.trainingSplit != null)
                          ParamItem('Training Split', params.programPreferences.trainingSplit!.replaceAll('_', ' ').capitalize()),
                        if (params.programPreferences.focusAreas.isNotEmpty)
                          ParamItem('Focus Areas', params.programPreferences.focusAreas.join(', ')),
                        if (params.programPreferences.workoutDays.isNotEmpty)
                          ParamItem('Workout Days', params.programPreferences.workoutDays.join(', ')),
                      ],
                      textPrimary: textPrimary, textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    _buildParamsSection(
                      title: 'Workout Specifics', icon: Icons.fitness_center, color: AppColors.green,
                      items: [
                        ParamItem('Workout Name', params.workoutName ?? 'N/A'),
                        ParamItem('Type', (params.workoutType ?? 'N/A').capitalize()),
                        ParamItem('Difficulty', params.difficulty != null ? DifficultyUtils.getDisplayName(params.difficulty!) : 'N/A'),
                        ParamItem('Duration', '${params.durationMinutes ?? 0} min'),
                        ParamItem('Generation Method', (params.generationMethod ?? 'ai').toUpperCase()),
                        if (params.targetMuscles.isNotEmpty)
                          ParamItem('Target Muscles', params.targetMuscles.join(', ')),
                      ],
                      textPrimary: textPrimary, textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: accentColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These parameters were used by the AI to generate personalized exercises that match your fitness level, goals, and available equipment.',
                              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParamsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<ParamItem> items,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final validItems = items.where((item) => item.value.isNotEmpty && item.value != 'N/A').toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: validItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(item.label, style: TextStyle(fontSize: 12, color: textSecondary)),
                      ),
                      Expanded(
                        child: Text(item.value,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// capitalize() extension is provided by WorkoutDetailStringExtension
// from workout_detail_helpers.dart
