/// Futuristic Set Tracking Card
///
/// A simplified, futuristic set tracking card that focuses on the current set
/// with large touch targets and glowing accents. Uses the new NumberStepper
/// and GlowButton components for gym-friendly UX.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/smart_weight_suggestion.dart';
import '../../../widgets/glow_button.dart';
import '../../../widgets/number_stepper.dart';

/// Futuristic set tracking card for active workout
class FuturisticSetCard extends StatefulWidget {
  /// Exercise name
  final String exerciseName;

  /// Current set number (1-indexed)
  final int currentSetNumber;

  /// Total sets for this exercise
  final int totalSets;

  /// Current weight value
  final double weight;

  /// Current reps value
  final int reps;

  /// Weight increment step (equipment-aware)
  final double weightStep;

  /// Whether using kg or lbs
  final bool useKg;

  /// Previous session weight (optional)
  final double? previousWeight;

  /// Previous session reps (optional)
  final int? previousReps;

  /// Callback when weight changes
  final ValueChanged<double> onWeightChanged;

  /// Callback when reps changes
  final ValueChanged<int> onRepsChanged;

  /// Callback when set is completed
  final VoidCallback onComplete;

  /// Callback to skip to next exercise
  final VoidCallback? onSkip;

  /// List of completed sets info (for mini indicators)
  final List<Map<String, dynamic>> completedSets;

  /// Whether this is the last set
  final bool isLastSet;

  /// Set type (working, warmup, failure)
  final String setType;

  /// Callback when set type changes
  final ValueChanged<String>? onSetTypeChanged;

  /// Smart weight suggestion from AI (optional)
  final SmartWeightSuggestion? smartWeightSuggestion;

  /// Whether the current weight was auto-filled from AI suggestion
  final bool isWeightFromAiSuggestion;

  const FuturisticSetCard({
    super.key,
    required this.exerciseName,
    required this.currentSetNumber,
    required this.totalSets,
    required this.weight,
    required this.reps,
    this.weightStep = 2.5,
    this.useKg = true,
    this.previousWeight,
    this.previousReps,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
    this.onSkip,
    this.completedSets = const [],
    this.isLastSet = false,
    this.setType = 'working',
    this.onSetTypeChanged,
    this.smartWeightSuggestion,
    this.isWeightFromAiSuggestion = false,
  });

  @override
  State<FuturisticSetCard> createState() => _FuturisticSetCardState();
}

class _FuturisticSetCardState extends State<FuturisticSetCard> {
  bool _showPreviousDetails = false;
  bool _showAiTooltip = false;

  Color get _setTypeColor {
    switch (widget.setType) {
      case 'warmup':
        return AppColors.glowOrange;
      case 'failure':
        return AppColors.error;
      default:
        return AppColors.glowCyan;
    }
  }

  String get _setTypeLabel {
    switch (widget.setType) {
      case 'warmup':
        return 'WARMUP';
      case 'failure':
        return 'TO FAILURE';
      default:
        return 'WORKING SET';
    }
  }

