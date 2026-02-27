import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import 'tabs/netflix_exercises_tab.dart';

// Export providers and models for external use
export 'providers/library_providers.dart';
export 'models/filter_option.dart';
export 'models/exercises_state.dart';

/// Main Library Screen showing the exercise library
class LibraryScreen extends ConsumerWidget {
  /// Initial tab index (kept for route compatibility)
  final int initialTab;

  const LibraryScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with title only
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 12, 16, 16),
                  child: Row(
                    children: [
                      Text(
                        'Library',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                // Exercises content
                const Expanded(
                  child: NetflixExercisesTab(),
                ),
              ],
            ),

            // Floating back button
            Positioned(
              top: 8,
              left: 8,
              child: GlassBackButton(
                onTap: () {
                  HapticService.light();
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
