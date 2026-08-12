/// Health tab — branch root for `/health` (2026-08 nav redesign).
///
/// Coach gives up the centre bottom-nav slot and Health takes it, so the three
/// homeless domains (sleep, recovery, body) finally get a top-level home. This
/// screen is the hub: a masthead, a health-source chip, and **the only rail in
/// the app** — OVERVIEW · SLEEP · RECOVERY · VITALS · BODY.
///
/// ## It composes, it does not re-implement
///
/// Every chip renders a screen that already shipped, in `embedded: true` mode
/// (drops that screen's own back-button header + opaque background; the body is
/// byte-identical):
///
///   | chip     | screen                       | why                            |
///   |----------|------------------------------|--------------------------------|
///   | Overview | `CombinedHealthScreen`       | the hub: recovery hero, activity streak, vitals/heart/fitness cards |
///   | Sleep    | `SleepDetailScreen`          | hypnogram, sleep score, debt    |
///   | Recovery | `HeartHealthDetailScreen`    | the fused 0-100 recovery/cardio-habit score and its four drivers |
///   | Vitals   | `VitalsDetailScreen`         | five overnight signals vs personal baseline |
///   | Body     | `FitnessIndexDetailScreen`   | the 5-axis index whose first axis IS body composition |
///
/// Recovery and Body have no 1:1 screen of their own — the mockup folds Heart
/// Health under recovery and body composition under Body, and those are the
/// screens that own that data today. Nothing was rewritten to make the mapping
/// fit.
///
/// ## Back-stack: the detail routes deliberately did NOT move
///
/// `/health/combined`, `/health/sleep`, `/health/vitals`, `/health/heart-health`
/// and `/health/fitness-index` stay registered as TOP-LEVEL routes
/// (`app_router_utility_routes.dart`), exactly where they were. ~23 call sites
/// across Home, Nutrition, You, chat and notifications `push` those paths and
/// rely on `GlassBackButton` popping back to *the screen they came from*.
/// Re-registering them inside this `StatefulShellBranch` would have switched
/// the active branch instead, leaving the previous tab behind in the
/// `IndexedStack` and stranding the user on a screen whose back button pops to
/// the Health root — or, on a cold push-notification deep link, no-ops.
///
/// So the branch owns exactly ONE path, `/health`, and the rail switches chips
/// with local state (`_index`) rather than navigation. Tapping a chip therefore
/// costs no route transition at all, and the pushed deep links keep their
/// current, correct pop behaviour. `/health?tab=sleep` is the deep link for the
/// *tab* view.
///
/// ## Honest empty states
///
/// No Health connection means none of these five screens has anything to draw,
/// so each chip renders a LABELLED empty state naming the view the user is on
/// plus the Connect Health CTA (which Home no longer carries) — never a wall of
/// blanks. Connected-but-empty is gated per chip against that chip's own
/// payload, except Vitals, which already degrades per-signal ("No data" capsule
/// per bio-signal) and is left alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/chrome_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/health_tab_request_provider.dart';
import '../../data/repositories/fitness_index_repository.dart';
import '../../data/repositories/heart_health_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/health_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cardio/fitness_index_detail_screen.dart';
import 'widgets/health_chrome.dart';
import 'combined_health_screen.dart';
import 'heart_health_detail_screen.dart';
import 'sleep_detail_screen.dart';
import 'vitals_detail_screen.dart';

/// The five rail chips, in rail order. [slug] is what `/health?tab=` accepts.
enum HealthSubTab {
  overview('overview'),
  sleep('sleep'),
  recovery('recovery'),
  vitals('vitals'),
  body('body');

  const HealthSubTab(this.slug);

  /// Query-parameter value that selects this chip.
  final String slug;

  /// Resolve a `?tab=` value (slug or bare index) to a chip. Unknown values
  /// fall back to Overview rather than throwing — a stale deep link should
  /// land on the hub, not a 404.
  static HealthSubTab fromParam(String? raw) {
    if (raw == null || raw.isEmpty) return HealthSubTab.overview;
    for (final t in HealthSubTab.values) {
      if (t.slug == raw) return t;
    }
    final asIndex = int.tryParse(raw);
    if (asIndex != null && asIndex >= 0 && asIndex < HealthSubTab.values.length) {
      return HealthSubTab.values[asIndex];
    }
    return HealthSubTab.overview;
  }

  /// The chip's glyph. The mockup's rail is icon-over-label, not text-only:
  /// grid / moon / heart-pulse / pulse-line / person, 17 px, above a 5 px gap.
  /// The icon is what lets the label drop to 10 px without the rail becoming
  /// unscannable.
  IconData get icon {
    switch (this) {
      case HealthSubTab.overview:
        return Icons.grid_view_rounded;
      case HealthSubTab.sleep:
        return Icons.bedtime_outlined;
      case HealthSubTab.recovery:
        return Icons.monitor_heart_outlined;
      case HealthSubTab.vitals:
        return Icons.show_chart_rounded;
      case HealthSubTab.body:
        return Icons.person_outline;
    }
  }

