import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/providers/variation_provider.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../../home/widgets/edit_gym_profile_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Unified card displaying equipment and workout preferences with edit capability.
/// Equipment and Environment are pulled from the active gym profile.
class TrainingSetupCard extends ConsumerWidget {
  final User? user;
  final VoidCallback? onCustomEquipment;

  const TrainingSetupCard({
    super.key,
    required this.user,
    this.onCustomEquipment,
  });

  /// Format equipment name for display
  String _formatEquipmentName(String equipment) {
    const displayNames = {
      'full_gym': 'Full Gym Access',
      'home_gym': 'Home Gym',
      'commercial_gym': 'Commercial Gym',
      'bodyweight': 'Bodyweight',
      'dumbbells': 'Dumbbells',
      'barbell': 'Barbell',
      'kettlebell': 'Kettlebell',
      'kettlebells': 'Kettlebells',
      'resistance_bands': 'Resistance Bands',
      'pull_up_bar': 'Pull-up Bar',
      'cable_machine': 'Cable Machine',
      'smith_machine': 'Smith Machine',
      'leg_press': 'Leg Press',
      'bench': 'Bench',
      'bench_press': 'Bench Press',
      'adjustable_bench': 'Adjustable Bench',
      'squat_rack': 'Squat Rack',
      'power_rack': 'Power Rack',
      'dip_station': 'Dip Station',
      'ez_curl_bar': 'EZ Curl Bar',
      'trap_bar': 'Trap Bar',
      'medicine_ball': 'Medicine Ball',
      'slam_ball': 'Slam Ball',
      'exercise_ball': 'Exercise Ball',
      'bosu_ball': 'BOSU Ball',
      'foam_roller': 'Foam Roller',
      'ab_wheel': 'Ab Wheel',
      'jump_rope': 'Jump Rope',
      'yoga_mat': 'Yoga Mat',
      'landmine': 'Landmine',
      'trx': 'TRX / Suspension Trainer',
      'suspension_trainer': 'Suspension Trainer',
      'battle_ropes': 'Battle Ropes',
      'gymnastic_rings': 'Gymnastic Rings',
      'sandbag': 'Sandbag',
      'weight_plates': 'Weight Plates',
      'lat_pulldown': 'Lat Pulldown',
      'seated_row_machine': 'Seated Row Machine',
      'leg_curl_machine': 'Leg Curl Machine',
      'leg_extension_machine': 'Leg Extension Machine',
      'chest_fly_machine': 'Chest Fly Machine',
      'shoulder_press_machine': 'Shoulder Press Machine',
      'hack_squat': 'Hack Squat',
      'calf_raise_machine': 'Calf Raise Machine',
    };
    if (displayNames.containsKey(equipment)) return displayNames[equipment]!;
    return equipment
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Format workout day indices into "Mon, Wed, Fri" using 0=Mon..6=Sun
  /// to match the User model convention. Used when reading from the
  /// active gym profile (the new source of truth for this field).
  String _formatWorkoutDays(List<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = [...days]..sort();
    return sorted
        .where((d) => d >= 0 && d < 7)
        .map((d) => names[d])
        .join(', ');
  }

  /// Title-case a single token (e.g. "upper_body" → "Upper body").
  /// Used for focus-area display from the gym profile, which stores
  /// snake_case values.
  String _titleCase(String s) {
    if (s.isEmpty) return s;
    final spaced = s.replaceAll('_', ' ');
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  /// Get simplified equipment display text
  String _getEquipmentDisplay(List<String> equipment) {
    if (equipment.isEmpty) return 'Not set';

    // If user has full_gym, just show that
    if (equipment.contains('full_gym')) {
      return 'Full Gym Access';
    }

    // If user has home_gym, show that
    if (equipment.contains('home_gym')) {
      return 'Home Gym';
    }

    // Otherwise show count or list
    if (equipment.length <= 3) {
      return equipment.map(_formatEquipmentName).join(', ');
    }
    return '${equipment.length} items';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    // Get the active gym profile for equipment and environment.
    // After this edit the gym profile is also the source of truth for
    // workout days, focus areas, and training split — the users table
    // lagged behind My Gym edits because those fields live on
    // gym_profiles, not users.
    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final equipment = activeGymProfile?.equipment ?? user?.equipmentList ?? [];
    final environment = activeGymProfile?.environmentDisplayName ?? user?.workoutEnvironmentDisplay ?? 'Not set';
    final gymWorkoutDays = activeGymProfile?.workoutDays ?? const <int>[];
    final workoutDaysValue = gymWorkoutDays.isNotEmpty
        ? _formatWorkoutDays(gymWorkoutDays)
        : (user?.workoutDaysFormatted ?? 'Not set');
    final focusAreasValue = (activeGymProfile?.focusAreas.isNotEmpty ?? false)
        ? activeGymProfile!.focusAreas.map(_titleCase).join(', ')
        : (user?.focusAreasDisplay ?? 'Full body');

    // Signature-v2: matte hairline surface (no boxed Material elevation),
    // Barlow kicker header, hairline-ruled rows with framed muted glyphs.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — Barlow uppercase kicker + ghost edit affordance.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).trainingSetupCardTrainingSetup,
                style: ZType.lbl(12, color: textMuted, letterSpacing: 1.8),
              ),
              if (activeGymProfile != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showGlassSheet(
                      context: context,
                      builder: (context) => EditGymProfileSheet(
                        profile: activeGymProfile,
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context).commonEdit.toUpperCase(),
                          style: ZType.lbl(11, color: accent, letterSpacing: 1.4),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_rounded, color: accent, size: 14),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Equipment row
          _SetupRow(
            icon: Icons.fitness_center,
            label: AppLocalizations.of(context).trainingSetupCardEquipment,
            value: _getEquipmentDisplay(equipment),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Environment row (from gym profile)
          _SetupRow(
            icon: Icons.location_on_outlined,
            label: AppLocalizations.of(context).workoutPreferencesCardEnvironment,
            value: environment,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Experience row
          _SetupRow(
            icon: Icons.timeline,
            label: AppLocalizations.of(context).workoutPreferencesCardExperience,
            value: user?.trainingExperienceDisplay ?? AppLocalizations.of(context).workoutPreferencesCardNotSet,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Focus Areas row (reads from active gym profile first so
          // My Gym edits surface here without a reload)
          _SetupRow(
            icon: Icons.center_focus_strong,
            label: AppLocalizations.of(context).workoutPreferencesCardFocusAreas,
            value: focusAreasValue,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Workout Days row (active gym profile is source of truth)
          _SetupRow(
            icon: Icons.calendar_today_outlined,
            label: AppLocalizations.of(context).workoutSettingsWorkoutDays,
            value: workoutDaysValue,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Training Split row
          _TrainingSplitRow(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Weekly Variety row
          _VarietyRow(
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          // Custom Equipment link
          if (onCustomEquipment != null)
            _TappableRow(
              icon: Icons.build_outlined,
              label: AppLocalizations.of(context).trainingSetupCardMyCustomEquipment,
              subtitle: AppLocalizations.of(context).trainingSetupCardAddEquipmentNotIn,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
              onTap: onCustomEquipment!,
            ),
        ],
      ),
    );
  }
}

/// A single hairline-ruled row in the setup card. Framed muted glyph (the
/// `.st-gl` grammar), neutral label, value right-aligned. No per-row accent
/// tint — the redesign drops the rainbow icons.
class _SetupRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _SetupRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cardBorder)),
      ),
      // crossAxisAlignment.start so a 2-line value (long German/Telugu
      // translation) tops out flush with the label glyph instead of pushing
      // the glyph downward as the row grows.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FramedGlyph(icon: icon, color: textMuted, cardBorder: cardBorder),
          const SizedBox(width: 12),
          // Label gets a smaller flex weight so the value (the user-customised
          // content) wins the layout when both compete.
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The signature framed hairline glyph box (`.st-gl`) — a muted icon inside a
/// 30px hairline-bordered rounded square. Shared by the setup rows.
class _FramedGlyph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color cardBorder;

  const _FramedGlyph({
    required this.icon,
    required this.color,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// A tappable hairline-ruled row with a framed glyph, label, subtitle, chevron.
class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cardBorder)),
        ),
        child: Row(
          children: [
            _FramedGlyph(icon: icon, color: textMuted, cardBorder: cardBorder),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}

/// Displays the training split from training preferences provider.
class _TrainingSplitRow extends ConsumerWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _TrainingSplitRow({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  static const _splitDisplayNames = {
    'full_body': 'Full Body',
    'upper_lower': 'Upper/Lower',
    'push_pull_legs': 'Push/Pull/Legs',
    'body_part': 'Body Part Split',
    'phul': 'PHUL',
    'arnold_split': 'Arnold Split',
    'hyrox': 'HYROX',
    'dont_know': 'AI Decides',
    'ai_decide': 'AI Decides',
    'ai decide': 'AI Decides',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active gym profile is source of truth for training_split — the
    // legacy trainingPreferencesProvider held a separate cached value that
    // lagged behind My Gym edits. Falling back to that provider only when
    // the gym profile hasn't loaded yet.
    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final trainingPrefs = ref.watch(trainingPreferencesProvider);
    final splitValue = activeGymProfile?.trainingSplit ?? trainingPrefs.trainingSplit;
    final displayName = _splitDisplayNames[splitValue] ?? splitValue.replaceAll('_', ' ');

    return _SetupRow(
      icon: Icons.view_week_outlined,
      label: AppLocalizations.of(context).workoutSettingsTrainingSplit,
      value: displayName,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      cardBorder: cardBorder,
    );
  }
}

/// Displays the weekly variety level with tap-to-edit.
class _VarietyRow extends ConsumerWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _VarietyRow({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  String _varietyLabel(int percentage) {
    if (percentage <= 25) return 'Low ($percentage%)';
    if (percentage <= 50) return 'Medium ($percentage%)';
    return 'High ($percentage%)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variationState = ref.watch(variationProvider);
    final percentage = variationState.percentage;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showVariationSlider(context, ref, percentage);
      },
      behavior: HitTestBehavior.opaque,
      child: _SetupRow(
        icon: Icons.shuffle_rounded,
        label: AppLocalizations.of(context).workoutSettingsWeeklyVariety,
        value: _varietyLabel(percentage),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        cardBorder: cardBorder,
      ),
    );
  }

  void _showVariationSlider(BuildContext context, WidgetRef ref, int currentPercentage) {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassSheet(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).workoutSettingsWeeklyVariety,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).trainingSetupCardHowMuchExerciseVariety,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('Low', 25, currentPercentage, context, ref),
                  _buildChip('Medium', 50, currentPercentage, context, ref),
                  _buildChip('High', 75, currentPercentage, context, ref),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() {
        try {
          container.read(floatingNavBarVisibleProvider.notifier).state = true;
        } catch (_) {}
      });
    });
  }

  Widget _buildChip(String label, int value, int current, BuildContext context, WidgetRef ref) {
    final presets = [25, 50, 75];
    final closestPreset = presets.reduce((a, b) => (a - current).abs() < (b - current).abs() ? a : b);
    final isSelected = value == closestPreset;
    return ChoiceChip(
      label: Text('$label ($value%)'),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        ref.read(variationProvider.notifier).setVariation(value);
        Navigator.pop(context);
      },
      selectedColor: AppColors.orange.withValues(alpha: 0.2),
      checkmarkColor: AppColors.orange,
    );
  }
}
