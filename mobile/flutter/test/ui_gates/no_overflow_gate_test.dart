// App-wide RenderFlex overflow gate.
//
// WHY: Flutter paints the yellow/black overflow hazard stripe ONLY in debug
// builds. In release the overflowing content is silently clipped — a user on
// a small phone with large text sees truncated/missing UI and nobody in CI
// ever sees a stripe. A manual screenshot sweep also only ever covers the
// screens someone happened to photograph, in the one data/size/text-scale
// state they happened to be in.
//
// This harness instead mounts a broad inventory of real, production widgets
// — design-system primitives, cards, banners, rows, chips, headers, and a
// handful of composite screens — across a 3×3 matrix of device widths and
// text scales (9 configurations per widget) and asserts no RenderFlex
// overflow (or any other layout-phase throw) occurs. A RenderFlex overflow
// surfaces as a FlutterError thrown during the layout phase; the widget-test
// binding captures it and `tester.takeException()` returns it on the next
// pump — that is the mechanism this gate relies on throughout.
//
// BREADTH OVER DEPTH: ~70 distinct widget configurations, each pumped at 9
// size/scale combinations = ~630 individual assertions. Where a widget
// genuinely cannot be mounted without a live provider tree this file cannot
// stub (Supabase-backed ConsumerWidgets pulling in real repositories), it is
// recorded in the SKIPPED list below with the concrete reason — never
// silently omitted.
//
// Harness pattern follows the prior art at
// test/screens/workout/workout_result_unbounded_layout_test.dart: real
// widgets, a MediaQuery-driven size/textScale matrix, `takeException()`
// after each pump, failures named by widget + size + scale.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/synced_workout_kinds.dart';
import 'package:fitwiz/data/models/coach_persona.dart';
import 'package:fitwiz/data/models/fueling_split.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/repositories/cardio_phase_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/widgets/branded_error_widget.dart';
import 'package:fitwiz/widgets/cardio/auto_tag_chips.dart';
import 'package:fitwiz/widgets/cardio/phase_recommendation_banner.dart';
import 'package:fitwiz/widgets/charts/mini_sparkline.dart';
import 'package:fitwiz/widgets/coach_avatar.dart';
import 'package:fitwiz/widgets/coach_spark_icon.dart';
import 'package:fitwiz/widgets/common/last_used_badge.dart';
import 'package:fitwiz/widgets/cycle_disclaimer.dart';
import 'package:fitwiz/widgets/design_system/section_header.dart';
import 'package:fitwiz/widgets/design_system/zealova_app_bar.dart';
import 'package:fitwiz/widgets/design_system/zealova_button.dart';
import 'package:fitwiz/widgets/design_system/zealova_card.dart';
import 'package:fitwiz/widgets/design_system/zealova_chip.dart';
import 'package:fitwiz/widgets/design_system/zealova_list_row.dart';
import 'package:fitwiz/widgets/design_system/zealova_rule.dart';
import 'package:fitwiz/widgets/design_system/zealova_stat_tile.dart';
import 'package:fitwiz/widgets/empty_state.dart' as legacy_empty;
import 'package:fitwiz/widgets/fading_chip_row.dart';
import 'package:fitwiz/widgets/floating_tab_bar.dart';
import 'package:fitwiz/widgets/glass_back_button.dart';
import 'package:fitwiz/widgets/gradient_circular_progress_indicator.dart';
import 'package:fitwiz/widgets/hexagon_badge.dart';
import 'package:fitwiz/widgets/medical_disclaimer_banner.dart';
import 'package:fitwiz/widgets/metric_grid.dart';
import 'package:fitwiz/widgets/number_stepper.dart';
import 'package:fitwiz/widgets/pill_app_bar.dart';
import 'package:fitwiz/widgets/pill_search_bar.dart';
import 'package:fitwiz/widgets/plan_portability_badge.dart';
import 'package:fitwiz/widgets/program_badge.dart';
import 'package:fitwiz/widgets/segmented_tab_bar.dart';
import 'package:fitwiz/widgets/senior/senior_button.dart';
import 'package:fitwiz/widgets/senior/senior_card.dart';
import 'package:fitwiz/widgets/sheet_header.dart';
import 'package:fitwiz/widgets/signature/z_chip.dart';
import 'package:fitwiz/widgets/signature/z_hairline_row.dart';
import 'package:fitwiz/widgets/signature/z_hero_card.dart';
import 'package:fitwiz/widgets/signature/z_poster_card.dart';
import 'package:fitwiz/widgets/signature/z_section_kicker.dart';
import 'package:fitwiz/widgets/stats/big_stat.dart';
import 'package:fitwiz/widgets/stats/custom_trends_button.dart';
import 'package:fitwiz/widgets/stats/fueling_split_card.dart';
import 'package:fitwiz/widgets/stats/stat_delta_chip.dart';
import 'package:fitwiz/widgets/stats/stat_section_shell.dart';
import 'package:fitwiz/widgets/synced/kind_avatar.dart';
import 'package:fitwiz/widgets/synced/metric_chip.dart';
import 'package:fitwiz/widgets/top_segmented_control.dart';
import 'package:fitwiz/data/providers/trend_series_provider.dart' show TrendMetric;

