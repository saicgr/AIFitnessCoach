import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../workout/widgets/per_day_focus_chips.dart';

/// Per-day AI workout customization sheet.
///
/// User picks a training day → assigns focus, duration, intensity for that
/// day. The AI plan generator reads these overrides at next plan-gen and
/// matches each weekday's workout accordingly. Days NOT in the user's
/// `workout_days` are visibly disabled with a one-line explainer.
///
/// Save → optimistic update on `currentUserProvider` via the auth notifier's
/// existing `updateUserProfile` path (preferences JSONB merge); sheet pops
/// in the same frame as the tap. Background persistence has rollback +
/// state.error wired by the auth notifier.
///
/// Pre-existing plumbing reused:
///   - `WorkoutDayOverride` model (lib/data/models/user.dart)
///   - `user.workoutDayOverrides` getter
///   - `authStateProvider.notifier.updateUserProfile` (optimistic)
///   - `DurationSlider` not reused — small inline slider here keeps the
///     sheet self-contained.
class PerDayWorkoutOverridesSheet extends ConsumerStatefulWidget {
  const PerDayWorkoutOverridesSheet({super.key});

  @override
  ConsumerState<PerDayWorkoutOverridesSheet> createState() =>
      _PerDayWorkoutOverridesSheetState();
}

