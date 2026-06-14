import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

import '../../../l10n/generated/app_localizations.dart';
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

                  // Month + Year
                  Text(
                    data.monthDisplayName.toUpperCase(),
                    style: ZType.disp(42,
                        color: Colors.white, height: 1, letterSpacing: 4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.yearDisplay,
                    style: ZType.lbl(18,
                        color: const Color(0xFFA855F7).withValues(alpha: 0.8),
                        letterSpacing: 4),
                  ),

                  const Spacer(flex: 2),

                  // "was YOUR month."
                  Text(
                    'was',
                    style: ZType.ser(20,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'YOUR',
                    style: ZType.disp(72,
                        color: Colors.white, height: 1, letterSpacing: 6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).introCardMonth,
                    style: ZType.ser(20,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),

                  const Spacer(flex: 2),

                  // Stats teaser row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      '${data.totalWorkouts} workouts · ${NumberFormat('#,###').format(data.totalVolumeLbs.round())} lbs · ${data.totalSets} sets',
                      style: ZType.lbl(14,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5),
                      textAlign: TextAlign.center,
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
