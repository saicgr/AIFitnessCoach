import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/providers/daily_xp_strip_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'components/daily_xp_strip.dart';
import 'contextual_banner.dart';
import '../../../widgets/double_xp_banner.dart';
import 'daily_crate_banner.dart';

/// Compact ~32dp strip that collapses all home screen banners into one line.
///
/// **Collapsed view (~32dp):**
/// Row of compact indicators: bolt icon + "X/Y goals", optional "2x" chip,
/// optional crate icon, and a dismiss (X) button.
///
/// **Expanded view:**
/// Column of full banner widgets (DailyXPStrip, ContextualBanner,
/// DoubleXPBanner, DailyCrateBanner), each wrapped in its own Dismissible.
///
/// Transition uses [AnimatedSize] with 300ms easeInOut.
class CollapsedBannerStrip extends ConsumerStatefulWidget {
  const CollapsedBannerStrip({super.key});

  @override
  ConsumerState<CollapsedBannerStrip> createState() =>
      _CollapsedBannerStripState();
}

class _CollapsedBannerStripState extends ConsumerState<CollapsedBannerStrip> {
  bool _isExpanded = false;
  bool _isDismissed = false;

  // Track individually dismissed banners in expanded view
  bool _dailyXPDismissed = false;
  bool _contextualDismissed = false;
  bool _doubleXPDismissed = false;
  bool _crateDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _isExpanded
          ? _buildExpandedView(context, isDark)
          : _buildCollapsedStrip(context, isDark),
    );
  }

  // ---------------------------------------------------------------------------
  // Collapsed strip (~32dp)
  // ---------------------------------------------------------------------------

  Widget _buildCollapsedStrip(BuildContext context, bool isDark) {
    final xpState = ref.watch(xpProvider);
    final doubleXPEvent = ref.watch(activeDoubleXPEventProvider);
    final dailyCrates = ref.watch(dailyCratesProvider);
    final dailyGoals = xpState.dailyGoals;

    final bgColor =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final completedGoals = dailyGoals?.completedCount ?? 0;
    final totalGoals = dailyGoals?.totalCount ?? 6;

    final hasDoubleXP = doubleXPEvent != null;
    final hasUnclaimed =
        dailyCrates != null && dailyCrates.hasAvailableCrate;

    return Dismissible(
      key: const ValueKey('collapsed_banner_strip'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticService.light();
        setState(() => _isDismissed = true);
      },
      background: const SizedBox.shrink(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: GestureDetector(
          onTap: () {
            HapticService.selection();
            setState(() => _isExpanded = true);
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Bolt icon + goals count
                Icon(
                  Icons.bolt,
                  size: 16,
                  color: textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$completedGoals/$totalGoals goals',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),

                // Double XP chip (conditional)
                if (hasDoubleXP) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '\u00b7',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '2x',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.orange : AppColorsLight.orange,
                      ),
                    ),
                  ),
                ],

                // Crate icon (conditional)
                if (hasUnclaimed) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '\u00b7',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: textSecondary,
                  ),
                ],

                const Spacer(),

                // Dismiss button
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    setState(() => _isDismissed = true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Expanded view - column of full banner widgets
  // ---------------------------------------------------------------------------

  Widget _buildExpandedView(BuildContext context, bool isDark) {
    final isStripVisible = ref.watch(dailyXPStripVisibleProvider);
    final doubleXPEvent = ref.watch(activeDoubleXPEventProvider);
    final showCrateBanner = ref.watch(showDailyCrateBannerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DailyXPStrip
        if (!_dailyXPDismissed && isStripVisible)
          Dismissible(
            key: const ValueKey('expanded_daily_xp'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              HapticService.light();
              setState(() => _dailyXPDismissed = true);
            },
            child: const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: DailyXPStrip(),
            ),
          ),

        // ContextualBanner
        if (!_contextualDismissed)
          Dismissible(
            key: const ValueKey('expanded_contextual'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              HapticService.light();
              setState(() => _contextualDismissed = true);
            },
            child: ContextualBanner(isDark: isDark),
          ),

        // DoubleXPBanner
        if (!_doubleXPDismissed && doubleXPEvent != null)
          Dismissible(
            key: const ValueKey('expanded_double_xp'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              HapticService.light();
              setState(() => _doubleXPDismissed = true);
            },
            child: const DoubleXPBanner(),
          ),

        // DailyCrateBanner
        if (!_crateDismissed && showCrateBanner)
          Dismissible(
            key: const ValueKey('expanded_crate'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              HapticService.light();
              setState(() => _crateDismissed = true);
            },
            child: const DailyCrateBanner(),
          ),
      ],
    );
  }
}
