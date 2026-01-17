import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/home_layout.dart';
import '../../../data/providers/home_layout_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for picking layout templates
class TemplatePickerSheet extends ConsumerWidget {
  final Function(HomeLayoutTemplate template) onTemplateSelected;

  const TemplatePickerSheet({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final templatesState = ref.watch(layoutTemplatesProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
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
          child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Templates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start with a pre-designed layout',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Templates list
              Expanded(
                child: templatesState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load templates',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                  data: (templates) {
                    // Create built-in default template
                    final defaultTemplate = HomeLayoutTemplate(
                      id: 'default',
                      name: 'Default Layout',
                      description: 'The original FitWiz home screen experience',
                      tiles: createDefaultTiles(),
                      icon: 'dashboard',
                      category: 'default',
                    );

                    // Add default template to the beginning
                    final allTemplates = [defaultTemplate, ...templates];

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allTemplates.length,
                      itemBuilder: (context, index) {
                        final template = allTemplates[index];
                        final isDefault = template.id == 'default';
                        return _buildTemplateCard(
                          context,
                          template,
                          elevatedColor,
                          textColor,
                          textMuted,
                          isDefault: isDefault,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    HomeLayoutTemplate template,
    Color elevatedColor,
    Color textColor,
    Color textMuted, {
    bool isDefault = false,
  }) {
    final iconData = _getIconForTemplate(template.icon);
    final iconColor = _getColorForCategory(template.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (template.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Preview tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTilePreview(template.tiles, textMuted),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    onTemplateSelected(template);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Use This Template',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilePreview(List<HomeTile> tiles, Color textMuted) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles.take(6).map((tile) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: textMuted.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tile.type.displayName,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForTemplate(String? icon) {
    switch (icon) {
      case 'spa':
        return Icons.spa;
      case 'analytics':
        return Icons.analytics;
      case 'favorite':
        return Icons.favorite;
      case 'people':
        return Icons.people;
      case 'dashboard':
        return Icons.dashboard;
      default:
        return Icons.style;
    }
  }

  Color _getColorForCategory(String? category) {
    switch (category) {
      case 'default':
        return AppColors.cyan;
      case 'minimalist':
        return AppColors.green;
      case 'performance':
        return AppColors.cyan;
      case 'wellness':
        return AppColors.orange;
      case 'social':
        return AppColors.purple;
      case 'complete':
        return AppColors.yellow;
      default:
        return AppColors.cyan;
    }
  }
}