  /// The chip's localised label. Every one of these strings already shipped
  /// translated in all 36 locales except Vitals, which is the one new key.
  String label(AppLocalizations l10n) {
    switch (this) {
      case HealthSubTab.overview:
        return l10n.youHubOverview;
      case HealthSubTab.sleep:
        return l10n.combinedHealthSleep;
      case HealthSubTab.recovery:
        return l10n.recoveryLabel;
      case HealthSubTab.vitals:
        return l10n.healthTabVitals;
      case HealthSubTab.body:
        return l10n.insightsScreenPartBody;
    }
  }
}

/// The screen a rail chip composes, always in `embedded: true` mode.
///
/// Public and pure so the rail's routing contract — chip N shows screen N —
/// is assertable without standing up five screens' worth of providers and
/// network. `_HealthSubTabView` calls this after its availability gates.
Widget healthSubTabScreen(HealthSubTab tab) {
  switch (tab) {
    case HealthSubTab.overview:
      return const CombinedHealthScreen(embedded: true);
    case HealthSubTab.sleep:
      return const SleepDetailScreen(embedded: true);
    case HealthSubTab.recovery:
      return const HeartHealthDetailScreen(embedded: true);
    case HealthSubTab.vitals:
      return const VitalsDetailScreen(embedded: true);
    case HealthSubTab.body:
      return const FitnessIndexDetailScreen(embedded: true);
  }
}

class HealthShellScreen extends ConsumerStatefulWidget {
  /// Chip to land on. Comes from `/health?tab=<slug>` on a cold entry; a warm
  /// entry (branch already alive in the IndexedStack) is driven by
  /// [healthTabRequestProvider] instead.
  final HealthSubTab initialTab;

  const HealthShellScreen({super.key, this.initialTab = HealthSubTab.overview});

  @override
  ConsumerState<HealthShellScreen> createState() => _HealthShellScreenState();
}

class _HealthShellScreenState extends ConsumerState<HealthShellScreen> {
  late int _index;

  /// Chips the user has actually opened. An `IndexedStack` builds every child,
  /// which would fire all five screens' providers (and their network reads) the
  /// moment the tab opens; unvisited chips render a zero-cost placeholder until
  /// first selection and are kept alive from then on, so switching back is
  /// instant and keeps its scroll position.
  late Set<int> _visited;

  /// Last honoured [HealthTabRequest.seq] — so the build-time listener moves
  /// the rail only on genuinely new requests, never on incidental rebuilds.
  int? _lastTabSeq;

  @override
  void initState() {
    super.initState();
    // Seed from a pending request if one was filed immediately before
    // navigation (avoids a visible Overview→Sleep sweep on a cold deep link).
    final pending = ref.read(healthTabRequestProvider);
    _lastTabSeq = pending?.seq;
    _index = (pending?.index ?? widget.initialTab.index)
        .clamp(0, HealthSubTab.values.length - 1);
    _visited = {_index};
  }

