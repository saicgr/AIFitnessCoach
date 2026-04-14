import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';
import 'report_thumbnail_provider.dart';

/// Reports Hub — one catalog of every shareable report in the app.
///
/// Two view modes (toggled from the app bar):
///  - **Carousel (default)**: vertical swipe through big squircle cards, one
///    per report type, with a month header above and the report name below.
///    Modeled on the wallpaper-app style the user referenced.
///  - **List**: compact rows grouped into Training / Body / Lifestyle.
///
/// Favoriting persists per-user via SharedPreferences so hearts survive
/// app restarts without needing a backend round-trip.
class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

enum _HubView { carousel, list }

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  static const _favsPrefsKey = 'reports_hub_favorites';

  _HubView _view = _HubView.carousel; // default per user request
  Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'reports_hub_viewed');
    });
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_favsPrefsKey) ?? const [];
    if (mounted) setState(() => _favorites = stored.toSet());
  }

  Future<void> _toggleFavorite(String routeKey) async {
    HapticService.light();
    setState(() {
      if (_favorites.contains(routeKey)) {
        _favorites.remove(routeKey);
      } else {
        _favorites.add(routeKey);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favsPrefsKey, _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    final reports = _allReports();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Reports & Insights',
        actions: [
          PillAppBarAction(
            icon: _view == _HubView.carousel
                ? Icons.view_list_rounded
                : Icons.view_carousel_rounded,
            onTap: () {
              HapticService.selection();
              setState(() {
                _view =
                    _view == _HubView.carousel ? _HubView.list : _HubView.carousel;
              });
            },
          ),
        ],
      ),
      // KeyedSubtree on view mode forces a fresh PageController per carousel
      // mount — removes any risk of a stale controller being attached to a
      // second scroll view when the user flips views mid-animation.
      body: _view == _HubView.carousel
          ? _CarouselView(
              key: const ValueKey('reports-carousel'),
              reports: reports,
              isDark: isDark,
              favorites: _favorites,
              onToggleFavorite: _toggleFavorite,
            )
          : _ListView(
              reports: reports,
              isDark: isDark,
              favorites: _favorites,
              onToggleFavorite: _toggleFavorite,
            ),
    );
  }

  /// Single source of truth for the hub's contents. Both views iterate this.
  List<_ReportDef> _allReports() {
    return const [
      // Training
      _ReportDef(
        section: _Section.training,
        icon: Icons.insights_rounded,
        accent: AppColors.purple,
        title: 'Period Insights',
        subtitle: 'Workouts, time, calories by 1W / 1M / 3M / 6M / 1Y / YTD / Custom',
        route: '/summaries',
        gradient: [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF0F172A)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.emoji_events_rounded,
        accent: AppColors.orange,
        title: 'Personal Records',
        subtitle: 'Every lift PR you\'ve hit, ranked',
        route: '/stats/personal-records',
        gradient: [Color(0xFF422006), Color(0xFF92400E), Color(0xFF1A1008)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.accessibility_new_rounded,
        accent: AppColors.cyan,
        title: 'Muscle Strength',
        subtitle: 'Score per muscle group, trends & heatmap',
        route: '/stats/muscle-analytics',
        gradient: [Color(0xFF083344), Color(0xFF155E75), Color(0xFF0F172A)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.fitness_center_rounded,
        accent: AppColors.teal,
        title: '1-Rep Maxes',
        subtitle: 'Estimated 1RMs for every main lift',
        route: '/settings/my-1rms',
        gradient: [Color(0xFF042F2E), Color(0xFF0F766E), Color(0xFF134E4A)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.history_rounded,
        accent: AppColors.coral,
        title: 'Exercise History',
        subtitle: 'Progression curve for every exercise you\'ve done',
        route: '/stats/exercise-history',
        gradient: [Color(0xFF450A0A), Color(0xFF991B1B), Color(0xFF1F1517)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.military_tech_rounded,
        accent: AppColors.orange,
        title: 'Milestones',
        subtitle: 'Badges unlocked along your journey',
        route: '/stats/milestones',
        gradient: [Color(0xFF431407), Color(0xFF9A3412), Color(0xFF1C1917)],
      ),
      _ReportDef(
        section: _Section.training,
        icon: Icons.show_chart_rounded,
        accent: AppColors.purple,
        title: 'Progress Charts',
        subtitle: 'Volume, strength, and consistency over time',
        route: '/progress-charts',
        gradient: [Color(0xFF2E1065), Color(0xFF6D28D9), Color(0xFF0F0A2E)],
      ),
      // Body & Recovery
      _ReportDef(
        section: _Section.body,
        icon: Icons.monitor_weight_rounded,
        accent: AppColors.teal,
        title: 'Body Measurements',
        subtitle: 'Weight, body fat, circumference trends',
        route: '/measurements',
        gradient: [Color(0xFF134E4A), Color(0xFF0D9488), Color(0xFF042F2E)],
      ),
      _ReportDef(
        section: _Section.body,
        icon: Icons.bolt_rounded,
        accent: AppColors.cyan,
        title: 'Readiness & Recovery',
        subtitle: 'Sleep, fatigue, stress, readiness score',
        route: '/stats/readiness',
        gradient: [Color(0xFF164E63), Color(0xFF0891B2), Color(0xFF0F172A)],
      ),
      // Lifestyle
      _ReportDef(
        section: _Section.lifestyle,
        icon: Icons.restaurant_rounded,
        accent: AppColors.success,
        title: 'Nutrition',
        subtitle: 'Macros, calories, adherence',
        route: '/nutrition',
        gradient: [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF052E16)],
      ),
      _ReportDef(
        section: _Section.lifestyle,
        icon: Icons.auto_awesome_rounded,
        accent: AppColors.purple,
        title: 'Achievements',
        subtitle: 'Everything you\'ve earned in FitWiz',
        route: '/achievements',
        gradient: [Color(0xFF3B0764), Color(0xFF7E22CE), Color(0xFF1E1B4B)],
      ),
    ];
  }
}

enum _Section { training, body, lifestyle }

/// Declarative record of one report in the hub. Consumed by both views.
class _ReportDef {
  final _Section section;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String route;
  final List<Color> gradient;

  const _ReportDef({
    required this.section,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradient,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Carousel view — the default. Vertical PageView with peek + month header.
// ─────────────────────────────────────────────────────────────────────────

class _CarouselView extends ConsumerStatefulWidget {
  final List<_ReportDef> reports;
  final bool isDark;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  const _CarouselView({
    super.key,
    required this.reports,
    required this.isDark,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  ConsumerState<_CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends ConsumerState<_CarouselView> {
  late final PageController _pageController;
  int _currentPage = 0;
  // Months offset from the current month. 0 = current, -1 = one month
  // back, etc. Header chevrons mutate this so users can browse their
  // report history over time; cards/carousel are unaffected (that axis
  // is selection of which *report type* — the dial does that job).
  int _monthOffset = 0;

  @override
  void initState() {
    super.initState();
    // Vertical PageView with viewportFraction < 1 lets the previous and next
    // pages peek at the top/bottom — the signature look from the reference.
    _pageController = PageController(viewportFraction: 0.75);
  }

  /// Current month the header is scoped to. Built fresh on every build
  /// because DateTime.now() can shift if the app lives across midnight.
  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  /// Right chevron is disabled once we're on the current calendar month —
  /// there are no reports for months that haven't happened yet.
  bool get _canGoForward => _monthOffset < 0;

  void _stepMonth(int delta) {
    if (delta > 0 && !_canGoForward) return;
    HapticService.selection();
    setState(() => _monthOffset += delta);
  }

  /// Kick off a share sheet for the given report scoped to [month].
  ///
  /// Text-share today. When report snapshot rendering ships, this will
  /// render the card-sized summary to a PNG and `Share.shareXFiles` it
  /// so recipients get an actual visual instead of a link.
  Future<void> _shareReport(_ReportDef report, DateTime month) async {
    HapticService.light();
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final text = 'My FitWiz ${report.title} — $monthLabel\n${report.subtitle}';
    ref.read(posthogServiceProvider).capture(
      eventName: 'reports_hub_share_tapped',
      properties: {'route': report.route, 'month_offset': _monthOffset},
    );
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: '${report.title} — $monthLabel',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int target) {
    final clamped = target.clamp(0, widget.reports.length - 1);
    if (clamped == _currentPage) return;
    HapticService.selection();
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final monthLabel =
        DateFormat('MMM yyyy').format(_currentMonth).toUpperCase();

    return Column(
      children: [
        const SizedBox(height: 10),
        // Month/year header with prev / next chevron buttons. The label
        // is the time period the reports are scoped to; chevrons step
        // the month offset — they do *not* change the focused card.
        // (Card selection is handled by swipe and the dial below.)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChevronButton(
              icon: Icons.chevron_left_rounded,
              color: textPrimary,
              enabled: true, // past months are always valid
              onTap: () => _stepMonth(-1),
            ),
            const SizedBox(width: 12),
            // Animated label swaps with a subtle fade/slide when the
            // month changes so the chevron tap feels responsive.
            SizedBox(
              width: 120,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: Text(
                  monthLabel,
                  key: ValueKey(monthLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ChevronButton(
              icon: Icons.chevron_right_rounded,
              color: textPrimary,
              enabled: _canGoForward,
              onTap: () => _stepMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Card carousel. Each page wraps the card in an AnimatedBuilder that
        // reads live pageController offset to apply cover-flow scale + Y
        // rotation — adjacent cards recede and tilt toward the focused one.
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.reports.length,
            onPageChanged: (i) {
              if (!mounted) return;
              HapticService.selection();
              setState(() => _currentPage = i);
            },
            itemBuilder: (context, index) {
              final r = widget.reports[index];
              final page = _CarouselPage(
                report: r,
                month: _currentMonth,
                isFavorited: widget.favorites.contains(r.route),
                onToggleFavorite: () => widget.onToggleFavorite(r.route),
                onTap: () {
                  HapticService.selection();
                  context.push(r.route);
                },
                onShare: () => _shareReport(r, _currentMonth),
                onMaximize: () {
                  HapticService.selection();
                  context.push(r.route);
                },
              );
              // Siblings shrink, dim, and are pulled slightly inward so
              // their inner edges overlap the focused card's margin and
              // actually peek into the viewport. Driven by live
              // pageController offset for smooth motion during drag.
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double delta = (_currentPage - index).toDouble();
                  if (_pageController.positions.length == 1 &&
                      _pageController.position.haveDimensions) {
                    delta = (_pageController.page ?? _currentPage.toDouble()) -
                        index;
                  }
                  final absD = delta.abs();
                  final opacity = (1.0 - absD * 0.5).clamp(0.3, 1.0);
                  final scale = (1.0 - absD * 0.15).clamp(0.78, 1.0);
                  // delta > 0 → this page is to the *left* of focus, so
                  // translate it right (positive X) to pull it inward;
                  // delta < 0 → right sibling, translate left. The fall-
                  // off stops after one page (clamp ±1) so only immediate
                  // neighbors peek, not cards deeper in the stack.
                  final pull = delta.clamp(-1.0, 1.0) * 28.0;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(pull, 0),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: page,
              );
            },
          ),
        ),
        // Dial sits tight under the card. Drag to *glide* continuously
        // through pages (like a tuner knob); release snaps to the nearest
        // page. Tap-left/right steps by one for precision.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            if (!_pageController.hasClients) return;
            final pos = _pageController.position;
            // 2.6x scrub multiplier — dragging ~40px moves a full page,
            // so a slow drag glides smoothly while a quick one can cross
            // several cards without lifting the finger.
            const scrubSpeed = 2.6;
            final newPixels = (pos.pixels - details.delta.dx * scrubSpeed)
                .clamp(pos.minScrollExtent, pos.maxScrollExtent);
            _pageController.position.jumpTo(newPixels);
          },
          onHorizontalDragEnd: (details) {
            if (!_pageController.hasClients) return;
            // Snap to the nearest page. Flick velocity nudges the target
            // by ±1 so a quick flick keeps moving past the current card.
            final page = _pageController.page ?? _currentPage.toDouble();
            final v = details.primaryVelocity ?? 0;
            int target = page.round();
            if (v.abs() > 400) {
              target = (v < 0 ? page.ceil() : page.floor());
            }
            target = target.clamp(0, widget.reports.length - 1);
            _pageController.animateToPage(
              target,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          },
          onTapUp: (details) {
            final w = context.size?.width ?? 0;
            if (w == 0) return;
            _goToPage(_currentPage +
                (details.localPosition.dx < w / 2 ? -1 : 1));
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: _TallyIndicator(
              count: widget.reports.length,
              currentPage: _currentPage,
              pageController: _pageController,
              isDark: widget.isDark,
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }
}

/// One page inside the PageView. Just the card centered in the viewport —
/// labels are hoisted into the parent so they don't travel with the swipe.
class _CarouselPage extends StatelessWidget {
  final _ReportDef report;
  final DateTime month;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onMaximize;

  const _CarouselPage({
    required this.report,
    required this.month,
    required this.isFavorited,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onShare,
    required this.onMaximize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Center(
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: _SquircleCard(
            report: report,
            month: month,
            isFavorited: isFavorited,
            onToggleFavorite: onToggleFavorite,
            onTap: onTap,
            onShare: onShare,
            onMaximize: onMaximize,
          ),
        ),
      ),
    );
  }
}

class _SquircleCard extends ConsumerWidget {
  final _ReportDef report;
  final DateTime month;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onMaximize;

  const _SquircleCard({
    required this.report,
    required this.month,
    required this.isFavorited,
    required this.onToggleFavorite,
    required this.onTap,
    required this.onShare,
    required this.onMaximize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the lightweight thumbnail summary for this (report, month). When
    // it resolves to non-null, we replace "View report" with the live stat;
    // otherwise the card keeps its hero-icon placeholder look.
    final thumbAsync = ref.watch(reportThumbnailProvider(
      ReportThumbnailKey(route: report.route, month: month),
    ));
    final thumb = thumbAsync.asData?.value;
    // Aspect-ratio is owned by the parent (_CarouselPage). This widget fills
    // whatever box it's given so peek/scale animations stay smooth.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: report.gradient,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                // Tighter ambient shadow + wider colored glow so the card
                // feels like it floats over the backdrop.
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: report.accent.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                children: [
                // Accent-colored radial glow behind the icon — gives the
                // card a light source instead of reading as flat gradient.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.35),
                        radius: 0.9,
                        colors: [
                          report.accent.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative ring top-right
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -16,
                  right: -16,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Soft diagonal highlight — cheap specular pass.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Hero icon — lifted a touch above center so the title
                // ribbon at the bottom doesn't fight it for attention.
                Align(
                  alignment: const Alignment(0, -0.18),
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      report.icon,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
                // Sparkle accents — reference uses small stars; mirror that.
                Positioned(
                  top: 48,
                  left: 32,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  top: 96,
                  left: 58,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                // Title ribbon bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title sits smaller when there's a hero stat to
                        // promote — otherwise the title is the hero.
                        Text(
                          report.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: thumb != null ? 16 : 24,
                            fontWeight: thumb != null
                                ? FontWeight.w600
                                : FontWeight.w800,
                            height: 1.1,
                            letterSpacing: thumb != null ? 0.2 : 0,
                          ),
                        ),
                        if (thumb != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            thumb.primary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (thumb.secondary != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              thumb.secondary!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'View report',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Top-right action cluster: maximize then favorite.
                // Maximize is the primary "open the full report" affordance
                // and is placed BEFORE the heart so the eye flow reads
                // [open] [save].
                Positioned(
                  top: 14,
                  right: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CardCircleButton(
                        icon: Icons.fullscreen_rounded,
                        onTap: onMaximize,
                      ),
                      const SizedBox(width: 8),
                      _HeartButton(
                        isFavorited: isFavorited,
                        onTap: onToggleFavorite,
                      ),
                    ],
                  ),
                ),
                // Share pill — bottom right, visually balances the title
                // ribbon on the left and is the primary CTA for this hub.
                Positioned(
                  right: 14,
                  bottom: 16,
                  child: _SharePill(onTap: onShare),
                ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  final VoidCallback onTap;

  const _SharePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.ios_share_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round chevron button used in the month header to step the
/// carousel one card. Disabled (dimmed + ignored taps) at the ends so
/// users can't tap past the list bounds.
class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ChevronButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticService.selection();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Generic round dark-glass button used in the top-right cluster of a card.
/// Matches the heart's footprint so adjacent buttons read as a paired set.
class _CardCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CardCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 20),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onTap;

  const _HeartButton({required this.isFavorited, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            key: ValueKey(isFavorited),
            color: isFavorited
                ? const Color(0xFFFB7185)
                : Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Tally-mark page indicator — straight, evenly-spaced bars with a soft
/// edge fade. Matches the simple bar-strip look from the reference:
/// uniform spacing, one focused bar is thicker/taller, outer bars fade.
///
/// Animates continuously with the [pageController] so the focus slides
/// smoothly during a swipe rather than snapping at page-change boundaries.
class _TallyIndicator extends StatelessWidget {
  final int count;
  final int currentPage;
  final PageController pageController;
  final bool isDark;

  const _TallyIndicator({
    required this.count,
    required this.currentPage,
    required this.pageController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : Colors.black;

    // Drum geometry. Smaller radius = tighter wheel with more wrap. The
    // angle step is bumped in proportion so the *center* bar spacing stays
    // the same (≈ R · sin(step)) — the drum shrinks but bars don't.
    const arcR = 80.0;
    const thetaStep = 0.275;

    return SizedBox(
      // Stack sized so the drum can span horizontally and the small arc
      // drop has headroom.
      width: arcR * 2 + 40,
      height: 34,
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, _) {
          double pos = currentPage.toDouble();
          if (pageController.positions.length == 1 &&
              pageController.position.haveDimensions) {
            pos = pageController.page ?? pos;
          }

          return Stack(
            alignment: Alignment.center,
            children: List.generate(count, (i) {
              final offset = i - pos;
              final absOff = offset.abs();
              final isActive = absOff < 0.5;

              // Angle on the drum. Clamped just past ±π/2 so bars can
              // sweep fully edge-on and fade out — the "disappears around
              // the back" cue.
              final theta =
                  (offset * thetaStep).clamp(-1.55, 1.55).toDouble();

              // Projected X on the drum viewed head-on. sin compresses
              // naturally near the edges — bars 4/5/6/7 indices out all
              // bunch together because sin saturates.
              final x = arcR * math.sin(theta);
              // Tiny vertical drop so the strip reads as "top of a drum"
              // rather than a flat line, without looking like a visible
              // bowl. 6px at the extremes is enough to sell the depth.
              final y = 6.0 * (1 - math.cos(theta));

              final height = (22 - absOff * 1.0).clamp(14.0, 22.0);
              final width = isActive ? 3.2 : 2.0;

              // Asymmetric opacity kept — past marks (left) vivid, future
              // marks (right) fade as they roll behind the drum. cos(θ)
              // is the natural "facing-toward-viewer" factor and scales
              // the fade smoothly.
              final facing = math.cos(theta).clamp(0.0, 1.0);
              final opacity = offset <= 0
                  ? (0.35 + 0.65 * facing).clamp(0.0, 1.0).toDouble()
                  : (facing * facing).clamp(0.0, 1.0).toDouble();

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // perspective depth
                  ..translateByDouble(x, y, 0.0, 1.0)
                  ..rotateY(theta), // bars tilt tangent to drum surface
                child: Container(
                  width: width.toDouble(),
                  height: height,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List view — grouped rows. Clean (no share pill).
// ─────────────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<_ReportDef> reports;
  final bool isDark;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;

  const _ListView({
    required this.reports,
    required this.isDark,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    List<_ReportDef> inSection(_Section s) =>
        reports.where((r) => r.section == s).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        _SectionLabel(title: 'TRAINING', isDark: isDark),
        const SizedBox(height: 8),
        ...inSection(_Section.training).asMap().entries.map(
              (e) => _ListCard(
                report: e.value,
                isDark: isDark,
                isFavorited: favorites.contains(e.value.route),
                onToggleFavorite: () => onToggleFavorite(e.value.route),
              )
                  .animate()
                  .fadeIn(delay: (50 + 30 * e.key).ms)
                  .slideY(begin: 0.08),
            ),
        const SizedBox(height: 20),
        _SectionLabel(title: 'BODY & RECOVERY', isDark: isDark),
        const SizedBox(height: 8),
        ...inSection(_Section.body).asMap().entries.map(
              (e) => _ListCard(
                report: e.value,
                isDark: isDark,
                isFavorited: favorites.contains(e.value.route),
                onToggleFavorite: () => onToggleFavorite(e.value.route),
              )
                  .animate()
                  .fadeIn(delay: (150 + 30 * e.key).ms)
                  .slideY(begin: 0.08),
            ),
        const SizedBox(height: 20),
        _SectionLabel(title: 'LIFESTYLE', isDark: isDark),
        const SizedBox(height: 8),
        ...inSection(_Section.lifestyle).asMap().entries.map(
              (e) => _ListCard(
                report: e.value,
                isDark: isDark,
                isFavorited: favorites.contains(e.value.route),
                onToggleFavorite: () => onToggleFavorite(e.value.route),
              )
                  .animate()
                  .fadeIn(delay: (220 + 30 * e.key).ms)
                  .slideY(begin: 0.08),
            ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final _ReportDef report;
  final bool isDark;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;

  const _ListCard({
    required this.report,
    required this.isDark,
    required this.isFavorited,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.selection();
            context.push(report.route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: report.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(report.icon, color: report.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          report.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          report.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compact heart — keeps the list clean while still letting
                  // users pin favorites. Same persistence as carousel.
                  IconButton(
                    onPressed: onToggleFavorite,
                    padding: const EdgeInsets.all(6),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorited
                          ? const Color(0xFFFB7185)
                          : textMuted,
                      size: 18,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: textMuted, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
