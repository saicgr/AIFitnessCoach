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
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive loads for data this widget needs that isn't already fetched
    // elsewhere on Home (prStats, the 8-week volume series). Both providers
    // guard their own in-flight/freshness state, so calling every build is a
    // cheap no-op after the first successful load.
    final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
    ensureTrainingWeekStatsLoaded(ref, userId);
    // Touch the 8-week volume provider so it's requested even before the
    // Training/Volume-trend card builds (both read it via computed
    // providers, but a plain `ref.watch` on the underlying data provider
    // ensures the fetch kicks off exactly once here).
    ref.watch(volumeProgressionProvider);

    final prefs = ref.watch(metricsCarouselPrefsProvider);
    final recovery = ref.watch(recoverySnapshotProvider);
    final pages = visibleCarouselPages(prefs, recoveryAvailable: recovery.isAvailable);

    if (pages.isEmpty) return const SizedBox.shrink();

    if (_index >= pages.length) _index = pages.length - 1;

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
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final pageId = pages[i];
            final config = prefs.pages.firstWhere((p) => p.id == pageId);
            return Align(
              alignment: Alignment.topLeft,
              child: CarouselCardShell(
                pageIndex: i,
                pageCount: pages.length,
                tall: config.tall,
                isPlaceholder: !pageId.hasBuiltCard,
                onEdit: () => showCarouselEditSheet(context),
                child: _buildPageBody(pageId, config),
              ),
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
        return const ComingSoonCard(
          title: 'Muscle balance',
          subtitle: 'Coming soon — needs 3+ muscle\ngroups trained to compare.',
        );
      case CarouselPageId.prLadder:
        return const ComingSoonCard(
          title: 'PR ladder',
          subtitle: 'Coming soon — estimated 1RM\nprogress over time.',
        );
    }
  }
}
