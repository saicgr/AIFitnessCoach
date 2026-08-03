/// Preferences model for the Home metrics carousel (register #176 change 3
/// replacement — see `metrics_carousel_prefs_provider.dart` for persistence).
///
/// Two independent levers, deliberately kept separate (mockup "Adding
/// metrics to a page" section):
///   * PAGES — breadth. One swipe each. [CarouselPageId] enumerates every
///     page the carousel could ever show; there are exactly 5, so the "cap
///     pages at 5" build-spec rule is structural, not a runtime check.
///   * SLOTS — depth. What fills a page's stat strip. Only the Training page
///     has a configurable strip today (the ring/chart on every other page is
///     fixed) — capped at 4 normally, 6 when the page opts into the taller
///     240px card (see the mockup's "Or buy height instead" panel).
library;

/// Every page the carousel can show, in the app's canonical default order.
enum CarouselPageId {
  training,
  volumeTrend,
  muscleBalance,
  prLadder,
  recovery;

  /// Title shown in the edit sheet + as a fallback page label.
  String get title {
    switch (this) {
      case CarouselPageId.training:
        return 'Training';
      case CarouselPageId.volumeTrend:
        return 'Volume trend';
      case CarouselPageId.muscleBalance:
        return 'Muscle balance';
      case CarouselPageId.prLadder:
        return 'PR ladder';
      case CarouselPageId.recovery:
        return 'Recovery';
    }
  }

  /// One-line description shown under the title in the edit sheet.
  String get subtitle {
    switch (this) {
      case CarouselPageId.training:
        return 'Sessions, streak, volume, PRs';
      case CarouselPageId.volumeTrend:
        return '8 weeks';
      case CarouselPageId.muscleBalance:
        return 'Needs 3+ groups trained';
      case CarouselPageId.prLadder:
        return 'Est. 1RM over time';
      case CarouselPageId.recovery:
        return 'Sleep & readiness';
    }
  }

  /// Pages whose card body is fully built in this pass. [muscleBalance] and
  /// [prLadder] ship as toggleable-but-"coming soon" rows — no chart package
  /// was added (build spec: "no chart package is required for these two
  /// pages"), and neither page had a card mockup to build against, so they
  /// render an honest placeholder rather than a fabricated chart.
  bool get hasBuiltCard =>
      this != CarouselPageId.muscleBalance && this != CarouselPageId.prLadder;
}

/// One stat-strip slot option on the Training page. Every value here is
/// backed by a real provider — see `metrics_carousel_data_provider.dart`.
/// [steps] is the only slot gated on a Health connection.
enum CarouselSlotId {
  volumeKg,
  timeHrs,
  newPrs,
  caloriesBurned,
  exercisesDone,
  steps;

  String get label {
    switch (this) {
      case CarouselSlotId.volumeKg:
        return 'Volume';
      case CarouselSlotId.timeHrs:
        return 'Time trained';
      case CarouselSlotId.newPrs:
        return 'New PRs';
      case CarouselSlotId.caloriesBurned:
        return 'Calories burned';
      case CarouselSlotId.exercisesDone:
        return 'Exercises done';
      case CarouselSlotId.steps:
        return 'Steps';
    }
  }

  /// Short mono label painted in the stat-strip tile (matches the mockup's
  /// "VOLUME KG" / "TIME HRS" / "PRS NEW" style).
  String get tileLabel {
    switch (this) {
      case CarouselSlotId.volumeKg:
        return 'VOLUME KG';
      case CarouselSlotId.timeHrs:
        return 'TIME HRS';
      case CarouselSlotId.newPrs:
        return 'PRS NEW';
      case CarouselSlotId.caloriesBurned:
        return 'KCAL BURNED';
      case CarouselSlotId.exercisesDone:
        return 'EXERCISES';
      case CarouselSlotId.steps:
        return 'STEPS';
    }
  }

  bool get needsHealth => this == CarouselSlotId.steps;
}

/// Normal (170px) card stat-strip cap — see mockup "4 slots / the practical
/// ceiling" panel (5 was ruled out: values drop below the app's own
/// accessibility floor).
const int kCarouselMaxSlotsNormal = 4;

/// Slot cap when a page opts into the taller 240px card (two stat-strip rows
/// of 3, per the mockup's "Or buy height instead" panel).
const int kCarouselMaxSlotsTall = 6;

/// Structural page cap — there are exactly 5 [CarouselPageId] values.
/// (`EnumType.values` isn't a compile-time constant in Dart, so this can't
/// be `const` — it's still fixed at exactly [CarouselPageId.values.length].)
final int kCarouselMaxPages = CarouselPageId.values.length;

/// One page's configuration: whether it's shown, its position (implicit —
/// carried by list order in [MetricsCarouselPrefs.pages]), and (Training
/// only, for now) which stats fill its strip.
class CarouselPageConfig {
  final CarouselPageId id;
  final bool enabled;

  /// Taller 240px variant — currently only meaningful for [CarouselPageId.training].
  final bool tall;

  /// Stat-strip slot selection, in display order. Only read for pages whose
  /// card has a configurable strip (Training today).
  final List<CarouselSlotId> slots;

  const CarouselPageConfig({
    required this.id,
    required this.enabled,
    this.tall = false,
    this.slots = const [],
  });

