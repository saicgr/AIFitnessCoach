import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../components/ai_split_preset_detail_sheet.dart';
import '../providers/for_you_provider.dart';
import '../providers/library_providers.dart';
import '../providers/muscle_group_images_provider.dart';
import '../widgets/compact_split_card.dart';

/// Main discovery tab for the Library screen.
///
/// Shows AI hero card, personalized "For You" splits, category-organized
/// training splits, and browse-by-muscle/equipment pills.
class DiscoverTab extends ConsumerWidget {
  final Function(String? muscleFilter)? onSwitchToExercises;

  const DiscoverTab({super.key, this.onSwitchToExercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forYouPresets = ref.watch(forYouPresetsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        _AiHeroCard(isDark: isDark),
        const SizedBox(height: 20),
        _ForYouSection(presets: forYouPresets, isDark: isDark),
        const SizedBox(height: 20),
        _TrainingPlansSection(isDark: isDark),
        const SizedBox(height: 20),
        _BrowseSection(
          isDark: isDark,
          onMuscleSelected: onSwitchToExercises,
        ),
      ],
    );
  }
}

// ============================================================================
// AI HERO CARD
// ============================================================================

class _AiHeroCard extends StatelessWidget {
  final bool isDark;

  const _AiHeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          context.push('/chat', extra: {
            'initialMessage': 'What should I train today? Give me a personalized recommendation based on my recent workouts, recovery, and goals.',
          });
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                purple.withOpacity(0.25),
                cyan.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: purple.withOpacity(0.3),
            ),
          ),
          child: Stack(
            children: [
              // Shimmer overlay on the border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cyan.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: cyan.withOpacity(0.3),
                    ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What should I train?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get a personalized AI recommendation',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColorsLight.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms);
  }
}

// ============================================================================
// FOR YOU SECTION
// ============================================================================

class _ForYouSection extends StatelessWidget {
  final List<AISplitPreset> presets;
  final bool isDark;

