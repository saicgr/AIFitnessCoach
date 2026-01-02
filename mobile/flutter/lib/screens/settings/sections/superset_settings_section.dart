import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/superset_preferences_provider.dart';
import '../widgets/widgets.dart';

/// The superset settings section for configuring superset preferences.
///
/// Allows users to configure:
/// - Enable/disable supersets in AI-generated workouts
/// - Pairing preferences (antagonist vs compound)
/// - Maximum supersets per workout
/// - Rest times between exercises and after supersets
/// - Favorite superset pairs
class SupersetSettingsSection extends ConsumerWidget {
  const SupersetSettingsSection({super.key});

  /// Help items explaining each superset setting
  static const List<Map<String, dynamic>> _supersetHelpItems = [
    {
      'icon': Icons.sync_alt,
      'title': 'What are Supersets?',
      'description': 'Supersets are pairs of exercises performed back-to-back with minimal rest. They save time and increase workout intensity.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Antagonist Pairs',
      'description': 'Exercises targeting opposing muscle groups (e.g., chest press + rows, bicep curls + tricep extensions). Allows one muscle to rest while the other works.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Compound Sets',
      'description': 'Two exercises for the same muscle group performed consecutively. Maximizes muscle fatigue and time under tension.',
      'color': AppColors.orange,
    },
    {
      'icon': Icons.timer,
      'title': 'Rest Between Exercises',
      'description': 'Short rest (0-30 seconds) between the two exercises in a superset. Shorter rest increases intensity.',
      'color': AppColors.success,
    },
    {
      'icon': Icons.hourglass_empty,
      'title': 'Rest After Superset',
      'description': 'Recovery time after completing both exercises before the next set or superset. Typically 60-180 seconds.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.favorite,
      'title': 'Favorite Pairs',
      'description': 'Save your preferred exercise combinations. The AI will prioritize including these pairs in your workouts.',
      'color': AppColors.error,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supersetPrefs = ref.watch(supersetPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'SUPERSET SETTINGS',
          subtitle: 'Control how supersets are generated in your workouts',
          helpTitle: 'Superset Settings Explained',
          helpItems: _supersetHelpItems,
        ),
        const SizedBox(height: 12),

        // Main settings card
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Enable supersets toggle
              _SupersetToggleTile(
                icon: Icons.sync_alt,
                title: 'Auto-generate supersets',
                subtitle: 'Include superset pairs in AI-generated workouts',
                value: supersetPrefs.supersetsEnabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref.read(supersetPreferencesProvider.notifier).setSupersetsEnabled(value);
                },
              ),

              // Divider
              Divider(height: 1, color: cardBorder, indent: 50),

              // Pairing preferences (only when enabled)
              if (supersetPrefs.supersetsEnabled) ...[
                _SupersetToggleTile(
                  icon: Icons.compare_arrows,
                  title: 'Prefer antagonist pairs',
                  subtitle: 'Chest/back, biceps/triceps pairings',
                  value: supersetPrefs.preferAntagonistPairs,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setPreferAntagonistPairs(value);
                  },
                ),

                Divider(height: 1, color: cardBorder, indent: 50),

                _SupersetToggleTile(
                  icon: Icons.fitness_center,
                  title: 'Allow compound sets',
                  subtitle: 'Same muscle group exercises',
                  value: supersetPrefs.allowCompoundSets,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setAllowCompoundSets(value);
                  },
                ),

                Divider(height: 1, color: cardBorder, indent: 50),

                // Max supersets slider
                _SupersetSliderTile(
                  icon: Icons.format_list_numbered,
                  title: 'Maximum supersets per workout',
                  value: supersetPrefs.maxSupersetsPerWorkout,
                  min: 1,
                  max: 5,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setMaxSupersetsPerWorkout(value);
                  },
                ),

                Divider(height: 1, color: cardBorder, indent: 50),

                // Rest between exercises
                _RestTimeSelectorTile(
                  icon: Icons.timer,
                  title: 'Rest between superset exercises',
                  currentValue: supersetPrefs.restBetweenExercises,
                  options: const [0, 10, 15, 20, 30],
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setRestBetweenExercises(value);
                  },
                ),

                Divider(height: 1, color: cardBorder, indent: 50),

                // Rest after superset
                _RestTimeSelectorTile(
                  icon: Icons.hourglass_empty,
                  title: 'Rest after completing superset',
                  currentValue: supersetPrefs.restAfterSuperset,
                  options: const [60, 90, 120, 150, 180],
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setRestAfterSuperset(value);
                  },
                ),
              ],
            ],
          ),
        ),

        // Favorite pairs section (only when enabled)
        if (supersetPrefs.supersetsEnabled) ...[
          const SizedBox(height: 16),
          _FavoritePairsSection(
            pairs: supersetPrefs.favoritePairs,
            onRemovePair: (pairId) {
              HapticFeedback.lightImpact();
              ref.read(supersetPreferencesProvider.notifier).removeFavoritePair(pairId);
            },
            onAddPair: () {
              HapticFeedback.lightImpact();
              _showAddPairSheet(context, ref);
            },
          ),
        ],
      ],
    );
  }

  void _showAddPairSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.elevated
          : AppColorsLight.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddFavoritePairSheet(
        onAdd: (exercise1, exercise2) {
          final pair = FavoriteSupersetPair(
            id: const Uuid().v4(),
            exercise1Name: exercise1,
            exercise2Name: exercise2,
          );
          ref.read(supersetPreferencesProvider.notifier).addFavoritePair(pair);
        },
      ),
    );
  }
}

