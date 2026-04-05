part of 'habits_screen.dart';



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

  DateTime? _lastLoadTime;

  HabitsScreenNotifier(
    this._repository,
    this._userId,
    this._getAutoHabits,
    this._accentColor,
  ) : super(const HabitsScreenState()) {
    loadHabits();
  }

  Future<void> loadHabits({bool force = false}) async {
    // Skip reload if data was loaded recently (within 30s) unless forced
    if (!force && _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inSeconds < 30 &&
        state.unifiedHabits.isNotEmpty) {
      return;
    }

    // Only show loading spinner on first load (not refreshes)
    final isFirstLoad = state.unifiedHabits.isEmpty;
    if (isFirstLoad) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Parallelize API + local storage calls
      final results = await Future.wait([
        _repository.getTodayHabits(_userId),
        _loadSavedOrder(),
      ]);

      final todayResponse = results[0] as dynamic;
      final savedOrder = results[1] as List<String>;

      // Build unified habit list with saved order
      final unified = await _buildUnifiedList(
        _getAutoHabits(),
        todayResponse.habits,
        savedOrder,
      );

      _lastLoadTime = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        customHabits: todayResponse.habits,
        unifiedHabits: unified,
        totalHabits: todayResponse.totalHabits,
        completedToday: todayResponse.completedToday,
        completionPercentage: todayResponse.completionPercentage,
        templates: HabitTemplate.defaults,
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

  /// Refresh unified list with latest auto-tracked data.
  /// Skipped while the initial load is running to prevent a race that could
  /// blank the list before loadHabits() finishes populating customHabits.
  Future<void> refreshUnifiedList(List<HabitData> autoHabits) async {
    if (state.isLoading) return;
    final savedOrder = await _loadSavedOrder();
    final unified = await _buildUnifiedList(autoHabits, state.customHabits, savedOrder);
    // Never blank the list — if the rebuild somehow produces fewer items, keep current.
    if (unified.isEmpty && state.unifiedHabits.isNotEmpty) return;
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

