import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/program_template.dart';
import '../../l10n/generated/app_localizations.dart';

/// Settings strip surfaced inside the program builder (plan B.3 / B.3.2).
///
/// Lets the user set the three template-level knobs before saving:
///   - `progression_strategy` — linear / wave / double / none
///   - `deload_every_n_weeks`  — 0 (off) .. 8
///   - `apply_staples`         — inject the user's staple exercises
///
/// Stateless: it renders [template] and reports edits through [onChanged] with
/// a fresh copy. The parent screen owns the mutable draft.
class ProgramTemplateMetaStrip extends StatelessWidget {
  final ProgramTemplate template;
  final ValueChanged<ProgramTemplate> onChanged;

  const ProgramTemplateMetaStrip({
    super.key,
    required this.template,
    required this.onChanged,
  });

  /// Non-strength programs (Yoga, Stretching, Pain Management) carry no
  /// meaningful progression — the strip hides the strategy/deload controls
  /// and shows an explanatory note instead.
  bool get _progressionMeaningless {
    final c = (template.category ?? '').toLowerCase();
    return c.contains('yoga') ||
        c.contains('stretch') ||
        c.contains('pain') ||
        template.progressionStrategy == 'none';
  }

  @override
  Widget build(BuildContext context) {
    // TODO(i18n): _label, _infoNote, _buildStrategyChips, _buildDeloadSlider have no BuildContext — refactor to accept AppLocalizations
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                l.programMetaProgramSettings,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progression strategy.
          _label(l.programMetaProgression, textSecondary),
          const SizedBox(height: 6),
          _buildStrategyChips(isDark, accent),
          const SizedBox(height: 14),

          if (_progressionMeaningless)
            _infoNote(
              l.programMetaFixedLoadsNote,
              textSecondary,
            )
          else ...[
            // Deload frequency.
            _label(l.programMetaDeloadEvery, textSecondary),
            const SizedBox(height: 4),
            _buildDeloadSlider(isDark, accent, textPrimary, textSecondary),
            const SizedBox(height: 14),
          ],

          // Apply staples toggle.
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: template.applyStaples,
            activeThumbColor: accent,
            onChanged: (v) => onChanged(template.copyWith(applyStaples: v)),
            title: Text(
              l.programMetaApplyStaples,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              l.programMetaApplyStaplesSubtitle,
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget _label(String text, Color color) {
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

  Widget _infoNote(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, height: 1.35, color: color),
          ),
        ),
      ],
    );
  }

  /// The four supported progression strategies, each with a friendly label.
  // TODO(i18n): _strategies is a static const — values 'Linear'/'Wave'/'Double'/'None' cannot be localized here
  static const _strategies = <String, String>{
    'linear': 'Linear',
    'wave': 'Wave',
    'double': 'Double',
    'none': 'None',
  };

  Widget _buildStrategyChips(bool isDark, Color accent) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in _strategies.entries)
          _MetaChip(
            label: entry.value,
            selected: template.progressionStrategy == entry.key,
            accent: accent,
            isDark: isDark,
            onTap: () {
              // Picking "none" also clears the deload cadence — a no-
              // progression program never deloads.
              if (entry.key == 'none') {
                onChanged(template.copyWith(
                  progressionStrategy: 'none',
                  clearDeload: true,
                ));
              } else {
                onChanged(template.copyWith(
                  progressionStrategy: entry.key,
                  // Restore a sensible default cadence if it was cleared.
                  deloadEveryNWeeks: template.deloadEveryNWeeks ?? 5,
                ));
              }
            },
          ),
      ],
    );
  }

  // TODO(i18n): _buildDeloadSlider has no BuildContext — 'No scheduled deload', 'Every $n weeks', 'Off', '$n wk' can't be localized here
  Widget _buildDeloadSlider(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textSecondary,
  ) {
    // 0 = off, 3..8 = every Nth week.
    final current = template.deloadEveryNWeeks ?? 0;
    final clamped = current.clamp(0, 8).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current == 0
              ? 'No scheduled deload'
              : 'Every $current weeks',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Slider(
          value: clamped,
          min: 0,
          max: 8,
          divisions: 8,
          activeColor: accent,
          label: clamped.round() == 0 ? 'Off' : '${clamped.round()} wk',
          onChanged: (v) {
            final weeks = v.round();
            onChanged(template.copyWith(
              deloadEveryNWeeks: weeks,
              clearDeload: weeks == 0,
            ));
          },
        ),
      ],
    );
  }
}

/// Selectable pill used for the strategy chips.
class _MetaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _MetaChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.surface : AppColorsLight.background;
    final textColor = selected
        ? (accent.computeLuminance() > 0.55 ? Colors.black : Colors.white)
        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);
    return Material(
      color: selected ? accent : base,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
