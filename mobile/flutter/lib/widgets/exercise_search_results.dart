import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../data/models/workout_day_detail.dart';
import '../data/providers/consistency_provider.dart';
import '../data/services/api_client.dart';
import 'workout_day_detail_sheet.dart';

/// Widget showing search results for exercise history
class ExerciseSearchResults extends ConsumerWidget {
  final String? exerciseName;
  final Function(String date)? onResultTapped;

  const ExerciseSearchResults({
    super.key,
    this.exerciseName,
    this.onResultTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (exerciseName == null || exerciseName!.isEmpty) {
      return const SizedBox.shrink();
    }

    final apiClient = ref.watch(apiClientProvider);
    final timeRange = ref.watch(heatmapTimeRangeProvider);

    return FutureBuilder<String?>(
      future: apiClient.getUserId(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const SizedBox.shrink();
        }

        final userId = userSnapshot.data!;
        final searchAsync = ref.watch(
          exerciseSearchProvider((
            userId: userId,
            exerciseName: exerciseName!,
            weeks: timeRange.weeks,
          )),
        );

        return searchAsync.when(
          data: (response) => _SearchResultsList(
            response: response,
            onResultTapped: onResultTapped,
          ),
          loading: () => const _SearchLoading(),
          error: (e, _) => _SearchError(error: e.toString()),
        );
      },
    );
  }
}

/// List of search results
class _SearchResultsList extends StatelessWidget {
  final ExerciseSearchResponse response;
  final Function(String date)? onResultTapped;

  const _SearchResultsList({
    required this.response,
    this.onResultTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (response.results.isEmpty) {
      return _NoResults(exerciseName: response.exerciseName);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${response.exerciseName}" - ${response.totalResults} workouts found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Results list
        ...response.results.take(10).map((result) => _ResultCard(
              result: result,
              onTap: () {
                onResultTapped?.call(result.date);
                WorkoutDayDetailSheet.show(context, result.date);
              },
            )),

        // Show more indicator if truncated
        if (response.results.length > 10)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                '+${response.results.length - 10} more workouts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual result card
class _ResultCard extends StatelessWidget {
  final ExerciseSearchResult result;
  final VoidCallback? onTap;

  const _ResultCard({
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = result.dateTime;
    final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: result.hasPr
              ? Border.all(color: AppColors.yellow.withOpacity(0.3))
              : Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Date and workout info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          result.workoutName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.cyan,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${result.setsCompleted} sets',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Best: ${result.bestSetDisplay}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PR badge
            if (result.hasPr) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.yellow,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.prType ?? 'PR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // Arrow
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// No results state
class _NoResults extends StatelessWidget {
  final String exerciseName;

  const _NoResults({required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'No workouts containing "$exerciseName" in selected time range',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Loading state
class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.cyan),
          ),
        ),
      ),
    );
  }
}

/// Error state
class _SearchError extends StatelessWidget {
  final String error;

  const _SearchError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to search exercises',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper extension for getting matching dates from search response
extension ExerciseSearchResponseX on ExerciseSearchResponse {
  Set<String> get matchingDatesSet => matchingDates.toSet();
}
