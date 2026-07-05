import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Hero fasting card - prominent action-focused fasting display
/// Shows current fast progress or start fast button.
///
/// Signature v2 styling: ZealovaCard hero variant (accent left edge), Anton
/// hero numerals, Barlow Condensed labels/chips. The live 1s timer + progress
/// + zone logic is unchanged.
class HeroFastingCard extends ConsumerStatefulWidget {
  const HeroFastingCard({super.key});

  @override
  ConsumerState<HeroFastingCard> createState() => _HeroFastingCardState();
}

class _HeroFastingCardState extends ConsumerState<HeroFastingCard> {
  Timer? _timer;
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Update every second when fasting
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Get fasting hours based on protocol
  int _getFastingHours(FastingPreferences? preferences) {
    if (preferences == null) return 16; // Default 16:8

    // Try to parse from defaultProtocol string (e.g., "16:8")
    final protocol = preferences.defaultProtocol;
    if (protocol.contains(':')) {
      final parts = protocol.split(':');
      final hours = int.tryParse(parts[0]);
      if (hours != null) return hours;
    }

    // Use custom fasting hours if set
    if (preferences.customFastingHours != null) {
      return preferences.customFastingHours!;
    }

    return 16; // Default
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;
    final preferences = fastingState.preferences;

    // Calculate progress
    final elapsedMinutes = activeFast?.elapsedMinutes ?? 0;
    final targetHours = _getFastingHours(preferences);
    final targetMinutes = targetHours * 60;
    final progress = targetMinutes > 0
        ? (elapsedMinutes / targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    // Format time
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;

    // Get current zone
    final zone = activeFast?.currentZone;

    // Ring goes accent until the goal is reached, then success.
    final ringColor = progress >= 1.0 ? AppColors.success : tc.accent;

    // "EAT AT h:mm a" — the moment the fasting window closes. Derived from the
    // fast's start time + the target window so it stays stable across ticks.
    String? eatAtLabel;
    if (hasFast && activeFast != null) {
      final eatAt = activeFast.startTime.add(Duration(hours: targetHours));
      eatAtLabel = DateFormat('h:mm a').format(eatAt);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ZealovaCard(
        variant: ZealovaCardVariant.hero,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status badge — Barlow uppercase
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (hasFast ? AppColors.success : tc.accent)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                hasFast
                    ? AppLocalizations.of(context).heroFastingCardFasting
                    : AppLocalizations.of(context).heroFastingCardNotFasting,
                style: ZType.lbl(
                  11,
                  color: hasFast ? AppColors.success : tc.accent,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (hasFast && activeFast != null) ...[
              // Elapsed time — Anton hero numeral
              Text(
                AppLocalizations.of(context).heroFastingCardHM(hours, mins),
                style: ZType.disp(40, color: tc.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)
                    .heroFastingCardOfHGoal(targetHours)
                    .toUpperCase(),
                style: ZType.lbl(12, color: tc.textMuted),
              ),
              const SizedBox(height: 16),

              // Circular progress — bigger
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: tc.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(ringColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: ZType.disp(26, color: tc.textPrimary),
                        ),
                        if (zone != null)
                          Icon(
                            Icons.local_fire_department,
                            color: zone.color,
                            size: 22,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Zone chip — keep zone color semantics
              if (zone != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: zone.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    zone.displayName.toUpperCase(),
                    style: ZType.lbl(11, color: zone.color),
                  ),
                ),

              // "EAT AT h:mm a" — when the eating window opens.
              if (eatAtLabel != null) ...[
                const SizedBox(height: 10),
                Text(
                  'EAT AT $eatAtLabel',
                  style: ZType.lbl(12, color: tc.textSecondary),
                ),
              ],

              const SizedBox(height: 16),

              // End Fast button — success fill
              _FastingActionButton(
                label: AppLocalizations.of(context).heroFastingCardEndFast,
                icon: Icons.check_circle_outline,
                background: AppColors.success,
                onPressed: _userId == null
                    ? null
                    : () async {
                        HapticService.medium();
                        await ref.read(fastingProvider.notifier).endFast(
                              userId: _userId!,
                            );
                      },
              ),
            ] else ...[
              // Not fasting state — bigger icon + more content
              const SizedBox(height: 8),
              Icon(
                Icons.timer_outlined,
                size: 72,
                color: tc.accent.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)
                    .heroFastingCardReadyToFast
                    .toUpperCase(),
                style: ZType.disp(24, color: tc.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                (preferences != null
                        ? AppLocalizations.of(context)
                            .heroFastingCardProtocol(preferences.defaultProtocol)
                        : 'Intermittent fasting')
                    .toUpperCase(),
                style: ZType.lbl(12, color: tc.textMuted),
              ),
              const SizedBox(height: 14),
              // Benefit hints
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _FastingBenefit(
                        icon: Icons.local_fire_department,
                        label: AppLocalizations.of(context)
                            .heroFastingCardBurnFat),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _FastingBenefit(
                        icon: Icons.auto_fix_high,
                        label: AppLocalizations.of(context)
                            .heroFastingCardAutophagy),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _FastingBenefit(
                        icon: Icons.bolt,
                        label: AppLocalizations.of(context)
                            .workoutSummaryGeneralEnergy),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start Fast button — orange/accent fill
              _FastingActionButton(
                label: AppLocalizations.of(context).heroFastingCardStartFast,
                icon: Icons.play_arrow_rounded,
                background: AppColors.orange,
                onPressed: _userId == null
                    ? null
                    : () async {
                        HapticService.medium();
                        final protocol = FastingProtocol.fromString(
                            preferences?.defaultProtocol ?? '16:8');
                        await ref.read(fastingProvider.notifier).startFast(
                              userId: _userId!,
                              protocol: protocol,
                            );
                      },
              ),
            ],
            const SizedBox(height: 6),

            // View Details
            TextButton.icon(
              onPressed: () {
                HapticService.light();
                context.push('/fasting');
              },
              icon: Icon(
                Icons.insights_outlined,
                size: 16,
                color: tc.textMuted,
              ),
              label: Text(
                AppLocalizations.of(context).heroWorkoutCardViewDetails,
                style: ZType.lbl(11, color: tc.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width Signature CTA — solid fill, Barlow uppercase label, rounded ~14.
class _FastingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback? onPressed;

  const _FastingActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: ZType.lbl(16, color: Colors.white, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _FastingBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FastingBenefit({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: tc.accent.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            style: ZType.lbl(10, color: tc.textSecondary, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }
}
