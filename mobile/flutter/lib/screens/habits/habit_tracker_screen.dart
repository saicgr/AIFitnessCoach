import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habit_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_progress_header.dart';
import 'widgets/create_habit_sheet.dart';
import 'widgets/habit_templates_sheet.dart';

/// Main habit tracking screen
class HabitTrackerScreen extends ConsumerStatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  ConsumerState<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends ConsumerState<HabitTrackerScreen> {
  HabitCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final habitsState = ref.watch(habitsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsights(context, userId),
            tooltip: 'View Insights',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(habitsProvider(userId).notifier).loadTodayHabits();
        },
        child: CustomScrollView(
          slivers: [
            // Progress header
            SliverToBoxAdapter(
              child: HabitProgressHeader(
                completed: habitsState.completedToday,
                total: habitsState.totalHabits,
                percentage: habitsState.completionPercentage,
              ),
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: _buildCategoryFilter(),
            ),

            // Habits list
            if (habitsState.isLoading && habitsState.habits.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (habitsState.habits.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context, userId),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filteredHabits = _getFilteredHabits(habitsState.habits);
                      if (index >= filteredHabits.length) return null;

                      final habit = filteredHabits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HabitCard(
                          habit: habit,
                          onToggle: (completed) => _toggleHabit(userId, habit, completed),
                          onTap: () => _showHabitDetail(context, habit),
                          onEdit: () => _editHabit(context, userId, habit),
                          onDelete: () => _deleteHabit(userId, habit),
                        ),
                      );
                    },
                    childCount: _getFilteredHabits(habitsState.habits).length,
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitOptions(context, userId),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [null, ...HabitCategory.values];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          final label = category?.label ?? 'All';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              selectedColor: AppColors.teal.withValues(alpha: 0.2),
              checkmarkColor: AppColors.teal,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<HabitWithStatus> _getFilteredHabits(List<HabitWithStatus> habits) {
    if (_selectedCategory == null) return habits;
    return habits.where((h) => h.category == _selectedCategory).toList();
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start building healthy habits today.\nTrack what matters to you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddHabitOptions(context, userId),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Habit'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleHabit(String userId, HabitWithStatus habit, bool completed) {
    HapticFeedback.lightImpact();
    ref.read(habitsProvider(userId).notifier).toggleHabit(habit.id, completed);
  }

  void _showAddHabitOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Choose from Templates'),
              subtitle: const Text('Quick start with pre-made habits'),
              onTap: () {
                Navigator.pop(context);
                _showTemplates(context, userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Create Custom Habit'),
              subtitle: const Text('Build your own habit from scratch'),
              onTap: () {
                Navigator.pop(context);
                _showCreateHabit(context, userId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTemplates(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => HabitTemplatesSheet(
          scrollController: scrollController,
          onTemplateSelected: (template) async {
            Navigator.pop(context);
            final habit = HabitCreate(
              name: template.name,
              description: template.description,
              category: template.category,
              habitType: template.habitType,
              targetCount: template.suggestedTargetCount,
              unit: template.unit,
              icon: template.icon,
              color: template.color,
            );
            await ref.read(habitsProvider(userId).notifier).createHabit(habit);
          },
        ),
      ),
    );
  }

  void _showCreateHabit(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CreateHabitSheet(
          onSave: (habit) async {
            Navigator.pop(context);
            await ref.read(habitsProvider(userId).notifier).createHabit(habit);
          },
        ),
      ),
    );
  }

  void _showHabitDetail(BuildContext context, HabitWithStatus habit) {
    // TODO: Navigate to habit detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Streak: ${habit.currentStreak} days'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editHabit(BuildContext context, String userId, HabitWithStatus habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CreateHabitSheet(
          existingHabit: habit,
          onSave: (update) async {
            Navigator.pop(context);
            await ref.read(habitsProvider(userId).notifier).updateHabit(
                  habit.id,
                  HabitUpdate(
                    name: update.name,
                    description: update.description,
                    category: update.category,
                    habitType: update.habitType,
                    frequency: update.frequency,
                    specificDays: update.specificDays,
                    targetCount: update.targetCount,
                    unit: update.unit,
                    icon: update.icon,
                    color: update.color,
                  ),
                );
          },
        ),
      ),
    );
  }

  void _deleteHabit(String userId, HabitWithStatus habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(habitsProvider(userId).notifier).archiveHabit(habit.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInsights(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              final insightsAsync = ref.watch(habitInsightsProvider(userId));

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Habit Insights',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: insightsAsync.when(
                        data: (insights) => ListView(
                          controller: scrollController,
                          children: [
                            _buildInsightCard(
                              context,
                              'Summary',
                              insights.summary,
                              Icons.analytics,
                            ),
                            if (insights.bestPerforming.isNotEmpty)
                              _buildInsightCard(
                                context,
                                'Best Performing',
                                insights.bestPerforming.join(', '),
                                Icons.star,
                                color: Colors.amber,
                              ),
                            if (insights.needsImprovement.isNotEmpty)
                              _buildInsightCard(
                                context,
                                'Needs Attention',
                                insights.needsImprovement.join(', '),
                                Icons.warning,
                                color: Colors.orange,
                              ),
                            if (insights.suggestions.isNotEmpty)
                              _buildInsightCard(
                                context,
                                'Suggestions',
                                insights.suggestions.join('\n'),
                                Icons.lightbulb,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => Center(
                          child: Text('Error loading insights: $e'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String content,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
