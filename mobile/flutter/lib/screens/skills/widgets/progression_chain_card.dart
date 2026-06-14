import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/skill_progression.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final tc = ThemeColors.of(context);

    final isStarted = progress != null;
    final progressPercent = isStarted
        ? progress!.getProgressPercentage(chain.steps?.length ?? 1)
        : 0.0;

    if (isCompact) {
      return _buildCompactCard(context, tc, isStarted, progressPercent);
    }

    return _buildFullCard(context, tc, isStarted, progressPercent);
  }

  /// Framed hairline category glyph (surface fill + cardBorder, radius 9).
  Widget _categoryGlyph(ThemeColors tc, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        _getCategoryIcon(chain.category),
        color: tc.textSecondary,
        size: size * 0.5,
      ),
    );
  }

  Widget _percentChip(ThemeColors tc, double progressPercent) {
    return Text(
      '${(progressPercent * 100).toInt()}%',
      style: ZType.data(13, color: tc.accent),
    );
  }

  Widget _progressBar(ThemeColors tc, double progressPercent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progressPercent,
        backgroundColor: AppColors.hairlineStrong,
        color: tc.accent,
        minHeight: 4,
      ),
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    ThemeColors tc,
    bool isStarted,
    double progressPercent,
  ) {
    return ZealovaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and category
          Row(
            children: [
              _categoryGlyph(tc, 40),
              const Spacer(),
              if (isStarted) _percentChip(tc, progressPercent),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            chain.name,
            style: ZType.disp(16, color: tc.textPrimary, letterSpacing: 0.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Category
          Text(
            chain.category.toUpperCase(),
            style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.2),
          ),

          const Spacer(),

          // Progress bar or step count
          if (isStarted) ...[
            _progressBar(tc, progressPercent),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.progressionChainCardStepOf(progress!.currentStepOrder, chain.steps?.length ?? "?"),
              style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.stairs_rounded,
                  size: 13,
                  color: tc.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  AppLocalizations.of(context)!.progressionChainCardSteps(chain.steps?.length ?? "?"),
                  style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullCard(
    BuildContext context,
    ThemeColors tc,
    bool isStarted,
    double progressPercent,
  ) {
    return ZealovaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          _categoryGlyph(tc, 48),
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
                        style: ZType.disp(18, color: tc.textPrimary, letterSpacing: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isStarted) _percentChip(tc, progressPercent),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  chain.description,
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Progress bar or metadata
                if (isStarted) ...[
                  _progressBar(tc, progressPercent),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.progressionChainCardStepOf2(progress!.currentStepOrder, chain.steps?.length ?? "?"),
                        style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
                      ),
                      if (progress!.daysSinceLastPractice != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: tc.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLastPracticeText(progress!.daysSinceLastPractice!).toUpperCase(),
                          style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
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
                        tc.textMuted,
                      ),
                      const SizedBox(width: 12),
                      _buildMetaBadge(
                        Icons.category_rounded,
                        chain.category,
                        tc.textMuted,
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
            color: tc.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text.toUpperCase(),
          style: ZType.lbl(10, color: color, letterSpacing: 0.8),
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
}
