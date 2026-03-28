import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/set_progression.dart';

/// Educational screen showing all set progression patterns with research-backed
/// explanations, usage guidance, and adaptive behavior details.
class TrainingMethodsScreen extends StatefulWidget {
  const TrainingMethodsScreen({super.key});

  @override
  State<TrainingMethodsScreen> createState() => _TrainingMethodsScreenState();
}

class _TrainingMethodsScreenState extends State<TrainingMethodsScreen> {
  SetProgressionPattern? _expandedPattern;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('Training Methods'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set progression patterns control how weight and reps change across sets. '
            'Each method auto-adjusts based on your actual performance.',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...SetProgressionPattern.values.map((pattern) {
            final isExpanded = _expandedPattern == pattern;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isExpanded
                      ? Border.all(
                          color: _goalColor(pattern.goalTags.first, isDark)
                              .withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _expandedPattern = isExpanded ? null : pattern;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: icon + name + goal tags + chevron
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _goalColor(pattern.goalTags.first, isDark)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  pattern.icon,
                                  size: 20,
                                  color: _goalColor(pattern.goalTags.first, isDark),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pattern.displayName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pattern.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Goal tags
                              ...pattern.goalTags.map((tag) => Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _goalColor(tag, isDark).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _goalColor(tag, isDark),
                                  ),
                                ),
                              )),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: textMuted,
                                size: 20,
                              ),
                            ],
                          ),

                          // Expanded content
                          if (isExpanded) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // How it works
                            _sectionHeader('How it works', Icons.info_outline, textPrimary),
                            const SizedBox(height: 6),
                            Text(
                              pattern.infoExplanation,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // When to use
                            _sectionHeader('When to use', Icons.lightbulb_outline, textPrimary),
                            const SizedBox(height: 6),
                            Text(
                              pattern.whenToUse,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Auto-adjusts
                            _sectionHeader('Auto-adjusts', Icons.auto_fix_high, textPrimary),
                            const SizedBox(height: 6),
                            Text(
                              pattern.adaptiveDescription,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Rest suggestion
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Rest: ${pattern.restDisplayHint}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Research source
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.science_outlined, size: 14, color: textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pattern.researchSource,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: textMuted,
                                        height: 1.4,
                                      ),
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
                ),
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textColor.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Color _goalColor(String tag, bool isDark) {
    switch (tag) {
      case 'Strength':
        return isDark ? AppColors.orange : AppColorsLight.orange;
      case 'Hypertrophy':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      default:
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
    }
  }
}
