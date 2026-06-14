import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/providers/cosmetics_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Appearance sub-page — rebuilt into the Signature v2 hairline composition.
///
/// Structure mirrors `signature-v2.html` frame `#set-appearance`:
///   1. THEME MODE  — Barlow kicker + a System / Light / Dark segmented
///      control (active marked by the accent underline).
///   2. ACCENT COLOR — Barlow kicker + the genuine 12-swatch grid (✓ on the
///      chosen swatch; locked swatches gated by owned cosmetics).
///   3. A grouped hairline list: Haptic feedback (toggle), Week starts on
///      (Sun/Mon chips), Show daily goals (toggle), Serious mode (toggle).
///
/// Wiring preserved 1:1 — themeModeProvider.setTheme, accentColorProvider
/// .setAccent, hapticLevelProvider.setLevel, weekStartsSundayProvider
/// .setStartsSunday, dailyXPStripEnabledProvider.setEnabled, and
/// seriousModeProvider.setEnabled all keep their exact bindings.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(title: l10n.settingsAppearance, titleSize: 26),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── THEME MODE ──────────────────────────────────────────────
            ZealovaSectionKicker(l10n.settingsThemeMode),
            const SizedBox(height: 3),
            Text(
              l10n.preferencesSystemLightOrDark,
              style: TextStyle(fontSize: 11, color: tc.textMuted),
            ),
            const SizedBox(height: 9),
            const _ThemeSegmented(),
            const SizedBox(height: 18),
            const ZealovaRule(),
            const SizedBox(height: 14),

            // ── ACCENT COLOR ────────────────────────────────────────────
            ZealovaSectionKicker(l10n.settingsCardUiAccentColor),
            const SizedBox(height: 3),
            Text(
              l10n.preferencesChooseYourAppAccent,
              style: TextStyle(fontSize: 11, color: tc.textMuted),
            ),
            const SizedBox(height: 12),
            const _AccentSwatchGrid(),
            const SizedBox(height: 18),
            const ZealovaRule(),
            const SizedBox(height: 6),

            // ── TOGGLES + WEEK START (hairline list) ─────────────────────
            const _HapticToggleRow(),
            const _WeekStartRow(),
            const _DailyGoalsRow(),
            const _SeriousModeRow(),
          ],
        ),
      ),
    );
  }
}

/// System / Light / Dark segmented control — active marked by the accent
/// underline (v2 `.ap-seg`). Reads + writes [themeModeProvider].
class _ThemeSegmented extends ConsumerWidget {
  const _ThemeSegmented();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final mode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context);

    void set(ThemeMode m) {
      if (m == mode) return;
      HapticFeedback.selectionClick();
      ref.read(themeModeProvider.notifier).setTheme(m);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tc.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _ThemeSeg(
            label: l10n.inlineThemeSelectorAuto,
            selected: mode == ThemeMode.system,
            onTap: () => set(ThemeMode.system),
          ),
          _segDivider(tc),
          _ThemeSeg(
            label: l10n.settingsThemeLight,
            selected: mode == ThemeMode.light,
            onTap: () => set(ThemeMode.light),
          ),
          _segDivider(tc),
          _ThemeSeg(
            label: l10n.settingsThemeDark,
            selected: mode == ThemeMode.dark,
            onTap: () => set(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _segDivider(ThemeColors tc) =>
      Container(width: 1, height: 40, color: AppColors.hairline);
}

class _ThemeSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeSeg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: selected ? tc.surface : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: ZType.lbl(
                  11.5,
                  color: selected ? tc.textPrimary : tc.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              // Accent underline on the active segment.
              Container(
                height: 2,
                width: 30,
                color: selected ? tc.accent : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The genuine 12-color accent grid (v2 `.ap-grid`). Chosen swatch is ringed
/// with a ✓; cosmetic-gated swatches show a lock until owned. Reads + writes
/// [accentColorProvider].
class _AccentSwatchGrid extends ConsumerWidget {
  const _AccentSwatchGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final current = ref.watch(accentColorProvider);
    final cosmetics = ref.watch(cosmeticsProvider);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
      ),
      itemCount: AccentColor.values.length,
      itemBuilder: (context, index) {
        final accent = AccentColor.values[index];
        final isSelected = accent == current;
        final gatingId = accent.gatingCosmeticId;
        final isLocked = gatingId != null && !cosmetics.ownsCosmetic(gatingId);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unlocks at Level ${accent.unlockLevel} — keep going!',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            ref.read(accentColorProvider.notifier).setAccent(accent);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: isLocked ? 0.4 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.previewColor,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(color: tc.background, spreadRadius: 2),
                            BoxShadow(color: tc.textPrimary, spreadRadius: 3.5),
                          ]
                        : null,
                  ),
                  child: const AspectRatio(aspectRatio: 1),
                ),
              ),
              if (isSelected && !isLocked)
                const Icon(Icons.check, color: Colors.white, size: 16),
              if (isLocked)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 11),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Haptic feedback — a single hairline-track toggle (v2 `.st-tog`). Maps the
