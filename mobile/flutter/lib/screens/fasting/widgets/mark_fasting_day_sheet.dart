import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/fasting_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for marking a historical date as a fasting day
class MarkFastingDaySheet extends ConsumerStatefulWidget {
  final String userId;
  final DateTime? initialDate;
  final VoidCallback? onSuccess;

  const MarkFastingDaySheet({
    super.key,
    required this.userId,
    this.initialDate,
    this.onSuccess,
  });

  /// Show the mark fasting day sheet
  static Future<MarkFastingDayResult?> show({
    required BuildContext context,
    required String userId,
    DateTime? initialDate,
    VoidCallback? onSuccess,
  }) async {
    return showModalBottomSheet<MarkFastingDayResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarkFastingDaySheet(
        userId: userId,
        initialDate: initialDate,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<MarkFastingDaySheet> createState() => _MarkFastingDaySheetState();
}

class _MarkFastingDaySheetState extends ConsumerState<MarkFastingDaySheet> {
  late DateTime _selectedDate;
  String _selectedProtocol = '16:8';
  double _estimatedHours = 16;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Available protocols for selection
  static const List<Map<String, dynamic>> _protocols = [
    {'id': '12:12', 'name': '12:12', 'hours': 12.0},
    {'id': '14:10', 'name': '14:10', 'hours': 14.0},
    {'id': '16:8', 'name': '16:8', 'hours': 16.0},
    {'id': '18:6', 'name': '18:6', 'hours': 18.0},
    {'id': '20:4', 'name': '20:4', 'hours': 20.0},
    {'id': 'OMAD', 'name': 'OMAD', 'hours': 23.0},
    {'id': '24h', 'name': '24h Fast', 'hours': 24.0},
    {'id': 'custom', 'name': 'Custom', 'hours': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    // Default to yesterday if no initial date provided
    _selectedDate = widget.initialDate ?? DateTime.now().subtract(const Duration(days: 1));
    // Ensure date is valid (in the past, within 30 days)
    _validateAndAdjustDate();
    // Set default protocol hours
    _updateHoursFromProtocol();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _validateAndAdjustDate() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    // If date is today or in the future, set to yesterday
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      _selectedDate = today.subtract(const Duration(days: 1));
    } else if (_selectedDate.isAfter(today)) {
      _selectedDate = today.subtract(const Duration(days: 1));
    }

    // If date is more than 30 days ago, set to 30 days ago
    if (_selectedDate.isBefore(thirtyDaysAgo)) {
      _selectedDate = thirtyDaysAgo;
    }
  }

  void _updateHoursFromProtocol() {
    final protocol = _protocols.firstWhere(
      (p) => p['id'] == _selectedProtocol,
      orElse: () => _protocols[2], // Default to 16:8
    );
    if (_selectedProtocol != 'custom') {
      _estimatedHours = (protocol['hours'] as num).toDouble();
    }
  }

  bool _isValidDate(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final thirtyDaysAgo = todayOnly.subtract(const Duration(days: 30));

    return dateOnly.isBefore(todayOnly) && !dateOnly.isBefore(thirtyDaysAgo);
  }

  Future<void> _selectDate() async {
    HapticService.light();
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: thirtyDaysAgo,
      lastDate: today.subtract(const Duration(days: 1)),
      helpText: 'Select date to mark as fasting day',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: isDark ? AppColors.accent : AppColorsLight.accent,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && _isValidDate(picked)) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    // Validate date
    if (!_isValidDate(_selectedDate)) {
      setState(() {
        _errorMessage = 'Please select a valid date within the last 30 days.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    HapticService.medium();

    try {
      final repository = ref.read(fastingRepositoryProvider);
      final result = await repository.markHistoricalFastingDay(
        userId: widget.userId,
        date: _selectedDate,
        protocol: _selectedProtocol == 'custom' ? null : _selectedProtocol,
        estimatedHours: _estimatedHours,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      HapticService.success();

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(result);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      HapticService.error();
      setState(() {
        _isSubmitting = false;
        if (e.toString().contains('already exists')) {
          _errorMessage = 'A fasting record already exists for this date.';
        } else if (e.toString().contains('past')) {
          _errorMessage = 'Cannot mark today or future dates.';
        } else if (e.toString().contains('30 days')) {
          _errorMessage = 'Cannot mark dates more than 30 days in the past.';
        } else {
          _errorMessage = 'Failed to mark fasting day. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mark Fasting Day',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Forgot to track a fast? Mark a past day as a fasting day.',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Protocol Selector
              Text(
                'Fasting Protocol',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _protocols.map((protocol) {
                  final isSelected = _selectedProtocol == protocol['id'];
                  return GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() {
                        _selectedProtocol = protocol['id'] as String;
                        _updateHoursFromProtocol();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.15)
                            : cardBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        protocol['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? accentColor : textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Custom Hours Slider (only show for custom protocol or to fine-tune)
              Text(
                'Fasting Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Hours',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${_estimatedHours.round()} hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _estimatedHours,
                      min: 12,
                      max: 48,
                      divisions: 36,
                      activeColor: accentColor,
                      inactiveColor: accentColor.withValues(alpha: 0.2),
                      onChanged: (value) {
                        HapticService.light();
                        setState(() {
                          _estimatedHours = value;
                          // If hours don't match a protocol, switch to custom
                          final matchingProtocol = _protocols.firstWhere(
                            (p) => (p['hours'] as num).toDouble() == value,
                            orElse: () => {'id': 'custom'},
                          );
                          _selectedProtocol = matchingProtocol['id'] as String;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('12h', style: TextStyle(color: textMuted, fontSize: 12)),
                        Text('48h', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes (optional)
              Text(
                'Notes (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'How did the fast go?',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: cardBorder.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                style: TextStyle(color: textPrimary),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.coral, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Mark as Fasting Day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Info text
              Center(
                child: Text(
                  'You can mark days within the last 30 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
