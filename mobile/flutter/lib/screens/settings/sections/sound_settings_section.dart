/// Sound settings section for customizing workout sounds.
///
/// This addresses user feedback: "countdown timer sux plus cheesy applause smh.
/// sounds should be customizable."
///
/// Sound Categories:
/// - Countdown (3, 2, 1): beep, chime, voice, tick, none
/// - Rest Timer End: beep, chime, gong, none
/// - Exercise Complete: chime, bell, ding, pop, whoosh, none
/// - Workout Complete: chime, bell, success, fanfare, none (NO APPLAUSE!)
///
/// UI: Each sound category shows ONLY its switch + a compact "Sound: Beep ▸"
/// sub-row when enabled. Tapping opens a bottom sheet with the full list of
/// options (beep / chime / voice / upload / none) — keeps the parent screen
/// from spilling 5+ choice chips per category. Long-press inside the sheet
/// to preview before committing.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/sound_preferences_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/sound_service.dart';
import '../widgets/setting_tile.dart';
import '../widgets/section_header.dart';

const List<String> countdownSoundTypes = [
  'beep',
  'chime',
  'voice',
  'tick',
  'custom',
  'none',
];

const List<String> restTimerSoundTypes = ['beep', 'chime', 'gong', 'custom', 'none'];

const List<String> exerciseCompletionSoundTypes = [
  'chime',
  'bell',
  'ding',
  'pop',
  'whoosh',
  'custom',
  'none',
];

const List<String> workoutCompletionSoundTypes = [
  'chime',
  'bell',
  'success',
  'fanfare',
  'custom',
  'none',
];