  void _select(int i) {
    if (i == _index) return;
    HapticService.light();
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  void _applyTabRequest(HealthTabRequest req) {
    if (req.seq == _lastTabSeq) return;
    _lastTabSeq = req.seq;
    final target = req.index.clamp(0, HealthSubTab.values.length - 1);
    if (target == _index) return;
    // Requests arrive from a router post-frame callback, so mutating state
    // synchronously here is safe (we are inside build's listener, which fires
    // outside the build phase for subsequent changes).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index = target;
        _visited.add(target);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HealthTabRequest?>(healthTabRequestProvider, (prev, next) {
      if (next != null) _applyTabRequest(next);
    });

    final tc = ThemeColors.of(context);
    final mq = MediaQuery.of(context);
    final sync = ref.watch(healthSyncProvider);
    final tabs = HealthSubTab.values;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HealthMasthead(isConnected: sync.isConnected),
            // The only rail in the app.
            //
            // Built here rather than from `ZealovaTextTabs` because this rail's
            // spec diverges from that widget in four ways the mockup is
            // explicit about — icon over label, a full-chip-width underline,
            // an ACCENT active label, and five chips distributed across the
            // content width — and `ZealovaTextTabs` is shared by 14 other
            // surfaces (stats, nutrition, skills, achievements, rewards,
            // leaderboard, injuries, streaks, progress) that must not inherit
            // any of it. Same tokens, local composition.
            //
            // No bottom padding and no sibling `Divider`: the rail draws its
            // OWN 1 px bottom hairline so the active chip's 2 px accent
            // underline rests directly on it (`.pillars{border-bottom}` +
            // `.pill-chip.on{border-bottom-color:var(--accent)}`) instead of
            // floating 10 px above a separate line.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: HealthRail(
                tabs: tabs,
                activeIndex: _index,
                onChanged: _select,
              ),
            ),
            Expanded(
              child: MediaQuery(
                // The floating nav pill AND the quick-log / coach cluster paint
                // over the bottom of this area. WIDENING `padding.bottom` by
                // the FAB clearance (adding to the device inset, never
                // replacing it — the cluster is itself positioned at
                // `paddingOf.bottom + kQuickLogFabBottomOffset`) makes each
                // composed screen's own `SafeArea` lift its scroll extent clear
                // of both. Same trick `CoachTabScreen` used for the chat
                // composer, and it needs no edit inside the five screens.
                data: MediaQuery.of(context).copyWith(
                  padding: mq.padding.copyWith(
                    bottom: mq.padding.bottom + kQuickLogFabClearance,
                  ),
                  viewPadding: mq.viewPadding.copyWith(
                    bottom: mq.viewPadding.bottom + kQuickLogFabClearance,
                  ),
                ),
                child: IndexedStack(
                  index: _index,
                  sizing: StackFit.expand,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      _visited.contains(i)
                          ? _HealthSubTabView(
                              tab: tabs[i],
                              isConnected: sync.isConnected,
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Font size of a rail chip's label. 10 (mockup: 9.5) — the 17 px glyph above
/// it carries the target size, so the label can be this quiet without the rail
/// becoming hard to scan. At 12.5 it read a full step louder than the mockup
/// and competed with the Anton masthead directly above it.
const double _kRailLabelSize = 10.0;

/// The Health rail — five icon-over-label chips on a shared hairline.
///
/// Public (rather than `_HealthRail`) so `test/navigation/health_tab_test.dart`
/// can read [activeIndex] off the built widget and assert which chip a cold
/// `initialTab` / a warm `healthTabRequestProvider` request actually selected —
/// the same handle the rail's previous `ZealovaTextTabs` implementation gave
/// those tests. Nothing outside this file constructs it.
///
/// Layout: `Row` of `Expanded` slots so the five chips SPAN the content width
/// (`.pill-chip{flex:1 0 auto}`), which is what stops the rail hugging the left
/// edge with dead space after BODY. Above ~1.3× text scale the labels can no
/// longer fit five-across, so it degrades to the horizontal scroll strip rather
/// than ellipsising navigation labels into uselessness — the same trade
/// `ZealovaTextTabs` documents.
class HealthRail extends StatelessWidget {
  final List<HealthSubTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const HealthRail({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final scaled = MediaQuery.textScalerOf(context).scale(_kRailLabelSize);
    final fitsFiveAcross = scaled <= _kRailLabelSize * 1.3;

    final chips = <Widget>[
      for (var i = 0; i < tabs.length; i++)
        _RailChip(
          tab: tabs[i],
          label: tabs[i].label(l10n),
          isActive: i == activeIndex,
          onTap: () => onChanged(i),
        ),
    ];

    return DecoratedBox(
      // The line the active chip's accent underline sits ON.
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tc.hairline, width: 1)),
      ),
      child: fitsFiveAcross
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (final c in chips) Expanded(child: c)],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final c in chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: c,
                    ),
                ],
              ),
            ),
    );
  }
}

class _RailChip extends StatelessWidget {
  final HealthSubTab tab;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RailChip({
    required this.tab,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // The ACTIVE label turns accent (`.pill-chip.on{color:var(--accent-text)}`)
    // — the underline is not the only cue, which also means the active chip
    // survives for a user who cannot resolve a 2 px line.
    final fg = isActive ? tc.accent : tc.textMuted;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 7),
            decoration: BoxDecoration(
              // The chip's OWN bottom border — full chip width, 2 px, drawn
              // immediately above the rail's hairline so the two meet.
              border: Border(
                bottom: BorderSide(
                  color: isActive ? tc.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 17, color: fg),
                const SizedBox(height: 5),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(
                    _kRailLabelSize,
                    color: fg,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "HEALTH" masthead + today's date, with the health-source chip on the right.
class _HealthMasthead extends ConsumerWidget {
  final bool isConnected;

  const _HealthMasthead({required this.isConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.combinedHealthHealth.toUpperCase(),
                  style: ZType.disp(24, color: tc.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase(),
                  style:
                      ZType.lbl(11, color: tc.textMuted, letterSpacing: 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HealthSourceChip(isConnected: isConnected),
          const SizedBox(width: 8),
          // The mockup's only masthead control is a 34 pt hairline gear; the
          // shipped chip is kept BESIDE it rather than replaced by it, because
          // the chip carries live state (disconnected / connected / syncing)
          // that a gear cannot express and that the tab's whole data story
          // depends on. The gear is the destination the mockup's own annotation
          // implies — real source management, not a decorative icon.
          HealthIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.settingsHealthDevices,
            onTap: () => context.push('/settings/health-devices'),
          ),
        ],
      ),
    );
  }
}

/// The source-management affordance Home gave up — it now lives next to the
/// data it unlocks.
///
/// Disconnected it is the accent "Connect Health" CTA. Connected it is a quiet,
/// non-interactive status dot: there is no "add a wearable" flow in the app to
/// send the user to, and a tappable chip that does nothing (or silently
/// re-probes permissions) would be a lie about what the control does.
class _HealthSourceChip extends ConsumerWidget {
  final bool isConnected;

  const _HealthSourceChip({required this.isConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final syncing = ref.watch(healthSyncProvider).isSyncing;
    final label = syncing
        ? l10n.syncStatusSyncing
        : (isConnected
            ? l10n.healthSyncConnected
            : l10n.combinedHealthConnectHealth);
    final fg = isConnected ? tc.textSecondary : tc.accent;

    final chip = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isConnected ? tc.cardBorder : tc.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncing)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                // Connected reads on the semantic ramp (this IS a "your data
                // is flowing" state), not the user-chosen accent.
                color: isConnected ? tc.stateSupports : tc.accent,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(10, color: fg, letterSpacing: 1.4),
          ),
        ],
      ),
    );

    if (isConnected) return chip;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.light();
          ref.read(healthSyncProvider.notifier).connect();
        },
        child: ExcludeSemantics(child: chip),
      ),
    );
  }
}

