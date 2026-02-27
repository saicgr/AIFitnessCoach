import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';
import 'template_editor_sheet.dart';

class TemplateSection extends ConsumerWidget {
  final BeastThemeData theme;

  const TemplateSection({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(beastModeConfigProvider);
    final notifier = ref.read(beastModeConfigProvider.notifier);
    final templates = config.workoutTemplates;

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('My Templates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary))),
              GestureDetector(
                onTap: () => TemplateEditorSheet.show(context, null, notifier),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text('New', style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (templates.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 32, color: theme.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text('No custom templates yet', style: TextStyle(fontSize: 12, color: theme.textMuted)),
                  const SizedBox(height: 4),
                  Text('Add one or use a pre-built template below', style: TextStyle(fontSize: 11, color: theme.textMuted.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...templates.map((t) => _buildTemplateRow(context, t, notifier)),
          ],
          const SizedBox(height: 16),
          Text('Pre-built Templates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkoutTemplate.prebuiltTemplates.map((t) {
              final alreadyAdded = templates.any((existing) => existing.id == t.id);
              return ActionChip(
                avatar: Icon(alreadyAdded ? Icons.check : Icons.add, size: 14,
                    color: alreadyAdded ? AppColors.success : AppColors.orange),
                label: Text(t.name),
                labelStyle: TextStyle(fontSize: 12, color: alreadyAdded ? theme.textMuted : theme.textPrimary),
                side: BorderSide(color: alreadyAdded ? theme.cardBorder : AppColors.orange.withValues(alpha: 0.3)),
                onPressed: alreadyAdded
                    ? null
                    : () {
                        HapticService.light();
                        notifier.addTemplate(t);
                        AppSnackBar.success(context, '${t.name} template added');
                      },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateRow(BuildContext context, WorkoutTemplate template, BeastModeConfigNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(template.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textPrimary))),
              GestureDetector(
                onTap: () => TemplateEditorSheet.show(context, template, notifier),
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 16, color: AppColors.orange)),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  notifier.duplicateTemplate(template.id);
                  AppSnackBar.info(context, 'Template duplicated');
                },
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.copy_outlined, size: 16, color: theme.textMuted)),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.medium();
                  notifier.removeTemplate(template.id);
                  AppSnackBar.info(context, 'Template removed');
                },
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 16, color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${template.exerciseCount} exercises  |  ${template.setScheme}  |  Rest: ${template.restPattern}${template.supersets ? '  |  Supersets' : ''}',
            style: TextStyle(fontSize: 11, color: theme.textMuted),
          ),
          if (template.notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(template.notes, style: TextStyle(fontSize: 10, color: theme.textMuted.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}
