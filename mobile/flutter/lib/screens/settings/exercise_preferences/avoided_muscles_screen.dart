import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Provider for avoided muscles list
final avoidedMusclesProvider = FutureProvider.family<List<AvoidedMuscle>, String>((ref, userId) async {
  final repo = ref.watch(exercisePreferencesRepositoryProvider);
  return repo.getAvoidedMuscles(userId);
});

/// Provider for available muscle groups
final muscleGroupsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(exercisePreferencesRepositoryProvider);
  return repo.getMuscleGroups();
});

/// Screen for managing muscle groups to avoid
class AvoidedMusclesScreen extends ConsumerStatefulWidget {
  const AvoidedMusclesScreen({super.key});

  @override
  ConsumerState<AvoidedMusclesScreen> createState() => _AvoidedMusclesScreenState();
}

class _AvoidedMusclesScreenState extends ConsumerState<AvoidedMusclesScreen> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Muscles to Avoid')),
        body: const Center(child: Text('Please log in')),
      );
    }

    final avoidedAsync = ref.watch(avoidedMusclesProvider(userId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Muscles to Avoid',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.cyan),
            onPressed: () => _showAddMuscleSheet(context, userId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.accessibility_new, color: AppColors.purple, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Muscle groups you add here will be avoided or reduced in AI-generated workouts.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: avoidedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error loading muscles', style: TextStyle(color: textMuted)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(avoidedMusclesProvider(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (muscles) {
                if (muscles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.green.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No muscles to avoid',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add muscle groups to skip',
                          style: TextStyle(color: textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: muscles.length,
                  itemBuilder: (context, index) {
                    final muscle = muscles[index];
                    return _AvoidedMuscleCard(
                      muscle: muscle,
                      isDark: isDark,
                      onRemove: () => _removeMuscle(userId, muscle),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMuscleSheet(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    String? selectedMuscle;
    String reason = '';
    bool isTemporary = false;
    DateTime? endDate;
    String severity = 'avoid';

    final muscleGroupsAsync = ref.read(muscleGroupsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Add Muscle Group to Avoid',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Muscle group dropdown
                Text(
                  'Select Muscle Group',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                muscleGroupsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Text('Error loading muscle groups', style: TextStyle(color: AppColors.error)),
                  data: (data) {
                    final primary = (data['primary'] as List<dynamic>).cast<String>();
                    final secondary = (data['secondary'] as List<dynamic>).cast<String>();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary muscles
                        Text(
                          'Primary',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: primary.map((muscle) {
                            final isSelected = selectedMuscle == muscle;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedMuscle = muscle),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cyan.withValues(alpha: 0.2)
                                      : elevatedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.cyan
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _formatMuscleName(muscle),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? AppColors.cyan : textColor,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Secondary muscles
                        Text(
                          'Secondary',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: secondary.map((muscle) {
                            final isSelected = selectedMuscle == muscle;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedMuscle = muscle),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cyan.withValues(alpha: 0.2)
                                      : elevatedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.cyan
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  _formatMuscleName(muscle),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? AppColors.cyan : textColor,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Severity selector
                Text(
                  'Severity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => severity = 'avoid'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: severity == 'avoid'
                                ? AppColors.error.withValues(alpha: 0.15)
                                : elevatedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: severity == 'avoid'
                                  ? AppColors.error
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.block,
                                color: severity == 'avoid' ? AppColors.error : textMuted,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Avoid',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: severity == 'avoid' ? AppColors.error : textColor,
                                ),
                              ),
                              Text(
                                'Skip completely',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => severity = 'reduce'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: severity == 'reduce'
                                ? AppColors.orange.withValues(alpha: 0.15)
                                : elevatedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: severity == 'reduce'
                                  ? AppColors.orange
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.remove_circle_outline,
                                color: severity == 'reduce' ? AppColors.orange : textMuted,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reduce',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: severity == 'reduce' ? AppColors.orange : textColor,
                                ),
                              ),
                              Text(
                                'Limit exposure',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Reason field
                TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    labelStyle: TextStyle(color: textMuted),
                    hintText: 'e.g., Lower back injury',
                    hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: elevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => reason = value,
                ),
                const SizedBox(height: 16),
                // Temporary toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temporary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Set an end date for this restriction',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isTemporary,
                        onChanged: (value) {
                          setSheetState(() {
                            isTemporary = value;
                            if (!value) endDate = null;
                          });
                        },
                        activeColor: AppColors.cyan,
                      ),
                    ],
                  ),
                ),
                if (isTemporary) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              endDate != null
                                  ? 'Until ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                  : 'Select end date',
                              style: TextStyle(
                                fontSize: 15,
                                color: endDate != null ? textColor : textMuted,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAdding || selectedMuscle == null
                        ? null
                        : () => _addMuscle(
                              context,
                              userId,
                              selectedMuscle!,
                              reason.trim().isEmpty ? null : reason.trim(),
                              isTemporary,
                              endDate,
                              severity,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add to Avoid List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMuscleName(String muscle) {
    return muscle
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Future<void> _addMuscle(
    BuildContext context,
    String userId,
    String muscleGroup,
    String? reason,
    bool isTemporary,
    DateTime? endDate,
    String severity,
  ) async {
    setState(() => _isAdding = true);
    HapticService.light();

    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);
      await repo.addAvoidedMuscle(
        userId,
        muscleGroup,
        reason: reason,
        isTemporary: isTemporary,
        endDate: endDate,
        severity: severity,
      );

      ref.invalidate(avoidedMusclesProvider(userId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${_formatMuscleName(muscleGroup)}" to avoid list'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removeMuscle(String userId, AvoidedMuscle muscle) async {
    HapticService.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Muscle Group'),
        content: Text('Remove "${muscle.displayName}" from avoid list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(exercisePreferencesRepositoryProvider);
        await repo.removeAvoidedMuscle(userId, muscle.id);
        ref.invalidate(avoidedMusclesProvider(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${muscle.displayName}"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for an avoided muscle
class _AvoidedMuscleCard extends StatelessWidget {
  final AvoidedMuscle muscle;
  final bool isDark;
  final VoidCallback onRemove;

  const _AvoidedMuscleCard({
    required this.muscle,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final isAvoid = muscle.severity == 'avoid';
    final severityColor = isAvoid ? AppColors.error : AppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAvoid ? Icons.block : Icons.remove_circle_outline,
              color: severityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      muscle.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAvoid ? 'AVOID' : 'REDUCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (muscle.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    muscle.reason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
                if (muscle.isTemporary && muscle.endDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Until ${muscle.endDate!.day}/${muscle.endDate!.month}/${muscle.endDate!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          IconButton(
            icon: Icon(Icons.close, color: textMuted, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
