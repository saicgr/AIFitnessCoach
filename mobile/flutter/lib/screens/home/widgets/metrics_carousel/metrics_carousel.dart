/// Home metrics carousel — replaces the static `HomeWeekGlanceBand` (register
/// #176 change 3) with a swipeable, user-configurable set of metric cards.
/// Mount point in `home_screen.dart` is unchanged: directly under
/// `MinimalHeader`, before the banner stack.
///
/// See the approved spec: `docs/planning/mockups/graphs.html` (rendered
/// cards, edit-sheet, build-spec table) for the full design rationale — this
/// file wires that spec to real providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/metrics_carousel_prefs.dart';
import '../../../../data/providers/metrics_carousel_data_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/providers/metrics_carousel_prefs_provider.dart';
import 'metrics_carousel_cards.dart';
import 'metrics_carousel_edit_sheet.dart';
import '../home/unified_home_widgets.dart' show kHomeHPad;

class MetricsCarousel extends ConsumerStatefulWidget {
  const MetricsCarousel({super.key});

  @override
  ConsumerState<MetricsCarousel> createState() => _MetricsCarouselState();
}

class _MetricsCarouselState extends ConsumerState<MetricsCarousel> {
  final PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    // Kick the loads this carousel needs ONCE, after the first frame.
    //
    // This used to sit in build(). ScoresState carries readiness and prStats in
    // one object, so the PR write notified the readiness providers this widget
    // watches -> rebuild -> another load: 255 req/min from an idle Home screen.
    // The notifier now guards re-entry too, but a network call still does not
    // belong in build() — build must be pure and can run any number of times.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ensureTrainingWeekStatsLoaded(ref, ref.read(authStateProvider).user?.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-kick the PR load when the ACCOUNT changes (initState covers the first
    // load). `ref.listen` is the sanctioned place for a side effect that
    // reacts to a provider — calling it directly in build is what produced the
    // request loop this widget shipped with.
    ref.listen(authStateProvider.select((s) => s.user?.id), (prev, next) {
      if (next != null && next != prev) ensureTrainingWeekStatsLoaded(ref, next);
    });
    // Touch the 8-week volume provider so it's requested even before the
    // Training/Volume-trend card builds (both read it via computed
    // providers). This one is a FutureProvider — watching it is idempotent.
    ref.watch(volumeProgressionProvider);

    final prefs = ref.watch(metricsCarouselPrefsProvider);
    final recovery = ref.watch(recoverySnapshotProvider);
    final pages = visibleCarouselPages(prefs, recoveryAvailable: recovery.isAvailable);

    if (pages.isEmpty) return const SizedBox.shrink();

    final trainingConfig =
        prefs.pages.where((p) => p.id == CarouselPageId.training).firstOrNull;
    final viewportHeight = (trainingConfig?.tall ?? false) &&
            pages.contains(CarouselPageId.training)
        ? kCarouselCardHeightTall
        : kCarouselCardHeightNormal;

    return Padding(
      padding: kHomeHPad,
      child: SizedBox(
        height: viewportHeight,
        child: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          itemBuilder: (context, i) {
            final pageId = pages[i];
            final config = prefs.pages.firstWhere((p) => p.id == pageId);
            // NOT wrapped in `Align(topLeft, ...)` — that gave the shell
            // loose constraints so it shrink-wrapped to its old fixed
            // `kCarouselCardWidth`, leaving the item slot's real width
            // (device width minus `kHomeHPad`) unused on the right (E2E row
            // 137). `CarouselCardShell` now fills whatever tight width
            // PageView's viewport slot hands it, same as every other Home
            // card between which it sits.
            return CarouselCardShell(
              pageIndex: i,
              pageCount: pages.length,
              tall: config.tall,
              isPlaceholder: !pageId.hasBuiltCard,
              onEdit: () => showCarouselEditSheet(context),
              child: _buildPageBody(pageId, config),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageBody(CarouselPageId pageId, CarouselPageConfig config) {
    switch (pageId) {
      case CarouselPageId.training:
        final stats = ref.watch(trainingWeekStatsProvider);
        return TrainingCard(stats: stats, slots: config.slots, tall: config.tall);
      case CarouselPageId.volumeTrend:
        final data = ref.watch(volumeTrendSnapshotProvider);
        return VolumeTrendCard(data: data);
      case CarouselPageId.recovery:
        final data = ref.watch(recoverySnapshotProvider);
        return RecoveryCard(data: data);
      case CarouselPageId.muscleBalance:
        // Unconditional placeholder — no provider backs this page at all
        // (unlike training/volumeTrend/recovery above, which each watch a
        // real one). The old copy ("needs 3+ muscle groups trained to
        // compare") implied a data-readiness gate that would clear once the
        // user trained enough; it doesn't — E2E row 135 found an account
        // that already had 3 muscle groups logged still stuck here. Say
        // plainly that the feature isn't built yet, not a false precondition.
        return const ComingSoonCard(
          title: 'Muscle balance',
          subtitle: "Coming soon — we're building\nmuscle-group comparison.",
        );
      case CarouselPageId.prLadder:
        return const ComingSoonCard(
          title: 'PR ladder',
          subtitle: 'Coming soon — estimated 1RM\nprogress over time.',
        );
    }
  }
}