// ─────────────────────────── render matrix ───────────────────────────
//
// Per the task spec: at minimum a small phone (320-360), a standard phone
// (393), and a large phone/tablet, crossed with text scales 1.0 / 1.3 / 2.0.
// Height is generous (2200) so nothing is artificially clipped vertically —
// width is the axis that drives wrap/flex overflow math.

class _Size {
  final String label;
  final double width;
  const _Size(this.label, this.width);
}

const _sizes = <_Size>[
  _Size('small-320', 320),
  _Size('standard-393', 393),
  _Size('large-834', 834),
];

const _scales = <double>[1.0, 1.3, 2.0];

/// Every (size × scale) combination — 3×3 = 9 configurations per widget.
List<({_Size size, double scale})> get _matrix => [
      for (final s in _sizes)
        for (final t in _scales) (size: s, scale: t),
    ];

// ─────────────────────────── failure tracking ───────────────────────────

class _Failure {
  final String widget;
  final String size;
  final double scale;
  final String error;
  _Failure(this.widget, this.size, this.scale, this.error);

  @override
  String toString() =>
      '$widget @ $size / textScale=$scale\n    -> $error';
}

final List<_Failure> _failures = [];

// ─────────────────────────── harness ───────────────────────────

/// Mounts [child] at the given size/scale inside a real MaterialApp +
/// ProviderScope (so ConsumerWidget-shaped children resolve
/// `AccentColorScope` fallbacks, `Theme.of`, `AppLocalizations.of`, etc. the
/// same way production does), records the [name] under test, and appends any
/// captured layout exception to [_failures].
///
/// The child is NOT wrapped in a bounding SizedBox/width-constraint beyond
/// what MediaQuery.size implies for the root — this mirrors how these
/// widgets are actually laid out in production (inside a Scaffold body under
/// the device's real width), which is exactly the axis a RenderFlex overflow
/// depends on.
Future<void> _mount(
  WidgetTester tester, {
  required String name,
  required Widget Function(BuildContext context) builder,
  bool scrollable = true,
}) async {
  for (final m in _matrix) {
    tester.view.physicalSize = Size(m.size.width, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(m.size.width, 2200),
              textScaler: TextScaler.linear(m.scale),
            ),
            child: Scaffold(
              body: scrollable
                  ? SingleChildScrollView(child: Builder(builder: builder))
                  : Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // A second pump lets any post-frame-scheduled work (e.g. animation
    // controllers kicked off in initState) surface a throw too.
    await tester.pump(const Duration(milliseconds: 50));

    final ex = tester.takeException();
    if (ex != null) {
      _failures.add(_Failure(name, m.size.label, m.scale, ex.toString()));
    }
  }
}

// ─────────────────────────── fixtures ───────────────────────────

const _longLabel =
    'A deliberately long label that a narrow phone at 200% text size will '
    'struggle to fit without wrapping or clipping something';

final _coachPersona = const CoachPersona(
  id: 'test',
  name: 'Coach Rivera',
  tagline: 'Direct, no-nonsense, always in your corner',
  specialization: 'Strength & powerlifting',
  coachingStyle: 'Tough love',
  communicationTone: 'Direct',
  encouragementLevel: 0.8,
  icon: Icons.fitness_center,
  primaryColor: Color(0xFFFF6B35),
  accentColor: Color(0xFF00B4D8),
  imagePath: null,
);

final _fuelingSplit = const FuelingSplit(
  training: FuelingGroup(avgProteinG: 168, avgCalories: 2650, days: 12),
  rest: FuelingGroup(avgProteinG: 122, avgCalories: 2100, days: 9),
);

final _phaseRecommendation = const PhaseRecommendation(
  phase: 'ovulation',
  recommendedIntensity: 'high',
  rationale:
      'Estrogen is peaking, which is associated with better neuromuscular '
      'performance and pain tolerance — a good window for intervals or a '
      'heavy strength session if you are feeling it.',
  evidenceCitation: 'Journal of Sports Sciences, 2021',
  cycleDay: 14,
  confidence: 'moderate',
);

/// TabController needs a TickerProvider; this tiny stateful host creates one
/// via SingleTickerProviderStateMixin so SegmentedTabBar can be mounted like
/// it is at its real call sites (which own a TabController themselves).
class _SegmentedTabBarHost extends StatefulWidget {
  const _SegmentedTabBarHost();
  @override
  State<_SegmentedTabBarHost> createState() => _SegmentedTabBarHostState();
}

class _SegmentedTabBarHostState extends State<_SegmentedTabBarHost>
    with SingleTickerProviderStateMixin {
  late final TabController _controller =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedTabBar(
      controller: _controller,
      tabs: const [
        SegmentedTabItem(label: 'Overview', icon: Icons.dashboard_rounded),
        SegmentedTabItem(label: 'History', icon: Icons.history_rounded),
        SegmentedTabItem(label: _longLabel, icon: Icons.insights_rounded),
      ],
    );
  }
}

