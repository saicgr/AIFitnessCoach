import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/personal_bests_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// 3-tile grid of Personal Bests (Heaviest Lift / Longest Session / Most
/// Volume). Each tile renders either real data from `PersonalBests` or a
/// muted "No data" placeholder — never a blank grid.
class PersonalBestsGrid extends StatelessWidget {
  final PersonalBests? data;
  final bool loading;

  const PersonalBestsGrid({
    super.key,
    required this.data,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <_PbTileData>[
      _buildHeaviestTile(l10n, data?.heaviestLift),
      _buildLongestTile(l10n, data?.longestSession),
      _buildVolumeTile(l10n, data?.mostVolume),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => _PbTile(
        data: tiles[i],
        loading: loading,
      ),
    );
  }

  _PbTileData _buildHeaviestTile(AppLocalizations l10n, HeaviestLift? hl) {
    if (hl == null || hl.weightLb <= 0) {
      return _PbTileData(
        label: l10n.personalBestsGridHeaviestLift,
        emoji: '💪',
        primary: null,
        secondary: null,
      );
    }
    return _PbTileData(
      label: l10n.personalBestsGridHeaviestLift,
      emoji: '💪',
      primary: '${hl.weightLb.toStringAsFixed(hl.weightLb % 1 == 0 ? 0 : 1)} lb'
          '${hl.reps > 0 ? ' × ${hl.reps}' : ''}',
      secondary: _composeSecondary(hl.exerciseName, hl.date),
    );
  }

  _PbTileData _buildLongestTile(AppLocalizations l10n, LongestSession? ls) {
    if (ls == null || ls.durationMinutes <= 0) {
      return _PbTileData(
        label: l10n.personalBestsGridLongestSession,
        emoji: '⏱️',
        primary: null,
        secondary: null,
      );
    }
    final minutes = ls.durationMinutes;
    final primary = minutes >= 60
        ? '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)}h'
        : '${minutes}m';
    return _PbTileData(
      label: l10n.personalBestsGridLongestSession,
      emoji: '⏱️',
      primary: primary,
      secondary: _composeSecondary(ls.workoutName, ls.date),
    );
  }

  _PbTileData _buildVolumeTile(AppLocalizations l10n, MostVolume? mv) {
    if (mv == null || mv.totalVolumeLb <= 0) {
      return _PbTileData(
        label: l10n.personalBestsGridMostVolume,
        emoji: '📈',
        primary: null,
        secondary: null,
      );
    }
    final v = mv.totalVolumeLb;
    final primary = v >= 10000
        ? '${(v / 1000).toStringAsFixed(v >= 100000 ? 0 : 1)}k lb'
        : '${v.toStringAsFixed(0)} lb';
    return _PbTileData(
      label: l10n.personalBestsGridMostVolume,
      emoji: '📈',
      primary: primary,
      secondary: _composeSecondary(mv.workoutName, mv.date),
    );
  }

  static String? _composeSecondary(String name, String? date) {
    final d = _formatDateShort(date);
    if (name.isEmpty && d == null) return null;
    if (d == null) return name;
    if (name.isEmpty) return d;
    return '$name · $d';
  }

  static String? _formatDateShort(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}


class _PbTileData {
  final String label;
  final String emoji;
  final String? primary;   // null → "No data" state
  final String? secondary; // null when empty

  const _PbTileData({
    required this.label,
    required this.emoji,
    required this.primary,
    required this.secondary,
  });

  bool get hasData => primary != null;
}


class _PbTile extends StatelessWidget {
  final _PbTileData data;
  final bool loading;

  const _PbTile({
    required this.data,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (data.hasData)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x52FBBF24), // gold @ 32%
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.72],
                      ),
                    ),
                  ),
                Opacity(
                  opacity: data.hasData ? 1.0 : 0.4,
                  child: Text(data.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(9, color: textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              loading
                  ? '…'
                  : (data.primary ?? AppLocalizations.of(context)!.unifiedHomeWidgetsNoData),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: data.hasData
                  ? ZType.disp(15, color: textPrimary)
                  : TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          if (data.secondary != null) ...[
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                data.secondary!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textMuted, fontSize: 9, height: 1.2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
