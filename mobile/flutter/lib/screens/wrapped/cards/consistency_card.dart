import 'package:flutter/material.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 4: Consistency card - calendar heatmap + streak + consistency %
class WrappedConsistencyCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedConsistencyCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  int get _daysInMonth {
    final parts = data.periodKey.split('-');
    if (parts.length != 2) return 30;
    final year = int.tryParse(parts[0]) ?? 2026;
    final month = int.tryParse(parts[1]) ?? 1;
    return DateTime(year, month + 1, 0).day;
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
              Color(0xFF0D2912),
              Color(0xFF081C0B),
              Color(0xFF040E06),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Green glow
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
                        const Color(0xFF22C55E).withValues(alpha: 0.1),
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
                  Text(
                    'CONSISTENCY',
                    style: TextStyle(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),

                  const Spacer(),

                  // Consistency percentage
                  Text(
                    '${data.workoutConsistencyPct.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'of days you showed up',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(),

                  // Calendar heatmap grid
                  _buildCalendarGrid(),

                  const Spacer(),

                  // Streak display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFF4ADE80),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${data.streakBest}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Day Best\nStreak',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
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

  Widget _buildCalendarGrid() {
    final days = _daysInMonth;
    // Approximate active days from consistency percentage
    final activeDays = (days * data.workoutConsistencyPct / 100).round();

    // Create a simple deterministic pattern of active days
    final activeSet = <int>{};
    if (activeDays > 0 && days > 0) {
      final step = days / activeDays;
      for (int i = 0; i < activeDays; i++) {
        activeSet.add((i * step).round().clamp(0, days - 1));
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: List.generate(days, (index) {
        final isActive = activeSet.contains(index);
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF22C55E).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
          ),
        );
      }),
    );
  }
}
