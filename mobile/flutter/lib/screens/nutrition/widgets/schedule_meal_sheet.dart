import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';

/// One of the 11 cadence presets the meal long-press menu offers. Each
/// preset materializes into a `ScheduleSpec` when the user taps Confirm —
/// presets carry just enough info for the spec to be derived, the rest
/// (time, days when relevant) comes from the picker UI on the same sheet.
enum SchedulePreset {
  tomorrowOnly,
  daily,
  dailyUntil,
  weekdays,
  weeklyOnDay,
  justThisWeek,
  alternateThisWeek,
  alternateEveryWeek,
  customDays,
  everyNDays,
}

extension _PresetLabels on SchedulePreset {
  String get title {
    switch (this) {
      case SchedulePreset.tomorrowOnly:
        return 'Tomorrow only';
      case SchedulePreset.daily:
        return 'Every day';
      case SchedulePreset.dailyUntil:
        return 'Every day until…';
      case SchedulePreset.weekdays:
        return 'Weekdays (Mon–Fri)';
      case SchedulePreset.weeklyOnDay:
        return 'Weekly on…';
      case SchedulePreset.justThisWeek:
        return 'Just this week';
      case SchedulePreset.alternateThisWeek:
        return 'Alternate days, this week only';
      case SchedulePreset.alternateEveryWeek:
        return 'Alternate days, every week';
      case SchedulePreset.customDays:
        return 'Custom days + end date';
      case SchedulePreset.everyNDays:
        return 'Every N days';
    }
  }

  IconData get icon {
    switch (this) {
      case SchedulePreset.tomorrowOnly:
        return Icons.event_available;
      case SchedulePreset.daily:
        return Icons.repeat;
      case SchedulePreset.dailyUntil:
        return Icons.event_busy;
      case SchedulePreset.weekdays:
        return Icons.work_outline;
      case SchedulePreset.weeklyOnDay:
        return Icons.calendar_today;
      case SchedulePreset.justThisWeek:
        return Icons.date_range;
      case SchedulePreset.alternateThisWeek:
        return Icons.alarm;
      case SchedulePreset.alternateEveryWeek:
        return Icons.event_repeat;
      case SchedulePreset.customDays:
        return Icons.tune;
      case SchedulePreset.everyNDays:
        return Icons.timelapse;
    }
  }

  bool get needsDayPicker =>
      this == SchedulePreset.weeklyOnDay ||
      this == SchedulePreset.justThisWeek ||
      this == SchedulePreset.alternateThisWeek ||
      this == SchedulePreset.alternateEveryWeek ||
      this == SchedulePreset.customDays;

  bool get needsEndDate =>
      this == SchedulePreset.dailyUntil || this == SchedulePreset.customDays;

  bool get needsInterval => this == SchedulePreset.everyNDays;
}

/// Result returned to the caller when the user confirms. Caller dispatches
/// to the schedule_save_jobs_provider with this spec + a friendly label.
class ScheduleSheetResult {
  final ScheduleSpec spec;
  final String cadenceLabel;
  const ScheduleSheetResult({required this.spec, required this.cadenceLabel});
}

/// Show the cadence picker. Returns null if cancelled.
Future<ScheduleSheetResult?> showScheduleMealSheet({
  required BuildContext context,
  required FoodLog meal,
  required String timezone,
  SchedulePreset initialPreset = SchedulePreset.tomorrowOnly,
}) {
  return showGlassSheet<ScheduleSheetResult?>(
    context: context,
    builder: (ctx) => GlassSheet(
      child: _ScheduleMealSheet(
        meal: meal,
        timezone: timezone,
        initialPreset: initialPreset,
      ),
    ),
  );
}

class _ScheduleMealSheet extends StatefulWidget {
  final FoodLog meal;
  final String timezone;
  final SchedulePreset initialPreset;

  const _ScheduleMealSheet({
    required this.meal,
    required this.timezone,
    required this.initialPreset,
  });

  @override
  State<_ScheduleMealSheet> createState() => _ScheduleMealSheetState();
}

