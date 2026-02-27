import 'package:flutter/material.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 5: Personal Records card - trophy icon, PR count, best PR highlight
class WrappedRecordsCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedRecordsCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bestPr = data.bestPr;
    final bestPrExercise = bestPr?['exercise'] as String? ?? '';
    final bestPrValue = bestPr?['value']?.toString() ?? '';
    final bestPrUnit = bestPr?['unit'] as String? ?? 'lbs';

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A1F00),
              Color(0xFF1A1300),
              Color(0xFF0A0800),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Gold radial glow behind trophy
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: const Alignment(0, -0.3),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.15),
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

                  // Header
                  const Text(
                    'PERSONAL RECORDS',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),

                  const Spacer(),

                  // Trophy icon with gold glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // PR count
                  Text(
                    '${data.personalRecordsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.personalRecordsCount == 1
                        ? 'RECORD BROKEN'
                        : 'RECORDS BROKEN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),

                  const Spacer(),

                  // Best PR highlight
                  if (bestPrExercise.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'BEST PR',
                            style: TextStyle(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bestPrExercise,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (bestPrValue.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$bestPrValue $bestPrUnit',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
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
