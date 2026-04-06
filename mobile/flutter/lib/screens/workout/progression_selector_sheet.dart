part of 'active_workout_screen_refactored.dart';

/// Bottom sheet for selecting a set progression pattern.
class _ProgressionSelectorSheet extends StatefulWidget {
  final SetProgressionPattern currentPattern;
  final double workingWeight;
  final int totalSets;
  final int baseReps;
  final double increment;
  final String unit;
  final bool isDark;
  final ScrollController scrollController;
  final ValueChanged<SetProgressionPattern> onSelect;
  final String? trainingGoal;
  final String exerciseType; // 'compound', 'isolation', or 'bodyweight'

  const _ProgressionSelectorSheet({
    required this.currentPattern,
    required this.workingWeight,
    required this.totalSets,
    required this.baseReps,
    required this.increment,
    required this.unit,
    required this.isDark,
    required this.scrollController,
    required this.onSelect,
    this.trainingGoal,
    this.exerciseType = 'isolation',
  });

  @override
  State<_ProgressionSelectorSheet> createState() => _ProgressionSelectorSheetState();
}

class _ProgressionSelectorSheetState extends State<_ProgressionSelectorSheet> {
  /// Tracks which patterns have their info expanded.
  final Set<SetProgressionPattern> _expandedInfo = {};

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? Colors.white : Colors.grey.shade900;
    final textSecondary = widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final selectedBorder = widget.isDark ? Colors.white : Colors.black;
    final dividerColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    // Standard patterns (non-advanced)
    final standardPatterns = SetProgressionPattern.values
        .where((p) => !p.isAdvanced)
        .toList();
    final advancedPatterns = SetProgressionPattern.values
        .where((p) => p.isAdvanced)
        .toList();

    return SafeArea(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          // Handle
          GlassSheetHandle(isDark: widget.isDark),
          const SizedBox(height: 8),
          // Title
          Text(
            'Set Progression',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how weight changes across sets',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 20),

          // Standard patterns
          ...standardPatterns.map((p) => _buildPatternTile(
                p, textPrimary, textSecondary, cardBg, selectedBorder, dividerColor)),

          // Advanced section
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ADVANCED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...advancedPatterns.map((p) => _buildPatternTile(
                p, textPrimary, textSecondary, cardBg, selectedBorder, dividerColor)),
        ],
      ),
    );
  }

  Widget _buildPatternTile(
    SetProgressionPattern pattern,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color selectedBorder,
    Color dividerColor,
  ) {
    final isSelected = pattern == widget.currentPattern;
    final isExpanded = _expandedInfo.contains(pattern);
    // Compute pattern-aware maxReps (endurance allows higher)
    final int patternMaxReps;
    if (pattern == SetProgressionPattern.endurance) {
      patternMaxReps = widget.exerciseType == 'compound' ? 15 : widget.exerciseType == 'bodyweight' ? 30 : 25;
    } else {
      patternMaxReps = widget.exerciseType == 'compound' ? 12 : widget.exerciseType == 'bodyweight' ? 20 : 15;
    }
    final preview = pattern.previewString(
      workingWeight: widget.workingWeight,
      totalSets: widget.totalSets,
      baseReps: widget.baseReps,
      increment: widget.increment,
      unit: widget.unit,
      trainingGoal: widget.trainingGoal,
      maxReps: patternMaxReps,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => widget.onSelect(pattern),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? selectedBorder : dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? selectedBorder : textSecondary,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedBorder,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Icon
                  Icon(pattern.icon, size: 20, color: textPrimary),
                  const SizedBox(width: 8),
                  // Name
                  Expanded(
                    child: Text(
                      pattern.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  // Goal tags
                  ...pattern.goalTags.map((tag) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tag == 'Strength'
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tag == 'Strength'
                                ? Colors.orange.shade400
                                : Colors.blue.shade400,
                          ),
                        ),
                      )),
                  const SizedBox(width: 4),
                  // Info button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedInfo.remove(pattern);
                        } else {
                          _expandedInfo.add(pattern);
                        }
                      });
                    },
                    child: Icon(
                      isExpanded ? Icons.info : Icons.info_outline,
                      size: 20,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Description
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  pattern.description,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
              // Preview string
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(
                  preview,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Rest hint
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      pattern.restDisplayHint,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              // Expandable info panel
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(left: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.infoExplanation,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // When to use
                      Text(
                        'When to use',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pattern.whenToUse,
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Auto-adjust behavior
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 14,
                            color: textPrimary.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-adjusts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pattern.adaptiveDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Research source
                      Text(
                        pattern.researchSource,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: textPrimary.withValues(alpha: 0.45),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