class _ScheduleMealSheetState extends State<_ScheduleMealSheet> {
  late SchedulePreset _preset;
  late TimeOfDay _time; // local clock time
  late Set<int> _selectedDays; // 0=Sun..6=Sat
  DateTime? _endDate;
  int _intervalDays = 3;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    final logged = widget.meal.loggedAt.toLocal();
    _time = TimeOfDay(hour: logged.hour, minute: logged.minute);
    final today = DateTime.now();
    final sunIdx = today.weekday % 7; // Mon=1..Sun=0 mapped to Sun=0..Sat=6
    _selectedDays = <int>{sunIdx};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final cardBorder = isDark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).scheduleMealScheduleThisMeal,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).scheduleMealPickACadenceWe,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 14),

            // Cadence presets — Wrap so it adapts to small screens.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SchedulePreset.values.map((p) {
                final selected = p == _preset;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.icon,
                        size: 14,
                        color: selected ? Colors.white : accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? Colors.white : textPrimary,
                        ),
                      ),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _preset = p),
                  selectedColor: accent,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: selected ? accent : cardBorder),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Day picker (Sun..Sat) — shown only when the preset needs it.
            if (_preset.needsDayPicker) ...[
              Text(
                AppLocalizations.of(context).scheduleMealDays,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final selected = _selectedDays.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedDays.remove(i);
                      } else {
                        _selectedDays.add(i);
                      }
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? accent : cardBorder,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: selected ? Colors.white : textPrimary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],

            // End date — Daily until / custom + end date.
            if (_preset.needsEndDate) ...[
              _Tile(
                label: AppLocalizations.of(context).vacationModeEndDate,
                value: _endDate == null
                    ? AppLocalizations.of(context).scheduleMealPickADate
                    : _formatDate(_endDate!),
                icon: Icons.event_busy,
                accent: accent,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? now.add(const Duration(days: 7)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
              const SizedBox(height: 8),
            ],

            // Interval stepper — Every N days.
            if (_preset.needsInterval) ...[
              _Tile(
                label: AppLocalizations.of(context).scheduleMealInterval,
                value: 'Every $_intervalDays days',
                icon: Icons.timelapse,
                accent: accent,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
                onTap: () => _showIntervalPicker(context, accent),
              ),
              const SizedBox(height: 8),
            ],

            // Time picker — used by every preset.
            _Tile(
              label: AppLocalizations.of(context).workoutShowcaseTime,
              value: _time.format(context),
              icon: Icons.schedule,
              accent: accent,
              textPrimary: textPrimary,
              textMuted: textMuted,
              cardBorder: cardBorder,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).scheduleWorkoutSchedule,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIntervalPicker(BuildContext context, Color accent) async {
    int v = _intervalDays;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 220,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: _intervalDays - 2,
                ),
                onSelectedItemChanged: (i) => v = i + 2, // 2..30
                children: [
                  for (int i = 2; i <= 30; i++) Center(child: Text('$i days')),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _intervalDays = v);
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context).commonDone,
                style: TextStyle(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    // Validate per-preset before constructing the spec.
    if (_preset.needsDayPicker && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).scheduleMealPickAtLeastOne,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_preset.needsEndDate && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).scheduleMealPickAnEndDate),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final spec = _buildSpec();
    final label = _buildLabel();
    Navigator.pop(
      context,
      ScheduleSheetResult(spec: spec, cadenceLabel: label),
    );
  }

  ScheduleSpec _buildSpec() {
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    switch (_preset) {
      case SchedulePreset.tomorrowOnly:
        // Compute tomorrow's weekday (Sun=0..Sat=6)
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final sunIdx = tomorrow.weekday % 7;
        return ScheduleSpec(
          scheduleKind: 'once',
          daysOfWeek: [sunIdx],
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
          occurrencesRemaining: 1,
        );
      case SchedulePreset.daily:
        return ScheduleSpec(
          scheduleKind: 'daily',
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
        );
      case SchedulePreset.dailyUntil:
        return ScheduleSpec(
          scheduleKind: 'daily',
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
          untilDate: _endDate,
        );
      case SchedulePreset.weekdays:
        return ScheduleSpec(
          scheduleKind: 'weekdays',
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
        );
      case SchedulePreset.weeklyOnDay:
      case SchedulePreset.alternateEveryWeek:
        return ScheduleSpec(
          scheduleKind: 'custom',
          daysOfWeek: _selectedDays.toList()..sort(),
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
        );
      case SchedulePreset.justThisWeek:
      case SchedulePreset.alternateThisWeek:
        return ScheduleSpec(
          scheduleKind: 'custom',
          daysOfWeek: _selectedDays.toList()..sort(),
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
          isTemporaryWeekOnly: true,
        );
      case SchedulePreset.customDays:
        return ScheduleSpec(
          scheduleKind: 'custom',
          daysOfWeek: _selectedDays.toList()..sort(),
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
          untilDate: _endDate,
        );
      case SchedulePreset.everyNDays:
        return ScheduleSpec(
          scheduleKind: 'custom',
          daysOfWeek: const [0, 1, 2, 3, 4, 5, 6],
          localTime: timeStr,
          timezone: widget.timezone,
          mealType: widget.meal.mealType,
          intervalDays: _intervalDays,
        );
    }
  }

  String _buildLabel() {
    final timeStr = _time.format(context);
    switch (_preset) {
      case SchedulePreset.tomorrowOnly:
        return 'Scheduled for tomorrow at $timeStr';
      case SchedulePreset.daily:
        return 'Scheduled daily at $timeStr';
      case SchedulePreset.dailyUntil:
        return 'Scheduled daily until ${_formatDate(_endDate!)}';
      case SchedulePreset.weekdays:
        return 'Scheduled weekdays at $timeStr';
      case SchedulePreset.weeklyOnDay:
      case SchedulePreset.alternateEveryWeek:
        return 'Scheduled on ${_dayLabels(_selectedDays)} at $timeStr';
      case SchedulePreset.justThisWeek:
      case SchedulePreset.alternateThisWeek:
        return 'Scheduled this week — ${_dayLabels(_selectedDays)}';
      case SchedulePreset.customDays:
        return 'Scheduled ${_dayLabels(_selectedDays)} until ${_formatDate(_endDate!)}';
      case SchedulePreset.everyNDays:
        return 'Scheduled every $_intervalDays days at $timeStr';
    }
  }

  String _dayLabels(Set<int> days) {
    const full = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final ordered = days.toList()..sort();
    return ordered.map((i) => full[i]).join('/');
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _Tile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color accent, textPrimary, textMuted, cardBorder;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
