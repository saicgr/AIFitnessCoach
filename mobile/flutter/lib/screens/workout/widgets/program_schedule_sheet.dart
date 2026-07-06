import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/program_template.dart';
import '../../../data/repositories/program_template_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Opens the "Schedule this" sheet for a saved template (date, weeks,
/// alignment, per-training-day times, apply-staples). Shared between the
/// Your Programs hub's Custom/AI-Made template actions and anywhere else a
/// saved [ProgramTemplate] needs to be pushed onto the user's calendar.
void showScheduleTemplateSheet(BuildContext context, ProgramTemplate template) {
  if (template.id == null) return;
  HapticService.light();
  showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(child: _ScheduleSheet(template: template)),
  );
}

class _ScheduleSheet extends ConsumerStatefulWidget {
  final ProgramTemplate template;
  const _ScheduleSheet({required this.template});

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  late DateTime _startDate;
  int _weeks = 8;

  /// `start_today` or `calendar_weekday`.
  String _alignment = 'start_today';

  late bool _applyStaples;

  /// Per-training-day time. Keyed by `dayIndex`. Defaults to a single shared
  /// time the user can override per day.
  TimeOfDay _defaultTime = const TimeOfDay(hour: 7, minute: 0);
  final Map<int, TimeOfDay> _dayTimes = {};

  bool _scheduling = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _applyStaples = widget.template.applyStaples;
  }

  /// The template's non-rest days — one time picker per day.
  List<ProgramDay> get _trainingDays =>
      widget.template.days.where((d) => !d.effectivelyRest).toList();

  TimeOfDay _timeFor(ProgramDay d) => _dayTimes[d.dayIndex] ?? _defaultTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    // No inner drag handle / rounded background here — the GlassSheet
    // wrapper this sheet is opened inside already draws a single handle +
    // the rounded top surface (was double-stacked before). Same pattern
    // already established by _ProgramFilterSheet in program_library_screen.
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Schedule "${widget.template.name}"',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: [
                // Start date.
                _sectionLabel('Start date', textSecondary),
                const SizedBox(height: 6),
                _PickerTile(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDate(_startDate),
                  isDark: isDark,
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 16),

                // Weeks slider.
                _sectionLabel('Repeat for $_weeks weeks', textSecondary),
                Slider(
                  value: _weeks.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  activeColor: accent,
                  label: '$_weeks',
                  onChanged: (v) => setState(() => _weeks = v.round()),
                ),
                const SizedBox(height: 8),

                // Alignment toggle.
                _sectionLabel('Day alignment', textSecondary),
                const SizedBox(height: 6),
                _AlignmentToggle(
                  value: _alignment,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) => setState(() => _alignment = v),
                ),
                const SizedBox(height: 16),

                // Default time + per-day overrides.
                _sectionLabel('Workout times', textSecondary),
                const SizedBox(height: 6),
                _PickerTile(
                  icon: Icons.schedule_rounded,
                  label: 'All days: ${_defaultTime.format(context)}',
                  isDark: isDark,
                  onTap: _pickDefaultTime,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).templateListTapADayTo,
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
                const SizedBox(height: 8),
                for (final d in _trainingDays)
                  _DayTimeRow(
                    dayName: d.dayName,
                    time: _timeFor(d),
                    overridden: _dayTimes.containsKey(d.dayIndex),
                    isDark: isDark,
                    onTap: () => _pickDayTime(d),
                    onClear: _dayTimes.containsKey(d.dayIndex)
                        ? () => setState(() => _dayTimes.remove(d.dayIndex))
                        : null,
                  ),
                const SizedBox(height: 12),

                // Apply staples.
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _applyStaples,
                  activeThumbColor: accent,
                  onChanged: (v) => setState(() => _applyStaples = v),
                  title: Text(
                    AppLocalizations.of(context).templateListApplyMyStaples,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).templateListAddYourWarmUp,
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _scheduling ? null : _schedule,
                  icon: _scheduling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.event_available_rounded, size: 18),
                  label: Text(
                    _scheduling
                        ? AppLocalizations.of(context).templateListScheduling
                        : 'Add to my calendar',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: color,
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _startDate =
          DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickDefaultTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _defaultTime);
    if (picked != null && mounted) {
      setState(() => _defaultTime = picked);
    }
  }

  Future<void> _pickDayTime(ProgramDay day) async {
    final picked = await showTimePicker(
        context: context, initialTime: _timeFor(day));
    if (picked != null && mounted) {
      setState(() => _dayTimes[day.dayIndex] = picked);
    }
  }

  Future<void> _schedule() async {
    setState(() => _scheduling = true);
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Build the day_times map — every training day gets an explicit HH:MM so
    // the backend never has to guess (absent days would default to noon).
    final dayTimes = <String, String>{};
    for (final d in _trainingDays) {
      final t = _timeFor(d);
      dayTimes[d.dayIndex.toString()] =
          '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    }

    try {
      // Persist the apply-staples choice on the template first if it changed,
      // so the expander honors it.
      if (_applyStaples != widget.template.applyStaples &&
          widget.template.id != null) {
        await repo.updateTemplate(
          widget.template.id!,
          widget.template.copyWith(applyStaples: _applyStaples),
        );
      }
      final result = await repo.scheduleTemplate(
        widget.template.id!,
        startDate: _formatIso(_startDate),
        weeks: _weeks.clamp(1, 12),
        dayAlignment: _alignment,
        dayTimes: dayTimes,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.skippedExisting > 0
              ? '${result.workoutsCreated} workouts added '
                  '(${result.skippedExisting} already existed)'
              : '${result.workoutsCreated} workouts added to your calendar'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _scheduling = false);
      messenger.showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).templateListCouldNotSchedulePlease)),
      );
    }
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ===========================================================================
// Schedule-sheet sub-widgets.
// ===========================================================================

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlignmentToggle extends StatelessWidget {
  final String value;
  final Color accent;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _AlignmentToggle({
    required this.value,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _option(
          context,
          id: 'start_today',
          title: AppLocalizations.of(context).templateListStartDay1On,
          subtitle: AppLocalizations.of(context).templateListDay1OfThe,
        ),
        const SizedBox(height: 8),
        _option(
          context,
          id: 'calendar_weekday',
          title: AppLocalizations.of(context).templateListAlignToCalendarWeekdays,
          subtitle: AppLocalizations.of(context).templateListAMondayInThe,
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
  }) {
    final selected = value == id;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? accent : textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayTimeRow extends StatelessWidget {
  final String dayName;
  final TimeOfDay time;
  final bool overridden;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DayTimeRow({
    required this.dayName,
    required this.time,
    required this.overridden,
    required this.isDark,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 15, color: textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: overridden ? FontWeight.w800 : FontWeight.w500,
                color: overridden ? textPrimary : textSecondary,
              ),
            ),
            if (onClear != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: Icon(Icons.close_rounded, size: 15, color: textSecondary),
                onPressed: onClear,
              )
            else
              const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}
