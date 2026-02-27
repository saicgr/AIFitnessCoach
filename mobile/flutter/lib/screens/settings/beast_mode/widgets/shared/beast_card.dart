import 'package:flutter/material.dart';
import '../../beast_mode_constants.dart';

/// Reusable card wrapper used across all Beast Mode sections.
class BeastCard extends StatelessWidget {
  final BeastThemeData theme;
  final Widget child;

  const BeastCard({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardBorder),
      ),
      child: child,
    );
  }
}
