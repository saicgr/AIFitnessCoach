import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/environment_equipment_provider.dart';
import 'environment_detail_screen.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/glass_sheet.dart';

/// Screen showing list of workout environments with their equipment.
class EnvironmentListScreen extends ConsumerStatefulWidget {
  const EnvironmentListScreen({super.key});

  @override
  ConsumerState<EnvironmentListScreen> createState() => _EnvironmentListScreenState();
}

class _EnvironmentListScreenState extends ConsumerState<EnvironmentListScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final envEquipState = ref.watch(environmentEquipmentProvider);
    final currentEnv = envEquipState.environment;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Workout Environment',
          style: TextStyle(
            color: isDark ? Colors.white : AppColorsLight.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppColors.cyan,
            ),
            onPressed: () => _showAddEnvironmentSheet(context),
            tooltip: 'Add Custom Environment',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cyan.withValues(alpha: 0.1)
                  : AppColorsLight.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.cyan.withValues(alpha: 0.3)
                    : AppColorsLight.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select your workout environment to customize the equipment available to you.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Environment cards
          ...WorkoutEnvironment.values.map((env) {
            final isSelected = env == currentEnv;
            return _EnvironmentCard(
              environment: env,
              isSelected: isSelected,
              currentEquipment: isSelected ? envEquipState.equipment : env.defaultEquipment,
              onTap: () => _navigateToDetail(env),
              onSelect: () => _selectEnvironment(env),
            );
          }),
        ],
      ),
    );
  }

  void _navigateToDetail(WorkoutEnvironment env) {
    final envEquipState = ref.read(environmentEquipmentProvider);
    final isCurrentEnv = env == envEquipState.environment;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => EnvironmentDetailScreen(
          environment: env,
          equipment: isCurrentEnv ? envEquipState.equipment : env.defaultEquipment,
          isCurrentEnvironment: isCurrentEnv,
        ),
      ),
    );
  }

  void _selectEnvironment(WorkoutEnvironment env) {
    HapticFeedback.selectionClick();
    ref.read(environmentEquipmentProvider.notifier).setEnvironmentWithDefaultEquipment(env);
  }

  void _showAddEnvironmentSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddEnvironmentSheet(
          onSave: (name, icon) {
            // TODO: Save custom environment
            Navigator.pop(context);
          },
        ),
      )),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  final WorkoutEnvironment environment;
  final bool isSelected;
  final List<String> currentEquipment;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _EnvironmentCard({
    required this.environment,
    required this.isSelected,
    required this.currentEquipment,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.cyan : cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cyan.withValues(alpha: 0.15)
                            : (isDark ? AppColors.pureBlack : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        environment.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                environment.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            environment.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    Icon(
                      Icons.chevron_right,
                      color: textMuted,
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Equipment preview
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${currentEquipment.length} equipment items',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (!isSelected)
                      TextButton(
                        onPressed: onSelect,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Use This',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                  ],
                ),

                // Equipment chips preview
                if (currentEquipment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentEquipment.take(5).map((equip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.pureBlack.withValues(alpha: 0.5)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          getEquipmentDisplayName(equip),
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (currentEquipment.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${currentEquipment.length - 5} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEnvironmentSheet extends StatefulWidget {
  final void Function(String name, String icon) onSave;

  const _AddEnvironmentSheet({required this.onSave});

  @override
  State<_AddEnvironmentSheet> createState() => _AddEnvironmentSheetState();
}

class _AddEnvironmentSheetState extends State<_AddEnvironmentSheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = '🏋️';

  final _icons = ['🏋️', '🏠', '🏢', '🌳', '🧳', '🏬', '💼', '🎯', '⭐', '🔥'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Custom Environment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Environment Name',
                hintText: 'e.g., Beach Workout',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon selector
            Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan.withValues(alpha: 0.15)
                          : (isDark ? AppColors.pureBlack : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    widget.onSave(_nameController.text.trim(), _selectedIcon);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Environment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
