part of 'exercise_add_sheet.dart';


class _ExerciseOptionCard extends ConsumerWidget {
  final String name;
  final String? imageUrl;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool isRecommended;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final Color textPrimary;
  final Color textMuted;
  final IconData actionIcon;
  final Color actionColor;

  const _ExerciseOptionCard({
    required this.name,
    this.imageUrl,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    this.isRecommended = false,
    required this.onTap,
    this.onAdd,
    required this.textPrimary,
    required this.textMuted,
    this.actionIcon = Icons.add_circle,
    this.actionColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isRecommended
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(
                  color: Color(0xFFD4A017),
                  width: 2.5,
                ),
              ),
            )
          : null,
      child: Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Exercise image
                ExerciseImage(
                  exerciseName: name,
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  borderRadius: 8,
                  backgroundColor: glassSurface,
                  iconColor: textMuted,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add button
                GestureDetector(
                  onTap: onAdd ?? onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      actionIcon,
                      color: actionColor,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

