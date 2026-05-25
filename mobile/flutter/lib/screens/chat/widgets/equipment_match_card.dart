/// Issue 2: Equipment Match Card.
///
/// Renders the result of the `identify_equipment` LangGraph tool inside
/// the chat thread. Shows the canonical equipment name + up to 3 ranked
/// matches, each with image + name + Swap/Add CTA. Tapping a match's
/// button fires the chat-repo action handler which deeplinks to the
/// appropriate sheet (active workout) or quick-workout generator (no
/// active workout).
///
/// Empty-matches state (vision recognized equipment but library has no
/// rows for it, or vision rejected the photo entirely) renders a
/// "Create custom exercise" CTA so the snap is still actionable.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Tap callback for a single match. The handler decides whether to open
/// Swap, Add, or quick-workout-with-equipment based on the surrounding
/// app state (active workout? in-set?).
typedef EquipmentMatchTap = void Function(Map<String, dynamic> match);

class EquipmentMatchCard extends StatelessWidget {
  final Map<String, dynamic> actionData;
  final EquipmentMatchTap onMatchTap;
  final VoidCallback? onCreateCustom;
  final VoidCallback? onStartWorkoutWithEquipment;

  const EquipmentMatchCard({
    super.key,
    required this.actionData,
    required this.onMatchTap,
    this.onCreateCustom,
    this.onStartWorkoutWithEquipment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    final canonical = actionData['canonical_name'] as String?;
    final rawName = actionData['raw_name'] as String?;
    final matches = (actionData['matches'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final unmatchedReason = actionData['unmatched_reason'] as String?;
    final visionLabel = actionData['vision_label'] as String?;

    final headlineLabel = _displayLabel(canonical, rawName, unmatchedReason);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center_outlined,
                  size: 18,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headlineLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      matches.isNotEmpty
                          ? '${matches.length} exercise${matches.length == 1 ? "" : "s"} you can do here'
                          : (unmatchedReason == 'not_equipment'
                              ? 'That doesn\'t look like gym equipment'
                              : 'No matching exercises in your library yet'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            _buildEmptyState(context, colors, unmatchedReason, visionLabel)
          else
            ..._buildMatchRows(context, colors, matches),
        ],
      ),
    );
  }

  String _displayLabel(
    String? canonical,
    String? rawName,
    String? unmatchedReason,
  ) {
    if (canonical != null && canonical.isNotEmpty) {
      return _humanize(canonical);
    }
    if (rawName != null && rawName.isNotEmpty) {
      return rawName;
    }
    if (unmatchedReason == 'not_equipment') {
      return 'Not gym equipment';
    }
    return 'Couldn\'t identify that one';
  }

  String _humanize(String canonical) {
    return canonical
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeColors colors,
    String? unmatchedReason,
    String? visionLabel,
  ) {
    // Edge cases 30 / 32: even on empty matches we surface a useful CTA.
    final isNotEquipment = unmatchedReason == 'not_equipment';
    final cta = isNotEquipment ? null : 'Create custom exercise';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cta != null && onCreateCustom != null)
          OutlinedButton.icon(
            onPressed: onCreateCustom,
            icon: const Icon(Icons.add_outlined, size: 18),
            label: Text(cta),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
              side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        if (onStartWorkoutWithEquipment != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onStartWorkoutWithEquipment,
            icon: const Icon(Icons.flash_on_outlined, size: 18),
            label: Text(AppLocalizations.of(context).equipmentMatchCardStartAWorkoutWith),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildMatchRows(
    BuildContext context,
    ThemeColors colors,
    List<Map<String, dynamic>> matches,
  ) {
    return [
      for (final match in matches.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _MatchRow(
            match: match,
            colors: colors,
            onTap: () => onMatchTap(match),
          ),
        ),
      if (onStartWorkoutWithEquipment != null) ...[
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onStartWorkoutWithEquipment,
          icon: const Icon(Icons.flash_on_outlined, size: 16),
          label: Text(AppLocalizations.of(context).equipmentMatchCardStartAWorkoutWith),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.cyan,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    ];
  }
}

class _MatchRow extends StatelessWidget {
  final Map<String, dynamic> match;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _MatchRow({
    required this.match,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = match['image_url'] as String?;
    final name = (match['name'] as String?) ?? 'Exercise';
    final muscle = match['primary_muscle'] as String?;
    final badge = match['badge'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(colors),
                      )
                    : _placeholder(colors),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (muscle != null && muscle.isNotEmpty)
                    Text(
                      muscle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  if (badge != null && badge.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).nextSetPreviewUse,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeColors colors) {
    return Container(
      color: colors.isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.04),
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center_outlined,
        size: 20,
        color: colors.textMuted,
      ),
    );
  }
}