  void _cycleSetType() {
    if (widget.onSetTypeChanged == null) return;
    final types = ['working', 'warmup', 'failure'];
    final currentIndex = types.indexOf(widget.setType);
    final nextType = types[(currentIndex + 1) % types.length];
    widget.onSetTypeChanged!(nextType);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.pureBlack.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _setTypeColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _setTypeColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with set info and type badge
              _buildHeader(isDark),

              const SizedBox(height: 8),

              // Completed sets progress dots
              if (widget.completedSets.isNotEmpty || widget.totalSets > 1)
                _buildProgressDots(),

              const SizedBox(height: 20),

              // AI Suggested badge (if weight was auto-filled)
              if (widget.isWeightFromAiSuggestion &&
                  widget.smartWeightSuggestion != null)
                _buildAiSuggestedBadge(isDark),

              // Weight and Reps steppers - use LayoutBuilder for responsive spacing
              LayoutBuilder(
                builder: (context, constraints) {
                  // Reduce spacing on smaller screens
                  final isSmallScreen = constraints.maxWidth < 300;
                  return Row(
                    children: [
                      Expanded(
                        child: NumberStepper.weight(
                          value: widget.weight,
                          onChanged: widget.onWeightChanged,
                          step: widget.weightStep,
                          useKg: widget.useKg,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 16),
                      Expanded(
                        child: NumberStepper.reps(
                          value: widget.reps,
                          onChanged: widget.onRepsChanged,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Complete Set button
              GlowButton.complete(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  widget.onComplete();
                },
                setNumber: widget.currentSetNumber,
                width: double.infinity,
              ),

              // Previous data (collapsible)
              if (widget.previousWeight != null || widget.previousReps != null)
                _buildPreviousSection(isDark),

              // Skip button (if not last set)
              if (widget.onSkip != null && !widget.isLastSet)
                _buildSkipButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available width
        final isSmallScreen = constraints.maxWidth < 300;
        final badgeSize = isSmallScreen ? 36.0 : 44.0;
        final badgeFontSize = isSmallScreen ? 14.0 : 18.0;

        return Row(
          children: [
            // Set number badge (tappable to cycle type)
            GestureDetector(
              onTap: _cycleSetType,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _setTypeColor.withOpacity(0.3),
                      _setTypeColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _setTypeColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _setTypeColor.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.setType == 'warmup'
                        ? 'W'
                        : widget.setType == 'failure'
                            ? 'F'
                            : '${widget.currentSetNumber}',
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                      color: _setTypeColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            // Set info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SET ${widget.currentSetNumber} OF ${widget.totalSets}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: _setTypeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _setTypeLabel,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            // Exercise name (truncated) - only show if there's enough space
            if (!isSmallScreen)
              Flexible(
                child: Text(
                  widget.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalSets, (index) {
        final isCompleted = index < widget.completedSets.length;
        final isCurrent = index == widget.currentSetNumber - 1;

        return Container(
          width: isCurrent ? 12 : 8,
          height: isCurrent ? 12 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.glowGreen
                : isCurrent
                    ? _setTypeColor
                    : Colors.white.withOpacity(0.2),
            border: isCurrent && !isCompleted
                ? Border.all(color: _setTypeColor, width: 2)
                : null,
            boxShadow: isCompleted || isCurrent
                ? [
                    BoxShadow(
                      color: (isCompleted ? AppColors.glowGreen : _setTypeColor)
                          .withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildPreviousSection(bool isDark) {
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () {
        setState(() => _showPreviousDetails = !_showPreviousDetails);
        HapticFeedback.selectionClick();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showPreviousDetails
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: mutedColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _showPreviousDetails
                      ? 'Hide previous'
                      : 'Previous: ${widget.previousWeight?.toStringAsFixed(1) ?? '-'} ${widget.useKg ? 'kg' : 'lbs'} × ${widget.previousReps ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            if (_showPreviousDetails) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPrevDetail(
                      'Weight',
                      '${widget.previousWeight?.toStringAsFixed(1) ?? '-'} ${widget.useKg ? 'kg' : 'lbs'}',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _buildPrevDetail(
                      'Reps',
                      '${widget.previousReps ?? '-'}',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrevDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestedBadge(bool isDark) {
    final suggestion = widget.smartWeightSuggestion!;
    final badgeColor = AppColors.glowPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Main badge row
          GestureDetector(
            onTap: () {
              setState(() => _showAiTooltip = !_showAiTooltip);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    badgeColor.withOpacity(0.2),
                    badgeColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: badgeColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Suggested',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Confidence indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion.confidenceLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAiTooltip
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 14,
                    color: badgeColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),

          // Expandable tooltip with reasoning
          if (_showAiTooltip)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reasoning text
                    Text(
                      suggestion.reasoning,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    // Additional info row
                    if (suggestion.oneRmKg != null ||
                        suggestion.lastSessionData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            // 1RM info
                            if (suggestion.oneRmKg != null)
                              _buildAiInfoChip(
                                icon: Icons.fitness_center,
                                label:
                                    '1RM: ${suggestion.oneRmKg!.toStringAsFixed(1)}kg',
                                color: badgeColor,
                                isDark: isDark,
                              ),

                            // Target intensity
                            _buildAiInfoChip(
                              icon: Icons.speed,
                              label:
                                  '${(suggestion.targetIntensity * 100).toStringAsFixed(0)}% intensity',
                              color: badgeColor,
                              isDark: isDark,
                            ),

                            // Last session
                            if (suggestion.lastSessionData != null)
                              _buildAiInfoChip(
                                icon: Icons.history,
                                label: suggestion
                                    .lastSessionData!.formattedDate,
                                color: badgeColor,
                                isDark: isDark,
                              ),

                            // Performance modifier
                            if (suggestion.modifierDescription != null)
                              _buildAiInfoChip(
                                icon: suggestion.isIncrease
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                label: suggestion.modifierDescription!,
                                color: suggestion.isIncrease
                                    ? AppColors.glowGreen
                                    : AppColors.glowOrange,
                                isDark: isDark,
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
    );
  }

  Widget _buildAiInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onSkip?.call();
        },
        child: Text(
          'Skip to next exercise',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

/// Mini completed set indicator row
class CompletedSetsRow extends StatelessWidget {
  final List<Map<String, dynamic>> sets;
  final bool useKg;

  const CompletedSetsRow({
    super.key,
    required this.sets,
    this.useKg = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glowGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.glowGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final weight = set['weight'] as double? ?? 0;
                final reps = set['reps'] as int? ?? 0;

                return Text(
                  'S${index + 1}: ${weight.toStringAsFixed(0)}${useKg ? 'kg' : 'lbs'}×$reps',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.glowGreen,
                    fontWeight: FontWeight.w500,
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
