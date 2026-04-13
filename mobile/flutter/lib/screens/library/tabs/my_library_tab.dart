import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../components/exercise_detail_sheet.dart';
import '../providers/library_providers.dart';
import '../../custom_exercises/widgets/create_exercise_sheet.dart';

part 'my_library_tab_part_custom_exercises_section.dart';
part 'my_library_tab_part_history_timeline_card.dart';


/// My Library tab - personal collection of custom exercises, favorites,
/// staples, and recent exercise history.
class MyLibraryTab extends ConsumerWidget {
  const MyLibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Initialize custom exercises provider after the current build settles.
    // Calling `initialize()` synchronously inside build() mutates provider
    // state while the widget tree is building, which Riverpod rejects.
    Future.microtask(
      () => ref.read(customExercisesProvider.notifier).initialize(),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(exerciseHistoryProvider);
        ref.invalidate(categoryExercisesProvider);
        await ref.read(customExercisesProvider.notifier).refresh();
        await ref.read(favoritesProvider.notifier).refresh();
        await ref.read(staplesProvider.notifier).refresh();
      },
      color: isDark ? AppColors.orange : AppColorsLight.orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _CustomExercisesSection(isDark: isDark),
          const SizedBox(height: 28),
          _FavoritesSection(isDark: isDark),
          const SizedBox(height: 28),
          _StaplesSection(isDark: isDark),
          const SizedBox(height: 28),
          _RecentActivitySection(isDark: isDark),
        ],
      ),
    );
  }
}
