import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Menu Analysis sheet — already worked before
/// this refactor; lifted into its own class for consistency.
class MenuAnalysisTour {
  MenuAnalysisTour._();

  static const id = TooltipIds.menuAnalysis;

  // TODO(i18n): static method — no BuildContext available.
  // Refactor to instance method accepting BuildContext to enable l10n.
  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.swap_vert_rounded,
          title: 'Sort the whole menu',
          body:
              'Tap Protein, Carbs, Fat, or Inflammation to re-rank every dish at once. More… opens advanced sort.',
          targetKey: TooltipAnchors.menuAnalysisSortRow,
          targetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.tune_rounded,
          title: 'Filter by diet & allergens',
          body:
              'Hide dishes that don\'t fit your diet or contain your allergens — your preferences carry over from Settings.',
          targetKey: TooltipAnchors.menuAnalysisFilter,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.auto_awesome_rounded,
          title: 'Recommended for you',
          body:
              'AI picks the best three dishes against your remaining macros, allergens, and inflammation tolerance.',
          targetKey: TooltipAnchors.menuAnalysisRecommended,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 16,
        ),
        EmptyStateTip(
          icon: Icons.add_circle_outline_rounded,
          title: 'Select dishes to log',
          body:
              'Tick the dishes you actually ordered, then hit Log to send them to your daily totals.',
          targetKey: TooltipAnchors.menuAnalysisSelectFooter,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
      ];

  /// Mount the tour on the Menu Analysis sheet.
  ///
  /// The sheet body is hosted inside a `GlassSheet` whose `Stack` does NOT
  /// start at the top of the device — it floats some way down the screen.
  /// If the `EmptyStateTipTour` were dropped directly into that `Stack`
  /// (the old `Positioned.fill` form), the tour's card-placement logic —
  /// which reasons in full-screen `MediaQuery` coordinates — would push a
  /// card near the sheet's top edge *outside* the sheet bounds, where it
  /// was clipped.
  ///
  /// `_MenuAnalysisTourHost` instead inserts the tour into the root
  /// `Overlay`, so the tour's `RenderBox` fills the whole screen. Its
  /// origin is then (0, 0), which makes the screen-global rect math in
  /// `EmptyStateTipTour._resolveTargetRect` line up exactly with
  /// `MediaQuery` — the spotlight cutout stays aligned with the anchored
  /// widgets, and cards are no longer clipped by the sheet.
  static Widget overlay() => const _MenuAnalysisTourHost();
}

/// Zero-size widget that mounts the Menu Analysis [EmptyStateTipTour] into
/// the root [Overlay] for its lifetime, then tears it down on dispose.
///
/// Rendering through the root overlay (rather than as a `Positioned.fill`
/// child of the `GlassSheet` `Stack`) gives the tour a full-screen
/// coordinate space that matches `MediaQuery`, fixing top-edge clipping of
/// cards anchored near the sheet's upper border.
class _MenuAnalysisTourHost extends StatefulWidget {
  const _MenuAnalysisTourHost();

  @override
  State<_MenuAnalysisTourHost> createState() => _MenuAnalysisTourHostState();
}

class _MenuAnalysisTourHostState extends State<_MenuAnalysisTourHost> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // `rootOverlay: true` ensures we land on the app-level Overlay, above
      // the GlassSheet's route, so the tour fills the entire screen.
      final overlay = Overlay.of(context, rootOverlay: true);
      final entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: EmptyStateTipTour(
            tourId: MenuAnalysisTour.id,
            tips: _menuAnalysisTips,
            // No main nav bar — Menu Analysis is a modal sheet.
            hasMainNavBar: false,
          ),
        ),
      );
      _entry = entry;
      overlay.insert(entry);
    });
  }

  @override
  void dispose() {
    // Remove the overlay entry when the sheet is dismissed so the tour
    // doesn't linger over whatever screen is underneath.
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Tips list hoisted to a top-level `const` so the [OverlayEntry] builder
/// (which runs outside `_MenuAnalysisTourHost`'s build) can reference it.
final List<EmptyStateTip> _menuAnalysisTips = MenuAnalysisTour.steps();
