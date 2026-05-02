import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../nutrition/widgets/log_meal_helpers.dart';
import 'demo_tasks_screen.dart';

/// Nutrition Showcase — Onboarding v5
///
/// 4-frame user-paced tap-through. Mockups visually match the production
/// LogMealSheet + MenuAnalysisSheet flow without requiring auth, camera,
/// or backend calls. Pre-cached menu data + pre-cached analysis result.
class NutritionShowcaseScreen extends ConsumerStatefulWidget {
  const NutritionShowcaseScreen({super.key});

  @override
  ConsumerState<NutritionShowcaseScreen> createState() =>
      _NutritionShowcaseScreenState();
}

class _NutritionShowcaseScreenState
    extends ConsumerState<NutritionShowcaseScreen> {
  int _frame = 0;

  /// Lifted from Frame 3 so Frame 4 can read which dishes the user
  /// actually selected and render the matching cal/macro totals + dish
  /// list. Seeded with one prominent pick so the demo's first paint of
  /// Frame 4 looks reasonable even if the user skipped through fast.
  Set<String> _selectedDishes = {'Grilled Salmon Bowl'};

  /// CTA label per frame — verb-led so each tap maps to a real action,
  /// not a generic "continue".
  String get _ctaLabel {
    switch (_frame) {
      case 0:
        return 'Tap to scan menu →';
      case 1:
        return 'See results →';
      case 2:
        return 'Log them →';
      case 3:
      default:
        return "I'm in →";
    }
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_frame < 3) {
      setState(() => _frame++);
      return;
    }
    _markComplete();
  }

  Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DemoTasksScreen.nutritionDoneKey, true);
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_nutrition_showcase_completed',
        );
    if (mounted) context.pop();
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_nutrition_showcase_skipped',
          properties: {'frame': _frame},
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textPrimary),
                    onPressed: _skip,
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(4, (i) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: i < 3 ? 3 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _frame
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFF2ECC71)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Frame body. Frame 0 doesn't tap-anywhere-to-advance —
            // the pulsating menu icon is the only valid trigger so the
            // demo feels like a real interaction. Frames 1-3 keep the
            // tap-anywhere behavior since they're passive reveals.
            Expanded(
              child: _frame == 0
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _buildFrame(_frame, isDark),
                    )
                  : GestureDetector(
                      onTap: _next,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _buildFrame(_frame, isDark),
                      ),
                    ),
            ),
            // Bottom CTA — hidden on Frame 0 because the user is
            // expected to actually tap the pulsating menu icon (real
            // apptaste, not a generic continue button).
            if (_frame > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _ctaLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrame(int idx, bool isDark) {
    switch (idx) {
      case 0:
        return _Frame1Sheet(
          key: const ValueKey('n0'),
          isDark: isDark,
          onScanMenu: _next,
        );
      case 1:
        return _Frame2Scanning(key: const ValueKey('n1'), isDark: isDark);
      case 2:
        return _Frame3Result(
          key: const ValueKey('n2'),
          isDark: isDark,
          initialSelection: _selectedDishes,
          onSelectionChanged: (next) =>
              setState(() => _selectedDishes = next),
        );
      case 3:
        return _Frame4Logged(
          key: const ValueKey('n3'),
          isDark: isDark,
          selectedDishNames: _selectedDishes,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Frame 1: log meal sheet with 4 tabs visible
/// Frame 1 — faithful clone of the real Log-a-Meal bottom sheet.
/// Top: Daily/Recipes/Patterns/Fuel tabs · time + meal-type pickers ·
/// "What did you eat?" field with mic · Recent/Saved/Food DB pills.
/// Bottom: 5 colored ActionIconButton tiles + Analyze pill + 🔥 macro
/// footer. Matches `lib/screens/nutrition/log_meal_sheet*.dart`.
///
/// The menu-scan tile pulses + carries an arrow indicator so the demo
/// feels like a real apptaste — the user actually taps the menu icon
/// to advance, not a generic "Tap to continue" CTA.
class _Frame1Sheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onScanMenu;
  const _Frame1Sheet({
    super.key,
    required this.isDark,
    required this.onScanMenu,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          // ── Header row: back · "Today" · history · bookmark · share · stats · settings
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardBg,
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: textPrimary, size: 18),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left,
                        color: textSecondary, size: 16),
                    Icon(Icons.calendar_today_rounded,
                        color: textPrimary, size: 14),
                    const SizedBox(width: 6),
                    Text('Today',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: textSecondary, size: 16),
                  ],
                ),
              ),
              const Spacer(),
              _headerIcon(Icons.history_rounded, textSecondary),
              const SizedBox(width: 8),
              _headerIcon(Icons.bookmark_border_rounded,
                  const Color(0xFFEAB308)),
              const SizedBox(width: 8),
              _headerIcon(Icons.share_outlined, textSecondary),
              const SizedBox(width: 8),
              _headerIcon(Icons.bar_chart_rounded, textSecondary),
              const SizedBox(width: 8),
              _headerIcon(Icons.settings_outlined, textSecondary),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          // ── Tab strip
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _tabPill('Daily', Icons.restaurant_rounded, true,
                    textPrimary, cardBg),
                _tabPill('Recipes', Icons.menu_book_rounded, false,
                    textSecondary, cardBg),
                _tabPill('Patterns', Icons.show_chart_rounded, false,
                    textSecondary, cardBg),
                _tabPill('Fuel', Icons.bolt_rounded, false, textSecondary,
                    cardBg),
              ],
            ),
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 12),
          // ── Time + meal-type pickers
          Row(
            children: [
              _pickerPill(
                icon: Icons.access_time_rounded,
                label: '17:11',
                bg: cardBg,
                fg: textPrimary,
              ),
              const SizedBox(width: 8),
              _pickerPill(
                emoji: '🌙',
                label: 'Dinner',
                bg: cardBg,
                fg: textPrimary,
              ),
            ],
          ).animate(delay: 140.ms).fadeIn(),
          const SizedBox(height: 12),
          // ── "What did you eat?" TextField
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'What did you eat?',
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(Icons.mic_none_rounded,
                    color: textSecondary, size: 18),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 12),
          // ── Recent / Saved / Food DB pill row (inline clone of
          // _BrowseFilterTabs from food_browser_panel — same visual,
          // demo-only state)
          Row(
            children: [
              _filterPill(
                icon: Icons.access_time_rounded,
                label: 'Recent',
                selected: true,
              ),
              const SizedBox(width: 8),
              _filterPill(
                icon: Icons.bookmark_border_rounded,
                label: 'Saved',
                selected: false,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _filterPill(
                icon: Icons.storage_rounded,
                label: 'Food DB',
                selected: false,
                isDark: isDark,
              ),
            ],
          ).animate(delay: 260.ms).fadeIn(),
          const SizedBox(height: 14),
          // ── Empty content area: faded skeleton bars
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => Container(
                height: 56,
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              )
                  .animate(delay: (320 + i * 80).ms)
                  .fadeIn(duration: 600.ms),
            ),
          ),
          // ── 5 ActionIconButton tiles + Analyze pill. The menu-scan
          // tile owns its own tooltip + arrow indicator (in the same
          // column), so the indicator stays anchored to the tile no
          // matter the screen size, tile order, or spacing.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ActionIconButton(
                icon: Icons.camera_alt_rounded,
                onTap: () {},
                isDark: isDark,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              ActionIconButton(
                icon: Icons.photo_library_outlined,
                onTap: () {},
                isDark: isDark,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              _PulsingMenuTile(onTap: onScanMenu, isDark: isDark),
              const SizedBox(width: 6),
              ActionIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onTap: () {},
                isDark: isDark,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              ActionIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () {},
                isDark: isDark,
                color: AppColors.onboardingAccent,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.onboardingAccent,
                      Color(0xFFFF6B00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Analyze',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate(delay: 380.ms).fadeIn(),
          const SizedBox(height: 8),
          // ── 🔥 Macro footer pill (hardcoded targets, no provider)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                _macroPart('0', '/2000', textPrimary, textSecondary),
                _sep(textSecondary),
                _macroPart('C 0', '/200', const Color(0xFFEAB308),
                    textSecondary),
                _sep(textSecondary),
                _macroPart('P 0', '/150', const Color(0xFFA855F7),
                    textSecondary),
                _sep(textSecondary),
                _macroPart(
                    'F 0', '/65', const Color(0xFFFB7185), textSecondary),
              ],
            ),
          ).animate(delay: 440.ms).fadeIn(),
          // Annotation removed — the pulsing menu tile + arrow tooltip
          // already directs the user. Two simultaneous "tap me" cues
          // would compete instead of guide.
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, Color color) {
    return Icon(icon, color: color, size: 18);
  }

  Widget _tabPill(String label, IconData icon, bool active,
      Color color, Color cardBg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.black : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.black : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerPill({
    IconData? icon,
    String? emoji,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: fg, size: 14)
          else
            Text(emoji ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded, color: fg, size: 14),
        ],
      ),
    );
  }

  Widget _filterPill({
    required IconData icon,
    required String label,
    required bool selected,
    bool isDark = true,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.onboardingAccent
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.onboardingAccent
              : (isDark
                  ? AppColors.cardBorder
                  : AppColorsLight.cardBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColorsLight.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroPart(
      String value, String target, Color valueColor, Color targetColor) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        Text(
          target,
          style: TextStyle(
            fontSize: 11,
            color: targetColor,
          ),
        ),
      ],
    );
  }

  Widget _sep(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Frame 2: menu scan in progress
class _Frame2Scanning extends StatelessWidget {
  final bool isDark;
  const _Frame2Scanning({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Scanning menu…',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Multiple pages? Snap them all.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E9D4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: SingleChildScrollView(
                        physics:
                            const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'THE BISTRO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.brown[800],
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                '— Lunch & Dinner —',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.brown[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _MenuSectionHeader(title: 'STARTERS'),
                            _MenuItemMock(
                                'Burrata & Heirloom Tomato', '\$13'),
                            _MenuItemMock('Crispy Calamari', '\$15'),
                            _MenuItemMock('Caesar Salad', '\$14'),
                            const SizedBox(height: 10),
                            _MenuSectionHeader(title: 'MAINS'),
                            _MenuItemMock('Grilled Salmon Bowl', '\$22'),
                            _MenuItemMock('Margherita Pizza', '\$16'),
                            _MenuItemMock('Garden Risotto', '\$18'),
                            _MenuItemMock('Beef Burger · Truffle Fries',
                                '\$19'),
                            _MenuItemMock(
                                'Roasted Half Chicken', '\$21'),
                            const SizedBox(height: 10),
                            _MenuSectionHeader(title: 'PASTA'),
                            _MenuItemMock('Cacio e Pepe', '\$17'),
                            _MenuItemMock('Lobster Tagliatelle', '\$28'),
                            const SizedBox(height: 10),
                            _MenuSectionHeader(title: 'DESSERTS'),
                            _MenuItemMock('Tiramisu', '\$10'),
                          ],
                        ),
                      ),
                    ),
                    // Animated scan line
                    _ScanLine(),
                    // Corner brackets
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Bracket(),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _Bracket(rotateDeg: 90),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _Bracket(rotateDeg: -90),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _Bracket(rotateDeg: 180),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NutritionAnnotation(
            text:
                'Point at any menu — paper, screen, or photo. Multi-image supported (snap several pages at once).',
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ── Frame 3: parsed menu — production menu_analysis_sheet replica with
// section grouping, sort pills, filter button, and a live totals footer
// that updates as the user toggles dishes.
class _Frame3Result extends StatefulWidget {
  final bool isDark;
  final Set<String> initialSelection;
  final ValueChanged<Set<String>> onSelectionChanged;
  const _Frame3Result({
    super.key,
    required this.isDark,
    required this.initialSelection,
    required this.onSelectionChanged,
  });

  @override
  State<_Frame3Result> createState() => _Frame3ResultState();
}

/// Inflammation level — what every dish row surfaces instead of an
/// abstract A/B/C/D grade. Maps to the production health-strip
/// inflammation pill (see `_HealthStrip` in `menu_analysis_item_card`).
enum _Inflammation { low, medium, high }

extension _InflammationStyle on _Inflammation {
  String get label {
    switch (this) {
      case _Inflammation.low:
        return 'Low';
      case _Inflammation.medium:
        return 'Med';
      case _Inflammation.high:
        return 'High';
    }
  }

  String get emoji {
    switch (this) {
      case _Inflammation.low:
        return '🌿';
      case _Inflammation.medium:
        return '⚖️';
      case _Inflammation.high:
        return '🔥';
    }
  }

  Color get color {
    switch (this) {
      case _Inflammation.low:
        return const Color(0xFF22C55E); // green
      case _Inflammation.medium:
        return const Color(0xFFEAB308); // amber
      case _Inflammation.high:
        return const Color(0xFFEF4444); // red
    }
  }

  /// Sort key — higher = worse (more inflammatory). Frame 3's "Health"
  /// sort flips the sign so the LEAST inflammatory dishes float to top.
  int get sortKey {
    switch (this) {
      case _Inflammation.low:
        return 1;
      case _Inflammation.medium:
        return 2;
      case _Inflammation.high:
        return 3;
    }
  }
}

/// Mock dish record shared by Frame 3 (menu analysis) and Frame 4
/// (logged confirmation). Exposed as a top-level const so the parent
/// showcase state can use the master list for both frames.
class _Dish {
  final String section;
  final String name;
  final String price;
  final int cal;
  final int p;
  final int c;
  final int f;
  final int weightG;
  final _Inflammation inflammation;
  const _Dish({
    required this.section,
    required this.name,
    required this.price,
    required this.cal,
    required this.p,
    required this.c,
    required this.f,
    required this.weightG,
    required this.inflammation,
  });
}

/// Master dish list — Frame 3 lists/sorts these, Frame 4 reads back the
/// user's selections to render the calorie ring + macro chips + logged
/// rows. Single source of truth so the demo's narrative stays coherent.
// Inflammation grades reflect typical food-research consensus:
//   • Salmon, vegetables, olive oil, lean protein → low (anti-inflammatory)
//   • Pasta, refined carbs, fried foods, dairy fat → medium
//   • Heavy fried + processed + sugar-heavy desserts → high
const _kAllDishes = <_Dish>[
  _Dish(
      section: 'STARTERS',
      name: 'Burrata & Heirloom Tomato',
      price: '\$13',
      cal: 320,
      p: 14,
      c: 12,
      f: 22,
      weightG: 220,
      inflammation: _Inflammation.medium),
  _Dish(
      section: 'STARTERS',
      name: 'Crispy Calamari',
      price: '\$15',
      cal: 480,
      p: 22,
      c: 36,
      f: 26,
      weightG: 240,
      inflammation: _Inflammation.high),
  _Dish(
      section: 'STARTERS',
      name: 'Caesar Salad',
      price: '\$14',
      cal: 340,
      p: 12,
      c: 18,
      f: 26,
      weightG: 280,
      inflammation: _Inflammation.low),
  _Dish(
      section: 'MAINS',
      name: 'Grilled Salmon Bowl',
      price: '\$22',
      cal: 520,
      p: 38,
      c: 42,
      f: 22,
      weightG: 410,
      inflammation: _Inflammation.low),
  _Dish(
      section: 'MAINS',
      name: 'Margherita Pizza',
      price: '\$16',
      cal: 680,
      p: 24,
      c: 78,
      f: 28,
      weightG: 320,
      inflammation: _Inflammation.medium),
  _Dish(
      section: 'MAINS',
      name: 'Garden Risotto',
      price: '\$18',
      cal: 540,
      p: 14,
      c: 72,
      f: 18,
      weightG: 350,
      inflammation: _Inflammation.medium),
  _Dish(
      section: 'MAINS',
      name: 'Beef Burger · Truffle Fries',
      price: '\$19',
      cal: 920,
      p: 42,
      c: 64,
      f: 48,
      weightG: 480,
      inflammation: _Inflammation.high),
  _Dish(
      section: 'MAINS',
      name: 'Roasted Half Chicken',
      price: '\$21',
      cal: 720,
      p: 58,
      c: 18,
      f: 42,
      weightG: 420,
      inflammation: _Inflammation.low),
  _Dish(
      section: 'PASTA',
      name: 'Cacio e Pepe',
      price: '\$17',
      cal: 780,
      p: 22,
      c: 96,
      f: 32,
      weightG: 360,
      inflammation: _Inflammation.medium),
  _Dish(
      section: 'PASTA',
      name: 'Lobster Tagliatelle',
      price: '\$28',
      cal: 860,
      p: 38,
      c: 92,
      f: 36,
      weightG: 380,
      inflammation: _Inflammation.medium),
  _Dish(
      section: 'DESSERTS',
      name: 'Tiramisu',
      price: '\$10',
      cal: 460,
      p: 8,
      c: 48,
      f: 24,
      weightG: 160,
      inflammation: _Inflammation.high),
];

enum _SortField { protein, carbs, fat, inflammation }

extension _SortLabel on _SortField {
  String get label {
    switch (this) {
      case _SortField.protein:
        return 'Protein';
      case _SortField.carbs:
        return 'Carbs';
      case _SortField.fat:
        return 'Fat';
      case _SortField.inflammation:
        return 'Inflam';
    }
  }
}

class _Frame3ResultState extends State<_Frame3Result> {
  // 11 dishes across 4 sections — matches the scanned menu in Frame 2.

  // Selected dish names — seeded from the parent's lifted set so the
  // selection survives Frame 3 → Frame 4 → back navigation. Every
  // mutation also fires the parent callback.
  late final Set<String> _selected = {...widget.initialSelection};
  _SortField? _activeSort;
  bool _ascending = false;

  void _toggle(String name) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
    widget.onSelectionChanged({..._selected});
  }

  void _tapSort(_SortField f) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activeSort == f) {
        // Cycle: descending → ascending → off (matches production
        // SortSpecList.tap behavior).
        if (!_ascending) {
          _ascending = true;
        } else {
          _activeSort = null;
          _ascending = false;
        }
      } else {
        _activeSort = f;
        _ascending = false;
      }
    });
  }

  /// Returns the dishes grouped by section, with each group's items
  /// sorted according to the active sort (if any).
  Map<String, List<_Dish>> _grouped() {
    final out = <String, List<_Dish>>{};
    for (final d in _kAllDishes) {
      out.putIfAbsent(d.section, () => []).add(d);
    }
    if (_activeSort != null) {
      int compare(_Dish a, _Dish b) {
        final av = _value(a, _activeSort!);
        final bv = _value(b, _activeSort!);
        return _ascending ? av.compareTo(bv) : bv.compareTo(av);
      }

      for (final list in out.values) {
        list.sort(compare);
      }
    }
    return out;
  }

  num _value(_Dish d, _SortField f) {
    switch (f) {
      case _SortField.protein:
        return d.p;
      case _SortField.carbs:
        return d.c;
      case _SortField.fat:
        return d.f;
      case _SortField.inflammation:
        // Sort key: low=1, med=2, high=3. Default (descending) puts
        // worst first; tap again for ascending = least inflammatory first.
        return d.inflammation.sortKey;
    }
  }

  ({int cal, int p, int c, int f}) _selectedTotals() {
    int cal = 0, p = 0, c = 0, f = 0;
    for (final d in _kAllDishes) {
      if (!_selected.contains(d.name)) continue;
      cal += d.cal;
      p += d.p;
      c += d.c;
      f += d.f;
    }
    return (cal: cal, p: p, c: c, f: f);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final grouped = _grouped();
    final totals = _selectedTotals();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Menu analyzed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2ECC71), size: 12),
                SizedBox(width: 4),
                Text(
                  '11 dishes · 4 sections',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Sort row — mirrors production's _quickSortRow.
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert_rounded,
                        size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Sort:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                for (final f in _SortField.values) ...[
                  _SortPill(
                    field: f,
                    activeSort: _activeSort,
                    ascending: _ascending,
                    onTap: () => _tapSort(f),
                  ),
                  const SizedBox(width: 6),
                ],
                _FilterButton(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final entry in grouped.entries) ...[
                  _SectionHeader(
                    title: entry.key,
                    count: entry.value.length,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  ...entry.value.map((d) => _DishRow(
                        dish: d,
                        isDark: isDark,
                        selected: _selected.contains(d.name),
                        onTap: () => _toggle(d.name),
                      )),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          // ── Live totals footer — updates as items toggle.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _selected.isEmpty
                  ? cardBg
                  : AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selected.isEmpty
                    ? (isDark
                        ? AppColors.cardBorder
                        : AppColorsLight.cardBorder)
                    : AppColors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: _selected.isEmpty
                      ? textSecondary
                      : AppColors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_selected.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _selected.isEmpty
                        ? textSecondary
                        : AppColors.orange,
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      children: [
                        TextSpan(
                          text: '${totals.cal} ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444)),
                        ),
                        const TextSpan(text: 'cal · '),
                        TextSpan(
                          text: '${totals.p}g ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF22C55E)),
                        ),
                        const TextSpan(text: 'P · '),
                        TextSpan(
                          text: '${totals.c}g ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEAB308)),
                        ),
                        const TextSpan(text: 'C · '),
                        TextSpan(
                          text: '${totals.f}g ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFA855F7)),
                        ),
                        const TextSpan(text: 'F'),
                      ],
                    ),
                  )
                else
                  Text(
                    'Tap a dish to select',
                    style:
                        TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact row — replaces the previous big-card `_DishResult` so all
/// 12 dishes (+ section headers) fit in the viewport without scrolling
/// past the totals footer.
class _DishRow extends StatelessWidget {
  final _Dish dish;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;
  const _DishRow({
    required this.dish,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange.withValues(alpha: 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.orange.withValues(alpha: 0.4)
                : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: selected ? AppColors.orange : textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(fontSize: 10, color: textSecondary),
                      children: [
                        TextSpan(
                          text: '${dish.cal}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444)),
                        ),
                        const TextSpan(text: ' cal · '),
                        TextSpan(
                          text: '${dish.p}P',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF22C55E)),
                        ),
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: '${dish.c}C',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEAB308)),
                        ),
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: '${dish.f}F',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFA855F7)),
                        ),
                        TextSpan(
                          text: '   ${dish.price}',
                          style: TextStyle(color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Inflammation pill — emoji + label in a colored capsule.
            // Replaces the abstract A/B/C/D rating with a real health
            // signal (mirrors production's inflammation chip).
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: dish.inflammation.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dish.inflammation.color.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dish.inflammation.emoji,
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    dish.inflammation.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: dish.inflammation.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2, left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final _SortField field;
  final _SortField? activeSort;
  final bool ascending;
  final VoidCallback onTap;
  const _SortPill({
    required this.field,
    required this.activeSort,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeSort == field;
    final arrow = !active
        ? null
        : (ascending
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.orange.withValues(alpha: 0.55)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              field.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active
                    ? AppColors.orange
                    : (isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary),
              ),
            ),
            if (arrow != null) ...[
              const SizedBox(width: 3),
              Icon(arrow, size: 12, color: AppColors.orange),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorder
              : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_rounded,
              size: 12,
              color: isDark
                  ? AppColors.textPrimary
                  : AppColorsLight.textPrimary),
          const SizedBox(width: 4),
          Text(
            'Filter',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimary
                  : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frame 4: logged into food history
class _Frame4Logged extends StatelessWidget {
  final bool isDark;
  final Set<String> selectedDishNames;
  const _Frame4Logged({
    super.key,
    required this.isDark,
    required this.selectedDishNames,
  });

  // Macro colors — match Frame 3 + the rest of the demo so the visual
  // language is consistent (cal red, P green, C amber, F purple).
  static const _calColor = Color(0xFFEF4444);
  static const _pColor = Color(0xFF22C55E);
  static const _cColor = Color(0xFFEAB308);
  static const _fColor = Color(0xFFA855F7);
  static const _calorieGoal = 2100;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Compute totals from the selection passed in by Frame 3.
    final logged = _kAllDishes
        .where((d) => selectedDishNames.contains(d.name))
        .toList();
    int cal = 0, p = 0, c = 0, f = 0;
    for (final d in logged) {
      cal += d.cal;
      p += d.p;
      c += d.c;
      f += d.f;
    }
    final ringValue =
        (cal / _calorieGoal).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Calorie ring — value derived from selected dishes.
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 14,
                    color: _calColor,
                    backgroundColor: _calColor.withValues(alpha: 0.15),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$cal',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'of $_calorieGoal cal',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .scale(curve: Curves.easeOutCubic, duration: 600.ms),
          const SizedBox(height: 16),
          // Macros bar — colors aligned with the rest of the demo:
          // P = green, C = amber, F = purple (same convention as
          // the macro footer, dish row, and Frame 3 totals).
          Row(
            children: [
              _MacroChip('P', '${p}g', _pColor),
              const SizedBox(width: 8),
              _MacroChip('C', '${c}g', _cColor),
              const SizedBox(width: 8),
              _MacroChip('F', '${f}g', _fColor),
            ],
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 16),
          // Logged dish list — every item the user picked in Frame 3.
          if (logged.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No dishes selected — go back and pick a few.',
                style: TextStyle(fontSize: 13, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: logged.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final d = logged[i];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Inflammation badge — emoji on a colored
                        // square. Same signal Frame 3 surfaces.
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: d.inflammation.color
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            d.inflammation.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${d.cal} cal · just now',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded,
                            color: _pColor, size: 20),
                      ],
                    ),
                  )
                      .animate(delay: (300 + i * 60).ms)
                      .fadeIn()
                      .slideY(begin: 0.1);
                },
              ),
            ),
          const SizedBox(height: 8),
          _NutritionAnnotation(
                  text: 'Calories and macros update everywhere.')
              .animate(delay: 800.ms)
              .fadeIn(),
        ],
      ),
    );
  }
}

