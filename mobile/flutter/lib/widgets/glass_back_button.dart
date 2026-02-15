import 'dart:ui';
import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: GestureDetector(
          onTap: onTap ?? () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(size / 2),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black87,
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
