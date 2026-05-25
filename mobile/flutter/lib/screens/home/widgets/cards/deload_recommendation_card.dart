/// Home-screen deload recommendation card (Phase A.1).
///
/// The first coherent deload surface in the app — backed by
/// [deloadStatusProvider], which calls the existing (previously dead-code)
/// `BodyAnalyzerRepository.triggerDeloadCheck()` endpoint.
///
/// Render rules (all enforced in the provider, mirrored here defensively):
///   • shows ONLY when the API says `needs_deload == true`;
///   • hides on <4 logged workouts (API returns false in that case);
///   • hides while already inside a deload mesocycle;
///   • hides for 7 days after the user dismisses it;
///   • hides silently on any API/loading error (failure stays loud in logs).
///
/// Visually modelled on `PersonalRecordsCard` — same margin, radius, border,
/// icon-chip header — and registered just above it in `tile_factory.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/providers/deload_status_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../services/mesocycle_planner.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Title variant pool — 4 options per `feedback_dynamic_copy_not_robotic.md`.
/// Seeded deterministically per-day so the title is stable within a day but
/// rotates across days.
const List<String> _deloadTitleVariants = [
  'Time for a deload week',
  "Your body's asking for a reset",
  'Deload week recommended',
  'Recovery window detected',
];

/// Picks a title variant deterministically from today's date so the copy
/// stays stable across home rebuilds but feels fresh day to day.
String _pickDeloadTitle() {
  final now = DateTime.now();
  // Day-of-epoch as the seed — same title all day, rotates daily.
  final dayIndex = now.difference(DateTime(2020)).inDays;
  return _deloadTitleVariants[dayIndex % _deloadTitleVariants.length];
}

/// The deload recommendation card. Returns [SizedBox.shrink] whenever the
/// resolved status says it should not show — safe to place unconditionally
/// in a tile list.
class DeloadRecommendationCard extends ConsumerWidget {
  final bool isDark;

  const DeloadRecommendationCard({super.key, this.isDark = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deloadStatusProvider);

    // Loading and error both collapse to nothing — the card must never flash
    // a spinner or an error state on the home screen. Failures are still
    // logged inside the provider so the bug surfaces.
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (!status.shouldShow) return const SizedBox.shrink();
        return _DeloadCardBody(status: status, isDark: isDark);
      },
    );
  }
}

class _DeloadCardBody extends ConsumerStatefulWidget {
  final DeloadStatus status;
  final bool isDark;

  const _DeloadCardBody({required this.status, required this.isDark});

  @override
  ConsumerState<_DeloadCardBody> createState() => _DeloadCardBodyState();
}

class _DeloadCardBodyState extends ConsumerState<_DeloadCardBody> {
  /// Guards the CTA against double-taps while the planner write is in flight.
  bool _planning = false;

  Future<void> _onPlanDeload() async {
    if (_planning) return;
    setState(() => _planning = true);
    HapticService.medium();
    try {
      // Preset the mesocycle into its deload week, then route the user to the
      // progression / deload settings screen to confirm and tune it.
      await MesocyclePlanner.forceDeload();
    } catch (e) {
      debugPrint('❌ [Deload] forceDeload failed: $e');
    }
    if (!mounted) return;
    setState(() => _planning = false);
    // Dismiss after acting so the card doesn't linger once the user has
    // started a deload — re-checks naturally after the 7-day window.
    await dismissDeloadCard(ref);
    if (!mounted) return;
    context.push('/settings/progression-pace');
  }

  Future<void> _onDismiss() async {
    HapticService.light();
    await dismissDeloadCard(ref);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final title = _pickDeloadTitle();
    final reason = widget.status.reason.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        // A subtle accent-tinted border so the card reads as a recommendation,
        // not just another stat tile.
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon chip + title + dismiss ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.self_improvement_rounded,
                    color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              // Dismiss — small, low-emphasis, generous tap target.
              InkWell(
                onTap: _onDismiss,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Body: API reason verbatim ──
          Text(
            reason,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 14),
          // ── CTA: full-width so it stays comfortable on iPhone SE ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _planning ? null : _onPlanDeload,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    AccentColorScope.of(context).isLightFor(isDark)
                        ? Colors.black
                        : Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _planning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).deloadRecommendationCardPlanDeloadWeek,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
