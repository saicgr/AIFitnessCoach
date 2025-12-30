import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_watermark.dart';

/// Photo Overlay Template - User's photo with workout stats overlay
/// Stats displayed at bottom with gradient overlay
class PhotoOverlayTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int exercisesCount;
  final Uint8List? userPhotoBytes;
  final String? userPhotoUrl;
  final DateTime completedAt;
  final bool showWatermark;

  const PhotoOverlayTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    required this.exercisesCount,
    this.userPhotoBytes,
    this.userPhotoUrl,
    required this.completedAt,
    this.showWatermark = true,
  });

  String get _formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get _formattedVolume {
    if (totalVolumeKg == null) return '--';
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg!.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive height based on available space
    final screenHeight = MediaQuery.of(context).size.height;
    final templateHeight = (screenHeight * 0.55).clamp(400.0, 580.0);

    return Container(
      width: 320,
      height: templateHeight,
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // User photo or placeholder
            _buildPhotoBackground(),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Top gradient for date visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content overlay
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  _buildDateBadge(),

                  const Spacer(),

                  // Workout info
                  Text(
                    'WORKOUT COMPLETE',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    workoutName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 24),

                  // Stats row
                  _buildStatsRow(),

                  const SizedBox(height: 24),

                  // Watermark
                  if (showWatermark) const AppWatermark(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoBackground() {
    if (userPhotoBytes != null) {
      return Image.memory(
        userPhotoBytes!,
        fit: BoxFit.cover,
      );
    }

    if (userPhotoUrl != null) {
      return Image.network(
        userPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.3),
            AppColors.cyan.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your photo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge() {
    final now = DateTime.now();
    String dateText;
    if (completedAt.day == now.day &&
        completedAt.month == now.month &&
        completedAt.year == now.year) {
      dateText = 'Today';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dateText = '${months[completedAt.month - 1]} ${completedAt.day}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: _formattedDuration,
            label: 'Time',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '$exercisesCount',
            label: 'Exercises',
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.scale_outlined,
            value: _formattedVolume,
            label: 'Volume',
          ),
          if (calories != null) ...[
            _buildDivider(),
            _buildStatItem(
              icon: Icons.local_fire_department_outlined,
              value: '$calories',
              label: 'Cal',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.cyan,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

}
