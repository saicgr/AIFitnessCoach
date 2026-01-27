import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/habit_card.dart';

/// Unified habit item for display (combines auto-tracked and custom)
class UnifiedHabitItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isAutoTracked;
  final bool todayCompleted;
  final int currentStreak;
  final List<bool> last30Days;
  final String? description;
  final String? route;
  final int sortOrder;

  const UnifiedHabitItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isAutoTracked,
    required this.todayCompleted,
    required this.currentStreak,
    required this.last30Days,
    this.description,
    this.route,
    this.sortOrder = 0,
  });

  UnifiedHabitItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isAutoTracked,
    bool? todayCompleted,
    int? currentStreak,
    List<bool>? last30Days,
    String? description,
    String? route,
    int? sortOrder,
  }) {
    return UnifiedHabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAutoTracked: isAutoTracked ?? this.isAutoTracked,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      last30Days: last30Days ?? this.last30Days,
      description: description ?? this.description,
      route: route ?? this.route,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// State notifier for managing habits from API
class HabitsScreenNotifier extends StateNotifier<HabitsScreenState> {
  final HabitRepository _repository;
  final String _userId;
  final List<HabitData> Function() _getAutoHabits;
  final Color _accentColor;

  // Local storage key for habit order
  static const String _orderKey = 'habit_order';

  HabitsScreenNotifier(
    this._repository,
    this._userId,
    this._getAutoHabits,
    this._accentColor,
  ) : super(const HabitsScreenState()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final todayResponse = await _repository.getTodayHabits(_userId);
      final templates = await _repository.getHabitTemplates();

      // Load saved order from local storage
      final savedOrder = await _loadSavedOrder();

      // Build unified habit list with saved order
      final unified = await _buildUnifiedList(
        _getAutoHabits(),
        todayResponse.habits,
        savedOrder,
      );

      state = state.copyWith(
        isLoading: false,
        customHabits: todayResponse.habits,
        unifiedHabits: unified,
        totalHabits: todayResponse.totalHabits,
        completedToday: todayResponse.completedToday,
        completionPercentage: todayResponse.completionPercentage,
        templates: templates,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load saved habit order from SharedPreferences
  Future<List<String>> _loadSavedOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_orderKey}_$_userId';
      return prefs.getStringList(key) ?? [];
    } catch (e) {
      debugPrint('❌ Error loading habit order: $e');
      return [];
    }
  }

  /// Save habit order to SharedPreferences
  Future<void> _saveOrder(List<String> habitIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_orderKey}_$_userId';
      await prefs.setStringList(key, habitIds);
      debugPrint('✅ Saved habit order: ${habitIds.length} habits');
    } catch (e) {
      debugPrint('❌ Error saving habit order: $e');
    }
  }

  /// Refresh unified list with latest auto-tracked data
  Future<void> refreshUnifiedList(List<HabitData> autoHabits) async {
    final savedOrder = await _loadSavedOrder();
    final unified = await _buildUnifiedList(autoHabits, state.customHabits, savedOrder);
    state = state.copyWith(unifiedHabits: unified);
  }

  Future<List<UnifiedHabitItem>> _buildUnifiedList(
    List<HabitData> autoHabits,
    List<HabitWithStatus> customHabits,
    List<String> savedOrder,
  ) async {
    final Map<String, UnifiedHabitItem> habitsById = {};

    // Add auto-tracked habits
    for (int i = 0; i < autoHabits.length; i++) {
      final auto_ = autoHabits[i];
      final id = 'auto_${auto_.name.toLowerCase().replaceAll(' ', '_')}';
      habitsById[id] = UnifiedHabitItem(
        id: id,
        name: auto_.name,
        icon: auto_.icon,
        color: _accentColor,
        isAutoTracked: true,
        todayCompleted: auto_.last30Days.isNotEmpty && auto_.last30Days.last,
        currentStreak: auto_.currentStreak,
        last30Days: auto_.last30Days,
        route: auto_.route,
        sortOrder: i,
      );
    }

    // Add custom habits
    for (int i = 0; i < customHabits.length; i++) {
      final custom = customHabits[i];
      habitsById[custom.id] = UnifiedHabitItem(
        id: custom.id,
        name: custom.name,
        icon: _getIconFromName(custom.icon),
        color: _parseColor(custom.color, _accentColor),
        isAutoTracked: false,
        todayCompleted: custom.todayCompleted,
        currentStreak: custom.currentStreak,
        last30Days: [], // Custom habits don't have 30-day history
        description: custom.description,
        sortOrder: autoHabits.length + i,
      );
    }

    // If we have a saved order, use it
    if (savedOrder.isNotEmpty) {
      final List<UnifiedHabitItem> ordered = [];

      // First, add habits in saved order
      for (final id in savedOrder) {
        if (habitsById.containsKey(id)) {
          ordered.add(habitsById[id]!);
          habitsById.remove(id);
        }
      }

      // Then add any new habits that weren't in the saved order
      ordered.addAll(habitsById.values);

      return ordered;
    }

    // No saved order - return in default order (auto first, then custom)
    return habitsById.values.toList();
  }

  Future<void> toggleHabit(String habitId, bool completed) async {
    // Only custom habits can be toggled
    if (habitId.startsWith('auto_')) return;

    try {
      await _repository.toggleTodayHabit(_userId, habitId, completed);
      // Optimistic update
      final updatedHabits = state.customHabits.map((h) {
        if (h.id == habitId) {
          return h.copyWith(todayCompleted: completed);
        }
        return h;
      }).toList();

      final newCompletedCount = updatedHabits.where((h) => h.todayCompleted).length;

      // Update unified list
      final updatedUnified = state.unifiedHabits.map((h) {
        if (h.id == habitId) {
          return h.copyWith(todayCompleted: completed);
        }
        return h;
      }).toList();

      state = state.copyWith(
        customHabits: updatedHabits,
        unifiedHabits: updatedUnified,
        completedToday: newCompletedCount,
        completionPercentage: updatedHabits.isEmpty
            ? 0.0
            : (newCompletedCount / updatedHabits.length * 100),
      );
    } catch (e) {
      // Reload on error
      await loadHabits();
    }
  }

  Future<void> createHabitFromTemplate(String templateId) async {
    try {
      await _repository.createHabitFromTemplate(_userId, templateId);
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteHabit(String habitId) async {
    // Auto-tracked habits cannot be deleted
    if (habitId.startsWith('auto_')) return;

    try {
      await _repository.deleteHabit(_userId, habitId);
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    // Adjust newIndex for removal
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final unified = List<UnifiedHabitItem>.from(state.unifiedHabits);
    final item = unified.removeAt(oldIndex);
    unified.insert(newIndex, item);

    // Optimistic update
    state = state.copyWith(unifiedHabits: unified);

    // Save order locally (for all habits including auto-tracked)
    final orderedIds = unified.map((h) => h.id).toList();
    await _saveOrder(orderedIds);

    // Only send custom habit order to backend (skip auto-tracked)
    try {
      final customOrderMap = <String, int>{};
      int customIndex = 0;
      for (final habit in unified) {
        if (!habit.isAutoTracked) {
          customOrderMap[habit.id] = customIndex;
          customIndex++;
        }
      }
      if (customOrderMap.isNotEmpty) {
        await _repository.reorderHabits(_userId, customOrderMap);
      }
    } catch (e) {
      // Backend error is non-fatal since we saved locally
      debugPrint('⚠️ Backend reorder failed (local saved): $e');
    }
  }

  Color _parseColor(String colorHex, Color fallback) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _getIconFromName(String iconName) {
    const iconMap = {
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
      'delivery_dining': Icons.delivery_dining,
      'nightlight': Icons.nightlight,
      'restaurant': Icons.restaurant,
      'soup_kitchen': Icons.soup_kitchen,
      'heart': Icons.favorite,
      'running': Icons.directions_run,
      'apple': Icons.apple,
      'star': Icons.star,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }
}

class HabitsScreenState {
  final bool isLoading;
  final String? error;
  final List<HabitWithStatus> customHabits;
  final List<UnifiedHabitItem> unifiedHabits;
  final int totalHabits;
  final int completedToday;
  final double completionPercentage;
  final List<HabitTemplate> templates;

  const HabitsScreenState({
    this.isLoading = false,
    this.error,
    this.customHabits = const [],
    this.unifiedHabits = const [],
    this.totalHabits = 0,
    this.completedToday = 0,
    this.completionPercentage = 0.0,
    this.templates = const [],
  });

  HabitsScreenState copyWith({
    bool? isLoading,
    String? error,
    List<HabitWithStatus>? customHabits,
    List<UnifiedHabitItem>? unifiedHabits,
    int? totalHabits,
    int? completedToday,
    double? completionPercentage,
    List<HabitTemplate>? templates,
  }) {
    return HabitsScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customHabits: customHabits ?? this.customHabits,
      unifiedHabits: unifiedHabits ?? this.unifiedHabits,
      totalHabits: totalHabits ?? this.totalHabits,
      completedToday: completedToday ?? this.completedToday,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      templates: templates ?? this.templates,
    );
  }
}

/// Provider for habits screen state
final habitsScreenProvider = StateNotifierProvider.autoDispose<HabitsScreenNotifier, HabitsScreenState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';

  return HabitsScreenNotifier(
    repository,
    userId,
    () => ref.read(habitsProvider),
    AppColors.accent,
  );
});

