/// Adapter for **F12 — Zealova Score + percentile** share card.
///
/// Deterministic, zero-AI: reuses the EXISTING Discover leaderboard percentile
/// (`DiscoverSnapshot.yourPercentile`, the same value that powers the Discover
/// hero) plus the viewer's tier / rank / weekly metric. A small pure function
/// folds those into a 0–100 composite "Zealova Score". No new backend, no LLM.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart';
import '../../data/models/discover_snapshot.dart';
import '../../data/providers/discover_provider.dart';
import '../shareable_data.dart';

/// Folds the Discover percentile + tier into a 0–100 composite score. Pure:
/// the same inputs always produce the same score, so a re-share is free.
///
/// The percentile is the spine (it already ranks the viewer against everyone on
/// the board); the tier adds a small floor so an Elite/Legendary athlete on a
/// thin board never reads artificially low.
int zealovaScoreFrom(DiscoverSnapshot s) {
  final pct = s.yourPercentile.clamp(0.0, 100.0);
  final tierFloor = switch (s.yourTier.toLowerCase()) {
    'legendary' => 92.0,
    'top' => 85.0,
    'elite' => 75.0,
    'rising' => 60.0,
    'active' => 40.0,
    _ => 0.0,
  };
  return (pct > tierFloor ? pct : (pct + tierFloor) / 2).round().clamp(0, 100);
}

/// "stronger than X% of athletes your age" — the share's percentile line.
/// Uses the percentile directly (it already means "you beat X% of the board").
int strongerThanPercent(DiscoverSnapshot s) =>
    s.yourPercentile.clamp(0.0, 100.0).round();

class ZealovaScoreAdapter {
  /// Builds the Zealova-Score [Shareable] from the live Discover snapshot.
  /// Returns null when the viewer isn't ranked yet (no honest percentile to
  /// brag about) — the share sheet then declines to offer the card.
  static Future<Shareable?> fromProviders(WidgetRef ref) async {
    final snap = ref.read(discoverSnapshotProvider).asData?.value;
    if (snap == null) return null;
    // Not ranked / no percentile → nothing honest to share.
    if (snap.yourRank <= 0 && snap.yourPercentile <= 0) return null;

    final score = zealovaScoreFrom(snap);
    final stronger = strongerThanPercent(snap);
    final user = ref.read(currentUserProvider).asData?.value;
    final name = user?.name;

    final tierLabel = snap.yourTier.isNotEmpty
        ? snap.yourTier[0].toUpperCase() + snap.yourTier.substring(1)
        : 'Athlete';

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'TIER',
        value: tierLabel,
        icon: Icons.workspace_premium_rounded,
      ),
      ShareableMetric(
        label: 'RANK',
        value: snap.yourRank > 0 ? '#${snap.yourRank}' : '—',
        icon: Icons.leaderboard_rounded,
      ),
      ShareableMetric(
        label: 'STRONGER THAN',
        value: '$stronger%',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return Shareable(
      kind: ShareableKind.workoutComplete,
      title: 'Zealova Score',
      periodLabel: 'THIS WEEK',
      heroValue: score,
      heroUnitSingular: '',
      highlights: highlights,
      rank: tierLabel,
      currentStreak: snap.yourTierStreakWeeks,
      // The percentile + score travel as sub-metrics so the card preset can
      // read them without inventing new Shareable fields.
      subMetrics: [
        ShareableMetric(label: 'PERCENTILE', value: '$stronger'),
        ShareableMetric(label: 'SCORE', value: '$score'),
      ],
      userDisplayName: name,
      accentColor: const Color(0xFFD8FF3A), // volt-lime signature
    );
  }
}