void main() {
  setUpAll(() {
    _failures.clear();
  });

  group('UI overflow gate', () {
    // ── design_system ──────────────────────────────────────────────
    testWidgets('SectionHeader', (tester) async {
      await _mount(tester,
          name: 'SectionHeader',
          builder: (_) => const SectionHeader(label: _longLabel));
    });
    testWidgets('SectionHeader+trailing', (tester) async {
      await _mount(tester,
          name: 'SectionHeader+trailing',
          builder: (_) => SectionHeader(
                label: 'Recent workouts',
                trailing: TextButton(
                    onPressed: () {}, child: const Text('View all')),
              ));
    });
    testWidgets('ZealovaAppBar', (tester) async {
      await _mount(tester,
          name: 'ZealovaAppBar',
          builder: (_) => const ZealovaAppBar(
                title: 'Stats & Scores',
                kicker: 'Your progress this week',
              ));
    });
    testWidgets('ZealovaButton primary+icon', (tester) async {
      await _mount(tester,
          name: 'ZealovaButton primary+icon',
          builder: (_) => ZealovaButton(
                label: _longLabel,
                onTap: () {},
                trailingIcon: Icons.arrow_forward,
              ));
    });
    // E2E row 128: the exact reported geometry — the Set-A-Target sheet's
    // pinned footer, `Row([Expanded, SizedBox(10), Expanded])` inside 20pt
    // side padding. On a 390pt device that leaves 130pt for a label whose
    // intrinsic advance is 133.3pt, so the pre-fix bare `Text` overflowed by
    // ~5pt (release builds clipped it silently to "USE RECOMMEND…").
    testWidgets('ZealovaButton pair in a pinned footer row (row 128)',
        (tester) async {
      await _mount(tester,
          name: 'ZealovaButton pinned footer pair',
          builder: (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                    child: ZealovaButton(
                      label: 'Use recommended',
                      onTap: () {},
                      variant: ZealovaButtonVariant.ghost,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZealovaButton(
                      label: 'Save targets',
                      onTap: () {},
                    ),
                  ),
                ]),
              ));
    });
    testWidgets('ZealovaButton ghost non-expanded', (tester) async {
      await _mount(tester,
          name: 'ZealovaButton ghost non-expanded',
          builder: (_) => Row(children: [
                ZealovaButton(
                  label: 'Preview',
                  onTap: () {},
                  variant: ZealovaButtonVariant.ghost,
                  expand: false,
                ),
              ]));
    });
    testWidgets('ZealovaPlusButton', (tester) async {
      await _mount(tester,
          name: 'ZealovaPlusButton',
          builder: (_) => ZealovaPlusButton(onTap: () {}));
    });
    testWidgets('ZealovaCard outlined', (tester) async {
      await _mount(tester,
          name: 'ZealovaCard outlined',
          builder: (_) => const ZealovaCard(child: Text(_longLabel)));
    });
    testWidgets('ZealovaCard hero', (tester) async {
      await _mount(tester,
          name: 'ZealovaCard hero',
          builder: (_) => ZealovaCard(
                variant: ZealovaCardVariant.hero,
                onTap: () {},
                child: const Text('Coach to-do: log yesterday\'s dinner'),
              ));
    });
    testWidgets('ZealovaChip icon+long label', (tester) async {
      await _mount(tester,
          name: 'ZealovaChip icon+long label',
          builder: (_) => Wrap(children: [
                ZealovaChip(
                  label: _longLabel,
                  icon: Icons.filter_alt_rounded,
                  onTap: () {},
                ),
              ]));
    });
    testWidgets('ZealovaChip selected+emoji', (tester) async {
      await _mount(tester,
          name: 'ZealovaChip selected+emoji',
          builder: (_) => Wrap(children: [
                ZealovaChip(
                    label: 'Chest', emoji: '💪', selected: true, onTap: () {}),
              ]));
    });
    testWidgets('ZealovaTextTabs', (tester) async {
      await _mount(tester,
          name: 'ZealovaTextTabs',
          builder: (_) => ZealovaTextTabs(
                tabs: const ['Overview', 'History', 'Personal records'],
                activeIndex: 1,
                onChanged: (_) {},
              ));
    });
    testWidgets('ZealovaListRow value+long label', (tester) async {
      await _mount(tester,
          name: 'ZealovaListRow value+long label',
          builder: (_) => ZealovaListRow(
                icon: Icons.psychology_rounded,
                label: 'Coach memory: what your AI coach remembers about you',
                value: 'View & manage what your AI coach remembers',
                onTap: () {},
              ));
    });
    testWidgets('ZealovaToggle', (tester) async {
      await _mount(tester,
          name: 'ZealovaToggle',
          builder: (_) => ZealovaToggle(value: true, onChanged: (_) {}));
    });
    testWidgets('ZealovaRule', (tester) async {
      await _mount(tester,
          name: 'ZealovaRule', builder: (_) => const ZealovaRule(strong: true));
    });
    testWidgets('ZealovaSectionKicker', (tester) async {
      await _mount(tester,
          name: 'ZealovaSectionKicker',
          builder: (_) => const ZealovaSectionKicker(_longLabel, accent: true));
    });
    testWidgets('ZealovaStatTile', (tester) async {
      await _mount(tester,
          name: 'ZealovaStatTile',
          builder: (_) => const ZealovaStatTile(
                value: '12,480',
                label: 'total volume lifted',
                unit: 'lbs',
                accentValue: true,
              ));
    });

    // ── signature ──────────────────────────────────────────────────
    testWidgets('ZChip selected+dot', (tester) async {
      await _mount(tester,
          name: 'ZChip selected+dot',
          builder: (_) => ZChip(
                label: _longLabel,
                selected: true,
                leadingDot: Colors.orange,
                onTap: () {},
              ));
    });
    testWidgets('ZHairlineRow full', (tester) async {
      await _mount(tester,
          name: 'ZHairlineRow full',
          builder: (_) => ZHairlineRow(
                leading: const Icon(Icons.fitness_center),
                title: const Text(_longLabel),
                subtitle: const Text('CHEST · SHOULDERS · TRICEPS · BACK · CORE'),
                trailing: const Icon(Icons.chevron_right),
                accentStripeColor: Colors.orange,
                onTap: () {},
              ));
    });
    testWidgets('ZHeroCard full', (tester) async {
      await _mount(tester,
          name: 'ZHeroCard full',
          builder: (_) => ZHeroCard(
                title: 'PUSH PULL LEGS: SIX WEEK HYPERTROPHY BLOCK',
                description:
                    'A 6-week hypertrophy block built around progressive '
                    'overload and a deload every 4th week.',
                category: 'Goal-Based',
                difficultyLevel: 'Intermediate',
                meta: '6 WEEKS · 5 DAYS/WK · GYM EQUIPMENT REQUIRED',
                primaryLabel: 'START PROGRAM',
                onPrimary: () {},
                ghostLabel: 'PREVIEW',
                onGhost: () {},
              ));
    });
    testWidgets('ZCarouselDots', (tester) async {
      await _mount(tester,
          name: 'ZCarouselDots',
          builder: (_) =>
              ZCarouselDots(count: 5, index: 2, onPrev: () {}, onNext: () {}));
    });
    testWidgets('ZPosterCard gradient', (tester) async {
      await _mount(tester,
          name: 'ZPosterCard gradient',
          builder: (_) => ZPosterCard(
                name: 'Push / Pull / Legs: The Complete Hypertrophy System',
                category: 'Goal-Based',
                difficultyLevel: 'Advanced',
                stat: '6 WK · 5/WK',
                onTap: () {},
              ));
    });
    testWidgets('ZDifficultyRibbon', (tester) async {
      await _mount(tester,
          name: 'ZDifficultyRibbon',
          builder: (_) => const ZDifficultyRibbon(level: 'Intermediate'));
    });
    testWidgets('ZSectionKicker+seeAll', (tester) async {
      await _mount(tester,
          name: 'ZSectionKicker+seeAll',
          builder: (_) => ZSectionKicker(
                label: 'Featured programs for your goals',
                onSeeAll: () {},
              ));
    });

    // ── empty state ────────────────────────────────────────────────
    testWidgets('EmptyState with action', (tester) async {
      await _mount(tester,
          name: 'EmptyState with action',
          builder: (_) => legacy_empty.EmptyState(
                icon: Icons.fitness_center,
                title: 'No workouts scheduled',
                subtitle:
                    'Your workout schedule is empty. Create a program to get started.',
                actionLabel: 'Create program',
                onAction: () {},
                useLottie: false,
              ));
    });
    testWidgets('EmptyState.noResults factory', (tester) async {
      await _mount(tester,
          name: 'EmptyState.noResults factory',
          builder: (ctx) => legacy_empty.EmptyState.noResults(ctx));
    });

    // ── stats ──────────────────────────────────────────────────────
    testWidgets('BigStat full', (tester) async {
      await _mount(tester,
          name: 'BigStat full',
          builder: (_) => BigStat(
                value: '12,480',
                label: 'total workouts completed this year',
                unit: 'lbs',
                isDark: true,
                icon: Icons.bolt_rounded,
                accent: Colors.orange,
                delta: const StatDeltaChip(
                    value: 12,
                    magnitudeLabel: '12%',
                    isDark: true,
                    valence: GoodDirection.higher),
                trend: const MiniSparkline(
                    values: [2, 5, 3, 8, 6, 9, 12], color: Colors.orange),
              ));
    });
    testWidgets('StatDeltaChip positive', (tester) async {
      await _mount(tester,
          name: 'StatDeltaChip positive',
          builder: (_) => const StatDeltaChip(
              value: 8,
              magnitudeLabel: '8%',
              isDark: false,
              valence: GoodDirection.higher));
    });
    testWidgets('StatDeltaChip negative', (tester) async {
      await _mount(tester,
          name: 'StatDeltaChip negative',
          builder: (_) => const StatDeltaChip(
              value: -4,
              magnitudeLabel: '4 kg',
              isDark: true,
              valence: GoodDirection.lower));
    });
    testWidgets('StatSectionHeader full', (tester) async {
      await _mount(tester,
          name: 'StatSectionHeader full',
          builder: (_) => StatSectionHeader(
                title: 'Training stats and weekly overview',
                isDark: true,
                onSeeAll: () {},
                onTrendsTap: () {},
                onCustomize: () {},
              ));
    });
    testWidgets('StatCardShell', (tester) async {
      await _mount(tester,
          name: 'StatCardShell',
          builder: (_) => const StatCardShell(
              isDark: true, child: Text(_longLabel)));
    });
    testWidgets('CustomTrendsButton', (tester) async {
      await _mount(tester,
          name: 'CustomTrendsButton',
          builder: (_) => CustomTrendsButton(
                seed: TrendMetric.weight,
                title: 'Custom trends builder for advanced analysis',
                subtitle: 'Plot any two metrics against each other',
                isDark: true,
                accent: Colors.orange,
              ));
    });
    testWidgets('FuelingSplitCard data', (tester) async {
      await _mount(tester,
          name: 'FuelingSplitCard data',
          builder: (_) => FuelingSplitCard(
                fueling: AsyncValue.data(_fuelingSplit),
                isDark: true,
                accent: Colors.orange,
              ));
    });
    testWidgets('FuelingSplitCard loading', (tester) async {
      await _mount(tester,
          name: 'FuelingSplitCard loading',
          builder: (_) => FuelingSplitCard(
                fueling: const AsyncValue.loading(),
                isDark: true,
                accent: Colors.orange,
              ));
    });
    testWidgets('FuelingSplitCard empty', (tester) async {
      await _mount(tester,
          name: 'FuelingSplitCard empty',
          builder: (_) => FuelingSplitCard(
                fueling: const AsyncValue.data(FuelingSplit(
                  training: FuelingGroup(avgProteinG: 0, avgCalories: 0, days: 0),
                  rest: FuelingGroup(avgProteinG: 0, avgCalories: 0, days: 0),
                )),
                isDark: true,
                accent: Colors.orange,
              ));
    });

    // ── synced ─────────────────────────────────────────────────────
    testWidgets('KindAvatar large', (tester) async {
      await _mount(tester,
          name: 'KindAvatar large',
          builder: (_) => const KindAvatar.large(kind: SyncedKind.running));
    });
    testWidgets('MetricChip with unit', (tester) async {
      await _mount(tester,
          name: 'MetricChip with unit',
          builder: (_) => const MetricChip(
              dotColor: Colors.cyan, value: '5.2', unit: 'mi'));
    });

    // ── common ─────────────────────────────────────────────────────
    testWidgets('LastUsedBadge.static', (tester) async {
      await _mount(tester,
          name: 'LastUsedBadge.static',
          builder: (_) => const LastUsedBadge.static());
    });
    testWidgets('LastUsedBadge.glow', (tester) async {
      await _mount(tester,
          name: 'LastUsedBadge.glow',
          builder: (_) => const LastUsedBadge.glow());
    });

    // ── misc widgets/ ──────────────────────────────────────────────
    testWidgets('MedicalDisclaimerBanner', (tester) async {
      await _mount(tester,
          name: 'MedicalDisclaimerBanner',
          builder: (_) => const MedicalDisclaimerBanner());
    });
    testWidgets('CycleDisclaimer.banner', (tester) async {
      await _mount(tester,
          name: 'CycleDisclaimer.banner',
          builder: (_) => const CycleDisclaimer.banner());
    });
    testWidgets('CycleDisclaimer.onboarding', (tester) async {
      await _mount(tester,
          name: 'CycleDisclaimer.onboarding',
          builder: (_) => const CycleDisclaimer.onboarding());
    });
    testWidgets('PlanPortabilityBadge inline', (tester) async {
      await _mount(tester,
          name: 'PlanPortabilityBadge inline',
          builder: (_) => const PlanPortabilityBadge(
              size: PortabilitySize.inline));
    });
    testWidgets('PlanPortabilityBadge compact', (tester) async {
      await _mount(tester,
          name: 'PlanPortabilityBadge compact',
          builder: (_) => const PlanPortabilityBadge(
              size: PortabilitySize.compact));
    });
    testWidgets('PlanPortabilityBadge banner', (tester) async {
      await _mount(tester,
          name: 'PlanPortabilityBadge banner',
          builder: (_) => PlanPortabilityBadge(
              size: PortabilitySize.banner, onTap: () {}));
    });
    testWidgets('ProgramBadge AI', (tester) async {
      await _mount(tester,
          name: 'ProgramBadge AI',
          builder: (_) => ProgramBadge(workout: const Workout(name: 'Push Day')));
    });
    testWidgets('ProgramBadge curated+openable', (tester) async {
      await _mount(tester,
          name: 'ProgramBadge curated+openable',
          builder: (_) => ProgramBadge(
                workout: Workout(
                  name: 'Push Day',
                  generationMetadata: const {
                    'program_context': {
                      'program_id': 'p1',
                      'program_name':
                          'HYROX Prep: The Complete Twelve Week Program',
                      'slot': 'primary',
                    },
                  },
                ),
                onOpenProgram: () {},
              ));
    });
    testWidgets('HexagonBadge', (tester) async {
      await _mount(tester,
          name: 'HexagonBadge',
          builder: (_) =>
              const HexagonBadge(value: '9999', color: Colors.orange));
    });
    testWidgets('GradientCircularProgressIndicator', (tester) async {
      await _mount(tester,
          name: 'GradientCircularProgressIndicator',
          builder: (_) => const GradientCircularProgressIndicator(
                value: 0.65,
                gradientColors: [Colors.orange, Colors.red],
              ));
    });
    testWidgets('CoachAvatar', (tester) async {
      await _mount(tester,
          name: 'CoachAvatar',
          builder: (_) => CoachAvatar(coach: _coachPersona, size: 64));
    });
    testWidgets('CoachSparkIcon', (tester) async {
      await _mount(tester,
          name: 'CoachSparkIcon',
          builder: (_) => const CoachSparkIcon(size: 24, color: Colors.white));
    });
    testWidgets('CompactNumberStepper', (tester) async {
      await _mount(tester,
          name: 'CompactNumberStepper',
          builder: (_) => CompactNumberStepper(
                value: 60,
                onChanged: (_) {},
                label: 'KG',
                showDecimals: true,
              ));
    });
    testWidgets('SheetHeader with subtitle', (tester) async {
      await _mount(tester,
          name: 'SheetHeader with subtitle',
          builder: (_) => SheetHeader(
                icon: Icons.fitness_center_rounded,
                iconColor: Colors.cyan,
                title: 'Switch Gym Profile',
                subtitle: 'Choose which gym you are training at right now',
                onBack: () {},
                onClose: () {},
              ),
          scrollable: false);
    });
    testWidgets('SheetBackButton', (tester) async {
      await _mount(tester,
          name: 'SheetBackButton', builder: (_) => SheetBackButton(onTap: () {}));
    });
    testWidgets('GlassBackButton', (tester) async {
      await _mount(tester,
          name: 'GlassBackButton', builder: (_) => GlassBackButton(onTap: () {}));
    });
    testWidgets('PillSearchBar', (tester) async {
      final controller = TextEditingController(text: 'bench press');
      addTearDown(controller.dispose);
      await _mount(tester,
          name: 'PillSearchBar',
          builder: (_) => PillSearchBar(
                controller: controller,
                onChanged: (_) {},
                onMicTap: () {},
              ));
    });
    testWidgets('PillAppBar with actions', (tester) async {
      await _mount(tester,
          name: 'PillAppBar with actions',
          builder: (_) => PillAppBar(
                title: 'Stats & Scores and Your Progress',
                actions: [
                  PillAppBarAction(
                      icon: Icons.calendar_month_outlined, onTap: () {}),
                  PillAppBarAction(icon: Icons.share_rounded, onTap: () {}),
                ],
              ),
          scrollable: false);
    });
    testWidgets('TopSegmentedControl', (tester) async {
      await _mount(tester,
          name: 'TopSegmentedControl',
          builder: (_) => TopSegmentedControl(
                items: const [
                  TopSegmentItem(label: 'Overview', icon: Icons.list),
                  TopSegmentItem(label: 'By day', icon: Icons.calendar_today),
                  TopSegmentItem(label: 'Patterns', icon: Icons.insights),
                ],
                selectedIndex: 1,
                onSelected: (_) {},
                accentColor: Colors.orange,
              ));
    });
    testWidgets('SegmentedTabBar', (tester) async {
      await _mount(tester,
          name: 'SegmentedTabBar', builder: (_) => const _SegmentedTabBarHost());
    });
    testWidgets('FadingChipRow many chips', (tester) async {
      await _mount(tester,
          name: 'FadingChipRow many chips',
          builder: (_) => FadingChipRow(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final l in [
                    'Difficulty: Moderate',
                    'Duration: 45 min',
                    'Equipment: Full gym',
                    'Focus: Upper body',
                    'Nutrition compatible',
                  ])
                    Chip(label: Text(l)),
                ],
              ));
    });
    testWidgets('FloatingTabBar viewSwitcher', (tester) async {
      await _mount(tester,
          name: 'FloatingTabBar viewSwitcher',
          builder: (_) => FloatingTabBar(
                items: const [
                  FloatingTabItem(label: 'Discover', icon: Icons.explore),
                  FloatingTabItem(label: 'Nutrition', icon: Icons.restaurant),
                  FloatingTabItem(label: 'You', icon: Icons.person),
                ],
                selectedIndex: 1,
                onTap: (_) {},
                accentColor: Colors.orange,
              ),
          scrollable: false);
    });
    testWidgets('FloatingTabBar launcher no-coach', (tester) async {
      await _mount(tester,
          name: 'FloatingTabBar launcher no-coach',
          builder: (_) => FloatingTabBar(
                items: const [
                  FloatingTabItem(label: 'Log', icon: Icons.add),
                  FloatingTabItem(label: 'Scan', icon: Icons.camera_alt),
                  FloatingTabItem(label: 'Recipes', icon: Icons.menu_book),
                  FloatingTabItem(label: 'Barcode', icon: Icons.qr_code),
                ],
                onTap: (_) {},
                accentColor: Colors.orange,
                mode: FloatingTabBarMode.launcher,
                showCoachAction: false,
              ),
          scrollable: false);
    });
    testWidgets('BrandedErrorWidget', (tester) async {
      await _mount(tester,
          name: 'BrandedErrorWidget',
          builder: (_) => SizedBox(
                height: 300,
                child: BrandedErrorWidget(
                  details: FlutterErrorDetails(
                      exception: Exception('synthetic test error')),
                ),
              ));
    });
    testWidgets('MetricGrid 2col long labels', (tester) async {
      await _mount(tester,
          name: 'MetricGrid 2col long labels',
          builder: (_) => const MetricGrid(items: [
                MetricCell(
                    label: 'Total duration this session',
                    value: '1:42:18',
                    icon: Icons.timer),
                MetricCell(
                    label: 'Energy expended',
                    value: '842',
                    unit: 'kcal',
                    icon: Icons.local_fire_department),
                MetricCell(
                    label: 'Total volume lifted across all exercises',
                    value: '24,680',
                    unit: 'lbs'),
                MetricCell(label: 'Personal records', value: '3'),
              ]));
    });

    // ── charts ─────────────────────────────────────────────────────
    testWidgets('MiniSparkline', (tester) async {
      await _mount(tester,
          name: 'MiniSparkline',
          builder: (_) => const MiniSparkline(
              values: [1, 4, 2, 8, 5, 9, 7, 12], color: Colors.orange));
    });
    testWidgets('MiniBars', (tester) async {
      await _mount(tester,
          name: 'MiniBars',
          builder: (_) =>
              const MiniBars(values: [3, 7, 2, 9, 4], color: Colors.cyan));
    });

    // ── cardio ─────────────────────────────────────────────────────
    testWidgets('AutoTagChips many tags', (tester) async {
      await _mount(tester,
          name: 'AutoTagChips many tags',
          builder: (_) => const AutoTagChips(tags: [
                'is_hill_workout',
                'is_negative_split',
                'is_new_route',
                'is_dawn_run',
                'is_pr_session',
              ]));
    });
    testWidgets('PhaseRecommendationBanner', (tester) async {
      await _mount(tester,
          name: 'PhaseRecommendationBanner',
          builder: (_) =>
              PhaseRecommendationBanner(recommendation: _phaseRecommendation));
    });

    // ── senior ─────────────────────────────────────────────────────
    testWidgets('SeniorButton with icon', (tester) async {
      await _mount(tester,
          name: 'SeniorButton with icon',
          builder: (_) => SeniorButton(
                text: 'Start today\'s workout now',
                onPressed: () {},
                icon: Icons.play_arrow,
              ));
    });
    testWidgets('SeniorCard full', (tester) async {
      await _mount(tester,
          name: 'SeniorCard full',
          builder: (_) => SeniorCard(
                title: 'Today\'s workout: Full Body Strength Circuit',
                subtitle: '6 exercises · about 35 minutes',
                icon: Icons.fitness_center,
                onTap: () {},
              ));
    });
    testWidgets('SeniorWorkoutCard long name', (tester) async {
      await _mount(tester,
          name: 'SeniorWorkoutCard long name',
          builder: (_) => SeniorWorkoutCard(
                workoutName:
                    'Full Body Strength and Conditioning Circuit Training',
                exerciseCount: 8,
                durationMinutes: 45,
                onStart: () {},
              ));
    });
    testWidgets('SeniorStatCard', (tester) async {
      await _mount(tester,
          name: 'SeniorStatCard',
          builder: (_) => const SeniorStatCard(
              label: 'Workouts this month', value: '18', icon: Icons.bolt));
    });
  });

  // ─────────────────────────── report + assert ───────────────────────────
  tearDownAll(() {
    // ignore: avoid_print
    print(
        '\n=== no_overflow_gate: ${_failures.length} failing (widget × size × scale) case(s) ===');
    for (final f in _failures) {
      // ignore: avoid_print
      print('  $f');
    }
  });

  test('no_overflow_gate: zero layout failures across the matrix', () {
    expect(
      _failures,
      isEmpty,
      reason: _failures.isEmpty
          ? null
          : 'Layout failures found:\n${_failures.join('\n')}',
    );
  });
}

