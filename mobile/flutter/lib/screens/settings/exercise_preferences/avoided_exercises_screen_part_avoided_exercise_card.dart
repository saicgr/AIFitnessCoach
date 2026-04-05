part of 'avoided_exercises_screen.dart';


/// Card widget for an avoided exercise
class _AvoidedExerciseCard extends ConsumerWidget {
  final AvoidedExercise exercise;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _AvoidedExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.block,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (exercise.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.reason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                    if (exercise.isTemporary && exercise.endDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Until ${exercise.endDate!.day}/${exercise.endDate!.month}/${exercise.endDate!.year}',
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
              // Edit button
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppColors.cyan, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              // Remove button
              IconButton(
                icon: Icon(Icons.close, color: textMuted, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
          // View Substitutes button
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showSubstitutesSheet(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    'View Safe Alternatives',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubstitutesSheet(BuildContext context, WidgetRef ref) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(child: _SubstitutesSheet(
        exerciseName: exercise.exerciseName,
        reason: exercise.reason,
        isDark: isDark,
      )),
    );
  }
}


/// Sheet showing substitute exercise suggestions
class _SubstitutesSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? reason;
  final bool isDark;

  const _SubstitutesSheet({
    required this.exerciseName,
    this.reason,
    required this.isDark,
  });

  @override
  ConsumerState<_SubstitutesSheet> createState() => _SubstitutesSheetState();
}


class _SubstitutesSheetState extends ConsumerState<_SubstitutesSheet> {
  bool _isLoading = true;
  SubstituteResponse? _substitutes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubstitutes();
  }

  Future<void> _loadSubstitutes() async {
    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);
      final result = await repo.getSuggestedSubstitutes(
        widget.exerciseName,
        reason: widget.reason,
      );
      if (mounted) {
        setState(() {
          _substitutes = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? AppColors.background : AppColorsLight.background;
    final textColor = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.swap_horiz, color: AppColors.cyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Alternatives',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Instead of ${widget.exerciseName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.reason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medical_services, size: 14, color: AppColors.orange),
                        const SizedBox(width: 6),
                        Text(
                          widget.reason!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error loading alternatives', style: TextStyle(color: textMuted)),
                            ],
                          ),
                        ),
                      )
                    : _substitutes == null || _substitutes!.substitutes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: textMuted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No specific alternatives found',
                                    style: TextStyle(color: textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Browse the exercise library for options',
                                    style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            itemCount: _substitutes!.substitutes.length,
                            itemBuilder: (context, index) {
                              final sub = _substitutes!.substitutes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: elevatedColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: sub.isSafeForReason
                                      ? Border.all(color: AppColors.green.withValues(alpha: 0.3))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          if (sub.equipment != null || sub.muscleGroup != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                [
                                                  if (sub.muscleGroup != null) sub.muscleGroup,
                                                  if (sub.equipment != null) sub.equipment,
                                                ].join(' • '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textMuted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (sub.isSafeForReason)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Safe',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          // Message at bottom
          if (_substitutes != null && _substitutes!.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _substitutes!.message,
                style: TextStyle(fontSize: 12, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
    );
  }
}


/// Options collected from the avoid options sheet
class _AvoidOptions {
  final String? reason;
  final bool isTemporary;
  final DateTime? endDate;
  final bool goBack;

  const _AvoidOptions({
    this.reason,
    this.isTemporary = false,
    this.endDate,
    this.goBack = false,
  });
}

