import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Weekly fasting-schedule editor (Section G).
///
/// Seven day rows (Mon → Sun); each row is either a protocol or a rest /
/// eating day. Saves [FastingPreferences.weeklySchedule] via `savePreferences`.
class FastingScheduleEditorSheet extends ConsumerStatefulWidget {
  final FastingPreferences preferences;

  const FastingScheduleEditorSheet({super.key, required this.preferences});

  @override
  ConsumerState<FastingScheduleEditorSheet> createState() =>
      _FastingScheduleEditorSheetState();
}

class _FastingScheduleEditorSheetState
    extends ConsumerState<FastingScheduleEditorSheet> {
  /// Weekday key (0 = Mon … 6 = Sun) → [ScheduledFastDay]. A missing key is a
  /// rest / eating day.
  late Map<int, ScheduledFastDay> _schedule;
  bool _isSaving = false;

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Protocols offered per day — TRE protocols plus OMAD.
  static const _pickableProtocols = [
    FastingProtocol.twelve12,
    FastingProtocol.fourteen10,
    FastingProtocol.sixteen8,
    FastingProtocol.eighteen6,
    FastingProtocol.twenty4,
    FastingProtocol.omad,
  ];

  @override
  void initState() {
    super.initState();
    _schedule = {
      ...?widget.preferences.weeklySchedule,
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    setState(() => _isSaving = true);
    HapticService.medium();
    try {
      // Empty schedule → clear it so the screen falls back to defaultProtocol.
      final updated = _schedule.isEmpty
          ? widget.preferences.copyWith(clearWeeklySchedule: true)
          : widget.preferences.copyWith(weeklySchedule: _schedule);
      await ref.read(fastingProvider.notifier).savePreferences(
            userId: userId,
            preferences: updated,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weekly fasting schedule saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: ThemeColors.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _pickForDay(int weekday) {
    HapticService.light();
    final colors = ThemeColors.of(context);
    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekdayNames[weekday],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Rest / eating day option.
                  _OptionTile(
                    label: 'Rest / eating day',
                    icon: Icons.restaurant_rounded,
                    selected: !_schedule.containsKey(weekday),
                    colors: colors,
                    onTap: () {
                      setState(() => _schedule.remove(weekday));
                      Navigator.pop(sheetCtx);
                    },
                  ),
                  const SizedBox(height: 8),
                  ..._pickableProtocols.map((p) {
                    final current = _schedule[weekday];
                    final selected = current != null &&
                        current.protocol == p.name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OptionTile(
                        label: '${p.displayName}  ·  ${p.difficulty}',
                        icon: Icons.bolt_rounded,
                        selected: selected,
                        colors: colors,
                        onTap: () {
                          setState(() {
                            _schedule[weekday] =
                                ScheduledFastDay(protocol: p.name);
                          });
                          Navigator.pop(sheetCtx);
                        },
                      ),
                    );
                  }),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
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
                        Icon(Icons.calendar_month_rounded,
                            color: colors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Schedule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Pick a protocol for each day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    children: [
                      AnimationLimiter(
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 260),
                            childAnimationBuilder: (w) => SlideAnimation(
                              verticalOffset: 18,
                              child: FadeInAnimation(child: w),
                            ),
                            children: List.generate(7, (i) {
                              final entry = _schedule[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DayRow(
                                  dayName: _weekdayNames[i],
                                  entry: entry,
                                  colors: colors,
                                  onTap: () => _pickForDay(i),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.accentContrast,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                                  'Save Schedule',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom,
                      ),
                    ],
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

class _DayRow extends StatelessWidget {
  final String dayName;
  final ScheduledFastDay? entry;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _DayRow({
    required this.dayName,
    required this.entry,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = entry == null;
    final accent = colors.accent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRest
                ? colors.cardBorder
                : accent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                dayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Icon(
                    isRest
                        ? Icons.restaurant_rounded
                        : Icons.bolt_rounded,
                    size: 16,
                    color: isRest ? colors.textMuted : accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isRest
                          ? 'Rest / eating day'
                          : entry!.fastingProtocol.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isRest
                            ? colors.textMuted
                            : colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = colors.accent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : colors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? accent : colors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : colors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}
