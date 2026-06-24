import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/custom_exercises_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/custom_exercise.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/signature/signature.dart';
import 'widgets/custom_exercise_card.dart';
import 'widgets/create_exercise_sheet.dart';
import 'widgets/empty_custom_exercises.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen for viewing and managing custom exercises
class CustomExercisesScreen extends ConsumerStatefulWidget {
  const CustomExercisesScreen({super.key});

  @override
  ConsumerState<CustomExercisesScreen> createState() => _CustomExercisesScreenState();
}

class _CustomExercisesScreenState extends ConsumerState<CustomExercisesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize custom exercises
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customExercisesProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final state = ref.watch(customExercisesProvider);

    // Listen for success/error messages
    ref.listen<CustomExercisesState>(customExercisesProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearSuccess();
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, state),
            if (state.exercises.isNotEmpty) ...[
              _buildSearchBar(context, isDark),
              _buildTabBar(context, isDark),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: state.isLoading && state.exercises.isEmpty
                  // Layout-matched skeleton on a cold first load instead of a
                  // blocking spinner. The provider keeps an in-memory cache,
                  // so re-entering the screen in-session renders instantly.
                  ? const SkeletonList(
                      scrollable: true,
                      itemCount: 6,
                      padding: EdgeInsets.all(16),
                    )
                  : state.exercises.isEmpty
                      ? EmptyCustomExercises(
                          onCreatePressed: () => _showCreateSheet(context),
                        )
                      : _buildTabContent(context, isDark, state),
            ),
          ],
        ),
      ),
      floatingActionButton: state.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.orange,
              foregroundColor: const Color(0xFF160B03),
              icon: const Icon(Icons.add, color: Color(0xFF160B03)),
              label: Text(
                AppLocalizations.of(context).netflixExercisesTabCreate.toUpperCase(),
                style: ZType.lbl(
                  13,
                  color: const Color(0xFF160B03),
                  letterSpacing: 1.2,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, CustomExercisesState state) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final stats = state.stats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          GlassBackButton(
            onTap: () {
              HapticService.light();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).workoutSettingsMyExercises.toUpperCase(),
                  style: ZType.disp(26, color: textPrimary, letterSpacing: 0.5),
                ),
                if (stats != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${stats.totalCustomExercises} EXERCISES · ${stats.totalUses} USES',
                    style: ZType.lbl(11, color: textMuted, letterSpacing: 1.6),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final surface = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          style: ZType.sans(14, color: textPrimary, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).supersetExercisePickerSearchExercises,
            hintStyle: ZType.sans(14, color: textMuted, weight: FontWeight.w500),
            prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    return SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: [
        SegmentedTabItem(label: AppLocalizations.of(context).syncedWorkoutsHistoryAll),
        SegmentedTabItem(label: AppLocalizations.of(context).customExercisesSimple),
        SegmentedTabItem(label: AppLocalizations.of(context).customExercisesCombos),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, bool isDark, CustomExercisesState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExerciseList(context, isDark, _filterExercises(state.exercises)),
        _buildExerciseList(context, isDark, _filterExercises(state.simpleExercises)),
        _buildExerciseList(context, isDark, _filterExercises(state.compositeExercises)),
      ],
    );
  }

  List<CustomExercise> _filterExercises(List<CustomExercise> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    final query = _searchQuery.toLowerCase();
    return exercises.where((e) {
      return e.name.toLowerCase().contains(query) ||
          e.primaryMuscle.toLowerCase().contains(query) ||
          e.equipment.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildExerciseList(BuildContext context, bool isDark, List<CustomExercise> exercises) {
    if (exercises.isEmpty) {
      final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 44,
              color: textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? AppLocalizations.of(context).customExercisesNoExercisesMatchYour : 'No exercises in this category',
              style: ZType.sans(14, color: textMuted, weight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => ref.read(customExercisesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomExerciseCard(
              exercise: exercise,
              onTap: () => _showExerciseDetails(context, exercise),
              onDelete: () => _confirmDelete(context, exercise),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    HapticService.light();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const GlassSheet(
        child: CreateExerciseSheet(),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, CustomExercise exercise) {
    HapticService.light();
    // For now, show a simple details dialog
    // Later this can be a full detail screen
    showDialog(
      context: context,
      builder: (context) => _ExerciseDetailsDialog(exercise: exercise),
    );
  }

  void _confirmDelete(BuildContext context, CustomExercise exercise) {
    HapticService.medium();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
        title: Text(
          AppLocalizations.of(context).myExercisesDeleteExercise.toUpperCase(),
          style: ZType.lbl(15, color: textPrimary, letterSpacing: 1.2),
        ),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"? This cannot be undone.',
          style: ZType.sans(14, color: textSecondary, weight: FontWeight.w500, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).buttonCancel.toUpperCase(),
              style: ZType.lbl(13, color: textMuted, letterSpacing: 1.0),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(customExercisesProvider.notifier).deleteExercise(exercise.id);
            },
            child: Text(
              AppLocalizations.of(context).buttonDelete.toUpperCase(),
              style: ZType.lbl(13, color: AppColors.error, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog showing exercise details
class _ExerciseDetailsDialog extends StatelessWidget {
  final CustomExercise exercise;

  const _ExerciseDetailsDialog({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorder),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              exercise.name,
              style: ZType.sans(18, color: textPrimary, weight: FontWeight.w700),
            ),
          ),
          if (exercise.isComposite)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
              ),
              child: Text(
                exercise.typeLabel.toUpperCase(),
                style: ZType.lbl(10, color: AppColors.orange, letterSpacing: 1.0),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetail('Muscle', exercise.primaryMuscle, textMuted, textPrimary),
            _buildDetail('Equipment', exercise.equipment, textMuted, textPrimary),
            _buildDetail('Sets', exercise.defaultSets.toString(), textMuted, textPrimary),
            if (exercise.defaultReps != null)
              _buildDetail('Reps', exercise.defaultReps.toString(), textMuted, textPrimary),
            if (exercise.defaultRestSeconds != null)
              _buildDetail('Rest', '${exercise.defaultRestSeconds}s', textMuted, textPrimary),
            if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
              _buildDetail('Instructions', exercise.instructions!, textMuted, textPrimary),
            if (exercise.isComposite && exercise.componentExercises != null) ...[
              const SizedBox(height: 16),
              ZSectionKicker(
                label: AppLocalizations.of(context).pillarDetailComponents,
              ),
              const SizedBox(height: 8),
              ...exercise.componentExercises!.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text(
                              '${c.order}',
                              style: ZType.data(11, color: AppColors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${c.name} ${c.targetDisplay.isNotEmpty ? "(${c.targetDisplay})" : ""}',
                            style: ZType.sans(13.5,
                                color: textPrimary, weight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (exercise.usageCount > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Used ${exercise.usageCount} times${exercise.lastUsedFormatted != null ? " · Last: ${exercise.lastUsedFormatted}" : ""}',
                style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.2),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context).commonClose.toUpperCase(),
            style: ZType.lbl(13, color: AppColors.orange, letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(
      String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label.toUpperCase(),
              style: ZType.lbl(10.5, color: labelColor, letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ZType.sans(13.5, color: valueColor, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
