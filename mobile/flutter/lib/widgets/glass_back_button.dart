import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Glassmorphic circular back button used consistently across all screens.
///
/// Usage in AppBar:
/// ```dart
/// appBar: AppBar(
///   automaticallyImplyLeading: false,
///   leading: const GlassBackButton(),
///   ...
/// )
/// ```
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const GlassBackButton({
    super.key,
    this.onTap,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const size = 34.0;

    return GestureDetector(
        onTap: onTap ?? () {
          if (context.canPop()) {
            context.pop();
          }
        },
        child: SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ),
    );
  }
}
