import 'package:flutter/material.dart';

/// Coming Soon badge that appears on program cards
/// Simple label in top-right corner without darkening the card
class ComingSoonOverlay extends StatelessWidget {
  const ComingSoonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Coming Soon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
