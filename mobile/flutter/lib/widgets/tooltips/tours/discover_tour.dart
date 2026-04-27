import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Discover screen — 3 steps, each spotlighting
/// a real surface (Rising Stars, Near You, board-tabs) so the user
/// knows what each thing does without reading floating prose.
///
/// Replaces the legacy inline `EmptyStateTipTour(...)` that used to be
/// declared in `discover_screen.dart` without `targetKey`s, which is
/// why the original tour rendered as a passive bottom banner with no
/// dim layer / cutout.
class DiscoverTour {
  DiscoverTour._();

  static const id = TooltipIds.discover;

  /// The 3 spotlight steps. Anchored on `TooltipAnchors.discover*`.
  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.travel_explore_rounded,
          title: 'Find your peers',
          body:
              'Browse Rising Stars and Near You to see who\'s training at your level.',
          targetKey: TooltipAnchors.discoverRisingStars,
          targetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          targetRadius: 16,
        ),
        EmptyStateTip(
          icon: Icons.compare_arrows_rounded,
          title: 'Tap any user',
          body:
              'Open their 6-axis fitness radar and see how you stack up across XP, volume, streaks, and more.',
          targetKey: TooltipAnchors.discoverNearYou,
          targetPadding: const EdgeInsets.all(8),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.swap_horiz_rounded,
          title: 'Switch boards',
          body:
              'XP / Volume / Streaks each rank a different game — try them all to find your strongest axis.',
          targetKey: TooltipAnchors.discoverBoardTabs,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
      ];

  /// Drop into the screen's root `Stack` as a `Positioned.fill` child.
  /// `Positioned.fill` is required so the painter's dim/cutout cover
  /// the entire screen — `Positioned(bottom: 90)` (the legacy form)
  /// clipped the painter to a thin bottom strip and broke the
  /// spotlight effect.
  static Widget overlay() => Positioned.fill(
        child: SafeArea(
          top: false,
          child: EmptyStateTipTour(tourId: id, tips: steps()),
        ),
      );
}
