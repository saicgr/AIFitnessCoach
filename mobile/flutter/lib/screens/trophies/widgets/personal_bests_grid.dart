import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/personal_bests_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tiles = <_PbTileData>[
      _buildHeaviestTile(data?.heaviestLift),
      _buildLongestTile(data?.longestSession),
      _buildVolumeTile(data?.mostVolume),
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
        isDark: isDark,
        loading: loading,
      ),
    );
  }

  _PbTileData _buildHeaviestTile(HeaviestLift? hl) {
    if (hl == null || hl.weightLb <= 0) {
      return const _PbTileData(
        label: 'Heaviest Lift',
        emoji: '💪',
        primary: null,
        secondary: null,
      );
    }
    return _PbTileData(
      label: 'Heaviest Lift',
      emoji: '💪',
      primary: '${hl.weightLb.toStringAsFixed(hl.weightLb % 1 == 0 ? 0 : 1)} lb'
          '${hl.reps > 0 ? ' × ${hl.reps}' : ''}',
      secondary: _composeSecondary(hl.exerciseName, hl.date),
    );
  }

  _PbTileData _buildLongestTile(LongestSession? ls) {
    if (ls == null || ls.durationMinutes <= 0) {
      return const _PbTileData(
        label: 'Longest Session',
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
      label: 'Longest Session',
      emoji: '⏱️',
      primary: primary,
      secondary: _composeSecondary(ls.workoutName, ls.date),
    );
  }

  _PbTileData _buildVolumeTile(MostVolume? mv) {
    if (mv == null || mv.totalVolumeLb <= 0) {
      return const _PbTileData(
        label: 'Most Volume',
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
      label: 'Most Volume',
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
  final bool isDark;
  final bool loading;

  const _PbTile({
    required this.data,
    required this.isDark,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.hasData
                  ? const RadialGradient(
                      colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                    )
                  : null,
              color: data.hasData
                  ? null
                  : (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
            ),
            child: Center(
              child: Opacity(
                opacity: data.hasData ? 1.0 : 0.5,
                child: Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              loading
                  ? '…'
                  : (data.primary ?? 'No data'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.hasData ? textPrimary : textMuted,
                fontSize: data.hasData ? 12 : 10,
                fontWeight:
                    data.hasData ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          if (data.secondary != null) ...[
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                data.secondary!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
