import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// An action item for [PillAppBar].
///
/// Each action is rendered as a 44×44 circle pill.
class PillAppBarAction {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// When false the pill is hidden (use for conditional actions).
  final bool visible;

  const PillAppBarAction({
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.visible = true,
  });
}

/// Drop-in [AppBar] replacement that renders the back button, title, and
/// action buttons as a connected row of pills — exactly like the Settings
/// screen.
///
/// Uses `MediaQuery.of(context).padding.top + 8` for precise status-bar
/// spacing (same approach as the Settings screen).
///
/// **Usage:**
/// ```dart
/// appBar: PillAppBar(
///   title: 'Stats & Scores',
///   actions: [
///     PillAppBarAction(icon: Icons.calendar_month_outlined, onTap: () {}),
///   ],
/// ),
/// ```
class PillAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// If null, defaults to `context.pop()`.
  final VoidCallback? onBack;

  final List<PillAppBarAction> actions;

  /// Set to false for top-level tabs that have no back navigation.
  final bool showBack;

  const PillAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final iconColor = isDark ? Colors.white70 : AppColorsLight.textSecondary;
    final border = isDark
        ? null
        : Border.all(
            color: AppColorsLight.cardBorder.withValues(alpha: 0.3),
          );
    final shadow = BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );

    BoxDecoration pillDecor() => BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(22),
          border: border,
          boxShadow: [shadow],
        );

    final visibleActions =
        actions.where((a) => a.visible).toList();

    // Use the same spacing as the Settings screen:
    // MediaQuery.padding.top + 8px
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: statusBarHeight + 8 + 44 + 8, // status bar + gap + pill + bottom
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, 8),
        child: Row(
          children: [
            // Back button circle (hidden for top-level tabs)
            if (showBack) ...[
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  if (onBack != null) {
                    onBack!();
                  } else if (context.canPop()) {
                    context.pop();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: pillDecor(),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Title pill — expands to fill remaining space
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: pillDecor(),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),

            // Action circles
            for (final action in visibleActions) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  action.onTap?.call();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: pillDecor(),
                  child: Icon(
                    action.icon,
                    color: action.iconColor ?? iconColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
