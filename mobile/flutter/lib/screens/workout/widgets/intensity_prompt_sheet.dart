import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/last_used_service.dart';
import '../../../widgets/common/last_used_badge.dart';
import '../../../widgets/glass_sheet.dart';

String _rpeKeyFor(String exerciseName) {
  // Slug the exercise name for a stable, file-system-safe SharedPreferences
  // key. Two exercises with the same name (rare) collapse to one bucket —
  // acceptable trade-off vs threading exerciseId through the call site.
  final slug = exerciseName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'workout_rpe::$slug';
}

/// Result of the intensity prompt — both scales are returned so downstream
/// storage (rir column, analytics) can use whichever is expected.
class IntensityResult {
  /// 1-10 RPE value (10 = max effort / failure).
  final int rpe;
  /// Reps In Reserve: how many reps left in the tank. RIR = max(0, 10 - RPE).
  final int rir;

  const IntensityResult({required this.rpe, required this.rir});
}

/// Modal bottom sheet that asks the user "how hard was that set?" right
/// after they complete a set. Mandatory — the user must pick an effort
/// before the set is finalized.
///
/// Two-tier UX:
///   - **Primary row** = 3 big tap buttons (Easy / Moderate / Hard / Max)
///     that map directly to RPE 7 / 8 / 9 / 10 respectively. Most users
///     complete the prompt in one tap.
///   - **"Dial it in"** expander = 1-10 RPE slider for fine control.
///
/// Mapping table (consistent with workout_summary_advanced.dart bucketing):
///   RPE 10 → RIR 0  · Max    · "to failure"
///   RPE 9  → RIR 1  · Hard   · "1 rep left"
///   RPE 8  → RIR 2  · Mod    · "2 reps left"
///   RPE 7  → RIR 3  · Easy   · "3 reps left"
///   RPE 6  → RIR 4  · ...    · "4 reps left"
///   ...
Future<IntensityResult?> showIntensityPromptSheet(
  BuildContext context, {
  int? previousRpe,
  required String exerciseName,
  required int setNumber,
}) async {
  return showGlassSheet<IntensityResult>(
    context: context,
    isDismissible: false, // Mandatory — can't tap outside to dismiss.
    enableDrag: false,
    opaque: false,
    builder: (ctx) => GlassSheet(
      opaque: false,
      showHandle: true,
      child: _IntensityPromptSheet(
        previousRpe: previousRpe,
        exerciseName: exerciseName,
        setNumber: setNumber,
      ),
    ),
  );
}

class _IntensityPromptSheet extends ConsumerStatefulWidget {
  final int? previousRpe;
  final String exerciseName;
  final int setNumber;

  const _IntensityPromptSheet({
    required this.previousRpe,
    required this.exerciseName,
    required this.setNumber,
  });

  @override
  ConsumerState<_IntensityPromptSheet> createState() =>
      _IntensityPromptSheetState();
}

class _IntensityPromptSheetState extends ConsumerState<_IntensityPromptSheet> {
  int? _selectedRpe;
  bool _sliderExpanded = false;
  int? _lastUsedRpe;

  @override
  void initState() {
    super.initState();
    final raw = ref
        .read(lastUsedServiceProvider)
        .get(_rpeKeyFor(widget.exerciseName));
    final parsed = raw == null ? null : int.tryParse(raw);
    if (parsed != null && parsed >= 1 && parsed <= 10) {
      _lastUsedRpe = parsed;
    }
  }

  void _pickRpe(int rpe) {
    HapticService.selection();
    setState(() => _selectedRpe = rpe);
  }

  void _confirm() {
    if (_selectedRpe == null) return;
    HapticService.success();
    final rpe = _selectedRpe!.clamp(1, 10);
    final rir = (10 - rpe).clamp(0, 10);
    // Persist this RPE per-exercise so the next set of the same exercise
    // (in any future session) shows the sparkle on the matching chip.
    // Fire-and-forget — don't block the modal pop on prefs flush.
    // ignore: unawaited_futures
    ref
        .read(lastUsedServiceProvider)
        .set(_rpeKeyFor(widget.exerciseName), rpe.toString());
    Navigator.of(context).pop(IntensityResult(rpe: rpe, rir: rir));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How hard was that set?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set ${widget.setNumber} · ${widget.exerciseName}',
                        style: TextStyle(fontSize: 12, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Four primary buttons. The "easy" tile aliases RPE 1–7 (per the
            // existing UI), so we badge it whenever lastUsed is in that range.
            Row(
              children: [
                Expanded(
                  child: _EffortTile(
                    label: 'Easy',
                    subLabel: '3+ left',
                    emoji: '😌',
                    selected: _selectedRpe != null &&
                        _selectedRpe! <= 7,
                    isLastUsed: _lastUsedRpe != null && _lastUsedRpe! <= 7,
                    color: AppColors.success,
                    onTap: () => _pickRpe(7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EffortTile(
                    label: 'Moderate',
                    subLabel: '2 left',
                    emoji: '👍',
                    selected: _selectedRpe == 8,
                    isLastUsed: _lastUsedRpe == 8,
                    color: AppColors.orange,
                    onTap: () => _pickRpe(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EffortTile(
                    label: 'Hard',
                    subLabel: '1 left',
                    emoji: '🔥',
                    selected: _selectedRpe == 9,
                    isLastUsed: _lastUsedRpe == 9,
                    color: const Color(0xFFEF4444),
                    onTap: () => _pickRpe(9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EffortTile(
                    label: 'Max',
                    subLabel: 'failure',
                    emoji: '🥵',
                    selected: _selectedRpe == 10,
                    isLastUsed: _lastUsedRpe == 10,
                    color: const Color(0xFF7C3AED),
                    onTap: () => _pickRpe(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Dial-it-in expander
            GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _sliderExpanded = !_sliderExpanded);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _sliderExpanded
                          ? Icons.expand_less_rounded
                          : Icons.tune_rounded,
                      size: 16,
                      color: textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _sliderExpanded ? 'Hide RPE slider' : 'Dial it in (RPE 1-10)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_sliderExpanded) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RPE',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      )),
                  Text(
                    _selectedRpe != null
                        ? '${_selectedRpe!}  ·  ${(10 - _selectedRpe!).clamp(0, 10)} RIR'
                        : '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: (_selectedRpe ?? 8).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: 'RPE ${_selectedRpe ?? 8}',
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRpe = v.round());
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedRpe == null ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _selectedRpe == null ? null : AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _selectedRpe == null
                      ? 'Pick an effort to continue'
                      : 'Log set',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _selectedRpe == null
                        ? textSecondary
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffortTile extends StatelessWidget {
  final String label;
  final String subLabel;
  final String emoji;
  final bool selected;
  final bool isLastUsed;
  final Color color;
  final VoidCallback onTap;

  const _EffortTile({
    required this.label,
    required this.subLabel,
    required this.emoji,
    required this.selected,
    required this.isLastUsed,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Show the badge when this tile matches last-used AND is NOT currently
    // selected (the orange ring + glow already mark the active pick).
    final showBadge = isLastUsed && !selected;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.28)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? color
                    : (isDark
                        ? color.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.30)),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? color : textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showBadge)
            Positioned(
              top: -4,
              right: -4,
              child: LastUsedBadge.static(colorOverride: color, size: 14),
            ),
        ],
      ),
    );
  }
}
