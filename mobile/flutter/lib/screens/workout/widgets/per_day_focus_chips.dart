import 'package:flutter/material.dart';

import '../../../data/models/gym_profile.dart';

/// Shared per-day customization chip widgets + option catalogs.
///
/// Extracted from `per_day_workout_overrides_sheet.dart` so the unified Edit
/// Program editor (`edit_program_sheet.dart`) and the standalone per-day sheet
/// render IDENTICAL Focus / Duration / Intensity / Gym controls — one source,
/// no drift. The backend reads the resulting `WorkoutDayOverride` values; the
/// catalogs below map 1:1 to backend `workout_day_overrides.<int>` keys.

/// User-facing focus catalog. `value` maps to backend `focus`.
const List<({String value, String label, IconData icon})> kFocusOptions = [
  (value: 'upper_body', label: 'Upper', icon: Icons.fitness_center_rounded),
  (value: 'lower_body', label: 'Lower', icon: Icons.directions_walk_rounded),
  (value: 'full_body', label: 'Full', icon: Icons.accessibility_new_rounded),
  (value: 'push', label: 'Push', icon: Icons.arrow_upward_rounded),
  (value: 'pull', label: 'Pull', icon: Icons.arrow_downward_rounded),
  (value: 'legs', label: 'Legs', icon: Icons.directions_run_rounded),
  (value: 'core', label: 'Core', icon: Icons.center_focus_strong_rounded),
  (value: 'cardio', label: 'Cardio', icon: Icons.favorite_rounded),
  (value: 'mobility', label: 'Mobility', icon: Icons.self_improvement_rounded),
  (value: 'active_recovery', label: 'Recovery', icon: Icons.bedtime_rounded),
];

/// User-facing intensity catalog. `value` maps to backend `intensity`.
const List<({String value, String label})> kIntensityOptions = [
  (value: 'easy', label: 'Easy'),
  (value: 'moderate', label: 'Moderate'),
  (value: 'hard', label: 'Hard'),
  (value: 'hell', label: 'Hell 🔥'),
];

/// Duration options in minutes.
const List<int> kDurationOptions = [15, 20, 30, 45, 60, 75, 90];

/// A pill-style selectable chip used across per-day customization controls.
///
/// Identical to the chip previously private to the per-day sheet, lifted here
/// so both surfaces share one implementation.
class PerDayChip extends StatelessWidget {
  const PerDayChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 12 : 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : textMuted.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14, color: selected ? Colors.white : textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Focus / Duration / Intensity / Gym control stack for a single day.
///
/// Stateless and fully driven by [override] + callbacks so it can be embedded
/// in both the standalone per-day sheet and the unified Edit Program editor.
///
/// - "AI decide" Focus chip → [onAiDecide] (clears the whole day's override).
/// - Duration / Intensity → null toggles back to "AI picks".
/// - Gym selector renders whenever [showGymSelector] is true: an "Active gym"
///   chip ("Active gym" maps to `gymProfileId == null`), a chip per profile in
///   [gymProfiles], and — when [onAddGym] is set — an "Add gym" chip so a second
///   gym can be created inline (training different days at different gyms).
class PerDayControls extends StatelessWidget {
  const PerDayControls({
    super.key,
    required this.focus,
    required this.durationMin,
    required this.intensity,
    required this.gymProfileId,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.onFocusChanged,
    required this.onAiDecide,
    required this.onDurationChanged,
    required this.onIntensityChanged,
    required this.onGymChanged,
    this.onAddGym,
    this.gymProfiles = const [],
    this.showGymSelector = true,
  });

  /// Null = day is "AI decide" (no override). Non-null = explicit focus value.
  final String? focus;
  final int? durationMin;
  final String? intensity;
  final String? gymProfileId;

  final Color accent;
  final Color textPrimary;
  final Color textMuted;

  final ValueChanged<String> onFocusChanged;
  final VoidCallback onAiDecide;
  final ValueChanged<int?> onDurationChanged;
  final ValueChanged<String?> onIntensityChanged;
  final ValueChanged<String?> onGymChanged;

  /// Opens the "Add gym profile" flow. When null the "Add gym" chip is hidden.
  final VoidCallback? onAddGym;

  final List<GymProfile> gymProfiles;
  final bool showGymSelector;

  @override
  Widget build(BuildContext context) {
    final isAiDecide = focus == null;

    Widget sectionLabel(String text) => Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
            fontWeight: FontWeight.w600,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Focus (with explicit "AI decide") ──
        sectionLabel('Focus'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PerDayChip(
              label: 'AI decide',
              icon: Icons.auto_awesome_rounded,
              selected: isAiDecide,
              accent: accent,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: onAiDecide,
            ),
            for (final opt in kFocusOptions)
              PerDayChip(
                label: opt.label,
                icon: opt.icon,
                selected: focus == opt.value,
                accent: accent,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => onFocusChanged(opt.value),
              ),
          ],
        ),
        if (isAiDecide) ...[
          const SizedBox(height: 4),
          Text(
            'AI picks this day\'s focus, duration & intensity',
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        // The duration / intensity / gym controls only make sense once the
        // user has picked an explicit focus (i.e. opted OUT of AI-decide).
        if (!isAiDecide) ...[
          const SizedBox(height: 14),

          // ── Duration ──
          sectionLabel('Duration'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final mins in kDurationOptions)
                PerDayChip(
                  label: '$mins min',
                  icon: null,
                  selected: durationMin == mins,
                  accent: accent,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onTap: () =>
                      onDurationChanged(durationMin == mins ? null : mins),
                ),
            ],
          ),
          if (durationMin == null) ...[
            const SizedBox(height: 4),
            Text(
              'AI picks duration if not set',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // ── Intensity ──
          sectionLabel('Intensity'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final opt in kIntensityOptions)
                PerDayChip(
                  label: opt.label,
                  icon: null,
                  selected: intensity == opt.value,
                  accent: accent,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onTap: () => onIntensityChanged(
                    intensity == opt.value ? null : opt.value,
                  ),
                ),
            ],
          ),
          if (intensity == null) ...[
            const SizedBox(height: 4),
            Text(
              'AI picks intensity if not set',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // ── Gym selector ──
          // B1: always render when enabled — "Active gym" (gymProfileId=null,
          // inherit the active gym) + a chip per profile + an inline "Add gym"
          // chip. This makes training different days at different gyms
          // discoverable even with a single gym (the Add-gym chip is the path
          // to a second one). "Active gym" is hidden when there's nothing to
          // inherit from yet (zero profiles) — only the Add-gym chip shows.
          if (showGymSelector) ...[
            const SizedBox(height: 14),
            sectionLabel('Gym'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (gymProfiles.isNotEmpty)
                  PerDayChip(
                    label: 'Active gym',
                    icon: Icons.location_on_rounded,
                    selected: gymProfileId == null,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => onGymChanged(null),
                  ),
                for (final gym in gymProfiles)
                  PerDayChip(
                    label: gym.name,
                    icon: null,
                    selected: gymProfileId == gym.id,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => onGymChanged(gym.id),
                  ),
                if (onAddGym != null)
                  PerDayChip(
                    label: 'Add gym',
                    icon: Icons.add_rounded,
                    selected: false,
                    accent: accent,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: onAddGym!,
                  ),
              ],
            ),
            if (gymProfiles.length < 2) ...[
              const SizedBox(height: 4),
              Text(
                'Add a 2nd gym to train days at different gyms',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}