class SoundSettingsSection extends ConsumerWidget {
  const SoundSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(soundPreferencesProvider);
    final notifier = ref.read(soundPreferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ThemeColors.of(context).accent;
    final activeTrack = accent.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Sound Effects',
          subtitle: 'Customize workout sounds',
        ),
        Material(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _SoundCategoryRow(
                icon: Icons.timer_outlined,
                iconColor: AppColors.cyan,
                title: 'Countdown Sounds',
                subtitle: 'Play sounds during countdown (3, 2, 1)',
                enabled: prefs.countdownSoundEnabled,
                onEnabledChanged: notifier.setCountdownEnabled,
                currentSound: prefs.countdownSoundType,
                options: countdownSoundTypes,
                category: 'countdown',
                onChanged: notifier.setCountdownType,
                onPreview: (t) => notifier.playPreview('countdown', t),
                accent: accent,
                activeTrack: activeTrack,
              ),
              Divider(height: 1, color: cardBorder),
              _SoundCategoryRow(
                icon: Icons.hourglass_empty,
                iconColor: AppColors.warning,
                title: 'Rest Timer End',
                subtitle: 'Play sound when rest period ends',
                enabled: prefs.restTimerSoundEnabled,
                onEnabledChanged: notifier.setRestTimerEnabled,
                currentSound: prefs.restTimerSoundType,
                options: restTimerSoundTypes,
                category: 'rest_end',
                onChanged: notifier.setRestTimerType,
                onPreview: (t) => notifier.playPreview('rest_end', t),
                accent: accent,
                activeTrack: activeTrack,
              ),
              Divider(height: 1, color: cardBorder),
              _SoundCategoryRow(
                icon: Icons.fitness_center,
                iconColor: AppColors.textPrimary,
                title: 'Exercise Completion',
                subtitle: 'Play sound when all sets of exercise done',
                enabled: prefs.exerciseCompletionSoundEnabled,
                onEnabledChanged: notifier.setExerciseCompletionEnabled,
                currentSound: prefs.exerciseCompletionSoundType,
                options: exerciseCompletionSoundTypes,
                category: 'exercise_complete',
                onChanged: notifier.setExerciseCompletionType,
                onPreview: (t) => notifier.playPreview('exercise_complete', t),
                accent: accent,
                activeTrack: activeTrack,
              ),
              Divider(height: 1, color: cardBorder),
              _SoundCategoryRow(
                icon: Icons.celebration_outlined,
                iconColor: AppColors.success,
                title: 'Workout Completion',
                subtitle: 'Play sound when entire workout ends',
                enabled: prefs.workoutCompletionSoundEnabled,
                onEnabledChanged: notifier.setWorkoutCompletionEnabled,
                currentSound: prefs.workoutCompletionSoundType,
                options: workoutCompletionSoundTypes,
                category: 'workout_complete',
                onChanged: notifier.setWorkoutCompletionType,
                onPreview: (t) => notifier.playPreview('workout_complete', t),
                accent: accent,
                activeTrack: activeTrack,
              ),
              Divider(height: 1, color: cardBorder),
              SettingTile(
                icon: Icons.volume_up,
                iconColor: AppColors.textSecondary,
                title: 'Sound Volume',
                subtitle: '${(prefs.soundEffectsVolume * 100).round()}%',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: prefs.soundEffectsVolume,
                    onChanged: notifier.setVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row per sound category. Shows: icon · name · subtitle · enable Switch.
/// When enabled, slides in a compact tap-to-edit row with the current sound
/// name + chevron — opens a bottom sheet for the choice list. No more
/// 6-chip wrap on the parent screen.
class _SoundCategoryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final String currentSound;
  final List<String> options;
  final String category;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPreview;
  final Color accent;
  final Color activeTrack;

  const _SoundCategoryRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabledChanged,
    required this.currentSound,
    required this.options,
    required this.category,
    required this.onChanged,
    required this.onPreview,
    required this.accent,
    required this.activeTrack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingTile(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          trailing: Switch(
            value: enabled,
            onChanged: onEnabledChanged,
            activeThumbColor: accent,
            activeTrackColor: activeTrack,
          ),
        ),
        if (enabled) ...[
          Divider(height: 1, color: cardBorder, indent: 50),
          InkWell(
            onTap: () => _openPicker(context, isDark),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.music_note_outlined,
                      size: 16, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Sound',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const Spacer(),
                  Text(
                    _displayName(currentSound, category),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: textMuted),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPicker(BuildContext context, bool isDark) async {
    HapticFeedback.selectionClick();
    final soundService = SoundService();
    final hasCustom = soundService.getCustomSoundPath(category) != null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return _SoundPickerSheet(
          title: title,
          options: options,
          currentSound: currentSound,
          category: category,
          hasCustom: hasCustom,
          accent: accent,
          isDark: isDark,
          onChanged: onChanged,
          onPreview: onPreview,
        );
      },
    );
  }

  String _displayName(String type, String category) {
    if (type == 'custom') {
      final hasCustom = SoundService().getCustomSoundPath(category) != null;
      return hasCustom ? 'Custom' : 'Upload';
    }
    return _formatSoundTypeName(type);
  }
}

class _SoundPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String currentSound;
  final String category;
  final bool hasCustom;
  final Color accent;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPreview;

  const _SoundPickerSheet({
    required this.title,
    required this.options,
    required this.currentSound,
    required this.category,
    required this.hasCustom,
    required this.accent,
    required this.isDark,
    required this.onChanged,
    required this.onPreview,
  });

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  late String _selected;
  late bool _hasCustom;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSound;
    _hasCustom = widget.hasCustom;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final fg = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: muted,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tap to select. Long-press to preview.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.options.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border, indent: 56),
                itemBuilder: (_, i) {
                  final opt = widget.options[i];
                  return _buildOption(opt, fg, muted, border);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String opt, Color fg, Color muted, Color border) {
    final isCustom = opt == 'custom';
    final isNone = opt == 'none';
    final selected = opt == _selected;
    final accent = widget.accent;

    final label = isCustom
        ? (_hasCustom ? 'Custom file' : 'Upload sound…')
        : _formatSoundTypeName(opt);

    final iconData = isCustom
        ? (_hasCustom ? Icons.music_note_rounded : Icons.upload_file_rounded)
        : isNone
            ? Icons.notifications_off_outlined
            : Icons.music_note_outlined;

    return InkWell(
      onTap: () => _onTap(opt, isCustom),
      onLongPress: isNone || (isCustom && !_hasCustom)
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPreview(opt);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : muted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData,
                  size: 18, color: selected ? accent : muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: accent)
            else if (!isNone && !(isCustom && !_hasCustom))
              Icon(Icons.play_arrow_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(String opt, bool isCustom) async {
    HapticFeedback.selectionClick();
    if (isCustom) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (file.size > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB). Max 2MB for sound effects.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        final path = await SoundService()
            .setCustomSound(widget.category, file.path!);
        if (path != null && mounted) {
          setState(() {
            _hasCustom = true;
            _selected = 'custom';
          });
          widget.onChanged('custom');
          widget.onPreview('custom');
        }
        return;
      } else if (_hasCustom) {
        setState(() => _selected = 'custom');
        widget.onChanged('custom');
        widget.onPreview('custom');
        return;
      }
      return;
    }

    setState(() => _selected = opt);
    widget.onChanged(opt);
    if (opt != 'none') widget.onPreview(opt);
  }
}

String _formatSoundTypeName(String type) {
  switch (type) {
    case 'beep':
      return 'Beep';
    case 'chime':
      return 'Chime';
    case 'voice':
      return 'Voice';
    case 'tick':
      return 'Tick';
    case 'gong':
      return 'Gong';
    case 'bell':
      return 'Bell';
    case 'ding':
      return 'Ding';
    case 'pop':
      return 'Pop';
    case 'whoosh':
      return 'Whoosh';
    case 'success':
      return 'Success';
    case 'fanfare':
      return 'Fanfare';
    case 'none':
      return 'None';
    default:
      return type[0].toUpperCase() + type.substring(1);
  }
}
