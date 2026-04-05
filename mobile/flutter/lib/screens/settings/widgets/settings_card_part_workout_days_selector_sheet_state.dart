part of 'settings_card.dart';


class _WorkoutDaysSelectorSheetState
    extends ConsumerState<_WorkoutDaysSelectorSheet> {
  late Set<int> _selectedDays;
  bool _isLoading = false;
  String? _errorMessage;

  static const _days = [
    (label: 'M', full: 'Monday', short: 'Mon', value: 0),
    (label: 'T', full: 'Tuesday', short: 'Tue', value: 1),
    (label: 'W', full: 'Wednesday', short: 'Wed', value: 2),
    (label: 'T', full: 'Thursday', short: 'Thu', value: 3),
    (label: 'F', full: 'Friday', short: 'Fri', value: 4),
    (label: 'S', full: 'Saturday', short: 'Sat', value: 5),
    (label: 'S', full: 'Sunday', short: 'Sun', value: 6),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = Set.from(widget.initialDays);
    if (_selectedDays.isEmpty) {
      // Default to Mon, Wed, Fri if no days set
      _selectedDays = {0, 2, 4};
    }
  }

  void _toggleDay(int dayValue) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(dayValue)) {
        // Don't allow removing if only 1 day selected
        if (_selectedDays.length > 1) {
          _selectedDays.remove(dayValue);
        }
      } else {
        _selectedDays.add(dayValue);
      }
      _errorMessage = null;
    });
  }

  Future<void> _saveWorkoutDays() async {
    if (_selectedDays.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one workout day';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);

      // Convert day indices to day names
      final sortedDays = _selectedDays.toList()..sort();
      final dayNamesList = sortedDays
          .map((idx) => _days.firstWhere((d) => d.value == idx).short)
          .toList();

      // Call the quick day change API
      await repo.quickDayChange(widget.userId, dayNamesList);

      // Refresh user data
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout days updated to ${dayNamesList.join(", ")}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update workout days. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final hasChanges =
        !_setEquals(_selectedDays, Set.from(widget.initialDays));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Workout Days',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select which days you want to work out',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Day selector grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day.value);

                return GestureDetector(
                  onTap: () => _toggleDay(day.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan
                          : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppColorsLight.textPrimary),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Selected count
            Text(
              '${_selectedDays.length} day${_selectedDays.length != 1 ? 's' : ''} selected',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changing days will reschedule your upcoming workouts automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || !hasChanges) ? null : _saveWorkoutDays,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasChanges ? 'Save Changes' : 'No Changes',
                        style: const TextStyle(
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
  }

  /// Helper to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}


/// A tile for weight unit selection in the bottom sheet.
class _UnitChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? accent
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }
}

