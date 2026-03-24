import 'package:flutter/material.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 7: AI Personality card - fitness personality title + description + fun fact
class WrappedPersonalityCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedPersonalityCard({
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
              Color(0xFF2D0F3E),
              Color(0xFF1A0825),
              Color(0xFF0A0410),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Magenta glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.15),
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

                  // Header - dramatic build-up
                  Text(
                    'Your gym personality is...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(),

                  // Personality title - bordered reveal box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFEC4899).withValues(alpha: 0.06),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.fitnessPersonality.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                        if (data.personalityDescription.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            data.personalityDescription,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Fun fact bubble
                  if (data.funFact.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEC4899)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'FUN FACT',
                            style: TextStyle(
                              color: const Color(0xFFF472B6)
                                  .withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.funFact,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                  // Motivation quote
                  if (data.motivationQuote.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '"${data.motivationQuote}"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

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
