import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';
import 'fasting_stage_model.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card describing the user's current metabolic stage, what's happening in
/// their body, and how long until the next stage.
class FastingStageCard extends StatelessWidget {
  /// Elapsed seconds of the active fast (live).
  final int elapsedSeconds;

  /// Current metabolic stage.
  final FastingStage stage;

  /// Tapped when the `>` Body Status affordance is pressed (Task A entry
  /// point). When null the affordance is hidden.
  final VoidCallback? onOpenBodyStatus;

  const FastingStageCard({
    super.key,
    required this.elapsedSeconds,
    required this.stage,
    this.onOpenBodyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final stageColor = stage.color;
    final elapsedHours = elapsedSeconds / 3600.0;
    final next = stage.next;

    // Hours until the next stage.
    final hoursUntilNext = next == null
        ? null
        : (stage.endHour - elapsedHours).clamp(0.0, double.infinity);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            stageColor.withValues(alpha: colors.isDark ? 0.22 : 0.14),
            stageColor.withValues(alpha: colors.isDark ? 0.08 : 0.05),
          ],
        ),
        border: Border.all(color: stageColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stageColor.withValues(alpha: 0.2),
                ),
                child: Icon(stage.icon, color: stageColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).fastingStageCardCurrentStage,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.name,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: stageColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Stage index pill (e.g. "3 / 7").
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stage.index + 1} / ${FastingStage.values.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stageColor,
                  ),
                ),
              ),
              // `>` Body Status affordance (Task A entry point).
              if (onOpenBodyStatus != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: stageColor),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stage.description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            // Progress toward next stage.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stage.progressWithin(elapsedHours),
                minHeight: 6,
                backgroundColor: colors.cardBorder.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(stageColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(next.icon, size: 15, color: colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.fastingStageCardNext(next.name),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  _formatHoursUntil(hoursUntilNext!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: stageColor,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 15, color: stageColor),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).fastingStageCardFinalMetabolicStageReached,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: stageColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onOpenBodyStatus == null) return card;
    return GestureDetector(
      onTap: onOpenBodyStatus,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  String _formatHoursUntil(double hours) {
    if (hours <= 0) return 'now';
    if (hours < 1) {
      final mins = (hours * 60).round();
      return 'in ${mins}m';
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return 'in ${h}h';
    return 'in ${h}h ${m}m';
  }
}
