import 'package:flutter/material.dart';
import '../../../data/models/wrapped_data.dart';
import '../../workout/widgets/share_templates/app_watermark.dart';

/// Card 3: Favorites card - favorite exercise and muscle group
class WrappedFavoritesCard extends StatelessWidget {
  final WrappedData data;
  final bool showWatermark;

  const WrappedFavoritesCard({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.expand;
      case 'back':
        return Icons.airline_seat_flat;
      case 'legs':
      case 'quads':
      case 'hamstrings':
      case 'glutes':
        return Icons.directions_walk;
      case 'shoulders':
      case 'delts':
        return Icons.accessibility_new;
      case 'arms':
      case 'biceps':
      case 'triceps':
        return Icons.fitness_center;
      case 'core':
      case 'abs':
        return Icons.sports_martial_arts;
      default:
        return Icons.accessibility_new;
    }
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
              Color(0xFF0D2925),
              Color(0xFF081C19),
              Color(0xFF040E0C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Teal glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF14B8A6).withValues(alpha: 0.12),
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
                    'YOUR GO-TO',
                    style: TextStyle(
                      color: const Color(0xFF5EEAD4).withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),

                  const Spacer(),

                  // Favorite exercise name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.favoriteExercise,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your most performed exercise',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Divider
                  Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  const Spacer(),

                  // Favorite muscle group section
                  Icon(
                    _getMuscleGroupIcon(data.favoriteMuscleGroup),
                    color: const Color(0xFF5EEAD4).withValues(alpha: 0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FAVORITE MUSCLE GROUP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.favoriteMuscleGroup.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF5EEAD4),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
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
