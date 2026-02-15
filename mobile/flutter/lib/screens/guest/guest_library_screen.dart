import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../library/providers/library_providers.dart';

/// Maximum exercises shown in guest mode
const int guestExerciseLimit = 20;

/// Guest exercise library screen with limited exercises
/// Shows first 20 exercises and prompts for sign up
class GuestLibraryScreen extends ConsumerStatefulWidget {
  const GuestLibraryScreen({super.key});

  @override
  ConsumerState<GuestLibraryScreen> createState() => _GuestLibraryScreenState();
}

class _GuestLibraryScreenState extends ConsumerState<GuestLibraryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSignUp() async {
    await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
    if (mounted) {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Watch the exercises provider
    final exercisesAsync = ref.watch(categoryExercisesProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, textMuted, textPrimary, textSecondary),

            // Search Bar
            _buildSearchBar(isDark, elevatedColor, textSecondary, textMuted),

            // Limit notice
            _buildLimitNotice(textSecondary),

            // Exercise List
            Expanded(
              child: exercisesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
                error: (error, _) => _buildErrorState(textSecondary),
                data: (categoryData) => _buildExerciseList(
                  categoryData.preview,
                  isDark,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textMuted,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              HapticService.light();
              context.pop();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: textMuted,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Exercise Library',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse sample exercises',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    Color elevatedColor,
    Color textSecondary,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(color: textSecondary),
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            hintStyle: TextStyle(color: textMuted),
            prefixIcon: Icon(Icons.search, color: textMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLimitNotice(Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Showing $guestExerciseLimit sample exercises. Sign up free to access 1700+ exercises!',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _navigateToSignUp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildExerciseList(
    Map<String, List<LibraryExercise>> categoryData,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Flatten all exercises and take only the limit
    final allExercises = <LibraryExercise>[];
    for (final exercises in categoryData.values) {
      allExercises.addAll(exercises);
    }

    // Filter by search query if present
    var filteredExercises = allExercises;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredExercises = allExercises
          .where((e) =>
              e.name.toLowerCase().contains(query) ||
              (e.bodyPart?.toLowerCase().contains(query) ?? false) ||
              (e.equipment.any((eq) => eq.toLowerCase().contains(query)) ?? false))
          .toList();
    }

    // Limit to guest mode limit
    final limitedExercises = filteredExercises.take(guestExerciseLimit).toList();

    if (limitedExercises.isEmpty) {
      return _buildEmptyState(textSecondary);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: limitedExercises.length + 1, // +1 for the sign up card
      itemBuilder: (context, index) {
        if (index == limitedExercises.length) {
          return _buildSignUpCard(isDark, textPrimary, textSecondary);
        }

        final exercise = limitedExercises[index];
        return _buildExerciseCard(
          exercise,
          isDark,
          textPrimary,
          textSecondary,
          index,
        );
      },
    );
  }

  Widget _buildExerciseCard(
    LibraryExercise exercise,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    int index,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticService.light();
            _showExerciseDetail(exercise, isDark);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Exercise thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exercise.gifUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.gifUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.fitness_center,
                              color: AppColors.purple,
                              size: 24,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.fitness_center,
                          color: AppColors.purple,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (exercise.bodyPart != null) ...[
                            _buildChip(exercise.bodyPart!, AppColors.purple),
                            const SizedBox(width: 6),
                          ],
                          if (exercise.equipment.isNotEmpty)
                            _buildChip(exercise.equipment.first, AppColors.cyan),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 50 * (index % 10)),
          duration: const Duration(milliseconds: 200),
        );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSignUpCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 100),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.15),
            AppColors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_open,
            color: AppColors.cyan,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock 1700+ Exercises',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign up free to access our complete exercise library with video demonstrations and instructions.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Up Free',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: const Text(
              'Clear search',
              style: TextStyle(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load exercises',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(categoryExercisesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(LibraryExercise exercise, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Exercise GIF
                  if (exercise.gifUrl != null)
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.glassSurface
                            : AppColorsLight.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          exercise.gifUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: textMuted,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Exercise name
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (exercise.bodyPart != null)
                        _buildDetailChip(exercise.bodyPart!, AppColors.purple),
                      if (exercise.equipment.isNotEmpty)
                        _buildDetailChip(exercise.equipment.first, AppColors.cyan),
                      if (exercise.targetMuscle != null)
                        _buildDetailChip(exercise.targetMuscle!, AppColors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Instructions placeholder
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (exercise.instructions.isNotEmpty)
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Text(
                      'Sign up to view detailed instructions for this exercise.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Sign up CTA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: AppColors.cyan,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get Video Demonstrations',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign up free to access HD video guides for all exercises.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToSignUp();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyan,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Sign Up Free'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
