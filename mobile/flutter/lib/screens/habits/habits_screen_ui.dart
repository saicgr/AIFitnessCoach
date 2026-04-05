part of 'habits_screen.dart';

/// Methods extracted from HabitsScreen
extension _HabitsScreenExt on HabitsScreen {

  void _showCreateCustomHabitSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final nameController = TextEditingController();
    String selectedIcon = 'check_circle';
    String selectedColor = '#06B6D4'; // Default cyan

    // Color palette for habits
    const colorOptions = [
      '#06B6D4', // Cyan
      '#8B5CF6', // Purple
      '#F97316', // Orange
      '#10B981', // Emerald
      '#EF4444', // Red
      '#3B82F6', // Blue
      '#EC4899', // Pink
      '#F59E0B', // Amber
      '#14B8A6', // Teal
      '#6366F1', // Indigo
      '#84CC16', // Lime
      '#A855F7', // Violet
    ];

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return GlassSheet(
          child: StatefulBuilder(
          builder: (context, setSheetState) {
            final currentColor = _parseColor(selectedColor, accentColor);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  children: [
                      // Header with back button
                      Row(
                        children: [
                          GlassBackButton(
                            onTap: () {
                              HapticService.light();
                              Navigator.pop(context);
                              _showAddHabitSheet(context, ref, ref.read(habitsScreenProvider).templates);
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Create Custom Habit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name input
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: textPrimary),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Habit Name',
                          labelStyle: TextStyle(color: textSecondary),
                          hintText: 'e.g., Morning Meditation',
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: currentColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color selection
                      Text(
                        'Choose Color',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: colorOptions.map((hex) {
                          final color = _parseColor(hex, accentColor);
                          final isSelected = selectedColor == hex;
                          return GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setSheetState(() => selectedColor = hex);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : null,
                                boxShadow: isSelected
                                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Icon selection
                      Text(
                        'Choose Icon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          'check_circle', 'star', 'favorite', 'fitness_center',
                          'self_improvement', 'menu_book', 'water_drop', 'bedtime',
                          'directions_run', 'eco', 'wb_sunny', 'restaurant_menu',
                        ].map((iconName) {
                          final isSelected = selectedIcon == iconName;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedIcon = iconName);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? currentColor : cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? null : Border.all(
                                  color: textSecondary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                _getIconFromName(iconName),
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary,
                                size: 22,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: currentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getIconFromName(selectedIcon),
                                color: currentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nameController.text.isEmpty ? 'Preview' : nameController.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: nameController.text.isEmpty
                                      ? textSecondary.withValues(alpha: 0.5)
                                      : textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: currentColor),
                              ),
                              child: Icon(Icons.check, color: currentColor, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Create button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a habit name'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            HapticService.medium();
                            final messenger = ScaffoldMessenger.of(context);
                            final habitName = nameController.text.trim();
                            Navigator.pop(context);

                            try {
                              // Create the habit via API
                              final habit = HabitCreate(
                                name: habitName,
                                icon: selectedIcon,
                                color: selectedColor,
                              );
                              await ref.read(habitRepositoryProvider).createHabit(
                                ref.read(authStateProvider).user?.id ?? '',
                                habit,
                              );

                              // Reload habits list
                              await ref.read(habitsScreenProvider.notifier).loadHabits(force: true);

                              // Check for first habit XP bonus
                              final xpAwarded = await ref.read(xpProvider.notifier).checkFirstHabitBonus();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    xpAwarded > 0
                                      ? 'Created "$habitName" +$xpAwarded XP bonus!'
                                      : 'Created "$habitName"',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create habit: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Habit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
            );
          },
        ),
        );
      },
    );
  }

}
