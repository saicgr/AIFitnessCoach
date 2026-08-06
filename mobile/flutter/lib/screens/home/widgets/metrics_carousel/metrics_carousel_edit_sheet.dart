/// Two-level `GlassSheet` for customising the Home metrics carousel.
///
/// Level 1 — which pages (drag-to-reorder, toggle each, `›` opens level 2
/// for pages with a configurable stat strip). Level 2 — that page's slots
/// (drag-to-reorder, toggle each, capped at 4/6).
///
/// Drag-to-reorder is mandatory here, not a nice-to-have — Google shipped
/// remove-then-re-add for the equivalent Google Health Connect surface, was
/// publicly criticised for it (3,400-vote "bring back the old app" thread),
/// and is patching it post-launch. This sheet ships with real
/// `ReorderableListView` drag from day one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/metrics_carousel_prefs.dart';
import '../../../../data/providers/metrics_carousel_prefs_provider.dart';
import '../../../../data/services/health_service.dart';
import '../../../../widgets/glass_sheet.dart';

Future<void> showCarouselEditSheet(BuildContext context) {
  return showGlassSheet(
    context: context,
    builder: (ctx) => const GlassSheet(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: _CarouselEditSheetContent(),
    ),
  );
}

/// Pages whose card has a real configurable stat strip today — only these
/// get a `›` into level 2. The others (Volume trend's chart, Recovery's
/// sleep+readiness, the two coming-soon pages) have nothing to reorder, so a
/// `›` for them would open an empty screen — omitted rather than faked.
const Set<CarouselPageId> _kConfigurablePages = {CarouselPageId.training};

class _CarouselEditSheetContent extends ConsumerStatefulWidget {
  const _CarouselEditSheetContent();

  @override
  ConsumerState<_CarouselEditSheetContent> createState() =>
      _CarouselEditSheetContentState();
}

class _CarouselEditSheetContentState
    extends ConsumerState<_CarouselEditSheetContent> {
  CarouselPageId? _openPage;

  @override
  Widget build(BuildContext context) {
    final openPage = _openPage;
    if (openPage != null) {
      return _SlotsLevel(
        pageId: openPage,
        onBack: () => setState(() => _openPage = null),
      );
    }
    return _PagesLevel(
      onOpenSlots: (id) => setState(() => _openPage = id),
    );
  }
}

// ---------------------------------------------------------------------------
// Level 1 — pages
// ---------------------------------------------------------------------------

class _PagesLevel extends ConsumerWidget {
  final void Function(CarouselPageId) onOpenSlots;
  const _PagesLevel({required this.onOpenSlots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final prefs = ref.watch(metricsCarouselPrefsProvider);
    final healthConnected = ref.watch(healthSyncProvider).isConnected;
    // NOT a bare `enabled` sum (E2E row 136) — the carousel itself drops
    // Recovery whenever Health isn't connected (metrics_carousel_prefs.dart),
    // so an enabled-but-unconnected Recovery toggle here must not count
    // toward "N shown" or this header disagrees with the carousel's own
    // "x of y" page counter.
    final shownCount = prefs.pages
        .where((p) =>
            p.enabled &&
            !(p.id == CarouselPageId.recovery && !healthConnected))
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text('CUSTOMISE CAROUSEL', style: ZType.data(11, color: c.textMuted)),
              const Spacer(),
              Text('$shownCount shown', style: ZType.data(10, color: c.textMuted)),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: prefs.pages.length,
          onReorder: (oldIndex, newIndex) =>
              ref.read(metricsCarouselPrefsProvider.notifier).reorderPages(oldIndex, newIndex),
          itemBuilder: (context, i) {
            final page = prefs.pages[i];
            final isRecovery = page.id == CarouselPageId.recovery;
            final recoveryNeedsConnect = isRecovery && !healthConnected;
            return Padding(
              key: ValueKey(page.id),
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 11),
                      child: Icon(Icons.drag_indicator, size: 18, color: c.textMuted.withValues(alpha: 0.5)),
                    ),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: recoveryNeedsConnect ? 0.62 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(page.id.title,
                                style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: c.textPrimary)),
                            const SizedBox(height: 2),
                            Text(_subtitleFor(page), style: TextStyle(fontSize: 11, color: c.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_kConfigurablePages.contains(page.id))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => onOpenSlots(page.id),
                        child: Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                      ),
                    ),
                  if (recoveryNeedsConnect)
                    _ConnectCta(onTap: () => context.push('/settings/health-devices'))
                  else
                    _EditSheetToggle(
                      value: page.enabled,
                      onChanged: (v) =>
                          ref.read(metricsCarouselPrefsProvider.notifier).togglePage(page.id, v),
                    ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Up to $kCarouselMaxPages pages. Past that it stops being a glance.',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subtitleFor(CarouselPageConfig page) {
    switch (page.id) {
      case CarouselPageId.training:
        return 'Ring · ${page.slots.length} metric${page.slots.length == 1 ? '' : 's'}';
      case CarouselPageId.volumeTrend:
        return '8 weeks · 1 metric';
      case CarouselPageId.muscleBalance:
        return page.id.subtitle;
      case CarouselPageId.prLadder:
        return page.id.subtitle;
      case CarouselPageId.recovery:
        return page.id.subtitle;
    }
  }
}

// ---------------------------------------------------------------------------
// Level 2 — slots (Training only, today)
// ---------------------------------------------------------------------------