// ── Helpers

class _LogModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  final Color bg;
  final bool isDark;
  final bool highlighted;
  const _LogModeCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.bg,
    required this.isDark,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: highlighted
            ? Border.all(color: color, width: 2)
            : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (highlighted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemMock extends StatelessWidget {
  final String name;
  final String price;
  const _MenuItemMock(this.name, this.price);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.brown[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 11,
              color: Colors.brown[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Italic section header used by the categorized menu (STARTERS / MAINS /
/// PASTA / DESSERTS). Mimics a real restaurant menu's section dividers.
class _MenuSectionHeader extends StatelessWidget {
  final String title;
  const _MenuSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.brown.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.brown[700],
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.brown.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Positioned(
          left: 0,
          right: 0,
          top: 20 + _ctrl.value * (MediaQuery.of(context).size.height * 0.45),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF2ECC71),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2ECC71),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bracket extends StatelessWidget {
  final double rotateDeg;
  const _Bracket({this.rotateDeg = 0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateDeg * 3.14159 / 180,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _BracketPainter(),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2ECC71)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), p);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Mock of the real `MenuAnalysisItemCard` for the onboarding demo.
/// Mirrors the production card: checkbox + name + price + rating pill +
/// portion · macro line + selected-state orange tint. Selection toggles
/// locally so the demo feels interactive instead of static.
class _DishResult extends StatefulWidget {
  final int delay;
  final bool isDark;
  final String name;
  final String price;
  final int cal;
  final int p;
  final int c;
  final int f;
  final int weightG;
  final String rating;
  final Color ratingColor;
  final bool initiallySelected;
  const _DishResult({
    required this.delay,
    required this.isDark,
    required this.name,
    required this.price,
    required this.cal,
    required this.p,
    required this.c,
    required this.f,
    required this.weightG,
    required this.rating,
    required this.ratingColor,
    this.initiallySelected = false,
  });

  @override
  State<_DishResult> createState() => _DishResultState();
}

class _DishResultState extends State<_DishResult> {
  late bool _selected = widget.initiallySelected;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = !_selected);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: _selected
              ? AppColors.orange.withValues(alpha: 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selected
                ? AppColors.orange.withValues(alpha: 0.4)
                : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox — matches production MenuAnalysisItemCard.
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                _selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: _selected ? AppColors.orange : textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating pill row.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RatingPill(
                          rating: widget.rating,
                          color: widget.ratingColor),
                    ],
                  ),
                  // Portion + price line.
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${widget.weightG} g · ${widget.price}',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ),
                  // Macro line.
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _MacroLine(
                      cal: widget.cal,
                      p: widget.p,
                      c: widget.c,
                      f: widget.f,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: widget.delay.ms).fadeIn(duration: 350.ms).slideX(begin: 0.05);
  }
}

class _RatingPill extends StatelessWidget {
  final String rating;
  final Color color;
  const _RatingPill({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          rating,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final int cal, p, c, f;
  final Color color;
  const _MacroLine({
    required this.cal,
    required this.p,
    required this.c,
    required this.f,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    TextSpan macro(String label, int v, Color accent, {String unit = 'g'}) {
      return TextSpan(
        children: [
          TextSpan(
            text: '$v$unit ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          TextSpan(
            text: label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 11, color: color),
        children: [
          macro('cal', cal, const Color(0xFFEF4444), unit: ''),
          TextSpan(text: ' · ', style: TextStyle(color: color)),
          macro('P', p, const Color(0xFF22C55E)),
          TextSpan(text: ' · ', style: TextStyle(color: color)),
          macro('C', c, const Color(0xFFEAB308)),
          TextSpan(text: ' · ', style: TextStyle(color: color)),
          macro('F', f, const Color(0xFFA855F7)),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu-scan tile with a self-anchored tooltip + arrow indicator
/// stacked above it. Because the tooltip + arrow live in the same
/// Column as the tile (and the tile is rendered at its natural 44pt
/// width), the indicator auto-aligns to the tile's center on every
/// screen size — no hardcoded x-offsets. The Stack's `clipBehavior:
/// Clip.none` lets the tooltip overflow the column above the tile
/// without affecting the row's layout.
class _PulsingMenuTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _PulsingMenuTile({required this.onTap, required this.isDark});

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Tile itself — pulses to draw the eye to the tap target.
          ActionIconButton(
            icon: Icons.menu_book_outlined,
            onTap: onTap,
            isDark: isDark,
            color: _amber,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 700.ms,
                curve: Curves.easeInOut,
              ),
          // Down arrow — sits directly above the tile, bouncing toward it.
          Positioned(
            top: -28,
            child: const Icon(
              Icons.arrow_downward_rounded,
              size: 22,
              color: _amber,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 6, duration: 800.ms),
          ),
          // Tooltip — centered above the tile. Symmetric ±200pt
          // overflow gives a 444pt horizontal target around the 44pt
          // tile, plenty for the pill to lay out at intrinsic width
          // on every device from iPhone SE (320pt) up. `Center` +
          // `IntrinsicWidth` keep it horizontally centered regardless
          // of phone width, and `clipBehavior: Clip.none` on the
          // ancestor Stack lets the overflow render.
          Positioned(
            top: -64,
            left: -200,
            right: -200,
            child: Center(
              child: IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _amber.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Tap below to scan menu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -3, duration: 800.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionAnnotation extends StatelessWidget {
  final String text;
  const _NutritionAnnotation({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF2ECC71), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