// ─────────────────────────── SKIPPED ───────────────────────────
//
// These widgets could not be mounted by this harness and are recorded here
// rather than silently omitted:
//
// - Every screen under lib/screens/** except via the composite widgets
//   reused above: most screens are ConsumerWidgets/ConsumerStatefulWidgets
//   whose build() reads StateNotifierProviders wired directly to Supabase
//   session state, Dio, or the local Drift DB (WorkoutsNotifier,
//   TodayWorkoutNotifier, XPNotifier, auth/session providers, etc.) — see
//   test/screens/home/test_provider_stubs.dart for the stub pattern this
//   requires. A full screen sweep needs a per-screen stub set (the
//   `apiClientProvider` / `useKgForWorkoutProvider` overrides in
//   workout_result_unbounded_layout_test.dart are the template) which is
//   substantial per-screen work; this gate covers the shared building-block
//   widgets those screens are assembled from instead, on the theory that a
//   RenderFlex overflow inside a shared card/row/header widget reproduces on
//   every screen that embeds it.
// - `main_shell.dart` (MainShell) — the app's root shell: owns bottom-nav
//   state, deep-link handling, and several StateNotifierProviders; not
//   mountable without the full app bootstrap.
// - ConsumerWidget banners that gate on live device/account state with no
//   safe default (OfflineBanner reads connectivity, DoubleXPBanner /
//   XpHeroTile / XPLevelBarCompact / UsageCounterStrip read XP/usage
//   providers backed by Drift, LiveCaloriesDisplay / HeartRateDisplay read
//   live HealthKit/Health Connect streams) — these need device-tier fakes
//   beyond a ProviderScope override and were left out of this pass.
// - `ZPosterCard`(imageUrl: set) / other `CachedNetworkImage`-backed
//   variants — intentionally exercised only in their image-free (gradient)
//   configuration so the gate never depends on network access; the
//   image-url codepath is presentational-only (Stack + scrim) and shares its
//   text-overflow handling with the gradient path already covered.
// - Floating chat / trophy-ceremony / weekly-recap OVERLAY widgets
//   (FloatingChatOverlay, TrophyCeremonyOverlay, WeeklyRecapDialog,
//   ComebackModeSheet, GuestUpgradeSheet) — each opens via a
//   provider-driven `showDialog`/`showModalBottomSheet` call gated on
//   account state (trial day count, streak state, dismissed-banner
//   persistence) rather than being a plain constructor; reaching their
//   content requires driving that provider state, which is a per-widget
//   investment beyond this pass's scope.
