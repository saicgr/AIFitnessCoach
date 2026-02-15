import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

/// A styled section header for the settings screen.
///
/// Displays a muted, uppercase label to group related settings.
/// Optionally includes a "What's this?" help icon that shows an explanatory
/// bottom sheet when tapped.
class SectionHeader extends StatelessWidget {
  /// The title text to display (will be shown in uppercase).
  final String title;

  /// Optional subtitle/description that appears below the title.
  final String? subtitle;

  /// Optional help title for the bottom sheet.
  final String? helpTitle;

  /// Optional list of help items to show in the bottom sheet.
  /// Each item should have 'icon' (IconData), 'title' (String),
  /// 'description' (String), and optional 'color' (Color).
  final List<Map<String, dynamic>>? helpItems;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.helpTitle,
    this.helpItems,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (helpItems != null && helpItems!.isNotEmpty)
              GestureDetector(
                onTap: () => _showHelpSheet(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "What's this?",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  void _showHelpSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      helpTitle ?? title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            // Help items
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: helpItems!.length,
                itemBuilder: (context, index) {
                  final item = helpItems![index];
                  final icon = item['icon'] as IconData? ?? Icons.info_outline;
                  final itemTitle = item['title'] as String? ?? '';
                  final description = item['description'] as String? ?? '';
                  final color = item['color'] as Color? ?? AppColors.cyan;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      )),
    );
  }
}
