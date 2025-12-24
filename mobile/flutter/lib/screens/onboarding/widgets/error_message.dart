import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';

/// Error message display widget.
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorMessage({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: colors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Text(
              'Dismiss',
              style: TextStyle(
                fontSize: 12,
                color: colors.error,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
