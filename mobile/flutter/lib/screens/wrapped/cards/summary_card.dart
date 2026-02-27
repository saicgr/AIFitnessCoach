import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 8: Summary card - 2x3 stat grid, motivational quote, share CTA
class WrappedSummaryCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedSummaryCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String get _formattedHours {
    final hours = data.totalDurationMinutes / 60;
    return hours.toStringAsFixed(1);
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
              Color(0xFF2D1B69),
              Color(0xFF1A0F3C),
              Color(0xFF0A0612),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle purple glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA855F7).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Header
                  const Text(
                    'YOUR MONTH IN REVIEW',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data.monthDisplayName} ${data.yearDisplay}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // 2x3 stats grid
                  _buildStatsGrid(),

                  const Spacer(),

                  // Motivational quote from AI
                  if (data.motivationQuote.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: const Color(0xFFC084FC)
                                .withValues(alpha: 0.5),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.motivationQuote,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Share CTA
                  Text(
                    'Share Your Wrapped',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(),

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

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        icon: Icons.fitness_center,
        value: '${data.totalWorkouts}',
        label: 'Workouts',
        color: const Color(0xFFA855F7),
      ),
      _StatItem(
        icon: Icons.scale,
        value: NumberFormat.compact().format(data.totalVolumeLbs),
        label: 'Volume (lbs)',
        color: const Color(0xFF3B82F6),
      ),
      _StatItem(
        icon: Icons.emoji_events,
        value: '${data.personalRecordsCount}',
        label: 'PRs',
        color: const Color(0xFFFFD700),
      ),
      _StatItem(
        icon: Icons.local_fire_department,
        value: '${data.streakBest}',
        label: 'Best Streak',
        color: const Color(0xFFF97316),
      ),
      _StatItem(
        icon: Icons.schedule,
        value: _formattedHours,
        label: 'Hours',
        color: const Color(0xFF6366F1),
      ),
      _StatItem(
        icon: Icons.sports_gymnastics,
        value: '${data.totalExercises}',
        label: 'Exercises',
        color: const Color(0xFF14B8A6),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile(stats[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile(stats[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatTile(stats[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile(stats[3])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatTile(stats[4])),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile(stats[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: item.color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}