/// underlying [hapticLevelProvider] (off / light / medium / strong) to a
/// boolean: off ⇄ light, preserving any non-off level the user picked
/// elsewhere as "on".
class _HapticToggleRow extends ConsumerWidget {
  const _HapticToggleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(hapticLevelProvider);
    final on = level != HapticLevel.off;
    return ZealovaListRow(
      icon: Icons.vibration_outlined,
      label: AppLocalizations.of(context).hapticsHapticFeedback,
      value: level.displayName.toUpperCase(),
      showChevron: false,
      trailing: ZealovaToggle(
        value: on,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          ref.read(hapticLevelProvider.notifier).setLevel(
                v ? HapticLevel.light : HapticLevel.off,
              );
        },
      ),
    );
  }
}

/// Week starts on — Sun / Mon chip pair as the row trailing (v2 `.ai-chip`).
/// Reads + writes [weekStartsSundayProvider].
class _WeekStartRow extends ConsumerWidget {
  const _WeekStartRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startsSunday = ref.watch(weekStartsSundayProvider);
    final l10n = AppLocalizations.of(context);

    void set(bool sunday) {
      if (sunday == startsSunday) return;
      HapticFeedback.lightImpact();
      ref.read(weekStartsSundayProvider.notifier).setStartsSunday(sunday);
    }

    return ZealovaListRow(
      icon: Icons.calendar_today_outlined,
      label: l10n.workoutPreferencesCardWeekStartsOn,
      showChevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DayChip(
            label: l10n.settingsCardSunday,
            selected: startsSunday,
            onTap: () => set(true),
          ),
          const SizedBox(width: 6),
          _DayChip(
            label: l10n.settingsCardPartMonday,
            selected: !startsSunday,
            onTap: () => set(false),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? tc.textPrimary : tc.cardBorder,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: ZType.lbl(
            10.5,
            color: selected ? tc.textPrimary : tc.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Show daily goals — hairline-track toggle for the Home XP progress strip.
/// Reads + writes [dailyXPStripEnabledProvider].
class _DailyGoalsRow extends ConsumerWidget {
  const _DailyGoalsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyXPStripEnabledProvider);
    final l10n = AppLocalizations.of(context);
    return ZealovaListRow(
      icon: Icons.flag_outlined,
      label: l10n.preferencesShowDailyGoals,
      value: l10n.preferencesXpProgressStripOn,
      showChevron: false,
      trailing: ZealovaToggle(
        value: enabled,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          ref.read(dailyXPStripEnabledProvider.notifier).setEnabled(v);
        },
      ),
    );
  }
}

/// Serious mode — dials gamification down without losing tracking. Hairline
/// row + toggle (last row, no hairline). Reads + writes [seriousModeProvider].
class _SeriousModeRow extends ConsumerWidget {
  const _SeriousModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serious = ref.watch(seriousModeProvider);
    return ZealovaListRow(
      icon: Icons.self_improvement_outlined,
      label: AppLocalizations.of(context).appearanceSeriousMode,
      value: 'Dial gamification down',
      showChevron: false,
      hairline: false,
      trailing: ZealovaToggle(
        value: serious,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          ref.read(seriousModeProvider.notifier).setEnabled(v);
        },
      ),
    );
  }
}
