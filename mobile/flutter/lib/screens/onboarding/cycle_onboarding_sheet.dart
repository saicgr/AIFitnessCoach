import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/hormonal_health.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/hormonal_health_repository.dart';
import '../../data/services/notification_service.dart';
import '../../widgets/cycle_disclaimer.dart';
import '../../widgets/glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
/// Optional cycle-tracking setup step (Phase E — onboarding).
///
/// Shown after the gender question for users who can have a menstrual cycle:
///  * `gender == female`  → auto-offered.
///  * `non_binary` / `other` / `prefer_not_to_say` → offered behind a gentle
///    opt-in ("Do you track a menstrual cycle?"), handled by the CALLER which
///    only opens this sheet when the user says yes.
///  * `male` → never shown.
///
/// The single feature gate everywhere downstream is
/// `hormonal_profiles.menstrual_tracking_enabled` — NOT gender. This sheet is
/// what flips that flag on. Skipping it leaves the flag off; the user can
/// still enable cycle tracking later from Settings.
///
/// On confirm it seeds, via [HormonalHealthRepository]:
///   1. the hormonal profile (`menstrual_tracking_enabled = true`,
///      `cycle_length_days`, `typical_period_duration_days`,
///      `last_period_start_date`), and
///   2. the first `cycle_periods` row (the last period start date) — the
///      canonical history the prediction engine reads.
/// It also primes the cycle reminder schedule with the tracking mode.
///
/// PRIVACY: this sheet emits NO cycle/symptom content to analytics — the
/// caller may emit a content-free `cycle_onboarding_completed` event name.
class CycleOnboardingSheet extends ConsumerStatefulWidget {
  /// The id of the signed-in user whose profile + first period to seed.
  final String userId;

  const CycleOnboardingSheet({super.key, required this.userId});

  /// Show the sheet. Returns true when the user completed setup (data was
  /// seeded), false / null when they skipped or dismissed.
  static Future<bool?> show(BuildContext context, {required String userId}) {
    return showGlassSheet<bool>(
      context: context,
      opaque: true,
      builder: (_) => GlassSheet(
        opaque: true,
        showHandle: true,
        child: CycleOnboardingSheet(userId: userId),
      ),
    );
  }

  @override
  ConsumerState<CycleOnboardingSheet> createState() =>
      _CycleOnboardingSheetState();
}

class _CycleOnboardingSheetState extends ConsumerState<CycleOnboardingSheet> {
  // Tier-1 required input: the last period's Day 1. Defaults to null so the
  // user makes a deliberate choice rather than accepting a wrong "today".
  DateTime? _lastPeriodStart;
  // Profile defaults — clamped to the backend's accepted ranges
  // (cycle 21-45, period 2-10) so the seed PUT never 422s.
  int _cycleLength = 28;
  int _periodLength = 5;
  CycleTrackingMode _mode = CycleTrackingMode.tracking;
  bool _saving = false;
  String? _error;

  Future<void> _pickLastPeriod() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart ?? now.subtract(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'First day of your last period',
    );
    if (picked != null) {
      setState(() =>
          _lastPeriodStart = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _confirm() async {
    if (_lastPeriodStart == null) {
      setState(() => _error = 'Pick the first day of your last period.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(hormonalHealthRepositoryProvider);
    try {
      // 1. Seed the hormonal profile — flips `menstrual_tracking_enabled` on,
      //    which is the single gate every cycle surface checks.
      await repo.upsertProfile(widget.userId, {
        'menstrual_tracking_enabled': true,
        'cycle_length_days': _cycleLength.clamp(21, 45),
        'typical_period_duration_days': _periodLength.clamp(2, 10),
        'last_period_start_date':
            _isoDate(_lastPeriodStart!),
      });

      // 2. Seed the first observed period — the canonical history row the
      //    prediction engine derives every forecast from.
      final period =
          await repo.createPeriod(widget.userId, startDate: _lastPeriodStart!);

      // Gamification: seeding the first period IS a cycle log — award the
      // cycle-logging XP + advance the cycle streak trophy. Fire-and-forget;
      // a failure here must never block onboarding.
      try {
        // ignore: unawaited_futures
        ref
            .read(xpProvider.notifier)
            .markCycleLogged(sourceId: period.id, entryKind: 'period');
      } catch (_) {/* non-fatal */}

      // 3. Prime the cycle reminders with the chosen tracking mode so the
      //    TTC-only fertility reminders schedule correctly from day one.
      try {
        ref
            .read(notificationPreferencesProvider.notifier)
            .setCycleTrackingMode(_mode.value);
      } catch (_) {
        // Notification prefs not ready in some flows — non-fatal; the cycle
        // providers will re-sync the mode on the next prediction.
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your cycle setup. Please try again.';
        });
      }
    }
  }

  String _isoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).cycleSetupHomeTrackYourCycle,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'A few details lets Zealova predict your period and cycle '
              'phases, and adapt workouts and nutrition around them. '
              'Optional — you can skip and set this up later in Settings.',
              style: TextStyle(fontSize: 13, height: 1.5, color: textMuted),
            ),
            const SizedBox(height: 18),

            // ── Last period start ─────────────────────────────────
            _SectionLabel('When did your last period start?', textMuted),
            const SizedBox(height: 8),
            InkWell(
              onTap: _saving ? null : _pickLastPeriod,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      _lastPeriodStart == null
                          ? 'Tap to choose a date'
                          : _isoDate(_lastPeriodStart!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _lastPeriodStart == null
                            ? textMuted
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Cycle length ──────────────────────────────────────
            _SliderRow(
              label: AppLocalizations.of(context).cycleOnboardingTypicalCycleLength,
              valueLabel: '$_cycleLength days',
              value: _cycleLength.toDouble(),
              min: 21,
              max: 45,
              divisions: 24,
              accent: accent,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _cycleLength = v.round()),
            ),
            const SizedBox(height: 14),

            // ── Period length ─────────────────────────────────────
            _SliderRow(
              label: AppLocalizations.of(context).cycleOnboardingTypicalPeriodLength,
              valueLabel: '$_periodLength days',
              value: _periodLength.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              accent: accent,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _periodLength = v.round()),
            ),
            const SizedBox(height: 18),

            // ── Tracking mode ─────────────────────────────────────
            _SectionLabel('What are you tracking for?', textMuted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModeChip(
                  label: AppLocalizations.of(context).cycleOnboardingGeneralTracking,
                  selected: _mode == CycleTrackingMode.tracking,
                  accent: accent,
                  isDark: isDark,
                  onTap: _saving
                      ? null
                      : () => setState(
                          () => _mode = CycleTrackingMode.tracking),
                ),
                _ModeChip(
                  label: AppLocalizations.of(context).cycleOnboardingTryingToConceive,
                  selected: _mode == CycleTrackingMode.ttc,
                  accent: accent,
                  isDark: isDark,
                  onTap: _saving
                      ? null
                      : () =>
                          setState(() => _mode = CycleTrackingMode.ttc),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Safety disclaimer (non-contraceptive) ─────────────
            const CycleDisclaimer.onboarding(),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.error),
              ),
              const SizedBox(height: 10),
            ],

            // ── Actions ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).cycleScreenUiStartTracking,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  AppLocalizations.of(context).notifsLaterButton,
                  style: TextStyle(color: textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      );
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<double>? onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.2),
            overlayColor: accent.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : accent.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 15, color: accent),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
