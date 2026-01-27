import 'dart:ui';
import 'package:flutter/material.dart';

/// Transparent bottom sheet that blurs content behind it.
///
/// Creates a modern iOS/Samsung style glassmorphic effect where
/// the content underneath the sheet is visible but blurred.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: Colors.transparent,  // CRITICAL
///   isScrollControlled: true,
useRootNavigator: true,
///   builder: (context) => GlassSheet(
///     child: YourSheetContent(),
///   ),
/// );
/// ```
class GlassSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFraction;
  final double blurSigma;
  final double borderRadius;

  const GlassSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.9,
    this.blurSigma = 25,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            // Semi-transparent background lets blurred content show through
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