/// Full-screen habits page showing all tracked habits in detail
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Auto-tracked habits (for stats calculation)
    final autoHabits = ref.watch(habitsProvider);

    // Unified habits from provider
    final habitsState = ref.watch(habitsScreenProvider);
    final habitsNotifier = ref.read(habitsScreenProvider.notifier);

    // Refresh unified list when auto habits change
    ref.listen(habitsProvider, (prev, next) {
      habitsNotifier.refreshUnifiedList(next);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: habitsNotifier.loadHabits,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16,
                    right: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Your Habits',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Summary card
                        _buildSummaryCard(
                          context,
                          autoHabits: autoHabits,
                          customHabits: habitsState.customHabits,
                          completedToday: habitsState.completedToday,
                          totalHabits: habitsState.totalHabits,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 24),
                        // Hint text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              size: 14,
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hold to reorder • Swipe to delete',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Unified reorderable list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: habitsState.unifiedHabits.length,
                    onReorder: (oldIndex, newIndex) {
                      HapticService.medium();
                      habitsNotifier.reorderHabits(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final scale = Tween<double>(begin: 1.0, end: 1.03).animate(animation);
                          return Transform.scale(
                            scale: scale.value,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final habit = habitsState.unifiedHabits[index];
                      return _buildUnifiedHabitItem(
                        context,
                        ref,
                        index: index,
                        habit: habit,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                context.pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Floating add button (bottom right)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticService.medium();
                _showAddHabitSheet(context, ref, habitsState.templates);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: isDark ? Colors.black : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build unified habit card with reorder and swipe-to-delete
  Widget _buildUnifiedHabitItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required UnifiedHabitItem habit,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Padding(
      key: ValueKey(habit.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss_${habit.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          HapticService.error();
          final message = habit.isAutoTracked
              ? 'Auto-tracked habits like "${habit.name}" cannot be deleted. They are based on your activity.'
              : 'Are you sure you want to delete "${habit.name}"? This cannot be undone.';

          if (habit.isAutoTracked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return false;
          }

          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Habit?'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          HapticService.medium();
          ref.read(habitsScreenProvider.notifier).deleteHabit(habit.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${habit.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: ReorderableDragStartListener(
          index: index,
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              // Navigate to habit detail screen
              context.push('/habit/${habit.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: habit.todayCompleted
                      ? habit.color.withValues(alpha: 0.5)
                      : cardBorder,
                  width: habit.todayCompleted ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Drag handle
                      Icon(
                        Icons.drag_indicator,
                        color: textSecondary.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Checkbox for custom habits / check icon for auto
                      if (habit.isAutoTracked)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: habit.todayCompleted
                                ? habit.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: habit.todayCompleted
                                  ? habit.color
                                  : cardBorder,
                              width: 2,
                            ),
                          ),
                          child: habit.todayCompleted
                              ? Icon(Icons.check, color: habit.color, size: 18)
                              : null,
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            HapticService.medium();
                            ref.read(habitsScreenProvider.notifier).toggleHabit(
                              habit.id,
                              !habit.todayCompleted,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: habit.todayCompleted
                                  ? habit.color
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: habit.todayCompleted
                                    ? habit.color
                                    : cardBorder,
                                width: 2,
                              ),
                            ),
                            child: habit.todayCompleted
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: habit.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(habit.icon, color: habit.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    habit.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: habit.todayCompleted
                                          ? textSecondary
                                          : textPrimary,
                                      decoration: habit.todayCompleted && !habit.isAutoTracked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (habit.isAutoTracked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: textSecondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (habit.isAutoTracked && habit.last30Days.isNotEmpty)
                              Text(
                                '${habit.last30Days.where((d) => d).length} of 30 days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              )
                            else if (habit.description != null && habit.description!.isNotEmpty)
                              Text(
                                habit.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Streak badge
                      if (habit.currentStreak > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: habit.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department, size: 14, color: habit.color),
                              const SizedBox(width: 2),
                              Text(
                                '${habit.currentStreak}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: habit.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (habit.route != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: textSecondary, size: 20),
                      ],
                    ],
                  ),
                  // Mini grid for auto-tracked habits
                  if (habit.isAutoTracked && habit.last30Days.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMiniGrid(habit.last30Days, habit.color, emptyColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required List<HabitData> autoHabits,
    required List<HabitWithStatus> customHabits,
    required int completedToday,
    required int totalHabits,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    // Calculate totals from auto-habits
    final autoTracked = autoHabits.fold<int>(
      0, (sum, h) => sum + h.last30Days.where((d) => d).length);
    final autoPossible = autoHabits.length * 30;
    final autoPercentage = autoPossible > 0 ? (autoTracked / autoPossible * 100).round() : 0;

    // Combined stats
    final totalCustomCompleted = customHabits.where((h) => h.todayCompleted).length;
    final autoCompletedToday = autoHabits.where((h) => h.last30Days.isNotEmpty && h.last30Days.last).length;
    final combinedTodayTotal = autoHabits.length + customHabits.length;
    final combinedTodayCompleted = autoCompletedToday + totalCustomCompleted;

    // Find longest streak across all habits
    final autoStreaks = autoHabits.map((h) => h.currentStreak).toList();
    final customStreaks = customHabits.map((h) => h.currentStreak).toList();
    final allStreaks = [...autoStreaks, ...customStreaks];
    final longestStreak = allStreaks.isNotEmpty
        ? allStreaks.reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Completed',
                  value: '$combinedTodayCompleted/$combinedTodayTotal',
                  icon: Icons.check_circle_outline,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: '30-Day Rate',
                  value: '$autoPercentage%',
                  icon: Icons.calendar_today,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Best Streak',
                  value: '$longestStreak',
                  icon: Icons.local_fire_department,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: accentColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniGrid(List<bool> days, Color accentColor, Color emptyColor) {
    final paddedDays = List<bool>.from(days);
    while (paddedDays.length < 30) {
      paddedDays.insert(0, false);
    }
    if (paddedDays.length > 30) {
      paddedDays.removeRange(0, paddedDays.length - 30);
    }

    // GitHub-style contribution grid: 5 rows x 6 columns with circular dots
    const int columns = 10;
    const int rows = 3;
    const double dotSize = 10.0;
    const double spacing = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? spacing : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(columns, (colIndex) {
              final index = rowIndex * columns + colIndex;
              final completed = index < paddedDays.length ? paddedDays[index] : false;
              return Padding(
                padding: EdgeInsets.only(right: colIndex < columns - 1 ? spacing : 0),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: completed ? accentColor : emptyColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref, List<HabitTemplate> templates) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final sheetBg = isDark ? AppColors.pureBlack : Colors.white;
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Use local templates if API returned empty
    final displayTemplates = templates.isEmpty ? HabitTemplate.defaults : templates;

    // Group by category
    final grouped = <HabitCategory, List<HabitTemplate>>{};
    for (final t in displayTemplates) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Add Habit',
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
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Create Custom section at top
                      GestureDetector(
                        onTap: () {
                          HapticService.medium();
                          Navigator.pop(context);
                          _showCreateCustomHabitSheet(context, ref);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.15),
                                accentColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: isDark ? Colors.black : Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Custom Habit',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Define your own habit with custom name & icon',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: accentColor, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Templates section header
                      Text(
                        'OR CHOOSE A TEMPLATE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Templates by category
                      for (final category in HabitCategory.values)
                        if (grouped.containsKey(category)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              category.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textSecondary.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...grouped[category]!.map((template) {
                            final templateColor = _parseColor(template.color, AppColors.accent);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  HapticService.medium();
                                  Navigator.pop(context);
                                  await ref.read(habitsScreenProvider.notifier)
                                      .createHabitFromTemplate(template.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added "${template.name}"'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
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
                                          color: templateColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getIconFromName(template.icon),
                                          color: templateColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              template.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              template.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.add_circle_outline,
                                        color: templateColor, size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCustomHabitSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final sheetBg = isDark ? AppColors.pureBlack : Colors.white;
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final nameController = TextEditingController();
    String selectedIcon = 'check_circle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header with back button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticService.light();
                              Navigator.pop(context);
                              // Re-open the Add Habit sheet
                              _showAddHabitSheet(context, ref, ref.read(habitsScreenProvider).templates);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: textSecondary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: textPrimary,
                                size: 18,
                              ),
                            ),
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
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
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
                                color: isSelected ? accentColor : cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? null : Border.all(
                                  color: textSecondary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                _getIconFromName(iconName),
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textSecondary,
                                size: 22,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

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
                            Navigator.pop(context);
                            // TODO: Call API to create custom habit
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Created "${nameController.text}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
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
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String colorHex, Color fallback) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _getIconFromName(String iconName) {
    const iconMap = {
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
      'delivery_dining': Icons.delivery_dining,
      'nightlight': Icons.nightlight,
      'restaurant': Icons.restaurant,
      'soup_kitchen': Icons.soup_kitchen,
      'heart': Icons.favorite,
      'running': Icons.directions_run,
      'apple': Icons.apple,
      'star': Icons.star,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }
}