/// Toggle tile for superset settings
class _SupersetToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SupersetToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}

/// Slider tile for superset limits
class _SupersetSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SupersetSliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.cyan,
              inactiveTrackColor: AppColors.cyan.withOpacity(0.2),
              thumbColor: AppColors.cyan,
              overlayColor: AppColors.cyan.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (newValue) => onChanged(newValue.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                max - min + 1,
                (index) => Text(
                  '${min + index}',
                  style: TextStyle(
                    fontSize: 11,
                    color: (min + index) == value ? AppColors.cyan : textMuted,
                    fontWeight: (min + index) == value ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rest time selector tile
class _RestTimeSelectorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int currentValue;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _RestTimeSelectorTile({
    required this.icon,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  String _formatTime(int seconds) {
    if (seconds == 0) return 'None';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final isSelected = option == currentValue;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cyan
                            : (isDark ? AppColors.pureBlack.withOpacity(0.3) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.cyan : cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : AppColorsLight.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Favorite pairs section
class _FavoritePairsSection extends StatelessWidget {
  final List<FavoriteSupersetPair> pairs;
  final ValueChanged<String> onRemovePair;
  final VoidCallback onAddPair;

  const _FavoritePairsSection({
    required this.pairs,
    required this.onRemovePair,
    required this.onAddPair,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.favorite, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'FAVORITE PAIRS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '${pairs.length} saved',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pairs list or empty state
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (pairs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.link_off,
                        size: 40,
                        color: textMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No favorite pairs yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your go-to exercise combinations',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...pairs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pair = entry.value;
                  return Column(
                    children: [
                      if (index > 0) Divider(height: 1, color: cardBorder, indent: 16),
                      _FavoritePairTile(
                        pair: pair,
                        onRemove: () => onRemovePair(pair.id),
                      ),
                    ],
                  );
                }),

              // Add pair button
              Divider(height: 1, color: cardBorder),
              InkWell(
                onTap: onAddPair,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.cyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Favorite Pair',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual favorite pair tile
class _FavoritePairTile extends StatelessWidget {
  final FavoriteSupersetPair pair;
  final VoidCallback onRemove;

  const _FavoritePairTile({
    required this.pair,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Exercise pair display
          Expanded(
            child: Row(
              children: [
                // Exercise 1
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pair.exercise1Name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Link icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.link,
                    size: 18,
                    color: AppColors.cyan,
                  ),
                ),
                // Exercise 2
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pair.exercise2Name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding a favorite pair
class _AddFavoritePairSheet extends StatefulWidget {
  final void Function(String exercise1, String exercise2) onAdd;

  const _AddFavoritePairSheet({required this.onAdd});

  @override
  State<_AddFavoritePairSheet> createState() => _AddFavoritePairSheetState();
}

class _AddFavoritePairSheetState extends State<_AddFavoritePairSheet> {
  final TextEditingController _exercise1Controller = TextEditingController();
  final TextEditingController _exercise2Controller = TextEditingController();
  final FocusNode _exercise1Focus = FocusNode();
  final FocusNode _exercise2Focus = FocusNode();

  bool get _canAdd =>
      _exercise1Controller.text.trim().isNotEmpty &&
      _exercise2Controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _exercise1Controller.dispose();
    _exercise2Controller.dispose();
    _exercise1Focus.dispose();
    _exercise2Focus.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (!_canAdd) return;
    widget.onAdd(
      _exercise1Controller.text.trim(),
      _exercise2Controller.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Add Favorite Pair',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter two exercises you want to superset together',
            style: TextStyle(fontSize: 14, color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Exercise 1 input
          TextField(
            controller: _exercise1Controller,
            focusNode: _exercise1Focus,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'First Exercise',
              hintText: 'e.g., Bench Press',
              prefixIcon: Icon(Icons.fitness_center, color: AppColors.cyan),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cyan, width: 2),
              ),
            ),
            onSubmitted: (_) => _exercise2Focus.requestFocus(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Link indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 1,
                height: 16,
                color: cardBorder,
              ),
              const SizedBox(width: 8),
              Icon(Icons.link, size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 16,
                color: cardBorder,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise 2 input
          TextField(
            controller: _exercise2Controller,
            focusNode: _exercise2Focus,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Second Exercise',
              hintText: 'e.g., Bent Over Rows',
              prefixIcon: Icon(Icons.fitness_center, color: AppColors.purple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.purple, width: 2),
              ),
            ),
            onSubmitted: (_) => _handleAdd(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAdd ? _handleAdd : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.cyan.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Pair',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