  int get maxSlots => tall ? kCarouselMaxSlotsTall : kCarouselMaxSlotsNormal;

  CarouselPageConfig copyWith({
    bool? enabled,
    bool? tall,
    List<CarouselSlotId>? slots,
  }) {
    return CarouselPageConfig(
      id: id,
      enabled: enabled ?? this.enabled,
      tall: tall ?? this.tall,
      slots: slots ?? this.slots,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'enabled': enabled,
        'tall': tall,
        'slots': [for (final s in slots) s.name],
      };

  /// Tolerant decode — an unknown slot/id name (future app version wrote a
  /// slot this build doesn't know) is dropped rather than throwing, so an
  /// old build never crashes reading a newer prefs blob.
  static CarouselPageConfig? fromJson(Map<String, dynamic> json) {
    final idName = json['id'] as String?;
    final id = CarouselPageId.values.where((e) => e.name == idName).firstOrNull;
    if (id == null) return null;
    final rawSlots = json['slots'];
    final slots = <CarouselSlotId>[
      if (rawSlots is List)
        for (final s in rawSlots)
          if (CarouselSlotId.values.where((e) => e.name == s).firstOrNull
              case final slot?)
            slot,
    ];
    return CarouselPageConfig(
      id: id,
      enabled: json['enabled'] as bool? ?? false,
      tall: json['tall'] as bool? ?? false,
      slots: slots,
    );
  }
}

/// Top-level persisted prefs — the ordered list of every page (enabled or
/// not) plus its config. Order in [pages] IS the carousel's display order
/// for enabled pages.
class MetricsCarouselPrefs {
  final List<CarouselPageConfig> pages;

  const MetricsCarouselPrefs({required this.pages});

  factory MetricsCarouselPrefs.defaults() => const MetricsCarouselPrefs(
        pages: [
          CarouselPageConfig(
            id: CarouselPageId.training,
            enabled: true,
            slots: [
              CarouselSlotId.volumeKg,
              CarouselSlotId.timeHrs,
              CarouselSlotId.newPrs,
            ],
          ),
          CarouselPageConfig(id: CarouselPageId.volumeTrend, enabled: true),
          CarouselPageConfig(id: CarouselPageId.muscleBalance, enabled: false),
          CarouselPageConfig(id: CarouselPageId.prLadder, enabled: false),
          // Enabled by default so Recovery appears the moment Health connects
          // + readiness data exists — actual on-Home visibility is gated
          // separately (health connected AND readiness data present), never
          // by this flag alone. Disabling here is the user opting OUT even
          // once available.
          CarouselPageConfig(id: CarouselPageId.recovery, enabled: true),
        ],
      );

  /// Guarantees every [CarouselPageId] has an entry (defensive — covers a
  /// prefs blob written by an older build before a page type existed) and
  /// that [pages] never exceeds [kCarouselMaxPages].
  MetricsCarouselPrefs _normalized() {
    final byId = {for (final p in pages) p.id: p};
    final defaults = {for (final p in MetricsCarouselPrefs.defaults().pages) p.id: p};
    final merged = <CarouselPageConfig>[
      for (final p in pages)
        if (byId.containsKey(p.id)) p,
    ];
    for (final id in CarouselPageId.values) {
      if (!merged.any((p) => p.id == id)) {
        merged.add(defaults[id]!);
      }
    }
    return MetricsCarouselPrefs(pages: merged.take(kCarouselMaxPages).toList());
  }

  Map<String, dynamic> toJson() => {
        'pages': [for (final p in pages) p.toJson()],
      };

  /// Tolerant decode. Returns [defaults] on any structural failure — never
  /// throws into the caller, matching the app's "corrupt cache => clean
  /// fallback, never crash" convention.
  factory MetricsCarouselPrefs.fromJson(Map<String, dynamic> json) {
    try {
      final rawPages = json['pages'];
      if (rawPages is! List) return MetricsCarouselPrefs.defaults();
      final pages = <CarouselPageConfig>[
        for (final raw in rawPages)
          if (raw is Map)
            if (CarouselPageConfig.fromJson(Map<String, dynamic>.from(raw))
                case final p?)
              p,
      ];
      if (pages.isEmpty) return MetricsCarouselPrefs.defaults();
      return MetricsCarouselPrefs(pages: pages)._normalized();
    } catch (_) {
      return MetricsCarouselPrefs.defaults();
    }
  }
}

/// The ordered list of pages the carousel actually shows, given [prefs] and
/// whether Recovery's data is available right now.
///
/// Pure function (no provider/BuildContext dependency) so the Recovery-hidden
/// guard and the "0/1 pages" pagination guard are unit-testable without
/// pumping a widget tree. [CarouselPageId.recovery] is dropped whenever
/// [recoveryAvailable] is false — not shown as an empty card, per the build
/// spec ("hidden entirely... not an empty card, not a placeholder").
List<CarouselPageId> visibleCarouselPages(
  MetricsCarouselPrefs prefs, {
  required bool recoveryAvailable,
}) {
  return [
    for (final page in prefs.pages)
      if (page.enabled)
        if (page.id != CarouselPageId.recovery || recoveryAvailable) page.id,
  ];
}
