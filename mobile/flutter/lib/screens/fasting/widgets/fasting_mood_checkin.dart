import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/mood.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Result of the end-fast mood + energy check-in (Section F).
class FastingMoodEnergyResult {
  /// The selected [Mood] (its `.value` becomes `moodAfter`), or null if skipped.
  final Mood? mood;

  /// Energy level 1–5, or null if skipped.
  final int? energyLevel;

  const FastingMoodEnergyResult({this.mood, this.energyLevel});

  bool get isEmpty => mood == null && energyLevel == null;
}

/// End-fast mood + energy check-in bottom sheet (Section F).
///
/// Uses the app's standard [Mood] vocabulary/emojis — the SAME mood set as
/// the global mood feature, so fasting mood never diverges. This is
/// fast-scoped (before/after a fast); it does not replace the daily mood log.
class FastingMoodCheckInSheet extends StatefulWidget {
  /// Called with the chosen mood/energy when the user confirms.
  final ValueChanged<FastingMoodEnergyResult> onSubmit;

  const FastingMoodCheckInSheet({super.key, required this.onSubmit});

  @override
  State<FastingMoodCheckInSheet> createState() =>
      _FastingMoodCheckInSheetState();
}

class _FastingMoodCheckInSheetState extends State<FastingMoodCheckInSheet> {
  Mood? _mood;
  int? _energy;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
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
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context).fastingMoodCheckinHowDoYouFeel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).fastingMoodCheckinLogYourMoodAnd,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          const SizedBox(height: 18),

          Text(
            'MOOD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Mood.values.map((m) {
              final selected = _mood == m;
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() => _mood = selected ? null : m);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.accent.withValues(alpha: 0.16)
                        : colors.elevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? colors.accent
                          : colors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? colors.accent
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text(
            AppLocalizations.of(context).fastingMoodCheckinEnergy,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = _energy != null && level <= _energy!;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() =>
                          _energy = _energy == level ? null : level);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.accent.withValues(alpha: 0.16)
                            : colors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? colors.accent
                              : colors.cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: selected
                              ? colors.accent
                              : colors.textMuted
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          if (_energy != null)
            Text(
              _energyLabel(_energy!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ).animate().fadeIn(duration: 180.ms),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.onSubmit(const FastingMoodEnergyResult());
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(
                    AppLocalizations.of(context).onboardingSkip,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.medium();
                      widget.onSubmit(FastingMoodEnergyResult(
                        mood: _mood,
                        energyLevel: _energy,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentContrast,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).heroFastingCardEndFast,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _energyLabel(int level) {
    switch (level) {
      case 1:
        return 'Drained';
      case 2:
        return 'Low';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      default:
        return 'Energized';
    }
  }
}

/// Compact before → after mood/energy display for history cards and the
/// in-progress card (Section F).
///
/// Renders nothing if there is no mood/energy data at all.
class MoodEnergyDelta extends StatelessWidget {
  final String? moodBefore;
  final String? moodAfter;
  final int? energyBefore;
  final int? energyAfter;

  const MoodEnergyDelta({
    super.key,
    this.moodBefore,
    this.moodAfter,
    this.energyBefore,
    this.energyAfter,
  });

  bool get _hasAny =>
      moodBefore != null ||
      moodAfter != null ||
      energyBefore != null ||
      energyAfter != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    final colors = ThemeColors.of(context);

    final hasMood = moodBefore != null || moodAfter != null;
    final hasEnergy = energyBefore != null || energyAfter != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (hasMood) ...[
            _MoodChip(value: moodBefore, colors: colors),
            _Arrow(colors: colors),
            _MoodChip(value: moodAfter, colors: colors),
          ],
          if (hasMood && hasEnergy) ...[
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 16,
              color: colors.cardBorder,
            ),
            const SizedBox(width: 12),
          ],
          if (hasEnergy) ...[
            Icon(Icons.bolt_rounded, size: 13, color: colors.textMuted),
            const SizedBox(width: 3),
            _EnergyText(value: energyBefore, colors: colors),
            _Arrow(colors: colors),
            _EnergyText(value: energyAfter, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String? value;
  final ThemeColors colors;

  const _MoodChip({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: 13, color: colors.textMuted),
      );
    }
    final mood = Mood.fromString(value!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(mood.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 3),
        Text(
          mood.label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EnergyText extends StatelessWidget {
  final int? value;
  final ThemeColors colors;

  const _EnergyText({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      value == null ? '—' : '$value/5',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final ThemeColors colors;

  const _Arrow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Icon(Icons.arrow_forward_rounded,
          size: 12, color: colors.textMuted),
    );
  }
}
