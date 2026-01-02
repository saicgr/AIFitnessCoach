import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/skill_progression.dart';

/// Card displaying a progression chain with optional progress
class ProgressionChainCard extends StatelessWidget {
  final ProgressionChain chain;
  final UserSkillProgress? progress;
  final VoidCallback? onTap;
  final bool isCompact;

  const ProgressionChainCard({
    super.key,
    required this.chain,
    this.progress,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isStarted = progress != null;
    final progressPercent = isStarted
        ? progress!.getProgressPercentage(chain.steps?.length ?? 1)
        : 0.0;

    if (isCompact) {
      return _buildCompactCard(
        context,
        isDark,
        elevated,
        cardBorder,
        cyan,
        textSecondary,
        isStarted,
        progressPercent,
      );
    }

    return _buildFullCard(
      context,
      isDark,
      elevated,
      cardBorder,
      cyan,
      textSecondary,
      isStarted,
      progressPercent,
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color cyan,
    Color textSecondary,
    bool isStarted,
    double progressPercent,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStarted ? cyan.withOpacity(0.3) : cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and category
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(chain.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(chain.category),
                      color: _getCategoryColor(chain.category),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (isStarted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                chain.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Category
              Text(
                chain.category,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // Progress bar or step count
              if (isStarted) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: cardBorder,
                    color: cyan,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${progress!.currentStepOrder} of ${chain.steps?.length ?? "?"}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.stairs_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${chain.steps?.length ?? "?"} steps',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color cyan,
    Color textSecondary,
    bool isStarted,
    double progressPercent,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStarted ? cyan.withOpacity(0.3) : cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getCategoryColor(chain.category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(chain.category),
                  color: _getCategoryColor(chain.category),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chain.name,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                        if (isStarted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(progressPercent * 100).toInt()}%',
                              style: TextStyle(
                                color: cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      chain.description,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Progress bar or metadata
                    if (isStarted) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: cardBorder,
                          color: cyan,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Step ${progress!.currentStepOrder} of ${chain.steps?.length ?? "?"}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (progress!.daysSinceLastPractice != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getLastPracticeText(progress!.daysSinceLastPractice!),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          _buildMetaBadge(
                            Icons.stairs_rounded,
                            '${chain.steps?.length ?? "?"} steps',
                            textSecondary,
                          ),
                          const SizedBox(width: 12),
                          _buildMetaBadge(
                            Icons.category_rounded,
                            chain.category,
                            textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getLastPracticeText(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 14) return '1 week ago';
    return '${days ~/ 7} weeks ago';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'push':
      case 'pushing':
        return Icons.fitness_center_rounded;
      case 'pull':
      case 'pulling':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'legs':
      case 'squat':
        return Icons.directions_walk_rounded;
      case 'core':
      case 'abs':
        return Icons.accessibility_new_rounded;
      case 'balance':
      case 'handstand':
        return Icons.pan_tool_rounded;
      case 'flexibility':
      case 'mobility':
        return Icons.self_improvement_rounded;
      case 'planche':
        return Icons.airline_seat_flat_rounded;
      case 'muscle_up':
        return Icons.swap_vert_rounded;
      default:
        return Icons.trending_up_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'push':
      case 'pushing':
        return AppColors.purple;
      case 'pull':
      case 'pulling':
        return AppColors.cyan;
      case 'legs':
      case 'squat':
        return AppColors.orange;
      case 'core':
      case 'abs':
        return AppColors.coral;
      case 'balance':
      case 'handstand':
        return AppColors.teal;
      case 'flexibility':
      case 'mobility':
        return AppColors.green;
      case 'planche':
        return AppColors.magenta;
      case 'muscle_up':
        return AppColors.electricBlue;
      default:
        return AppColors.cyan;
    }
  }
}
