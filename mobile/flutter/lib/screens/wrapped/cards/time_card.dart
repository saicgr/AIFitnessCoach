import 'package:flutter/material.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 6: Time card - total hours, most active day, most active hour
class WrappedTimeCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedTimeCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String get _formattedHours {
    final hours = data.totalDurationMinutes / 60;
    if (hours >= 1) {
      return hours.toStringAsFixed(1);
    }
    return '${data.totalDurationMinutes}';
  }

  String get _hoursLabel {
    final hours = data.totalDurationMinutes / 60;
    if (hours >= 1) {
      return 'HOURS';
    }
    return 'MINUTES';
  }

  String get _formattedHour {
    final hour = data.mostActiveHour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
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
              Color(0xFF1A1145),
              Color(0xFF110B2E),
              Color(0xFF08061A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Indigo glow
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
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
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
                    'YOUR TIME',
                    style: TextStyle(
                      color: const Color(0xFF818CF8).withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),

                  const Spacer(),

                  // Clock icon
                  Icon(
                    Icons.schedule,
                    color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                    size: 48,
                  ),
                  const SizedBox(height: 20),

                  // Total hours
                  Text(
                    _formattedHours,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hoursLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'spent working out',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Most active day & hour
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.calendar_today,
                          label: 'MOST ACTIVE DAY',
                          value: data.mostActiveDayOfWeek,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.access_time,
                          label: 'PEAK HOUR',
                          value: _formattedHour,
                        ),
                      ),
                    ],
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF818CF8),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