class _PerDayWorkoutOverridesSheetState
    extends ConsumerState<PerDayWorkoutOverridesSheet> {
  static const _weekdayLabels = [
    (full: 'Monday', short: 'Mon', single: 'M'),
    (full: 'Tuesday', short: 'Tue', single: 'T'),
    (full: 'Wednesday', short: 'Wed', single: 'W'),
    (full: 'Thursday', short: 'Thu', single: 'T'),
    (full: 'Friday', short: 'Fri', single: 'F'),
    (full: 'Saturday', short: 'Sat', single: 'S'),
    (full: 'Sunday', short: 'Sun', single: 'S'),
  ];

  // Focus / intensity / duration catalogs now live in the shared
  // `per_day_focus_chips.dart` (kFocusOptions / kIntensityOptions /
  // kDurationOptions) so this sheet and the unified Edit Program editor render
  // identical controls.

  /// Currently-selected day for editing. Null = picker visible only.
  int? _selectedDay;

  /// Working copy of overrides as the user edits.
  late Map<int, WorkoutDayOverride> _draft;

  /// User's current training days (from preferences). Days outside this set
  /// are visibly disabled (orphan-protection — see plan §3.2 scenario F).
  late Set<int> _trainingDays;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _draft = Map<int, WorkoutDayOverride>.from(
      user?.workoutDayOverrides ?? const <int, WorkoutDayOverride>{},
    );
    _trainingDays = (user?.workoutDays ?? const <int>[]).toSet();
    // Auto-select the first training day so the editor isn't empty on open.
    if (_trainingDays.isNotEmpty) {
      _selectedDay = _trainingDays.first;
    }
  }

  void _selectDay(int day) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDay = day);
  }

  void _setFocus(int day, String focus) {
    setState(() {
      final existing = _draft[day];
      _draft[day] = existing == null
          ? WorkoutDayOverride(focus: focus)
          : existing.copyWith(focus: focus);
    });
  }

  void _setDuration(int day, int? duration) {
    setState(() {
      final existing = _draft[day];
      if (existing == null) {
        if (duration == null) return;
        _draft[day] = WorkoutDayOverride(focus: 'full_body', durationMin: duration);
      } else {
        _draft[day] = duration == null
            ? existing.copyWith(clearDurationMin: true)
            : existing.copyWith(durationMin: duration);
      }
    });
  }

  void _setIntensity(int day, String? intensity) {
    setState(() {
      final existing = _draft[day];
      if (existing == null) {
        if (intensity == null) return;
        _draft[day] = WorkoutDayOverride(focus: 'full_body', intensity: intensity);
      } else {
        _draft[day] = intensity == null
            ? existing.copyWith(clearIntensity: true)
            : existing.copyWith(intensity: intensity);
      }
    });
  }

  void _setGym(int day, String? gymProfileId) {
    setState(() {
      final existing = _draft[day];
      if (existing == null) {
        if (gymProfileId == null) return;
        _draft[day] =
            WorkoutDayOverride(focus: 'full_body', gymProfileId: gymProfileId);
      } else {
        _draft[day] = gymProfileId == null
            ? existing.copyWith(clearGymProfileId: true)
            : existing.copyWith(gymProfileId: gymProfileId);
      }
    });
  }

  void _setEquipment(int day, List<String>? equipment) {
    setState(() {
      final existing = _draft[day];
      if (existing == null) {
        if (equipment == null) return;
        _draft[day] =
            WorkoutDayOverride(focus: 'full_body', equipmentOverride: equipment);
      } else {
        _draft[day] = equipment == null
            ? existing.copyWith(clearEquipmentOverride: true)
            : existing.copyWith(equipmentOverride: equipment);
      }
    });
  }

  void _resetDay(int day) {
    setState(() => _draft.remove(day));
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Build the JSONB payload. Drop orphans (overrides on non-training days)
    // — actually KEEP them per plan §3.2 scenario F. Re-adding the day later
    // resurrects the customization automatically.
    final payload = <String, dynamic>{};
    _draft.forEach((day, override) {
      payload[day.toString()] = override.toJson();
    });

    // Merge into the existing preferences JSONB so we don't blow away
    // unrelated fields.
    Map<String, dynamic> currentPrefs = {};
    if (user.preferences != null && user.preferences!.isNotEmpty) {
      try {
        final decoded = jsonDecode(user.preferences!);
        if (decoded is Map) {
          currentPrefs = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    final mergedPrefs = Map<String, dynamic>.from(currentPrefs);
    mergedPrefs['workout_day_overrides'] = payload;

    final scaffold = ScaffoldMessenger.of(context);

    // Fire the optimistic update — auth notifier sets local state
    // synchronously + persists in background.
    unawaited(
      ref.read(authStateProvider.notifier).updateUserProfile({
        'preferences': mergedPrefs,
      }),
    );

    if (!mounted) return;
    Navigator.pop(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(_draft.isEmpty
            ? 'Per-day customization cleared — AI decides each day'
            : 'Per-day customization saved (${_draft.length} day${_draft.length == 1 ? '' : 's'})'),
        backgroundColor: AppColors.cyan,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final l10n = AppLocalizations.of(context);

    final selectedDay = _selectedDay;
    final currentOverride =
        selectedDay != null ? _draft[selectedDay] : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row + close ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Per-day customization',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 20, color: textMuted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a training day to assign focus, duration, and intensity. AI plan generator respects these per-day choices.',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),

            // ── Weekday picker ─────────────────────────────────────────
            Row(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  Expanded(
                    child: _DayButton(
                      label: _weekdayLabels[d].single,
                      isTrainingDay: _trainingDays.contains(d),
                      hasOverride: _draft.containsKey(d),
                      isSelected: _selectedDay == d,
                      accent: accent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _trainingDays.contains(d)
                          ? () => _selectDay(d)
                          : null,
                    ),
                  ),
                  if (d < 6) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Per-day editor or empty hint ──────────────────────────
            if (selectedDay == null)
              _emptyState(textMuted, l10n)
            else if (!_trainingDays.contains(selectedDay))
              _orphanState(selectedDay, textMuted, accent)
            else
              _editorPanel(
                selectedDay,
                currentOverride,
                accent,
                textPrimary,
                textMuted,
                isDark,
              ),

            const SizedBox(height: 20),

            // ── Save row ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save customization',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (_draft.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _draft.clear()),
                  child: Text(
                    'Clear all — let AI decide',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Color textMuted, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Select a training day above to customize it',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
      );

  Widget _orphanState(int day, Color textMuted, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: textMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textMuted.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_weekdayLabels[day].full} isn\'t in your workout days. Add it from Workout Days to activate customization.',
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorPanel(
    int day,
    WorkoutDayOverride? override,
    Color accent,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final gymProfiles =
        ref.watch(gymProfilesProvider).valueOrNull ?? const <GymProfile>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _weekdayLabels[day].full,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            if (override != null)
              TextButton.icon(
                onPressed: () => _resetDay(day),
                icon: Icon(Icons.restart_alt_rounded,
                    size: 16, color: textMuted),
                label: Text('Reset',
                    style: TextStyle(fontSize: 13, color: textMuted)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Shared control stack — identical to the unified Edit Program editor.
        // focus=null ⇒ "AI decide" (no override for this day); the AI-decide
        // chip clears the day so the Settings summary "AI decides" matches an
        // in-sheet control.
        PerDayControls(
          focus: override?.focus,
          durationMin: override?.durationMin,
          intensity: override?.intensity,
          gymProfileId: override?.gymProfileId,
          equipmentOverride: override?.equipmentOverride,
          accent: accent,
          textPrimary: textPrimary,
          textMuted: textMuted,
          gymProfiles: gymProfiles,
          onFocusChanged: (f) => _setFocus(day, f),
          onAiDecide: () => _resetDay(day),
          onDurationChanged: (d) => _setDuration(day, d),
          onIntensityChanged: (i) => _setIntensity(day, i),
          onGymChanged: (g) => _setGym(day, g),
          onEquipmentChanged: (eq) => _setEquipment(day, eq),
        ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.isTrainingDay,
    required this.hasOverride,
    required this.isSelected,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  final String label;
  final bool isTrainingDay;
  final bool hasOverride;
  final bool isSelected;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !isTrainingDay;
    final selectedColor = isSelected ? accent : Colors.transparent;
    final borderColor = isSelected
        ? accent
        : (isTrainingDay
            ? textMuted.withValues(alpha: 0.35)
            : textMuted.withValues(alpha: 0.15));
    final labelColor = disabled
        ? textMuted.withValues(alpha: 0.5)
        : (isSelected ? Colors.white : textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: selectedColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              if (hasOverride && isTrainingDay && !isSelected)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
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
