import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/superset_preferences_provider.dart';
import '../../../../widgets/glass_sheet.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

/// Beast Mode card for advanced superset algorithm tuning.
///
/// Controls: compound sets toggle, max supersets slider, rest time selectors,
/// and favorite superset pairs management.
class SupersetAlgorithmCard extends ConsumerWidget {
  final BeastThemeData theme;
  const SupersetAlgorithmCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(supersetPreferencesProvider);

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Superset Algorithm',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Fine-tune superset generation',
            style: TextStyle(fontSize: 11, color: theme.textMuted),
          ),
          const SizedBox(height: 16),

          // Compound sets toggle
          _buildToggle(
            'Allow compound sets',
            'Same muscle group exercises',
            Icons.fitness_center,
            prefs.allowCompoundSets,
            (v) {
              HapticFeedback.selectionClick();
              ref.read(supersetPreferencesProvider.notifier).setAllowCompoundSets(v);
            },
          ),
          const SizedBox(height: 12),

          // Max supersets slider
          _buildSlider(
            'Max supersets per workout',
            prefs.maxSupersetsPerWorkout,
            1,
            5,
            (v) {
              HapticFeedback.selectionClick();
              ref.read(supersetPreferencesProvider.notifier).setMaxSupersetsPerWorkout(v);
            },
          ),
          const SizedBox(height: 12),

          // Rest between exercises
          _buildRestSelector(
            context,
            'Rest between exercises',
            prefs.restBetweenExercises,
            [0, 10, 15, 20, 30],
            (v) {
              HapticFeedback.selectionClick();
              ref.read(supersetPreferencesProvider.notifier).setRestBetweenExercises(v);
            },
          ),
          const SizedBox(height: 12),

          // Rest after superset
          _buildRestSelector(
            context,
            'Rest after superset',
            prefs.restAfterSuperset,
            [60, 90, 120, 150, 180],
            (v) {
              HapticFeedback.selectionClick();
              ref.read(supersetPreferencesProvider.notifier).setRestAfterSuperset(v);
            },
          ),
          const SizedBox(height: 16),

          // Favorite pairs
          _FavoritePairsSection(
            theme: theme,
            pairs: prefs.favoritePairs,
            onRemovePair: (id) {
              HapticFeedback.lightImpact();
              ref.read(supersetPreferencesProvider.notifier).removeFavoritePair(id);
            },
            onAddPair: () {
              HapticFeedback.lightImpact();
              _showAddPairSheet(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: theme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textMuted)),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String title,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, color: theme.textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.cyan,
            inactiveTrackColor: AppColors.cyan.withOpacity(0.2),
            thumbColor: AppColors.cyan,
            overlayColor: AppColors.cyan.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
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
                  fontSize: 10,
                  color: (min + index) == value ? AppColors.cyan : theme.textMuted,
                  fontWeight: (min + index) == value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestSelector(
    BuildContext context,
    String title,
    int currentValue,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: theme.textMuted, size: 18),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan
                          : (theme.isDark ? AppColors.pureBlack.withOpacity(0.3) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : theme.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(option),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : theme.textPrimary,
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
    );
  }

  String _formatTime(int seconds) {
    if (seconds == 0) return 'None';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (remaining == 0) return '${minutes}m';
    return '${minutes}m ${remaining}s';
  }

  void _showAddPairSheet(BuildContext context, WidgetRef ref) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _AddFavoritePairSheet(
          onAdd: (exercise1, exercise2) {
            final pair = FavoriteSupersetPair(
              id: const Uuid().v4(),
              exercise1Name: exercise1,
              exercise2Name: exercise2,
            );
            ref.read(supersetPreferencesProvider.notifier).addFavoritePair(pair);
          },
        ),
      ),
    );
  }
}

/// Favorite pairs list section within the Beast Mode card.
class _FavoritePairsSection extends StatelessWidget {
  final BeastThemeData theme;
  final List<FavoriteSupersetPair> pairs;
  final ValueChanged<String> onRemovePair;
  final VoidCallback onAddPair;

  const _FavoritePairsSection({
    required this.theme,
    required this.pairs,
    required this.onRemovePair,
    required this.onAddPair,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: AppColors.error, size: 16),
            const SizedBox(width: 6),
            Text(
              'FAVORITE PAIRS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '${pairs.length} saved',
              style: TextStyle(fontSize: 10, color: theme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: theme.isDark ? AppColors.pureBlack.withOpacity(0.2) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.cardBorder),
          ),
          child: Column(
            children: [
              if (pairs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.link_off, size: 32, color: theme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'No favorite pairs yet',
                        style: TextStyle(fontSize: 12, color: theme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add your go-to exercise combinations',
                        style: TextStyle(fontSize: 10, color: theme.textMuted),
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
                      if (index > 0) Divider(height: 1, color: theme.cardBorder, indent: 12),
                      _FavoritePairTile(
                        theme: theme,
                        pair: pair,
                        onRemove: () => onRemovePair(pair.id),
                      ),
                    ],
                  );
                }),

              Divider(height: 1, color: theme.cardBorder),
              InkWell(
                onTap: onAddPair,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.cyan, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Add Favorite Pair',
                        style: TextStyle(
                          fontSize: 13,
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

/// Individual favorite pair tile adapted for Beast Mode.
class _FavoritePairTile extends StatelessWidget {
  final BeastThemeData theme;
  final FavoriteSupersetPair pair;
  final VoidCallback onRemove;

  const _FavoritePairTile({
    required this.theme,
    required this.pair,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pair.exercise1Name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.link, size: 14, color: AppColors.cyan),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pair.exercise2Name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close, size: 14, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding a new favorite superset pair.
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 1, height: 16, color: cardBorder),
              const SizedBox(width: 8),
              Icon(Icons.link, size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: cardBorder),
            ],
          ),
          const SizedBox(height: 12),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
