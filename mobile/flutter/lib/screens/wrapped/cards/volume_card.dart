import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 2: Volume card - total volume lifted with fun equivalence
class WrappedVolumeCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedVolumeCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String get _funEquivalence {
    final volume = data.totalVolumeLbs;
    if (volume <= 0) return '';

    // An elephant weighs ~10,000 lbs
    final elephants = volume / 10000;
    if (elephants >= 1) {
      return "That's ${elephants.toStringAsFixed(1)} elephants!";
    }

    // A barbell weighs 45 lbs
    final barbells = (volume / 45).round();
    return "That's $barbells barbells worth!";
  }

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
              Color(0xFF0D2137),
              Color(0xFF091628),
              Color(0xFF050B14),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Blue radial glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3B82F6).withValues(alpha: 0.15),
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

                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'TOTAL VOLUME LIFTED',
                      style: TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Massive number
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      NumberFormat('#,###').format(data.totalVolumeLbs.round()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'lbs',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),

                  const Spacer(),

                  // Fun equivalence
                  if (_funEquivalence.isNotEmpty)
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: Color(0xFF60A5FA),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _funEquivalence,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(flex: 2),

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
