import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/habit.dart';
import '../../../data/providers/habits_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'habit_card.dart';

/// Provider to fetch custom habits for home section
final customHabitsHomeProvider = FutureProvider.autoDispose<List<HabitWithStatus>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) return [];

  final repository = ref.watch(habitRepositoryProvider);
  try {
    final response = await repository.getTodayHabits(userId);
    return response.habits;
  } catch (e) {
    debugPrint('❌ [CustomHabitsHome] Error fetching habits: $e');
    return [];
  }
});

/// Habits section with horizontally scrollable square cards
/// Includes auto-tracked habits (Workouts, Food Log, Water) and custom habits from API
class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Auto-tracked habits (Workouts, Food Log, Water)
    final autoTrackedHabits = ref.watch(habitsProvider);

    // Custom habits from API
    final customHabitsAsync = ref.watch(customHabitsHomeProvider);

    // Convert custom habits to HabitData format for display
    final customHabitCards = customHabitsAsync.when(
      data: (habits) => habits.map((h) => _convertToHabitData(h)).toList(),
      loading: () => <HabitData>[],
      error: (_, __) => <HabitData>[],
    );

    // Combine auto-tracked + custom habits
    final allHabits = [...autoTrackedHabits, ...customHabitCards];

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with View All button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/habits'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable square cards
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // +1 for the "Add Habit" card at the end
              itemCount: allHabits.length + 1,
              itemBuilder: (context, index) {
                // Last item is the "Add Habit" card
                if (index == allHabits.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: _AddHabitCard(
                      onTap: () => _showAddHabitSheet(context, ref),
                    ),
                  );
                }

                final habit = allHabits[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HabitCard(
                    habit: habit,
                    size: 140,
                    onTap: () {
                      if (habit.route != null) {
                        context.push(habit.route!);
                      } else {
                        // Custom habit - navigate to habits screen
                        context.push('/habits');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Convert HabitWithStatus from API to HabitData for HabitCard
  HabitData _convertToHabitData(HabitWithStatus habit) {
    // Generate last 30 days data based on completion rate
    // For now, we mark today as completed if todayCompleted is true
    final last30Days = List<bool>.filled(30, false);

    // Mark today based on completion status
    if (habit.todayCompleted) {
      last30Days[29] = true;
    }

    // Estimate some completion based on 7-day rate
    // This is a rough approximation - ideally we'd fetch actual history
    final completedDays = (habit.completionRate7d * 7).round();
    for (int i = 0; i < completedDays && i < 7; i++) {
      last30Days[28 - i] = true;
    }

    return HabitData(
      name: habit.name,
      icon: _getIconData(habit.icon),
      last30Days: last30Days,
      currentStreak: habit.currentStreak,
      route: null, // Custom habits don't have a specific route
    );
  }

  /// Parse icon string to IconData
  IconData _getIconData(String iconName) {
    final iconMap = {
      'check_circle': Icons.check_circle,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'do_not_disturb': Icons.do_not_disturb,
      'medication': Icons.medication,
      'directions_walk': Icons.directions_walk,
      'self_improvement': Icons.self_improvement,
      'directions_run': Icons.directions_run,
      'fitness_center': Icons.fitness_center,
      'bedtime': Icons.bedtime,
      'spa': Icons.spa,
      'no_drinks': Icons.no_drinks,
      'wb_sunny': Icons.wb_sunny,
      'menu_book': Icons.menu_book,
      'edit_note': Icons.edit_note,
      'phone_disabled': Icons.phone_disabled,
      'favorite': Icons.favorite,
      'restaurant_menu': Icons.restaurant_menu,
      'local_fire_department': Icons.local_fire_department,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddHabitBottomSheet(ref: ref),
    );
  }
}

/// "Add Habit" card widget
class _AddHabitCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _AddHabitCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Habit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for adding a new habit
class _AddHabitBottomSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AddHabitBottomSheet({required this.ref});

  @override
  ConsumerState<_AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();
}

class _AddHabitBottomSheetState extends ConsumerState<_AddHabitBottomSheet> {
  List<HabitTemplate> _templates = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final repository = ref.read(habitRepositoryProvider);
      final templates = await repository.getHabitTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      if (mounted) {
        setState(() {
          _templates = HabitTemplate.defaults;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createHabitFromTemplate(HabitTemplate template) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final repository = ref.read(habitRepositoryProvider);
      await repository.createHabitFromTemplate(userId, template.id);

      // Refresh the custom habits provider
      ref.invalidate(customHabitsHomeProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} habit added!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add habit: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Group templates by category
    final categories = ['nutrition', 'activity', 'health', 'lifestyle'];
    final filteredTemplates = _selectedCategory == null
        ? _templates
        : _templates.where((t) => t.category.value == _selectedCategory).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add a Habit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: textSecondary),
                ),
              ],
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                  accentColor: accentColor,
                ),
                ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _CategoryChip(
                    label: cat[0].toUpperCase() + cat.substring(1),
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                    accentColor: accentColor,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Templates list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return _HabitTemplateCard(
                        template: template,
                        onTap: () => _createHabitFromTemplate(template),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Category filter chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Habit template card for the bottom sheet
class _HabitTemplateCard extends StatelessWidget {
  final HabitTemplate template;
  final VoidCallback onTap;

  const _HabitTemplateCard({
    required this.template,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    final iconMap = {
      'check_circle': Icons.check_circle,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'do_not_disturb': Icons.do_not_disturb,
      'medication': Icons.medication,
      'directions_walk': Icons.directions_walk,
      'self_improvement': Icons.self_improvement,
      'directions_run': Icons.directions_run,
      'fitness_center': Icons.fitness_center,
      'bedtime': Icons.bedtime,
      'spa': Icons.spa,
      'no_drinks': Icons.no_drinks,
      'wb_sunny': Icons.wb_sunny,
      'menu_book': Icons.menu_book,
      'edit_note': Icons.edit_note,
      'phone_disabled': Icons.phone_disabled,
      'favorite': Icons.favorite,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final iconColor = _parseColor(template.color);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(template.icon),
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: iconColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
