import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/components/sheet_theme_colors.dart';

/// Shows the log weight bottom sheet
Future<WeightLogResult?> showLogWeightSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final parentTheme = Theme.of(context);

  return showGlassSheet<WeightLogResult>(
    context: context,
    builder: (sheetContext) => GlassSheet(
      child: Theme(
        data: parentTheme,
        child: const _LogWeightSheet(),
      ),
    ),
  );
}

/// Result of logging weight
class WeightLogResult {
  final double weightKg;
  final DateTime date;
  final String? notes;
  final bool wasFastingDay;
  final String? message;

  const WeightLogResult({
    required this.weightKg,
    required this.date,
    this.notes,
    this.wasFastingDay = false,
    this.message,
  });
}

/// Unit for weight display
enum WeightUnit {
  kg('kg', 1.0),
  lbs('lbs', 2.20462);

  final String label;
  final double conversionFromKg;

  const WeightUnit(this.label, this.conversionFromKg);

  double toKg(double value) => value / conversionFromKg;
  double fromKg(double kg) => kg * conversionFromKg;
}

class _LogWeightSheet extends ConsumerStatefulWidget {
  const _LogWeightSheet();

  @override
  ConsumerState<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<_LogWeightSheet>
    with SingleTickerProviderStateMixin {
  // Weight state
  double _weightKg = 70.0; // Default weight in kg
  WeightUnit _selectedUnit = WeightUnit.kg;

  // Date state
  DateTime _selectedDate = DateTime.now();

  // Notes state
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  // Submission state
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _errorMessage;

  // Feedback state (computed on submit)
  double? _previousWeightKg;
  String? _feedbackMessage;
  IconData? _feedbackIcon;
  Color? _feedbackColor;
  bool _isAnomaly = false;

  // TODO: Re-enable fasting day detection when fasting feature launches
  // bool? _isFastingDay;
  // bool _isCheckingFastingDay = false;

  // Animation controller for the circular weight input
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // TODO: Re-enable fasting day check when fasting feature launches
    // _checkFastingDay();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // TODO: Re-enable _checkFastingDay when fasting feature launches
  // Future<void> _checkFastingDay() async {
  //   final authState = ref.read(authStateProvider);
  //   final userId = authState.user?.id;
  //   if (userId == null) return;
  //
  //   setState(() => _isCheckingFastingDay = true);
  //
  //   try {
  //     final fastingRepo = ref.read(fastingRepositoryProvider);
  //     final history = await fastingRepo.getFastingHistory(
  //       userId: userId,
  //       limit: 10,
  //       fromDate: _selectedDate.subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
  //       toDate: _selectedDate.add(const Duration(days: 1)).toIso8601String().split('T')[0],
  //     );
  //
  //     final isFasting = history.any((record) {
  //       final startDate = record.startTime;
  //       final endDate = record.endTime ?? DateTime.now();
  //       return _selectedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
  //              _selectedDate.isBefore(endDate.add(const Duration(days: 1)));
  //     });
  //
  //     if (mounted) {
  //       setState(() {
  //         _isFastingDay = isFasting;
  //         _isCheckingFastingDay = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isFastingDay = null;
  //         _isCheckingFastingDay = false;
  //       });
  //     }
  //   }
  // }

  void _incrementWeight() {
    HapticService.increment();
    setState(() {
      final increment = _selectedUnit == WeightUnit.kg ? 0.1 : 0.2;
      _weightKg += _selectedUnit.toKg(increment);
      _weightKg = double.parse(_weightKg.toStringAsFixed(2));
    });
  }

  void _decrementWeight() {
    HapticService.increment();
    setState(() {
      final decrement = _selectedUnit == WeightUnit.kg ? 0.1 : 0.2;
      final newWeight = _weightKg - _selectedUnit.toKg(decrement);
      if (newWeight >= 20.0) {
        _weightKg = double.parse(newWeight.toStringAsFixed(2));
      }
    });
  }

  void _toggleUnit() {
    HapticService.selection();
    setState(() {
      _selectedUnit = _selectedUnit == WeightUnit.kg
          ? WeightUnit.lbs
          : WeightUnit.kg;
    });
  }

  Future<void> _selectDate() async {
    HapticService.light();

    final colors = context.sheetColors;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.cyan,
              onPrimary: Colors.white,
              surface: colors.elevated,
              onSurface: colors.textPrimary,
            ), dialogTheme: DialogThemeData(backgroundColor: colors.elevated),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // TODO: Re-enable when fasting feature launches
      // _checkFastingDay();
    }
  }

  void _computeFeedback() {
    // Get previous weight from measurements state
    final measState = ref.read(measurementsProvider);
    final prevEntry = measState.summary?.latestByType[MeasurementType.weight];
    _previousWeightKg = prevEntry?.value;

    if (_previousWeightKg == null) {
      _feedbackMessage = 'Great start! Keep logging to track your progress.';
      _feedbackIcon = Icons.flag_rounded;
      _feedbackColor = null; // will use accent
      return;
    }

    final changeKg = _weightKg - _previousWeightKg!;
    final changeAbs = changeKg.abs();
    final changeInUnit = _selectedUnit.fromKg(changeAbs);
    final changeStr = '${changeInUnit.toStringAsFixed(1)} ${_selectedUnit.label}';

    // Anomaly detection: >5kg in a single log is suspicious
    if (changeAbs > 5.0) {
      _isAnomaly = true;
      _feedbackMessage = changeKg > 0
          ? 'That\'s +$changeStr since last weigh-in. Double-check this is correct!'
          : 'That\'s -$changeStr since last weigh-in. Double-check this is correct!';
      _feedbackIcon = Icons.warning_amber_rounded;
      _feedbackColor = const Color(0xFFF59E0B); // amber
      return;
    }

    // Get user goals to provide context-aware feedback
    final authState = ref.read(authStateProvider);
    final goals = authState.user?.goalsList ?? [];
    final wantsToLose = goals.any((g) => g.contains('lose'));
    final wantsToGain = goals.any((g) => g.contains('muscle') || g.contains('gain'));

    if (changeAbs < 0.2) {
      // Essentially stable
      _feedbackMessage = 'Holding steady. Consistency is key!';
      _feedbackIcon = Icons.horizontal_rule_rounded;
      _feedbackColor = null;
    } else if (changeKg < 0) {
      // Weight went down
      if (wantsToLose) {
        _feedbackMessage = 'Down $changeStr — you\'re on track!';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFF10B981); // green
      } else if (wantsToGain) {
        _feedbackMessage = 'Down $changeStr — make sure you\'re eating enough to support your gains.';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFFF59E0B); // amber
      } else {
        _feedbackMessage = 'Down $changeStr — keep it up!';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFF10B981);
      }
    } else {
      // Weight went up
      if (wantsToGain) {
        _feedbackMessage = 'Up $changeStr — gains are coming!';
        _feedbackIcon = Icons.trending_up_rounded;
        _feedbackColor = const Color(0xFF10B981);
      } else if (wantsToLose) {
        if (changeAbs > 2.0) {
          _feedbackMessage = 'Up $changeStr — stay focused, review your meals and activity this week.';
          _feedbackIcon = Icons.trending_up_rounded;
          _feedbackColor = const Color(0xFFEF4444); // red
        } else {
          _feedbackMessage = 'Up $changeStr — small fluctuations are normal. Stay consistent!';
          _feedbackIcon = Icons.trending_up_rounded;
          _feedbackColor = const Color(0xFFF59E0B);
        }
      } else {
        _feedbackMessage = 'Up $changeStr — weight fluctuations are normal.';
        _feedbackIcon = Icons.trending_up_rounded;
        _feedbackColor = null;
      }
    }
  }

  Future<void> _submitWeight() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to log your weight';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    HapticService.medium();

    try {
      // Compute feedback BEFORE recording (so we compare against previous weight)
      _computeFeedback();

      // Log weight through the consolidated measurements endpoint
      await ref.read(measurementsProvider.notifier).recordMeasurement(
        userId: userId,
        type: MeasurementType.weight,
        value: _weightKg,
        unit: 'kg',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Mark weight logged for daily XP goals (only if logging for today)
      final today = DateTime.now();
      if (_selectedDate.year == today.year &&
          _selectedDate.month == today.month &&
          _selectedDate.day == today.day) {
        ref.read(xpProvider.notifier).markWeightLogged();
      }

      // Refresh measurements history so new weight appears when user views history
      ref.invalidate(measurementsProvider);

      if (mounted) {
        HapticService.success();
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to log weight. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSuccess
            ? _buildSuccessState(colors)
            : _buildInputState(colors, bottomPadding),
      ),
    );
  }

  Widget _buildSuccessState(SheetColors colors) {
    final feedbackColor = _feedbackColor ?? colors.cyan;
    final changeKg = _previousWeightKg != null ? _weightKg - _previousWeightKg! : null;
    final changeInUnit = changeKg != null ? _selectedUnit.fromKg(changeKg.abs()) : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.success,
                size: 64,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Weight Logged!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),

            // Weight value with change badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedUnit.fromKg(_weightKg).toStringAsFixed(1)} ${_selectedUnit.label}',
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.textSecondary,
                  ),
                ),
                if (changeKg != null && changeInUnit != null && changeInUnit >= 0.1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: feedbackColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${changeKg > 0 ? '+' : '-'}${changeInUnit.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: feedbackColor,
                      ),
                    ),
                  ),
                ],
              ],
            )
                .animate()
                .fadeIn(delay: 300.ms),
            const SizedBox(height: 20),

            // Feedback message
            if (_feedbackMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: feedbackColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: feedbackColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_feedbackIcon ?? Icons.info_outline, color: feedbackColor, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.15, end: 0),

            // Anomaly warning
            if (_isAnomaly)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'If this was a mistake, log again with the correct weight.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(WeightLogResult(
                    weightKg: _weightKg,
                    date: _selectedDate,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    message: 'Weight logged successfully',
                  )),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/measurements/weight');
                  },
                  icon: const Icon(Icons.show_chart_rounded, size: 18),
                  label: const Text('Weight Chart'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInputState(SheetColors colors, double bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colors),
          const SizedBox(height: 12),
          // Date row (top-left) + Unit toggle (right)
          _buildDateAndUnitRow(colors),
          const SizedBox(height: 16),
          _buildWeightInput(colors),
          const SizedBox(height: 16),
          // TODO: Re-enable fasting day indicator when fasting feature launches
          // _buildFastingDayIndicator(colors),
          _buildNotesInput(colors),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(colors),
          ],
          const SizedBox(height: 16),
          _buildSubmitButton(colors),
          SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.monitor_weight_outlined, color: colors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log Weight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/measurements/weight');
            },
            icon: Icon(Icons.history_rounded, color: colors.textSecondary, size: 22),
            tooltip: 'Weight History',
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildDateAndUnitRow(SheetColors colors) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final formattedDate = isToday
        ? 'Today'
        : DateFormat('EEE, MMM d').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Date selector (left)
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.glassSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (!isToday) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        setState(() => _selectedDate = DateTime.now());
                        // TODO: Re-enable when fasting feature launches
                        // _checkFastingDay();
                      },
                      child: Icon(Icons.close, color: colors.textMuted, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: -0.1, end: 0),
          const Spacer(),
          // Unit toggle (right)
          Container(
            decoration: BoxDecoration(
              color: colors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: WeightUnit.values.map((unit) {
                final isSelected = unit == _selectedUnit;
                return GestureDetector(
                  onTap: _toggleUnit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.cyan.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unit.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colors.cyan : colors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput(SheetColors colors) {
    final displayWeight = _selectedUnit.fromKg(_weightKg);

    return Column(
      children: [
        // Smaller circular weight input
        GestureDetector(
          onTap: () => _showDirectInput(colors),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value * 0.015 + 1.0;
              return Transform.scale(
                scale: pulseValue,
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.cyan.withValues(alpha: 0.2),
                    colors.cyan.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: colors.cyan.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.cyan.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayWeight.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedUnit.label,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to edit',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(),
        const SizedBox(height: 16),

        // +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WeightAdjustButton(
              icon: Icons.remove,
              onTap: _decrementWeight,
              onLongPress: () {
                HapticService.medium();
                for (int i = 0; i < 5; i++) {
                  Future.delayed(Duration(milliseconds: i * 50), _decrementWeight);
                }
              },
              colors: colors,
            ),
            const SizedBox(width: 48),
            _WeightAdjustButton(
              icon: Icons.add,
              onTap: _incrementWeight,
              onLongPress: () {
                HapticService.medium();
                for (int i = 0; i < 5; i++) {
                  Future.delayed(Duration(milliseconds: i * 50), _incrementWeight);
                }
              },
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  void _showDirectInput(SheetColors colors) {
    HapticService.light();
    final controller = TextEditingController(
      text: _selectedUnit.fromKg(_weightKg).toStringAsFixed(1),
    );

    // Validation range based on unit
    final minValue = _selectedUnit == WeightUnit.kg ? 20.0 : 44.0;
    final maxValue = _selectedUnit == WeightUnit.kg ? 500.0 : 1100.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Weight',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                suffixText: _selectedUnit.label,
                suffixStyle: TextStyle(color: colors.textMuted, fontSize: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cyan, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}\.?\d{0,1}')),
              ],
              onSubmitted: (value) {
                final parsedValue = double.tryParse(value);
                if (parsedValue != null && parsedValue >= minValue && parsedValue <= maxValue) {
                  setState(() {
                    _weightKg = _selectedUnit.toKg(parsedValue);
                  });
                  HapticService.success();
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Valid range: ${minValue.toInt()}-${maxValue.toInt()} ${_selectedUnit.label}',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= minValue && value <= maxValue) {
                setState(() {
                  _weightKg = _selectedUnit.toKg(value);
                });
                HapticService.success();
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: colors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // TODO: Re-enable _buildFastingDayIndicator when fasting feature launches
  // Widget _buildFastingDayIndicator(SheetColors colors) { ... }

  Widget _buildNotesInput(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          maxLines: 1,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add a note (optional)',
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5), fontSize: 13),
            counterText: '',
            prefixIcon: Icon(Icons.note_outlined, color: colors.textMuted.withValues(alpha: 0.4), size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms);
  }

  Widget _buildErrorMessage(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn()
        .shake(hz: 3, duration: 400.ms);
  }

  Widget _buildSubmitButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitWeight,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.cyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.cyan.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Log Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 250.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

/// Button for adjusting weight with +/-
class _WeightAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final SheetColors colors;

  const _WeightAdjustButton({
    required this.icon,
    required this.onTap,
    this.onLongPress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: colors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}
