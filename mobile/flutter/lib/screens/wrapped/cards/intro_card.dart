import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 1: Intro card - "Your [Month] Wrapped" with total workouts hero number
class WrappedIntroCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedIntroCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B69),
              Color(0xFF1A0F3C),
              Color(0xFF0A0612),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle radial glow behind the number
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // "Your [Month] Wrapped" title
                  Text(
                    'Your',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.monthDisplayName} Wrapped',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.yearDisplay,
                    style: TextStyle(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Large total workouts number
                  Text(
                    NumberFormat('#,###').format(data.totalWorkouts),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WORKOUTS COMPLETED',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),

                  const Spacer(flex: 3),

                  if (showWatermark) ...[
                    const AppWatermark(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