/// One rail chip's content: the composed screen, or a labelled empty state
/// when that chip has nothing to draw.
class _HealthSubTabView extends ConsumerWidget {
  final HealthSubTab tab;
  final bool isConnected;

  const _HealthSubTabView({required this.tab, required this.isConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No Health source → nothing on ANY chip has a value. Label the view the
    // user is standing on and offer the connect CTA.
    if (!isConnected) {
      return _HealthTabEmpty(tab: tab, showConnect: true);
    }

    switch (tab) {
      case HealthSubTab.recovery:
        // The score gauge is meaningless with no driver measured at all —
        // a 0/100 ring reads as "your heart health is zero", not "no data".
        final heartData = ref.watch(heartHealthProvider).valueOrNull;
        if (heartData != null && !heartData.components.any((c) => c.hasData)) {
          return _HealthTabEmpty(tab: tab, showConnect: false);
        }
      case HealthSubTab.body:
        // A radar with every spoke at the centre is a wall of blanks.
        final indexData = ref.watch(fitnessIndexProvider).valueOrNull;
        if (indexData != null &&
            indexData.overall == null &&
            !indexData.axes.any((a) => a.hasData)) {
          return _HealthTabEmpty(tab: tab, showConnect: false);
        }
      case HealthSubTab.vitals:
        // Deliberately NOT gated: this screen already degrades per signal
        // (a "No data" capsule per bio-signal against its own baseline), which
        // is strictly more informative than one blanket empty state.
        break;
      case HealthSubTab.overview:
      case HealthSubTab.sleep:
        // Both screens already render their own honest per-day / per-metric
        // empty states inside a connected session.
        break;
    }
    return healthSubTabScreen(tab);
  }
}

/// Labelled per-chip empty state. Names the view first (so the user knows
/// WHICH thing is empty), then why, then the one action that fixes it.
class _HealthTabEmpty extends ConsumerWidget {
  final HealthSubTab tab;

  /// True when the cause is "no Health source connected" — the CTA can fix it.
  /// False when the source is connected but this chip's payload is empty, in
  /// which case there is no button to offer and pretending otherwise is a lie.
  final bool showConnect;

  const _HealthTabEmpty({required this.tab, required this.showConnect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        // Reserve the FAB cluster's band itself: unlike the five composed
        // screens this is not wrapped in a `SafeArea` that would consume the
        // widened bottom padding, so the Connect CTA would otherwise sit under
        // the Quick Log pill.
        padding: EdgeInsets.fromLTRB(
            32, 32, 32, 32 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 44, color: tc.textMuted),
            const SizedBox(height: 14),
            // The label — this is what makes it a LABELLED empty state rather
            // than a generic shrug.
            Text(
              tab.label(l10n).toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(12, color: tc.accent, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Text(
              showConnect
                  ? l10n.combinedHealthConnectHealthToSee
                  : l10n.healthTabNoDataYet,
              textAlign: TextAlign.center,
              style: ZType.sans(16, color: tc.textPrimary, height: 1.25),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.combinedHealthConnectHealthBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: tc.textMuted,
                height: 1.4,
              ),
            ),
            if (showConnect) ...[
              const SizedBox(height: 20),
              HealthCtaPill(
                label: l10n.combinedHealthConnectHealth,
                onTap: () =>
                    ref.read(healthSyncProvider.notifier).connect(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
