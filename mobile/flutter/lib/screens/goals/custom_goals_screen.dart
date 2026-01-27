import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/custom_goal.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

/// Suggestions for custom goals
const List<String> _goalSuggestions = [
  'Improve box jump height',
  'Do my first pull-up',
  'Run a 5K without stopping',
  'Increase vertical leap',
  'Master the handstand',
  'Touch my toes (flexibility)',
  'Sprint 100m faster',
  'Build explosive power',
  'Complete 10 unassisted pull-ups',
  'Hold a plank for 5 minutes',
];

/// Screen for managing custom training goals
class CustomGoalsScreen extends ConsumerStatefulWidget {
  const CustomGoalsScreen({super.key});

  @override
  ConsumerState<CustomGoalsScreen> createState() => _CustomGoalsScreenState();
}

class _CustomGoalsScreenState extends ConsumerState<CustomGoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<CustomGoal> _goals = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/custom-goals/${authState.user!.id}',
      );

      final data = response.data;
      if (data != null && data is List) {
        setState(() {
          _goals = data.map<CustomGoal>((g) => CustomGoal.fromJson(g)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load goals: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createGoal(String goalText) async {
    if (goalText.trim().isEmpty) return;
    if (_goals.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 custom goals allowed'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/custom-goals/',
        data: {
          'user_id': authState.user!.id,
          'goal_text': goalText.trim(),
          'priority': 3,
        },
      );

      final responseData = response.data;
      if (responseData != null) {
        final newGoal = CustomGoal.fromJson(responseData);
        setState(() {
          _goals.insert(0, newGoal);
          _goalController.clear();
        });

        // Show success with keywords preview
        if (mounted) {
          _showGoalCreatedSheet(newGoal);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showGoalCreatedSheet(CustomGoal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Goal Created!',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.goalText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'AI-Generated Keywords',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: goal.searchKeywords.take(8).map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'These keywords will help find relevant exercises for your goal.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(CustomGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text(
          'Delete Goal?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.goalText}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
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
    );

    if (confirmed != true) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/custom-goals/${goal.id}');

      setState(() {
        _goals.removeWhere((g) => g.id == goal.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updatePriority(CustomGoal goal, int newPriority) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/custom-goals/${goal.id}',
        data: {'priority': newPriority},
      );

      setState(() {
        final index = _goals.indexWhere((g) => g.id == goal.id);
        if (index != -1) {
          _goals[index] = goal.copyWith(priority: newPriority);
          // Re-sort by priority
          _goals.sort((a, b) => b.priority.compareTo(a.priority));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update priority: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Custom Goals',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Input section
          _buildInputSection(),

          // Goals list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _goals.isEmpty
                        ? _buildEmptyState()
                        : _buildGoalsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    // Filter suggestions to show ones not already added
    final availableSuggestions = _goalSuggestions
        .where((s) => !_goals.any((g) => g.goalText == s))
        .take(4)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input field
          TextField(
            controller: _goalController,
            focusNode: _focusNode,
            enabled: !_isCreating,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., "Improve box jump height"',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: _isCreating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyan,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.cyan),
                      onPressed: () => _createGoal(_goalController.text),
                    ),
            ),
            onSubmitted: _isCreating ? null : _createGoal,
            textInputAction: TextInputAction.done,
          ),

          // Quick suggestions
          if (availableSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableSuggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: _isCreating ? null : () => _createGoal(suggestion),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              size: 14,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              suggestion,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Custom Goals Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add specific skills or objectives you want to improve.\nAI will help find the right exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGoals,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return _GoalCard(
          goal: goal,
          onDelete: () => _deleteGoal(goal),
          onPriorityChanged: (priority) => _updatePriority(goal, priority),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(
              begin: 0.1,
              delay: (50 * index).ms,
            );
      },
    );
  }
}

/// Card widget for displaying a single custom goal
class _GoalCard extends StatelessWidget {
  final CustomGoal goal;
  final VoidCallback onDelete;
  final ValueChanged<int> onPriorityChanged;

  const _GoalCard({
    required this.goal,
    required this.onDelete,
    required this.onPriorityChanged,
  });

  Color _getGoalTypeColor() {
    switch (goal.goalType.toLowerCase()) {
      case 'power':
      case 'plyometric':
        return AppColors.orange;
      case 'skill':
        return AppColors.purple;
      case 'endurance':
        return AppColors.cyan;
      case 'strength':
        return AppColors.red;
      case 'flexibility':
      case 'mobility':
        return AppColors.teal;
      default:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getGoalTypeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Goal type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goal.goalType.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Priority stars
                Row(
                  children: List.generate(5, (index) {
                    final filled = index < goal.priority;
                    return GestureDetector(
                      onTap: () => onPriorityChanged(index + 1),
                      child: Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 18,
                        color: filled ? AppColors.yellow : AppColors.textMuted,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Goal text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              goal.goalText,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Keywords preview
          if (goal.searchKeywords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: goal.searchKeywords.take(5).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      keyword,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Training notes (if available)
          if (goal.trainingNotes != null && goal.trainingNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      goal.trainingNotes!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
