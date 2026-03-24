import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/week1_tips_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Banner that surfaces one progressive feature tip per day during the
/// user's first week. Dismissed tips stay hidden for the rest of the day.
class Week1TipBanner extends ConsumerStatefulWidget {
  const Week1TipBanner({super.key});

  @override
  ConsumerState<Week1TipBanner> createState() => _Week1TipBannerState();
}

class _Week1TipBannerState extends ConsumerState<Week1TipBanner>
    with SingleTickerProviderStateMixin {
  static const _dismissPrefix = 'week1_tip_dismissed_';

  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _prefsLoaded = false;
  String? _dismissedFeatureToday;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnim = Tween<double>(begin: -24, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _loadDismissedState();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_dismissPrefix$_todayKey';
    final dismissed = prefs.getString(key);

    if (mounted) {
      setState(() {
        _dismissedFeatureToday = dismissed;
        _prefsLoaded = true;
      });
      // Animate in after a brief delay for smooth entrance
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _animController.forward();
      });
    }
  }

  Future<void> _dismiss(String featureKey) async {
    HapticService.light();
    await _animController.reverse();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_dismissPrefix$_todayKey', featureKey);

    if (mounted) {
      setState(() {
        _dismissedFeatureToday = featureKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) return const SizedBox.shrink();

    final tip = ref.watch(week1TipProvider);

    // Nothing to show, or this tip was already dismissed today
    if (tip == null || tip.featureKey == _dismissedFeatureToday) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Resolve accent color per theme
    final accent = isDark ? tip.accentColor : _lightAccent(tip.accentColor);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(opacity: _fadeAnim.value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tip.icon, color: accent, size: 24),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip.subtitle,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // "Try It" action
                if (tip.actionRoute != null)
                  TextButton(
                    onPressed: () {
                      HapticService.light();
                      context.push(tip.actionRoute!);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Try It',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Dismiss
                IconButton(
                  onPressed: () => _dismiss(tip.featureKey),
                  icon: Icon(Icons.close, size: 18, color: textSecondary),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Map dark-theme accent colors to their light-theme counterparts.
  Color _lightAccent(Color darkColor) {
    if (darkColor == AppColors.orange) return AppColorsLight.orange;
    if (darkColor == AppColors.cyan) return AppColorsLight.cyan;
    if (darkColor == AppColors.purple) return AppColorsLight.purple;
    if (darkColor == AppColors.success) return AppColorsLight.success;
    if (darkColor == AppColors.green) return AppColorsLight.green;
    return darkColor;
  }
}
