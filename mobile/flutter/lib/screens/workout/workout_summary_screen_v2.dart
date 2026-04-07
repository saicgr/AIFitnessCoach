import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/lottie_animations.dart';
import 'workout_summary_detail.dart';
import 'workout_summary_general.dart';
import 'workout_summary_advanced.dart';
import 'widgets/summary_floating_pill.dart';

class WorkoutSummaryScreenV2 extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutSummaryScreenV2({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutSummaryScreenV2> createState() =>
      _WorkoutSummaryScreenV2State();
}

class _WorkoutSummaryScreenV2State
    extends ConsumerState<WorkoutSummaryScreenV2> {
  int _selectedView = 0; // 0 = Detail, 1 = General, 2 = Advanced
  WorkoutSummaryResponse? _summaryData;
  Map<String, dynamic>? _metadata;
  Workout? _parsedWorkout;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();

    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_summary_v2_viewed',
      properties: {'workout_id': widget.workoutId},
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);

      final results = await Future.wait([
        repo.getWorkoutCompletionSummary(widget.workoutId),
        repo.getWorkoutLogByWorkoutId(widget.workoutId),
      ]);

      if (!mounted) return;

      // Parse metadata — the endpoint flattens metadata fields to top level
      final rawLog = results[1] as Map<String, dynamic>?;

      // Parse workout object from summary data for the Detail tab
      Workout? parsed;
      final summaryResult = results[0] as WorkoutSummaryResponse?;
      if (summaryResult != null) {
        try {
          parsed = Workout.fromJson(summaryResult.workout);
        } catch (e) {
          debugPrint('Failed to parse workout from summary: $e');
        }
      }

      setState(() {
        _summaryData = summaryResult;
        _metadata = rawLog;
        _parsedWorkout = parsed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching workout summary v2 data: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load workout summary. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      body: _buildBody(isDark, accentColor),
    );
  }

  Widget _buildBody(bool isDark, Color accentColor) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_error != null) {
      return _buildErrorState(isDark, accentColor);
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Main content - switches between Detail, General, and Advanced
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedView == 0
              ? WorkoutSummaryDetail(
                  key: const ValueKey('detail'),
                  data: _summaryData,
                  metadata: _metadata,
                  workout: _parsedWorkout,
                  topPadding: topPadding,
                )
              : _selectedView == 1
                  ? WorkoutSummaryGeneral(
                      key: const ValueKey('general'),
                      data: _summaryData,
                      metadata: _metadata,
                      topPadding: topPadding,
                    )
                  : WorkoutSummaryAdvanced(
                      key: const ValueKey('advanced'),
                      data: _summaryData,
                      metadata: _metadata,
                      topPadding: topPadding,
                    ),
        ),

        // Floating back button
        Positioned(
          top: topPadding + 8,
          left: 16,
          child: const GlassBackButton(),
        ),

        // Floating pill at bottom (widget includes its own Positioned wrapper)
        SummaryFloatingPill(
          selectedIndex: _selectedView,
          onChanged: (i) => setState(() => _selectedView = i),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LottieLoading(size: 80),
          const SizedBox(height: 16),
          Text(
            'Loading summary...',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
