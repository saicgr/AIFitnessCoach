import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Edit-past-fast sheet (Section I).
///
/// Lets the user correct the start/end times of a completed fast. Calls
/// `FastingNotifier.editFast` which recomputes duration/completion on the
/// backend and refreshes history + stats.
class FastingEditSheet extends ConsumerStatefulWidget {
  final FastingRecord record;

  const FastingEditSheet({super.key, required this.record});

  @override
  ConsumerState<FastingEditSheet> createState() => _FastingEditSheetState();
}

class _FastingEditSheetState extends ConsumerState<FastingEditSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start = widget.record.startTime.toLocal();
    // Completed fasts always have an endTime; fall back to now defensively.
    _end = (widget.record.endTime ?? DateTime.now()).toLocal();
  }

  Duration get _duration => _end.difference(_start);

  bool get _isValid => _end.isAfter(_start);

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _error = _isValid ? null : 'End time must be after the start time.';
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_isValid) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    HapticService.medium();
    final ok = await ref.read(fastingProvider.notifier).editFast(
          userId: userId,
          fastId: widget.record.id,
          startTime: _start,
          endTime: _end,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fast updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _error = 'Could not save changes. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final dateFmt = DateFormat('MMM d, yyyy · h:mm a');
    final h = _duration.inHours;
    final m = _duration.inMinutes.remainder(60);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.edit_calendar_rounded,
                        color: colors.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Fast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _TimeField(
                  label: 'Start',
                  value: dateFmt.format(_start),
                  icon: Icons.play_arrow_rounded,
                  colors: colors,
                  onTap: () => _pickDateTime(isStart: true),
                ),
                const SizedBox(height: 10),
                _TimeField(
                  label: 'End',
                  value: dateFmt.format(_end),
                  icon: Icons.flag_rounded,
                  colors: colors,
                  onTap: () => _pickDateTime(isStart: false),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 17, color: colors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        _isValid ? '${h}h ${m}m' : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 16, color: colors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSaving || !_isValid) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentContrast,
                      elevation: 0,
                      disabledBackgroundColor:
                          colors.accent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accentContrast,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accent),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
