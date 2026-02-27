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

  const GlassBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const size = 40.0;

    return Center(
      child: GestureDetector(
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
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.1),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