  const _ForYouSection({required this.presets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Matched to your gym profile',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 12),

        // Horizontal scroll of cards
        if (presets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                'Complete your profile to get personalized recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColorsLight.textMuted,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                return CompactSplitCard(
                  preset: preset,
                  animationIndex: index,
                  onTap: () {
                    HapticService.light();
                    showGlassSheet(
                      context: context,
                      builder: (ctx) =>
                          AISplitPresetDetailSheet(preset: preset),
                    );
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        // "Not sure? Ask AI" text button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/chat', extra: {
                'initialMessage': 'I\'m not sure what to train. Can you suggest a training plan for me based on my goals and what I\'ve been doing recently?',
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: cyan,
                ),
                const SizedBox(width: 6),
                Text(
                  'Not sure? Ask AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TRAINING PLANS SECTION (unified: All / Classic / AI-Powered / Specialty)
// ============================================================================

class _TrainingPlansSection extends StatefulWidget {
  final bool isDark;

  const _TrainingPlansSection({required this.isDark});

  @override
  State<_TrainingPlansSection> createState() => _TrainingPlansSectionState();
}

class _TrainingPlansSectionState extends State<_TrainingPlansSection> {
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'All'),
    ('classic', 'Classic'),
    ('ai_powered', 'AI-Powered'),
    ('specialty', 'Specialty'),
  ];

  List<AISplitPreset> _presetsForSelected() {
    if (_selectedCategory == 'all') {
      return [
        ...getPresetsByCategory('classic'),
        ...getPresetsByCategory('ai_powered'),
        ...getPresetsByCategory('specialty'),
      ];
    }
    return getPresetsByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    final presets = _presetsForSelected();
    if (presets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Plans',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  final qs = _selectedCategory == 'all'
                      ? ''
                      : '?category=$_selectedCategory';
                  context.push('/library/splits$qs');
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 10),

        // Category chips
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (key, label) = _categories[i];
              final selected = _selectedCategory == key;
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() => _selectedCategory = key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? purple : elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? null
                        : Border.all(
                            color: textMuted.withValues(alpha: 0.2),
                          ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal scroll of cards
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return CompactSplitCard(
                preset: preset,
                animationIndex: index,
                onTap: () {
                  HapticService.light();
                  showGlassSheet(
                    context: context,
                    builder: (ctx) =>
                        AISplitPresetDetailSheet(preset: preset),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BROWSE SECTION (Muscle Groups + Equipment)
// ============================================================================

class _BrowseSection extends ConsumerWidget {
  final bool isDark;
  final Function(String? muscleFilter)? onMuscleSelected;

  const _BrowseSection({
    required this.isDark,
    this.onMuscleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final categoryData = ref.watch(categoryExercisesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "By Muscle" header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Browse by Muscle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 12),

        // Muscle group wrap grid (reflows to fit screen width, no horizontal scroll)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: List.generate(_muscleGroups.length, (index) {
              final muscle = _muscleGroups[index];
              final imagePath = muscleGroupAssets[muscle.name];
              final countLabel = categoryData.when(
                data: (data) {
                  final n = data.totalCounts?[muscle.name] ??
                      data.all[muscle.name]?.length ??
                      0;
                  return _formatBucketCount(n);
                },
                loading: () => '—',
                error: (_, __) => '',
              );

              return _MusclePill(
                name: muscle.name,
                imagePath: imagePath,
                countLabel: countLabel,
                isDark: isDark,
                animationIndex: index,
                onTap: () {
                  HapticService.light();
                  onMuscleSelected?.call(muscle.name);
                },
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // "By Equipment" header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Browse by Equipment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 12),

        // Equipment wrap grid (fits all 4 in one row on every phone size)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: List.generate(_equipmentTypes.length, (index) {
              final equipment = _equipmentTypes[index];
              return _EquipmentPill(
                name: equipment.name,
                icon: equipment.icon,
                color: equipment.color(isDark),
                isDark: isDark,
                animationIndex: index,
                onTap: () {
                  HapticService.light();
                  onMuscleSelected?.call(equipment.name);
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Bucket exact counts into friendlier labels:
///   0        -> ''        (hide)
///   1..99    -> exact
///   >=100    -> "Npp+" where N is floor(count/100)*100 (e.g. 354 -> "300+", 782 -> "700+")
String _formatBucketCount(int count) {
  if (count <= 0) return '';
  if (count < 100) return '$count';
  final bucket = (count ~/ 100) * 100;
  return '$bucket+';
}

// ============================================================================
// MUSCLE PILL
// ============================================================================

class _MusclePill extends StatelessWidget {
  final String name;
  final String? imagePath;
  final String countLabel;
  final bool isDark;
  final int animationIndex;
  final VoidCallback onTap;

  const _MusclePill({
    required this.name,
    this.imagePath,
    required this.countLabel,
    required this.isDark,
    required this.animationIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            // Circular avatar with anatomy image
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: elevated,
                border: Border.all(
                  color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fitness_center,
                        size: 22,
                        color: textMuted,
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      size: 22,
                      color: textMuted,
                    ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Count (bucketed or "—" during load)
            if (countLabel.isNotEmpty)
              Text(
                countLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
          delay: (animationIndex * 50).ms,
          duration: 600.ms,
        )
        .fadeIn(delay: (animationIndex * 50).ms, duration: 300.ms);
  }
}

// ============================================================================
// EQUIPMENT PILL
// ============================================================================

class _EquipmentPill extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isDark;
  final int animationIndex;
  final VoidCallback onTap;

  const _EquipmentPill({
    required this.name,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.animationIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            // Circular icon with color
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
          delay: (animationIndex * 50).ms,
          duration: 600.ms,
        )
        .fadeIn(delay: (animationIndex * 50).ms, duration: 300.ms);
  }
}

// ============================================================================
// DATA MODELS FOR BROWSE PILLS
// ============================================================================

class _MuscleGroupData {
  final String name;
  const _MuscleGroupData(this.name);
}

class _EquipmentData {
  final String name;
  final IconData icon;
  final Color Function(bool isDark) color;
  const _EquipmentData(this.name, this.icon, this.color);
}

const _muscleGroups = [
  _MuscleGroupData('Chest'),
  _MuscleGroupData('Back'),
  _MuscleGroupData('Shoulders'),
  _MuscleGroupData('Arms'),
  _MuscleGroupData('Legs'),
  _MuscleGroupData('Core'),
  _MuscleGroupData('Glutes'),
];

final _equipmentTypes = [
  _EquipmentData(
    'Weights',
    Icons.fitness_center,
    (isDark) => isDark ? AppColors.orange : AppColorsLight.orange,
  ),
  _EquipmentData(
    'Bodyweight',
    Icons.self_improvement,
    (isDark) => isDark ? AppColors.success : AppColorsLight.success,
  ),
  _EquipmentData(
    'Machines',
    Icons.precision_manufacturing,
    (isDark) => isDark ? AppColors.cyan : AppColorsLight.cyan,
  ),
  _EquipmentData(
    'Cardio',
    Icons.directions_run,
    (isDark) => isDark ? AppColors.yellow : const Color(0xFFCA8A04),
  ),
];
