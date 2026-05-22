/// Dedicated quick "Log period start / end" sheet.
///
/// Writes directly to `cycle_periods` via the repository — a focused flow
/// separate from the broader daily check-in. A period without an end date is
/// "in progress"; the sheet detects the most-recent open period and offers to
/// close it, otherwise it starts a new one. Any write recomputes the
/// prediction.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/repositories/hormonal_health_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../cycle_visuals.dart';

/// Shows the period-logging sheet. Returns true when a period was written.
Future<bool?> showLogPeriodSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const _LogPeriodBody(),
          ),
        ),
      ),
    ),
  );
}

class _LogPeriodBody extends ConsumerStatefulWidget {
  const _LogPeriodBody();

  @override
  ConsumerState<_LogPeriodBody> createState() => _LogPeriodBodyState();
}

class _LogPeriodBodyState extends ConsumerState<_LogPeriodBody> {
  DateTime _startDate = CycleDates.dateOnly(DateTime.now());
  DateTime? _endDate;
  bool _saving = false;

  /// The most-recent period with no end date, if any.
  CyclePeriod? get _openPeriod {
    final periods = ref.read(cyclePeriodsProvider).value ?? const [];
    final open = periods.where((p) => p.endDate == null).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return open.isEmpty ? null : open.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final open = _openPeriod;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.water_drop_rounded,
                    color: CyclePhaseColors.menstrual),
                const SizedBox(width: 8),
                Text(
                  open != null ? 'Log period' : 'Log a new period',
                  style: TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              open != null
                  ? 'You have a period that started '
                      '${CycleDates.medium(open.startDate)} with no end '
                      'date. Close it, or start a new one.'
                  : 'Pick the first day of bleeding. Add an end date now '
                      'or later when your period finishes.',
              style: TextStyle(
                color: fg.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // When there's an open period, offer to close it directly.
            if (open != null) ...[
              _OpenPeriodCard(
                period: open,
                accent: accent,
                fg: fg,
                onClose: () => _closeOpenPeriod(open),
                saving: _saving,
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '— or start a new period —',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // New-period date pickers.
            _DateRow(
              label: 'Start date (Day 1)',
              date: _startDate,
              fg: fg,
              accent: accent,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 10),
            _DateRow(
              label: 'End date (optional)',
              date: _endDate,
              fg: fg,
              accent: accent,
              placeholder: 'Still in progress',
              onTap: () => _pickDate(isStart: false),
              onClear: _endDate == null
                  ? null
                  : () => setState(() => _endDate = null),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: _saving ? null : _saveNewPeriod,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save period'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    HapticService.selection();
    final now = DateTime.now();
    final initial = isStart
        ? _startDate
        : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = CycleDates.dateOnly(picked);
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      } else {
        final d = CycleDates.dateOnly(picked);
        _endDate = d.isBefore(_startDate) ? _startDate : d;
      }
    });
  }

  Future<void> _saveNewPeriod() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    HapticService.light();
    setState(() => _saving = true);
    try {
      final repo = ref.read(hormonalHealthRepositoryProvider);
      await repo.createPeriod(
        user.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      // Award cycle-logging XP + advance the logging-streak trophy.
      ref.read(xpProvider.notifier).markCycleLogged(entryKind: 'period');
      _afterWrite();
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _closeOpenPeriod(CyclePeriod open) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    HapticService.light();
    setState(() => _saving = true);
    try {
      final repo = ref.read(hormonalHealthRepositoryProvider);
      await repo.updatePeriod(
        user.id,
        open.id,
        endDate: CycleDates.dateOnly(DateTime.now()),
      );
      _afterWrite();
    } catch (e) {
      _onError(e);
    }
  }

  void _afterWrite() {
    ref.invalidate(cyclePeriodsProvider);
    ref.invalidate(cyclePredictionProvider);
    ref.invalidate(cycleAiInsightProvider);
    if (mounted) {
      HapticService.success();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period logged')),
      );
    }
  }

  void _onError(Object e) {
    if (!mounted) return;
    HapticService.error();
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save: $e')),
    );
  }
}

class _OpenPeriodCard extends StatelessWidget {
  final CyclePeriod period;
  final Color accent;
  final Color fg;
  final VoidCallback onClose;
  final bool saving;

  const _OpenPeriodCard({
    required this.period,
    required this.accent,
    required this.fg,
    required this.onClose,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyclePhaseColors.menstrual.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: CyclePhaseColors.menstrual.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period in progress',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Started ${CycleDates.medium(period.startDate)}',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CyclePhaseColors.menstrual,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: saving ? null : onClose,
            child: const Text('End today'),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color fg;
  final Color accent;
  final String? placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.date,
    required this.fg,
    required this.accent,
    required this.onTap,
    this.placeholder,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    date != null
                        ? CycleDates.withWeekday(date!)
                        : (placeholder ?? 'Pick a date'),
                    style: TextStyle(
                      color: date != null
                          ? fg
                          : fg.withValues(alpha: 0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: fg.withValues(alpha: 0.4)),
              ),
          ],
        ),
      ),
    );
  }
}