class _SlotsLevel extends ConsumerWidget {
  final CarouselPageId pageId;
  final VoidCallback onBack;
  const _SlotsLevel({required this.pageId, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final prefs = ref.watch(metricsCarouselPrefsProvider);
    final page = prefs.pages.firstWhere((p) => p.id == pageId);
    final healthConnected = ref.watch(healthSyncProvider).isConnected;
    final notifier = ref.read(metricsCarouselPrefsProvider.notifier);

    final selected = page.slots;
    final unselected = [
      for (final s in CarouselSlotId.values)
        if (!selected.contains(s)) s,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: onBack,
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, size: 18, color: c.textMuted),
                    Text(pageId.title,
                        style: ZType.data(11, color: c.textMuted)),
                  ],
                ),
              ),
              const Spacer(),
              Text('${selected.length} of ${page.maxSlots} slots',
                  style: ZType.data(10, color: c.textMuted)),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Ring shows sessions this week — fixed',
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: selected.length,
          onReorder: (oldIndex, newIndex) =>
              notifier.reorderSlots(pageId, oldIndex, newIndex),
          itemBuilder: (context, i) {
            final slot = selected[i];
            return Padding(
              key: ValueKey(slot),
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 11),
                      child: Icon(Icons.drag_indicator, size: 18, color: c.textMuted.withValues(alpha: 0.5)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(slot.label,
                          style: TextStyle(
                              fontFamily: 'Archivo',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: c.textPrimary)),
                    ),
                  ),
                  _EditSheetToggle(
                    value: true,
                    onChanged: (_) => notifier.toggleSlot(pageId, slot, false),
                  ),
                ],
              ),
            );
          },
        ),
        if (unselected.isNotEmpty) ...[
          const Divider(height: 20),
          // E2E row 192 — at the slot cap, `toggleSlot`'s own guard
          // (metrics_carousel_prefs_provider.dart) silently no-ops rather
          // than enabling a slot past `maxSlots`, but every remaining row
          // still rendered as a live, full-opacity switch — tapping did
          // nothing with no toast, no hint, no disabled styling. Mirror the
          // "Needs Health" treatment below: dim + genuinely disable, don't
          // leave a control that looks live but silently refuses.
          for (final slot in unselected)
            _UnselectedSlotRow(
              slot: slot,
              needsHealthGate: slot.needsHealth && !healthConnected,
              atCap: selected.length >= page.maxSlots,
              maxSlots: page.maxSlots,
              c: c,
              onConnectHealth: () => context.push('/settings/health-devices'),
              onEnable: (_) => notifier.toggleSlot(pageId, slot, true),
            ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${page.maxSlots} slots max at this card height.',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
              // E2E row 193 — this used to be one-way (only ever called
              // with `true`, no way back once tapped). `setTall` itself
              // always took a plain bool, so the fix is just offering the
              // reverse link when already tall.
              if (!page.tall)
                InkWell(
                  onTap: () => notifier.setTall(pageId, true),
                  child: Text(
                    'Make the card taller ›',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accent),
                  ),
                )
              else
                InkWell(
                  onTap: () async {
                    await notifier.setTall(pageId, false);
                    // Slots enabled at the tall 6-slot cap don't auto-trim
                    // when the cap drops back to 4 — `toggleSlot`'s cap
                    // guard only blocks enabling past the cap, so an
                    // over-cap slot list would otherwise just sit there,
                    // silently overflowing the short card's stat strip.
                    // Re-read the post-setTall state (not the stale
                    // `page`/`selected` this closure captured) and disable
                    // the trailing excess.
                    final current = ref
                        .read(metricsCarouselPrefsProvider)
                        .pages
                        .firstWhere((p) => p.id == pageId);
                    final excess =
                        current.slots.length - kCarouselMaxSlotsNormal;
                    if (excess > 0) {
                      for (final slot
                          in current.slots.reversed.take(excess)) {
                        await notifier.toggleSlot(pageId, slot, false);
                      }
                    }
                  },
                  child: Text(
                    'Make it shorter ›',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accent),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row controls
// ---------------------------------------------------------------------------

/// One row for an unselected (off) slot in [_SlotsLevel] — dims + disables
/// itself when unavailable, either because it needs a Health connection or
/// (E2E row 192) because the page is already at its slot cap.
class _UnselectedSlotRow extends StatelessWidget {
  final CarouselSlotId slot;
  final bool needsHealthGate;
  final bool atCap;
  final int maxSlots;
  final ThemeColors c;
  final VoidCallback onConnectHealth;
  final ValueChanged<bool> onEnable;

  const _UnselectedSlotRow({
    required this.slot,
    required this.needsHealthGate,
    required this.atCap,
    required this.maxSlots,
    required this.c,
    required this.onConnectHealth,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: needsHealthGate || atCap ? 0.55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slot.label,
                      style: TextStyle(
                          fontFamily: 'Archivo',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: c.textPrimary)),
                  if (needsHealthGate)
                    Text('Needs Health',
                        style: TextStyle(fontSize: 11, color: c.textMuted))
                  else if (atCap)
                    Text('$maxSlots slot limit reached',
                        style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
          ),
          if (needsHealthGate)
            _ConnectCta(onTap: onConnectHealth)
          else
            _EditSheetToggle(
              value: false,
              onChanged: atCap ? null : onEnable,
            ),
        ],
      ),
    );
  }
}

class _EditSheetToggle extends StatelessWidget {
  final bool value;
  /// Nullable so a slot row at the max-slots cap can render a genuinely
  /// disabled (non-interactive, greyed) switch instead of a live-looking
  /// one that silently no-ops on tap (E2E row 192).
  final ValueChanged<bool>? onChanged;
  const _EditSheetToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.accent,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ConnectCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ConnectCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.accent.withValues(alpha: 0.5)),
        ),
        child: Text('Connect', style: ZType.data(9, color: c.accent)),
      ),
    );
  }
}
