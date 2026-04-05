part of 'set_adjustment_sheet.dart';


class _InWorkoutSetEditingSheetState extends State<InWorkoutSetEditingSheet> {
  late List<EditableSetData> _sets;
  SetAdjustmentReason? _selectedReason;
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Deep copy initial sets
    _sets = widget.initialSets.map((s) => EditableSetData(
      reps: s.reps,
      weight: s.weight,
      isCompleted: s.isCompleted,
    )).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Add a new set with default or copied values
  void _addSet({bool copyLast = false}) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (copyLast && _sets.isNotEmpty) {
        final lastSet = _sets.last;
        _sets.add(EditableSetData(
          reps: lastSet.reps,
          weight: lastSet.weight,
        ));
      } else {
        _sets.add(EditableSetData(
          reps: widget.defaultReps,
          weight: widget.defaultWeight,
        ));
      }
    });
    // Scroll to show new set
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Remove the last incomplete set
  void _removeSet() {
    if (_sets.isEmpty) return;
    // Only remove incomplete sets
    final lastIncompleteIndex = _sets.lastIndexWhere((s) => !s.isCompleted);
    if (lastIncompleteIndex >= 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sets.removeAt(lastIncompleteIndex);
      });
    }
  }

  /// Update reps for a specific set
  void _updateReps(int setIndex, int reps) {
    if (setIndex >= _sets.length) return;
    setState(() {
      _sets[setIndex] = _sets[setIndex].copyWith(reps: reps.clamp(1, 100));
    });
  }

  /// Update weight for a specific set
  void _updateWeight(int setIndex, double weight) {
    if (setIndex >= _sets.length) return;
    setState(() {
      _sets[setIndex] = _sets[setIndex].copyWith(weight: weight.clamp(0, 1000));
    });
  }

  /// Whether a reason is required (sets were reduced)
  bool get _requiresReason => _sets.length < widget.originalSetCount;

  /// Whether confirm can be pressed
  bool get _canConfirm => !_requiresReason || _selectedReason != null;

  void _handleConfirm() {
    if (!_canConfirm) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onConfirm(InWorkoutSetEditResult(
      sets: _sets,
      originalSetCount: widget.originalSetCount,
      newSetCount: _sets.length,
      adjustmentReason: _requiresReason ? _selectedReason : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    ));
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final weightUnit = widget.useKg ? 'kg' : 'lbs';

    final completedCount = _sets.where((s) => s.isCompleted).length;
    final remainingCount = _sets.length - completedCount;

    return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Sets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _handleCancel,
                    icon: Icon(Icons.close, color: textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: cardBg,
                    ),
                  ),
                ],
              ),
            ),

            // Quick action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // +1 Set button
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add,
                      label: '+1 Set',
                      color: AppColors.cyan,
                      onTap: () => _addSet(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // -1 Set button (only if we have incomplete sets)
                  if (remainingCount > 0)
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.remove,
                        label: '-1 Set',
                        color: AppColors.orange,
                        onTap: _removeSet,
                      ),
                    ),
                  if (remainingCount > 0) const SizedBox(width: 8),
                  // Copy Last Set button
                  if (_sets.isNotEmpty)
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.content_copy,
                        label: 'Copy Last',
                        color: AppColors.purple,
                        onTap: () => _addSet(copyLast: true),
                      ),
                    ),
                ],
              ),
            ),

            // Sets count indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$remainingCount remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_sets.length != widget.originalSetCount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _sets.length < widget.originalSetCount
                            ? AppColors.orange.withOpacity(0.1)
                            : AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _sets.length < widget.originalSetCount
                            ? '${widget.originalSetCount - _sets.length} removed'
                            : '+${_sets.length - widget.originalSetCount} added',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _sets.length < widget.originalSetCount
                              ? AppColors.orange
                              : AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Sets list
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  final isCompleted = set.isCompleted;
                  final isCurrent = index == widget.currentSetIndex && !isCompleted;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withOpacity(0.1)
                          : isCurrent
                              ? AppColors.cyan.withOpacity(0.1)
                              : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success.withOpacity(0.3)
                            : isCurrent
                                ? AppColors.cyan.withOpacity(0.5)
                                : isDark
                                    ? AppColors.cardBorder
                                    : AppColorsLight.cardBorder,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Set number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.success.withOpacity(0.2)
                                : isCurrent
                                    ? AppColors.cyan.withOpacity(0.2)
                                    : textMuted.withOpacity(0.1),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? AppColors.cyan : textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Reps input
                        Expanded(
                          child: _SetValueEditor(
                            label: 'Reps',
                            value: set.reps.toDouble(),
                            unit: '',
                            isInteger: true,
                            enabled: !isCompleted,
                            onChanged: (v) => _updateReps(index, v.toInt()),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Weight input
                        Expanded(
                          child: _SetValueEditor(
                            label: 'Weight',
                            value: set.weight,
                            unit: weightUnit,
                            isInteger: false,
                            enabled: !isCompleted,
                            onChanged: (v) => _updateWeight(index, v),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Reason selector (only if sets were reduced)
            if (_requiresReason) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reducing sets?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SetAdjustmentReason.values.map((reason) {
                        final isSelected = _selectedReason == reason;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedReason = reason;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.orange.withOpacity(0.15)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.orange
                                    : isDark
                                        ? AppColors.cardBorder
                                        : AppColorsLight.cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  reason.icon,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.orange
                                      : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reason.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.orange
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Additional notes (optional)',
                        hintStyle: TextStyle(color: textMuted, fontSize: 13),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _handleCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark
                            ? AppColors.elevated
                            : AppColorsLight.elevated,
                        disabledForegroundColor: textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _requiresReason ? 'Save Changes' : 'Apply',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

